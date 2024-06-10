function err_subs = fade_qsm_estimate_multi(volname, scanner_name, lambda)
% FADE_ESTIMATE_MULTI Reconstructs QSM with given lambda values for multiple subjects.
%
%   err_subs = FADE_QSM_ESTIMATE_MULTI(volname, scanner_name) reconstructs QSM
%   with a given lambda value, which should be determined before.
%   This function iterates through each subject directory
%   and reconstructs QSM using the fade_qsm_estimate function.
%
%   Inputs:
%   - volname: Name of the volume (default: 'ArmorATD').
%   - scanner_name: Name of the scanner ('verio', 'skyra', or 'skrep') (default: 'skyra').
%   - lambda: regularization parameter, needs to be determined before
%
%   Outputs:
%   - err_subs: Cell array containing the names of subjects for which an error occurred.
%
%   This function requires QSMbox and SPM12 toolboxes.
%
%   Example:
%       err_subs = fade_qsm_estimate_multi('ArmorATD', 'skyra', 749);
%
%   written by Bjoern Schott, 05/2024
%
%   See also: fade_qsm_estimate

% Set default values for inputs if not provided
if nargin < 1
    volname = 'ArmorATD';
end
if nargin < 2
    scanner_name = 'skyra';
end
if nargin < 3
    lambda = 749;  % determined from L-curve reconstruction in 32 subjects
end

% Set project directories
project_dir = strcat('/Volumes/', volname, '/projects/FADE_2016/');
work_dir = strcat(project_dir, 'subjects_', scanner_name, '/');
tools_dir = strcat(project_dir, 'tools_BS/');
use_dir_pref = 'use_002_def_msdi2*';
destname = strcat('QSM_lambda_', num2str(lambda));

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
    fprintf('\nReconstructing QSM with lambda = %d for subject %s\n', lambda, subj_id)
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
        % run QSM estimation
        fade_qsm_estimate(lambda);
        % rename QSM data directory
        use_dir_list = dir(use_dir_pref);
        srcname = use_dir_list(end).name;
        movefile(srcname, destname);
    catch
        err_subs = [err_subs, subj_id];
    end

end

disp(err_subs)

end


