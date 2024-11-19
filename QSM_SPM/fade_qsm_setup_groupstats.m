function fade_qsm_setup_groupstats(subj_list_name, modality, output_dir, image_dir, subj_filename, nocovars)

% for external harddrives in Unix-based systems ... needs to be adapted for Windows
vol_name = 'ArmorATD';
project_dir = strcat('/Volumes/', vol_name, '/projects/FADE_2016/');
tools_dir = strcat(project_dir, 'tools_BS/QSM_tools/');
analyses_dir = strcat(project_dir, 'analyses_new/2nd_level/QSM/');
scanner_dirs = {'subjects_skrep', 'subjects_skyra', 'subjects_verio'};

% define subject list file
if nargin < 1
    subj_list_name = 'subjects_qsm_all_2024-11-01.txt';
end
if ~contains(subj_list_name, '/') && ~contains(subj_list_name, '\')
    subj_list_file = strcat(tools_dir, subj_list_name);
else
    subj_list_file = subj_list_name;
end

% set default modality to GMV
if nargin<2
    modality = 'GMV'; % must be 'GMV' or 'QSM'
end

switch modality
    case 'GMV'
        if nargin < 4
            image_dir = 'QSM_main/spm/GMV/';
            image_filename = 's6_mwp1*_MPRAGE.nii';
        end
    case 'QSM'
        if nargin < 4
            image_dir = 'QSM_main/spm/';
            image_filename = 's6w_int16_MVSSM_749_39_2.nii';
        end
    otherwise
        fprintf('Modality must be GMV or QSM.\n');
        return
end

if nargin >= 5
    image_filename = subj_filename;
end

if nargin < 6
    nocovars = 0;
end

% create output directory
try
    cd(analyses_dir)
catch
    mkdir(analyses_dir)
    cd(analyses_dir)
end
if nargin < 3
    output_dir = strcat(analyses_dir, 'old-young_', modality, '_', date, '/');
end
mkdir(output_dir)

% collect group variables
[filename_list, age_covar, sex_covar, TIV_covar, scanner_covar] = fade_qsm_collect_groupvars(subj_list_file, image_dir, image_filename, 2, 'Age_Group');


clear matlabbatch

% model specification
matlabbatch{1}.spm.stats.factorial_design.dir = {output_dir};
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact.name = 'age_group';
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact.levels = 2;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact.dept = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact.variance = 1;

% use grand mean scaling and ANCOVA for QSM, consider disabling for GMV
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact.gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.fd.fact.ancova = 0;

% 2 age groups - can be adapted to 3 groups
for ll = 1:length(filename_list)
    filename_list{ll} = cellfun(@(x) [x, ',1'], filename_list{ll}, 'UniformOutput', false);
end

young_list = {}; old_list = {}; % middle_list = {}

for ll = 1:length(filename_list)
    for subj = 1:length(filename_list{ll})
        img_file = filename_list{ll}{subj};
        switch ll    % use ll = 3 when testing three groups
            case 1
                young_list = [young_list; img_file];
            case 2
                old_list = [old_list; img_file];
        end
    end
end




% assign subject lists to matlab batch
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).levels = 1;
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(1).scans = young_list;
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).levels = 2;
matlabbatch{1}.spm.stats.factorial_design.des.fd.icell(2).scans = old_list;
matlabbatch{1}.spm.stats.factorial_design.des.fd.contrasts = 1;

% linearize covariates
TIV_covar = [TIV_covar{1}; TIV_covar{2}];
sex_covar = [sex_covar{1}; sex_covar{2}];
scanner_covar = [scanner_covar{1}; scanner_covar{2}];

if ~nocovars

    % use TIV as covariate by default
    matlabbatch{1}.spm.stats.factorial_design.cov(1).c = TIV_covar;
    matlabbatch{1}.spm.stats.factorial_design.cov(1).cname = 'TIV';
    matlabbatch{1}.spm.stats.factorial_design.cov(1).iCFI = 1;
    matlabbatch{1}.spm.stats.factorial_design.cov(1).iCC = 1;

    % use sex/gender as covariate by default
    matlabbatch{1}.spm.stats.factorial_design.cov(2).c = sex_covar;
    matlabbatch{1}.spm.stats.factorial_design.cov(2).cname = 'gender';
    matlabbatch{1}.spm.stats.factorial_design.cov(2).iCFI = 1;
    matlabbatch{1}.spm.stats.factorial_design.cov(2).iCC = 1;

    % use scanner covariate if it has more than one value
    if ~all(scanner_covar == scanner_covar(1))
        matlabbatch{1}.spm.stats.factorial_design.cov(3).c = scanner_covar;
        matlabbatch{1}.spm.stats.factorial_design.cov(3).cname = 'scanner';
        matlabbatch{1}.spm.stats.factorial_design.cov(3).iCFI = 1;
        matlabbatch{1}.spm.stats.factorial_design.cov(3).iCC = 1;
    end

end

% multiple covariates via table not used here
matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});

% defaults
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

% model estimation
matlabbatch{2}.spm.stats.fmri_est.spmmat(1) = cfg_dep('Factorial design specification: SPM.mat File', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','spmmat'));
matlabbatch{2}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;


% save and run matlabbatch
current_date = date;
job_name = strcat(analyses_dir, 'old-young_', modality, '_', current_date, '.mat');
save(job_name, 'matlabbatch');
%try
spm_jobman('run', job_name);
%catch
%    ers = lasterror;
%    disp(['error in job ' job_name])
end
