Scripts for DICOM import and 4D NIFTI conversion of Siemens DICOM data.

When uncombined QSM images are acquired (i.e., one image per channel), SPM's DICOM Import always overwrites the previous image and stores only one NIFTI instead of N = number of channels.

This problem is circumvented by using the original filenames. These are then replaced by more meaningful filenames.

A separate script prepares the directory and file structure required by QSMbox, using the create_4D_nifti function.
