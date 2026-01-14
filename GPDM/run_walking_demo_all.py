"""
Learn twisted-ring walking-like data with GPDM
and visualize Figure-2b-style results.
"""

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.decomposition import PCA
import os
import glob

# ===== GPDM imports =====
from gpdm.model import FullGPDM, GPDMConfig
from gpdm.trainer import GPDMTrainer, TrainConfig


# ==============================================================================
#  CONFIGURATION 
# ==============================================================================
# 运行模��选择: 'single' (单文件), 'multiple' (多文件列表), 'folder' (文件夹遍历)
MODE = 'folder'

# 1. Single Mode 参数
SINGLE_FILE_PATH = r"GPDM/test/trial_11_0_noisy.pkl"

# 2. Multiple Mode 参数
MULTIPLE_FILE_PATHS = [
    r"GPDM/test/trial_11_0_noisy.pkl",
    r"GPDM/test/trial_11_0.pkl"
]

# 3. Folder Mode 参数
FOLDER_PATH = r"GPDM/test"

# 输出设置
OUTPUT_DIR = "./figs"  # 结果图片保存路径
# ==============================================================================


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


def plot_phase_colored_latent(X_learned_list, theta_list, save_path=None):
    fig = plt.figure(figsize=(6, 6))
    ax = fig.add_subplot(111, projection="3d")

    sc = None
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

    if sc:
        cbar = plt.colorbar(sc, ax=ax, shrink=0.6)
        cbar.set_label("gait phase θ")

    plt.tight_layout()
    if save_path is not None:
        plt.savefig(save_path)
        print(f"Saved: {save_path}")
    # plt.show() # 批量处理时建议注释掉 show，防止弹出太多窗口
    plt.close(fig) # 关闭图像释放内存

def plot_multiseq_latent(X_learned_list, save_path=None):
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
        print(f"Saved: {save_path}")
    # plt.show()
    plt.close(fig)


# --------------------------------------------------
# Core Processing Logic
# --------------------------------------------------
def run_gpdm_on_file(file_path):
    print(f"\n{'='*40}")
    print(f"Processing: {file_path}")
    print(f"{'='*40}")
    
    if not os.path.exists(file_path):
        print(f"Error: File not found: {file_path}")
        return

    try:
        data = pd.read_pickle(file_path).values
    except Exception as e:
        print(f"Error reading pickle file: {e}")
        return

    # Generate output filenames based on input filename
    base_name = os.path.splitext(os.path.basename(file_path))[0]
    out_img_time = os.path.join(OUTPUT_DIR, f"{base_name}_pca_time.png")
    out_img_pca = os.path.join(OUTPUT_DIR, f"{base_name}_pca.png")

    Y_list = [data]
    print("Data shapes:", [Y.shape for Y in Y_list])

    # ===== 2) PCA initialization =====
    try:
        X0_list = [
            0.5 * PCA(n_components=3).fit_transform(Y)
            for Y in Y_list
        ]
    except Exception as e:
        print(f"PCA failed (data might be too small?): {e}")
        return

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

    # Plotting
    plot_phase_colored_latent(X_learned_list, [t], save_path=out_img_time)
    plot_multiseq_latent(X_learned_list, save_path=out_img_pca)


# --------------------------------------------------
# Main
# --------------------------------------------------
def main():
    # Ensure output directory exists
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f"Created output directory: {OUTPUT_DIR}")

    files_to_process = []

    # Select files based on MODE
    if MODE == 'single':
        files_to_process.append(SINGLE_FILE_PATH)
    
    elif MODE == 'multiple':
        files_to_process = MULTIPLE_FILE_PATHS
    
    elif MODE == 'folder':
        if os.path.exists(FOLDER_PATH):
            # Find all .pkl files in the folder
            search_pattern = os.path.join(FOLDER_PATH, "*.pkl")
            files_to_process = glob.glob(search_pattern)
            print(f"Found {len(files_to_process)} .pkl files in {FOLDER_PATH}")
        else:
            print(f"Error: Folder path does not exist: {FOLDER_PATH}")

    else:
        print(f"Unknown MODE: {MODE}")
        return

    # Run processing
    if not files_to_process:
        print("No files to process.")
        return

    for f_path in files_to_process:
        run_gpdm_on_file(f_path)

    print("\nAll tasks completed.")

if __name__ == "__main__":
    main()