function fade_qsm_create_overview(volname, scanner_name, qsm_filename, pdf_filename)
% FADE_QSM_CREATE_OVERVIEW generates an overview PDF of QSM images for subjects.
%
%   fade_qsm_create_overview(volname, scanner_name, qsm_filename, pdf_filename)
%
%   Inputs:
%   - volname (optional): Name of the volume where the project is stored (default: 'ArmorATD')
%   - scanner_name (optional): Name of the MRI scanner used (default: 'skyra')
%   - qsm_filename (optional): Filename of the QSM NIfTI image (default: 'mvssm_qsm_INTEGRAL_2_MSDI_l749.nii')
%   - pdf_filename (optional): Output PDF filename for saving the QSM image overview (default: 'QSM_images.pdf')
%
%   Example:
%   fade_qsm_create_overview('ArmorATD', 'skyra', 'mvssm_qsm_INTEGRAL_2_MSDI_l749.nii', 'QSM_images.pdf');
%
%   Notes:
%   - This function requores SPM12 in the MATLAB path.
%   - Middle slices of images are rotated 90 degrees to the left and saved to a PDF.
%   - The original images and directories are not modified.
%
%   written by Bjoern Hendrik Schott, 07/2024
%   bjoern-hendrik.schott@dzne.de
%


% User-defined parameters
if nargin < 1
    volname = 'ArmorATD';
end
if nargin < 2
    scanner_name = 'skyra';
end

% Define filename of image file to display
if nargin < 3
    qsm_filename = 'mvssm_qsm_INTEGRAL_2_MSDI_l749.nii'
end

% output filename
if nargin < 4
    pdf_filename = 'QSM_images.pdf';
end


% Define directories
project_dir = strcat('/Volumes/', volname, '/projects/FADE_2016/');
subjects_dir = strcat(project_dir, 'subjects_', scanner_name, '/');
tools_dir = strcat(project_dir, 'tools_BS/');
temp_dir = strcat(project_dir, 'images_tmp/');

% output filename
if nargin < 4
    pdf_filename = strcat(subjects_dir, 'QSM_images_', scanner_name, '.pdf');
end

mkdir(temp_dir);


% Select subject directories
dir_names = spm_select(Inf, 'dir', subjects_dir);
subjnames = dir_names(:,end-3:end);

% Initialize a cell array to store image data and subject IDs
images = {};

num_subjects = size(dir_names,1);
% Traverse directories and process images
for subj = 1:num_subjects
    subj_id = subjnames(subj,:);
    image_path = fullfile(subjects_dir, subj_id, 'QSM_main', 'SPM', qsm_filename);
    if exist(image_path, 'file')
        % Load NIfTI image using SPM functions
        V = spm_vol(image_path);
        nifti_data = spm_read_vols(V);

        % Extract a middle slice
        middle_slice = nifti_data(:, :, round(size(nifti_data, 3) / 2));

        % Rotate the slice 90 degrees to the left (the original image remains unchanged
        rotated_slice = imrotate(middle_slice, 90);

        % Store the slice and subject ID
        images{end+1} = struct('id', subj_id, 'slice', rotated_slice);
    else
        fprintf('No image found for subject %s\n', subj_id)
    end
end

% Increase canvas size for saving figures
figure_size = [100, 100, 1200, 900];  % [left, bottom, width, height]

% Create a figure to save images
figure('Position', figure_size);


% Initialize a new PDF
if exist(pdf_filename, 'file')
    delete(pdf_filename);
end

% Loop through the images and add them to the PDF
for i = 1:length(images)
    % Plot the image
    imshow(images{i}.slice, []);
    title(['Subject ID: ', images{i}.id]);

    % Save the current figure as a temporary PNG file
    temp_png = fullfile(tempdir, [images{i}.id, '.png']);
    exportgraphics(gca, temp_png);

    % Add the PNG to the PDF
    % Escape underscores in the filename for the title
    [~, name, ext] = fileparts(qsm_filename);
    title_line = strrep([name, ext], '_', '\_');
    title_line = sprintf('filename: %s', title_line);
    append_image_to_pdf(pdf_filename, temp_png, title_line);

    % Clean up the temporary PNG file
    delete(temp_png);
end

% Close the figure
close(gcf);

end

% Function to append images to a PDF
function append_image_to_pdf(pdf_filename, image_filename, title_line)

    title_font_size = 10;
    % Read the image
    img = imread(image_filename);

    % Convert to grayscale if necessary
    if size(img, 3) == 1
        img = repmat(img, [1, 1, 3]);
    end

    % Create a new figure for the PDF
    figure('Visible', 'off');
    imshow(img);
    title(title_line, 'FontSize', title_font_size);

    % Save the figure to the PDF
    exportgraphics(gca, pdf_filename, 'Append', true);
    close(gcf);
end