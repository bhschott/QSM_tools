% FADE_QSM_MMA_pipeline
%
% run multimodal analysis (MMA) of QSM data with GMV as voxel-wise
% covariate
%
% requires SPM12, MMA toolbox (https://github.com/JoramSoch/MMA)
%
% written by Bjoern Hendrik Schott 11/2024
%

% define directory names
cwd = pwd;
MMA_dir = strcat(cwd, '/MMA_QSM_GMV_old-young_2024-11-19/');
SPM_mat_DM = strcat(cwd, '/QSM_old-young_all_2024-11-19/');
SPM_mat_IM = strcat(cwd, '/GMV_old-young_all_2024-11-19_nocovs/');

% contrast matrix for 2-sample t-test / one-way ANOVA with two levels
con_mat_IM = [1 0; 0 1];

% call MMA
mma_mma(SPM_mat_DM, SPM_mat_IM, con_mat_IM, MMA_dir)

