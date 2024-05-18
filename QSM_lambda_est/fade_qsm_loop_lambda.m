function fade_qsm_loop_lambda(script_file)
% FADE_QSM_LOOP_LAMBDA Generates and runs script files with fading lambda values.
%
%   FADE_QSM_LOOP_LAMBDA(script_file) generates multiple script files by
%   modifying the lambda value in the specified script file and runs each
%   modified script file using qsmbox. Lambda values are varied from 10^1
%   to 10^3.3 with a step size of 0.1.
%
%   This function requires QSMbox and SPM12 toolboxes.
%
%   The function must be called from the data directory containing the
%   phase and magnitude QSM raw images (in NIFTI format).
%
%   Inputs:
%   - script_file: Filename of the original script file (default:
%     'ptbs_use_002_def_msdi2.m').
%
%   written by Bjoern Schott, 04/2024

% Define the range of exponents for lambda
lambda_exponents = 1:0.1:3.3;

% Calculate lambda values from the exponents
lambda_values = 10.^lambda_exponents;

% Original script file
if nargin < 1
    script_file = 'ptbs_use_002_def_msdi2.m';
end

% Loop over each lambda value
for idx = 1:numel(lambda_values)

    lambda_val = round(lambda_values(idx));
    
    % Read the original script file into a cell array
    script_lines = strsplit(fileread(script_file), '\n');

    % Find the line number containing the lambda value
    lambda_line_idx = find(contains(script_lines, 'ptb.qsm.MSDI.lambda'), 1);

    % Replace the lambda value in the line
    new_lambda_line = sprintf('ptb.qsm.MSDI.lambda = %f;', lambda_val);
    script_lines{lambda_line_idx} = new_lambda_line;

    % Write the modified script back to the original file name
    new_script_file = sprintf('%s_lambda_10_%d_%1.0f.m', script_file(1:end-2), floor(lambda_exponents(idx)), (lambda_exponents(idx)-floor(lambda_exponents(idx)))*10);
    fid = fopen(new_script_file, 'w');
    fprintf(fid, '%s\n', script_lines{:});
    fclose(fid);
    
    % Run qsmbox with the modified script
    new_script_command = new_script_file(1:end-2);
    fprintf('Running %s\n\n', new_script_command)
    eval(new_script_command)

end
