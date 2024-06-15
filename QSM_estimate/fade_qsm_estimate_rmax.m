function fade_qsm_estimate_rmax(lambda, script_file)
% FADE_QSM_ESTIMATE_RMAX Generates and runs script file for QSM reconstruction.
%
%   This function requires QSMbox and SPM12 toolboxes.
%
%   The function must be called from the data directory containing the
%   phase and magnitude QSM raw images (in NIFTI format).
%
%   Inputs:
%   - script_file: Filename of the original script file (default:
%     'ptbs_use_002_def_msdi2.m').
%   - lambda: denominator of the desired lambda value.
%     - should be determined empirically, e.g., using the L-curve method
% 
%   Uses a definition of r_max 
%
%   written by Bjoern Schott, 05/2024


% cut-off for lambda values for which r_max = (default = 2 mm) is used
lambda_cutoff = 100;
r_max = 4;


% Original script file
if nargin < 2
    script_file = 'ptbs_use_002_def_msdi2.m';
end

% error if no lambda is provided
if nargin < 1
    error('Please provide a value for lambda.');
end


% Read the original script file into a cell array
script_lines = strsplit(fileread(script_file), '\n');

% Find the line number containing the lambda value
lambda_line_idx = find(contains(script_lines, 'ptb.qsm.MSDI.lambda'), 1);

% Replace the lambda value in the line
new_lambda_line = sprintf('ptb.qsm.MSDI.lambda = %f;', lambda);
script_lines{lambda_line_idx} = new_lambda_line;

% if lambda below cut-off for high-pass QSM, set r_max
if lambda <= lambda_cutoff
    % Find the line number containing r_max
    radius_line_idx = find(contains(script_lines, 'ptb.bfe.vsmv.R0'), 1);
    % Replace the lambda value in the line
    new_radius_line = sprintf('ptb.bfe.vsmv.R0 = %f;', r_max);
    script_lines{radius_line_idx} = new_radius_line;
end


% Write out the modified script 
new_script_file = sprintf('%s_lambda_fix_%d_rmax_%d.m', script_file(1:end-2), lambda, r_max)
fid = fopen(new_script_file, 'w');
fprintf(fid, '%s\n', script_lines{:});
fclose(fid);

% Run qsmbox with the modified script
new_script_command = new_script_file(1:end-2);
fprintf('Running %s\n\n', new_script_command)
eval(new_script_command)

