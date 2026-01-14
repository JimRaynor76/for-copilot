"""
Learn twisted-ring walking-like data with GPDM
and visualize Figure-2b-style results.
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.decomposition import PCA
import os

# ===== GPDM imports =====
from gpdm.model import FullGPDM, GPDMConfig
from gpdm.trainer import GPDMTrainer, TrainConfig


# --------------------------------------------------
# Utility: split concatenated latent back to sequences
# --------------------------------------------------
def split_latent(X_all, lengths):
    X_list = []
    idx = 0
    for L in lengths:
        X_list.append(X_all[idx:idx + L])
        idx += L
    return X_list


# --------------------------------------------------
# Visualization
# --------------------------------------------------
def plot_true_vs_learned(true_X_list, learned_X_list):
    fig = plt.figure(figsize=(12, 5))

    # ---- True latent ----
    ax1 = fig.add_subplot(121, projection="3d")
    for X in true_X_list:
        ax1.plot(X[:, 0], X[:, 1], X[:, 2], lw=1.5)
    ax1.set_title("True latent (twisted-ring attractor)")
    ax1.set_xlabel("x1")
    ax1.set_ylabel("x2")
    ax1.set_zlabel("z")

    # ---- Learned latent ----
    ax2 = fig.add_subplot(122, projection="3d")
    for X in learned_X_list:
        ax2.plot(X[:, 0], X[:, 1], X[:, 2], lw=1.5)
    ax2.set_title("Learned latent (GPDM)")
    ax2.set_xlabel("z1")
    ax2.set_ylabel("z2")
    ax2.set_zlabel("z3")

    plt.tight_layout()
    plt.show()




def plot_phase_colored_latent(X_learned_list, theta_list,save_path=None):
    fig = plt.figure(figsize=(6, 6))
    ax = fig.add_subplot(111, projection="3d")

    for X, theta in zip(X_learned_list, theta_list):
        sc = ax.scatter(
            X[:, 0], X[:, 1], X[:, 2],
            c=theta,
            cmap="hsv",
            s=5,
        )

    ax.set_title("Learned latent colored by true gait phase")
    ax.set_xlabel("z1")
    ax.set_ylabel("z2")
    ax.set_zlabel("z3")

    cbar = plt.colorbar(sc, ax=ax, shrink=0.6)
    cbar.set_label("gait phase θ")

    plt.tight_layout()
    if save_path is not None:
        plt.savefig(save_path)
    plt.show()

def plot_multiseq_latent(X_learned_list,save_path=None):
    fig = plt.figure(figsize=(6, 6))
    ax = fig.add_subplot(111, projection="3d")

    for i, X in enumerate(X_learned_list):
        ax.plot(
            X[:, 0], X[:, 1], X[:, 2],
            lw=1.5,
            label=f"seq{i}"
        )

    ax.set_title("Learned latent: multiple sequences")
    ax.set_xlabel("z1")
    ax.set_ylabel("z2")
    ax.set_zlabel("z3")
    ax.legend()


    plt.tight_layout()
    if save_path is not None:
        plt.savefig(save_path)
    plt.show()


def plot_phase_vs_time(theta_list):
    plt.figure(figsize=(6, 3))
    for theta in theta_list:
        plt.plot(theta, lw=1)

    plt.title("True gait phase vs time")
    plt.xlabel("time")
    plt.ylabel("θ")
    plt.tight_layout()
    plt.show()

def plot_latent_speed(X_learned_list):
    plt.figure(figsize=(6, 3))

    for X in X_learned_list:
        vel = np.linalg.norm(np.diff(X, axis=0), axis=1)
        plt.plot(vel, lw=1)

    plt.title("Latent speed ||x_{t+1} - x_t||")
    plt.xlabel("time")
    plt.ylabel("speed")
    plt.tight_layout()
    plt.show()


def plot_true_vs_learned_single(true_X, learned_X):
    fig = plt.figure(figsize=(10, 4))

    ax1 = fig.add_subplot(121, projection="3d")
    ax1.plot(true_X[:, 0], true_X[:, 1], true_X[:, 2])
    ax1.set_title("True latent")

    ax2 = fig.add_subplot(122, projection="3d")
    ax2.plot(learned_X[:, 0], learned_X[:, 1], learned_X[:, 2])
    ax2.set_title("Learned latent")

    plt.tight_layout()
    plt.show()


# --------------------------------------------------
# Main
# --------------------------------------------------
def main():
    # data=pd.read_pickle("walking.pkl").values
    data=pd.read_pickle("Z:\\BioMotionAnlyze\\analyze\\GPDM\\test\\trial_11_0_noisy.pkl").values

    Y_list=[data]
    print("Data shapes:")
    print("  Y_list:", [Y.shape for Y in Y_list])

    # ===== 2) PCA initialization (VERY IMPORTANT) =====
    X0_list = [
        0.5 * PCA(n_components=3).fit_transform(Y)
        for Y in Y_list
    ]

    # ===== 3) Fit GPDM =====
    model = FullGPDM(
        GPDMConfig(
            use_w=True,
            jitter_y=1e-6,
            jitter_x=1e-6,
        )
    )

    trainer = GPDMTrainer(
        model,
        TrainConfig(
            maxiter=0,
            verbose=True,
        )
    )

    result = trainer.fit(Y=Y_list, X0=X0_list)

    # ===== 4) Split learned latent =====
    X_all = np.asarray(result.state.X)      # shape (sum_T, 3)
    lengths = [len(Y) for Y in Y_list]
    X_learned_list = split_latent(X_all, lengths)

    print("Learned latent shapes:", [X.shape for X in X_learned_list])


    T = Y_list[0].shape[0]
    dt = 1.0 / 120
    t = np.arange(T) * dt


    if not os.path.exists("./figs"):
        os.makedirs("./figs")
        print("已自动创建 ./figs 文件夹")

    save_path="./figs/walking_demo_pca_time.png"
    plot_phase_colored_latent(X_learned_list,[t],save_path=save_path)
    
    save_path="./figs/walking_demo_pca.png"
    plot_multiseq_latent(X_learned_list,save_path=save_path)
    # plot_phase_vs_time(theta_list)
    # plot_latent_speed(X_learned_list)


if __name__ == "__main__":
    main()
