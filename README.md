# QSM Processing Pipeline with QSMbox and SPM

This repository contains scripts and tools for processing Quantitative Susceptibility Mapping (QSM) data using QSMbox and Statistical Parametric Mapping (SPM). The scripts are designed to work in conjunction with the [QSMbox toolbox](https://gitlab.com/acostaj/QSMbox) and [SPM12 software](https://www.fil.ion.ucl.ac.uk/spm/software/spm12/).

For theoretical background on the Multi-Scale Dipole Inversion (MSDI) algorithm implemented in QSMbox and on the Macro-Vessel-Suppressed Susceptibility Mapping (MVSSM) contrast, please see Acosta-Cabronero et al., 2018: [DOI: 10.1016/j.neuroimage.2018.07.065](https://doi.org/10.1016/j.neuroimage.2018.07.065).

## Directories

### QSMbox_bugfix

Updates and bugfixes related to the QSM processing toolbox (QSMbox).

### defaults

Default parameter files and configurations used in QSM processing scripts.

### QSM_Import

Scripts and tools for importing QSM data into the processing pipeline.

### QSM_lambda_est

Scripts for the estimation of optimal lambda parameters for QSM calculations.

### QSM_estimate

Scripts for estimating QSM values given a fixed lambda.

### QSM_MVSSM

Tools and scripts for generating Macro-Vessel-Suppressed Susceptibility Maps (MVSSM) from QSM data using a customized method.

### QSM_SPM

Scripts and workflows integrating SPM for preprocessing, normalization, and smoothing of QSM and MVSSM images.

