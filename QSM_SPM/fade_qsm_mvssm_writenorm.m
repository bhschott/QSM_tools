function err_subs = fade_qsm_mvssm_writenorm(volname, scanner_name, skullstrip)
% FADE_QSM_MVSSM_WRITENORM Write normalized QSM images from existing deformation fields.
%
% The function processes multiple subjects' data from the specified directories.
%
% Outputs:
%   err_subs - Cell array containing the subject IDs that encountered errors during processing.
%
% Dependencies:
%   - SPM12 (Statistical Parametric Mapping)
%   - fade_qsm_calculate_mvssm, fade_qsm_create_mask, fade_qsm_convert_int16 functions
%
% Example:
%   err_subs = fade_qsm_mvssm_spm;
%
% written by Bjoern Hendrik Schott, 11/2024
%

% User-defined parameters
if nargin < 1
    volname = 'ArmorATD';
end
if nargin < 2
    scanner_name = 'skyra';
end
if nargin < 3
    skullstrip = 0;
end

project_dir = strcat('/Volumes/', volname, '/projects/FADE_2016/');
subjects_dir = strcat(project_dir, 'subjects_', scanner_name, '/')
tools_dir = strcat(project_dir, 'tools_BS/');

% Define additional directories and filenames
qsm_tools_dir = strcat(tools_dir, 'QSM_tools/');
qsm_defs_dir = strcat(qsm_tools_dir, 'defaults/');
spm_dir = which('spm'); spm_dir = spm_dir(1:end-5);
high_lambda_dirname = 'QSM_lambda_749';
low_lambda_dirname = 'QSM_lambda_39_2';
clean_mvssm_filename = strcat('int16_MVSSM', high_lambda_dirname(11:end), low_lambda_dirname(11:end), '.nii')

% read subject directories for batch processing
dir_names = spm_select(Inf,'dir',subjects_dir);
subjnames = dir_names(:,end-3:end);

cwd = pwd;
err_subs = {};

% inner loop
for subject = 1 : size(dir_names,1)

    subj_id=subjnames(subject,:);
    disp(['Normalizing and smoothing QSM/MVSSM for ' subj_id]);

    try
        qsm_dir = strcat(subjects_dir, subj_id, '/QSM_main/');
        cd(qsm_dir)
        qsm_data_dir = strcat(qsm_dir, 'data/');
        qsm_spm_dir = strcat(qsm_dir, 'spm/');
        cd(qsm_spm_dir)
        % run SPM normalization based on MPRAGE image and smoothing
        clear matlabbatch
        date_dir = dir(strcat(subjects_dir, subj_id, '/20*'));
        mpragedir = dir(strcat(subjects_dir, subj_id, '/', date_dir.name, '/dzne_MPRAGE_1iso_PAT2_0*'));
        if skullstrip
            def_field_file = dir(strcat(subjects_dir, subj_id, '/', date_dir.name, '/', mpragedir.name, '/y_str_s20*.nii'));
        else
            def_field_file = dir(strcat(subjects_dir, subj_id, '/', date_dir.name, '/', mpragedir.name, '/y_s20*.nii'));
        end
        mpragefilename = strcat(subjects_dir, subj_id, '/', date_dir.name, '/', mpragedir.name, '/', def_field_file.name);
        % using skull stripping may improve co-registration, but occasionally fails segmentation
        def_field_filename = strcat(subjects_dir, subj_id, '/', date_dir.name, '/', mpragedir.name, '/', def_field_file.name);
        % SPM normalize
        matlabbatch{1}.spm.spatial.normalise.write.subj.def = {def_field_filename};
        matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {strcat(qsm_spm_dir, clean_mvssm_filename, ',1')};
        matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                                   78   76  85];
        matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [1 1 1];
        matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 7;
        matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w_';
        matlabbatch{2}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
        matlabbatch{2}.spm.spatial.smooth.fwhm = [4 4 4];
        matlabbatch{2}.spm.spatial.smooth.dtype = 0;
        matlabbatch{2}.spm.spatial.smooth.im = 0;
        matlabbatch{2}.spm.spatial.smooth.prefix = 's4';
        matlabbatch{3}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
        matlabbatch{3}.spm.spatial.smooth.fwhm = [6 6 6];
        matlabbatch{3}.spm.spatial.smooth.dtype = 0;
        matlabbatch{3}.spm.spatial.smooth.im = 0;
        matlabbatch{3}.spm.spatial.smooth.prefix = 's6';
        % run SPM job manager
        save(strcat(subj_id, '_norm-write_smooth.mat'));
        spm_jobman('run', strcat(subj_id, '_norm-write_smooth.mat'));
    catch
        ers = lasterror;
        disp(['Error in subject ' subj_id])
        err_subs = [err_subs subj_id];
    end

end

cd(cwd)
