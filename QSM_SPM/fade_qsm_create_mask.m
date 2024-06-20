function fade_qsm_create_mask(input_filename, output_filename, fwhm, num_iter)
% FADE_QSM_CREATE_MASK Smooths the image, then binarizes it, iteratively.
%
% Usage:
%   fade_qsm_create_mask(input_filename, output_filename, fwhm, num_iter)
%
% Inputs:
%   input_filename  - String, the filename of the input NIFTI image.
%   output_filename - String, the filename for the resulting mask.
%   fwhm            - Scalar, the full-width at half maximum (FWHM) for Gaussian smoothing in mm (default: 4).
%   num_iter        - Integer, the number of smoothing and binarization iterations (default: 3).
%
% Outputs:
%   None (The result is saved to the specified output file).

% Default smoothing kernel = 4 mm
if nargin < 3
    fwhm = 4;
end

% Default number of iterations = 3
if nargin < 4
    num_iter = 3;
end

% Load NIFTI image
original_img = spm_vol(input_filename);
original_data = spm_read_vols(original_img);

% Step 1: Initial smoothing and binarization
smoothed_data = original_data;
for i = 1:num_iter
    % Create a temporary NIFTI structure for smoothing
    temp_img = original_img;
    temp_img.fname = 'temp_smooth.nii';
    spm_write_vol(temp_img, smoothed_data);
    
    % Smooth the image
    spm_smooth(temp_img, temp_img, fwhm);
    
    % Load the smoothed data
    smoothed_data = spm_read_vols(temp_img);
    
    % Binarize the smoothed data
    smoothed_data = smoothed_data ~= 0;
end

% Step 2: Create the final binary mask
binary_mask = smoothed_data;

% Save the binary mask
binary_mask_img = original_img;
binary_mask_img.fname = output_filename;
spm_write_vol(binary_mask_img, binary_mask);

% Clean up temporary file
delete('temp_smooth.nii');

end
