# gpdm/kernels.py
import autograd.numpy as anp


def _sqdist(X):
    """
    Squared Euclidean distance matrix.
    Stable and autograd-friendly.
    """
    sq = anp.sum(X * X, axis=1, keepdims=True)
    sqdist = sq + sq.T - 2.0 * X @ X.T

    # Numerical safety: remove tiny negative values
    return anp.clip(sqdist, 0.0, anp.inf)


def ky_rbf(X, beta):
    """
    Observation kernel:
        k_Y(x,x') = β1 exp(-β2/2 ||x-x'||^2) + β3^{-1} δ
    """
    beta1, beta2, beta3 = beta
    T = X.shape[0]

    K = beta1 * anp.exp(-0.5 * beta2 * _sqdist(X))
    K = K + (1.0 / beta3) * anp.eye(T)
    return K


def kx_rbf_linear(X, alpha):
    """
    Dynamics kernel:
        k_X(x,x') = α1 exp(-α2/2 ||x-x'||^2) + α3 x^T x' + α4^{-1} δ
    """
    alpha1, alpha2, alpha3, alpha4 = alpha
    T = X.shape[0]

    K = alpha1 * anp.exp(-0.5 * alpha2 * _sqdist(X))
    K = K + alpha3 * (X @ X.T)
    K = K + (1.0 / alpha4) * anp.eye(T)
    return K
