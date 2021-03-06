%% Res2DInv Batch Creator; Created by A.R. Costall, 2017
%{
This script makes batch files for res2dinv from a set of *.dat and *.ivp
files.

Version History;
v1.0    - Added multiple dat and ivp functionality

%}

%% Select dat files (*.dat)
FilterSpec = '*.dat';
DialogTitle = 'Select Res2dInv DAT file/s';
[datfilename,pathname] = uigetfile(FilterSpec,DialogTitle,'MultiSelect','on');
cd (pathname);

%% Select inversion parameters (*.ivp)
FilterSpec = '*.ivp';
DialogTitle = 'Select Res2dInv IVP file/s';
[ivpfilename] = uigetfile(FilterSpec,DialogTitle,'MultiSelect','on');

%% Write batch file (*.bth)
fOutTitle = 'AutoGeneratedBTH'; % This can't handle special characters!
% fCount = size(ivpfilename,2);
if isa(datfilename,'char')
    datfilename = {datfilename};
    fCount = 1;
else
    fCount = size(datfilename,2);
end
disp(['Found ',num2str(fCount),' dat file/s']);
if isa(ivpfilename,'char')
    ivpfilename = {ivpfilename};
    iCount = 1;
else
    iCount = size(ivpfilename,2);
end
disp(['Found ',num2str(iCount),' ivp file/s']);

%% Write output file
fID = fopen([fOutTitle,'.bth'],'w');
fprintf(fID,'%s \n','Auto-GeneratedBTH');
fprintf(fID,'%i \n',fCount*iCount);
fprintf(fID,'%s \n','INVERSION PARAMETERS FILES USED');

c = 1;
for i = 1:iCount % Loop over inversion parameter files
    for j = 1:fCount % Loop over input data files
        fprintf(fID,'%s \n',['DATA FILE ',num2str(c)]); % header
        fprintf(fID,'%s \n',[pathname,datfilename{j}]); % Dat file
        fprintf(fID,'%s \n',[pathname,datfilename{j}(1:end-3),ivpfilename{i}(1:end-3),'inv']); % output *.inv
        fprintf(fID,'%s \n',[pathname,ivpfilename{i}]); % input *.ivp
        c = c+1;
    end
end
disp(['Wrote ', num2str(c-1),' entries.']);
disp('Done.');

fclose all;