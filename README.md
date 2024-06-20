# QSM Processing Pipeline with QSMbox and SPM

This repository contains scripts and tools for processing Quantitative Susceptibility Mapping (QSM) data using QSMbox and Statistical Parametric Mapping (SPM). The scripts are designed to work in conjunction with the [QSMbox toolbox](https://gitlab.com/acostaj/QSMbox) and [SPM12 software](https://www.fil.ion.ucl.ac.uk/spm/software/spm12/).

For theoretical background on the Multi-Scale Dipole Inversion (MSDI) algorithm implemented in QSMbox and on the Macro-Vessel-Suppressed Susceptibility Mapping (MVSSM) contrast, please see Acosta-Cabronero et al., 2018: [DOI: 10.1016/j.neuroimage.2018.07.065](https://doi.org/10.1016/j.neuroimage.2018.07.065).

## Directories

### QSMbox_bugfix

Bugfixes performed on QSMbox to run on Matlab R2023a on MacOS.

### defaults

Default QSMbox processing scripts and parameter files.

### QSM_Import

Scripts and tools for importing DICOM files, adjusting the filenames for uncombined data (i.e., images saved separately for each channel).

### QSM_lambda_est

Scripts for the estimation of optimal lambda (regularization parameter).

### QSM_estimate

Scripts for reconstructing QSM images given a fixed lambda.

### QSM_MVSSM

Scripts for generating Macro-Vessel-Suppressed Susceptibility Maps (MVSSM) from QSM images. Requires a high-lambda and a low-lambda QSM.

### QSM_SPM

SPM preprocessing (co-registration, normalization, and smoothing) of QSM / MVSSM images.

