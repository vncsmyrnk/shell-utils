#!/usr/bin/env python3

# vim: set ft=py:

import argparse
import pandas as pd

parser = argparse.ArgumentParser(description="A script that reads a file and calculates statistics.")
parser.add_argument("file", type=str, help="The path of the file containing the numbers")
args = parser.parse_args()

data = pd.read_csv(args.file, header=None).squeeze("columns")
print(data.describe())
