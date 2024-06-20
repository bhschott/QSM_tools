
volname = 'bschott';
scanner_name = 'skyra';
subj_id = 'ad30';

project_dir = strcat('/Users/', volname, '/projects/FADE_2016/');
subjects_dir = strcat(project_dir, 'subjects_', scanner_name, '/');
tools_dir = strcat(project_dir, 'tools_BS/');

% Define additional directories
qsm_tools_dir = strcat(tools_dir, 'QSM_tools/');
qsm_defs_dir = strcat(qsm_tools_dir, 'defaults/');
spm_dir = which('spm'); spm_dir = spm_dir(1:end-5);

% directories and image files generated with QSMbox batch 
high_lambda_dirname = 'QSM_lambda_749';
low_lambda_dirname = 'QSM_lambda_39_2';
high_lambda_filename = 'qsm_INTEGRAL_2_MSDI_l749.nii';
low_lambda_filename = 'qsm_INTEGRAL_2_MSDI_l39.nii';
dest_filename = strcat('mvssm_', high_lambda_filename);

% inner loop

qsm_dir = strcat(subjects_dir, subj_id, '/QSM_main/');
cd(qsm_dir)
mkdir spm

qsm_data_dir = strcat(qsm_dir, 'data/');
qsm_spm_dir = strcat(qsm_dir, 'spm/');
qsm_hl_dir = strcat(qsm_data_dir, high_lambda_dirname, '/');
qsm_hl_image = strcat(qsm_hl_dir, high_lambda_filename);
qsm_ll_dir = strcat(qsm_data_dir, low_lambda_dirname, '/');
qsm_ll_image = strcat(qsm_ll_dir, low_lambda_filename);

copyfile(qsm_hl_image, qsm_spm_dir)
copyfile(qsm_ll_image, qsm_spm_dir)

cd(qsm_spm_dir)
% binarize high-pass (low lambda) image
std_cutoff = 1.5; % in standard deviations
fwhm = 1.6; % voxel size * 2
smoothed_cutoff = 0.5;
bin_low_lambda_filename = strcat('b_', low_lambda_filename);
fade_qsm_calculate_mvssm(low_lambda_filename, bin_low_lambda_filename, dest_filename, std_cutoff, fwhm, smoothed_cutoff);

