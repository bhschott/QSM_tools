function err_subs = fade_qsm_loop_lambda_multi(volname, scanner_name)
% FADE_QSM_LOOP_LAMBDA_MULTI Reconstructs QSM with varying lambda values for multiple subjects.
%
%   err_subs = FADE_QSM_LOOP_LAMBDA_MULTI(volname, scanner_name) reconstructs QSM
%   with lambda values varying from 10^1 to 10^3.3 with a step size of 0.1 for
%   multiple subjects. This function iterates through each subject directory
%   and reconstructs QSM using the fade_qsm_loop_lambda function.
%
%   Inputs:
%   - volname: Name of the volume (default: 'ArmorATD').
%   - scanner_name: Name of the scanner ('verio', 'skyra', or 'skrep') (default: 'skyra').
%
%   Outputs:
%   - err_subs: Cell array containing the names of subjects for which an error occurred.
%
%   This function requires QSMbox and SPM12 toolboxes.
%
%   Example:
%       err_subs = fade_qsm_loop_lambda_multi('ArmorATD', 'skyra');
%
%   written by Bjoern Schott, 04/2024
%
%   See also: fade_qsm_loop_lambda

% Set default values for inputs if not provided
if nargin < 1
    volname = 'ArmorATD';
end
if nargin < 2
    scanner_name = 'skyra';
end

% Set project directories
project_dir = strcat('/Volumes/', volname, '/projects/FADE_2016/');
work_dir = strcat(project_dir, 'subjects_', scanner_name, '/');
tools_dir = strcat(project_dir, 'tools_BS/');

% Define QSM flag based on scanner name
switch scanner_name
    case 'verio'
        qsm_flag = 'SWI';
    case 'skyra'
        qsm_flag = 'QSM';
    case 'skrep'
        qsm_flag = 'QSM';
end

% Define additional directories
qsm_tools_dir = strcat(tools_dir, 'QSM_tools/');
qsm_defs_dir = strcat(qsm_tools_dir, 'defaults/');
spm_dir = which('spm'); spm_dir = spm_dir(1:end-5);

% Select subject directories
dir_names = spm_select(Inf, 'dir', work_dir);
subjnames = dir_names(:,end-3:end);

% Store current working directory
cwd = pwd;

% Initialize cell array to store subjects with errors
err_subs = {};


% Loop through each subject directory
for subject = 1 : size(dir_names,1)

    subj_id = subjnames(subject,:);
    fprintf('\nReconstructing QSM with lambda = 10^(1:1.1:3.3) for subject %s\n', subj_id)
    try
        subj_dir = strcat(work_dir, subj_id, '/');
        subj_qsm_dir = strcat(subj_dir, 'QSM_main/data/');
        cd(subj_qsm_dir)

        % Copy files from defaults directory to local directory
        % The defaults directory should contain all QSMbox files that should be
        % kept constant across subjects
        default_files = dir(qsm_defs_dir);

        % Loop through the files and copy them to the target directory
        for i = 1:length(default_files)
            % Skip directories '.' and '..'
            if strcmp(default_files(i).name, '.') || strcmp(default_files(i).name, '..')
                continue;
            end
            % Construct full paths for source and target files
            source_file = fullfile(qsm_defs_dir, default_files(i).name);
            target_file = fullfile(subj_qsm_dir, default_files(i).name);
            % Copy the file
            copyfile(source_file, target_file);
        end
        fade_qsm_loop_lambda;
    catch
        err_subs = [err_subs, subj_id];
    end

end

disp(err_subs)

end


