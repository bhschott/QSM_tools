function err_subs = fade_qsm_batch_dicom_import_qsm

% DICOM Import for uncombined QSM data. Uses DICOM Import function from
% SPM12. The script uses the Siemens ICDims as filenames, to avoid
% overwriting. Files are then renamed in a similar way as in SPM.
% 
%   Note:
%   - Please nsure that SPM (Statistical Parametric Mapping) toolbox is installed
%     and configured properly in MATLAB environment before running this function.
%   - Modify the input parameters within the function as required, such as:
%       - volname: Volume name
%       - scanner_name: Name of the MRI scanner used (e.g., 'verio', 'skyra', 'skrep')
%       - project_dir: Directory path where project data is stored
%       - work_dir: Directory path for processing and working files
%       - dicom_dir: Directory path where DICOM files are located
%       - qsm_tools_dir: Directory path for QSM tools
%
% written by Bjoern H. Schott, 03/2024
% bjoern-hendrik.schott@dzne.de


% Set up variables
volname = 'ArmorATD'; % Specify volume name
scanner_name = 'verio'; % Specify scanner name

project_dir = strcat('/Volumes/', volname, '/projects/FADE_2016/'); % Define project directory
work_dir = strcat(project_dir, 'subjects_', scanner_name, '/'); % Define working directory
tools_dir = strcat(project_dir, 'tools_BS/'); % Define tools directory

% Determine DICOM directory based on scanner name
switch scanner_name
    case 'verio'
        dicom_dir = strcat(project_dir, 'incoming_dicoms/dicom_verio/');
    case 'skyra'
        dicom_dir = strcat(project_dir, 'incoming_dicoms/dicom_skyra/');
    case 'skrep'
        dicom_dir = strcat(project_dir, 'incoming_dicoms/dicom_skrep/');
end

qsm_tools_dir = strcat(tools_dir, 'QSM_tools/'); % Define QSM tools directory
spm_dir = which('spm'); spm_dir = spm_dir(1:end-5); % Get SPM directory

% Select directories to process
dir_names = spm_select(Inf, 'dir', work_dir);
subjnames = dir_names(:, end-3:end);

cwd = pwd;
err_subs = {}; % Initialize error subjects list

% Loop through each subject directory
for subject = 1:size(dir_names, 1)
    
    clear matlabbatch dicom_list
    
    subj_id = subjnames(subject, :);
    disp(['Define job for subject ' subj_id]);
    
    try
        % Find DICOM tar file
        tarfile_name = dir(strcat(dicom_dir, subj_id, '*.tar'));
        tarfile_name = strcat(dicom_dir, tarfile_name.name);
        cd(strcat(work_dir, subj_id));
        mkdir import_temp
        cd import_temp
        % Untar DICOMs
        unix(['tar -xvf ' tarfile_name])
        % Get temporary DICOM directory
        subj_dicomdir = dir(strcat(work_dir, subj_id, '/import_temp/dicomdaten*'));
        subj_dicomdir = subj_dicomdir.name;
        dicomstudydirname = dir(subj_dicomdir);
        dicomstudydirname = dicomstudydirname(3).name;
        if strfind(dicomstudydirname, '._')
            dicomstudydirname = dicomstudydirname(3:end);
        end
        dicomstudydir = strcat(work_dir, subj_id, '/import_temp/', subj_dicomdir, '/');
        dicomstudydir = strcat(dicomstudydir, dicomstudydirname, '/');
        % Set permissions
        chmodcommand1 = ['chmod 777 ', subj_dicomdir];
        unix(chmodcommand1)
        chmodcommand2 = ['chmod 777 ', subj_dicomdir,'/*'];
        unix(chmodcommand2)
        % Delete index files on Mac
        rmcommand1 = ['rm ', subj_dicomdir,'/._*'];
        unix(rmcommand1)
        rmcommand2 = ['rm ', subj_dicomdir,'/*/._*'];
        unix(rmcommand2)
        rmcommand3 = ['rm ', subj_dicomdir,'/*/*/._*'];
        unix(rmcommand3)
        fn = dir(dicomstudydir);
        for ii = 1:length(fn)
            dicom_list{ii} = strcat(dicomstudydir, fn(ii).name);
        end
        dicom_list = dicom_list';
        
        % Set MATLAB batch for DICOM import
        matlabbatch{1}.spm.util.import.dicom.data = dicom_list;
        matlabbatch{1}.spm.util.import.dicom.root = 'date_time';
        matlabbatch{1}.spm.util.import.dicom.outdir = {strcat(work_dir, subj_id, '/import_temp/')};
        matlabbatch{1}.spm.util.import.dicom.protfilter = '.*';
        matlabbatch{1}.spm.util.import.dicom.convopts.format = 'nii';
        % Use Siemens ICDims => creates unique, but rather unhelpful filenames
        matlabbatch{1}.spm.util.import.dicom.convopts.icedims = 1;
        
        batchfile = strcat(work_dir, subj_id, '/', subj_id ,'_fade_dicomimp_qsm.mat');
        save(batchfile, 'matlabbatch')
    catch
        err_subs = [err_subs subj_id];
    end
end

cd(cwd)

% Define image numbers cell string for use below
image_numbers_str = sprintf('%04d\n', 1:32);
image_numbers_str = image_numbers_str(1:end-1);
image_numbers_cell = strsplit(image_numbers_str, '\n');

% Loop through each subject directory again to process DICOM import
for subject = 1:size(dir_names, 1)
    disp(['Run job for subject ' subjnames(subject,:)]);
    subj_id = subjnames(subject,:);
    job_name = strcat(work_dir, subj_id, '/', subj_id ,'_fade_dicomimp_qsm.mat');
    try
        spm_jobman('run', job_name);
        % Delete unneeded files
        cd(strcat(work_dir, subj_id, '/import_temp/'));
        unix('rm -r dicomdaten_*');
        imgdir = dir('20*');
        cd(imgdir.name)
        unix('rm -r *_ND_*');
        switch scanner_name
            case {'skyra', 'skrep'}
                unix(sprintf('mv *_QSM_* %s', strcat(work_dir, subj_id, '/', imgdir.name)));
            case 'verio'
                unix(sprintf('mv *_SWI_* %s', strcat(work_dir, subj_id, '/', imgdir.name)));
        end
        cd(strcat(work_dir, subj_id, '/'));
        unix('rm -r import_temp');
        % Rename QSM images after import
        data_dir = strcat(work_dir, subj_id, '/', imgdir.name, '/');
        cd(data_dir);
        pref = strcat('s', imgdir.name, '_QSM_000');
        % Current protocol "QSM", old protocol "SWI"
        switch scanner_name
            case {'skyra', 'skrep'}
                qsm_dir_list = dir ('*QSM*');
            case 'verio'
                qsm_dir_list = dir ('*SWI*');
        end
        % Loop through directories and adjust QSM filenames
        for qdir = 1:length(qsm_dir_list)
            prefix = sprintf('%s%d', pref, qdir);
            current_dir = strcat(data_dir,'/', qsm_dir_list(qdir).name, '/');
            file_list_raw = dir(current_dir);
            file_list_clean = {file_list_raw.name}';
            file_list_clean = file_list_clean(3:end);
            for fi = 1:length(file_list_clean)
                old_name = sprintf('%s%s', current_dir, file_list_clean{fi});
                new_name = strcat(current_dir, prefix, '_', image_numbers_cell{fi},'.nii');
                movefile(old_name, new_name);
            end
        end
    catch
        
        ers = lasterror;
        disp(['Error in Job ' job_name])
        err_subs = [err_subs subj_id];
    end
end

cd(cwd)

% Display error subjects, if any
if ~isempty(err_subs)
    disp('Errors occurred for the following subjects:')
    disp(err_subs)
else
    disp('All subjects processed successfully.')
end

end % End of main function
