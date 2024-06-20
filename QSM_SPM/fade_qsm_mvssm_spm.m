function err_subs = fade_qsm_mvssm_spm
% FADE_QSM_MVSSM_SPM Creates a mask from QSM images, processes them, and runs SPM normalization and smoothing.
%
% This function automates the pipeline for QSM processing, including:
% 1. Generating MVSSM images
% 2. Creating binary masks
% 3. Converting images to int16 format
% 4. Masking the images
% 5. Performing SPM normalization and smoothing
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
% written by Bjoern Hendrik Schott, 06/2024
%

% User-defined parameters
volname = 'ArmorATD';
scanner_name = 'skyra';

% Define project, subject, tools, and DICOM directories
project_dir = strcat('/Volumes/', volname, '/projects/FADE_2016/');
subjects_dir = strcat(project_dir, 'subjects_', scanner_name, '/');
tools_dir = strcat(project_dir, 'tools_BS/');
switch scanner_name
    case 'verio'
        dicom_dir = strcat(project_dir, 'incoming_dicoms/dicom_verio/');
    case 'skyra'
        dicom_dir = strcat(project_dir, 'incoming_dicoms/dicom_skyra/');
    case 'skrep'
        dicom_dir = strcat(project_dir, 'incoming_dicoms/dicom_skrep/');
end

% Define additional directories and filenames
qsm_tools_dir = strcat(tools_dir, 'QSM_tools/');
qsm_defs_dir = strcat(qsm_tools_dir, 'defaults/');
spm_dir = which('spm'); spm_dir = spm_dir(1:end-5);

high_lambda_dirname = 'QSM_lambda_749';
low_lambda_dirname = 'QSM_lambda_39_2';
high_lambda_filename = 'qsm_INTEGRAL_2_MSDI_l749.nii';
low_lambda_filename = 'qsm_INTEGRAL_2_MSDI_l39.nii';
mvssm_filename = strcat('mvssm_', high_lambda_filename);

% Parameters for MVSSM generation
std_cutoff = 1.5; % in standard deviations
fwhm = 1.6; % voxel size * 2
smoothed_cutoff = 0.5;

% Parameters for integer conversion
scaling_factor = 1000;

% Parameters for mask generation
fwhm_m = 2;
num_iter = 2;

% Get subject directories
dir_names = spm_select(Inf,'dir',subjects_dir);
subjnames = dir_names(:,end-3:end);

cwd = pwd;
err_subs = {};

% Process each subject
for subject = 1 : size(dir_names,1)

    clear matlabbatch dicom_list

    subj_id = subjnames(subject,:);
    disp(['Creating MVSSM and running SPM pre-processing for ' subj_id]);

    try
        % Define subject-specific directories
        qsm_dir = strcat(subjects_dir, subj_id, '/QSM_main/');
        cd(qsm_dir)
        mkdir spm

        qsm_data_dir = strcat(qsm_dir, 'data/');
        qsm_spm_dir = strcat(qsm_dir, 'spm/');
        qsm_hl_dir = strcat(qsm_data_dir, high_lambda_dirname, '/');
        qsm_hl_image = strcat(qsm_hl_dir, high_lambda_filename);
        qsm_ll_dir = strcat(qsm_data_dir, low_lambda_dirname, '/');
        qsm_ll_image = strcat(qsm_ll_dir, low_lambda_filename);

        % Copy QSM images to SPM directory
        copyfile(qsm_hl_image, qsm_spm_dir)
        copyfile(qsm_ll_image, qsm_spm_dir)

        cd(qsm_spm_dir)
        
        % Step 1: Calculate MVSSM image
        fade_qsm_calculate_mvssm(high_lambda_filename, low_lambda_filename, mvssm_filename, std_cutoff, fwhm, smoothed_cutoff);

        % Step 2: Create QSM brain mask from smoothed original QSM
        fade_qsm_create_mask(high_lambda_filename, 'qsm_mask.nii', fwhm_m, num_iter);

        % Step 3: Convert MVSSM to int16 format
        i16_mvssm_filename = strcat('i16_', mvssm_filename);
        fade_qsm_convert_int16(mvssm_filename, i16_mvssm_filename, scaling_factor)

        % Step 4: Mask integer MVSSM image with QSM brain mask
        clear matlabbatch
        matlabbatch{1}.spm.util.imcalc.input = {strcat(qsm_spm_dir, i16_mvssm_filename)
            strcat(qsm_spm_dir, 'qsm_mask.nii,1')};
        matlabbatch{1}.spm.util.imcalc.output = 'int16_MVSSM.nii';
        matlabbatch{1}.spm.util.imcalc.outdir = {''};
        matlabbatch{1}.spm.util.imcalc.expression = 'i1.*i2';
        matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
        matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
        matlabbatch{1}.spm.util.imcalc.options.mask = 0;
        matlabbatch{1}.spm.util.imcalc.options.interp = 1;
        matlabbatch{1}.spm.util.imcalc.options.dtype = 4;
        save(strcat(subj_id, 'imcalc.mat'));
        spm_jobman('run', strcat(subj_id, 'imcalc.mat'));

        % Step 5: SPM normalization based on MPRAGE image and smoothing
        clear matlabbatch
        date_dir = dir(strcat(subjects_dir, subj_id, '/20*'));
        mpragedir = dir(strcat(subjects_dir, subj_id, '/', date_dir.name, '/dzne_MPRAGE_1iso_PAT2_ND*'));
        mpragefile = dir(strcat(subjects_dir, subj_id, '/', date_dir.name, '/', mpragedir.name, '/s20*.nii'));
        mpragefilename = strcat(subjects_dir, subj_id, '/', date_dir.name, '/', mpragedir.name, '/', mpragefile.name);

        % SPM coregister
        matlabbatch{1}.spm.spatial.coreg.estimate.ref = {strcat(qsm_spm_dir, 'int16_MVSSM.nii,1')};
        matlabbatch{1}.spm.spatial.coreg.estimate.source = {mpragefilename};
        matlabbatch{1}.spm.spatial.coreg.estimate.other = {''};
        matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
        matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
        matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
        matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

        % Segmentation of MPRAGE
        matlabbatch{2}.spm.spatial.preproc.channel.vols(1) = cfg_dep('Coregister: Estimate: Coregistered Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
        matlabbatch{2}.spm.spatial.preproc.channel.biasreg = 0.001;
        matlabbatch{2}.spm.spatial.preproc.channel.biasfwhm = 60;
        matlabbatch{2}.spm.spatial.preproc.channel.write = [0 0];
        matlabbatch{2}.spm.spatial.preproc.tissue(1).tpm = {strcat(spm_dir, 'tpm/TPM.nii,1')};
        matlabbatch{2}.spm.spatial.preproc.tissue(1).ngaus = 1;
        matlabbatch{2}.spm.spatial.preproc.tissue(1).native = [1 0];
        matlabbatch{2}.spm.spatial.preproc.tissue(1).warped = [0 0];
        matlabbatch{2}.spm.spatial.preproc.tissue(2).tpm = {strcat(spm_dir, 'tpm/TPM.nii,2')};
        matlabbatch{2}.spm.spatial.preproc.tissue(2).ngaus = 1;
        matlabbatch{2}.spm.spatial.preproc.tissue(2).native = [1 0];
        matlabbatch{2}.spm.spatial.preproc.tissue(2).warped = [0 0];
        matlabbatch{2}.spm.spatial.preproc.tissue(3).tpm = {strcat(spm_dir, 'tpm/TPM.nii,3')};
        matlabbatch{2}.spm.spatial.preproc.tissue(3).ngaus = 2;
        matlabbatch{2}.spm.spatial.preproc.tissue(3).native = [1 0];
        matlabbatch{2}.spm.spatial.preproc.tissue(3).warped = [0 0];
        matlabbatch{2}.spm.spatial.preproc.tissue(4).tpm = {strcat(spm_dir, 'tpm/TPM.nii,4')};
        matlabbatch{2}.spm.spatial.preproc.tissue(4).ngaus = 3;
        matlabbatch{2}.spm.spatial.preproc.tissue(4).native = [1 0];
        matlabbatch{2}.spm.spatial.preproc.tissue(4).warped = [0 0];
        matlabbatch{2}.spm.spatial.preproc.tissue(5).tpm = {strcat(spm_dir, 'tpm/TPM.nii,5')};
        matlabbatch{2}.spm.spatial.preproc.tissue(5).ngaus = 4;
        matlabbatch{2}.spm.spatial.preproc.tissue(5).native = [1 0];
        matlabbatch{2}.spm.spatial.preproc.tissue(5).warped = [0 0];
        matlabbatch{2}.spm.spatial.preproc.tissue(6).tpm = {strcat(spm_dir, 'tpm/TPM.nii,6')};
        matlabbatch{2}.spm.spatial.preproc.tissue(6).ngaus = 2;
        matlabbatch{2}.spm.spatial.preproc.tissue(6).native = [0 0];
        matlabbatch{2}.spm.spatial.preproc.tissue(6).warped = [0 0];
        matlabbatch{2}.spm.spatial.preproc.warp.mrf = 1;
        matlabbatch{2}.spm.spatial.preproc.warp.cleanup = 2;
        matlabbatch{2}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{2}.spm.spatial.preproc.warp.affreg = 'mni';
        matlabbatch{2}.spm.spatial.preproc.warp.fwhm = 0;
        matlabbatch{2}.spm.spatial.preproc.warp.samp = 3;
        matlabbatch{2}.spm.spatial.preproc.warp.write = [0 1];
        matlabbatch{2}.spm.spatial.preproc.warp.vox = NaN;
        matlabbatch{2}.spm.spatial.preproc.warp.bb = [NaN NaN NaN
                                                      NaN NaN NaN];

        % Write normalized QSM
        matlabbatch{3}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));
        matlabbatch{3}.spm.spatial.normalise.write.subj.resample = {strcat(qsm_spm_dir, 'int16_MVSSM.nii,1')};
        matlabbatch{3}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
            78 76 85];
        matlabbatch{3}.spm.spatial.normalise.write.woptions.vox = [1 1 1];
        matlabbatch{3}.spm.spatial.normalise.write.woptions.interp = 7;
        matlabbatch{3}.spm.spatial.normalise.write.woptions.prefix = 'w_';

        % Smooth with 4 mm FWHM
        matlabbatch{4}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
        matlabbatch{4}.spm.spatial.smooth.fwhm = [4 4 4];
        matlabbatch{4}.spm.spatial.smooth.dtype = 0;
        matlabbatch{4}.spm.spatial.smooth.im = 0;
        matlabbatch{4}.spm.spatial.smooth.prefix = 's4';

        % Smooth with 6 mm FWHM
        matlabbatch{5}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
        matlabbatch{5}.spm.spatial.smooth.fwhm = [6 6 6];
        matlabbatch{5}.spm.spatial.smooth.dtype = 0;
        matlabbatch{5}.spm.spatial.smooth.im = 0;
        matlabbatch{5}.spm.spatial.smooth.prefix = 's6';

        % Run SPM job manager for normalization and smoothing
        save(strcat(subj_id, 'coreg_norm_smooth.mat'));
        spm_jobman('run', strcat(subj_id, 'coreg_norm_smooth.mat'));

    catch
        % Error handling for the subject
        ers = lasterror;
        disp(['Error in subject ' subj_id])
        err_subs = [err_subs subj_id];
    end

end

% Return to the original working directory
cd(cwd)
