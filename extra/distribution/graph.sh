#!/usr/bin/env python3

# vim: set ft=py:

import argparse
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

parser = argparse.ArgumentParser(description="A script that reads a file and plots relevant distribution graphs.")
parser.add_argument("file", type=str, help="The path of the file containing the numbers")
args = parser.parse_args()

data = pd.read_csv(args.file, header=None).squeeze("columns")

sns.set_theme(style="whitegrid")

fig, axes = plt.subplots(nrows=2, ncols=2, figsize=(12, 10))

# --- Plot 1: Histogram ---
sns.histplot(data, bins=6, color="skyblue", ax=axes[0, 0])
axes[0, 0].set_title("Histogram")
axes[0, 0].set_xlabel("Value")

# --- Plot 2: Box Plot ---
sns.boxplot(x=data, color="lightgreen", ax=axes[0, 1])
axes[0, 1].set_title("Box Plot")
axes[0, 1].set_xlabel("Value")

# --- Plot 3: Density Plot (KDE - Kernel Density Estimate) ---
sns.kdeplot(data, fill=True, color="coral", ax=axes[1, 0])
axes[1, 0].set_title("Density Plot")
axes[1, 0].set_xlabel("Value")

# --- Plot 4: ECDF (Empirical Cumulative Distribution Function) ---
sns.ecdfplot(data, color="purple", ax=axes[1, 1])
axes[1, 1].set_title("ECDF Plot")
axes[1, 1].set_xlabel("Value")

plt.tight_layout()
plt.show()
