function fade_qsm_copy_gmv_maps
%   Copy GMV maps from VBM processing directory to individual subjects'
%   QSM directories (in a subfolder 'GMV').
%   Can be adapted to copy other files from a single directory to
%   distributed subject directories.
%
%   known issues:
%   - the presence of one subject ID in multiple scanner directories is 
%     not yet handled
%
%   written by Bjoern Hendrik Schott, 10/2024
%   bjoern-hendrik.schott@dzne.de
%

% Directories and filename patterns
vbm_data_dir = '/Volumes/ArmorATD/projects/FADE_2016/VBM_data_2024/T1_clean_data/mri/';
project_dir = '/Volumes/ArmorATD/projects/FADE_2016/';
scanner_dirs = {'subjects_skrep', 'subjects_skyra', 'subjects_verio'};
gmv_pattern = 'mwp1*_MPRAGE.nii';

% Search for GMV map files in the VBM data directory
gmv_files = dir(fullfile(vbm_data_dir, gmv_pattern));

% Process each GMV file
for i = 1:length(gmv_files)
    % Extract subject ID from the filename (e.g., 'ab01' from 'mwp1ab01_MPRAGE.nii')
    filename = gmv_files(i).name;
    subj_id = filename(5:8);

    % Define source path
    source_path = fullfile(vbm_data_dir, filename);
    target_path_found = false;

    % Check each scanner directory for the subject's folder
    for j = 1:length(scanner_dirs)
        subj_dir = fullfile(project_dir, scanner_dirs{j}, subj_id, 'QSM_main', 'spm', 'GMV');

        % If the subject directory exists in this scanner directory, copy the file
        if exist(fileparts(subj_dir), 'dir')
            % Create target directory if it doesn't exist
            if ~exist(subj_dir, 'dir')
                mkdir(subj_dir);
            end

            % Define full target path
            target_path = fullfile(subj_dir, filename);

            % Copy GMV map to the target directory
            copyfile(source_path, target_path);

            % Display progress and mark as found
            fprintf('Copied %s to %s\n', filename, target_path);
            target_path_found = true;
            break;
        end
    end

    % If no target path is found, print a warning
    if ~target_path_found
        fprintf('Warning: No subject directory found for %s\n', subj_id);
    end
end

disp('All GMV maps have been processed.');
end
