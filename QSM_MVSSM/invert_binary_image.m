function invert_binary_image(input_filename, output_filename)
% INVERT_BINARY_IMAGE Inverts a binary NIFTI image.
%
% Usage:
%   invert_binary_image(input_filename, output_filename)
%
% Inputs:
%   input_filename  - String, the filename of the input binary NIFTI image.
%   output_filename - String, the filename for the output inverted binary NIFTI image.
%
% Description:
%   This function loads a binary NIFTI image, inverts the binary values (i.e.,
%   changes 0s to 1s and 1s to 0s), and saves the inverted image to the specified output file.
%
% written by Bjoern Hendrik Schott, 06/2024
% bjoern-hendrik.schott@dzne.de
%

if nargin < 2
    error('Please specify input and output filename');
end

% Load the binary NIFTI image
binary_img = spm_vol(input_filename);
binary_data = spm_read_vols(binary_img);

% Invert the binary image
inverted_data = 1 - binary_data;

% Save the inverted binary image
inverted_img = binary_img;
inverted_img.fname = output_filename;
spm_write_vol(inverted_img, inverted_data);

