# Res2dInvTools
A set of matlab-based tools for batch and visualisation of res2dinv ERI data.
RES2DINV_BATCHMANKER.m
This script makes batch files for res2dinv from a set of *.dat and *.ivp files.

LATEST VERSION is 1.0d - I will upload ASAP but if you need before then, please email me. [18/09/2018]

runMe_ver_1_0a.m
This script reads the *.XYZ output from Res2dinv and displays the resulting grids.

Hint; Navigate the XYZ blocks faster by searching through "/" in notepad++.

Datafiles MUST be inverted in the general array format. 
You can check by finding the followngblock set.
"
/The following section gives the X-location of the midpoint of the
/array and the electrode spacing for each data point. The calculated,
/observed and the percentage logarithmic difference between these
/values are also given.
"
If you see;
"Array Midpoint; Psueod-Depth; Calc Appar. Rho; ... etc," 
this will work fine.

If you see;
"Array Midpoint; Electrode Spacing; Calc Appar. Rho; ... etc,"
This will not work.

The consequence is that the misfit plot will not work, however data will
be displayed just fine.

This script acocunts for both extended and non-extended model sections.
For non-extended models, blank cells are added and flagged 'nan' to make up
the additional cells required to plot resolution/sensitivity/etc on a
topographic grid.

Version History;
v1.0    - Changed individual 'line' plots for cells to patch plots.
        - Included loop-able file and draw functions.
        - Added synthetic block expansion subroutine.
        - Added checks for non-general array structures.

v1.0a   - Added statistics output and error plots

To-Do List;
        - Implement GPS map options (i.e. show where line is).
        - Waste time implmeneting non-general array structure.
        - Expand commentary.
        - Speed-up data-loading.
