%% Res2dInv XYZ Reader - Created by A.M. Pethick and A.R. Costall, 2017
%{
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
        - Add export to SEG-y function
%}

%% Load Data
close all; clear all;

[fid,path] = uigetfile('.xyz','multiselect','on');
if class(fid) == 'char'
    fid = {fid};
end
i=1;

%% Plot Data
for i = 1:numel(fid)
    r = RES2DXYZ;
    r = r.load([path,fid{i}]);
    cd(path)
    %% Data definition;
    vals = [];
    vals(:,1) = log10(1000.*r.Conductivity);
    vals(:,2) = log10(r.Resolution);
%     vals(:,3) = log10(r.ResolutionPerUnitArea);
    
    cbarLabels = {['Conductivity (mS/m)'],...
        ['Resolution'], ...
        ['Resolution Per Unit Area']};
    caxislims = {[-0,2]; ... % Conductivity (log scale)
                 [-4,-0.969]; ... % Resolution (log scale)
                 [-4,-0.969]; ... % resolution p/unit area (log)
                 };
    %% Plot (New Method)
    titles.plot = fid{i};
    for j = 1:size(vals,2)
%         figure('Color',[1 1 1],'Position',[0,0,1920,1080]);
        figure('Color',[1 1 1],'Position',[0,0,1920,800]);
        set(gcf, 'visible', 'off') % Turn figure pop-up on/off

        plotModel_v2(r,vals(:,j),titles);
        
        % Colorbar
        cb2 = colorbar('southoutside');
        titles.cbar = cbarLabels{j};
        cb2.Label.String = {titles.cbar};
%         caxis(caxislims{j})
        caxis('auto')
        dfTicks = cb2.Ticks;
        dfTicks(end+1) = max(caxis);
        cb2.TickLabels = round((10.^dfTicks),2,'significant');
        cb2.TickDirection = 'out';
        
        % Export figure
        tic;
        saveas(gcf,[path,fid{i},'_',num2str(j),'MATLAB','.png'],'png');
%         saveas(gcf,[path,fid{i},'_',num2str(j),'MATLAB_VECTOR','.emf'],'emf');
        toc;
        
        disp('Exported Figure')
        close all
    end
    plotMismatch(r)
    saveas(gcf,[path,fid{i},'_','_Mismatch','.png'],'png');
%     saveas(gcf,[path,fid{i},'_','_Mismatch_Vector','.emf'],'emf');
    close all
    
    plotStats(r)
        saveas(gcf,[path,fid{i},'_','_ErrorStats','.png'],'png');
%     saveas(gcf,[path,fid{i},'_','_ErrorStats_Vector','.emf'],'emf');
    close all
    
end