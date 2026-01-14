
from __future__ import annotations
from typing import Optional, Sequence, List, Union
import numpy as np
import matplotlib.pyplot as plt

def plot_latent_2d(X, c=None, title=""):
    X = np.asarray(X)
    fig = plt.figure(figsize=(10,4))
    fig.suptitle(title, fontsize=14, fontweight="bold")
    ax1 = fig.add_subplot(1,2,1)
    ax1.set_title("Scatter")
    if c is None:
        ax1.scatter(X[:,0], X[:,1], s=12)
    else:
        ax1.scatter(X[:,0], X[:,1], c=c, cmap="Blues", s=12)
    ax2 = fig.add_subplot(1,2,2)
    ax2.set_title("Line")
    ax2.plot(X[:,0], X[:,1], lw=1.5)
    fig.tight_layout()
    plt.show()
    plt.close()

def plot_multi_latent_2d(X_list, t_list=None, title=""):
    fig = plt.figure(figsize=(10,4))
    fig.suptitle(title, fontsize=14, fontweight="bold")
    ax1 = fig.add_subplot(1,2,1); ax1.set_title("Scatter")
    ax2 = fig.add_subplot(1,2,2); ax2.set_title("Line")
    for k, X in enumerate(X_list):
        X = np.asarray(X)
        if t_list is None:
            ax1.scatter(X[:,0], X[:,1], s=10)
        else:
            ax1.scatter(X[:,0], X[:,1], c=t_list[k], cmap="Blues", s=10)
        ax2.plot(X[:,0], X[:,1], lw=1.2)
    fig.tight_layout()
    plt.show()
    plt.close()
