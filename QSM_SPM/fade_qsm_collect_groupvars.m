function [filename_list, age_covar, sex_covar, TIV_covar, scanner_covar] = fade_qsm_collect_groupvars(subj_list_file, image_dir, image_filename, test_type, group_var)
% FADE_QSM_COLLECT_GROUPVARS prepares data for group-level analysis in SPM
%
%   This function collects image filenames and relevant covariates from
%   a specified subject list for group-level analysis in SPM.
%
%   Usage:
%   [filename_list, age_covar, sex_covar, TIV_covar] = ...
%       fade_qsm_collect_groupvars(subj_list_file, image_dir, image_filename, test_type, group_var)
%
%   Input Arguments:
%   - subj_list_file: Path to a tab-separated subject list file containing
%       columns for subject IDs, scanner type, age, sex, age group, and TIV.
%   - image_dir: Relative directory path within each subject's folder where
%       the target image file is located (e.g., 'QSM_main/spm/').
%   - image_filename: Image filename pattern (e.g., '*.nii') to identify
%       target images in each subject's directory.
%   - test_type: Statistical test type, 1 for a 1-sample t-test or 2 for a
%       2-sample t-test.
%   - group_var: Variable used to divide subjects into groups if test_type
%       is 2; valid options are 'Age_Group', 'sex', or 'scanners'.
%
%   Output Arguments:
%   - filename_list: A cell array of full file paths to the images. For a
%       2-sample t-test, the cell array contains two subarrays for each group.
%   - age_covar: Array of subject ages, sorted to match the order in
%       filename_list.
%   - sex_covar: Array of subject sexes, sorted to match filename_list.
%   - TIV_covar: Array of TIV values, sorted to match filename_list.
%
%   Notes:
%   - If test_type is 2, subjects are divided by group_var into two groups.
%   - When 'scanners' is used as group_var, scanner = 3 is treated as scanner = 2
%     for covariate grouping only (not for directory paths).
%   - Subjects missing a target image file are excluded.
%
%   Example:
%   [filenames, age, sex, TIV] = fade_qsm_collect_groupvars('subjects_qsm_all_2024-11-01.txt', ...
%       'QSM_main/spm', 's6w_int16_MVSSM_749_39_2.nii', 2, 'Age_Group');
%
%   Dependencies:
%   Requires SPM installed and configured in MATLAB.

% Read subject list file using textread
[subject_ids, scanners, age, sex, age_group, TIV] = textread(subj_list_file, '%s%d%d%d%d%f', 'delimiter', '\t', 'headerlines', 1);

% Convert scanner value 3 to 2 only for covariate grouping
covariate_scanners = scanners;
covariate_scanners(covariate_scanners == 3) = 2;

% Initialize output variables
filename_list = {};
if test_type == 1
    age_covar = [];
    sex_covar = [];
    TIV_covar = [];
    scanner_covar = [];
elseif test_type == 2
    age_covar{1} = [];
    age_covar{2} = [];
    sex_covar{1} = [];
    sex_covar{2} = [];
    TIV_covar{1} = [];
    TIV_covar{2} = [];
    scanner_covar{1} = [];
    scanner_covar{2} = [];
end

% Check test_type validity
if test_type ~= 1 && test_type ~= 2
    error('Unsupported test type. Use 1 for 1-sample t-test or 2 for 2-sample t-test.');
end

% Set group_var for 1-sample t-test if undefined
if test_type == 1 && nargin < 5
    group_var = ''; % Set a default empty value for group_var
end

% Identify group variable based on input
switch group_var
    case 'Age_Group'
        group_data = age_group;
    case 'sex'
        group_data = sex;
    case 'scanners'
        group_data = covariate_scanners;
    otherwise
        if test_type == 2
            error('Unsupported group variable. Use Age_Group, sex, or scanners.');
        else
            group_data = []; % For 1-sample t-test, no grouping needed
        end
end

% Define indices for 2-sample t-test
if test_type == 2
    % Find indices for group 1 and group 2, and exclude other values
    group1_idx = find(group_data == 1);
    group2_idx = find(group_data == 2);
    valid_idx = [group1_idx; group2_idx];
else
    % For 1-sample t-test, include all subjects
    valid_idx = 1:length(subject_ids);
end

% Loop through valid subjects to construct file paths
for subj = 1:length(valid_idx)
    % Get the correct index from valid_idx
    idx = valid_idx(subj);

    % Ensure the current scanner value is valid and scalar
    current_scanner = scanners(idx);
    if isempty(current_scanner) || ~isnumeric(current_scanner) || ~isscalar(current_scanner)
        warning('Invalid scanner value for subject %s. Skipping...', subject_ids{idx});
        continue;
    end

    % Determine the base directory based on scanner type
    scanner_dir = '';
    switch current_scanner
        case 1
            scanner_dir = 'subjects_verio';
        case 2
            scanner_dir = 'subjects_skyra';
        case 3
            scanner_dir = 'subjects_skrep';
    end

    % Construct subject directory
    subj_dir = fullfile('/Volumes/ArmorATD/projects/FADE_2016', scanner_dir, subject_ids{idx}, image_dir);

    % Find image file with wildcard
    img_file_info = dir(fullfile(subj_dir, image_filename));
    if isempty(img_file_info)
        warning('Image not found for subject %s in directory %s.', subject_ids{idx}, subj_dir);
        continue;
    end
    img_file = fullfile(img_file_info(1).folder, img_file_info(1).name);  % Full path to image file

    % Append data based on test_type
    if test_type == 1
        % For 1-sample t-test, add directly to lists
        filename_list{end+1, 1} = img_file;
        age_covar = [age_covar; age(idx)];
        sex_covar = [sex_covar; sex(idx)];
        TIV_covar = [TIV_covar; TIV(idx)];
        current_scanner = scanners(idx);
        if current_scanner == 3
            current_scanner = 2;
        end
        scanner_covar = [scanner_covar current_scanner];
    elseif test_type == 2
        % For 2-sample t-test, sort into group cell arrays
        if ismember(idx, group1_idx)
            if isempty(filename_list)
                filename_list = {{img_file}, {}};
            else
                filename_list{1}{end+1, 1} = img_file;
            end
            age_covar{1}(end+1, 1) = age(idx);
            sex_covar{1}(end+1, 1) = sex(idx);
            TIV_covar{1}(end+1, 1) = TIV(idx);
            current_scanner = scanners(idx);
            if current_scanner == 3
                current_scanner = 2;
            end
            scanner_covar{1}(end+1, 1) = current_scanner;
        elseif ismember(idx, group2_idx)
            if isempty(filename_list)
                filename_list = {{}, {img_file}};
            else
                filename_list{2}{end+1, 1} = img_file;
            end
            age_covar{2}(end+1, 1) = age(idx);
            sex_covar{2}(end+1, 1) = sex(idx);
            TIV_covar{2}(end+1, 1) = TIV(idx);
            current_scanner = scanners(idx);
            if current_scanner == 3
                current_scanner = 2;
            end
            scanner_covar{2}(end+1, 1) = current_scanner;
        end
    end
end


fprintf('Data collection for group-level model setup completed.\n');
end
