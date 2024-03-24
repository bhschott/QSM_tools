function err_subs = fade_qsm_prep_4D(volname, scanner_name)
% function err_subs = fade_qsm_prep_4D(volname, scanner_name)
% 
% This function prepares 4D QSM (Quantitative Susceptibility Mapping) NIFTI files 
% for subjects in a given project directory using 3D NIFTI images. It creates 
% four 4D NIFTI files: 'magn_orig.nii', 'sum_magn.nii', 'phase_orig.nii', 
% and 'sum_phase.nii'.
% Additionally, a DICOM file with the header information is copied as
% required by QSMbox.
%
% INPUTS:
% - volname: Name of the volume (default: 'ArmorATD')
% - scanner_name: Name of the scanner (default: 'skyra')
%
% OUTPUTS:
% - err_subs: Cell array of subject IDs for which an error occurred during processing
%
% written by Bjoern H. Schott, 03/2024
% bjoern-hendrik.schott@dzne.de

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

% Define destination filenames
destfilename_list = {'magn_orig.nii', 'sum_magn.nii', 'phase_orig.nii', 'sum_phase.nii'};

% Define DICOM directory and QSM flag based on scanner name
switch scanner_name
    case 'verio'
        dicom_dir = strcat(project_dir, 'incoming_dicoms/dicom_verio/');
        qsm_flag = 'SWI';
    case 'skyra'
        dicom_dir = strcat(project_dir, 'incoming_dicoms/dicom_skyra/');
        qsm_flag = 'QSM';
    case 'skrep'
        dicom_dir = strcat(project_dir, 'incoming_dicoms/dicom_skrep/');
        qsm_flag = 'QSM';
end

% Define additional directories
qsm_tools_dir = strcat(tools_dir, 'QSM_tools/');
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
    
    clear dicom_list
    
    subj_id=subjnames(subject,:);
    disp(['Create QSM 4D Niftis for subject ' subj_id]);

    try
        % Get the name of the tar file containing DICOMs
        tarfile_name = dir(strcat(dicom_dir, subj_id, '*.tar'));
        tarfile_name = strcat(dicom_dir, tarfile_name.name);
        cd(strcat(work_dir, subj_id));
        
        % Create necessary directories
        mkdir QSM_main
        mkdir QSM_main/data
        mkdir QSM_main/data/dicom
        mkdir import_temp
        cd import_temp
        
        % Untar DICOMs
        untar(tarfile_name);
        
        % Get temporary DICOM directory
        subj_dicomdir = dir(strcat(work_dir, subj_id, '/import_temp/dicomdaten*'));
        subj_dicomdir = subj_dicomdir.name;
        dicomstudydirname = dir(subj_dicomdir);
        dicomstudydirname = dicomstudydirname(3).name;
        if strfind(dicomstudydirname, '._')
            dicomstudydirname = dicomstudydirname(3:end);
        end
        dicomstudydir = strcat(work_dir, subj_id, '/import_temp/', subj_dicomdir, '/', dicomstudydirname, '/');
        
        % Set permissions
        chmodcommand1 = ['chmod 777 ', subj_dicomdir];
        unix(chmodcommand1);
        chmodcommand2 = ['chmod 777 ', subj_dicomdir,'/*'];
        unix(chmodcommand2);
        chmodcommand3 = ['chmod 777 ', subj_dicomdir,'/*/*'];
        unix(chmodcommand2);
        
        % Delete index files on Mac
        rmcommand1 = ['rm ', subj_dicomdir,'/._*'];
        unix(rmcommand1);
        rmcommand2 = ['rm ', subj_dicomdir,'/*/._*'];
        unix(rmcommand2);
        rmcommand3 = ['rm ', subj_dicomdir,'/*/*/._*'];
        unix(rmcommand3);
        
        % Find QSM DICOM file
        fn = dir(dicomstudydir);
        is_qsm = false;
        ii = length(fn);
        while ~is_qsm && ii > 0 
            current_filename = fn(ii).name; 
            dcm_inf = spm_dicom_headers(fullfile(dicomstudydir, current_filename)); 
            dcm_inf = dcm_inf{1};
            if contains(dcm_inf.ProtocolName, qsm_flag)
                dicom_filename = fullfile(dicomstudydir, fn(ii).name);
                is_qsm = true;
            end
            ii = ii - 1;
        end
        if ~is_qsm
            error('No QSM images found among the DICOMs.'); 
        end
        
        % Prepare destination DICOM file
        QSM_work_dir = strcat(work_dir, subj_id, '/QSM_main/data/');
        dest_dicom_filename = strcat(QSM_work_dir, 'dicom/dicom_example.dcm');
        copyfile(dicom_filename, dest_dicom_filename);
        cd(strcat(work_dir, subj_id));
        imgdir = dir('20*');        
        data_dir = strcat(work_dir, subj_id, '/', imgdir.name, '/');
        cd(data_dir)
        qsm_dir_list = dir(strcat('*', qsm_flag, '*'));
        cd(QSM_work_dir)        
        
        % Loop through directories and create 4D QSM files in data directory
        for qdir = 1:length(qsm_dir_list)
            destfile_name = strcat(QSM_work_dir, destfilename_list{qdir});
            if contains(destfile_name, 'orig')
                current_dir = strcat(data_dir, qsm_dir_list(qdir).name, '/');
                file_list_raw = dir(current_dir);
                file_list_clean = {file_list_raw.name}';
                file_list_clean = file_list_clean(3:end);
                for fi = 1:length(file_list_clean)
                    full_name = sprintf('%s%s', current_dir, file_list_clean{fi});
                    file_list_clean{fi} = full_name;
                end
                create_4D_nifti(destfile_name, file_list_clean)
            end
        end
        
        % Delete temporary DICOM directory
        cd(strcat(work_dir, subj_id, '/'));
        rmdir('import_temp', 's');
        
    catch
        err_subs = [err_subs subj_id];
    end
end

cd(cwd)
