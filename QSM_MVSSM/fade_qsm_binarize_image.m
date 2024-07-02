function fade_qsm_binarize_image(input_filename, output_filename, std_cutoff, fwhm, smoothed_cutoff, twosided)
% FADE_QSM_BINARIZE_IMAGE Binarizes a NIFTI image based on a threshold and optionally applies Gaussian smoothing.
%
% Usage:
%   fade_qsm_binarize_image(input_filename, output_filename, std_cutoff, fwhm, smoothed_cutoff)
%
% Inputs:
%   input_filename    - String, the filename of the input NIFTI image.
%   output_filename   - String, the filename for the output binarized NIFTI image.
%   std_cutoff        - (Optional) Scalar, threshold in terms of standard deviations above the mean (default: 2.5).
%   fwhm              - (Optional) Scalar, full-width at half maximum (FWHM) for Gaussian smoothing in mm (default: 0, no smoothing).
%   smoothed_cutoff   - (Optional) Scalar, threshold for binarizing the smoothed image (default: 0.5).
%   twosided          - (Optional) Flag, also include very low susceptibility values in mask (default: 0).
%
% Description:
%   This function binarizes a high-pass NIFTI image based on a threshold defined
%   as a multiple of the standard deviation above the mean. Optionally, it can
%   apply Gaussian smoothing to the binary mask and re-threshold the smoothed
%   image to obtain a final binary mask.
%   The resulting binary mask is saved to the specified output file.
%
% written by Bjoern Hendrik Schott, 06/2024
% bjoern-hendrik.schott@dzne.de
%


if nargin < 2
    error('Please specify input and output filename');
end

% Default cut-off for masking in standard deviations
if nargin < 3
    std_cutoff = 2.5;
end

% Default full-width at half maximum (FWHM) for Gaussian smoothing (in mm)
if nargin < 4
    fwhm = 0;
end

% Default cut-off for binarizing of smoothed image
if nargin < 5
    smoothed_cutoff = 0.5;
end

% twosided: also include very low susceptibility values in binarized mask
if nargin < 6
    twosided = 0;
end

% Load NIFTI image
high_pass_img = spm_vol(input_filename);
high_pass_data = spm_read_vols(high_pass_img);

% Calculate mean and standard deviation
mean_val = mean(high_pass_data(:));
std_val = std(high_pass_data(:));

% Set threshold for binarization
threshold = mean_val + std_cutoff * std_val;
disp(['Mean: ', num2str(mean_val), ', Std: ', num2str(std_val), ', Threshold: ', num2str(threshold)]);  % Debug: Display mean, std, and threshold

% Create binary mask
if twosided
    binary_mask = abs(high_pass_data) > threshold;
else
    binary_mask = high_pass_data > threshold;
end

% Apply Gaussian smoothing using SPM
if fwhm > 0
    % Save the binary mask temporarily
    temp_mask_img = high_pass_img;
    temp_mask_img.fname = 'temp_mask.nii';
    spm_write_vol(temp_mask_img, binary_mask);
    % SPM smoothing
    smoothed_mask_img = high_pass_img;
    smoothed_mask_img.fname = 'smoothed_mask.nii';
    spm_smooth(temp_mask_img, smoothed_mask_img, fwhm);
    % Load the smoothed mask
    smoothed_mask_data = spm_read_vols(smoothed_mask_img);
    % Threshold the smoothed mask to get final binary mask
    final_binary_mask = smoothed_mask_data > smoothed_cutoff;
else
    final_binary_mask = binary_mask;
end
    
% Save the final binary mask
final_binary_mask_img = high_pass_img;
final_binary_mask_img.fname = output_filename;
spm_write_vol(final_binary_mask_img, final_binary_mask);

% Clean up temporary files
delete('temp_mask.nii');
delete('smoothed_mask.nii');


