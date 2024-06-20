function fade_qsm_calculate_mvssm(high_lambda_filename, low_lambda_filename, dest_filename, std_cutoff, fwhm, smoothed_cutoff)
% FADE_QSM_CALCULATE_MVSSM Creates macro-vessel-suppressed susceptibility mapping (MVSSM) images.
%
% Usage:
%   fade_qsm_calculate_mvssm(high_lambda_filename, low_lambda_filename, dest_filename, std_cutoff, fwhm, smoothed_cutoff)
%
% Inputs:
%   high_lambda_filename - String, the filename of the input high-lambda NIFTI image.
%   low_lambda_filename  - String, the filename of the input low-lambda NIFTI image.
%   dest_filename        - String, the filename for the output MVSSM NIFTI image.
%   std_cutoff           - (Optional) Scalar, threshold in terms of standard deviations above the mean for binarization (default: 2.5).
%   fwhm                 - (Optional) Scalar, full-width at half maximum (FWHM) for Gaussian smoothing in mm (default: 0, no smoothing).
%   smoothed_cutoff      - (Optional) Scalar, threshold for binarizing the smoothed image (default: 0.5).
%
% Outputs:
%   None (The result is saved to the specified output file).
%
% Example:
%   fade_qsm_calculate_mvssm('high_lambda.nii', 'low_lambda.nii', 'mvssm_output.nii', 2.5, 2, 0.5);
%
% Description:
%   This function creates macro-vessel-suppressed susceptibility mapping (MVSSM) images
%   by performing the following steps:
%     1. Binarizes the low-lambda image based on a specified threshold.
%     2. Inverts the binarized low-lambda image.
%     3. Applies the inverted binary mask to the high-lambda image to create the MVSSM image.
%   The resulting MVSSM image is saved to the specified output file.
%
% written by Bjoern Hendrik Schott, 06/2024
% bjoern-hendrik.schott@dzne.de
%


if nargin < 3
    error('Please specify input and output filenames');
end

% Default cut-off for masking in standard deviations
if nargin < 4
    std_cutoff = 2.5;
end

% Default full-width at half maximum (FWHM) for Gaussian smoothing (in mm)
if nargin < 5
    fwhm = 0;
end

% Default cut-off for binarizing of smoothed image
if nargin < 6
    smoothed_cutoff = 0.5;
end

% add prefix to binary files
[dirr fname extt] = fileparts(low_lambda_filename);
bin_low_lambda_filename = fullfile(dirr, strcat('b_', low_lambda_filename));
ibin_low_lambda_filename = fullfile(dirr, strcat('ib_', low_lambda_filename));


% binarize low-lambda image
fade_qsm_binarize_image(low_lambda_filename, bin_low_lambda_filename, std_cutoff, fwhm, smoothed_cutoff);

% invert binarized image
invert_binary_image(bin_low_lambda_filename, ibin_low_lambda_filename);

% mask high-lamba image with inverted binarized image
fade_qsm_mask_image(high_lambda_filename, ibin_low_lambda_filename, dest_filename);