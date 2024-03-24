function create_4D_nifti(output_filename, input_filenames, prefix, overwrite_flag)
% Function to create a 4D NIFTI file by merging multiple 3D NIFTI files.
%
% requires SPM12 installed and in the Matlab path
%
% Inputs:
%   - output_filename: Name of the output 4D NIFTI file.
%   - input_filenames: Either a directory containing 3D NIFTI files or a cell array of filenames.
%   - prefix (optional): Prefix to filter input filenames.
%   - overwrite_flag (optional): Flag to overwrite existing output file.
%
% Example usage:
%   create_4D_nifti('output.nii', '/path/to/files', 'prefix_', true);
%
% written by Bjoern H. Schott, 03/2024
% bjoern-hendrik.schott@dzne.de

% Check if SPM (Statistical Parametric Mapping) toolbox is installed

if ~exist('spm_file_merge', 'file')
    error('This function requires SPM (Statistical Parametric Mapping) toolbox to be installed.');
end

% Check if the output file already exists
if exist(output_filename, 'file') && (nargin < 4 || overwrite_flag)
    delete(output_filename); % Delete existing file if overwrite is requested
elseif exist(output_filename, 'file') && ~overwrite_flag
    error('Output file already exists. Please specify a different filename or delete the existing file.');
end

% Check if prefix is provided, if not, set it to empty string
if nargin < 3
    prefix = '';
end

% Get a list of input filenames based on the input type (directory or cell array)
if ischar(input_filenames) % If input_filenames is a directory
    nifti_files = dir(fullfile(input_filenames, '*.nii'));
    input_filenames = {nifti_files.name};
elseif iscell(input_filenames) % If input_filenames is a cell array
    % No need to do anything, assuming it's already a cell array of filenames
else
    error('Input filenames should be either a directory or a cell array.');
end

% Filter input filenames based on prefix
if ~isempty(prefix)
    input_filenames = input_filenames(startsWith(input_filenames, prefix));
end

% Merge the input NIFTI files into a single 4D NIFTI file
spm_file_merge(input_filenames, output_filename);

fprintf('4D NIFTI file created: %s\n', output_filename);
end
