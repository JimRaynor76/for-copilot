"""
Walking-like synthetic data generator
3D latent + 1D twisted-ring attractor (Figure-2b style)

Latent structure:
- One-dimensional limit cycle (phase θ)
- Embedded as a twisted ring in 3D
- Transverse stability toward a phase-dependent manifold z = g(θ)

This produces a genuinely non-planar ring attractor.
"""

import numpy as np
import matplotlib.pyplot as plt


# ============================================================
# 1) Twisted-ring latent dynamics
# ============================================================

def twisted_walking_latent_step(
        theta, r, z,
        r0=1.0, alpha=4.0, omega0=0.8, a=0.6,
        lam=0.2, c1=0.25, c2=0.15, c3=0.10,
        dt=0.05,
        process_noise_std=0.0,
        rng=None,
):
    dtheta = omega0 * (1.0 + a * np.cos(3.0 * theta))
    theta = theta + dt * dtheta

    r = r + dt * alpha * (r0 - r)

    g = (c1*np.sin(theta) + c2*np.sin(2.0*theta) + c3*np.cos(3.0*theta))
    z = z + lam * (g - z)

    # ---- add process noise (transverse) ----
    if process_noise_std > 0.0:
        assert rng is not None
        z = z + process_noise_std * rng.randn()

    return theta, r, z


def generate_latent_walking_sequences_twisted(
        K=4,
        T=350,
        dt=0.05,
        seed=0,
):
    """
    Returns:
      X_list: list of (T, 3) latent trajectories
      theta_list: list of (T,) true gait phases
    """
    rng = np.random.RandomState(seed)

    X_list = []
    theta_list = []

    for k in range(K):
        theta = 2.0 #* np.pi * k / K
        r = 1.0 + 0.05 * rng.randn()
        z = 1 * rng.randn()     # small transverse perturbation

        X = np.zeros((T, 3))
        theta_traj = np.zeros(T)

        for t in range(T):
            theta_traj[t] = theta

            X[t, 0] = r * np.cos(theta)
            X[t, 1] = r * np.sin(theta)
            X[t, 2] = z

            theta, r, z = twisted_walking_latent_step(
                theta, r, z, dt=dt,process_noise_std=0.02, rng=rng,
            )

        X_list.append(X)
        theta_list.append(theta_traj)

    return X_list, theta_list


# ============================================================
# 2) Walking-like observation model (joint angles)
# ============================================================

def generate_walking_observations(
        theta_list,
        X_list,
        D=20,
        noise_std=0.05,
        seed=1,
):
    """
    High-dimensional joint-angle-like observations.
    - Fourier structure in phase
    - Weak coupling to transverse dimension
    """
    rng = np.random.RandomState(seed)

    freqs = np.array([1, 2, 3])
    A = rng.randn(D, len(freqs)) * 0.8
    Phi = rng.uniform(0, 2 * np.pi, size=(D, len(freqs)))
    Bz = rng.randn(D) * 0.3

    Y_list = []

    for theta, X in zip(theta_list, X_list):
        T = len(theta)
        Y = np.zeros((T, D))

        for j in range(D):
            for k, f in enumerate(freqs):
                Y[:, j] += A[j, k] * np.sin(f * theta + Phi[j, k])

            # transverse modulation (postural variation)
            Y[:, j] += Bz[j] * X[:, 2]

        Y = np.tanh(Y) + noise_std * rng.randn(*Y.shape)
        Y_list.append(Y.astype(np.float64))

    return Y_list


# ============================================================
# 3) Visualization
# ============================================================

def plot_latent_3d(X_list):
    fig = plt.figure(figsize=(6, 6))
    ax = fig.add_subplot(111, projection="3d")

    for X in X_list:
        ax.plot(X[:, 0], X[:, 1], X[:, 2], lw=1.5)

    ax.set_title("True latent: twisted-ring walking attractor")
    ax.set_xlabel("x1")
    ax.set_ylabel("x2")
    ax.set_zlabel("z")

    plt.tight_layout()
    plt.show()


def plot_joint_angles(Y_list):
    plt.figure(figsize=(6, 3))
    plt.plot(Y_list[0][:, :6])
    plt.title("Example joint angles (first 6 dims)")
    plt.xlabel("time")
    plt.show()


# ============================================================
# 4) Main
# ============================================================

def main():
    K = 1
    T = 350
    D = 20

    X_list, theta_list = generate_latent_walking_sequences_twisted(
        K=K, T=T, dt=0.05, seed=0
    )

    Y_list = generate_walking_observations(
        theta_list, X_list, D=D, noise_std=0.05, seed=1
    )

    plot_latent_3d(X_list)
    plot_joint_angles(Y_list)

    print("Twisted-ring walking data ready:")
    print("  Latent shapes:", [X.shape for X in X_list])
    print("  Observation shapes:", [Y.shape for Y in Y_list])
    print(theta_list[0][0])
    print(theta_list[1][0])


if __name__ == "__main__":
    main()
