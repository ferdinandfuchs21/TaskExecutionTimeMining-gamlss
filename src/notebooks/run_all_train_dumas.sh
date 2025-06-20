#!/bin/bash
set -e

# Run AR notebook
echo "Running AR/AR_Train_Dumas.ipynb..."
jupyter nbconvert --to notebook --execute "AR/AR_Train_Dumas.ipynb"
echo "Done AR"

# Run PCR notebook
echo "Running PCR/PCR_Train_Dumas.ipynb..."
jupyter nbconvert --to notebook --execute "PCR/PCR_Train_Dumas.ipynb"
echo "Done PCR"

# Run BPIC2017 notebook
echo "Running BPIC2017/BPIC_2017_Train_Dumas.ipynb..."
jupyter nbconvert --to notebook --execute "BPIC2017/BPIC_2017_Train_Dumas.ipynb"
echo "Done BPIC2017"

echo "All notebooks executed."
