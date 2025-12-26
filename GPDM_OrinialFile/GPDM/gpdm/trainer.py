# gpdm/trainer.py
"""
Training / optimization logic separated from the model.

- owns optimizer choice, stopping, logging
- calls FullGPDM.neg_log_posterior + autograd grad
"""

from dataclasses import dataclass
from typing import Optional, Dict, Any, Tuple, Sequence, Union, List

import autograd.numpy as np
from autograd import grad
from scipy.optimize import fmin_l_bfgs_b


def _stack_time_sequences(
        arr: Union[np.ndarray, Sequence[np.ndarray]],
        name: str,
) -> Tuple[np.ndarray, Optional[Tuple[int, ...]]]:
    """Stack a list/tuple of (T_m, J) or (T_m, D) arrays along time.

    Returns:
        stacked: (sum T_m, ...)
        lengths: (T_1, ..., T_M) if input was a sequence, else None
    """
    if isinstance(arr, np.ndarray):
        a = np.asarray(arr)
        if a.ndim != 2:
            raise ValueError(f"{name} must be a 2D array, got shape {a.shape}")
        return a, None

    seq = list(arr)
    if len(seq) == 0:
        raise ValueError(f"{name} sequence is empty")
    seq2: List[np.ndarray] = []
    lengths: List[int] = []
    ncols = None
    for k, a in enumerate(seq):
        a = np.asarray(a)
        if a.ndim != 2:
            raise ValueError(f"{name}[{k}] must be 2D, got shape {a.shape}")
        if ncols is None:
            ncols = a.shape[1]
        elif a.shape[1] != ncols:
            raise ValueError(
                f"All {name} sequences must have same second dimension; got {a.shape[1]} vs {ncols}"
            )
        seq2.append(a)
        lengths.append(int(a.shape[0]))
    return np.vstack(seq2), tuple(lengths)


from .model import FullGPDM, GPDMState, GPDMHyperParams


@dataclass
class TrainConfig:
    maxiter: int = 200
    verbose: bool = True
    # L-BFGS-B options can be extended here
    # e.g. factr, pgtol, maxfun etc.


@dataclass
class TrainResult:
    state: GPDMState
    info: Dict[str, Any]
    final_neg_log_post: float


class GPDMTrainer:
    """
    Trainer for FullGPDM using SciPy L-BFGS-B and autograd gradients.
    """

    def __init__(self, model: FullGPDM, config: TrainConfig):
        self.model = model
        self.config = config

    def fit(
            self,
            Y: Union[np.ndarray, Sequence[np.ndarray]],
            X0: Union[np.ndarray, Sequence[np.ndarray]],
            hypers0: Optional[GPDMHyperParams] = None,
    ) -> TrainResult:
        """
        Fit MAP parameters.

        Y: (T,J)
        X0: (T,D) initialization, e.g. PCA(Y)
        hypers0: optional initialization for beta/alpha/w
        """
        Y_stacked, y_lengths = _stack_time_sequences(Y, name="Y")
        X0_stacked, x_lengths = _stack_time_sequences(X0, name="X0")

        if (y_lengths is not None) and (x_lengths is not None) and (y_lengths != x_lengths):
            raise ValueError(f"Y and X0 must have matching sequence lengths; got {y_lengths} vs {x_lengths}")

        # Store sequence lengths on the model config so the dynamics prior can exclude boundaries.
        self.model.config.seq_lengths = y_lengths if (y_lengths is not None) else x_lengths

        Y = Y_stacked
        X0 = X0_stacked
        T, J = Y.shape
        T2, D = X0.shape
        assert T2 == T, "X0 must match Y in time length"

        if hypers0 is None:
            hypers0 = self.model.default_hypers(J=J, use_w=self.model.config.use_w)

        theta0 = self.model.pack(
            X=X0,
            beta=hypers0.beta,
            alpha=hypers0.alpha,
            w=hypers0.w,
            Y_shape=Y.shape
        )

        def f(theta):
            return self.model.neg_log_posterior(Y, theta, T=T, D=D, J=J)

        g = grad(f)

        theta_opt, f_opt, info = fmin_l_bfgs_b(
            func=f,
            x0=theta0,
            fprime=g,
            maxiter=self.config.maxiter,
        )

        state = self.model.unpack(theta_opt, T=T, D=D, J=J)

        if self.config.verbose:
            print("Optimization finished.")
            print("  final neg log posterior:", float(f_opt))
            print("  warnflag:", info.get("warnflag", None))
            if info.get("task", None) is not None:
                print("  task:", info["task"])

        return TrainResult(state=state, info=info, final_neg_log_post=float(f_opt))


# =============================================================================
# New: Alternating / Block-coordinate trainer (Scheme 1)
# =============================================================================

@dataclass
class AlternatingTrainConfig:
    """
    Block-coordinate (alternating) optimization config.

    outer_iters:
        Number of alternation rounds: (optimize X) -> (optimize hypers) repeating.

    x_maxiter:
        L-BFGS-B maxiter for X-step each round.

    hypers_maxiter:
        L-BFGS-B maxiter for hypers-step each round.

    verbose:
        Print per-round progress.
    """
    outer_iters: int = 10
    x_maxiter: int = 50
    hypers_maxiter: int = 50
    verbose: bool = True

    # Optional: early stop when objective improvement is small
    tol: float = 1e-6


class AlternatingGPDMTrainer:
    """
    Block-coordinate trainer for FullGPDM:

    Repeat for several rounds:
        1) optimize X with hypers fixed
        2) optimize hypers (beta/alpha/(w)) with X fixed

    This often improves conditioning and stability vs full joint optimization.
    """

    def __init__(self, model: FullGPDM, config: AlternatingTrainConfig):
        self.model = model
        self.config = config

    def fit(
            self,
            Y: Union[np.ndarray, Sequence[np.ndarray]],
            X0: Union[np.ndarray, Sequence[np.ndarray]],
            hypers0: Optional[GPDMHyperParams] = None,
    ) -> TrainResult:
        Y_stacked, y_lengths = _stack_time_sequences(Y, name="Y")
        X0_stacked, x_lengths = _stack_time_sequences(X0, name="X0")

        if (y_lengths is not None) and (x_lengths is not None) and (y_lengths != x_lengths):
            raise ValueError(f"Y and X0 must have matching sequence lengths; got {y_lengths} vs {x_lengths}")

        # Store sequence lengths on the model config so the dynamics prior can exclude boundaries.
        self.model.config.seq_lengths = y_lengths if (y_lengths is not None) else x_lengths

        Y = Y_stacked
        X0 = X0_stacked
        T, J = Y.shape
        T2, D = X0.shape
        assert T2 == T, "X0 must match Y in time length"

        if hypers0 is None:
            hypers0 = self.model.default_hypers(J=J, use_w=self.model.config.use_w)

        # Initial full parameter vector (theta contains X_flat + log(beta) + log(alpha) + log(w))
        theta = self.model.pack(
            X=X0,
            beta=hypers0.beta,
            alpha=hypers0.alpha,
            w=hypers0.w,
            Y_shape=Y.shape,
        )

        # Indices for block slicing (theta is in "unconstrained" space for hypers)
        x_end = T * D
        beta_end = x_end + 3
        alpha_end = beta_end + 4
        w_end = alpha_end + (J if self.model.config.use_w else 0)

        if w_end != theta.shape[0]:
            raise ValueError("Internal theta slicing mismatch. Please check pack/unpack shapes.")

        def full_obj(th):
            return self.model.neg_log_posterior(Y, th, T=T, D=D, J=J)

        prev_f = float(full_obj(theta))

        # ---- Outer alternation loop ----
        info: Dict[str, Any] = {"outer_history": []}

        for it in range(int(self.config.outer_iters)):
            # -------------------------
            # Step 1: optimize X only
            # -------------------------
            theta_fixed_h = theta  # capture current hypers slice
            x0_flat = np.asarray(theta_fixed_h[:x_end])

            def f_x(x_flat):
                th = theta_fixed_h.copy()
                th[:x_end] = x_flat
                return self.model.neg_log_posterior(Y, th, T=T, D=D, J=J)

            g_x = grad(f_x)

            x_opt, f_x_opt, info_x = fmin_l_bfgs_b(
                func=f_x,
                x0=x0_flat,
                fprime=g_x,
                maxiter=int(self.config.x_maxiter),
            )

            theta = theta.copy()
            theta[:x_end] = x_opt

            # -----------------------------
            # Step 2: optimize hypers only
            # -----------------------------
            theta_fixed_x = theta
            h0 = np.asarray(theta_fixed_x[x_end:w_end])

            def f_h(h_vec):
                th = theta_fixed_x.copy()
                th[x_end:w_end] = h_vec
                return self.model.neg_log_posterior(Y, th, T=T, D=D, J=J)

            g_h = grad(f_h)

            h_opt, f_h_opt, info_h = fmin_l_bfgs_b(
                func=f_h,
                x0=h0,
                fprime=g_h,
                maxiter=int(self.config.hypers_maxiter),
            )

            theta = theta.copy()
            theta[x_end:w_end] = h_opt

            cur_f = float(full_obj(theta))
            info["outer_history"].append(
                {
                    "outer_iter": it,
                    "neg_log_post": cur_f,
                    "x_step": {"neg_log_post": float(f_x_opt), "warnflag": info_x.get("warnflag", None), "task": info_x.get("task", None)},
                    "hypers_step": {"neg_log_post": float(f_h_opt), "warnflag": info_h.get("warnflag", None), "task": info_h.get("task", None)},
                }
            )

            if self.config.verbose:
                print(f"[AltGPDM] outer {it+1}/{self.config.outer_iters} | neg_log_post = {cur_f:.6f} (prev {prev_f:.6f})")

            # Early stopping on small improvement
            if abs(prev_f - cur_f) < float(self.config.tol):
                if self.config.verbose:
                    print(f"[AltGPDM] early stop: improvement {abs(prev_f-cur_f):.3e} < tol {self.config.tol:.3e}")
                prev_f = cur_f
                break

            prev_f = cur_f

        # Final state
        state = self.model.unpack(theta, T=T, D=D, J=J)
        final_f = float(full_obj(theta))

        return TrainResult(state=state, info=info, final_neg_log_post=final_f)
