function lambda_opt = fade_m1_Lcurve(subj_id,scales,vol_name,scanner_name)
% DESCRIPTION
%  Estimate optimal regularisation parameter using L-curve analysis
% 
% SYNTAX
%  lambda_opt = fade_m1_Lcurve(subj_id,scales)
% 
% INPUTS
%  subj_id        string of the subject ID / subject directory
% 
%  scales         Vector of scale(s) to be analysed, e.g. 1:4. For
%                 nMEDI, nMEDI with SMV sharpening or if only 
%                 interested in one MSDI scale, 'scales' can be a 
%                 single integer
% 
% Created by Julio Acosta-Cabronero
%
% adapted by Bjoern Hendrik Schott 05/2024:
% * use data from multiple subdirectories 
% * truncate lambda_list to remove outliers

% define defaults -> adapt if needed

if nargin<3
    vol_name = 'ArmorATD';
end
if nargin<4
    scanner_name = 'skyra';
end
project_dir = strcat('/Volumes/', vol_name, '/projects/FADE_2016/');
subjects_dir = strcat(project_dir, 'subjects_', scanner_name, '/');
msdi_prefix = 'use_002_def_msdi2_';
work_dir = strcat(subjects_dir, subj_id, '/QSM_main/data/');

num_lambdas = 24;

% collect filenames
tmp = dir(strcat(work_dir, msdi_prefix, '*'));
lambda_list_dirnames = {tmp.name};
% if there are older use_002_* directories, use only the newest 24
if length(lambda_list_dirnames) > num_lambdas
    lambda_list_dirnames(end-num_lambdas+1:end);
end

% get lambda values from cost_fid* filenames
lambda_list = [];
for l = 1:length(lambda_list_dirnames)
    uu = dir(strcat(work_dir, lambda_list_dirnames{l}, '/cost_fid_l*'));
    uu = uu.name;
    lambda = str2num(uu(11:end-4));
    lambda_list(l) = lambda;
end

% remove half of the low values from lambda_list 
% lambda_list = lambda_list([2:2:9 11:end]);
% lambda_list_dirnames = lambda_list_dirnames([2:2:9 11:end]);

% truncate lambda_list
lambda_list = lambda_list(10:end-2);
lambda_list_dirnames = lambda_list_dirnames(10:end-2);

disp(num2str(lambda_list))

close all
figure

% c=['m','b','r','k','g'];
c = ['k','k','k','k','k'];

for S=scales
    for x=1:length(lambda_list)
        fid_cost_ttt = load([work_dir, lambda_list_dirnames{x}, '/cost_fid_l' num2str(lambda_list(x)) '.txt']);
        reg_cost_ttt = load([work_dir, lambda_list_dirnames{x}, '/cost_reg_l' num2str(lambda_list(x)) '.txt']);
        fid_cost_ttt = sum([fid_cost_ttt(1:S)].^1);
        reg_cost_ttt = sum(reg_cost_ttt(1:S));
        idx=find(fid_cost_ttt>0);
        fid_cost(x)=fid_cost_ttt(idx(end));
        reg_cost(x)=reg_cost_ttt(idx(end));
    end

    [idx_opt,lambda_opt_ttt,Kappa] = fade_m1_LcurveOpt(fid_cost,reg_cost,1./lambda_list,c(S));
    lambda_opt(S) = 1/lambda_opt_ttt;
        
end

% remove lambda_opt(1), which is always 0
lambda_opt = max(lambda_opt);