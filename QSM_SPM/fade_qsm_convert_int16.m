function fade_qsm_convert_int16(src_file, dest_file, scaling_factor)

if nargin < 1
    src_file  = 'qsm.nii';
end
if nargin < 2
    dest_file = strcat('i16_', src_file);
end

% set scaling factor for conversion (default = 1000)
if nargin < 3
    scaling_factor = 1000;
end


qsm_hdr  = spm_vol(src_file);
qsm_img  = spm_read_vols(qsm_hdr);
% qsm_img(qsm_img==0) = NaN;
qsm_img = qsm_img * scaling_factor + abs(min(qsm_img(:) * scaling_factor));
qsm_hdr.fname = dest_file;
qsm_hdr.dt    = [spm_type('uint16') spm_platform('bigend')];
spm_write_vol(qsm_hdr, qsm_img);