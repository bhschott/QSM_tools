Overview of bugfixes to run QSMbox on Matlab R2023b / MacOS Ventura

Bugfixes might have to be adapted for other Matlab or MacOS versions.

written by Bjoern Schott, 03/2024
For questions, please email: bjoern-hendrik.schott@dzne.de

QSMbox is available here: https://gitlab.com/acostaj/QSMbox
The approach underlying the QSM reconstruction implemented in QSMbox is described here:
https://doi.org/10.1016/j.neuroimage.2018.07.065

1. Quarantined all files in QSMbox/master/ptb/_spm12b_nifti
=> use the current version of SPM12 instead


2. Added symbolic links to Matlab libraries to QSMbox directories containing mex files:

/Applications/spm/spm12/toolbox/QSMbox/master/ptb/_LBV
bash-3.2$ ls -l
total 552
-rwxr-xr-x@ 1 schottb  staff    1608 Mar  7 11:36 LBV.m
drwxr-xr-x  3 schottb  staff      96 Mar  7 11:32 backup
lrwxr-xr-x  1 schottb  staff      55 Mar  7 10:17 libmat.dylib -> /Applications/MATLAB_R2023b.app/bin/maci64/libmat.dylib
lrwxr-xr-x  1 schottb  staff      55 Mar  7 10:17 libmex.dylib -> /Applications/MATLAB_R2023b.app/bin/maci64/libmex.dylib
-rwxr-xr-x@ 1 schottb  staff   31734 Mar  7 11:35 mexMGv3.cpp
-rwxr-xr-x@ 1 schottb  staff  100280 Mar  7 11:36 mexMGv3.mexmaci64
-rwxr-xr-x@ 1 schottb  staff   36864 Jun 15  2021 mexMGv3.mexw64
-rwxr-xr-x@ 1 schottb  staff   41125 Jun 15  2021 mexMGv6.mexa64
-rwxr-xr-x@ 1 schottb  staff   33820 Jun 15  2021 mexMGv6.mexmaci64
-rwxr-xr-x@ 1 schottb  staff   24576 Jun 15  2021 mexMGv6.mexw64

The same links have also been added to 
/Applications/spm/spm12/toolbox/QSMbox/master/ptb/_PhaseTools


3. Corrected memory management in mexMGv6.cpp:

To avoid memory management errors in the mexMGv6 mex file, the following steps were needed:

The most recent version of mexMG (v6) was not part of the QSMbox bundle and downloaded from here:
https://github.com/nosarthur/LBV

In mexMGv6.cpp, line 750: replaced 

	delete mask_int; 
with

	delete[] mask_int;

mexMGv6.cpp was then compiled with mex.

4. Corrected extraction of TE from DICOM header (m1_dicom_extract_res_B0_TE.m):
=> replace info.EchoNumber with info.EchoNumbers, if EchoNumber does not exist
=> Use info.EchoTime from the DICOM header in case TE could not be extracted from info.EchoNumber(s).
=> QSMbox needs TE in seconds => if TE > 1; TE = TE/1000 
