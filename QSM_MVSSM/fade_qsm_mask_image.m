function fade_qsm_mask_image(input_filename, inverted_mask_filename, output_filename)
% FADE_QSM_MASK_IMAGE Applies an inverted binary mask to a broad-band NIFTI image.
%
% Usage:
%   fade_qsm_mask_image(input_filename, inverted_mask_filename, output_filename)
%
% Inputs:
%   input_filename        - String, the filename of the input broad-band NIFTI image.
%   inverted_mask_filename - String, the filename of the inverted binary mask NIFTI image.
%   output_filename       - String, the filename for the output masked NIFTI image.
%
% Outputs:
%   None (The result is saved to the specified output file).
%
% Example:
%   fade_qsm_mask_image('broadband_image.nii', 'inverted_mask.nii', 'masked_output.nii');
%
% Description:
%   This function loads a source NIFTI image and an inverted binary mask NIFTI image,
%   multiplies them to apply the mask to the source image, and saves the resulting
%   masked image as target image to the specified output file.
%
% written by Bjoern Hendrik Schott, 06/2024
% bjoern-hendrik.schott@dzne.de
%



if nargin < 3
    error('Please specify broadband image, inverted mask image, and output filename');
end

% Load the broad-band NIFTI image
broadband_img = spm_vol(input_filename);
broadband_data = spm_read_vols(broadband_img);

% Load the inverted binary NIFTI image
inverted_mask_img = spm_vol(inverted_mask_filename);
inverted_mask_data = spm_read_vols(inverted_mask_img);

% Multiply the inverted binary mask with the broad-band image
masked_data = broadband_data .* inverted_mask_data;

% Save the masked image
masked_img = broadband_img;
masked_img.fname = output_filename;
spm_write_vol(masked_img, masked_data);

end
