# gpdm/model.py
"""
Full GPDM model (MAP inference) in a clean, class-based design.

This file contains ONLY model math:
- parameter transforms (positivity via exp)
- log posterior computation
- packing/unpacking of parameters

Training/optimization is delegated to gpdm/trainer.py.
"""

from dataclasses import dataclass
from typing import Optional, Tuple

import autograd.numpy as np

from .kernels import ky_rbf, kx_rbf_linear


def stable_cholesky(K, jitter=1e-6, max_tries=6):
    N = K.shape[0]
    identity = np.eye(N)

    jitter_curr = jitter
    for _ in range(max_tries):
        try:
            return np.linalg.cholesky(K + jitter_curr * identity)
        except np.linalg.LinAlgError:
            jitter_curr *= 10.0

    raise np.linalg.LinAlgError(
        f"Cholesky failed after {max_tries} attempts; "
        f"final jitter={jitter_curr}"
    )

@dataclass
class GPDMHyperParams:
    """
    Hyperparameters are stored in *positive* space.
    """
    beta: np.ndarray   # (3,)
    alpha: np.ndarray  # (4,)
    w: Optional[np.ndarray] = None  # (J,) if enabled


@dataclass
class GPDMState:
    """
    Latent trajectory X plus hypers.
    """
    X: np.ndarray                # (T, D)
    hypers: GPDMHyperParams


@dataclass
class GPDMConfig:
    """
    Model configuration (not train hyperparams).
    """
    use_w: bool = False
    jitter_y: float = 1e-6
    jitter_x: float = 1e-6
    # For multiple sequences: lengths of each sequence in the concatenated data.
    # If None, treat data as a single continuous sequence.
    seq_lengths: Optional[Tuple[int, ...]] = None


class FullGPDM:
    """
    Full GPDM (no sparse approximation).
    """

    def __init__(self, config: GPDMConfig):
        self.config = config

    # ---------- parameter transforms ----------
    @staticmethod
    def _to_positive(log_params: np.ndarray) -> np.ndarray:
        return np.exp(log_params)

    @staticmethod
    def _to_log(params: np.ndarray) -> np.ndarray:
        return np.log(params)

    # ---------- packing / unpacking ----------
    def pack(
        self,
        X: np.ndarray,
        beta: np.ndarray,
        alpha: np.ndarray,
        w: Optional[np.ndarray],
        Y_shape: Tuple[int, int],
    ) -> np.ndarray:
        T, J = Y_shape
        T2, D = X.shape
        assert T2 == T, "X must match Y in time length"

        parts = [X.reshape(-1), self._to_log(beta), self._to_log(alpha)]
        if self.config.use_w:
            assert w is not None and w.shape == (J,)
            parts.append(self._to_log(w))
        return np.concatenate(parts)

    def unpack(self, theta: np.ndarray, T: int, D: int, J: int) -> GPDMState:
        cur = 0
        X = theta[cur:cur + T * D].reshape(T, D)
        cur += T * D

        beta = self._to_positive(theta[cur:cur + 3])
        cur += 3
        alpha = self._to_positive(theta[cur:cur + 4])
        cur += 4

        w = None
        if self.config.use_w:
            w = self._to_positive(theta[cur:cur + J])

        hypers = GPDMHyperParams(beta=beta, alpha=alpha, w=w)
        return GPDMState(X=X, hypers=hypers)

    # ---------- core objective ----------
    def log_posterior(self, Y: np.ndarray, state: GPDMState) -> float:
        Y = np.asarray(Y)
        X = state.X
        beta = state.hypers.beta
        alpha = state.hypers.alpha
        w = state.hypers.w

        T, J = Y.shape
        _, D = X.shape

        # ---- W handling ----
        if not self.config.use_w:
            w_diag = np.ones(J)
        else:
            assert w is not None
            w_diag = w

        # ==========================================================
        # 1) Observation term: p(Y | X, beta, W)
        # ==========================================================
        K_Y = ky_rbf(X, beta)
        L_y = stable_cholesky(K_Y, self.config.jitter_y)
        logdet_KY = 2.0 * np.sum(np.log(np.diag(L_y)))

        Y_tilde = Y * w_diag[None, :]
        Z = np.linalg.solve(L_y, Y_tilde)
        KY_inv_Y = np.linalg.solve(L_y.T, Z)
        quad_Y = np.sum(Y_tilde * KY_inv_Y)

        log_like_Y = (
            (T * np.sum(np.log(w_diag)) if self.config.use_w else 0.0)
            - 0.5 * J * logdet_KY
            - 0.5 * quad_Y
        )

        # ==========================================================
        # 2) Dynamics term: p(X | alpha)
        #    INCLUDING p(x1)  (Eq. 8 / 9 in GPDM paper)
        # ==========================================================
        seq_lengths = self.config.seq_lengths

        # ---- transitions ----
        if (seq_lengths is None) or (len(seq_lengths) <= 1):
            X_in = X[:-1]
            X_bar = X[1:]
            Tx = T - 1
        else:
            lengths = tuple(int(L) for L in seq_lengths)
            if sum(lengths) != T:
                raise ValueError("seq_lengths do not sum to T")

            starts = np.cumsum((0,) + lengths[:-1])
            X_in_list = []
            X_bar_list = []
            for s, L in zip(starts, lengths):
                if L < 2:
                    continue
                X_in_list.append(X[s : s + L - 1])
                X_bar_list.append(X[s + 1 : s + L])
            X_in = np.vstack(X_in_list)
            X_bar = np.vstack(X_bar_list)
            # Tx = X_in.shape[0]

        K_X = kx_rbf_linear(X_in, alpha)
        L_x = stable_cholesky(K_X, self.config.jitter_x)
        logdet_KX = 2.0 * np.sum(np.log(np.diag(L_x)))

        Zx = np.linalg.solve(L_x, X_bar)
        KX_inv_Xbar = np.linalg.solve(L_x.T, Zx)
        quad_X = np.sum(X_bar * KX_inv_Xbar)

        log_prior_X = -0.5 * D * logdet_KX - 0.5 * quad_X

        # ---- NEW: initial state prior p(x1) ----
        if seq_lengths is None:
            x1_list = [X[0]]
        else:
            starts = np.cumsum((0,) + seq_lengths[:-1])
            x1_list = [X[s] for s in starts]

        log_prior_x1 = 0.0
        for x1 in x1_list:
            log_prior_x1 += -0.5 * np.sum(x1 * x1)

        # ==========================================================
        # 3) Hyperpriors
        # ==========================================================
        log_prior_hypers = -np.sum(np.log(alpha)) - np.sum(np.log(beta))

        return log_like_Y + log_prior_X + log_prior_x1 + log_prior_hypers

    def neg_log_posterior(self, Y, theta, T, D, J):
        state = self.unpack(theta, T=T, D=D, J=J)
        return -self.log_posterior(Y, state)

    @staticmethod
    def default_hypers(J: int, use_w: bool) -> GPDMHyperParams:
        beta = np.array([1.0, 1.0, 1.0])
        alpha = np.array([1.0, 1.0, 1.0, 1.0])
        w = np.ones(J) if use_w else None
        return GPDMHyperParams(beta=beta, alpha=alpha, w=w)

    def mean_prediction(
            self,
            X_query: np.ndarray,
            state: GPDMState,
    ) -> np.ndarray:
        """
        Compute GPDM mean prediction of next latent state.

        Parameters
        ----------
        X_query : (N, D) or (D,)
            Query latent states x_t.
        state : GPDMState
            Learned latent states and hyperparameters.

        Returns
        -------
        X_mean : (N, D)
            Mean prediction E[x_{t+1} | x_t].
        """
        X = state.X
        alpha = state.hypers.alpha

        if X_query.ndim == 1:
            X_query = X_query[None, :]

        T, D = X.shape

        # --------------------------------------------------
        # Build training pairs (X_in, X_bar)
        # --------------------------------------------------
        seq_lengths = self.config.seq_lengths

        if (seq_lengths is None) or (len(seq_lengths) <= 1):
            X_in = X[:-1]
            X_bar = X[1:]
        else:
            starts = np.cumsum((0,) + seq_lengths[:-1])
            X_in_list = []
            X_bar_list = []
            for s, L in zip(starts, seq_lengths):
                if L < 2:
                    continue
                X_in_list.append(X[s : s + L - 1])
                X_bar_list.append(X[s + 1 : s + L])
            X_in = np.vstack(X_in_list)
            X_bar = np.vstack(X_bar_list)

        # --------------------------------------------------
        # GP regression mean
        # --------------------------------------------------
        K_X = kx_rbf_linear(X_in, alpha)
        L = stable_cholesky(K_X, self.config.jitter_x)

        # Solve K^{-1} X_bar
        Z = np.linalg.solve(L, X_bar)
        Kinv_Xbar = np.linalg.solve(L.T, Z)

        # Cross-kernel k(x*, X_in)
        sqdist = (
                np.sum(X_query**2, axis=1, keepdims=True)
                + np.sum(X_in**2, axis=1)[None, :]
                - 2.0 * X_query @ X_in.T
        )

        alpha1, alpha2, alpha3, _ = alpha
        K_star = (
                alpha1 * np.exp(-0.5 * alpha2 * sqdist)
                + alpha3 * (X_query @ X_in.T)
        )

        # Mean prediction
        X_mean = K_star @ Kinv_Xbar
        return X_mean
