## TaskExecutionTimeMining-gamlss

This repository demonstrates the use of GAMLSS (Generalized Additive Models for Location, Scale and Shape) to train models on given datasets for the prediction of business process event durations. The goal is to evaluate GAMLSS-based models against standard duration models using real and synthetic event logs.

The project builds on the idea of DR-BART but replaces its core with GAMLSS, implemented in R and integrated via Python for training, simulation, and evaluation.


### Usage

To test GAMLSS-based BPS modeling, follow these steps:


### 1 Clone the repository, download data, install dependencies
- git clone https://github.com/your-user/TaskExecutionTimeMining-gamlss.git
- cd TaskExecutionTimeMining-gamlss
- pipenv install
- pipenv shell

Note: The data/ folder is not versioned due to its size. You’ll need to train the required logs as described below.


### 2 Train GAMLSS models

Training PIX framework
Run the script src/notebooks/run_all_train_dumas.sh to train models using the Python-based PIX framework.
(This is required before running any evaluation notebooks.)

This will generate the corresponding .pickle model files used for later evaluation.

Training GAMLSS framework:
All GAMLSS models are trained using R scripts.

Navigate to the models/ folder and run the relevant R files to retrain models.

Subfolders are organized by:
- Dataset (AR, PCR, BPIC2017)
- Distribution family (gamma, lognorm, etc.)

Inside each subfolder, you’ll find several scripts — each trains a different parameter combination.

Output files (e.g. predictions and model fits) will be saved in the data/ folder, inside the appropriate data/predictions_* subfolder.

For each parameter combination, a training and test dataset will be created automatically.

### 3 Evaluate results
To evaluate the trained models, run the corresponding evaluation Jupyter notebooks, located in:
- src/notebooks/AR
- src/notebooks/PCR
- src/notebooks/BPIC2017

Each evaluation notebook attempts to load all available parameter combinations from the relevant data/predictions_* folder.

For example: AR_evaluation_gamma.ipynb will evaluate all files in data/predictions_gamma/
