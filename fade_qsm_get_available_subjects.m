function fade_qsm_get_available_subjects(volname)
% FADE_QSM_GET_AVAILABLE_SUBJECTS generates an tab-separated text file of subjects with available QSM images.
%
%   fade_qsm_get_available_subjects(volname)
%
%   Inputs:
%   - volname (optional): Name of the volume where the project is stored (default: 'ArmorATD')
%
%   Notes:
%   - creates file lists of subjects with complete data.
%   - sorted by age group.
%
%   written by Bjoern Hendrik Schott, 11/2024
%   bjoern-hendrik.schott@dzne.de

% User-defined parameters
if nargin < 1
    volname = 'ArmorATD';
end
project_dir = strcat('/Volumes/', volname, '/projects/FADE_2016/');
tools_dir = strcat(project_dir, 'tools_BS/');
qsm_tools_dir = strcat(tools_dir, 'QSM_tools/');
scanner_names = {'verio', 'skyra', 'skrep'};
scanner_dirs = {'subjects_verio', 'subjects_skyra', 'subjects_skrep'};

% read subject information
subj_list_file = strcat(tools_dir, 'subjects_all_2024-11-01.txt');
[scanners subj_ids age sex age_group AiA_yFADE AiA young older male female Verio Skyra] = textread(subj_list_file, '%d%s%d%d%d%d%d%d%d%d%d%d%d', 'delimiter', '\t', 'headerlines', 1);
subj_list_tiv_file = strcat(tools_dir, 'subjects_all_TIV_2024-10-25.txt');
[subj_ids_tiv, TIVs] = textread(subj_list_tiv_file, '%s%f', 'delimiter', '\t', 'headerlines', 1);

% sort TIVs by subject IDs from the first file
TIVs_sorted = NaN(size(subj_ids));  
[is_in_tiv_list, idx_in_tiv_list] = ismember(subj_ids, subj_ids_tiv);
TIVs_sorted(is_in_tiv_list) = TIVs(idx_in_tiv_list(is_in_tiv_list));
if any(~is_in_tiv_list)
    fprintf('Warning: TIV not found for %d subject(s):\n', sum(~is_in_tiv_list));
    disp(subj_ids(~is_in_tiv_list));
end

% Check for available QSM and GMV files
qsm_filename = 'QSM_main/spm/s6w_int16_MVSSM_749_39_2.nii';
gmv_filename_template = 'QSM_main/spm/GMV/mwp1%s_MPRAGE.nii';

% Initialize exist_qsm and exist_gmv arrays
exist_qsm = zeros(size(subj_ids));
exist_gmv = zeros(size(subj_ids));

% Check for the presence of files for each subject
for i = 1:length(subj_ids)
    subj_id = subj_ids{i};
    scanner_dir = scanner_dirs{scanners(i)}; % Get the directory based on scanner
    qsm_path = fullfile(project_dir, scanner_dir, subj_id, qsm_filename);
    gmv_path = fullfile(project_dir, scanner_dir, subj_id, sprintf(gmv_filename_template, subj_id)); 
    % Check QSM 
    if exist(qsm_path, 'file')
        exist_qsm(i) = 1;
    end
    % Check GMV 
    if exist(gmv_path, 'file')
        exist_gmv(i) = 1;
    end
end

% Define output filename
output_file = strcat(qsm_tools_dir, 'subjects_qsm_all_2024-11-01.txt');

% Open the output file for writing
fid = fopen(output_file, 'w');

% Write header line
fprintf(fid, 'Subject_ID\tScanner\tAge\tSex\tAge_Group\tTIV\n');

% Loop through subjects and write eligible ones to the file
for i = 1:length(subj_ids)
    % Check if both QSM and GMV files exist for this subject
    if exist_qsm(i) == 1 && exist_gmv(i) == 1
        % Write the subject details to the file
        fprintf(fid, '%s\t%d\t%d\t%d\t%d\t%.2f\n', subj_ids{i}, scanners(i), age(i), sex(i), age_group(i), TIVs_sorted(i));
    end
end

% Close the file
fclose(fid);

fprintf('Clean subject list file created: %s\n', output_file);

% Define output filenames for Verio and Skyra/Skrep groups
output_file_verio = strcat(qsm_tools_dir, 'subjects_qsm_verio_2024-11-01.txt');
output_file_skyra_skrep = strcat(qsm_tools_dir, 'subjects_qsm_skyra_2024-11-01.txt');

% Open output files for writing
fid_verio = fopen(output_file_verio, 'w');
fid_skyra_skrep = fopen(output_file_skyra_skrep, 'w');

% Write header line to each file
header = 'Subject_ID\tScanner\tAge\tSex\tAge_Group\tTIV\n';
fprintf(fid_verio, header);
fprintf(fid_skyra_skrep, header);

% Loop through subjects and write eligible ones to the appropriate file
for i = 1:length(subj_ids)
    % Check if both QSM and GMV files exist for this subject
    if exist_qsm(i) == 1 && exist_gmv(i) == 1
        % Determine the correct file based on the scanner type
        if scanners(i) == 1  % Verio
            fprintf(fid_verio, '%s\t%d\t%d\t%d\t%d\t%.2f\n', subj_ids{i}, scanners(i), age(i), sex(i), age_group(i), TIVs_sorted(i));
        elseif scanners(i) == 2 || scanners(i) == 3  % Skyra or Skrep
            fprintf(fid_skyra_skrep, '%s\t%d\t%d\t%d\t%d\t%.2f\n', subj_ids{i}, scanners(i), age(i), sex(i), age_group(i), TIVs_sorted(i));
        end
    end
end

% Close files
fclose(fid_verio);
fclose(fid_skyra_skrep);

fprintf('Separate subject lists created:\n Verio: %s\n Skyra/Skrep: %s\n', output_file_verio, output_file_skyra_skrep);
