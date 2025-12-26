# run_full_gpdm_demo.py
"""
Example usage for the refactored Full GPDM.

Run:
    python run_full_gpdm_demo.py
"""
import numpy as onp
from sklearn.decomposition import PCA

from src.gpdm.model import (
    FullGPDM, GPDMConfig,
)

from src.gpdm.trainer import (
    GPDMTrainer, TrainConfig,

)
from src.gpdm.data import gen_scurve_gp_observations
from plotting import plot_latent_2d


def main():
    # 1) Generate data
    X_true, Y, t = gen_scurve_gp_observations(T=300, J=40, noise_std=0.01, seed=42)

    # 2) Init X with PCA(Y)
    X0 = PCA(n_components=2).fit_transform(onp.asarray(Y))

    # 3) Build model + trainer
    model = FullGPDM(GPDMConfig(use_w=True, jitter_y=1e-6, jitter_x=1e-6))
    trainer = GPDMTrainer(model, TrainConfig(maxiter=200, verbose=True))

    # 4) Fit
    result = trainer.fit(Y=Y, X0=X0)
    print("old")
    print(result.state.hypers.w)
    X_map = onp.asarray(result.state.X)

    # 5) Plot
    save_path="s_demo_true.png"
    plot_latent_2d(X_true, t, "True latent (X_true)",save_path=save_path)
    save_path="s_demo_pca.png"
    plot_latent_2d(X0, t, "PCA init (X0)",save_path=save_path)
    save_path="s_demo_pgdm.png"
    plot_latent_2d(X_map, t, "Full GPDM MAP (X_map)",save_path=save_path)


if __name__ == "__main__":
    main()
