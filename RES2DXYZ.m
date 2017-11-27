classdef RES2DXYZ
    properties
        modelName
        numBlocks
        topographyFlag
        generalFormatFlag
        resolutionFlag
        GpsFlag
        X
        Depth
        Elevation
        Resistivity
        Conductivity
        Resolution
        ResolutionIndex
        ResolutionPerUnitArea
        ResolutionPerUnitAreaIndex
        RelativeSensitivity
        SmoothedSensitivity
        PercentageUncertainty
        DataMidPoint
        DataElectrodeSpacing
        DataDipoleLength
        DataCalcApparentResistivity
        DataObservedApparentResistivity
        DataPercentLogarithmicDifference
        DataObservedApparentConductivity
        DataPseudoDepth
        CellBlockCoordsTopo
        CellBlockCoordsNoTopo
        topo
        offsets
        rmserror
    end
    methods
        function obj = load(obj,filename)
            %{
%% Res2dInv Block Structure
    #1:     Block centers.
    #2:     Block centers inc. topography (if present).
    #2a:	Surface Topography.
    #2b:    Electrode Topography.
    #3:     Calcuated Differences.
    #4:     Relative senstivities & Uncertainty.
    #5:     Model block resolution values.
    #6:     Model block coordinates w/o topography.
    #7:     Model block corners w/ topography (if exists).
    #8:     Model block coordinates w/ topography (if exists).
    #9:     Model block centers with GPS. (if exists)
    #10:    Model block centers with GPS and surface topopgrahy (if exists).
            %}
            %% Preallocate Data
            disp(['Loading ',filename]);
            disp('Initializing data structure...');
            %Initialise data structure
            obj.modelName = [];
            obj.numBlocks = [];
            obj.topographyFlag = [];
            obj.generalFormatFlag = [];
            obj.resolutionFlag = [];
            obj.GpsFlag = [];
            obj.X = [];
            obj.Depth = [];
            obj.Elevation = [];
            obj.Resistivity = [];
            obj.Conductivity = [];
            obj.Resolution = [];
            obj.ResolutionIndex = [];
            obj.ResolutionPerUnitArea = [];
            obj.ResolutionPerUnitAreaIndex = [];
            obj.DataMidPoint = [];
            obj.DataElectrodeSpacing = [];
            obj.DataDipoleLength = [];
            obj.DataCalcApparentResistivity = [];
            obj.DataObservedApparentResistivity = [];
            obj.DataPercentLogarithmicDifference = [];
            obj.DataObservedApparentConductivity = [];
            obj.CellBlockCoordsTopo = [];
            obj.CellBlockCoordsNoTopo = [];
            obj.DataPseudoDepth = [];
            obj.topo = [];
            obj.offsets = [];
            obj.rmserror = [];
            fid = fopen(filename,'r');
            
            tline = fgets(fid);
            
            %% BLOCK #1: Center block XZ with data.
            %{
/Name of survey line is...
/Number of blocks is ...
/The x and z coordinates of the centres of the model blocks, and
/The resistivity and conductivity of each block is given below.
            %}
            % Header Information: Name, #blocks, resolution parameter
            obj.resolutionFlag = 0;
            disp('...Reading BLOCK #1: Center block XZ with data');
            
            while contains(tline,'/')
                if contains(tline, '/Name of survey')
                    splitline = strsplit(tline);
                    obj.modelName = strjoin(splitline(6:end));
                end
                if contains(tline, '/Number of blocks')
                    nBlocks = str2double(strsplit(tline));
                    obj.numBlocks = nBlocks(~isnan(nBlocks));
                    disp(['Found ', num2str(obj.numBlocks),' model blocks.']);
                end
                if contains(tline,'Reso.')
                    obj.resolutionFlag = 1;
                    disp('Resolution data found.');
                end
                tline = fgets(fid);
            end
            % Data to arrays: [x, z, res, con, {resolution x4}]
            while ~contains(tline,'/')
                arr = str2num(tline);
                obj.X = cat(2, obj.X, arr(1));
                obj.Depth = cat(2, obj.Depth, arr(2));
                obj.Resistivity = cat(2, obj.Resistivity, arr(3));
                obj.Conductivity = cat(2, obj.Conductivity, arr(4));
                if(obj.resolutionFlag == 1)
                    obj.Resolution = cat(2, obj.Resolution, arr(5));
                    obj.ResolutionIndex = cat(2, obj.ResolutionIndex, arr(6));
                    obj.ResolutionPerUnitArea = cat(2, obj.ResolutionPerUnitArea, arr(7));
                    obj.ResolutionPerUnitAreaIndex = cat(2, obj.ResolutionPerUnitAreaIndex, arr(8));
                end
                tline = fgets(fid);
            end
            %% BLOCK #2: Topography
            %{
 /The following section gives the coordinates of the centers of
/the model blocks after incorporating the surface topography.
/The X and Z coordinates of the centres of the model blocks,
/the resistivity and conductivity of each blocks is given below.
            %}
            disp('...Checking for Topography');
            %skip the secondary header
            obj.generalFormatFlag = 1;
            obj.topographyFlag = 0;
            while contains(tline,'/')
                if contains(tline,'topography') == 1
                    obj.topographyFlag = 1;
                    disp('Topography data found.');
                end
                % Check for general format here, becuase if topography is
                % absent, the difference block header gets skipped.
                if sum(contains(strsplit(tline),["mid-point","spacing"])) == 2
                    obj.generalFormatFlag = 0;
                    disp(['General array format not used.']);
                end
                tline = fgets(fid);
                
            end
            if (obj.topographyFlag == 1)
                disp('...Reading BLOCK #2: Topography')
                % Read the inverted elevation data (topography)
                % Header contains [x, elevation, res, cond]
                while ~contains(tline,'/')
                    arr = str2num(tline);
                    obj.Elevation = cat(2, obj.Elevation, arr(2));
                    tline = fgets(fid);
                end
                %{
The following section gives the surface topographical data.
/The X-Location gives the distance along the ground surface
/and not the true horizontal distances.
                %}
                % Read Comments
                while contains(tline,'/')
                    tline = fgets(fid);
                end
                % Read Data
                while ~contains(tline,'/')
                    arr = str2num(tline);
                    obj.offsets = cat(2, obj.offsets, arr(1));
                    obj.topo = cat(2, obj.topo, arr(2));
                    tline = fgets(fid);
                end
                %{
/The following section gives the surface topographical data at each electrode.
/The X-Location gives the true horizontal distances.
                %}
                % Read Comments (This is currently skipped)
                while contains(tline,'/')
                    tline = fgets(fid);
                end
                % Read Data (This is currently skipped)
                while ~contains(tline,'/')
                    tline = fgets(fid);
                end
            else
                % If no topography data present, assign to zeros.
                obj.Elevation = -obj.Depth;
                obj.offsets = unique(obj.X);
                obj.topo = zeros(1,numel(unique(obj.X)));
            end
            %% BLOCK 3: Differences
            %{
/The following section gives the X-location of the midpoint of the
/array and the electrode spacing for each data point. The calculated,
/observed and the percentage logarithmic difference between these
/values are also given.
            %}
            while contains(tline,'/')
                if sum(contains(strsplit(tline),["mid-point","spacing"])) == 2
                    obj.generalFormatFlag = 0;
                    disp(['General array format not used.']);
                end
                tline = fgets(fid);
            end
            if obj.generalFormatFlag == 1
                disp('...Reading BLOCK 3: Differences')
                while ~contains(tline,'/')
                    arr = str2num(tline);
                    obj.DataMidPoint = cat(2, obj.DataMidPoint, arr(1));
                    obj.DataPseudoDepth = cat(2, obj.DataPseudoDepth, arr(2));
                    obj.DataCalcApparentResistivity = cat(2, obj.DataCalcApparentResistivity, arr(3));
                    obj.DataObservedApparentResistivity = cat(2, obj.DataObservedApparentResistivity, arr(4));
                    obj.DataPercentLogarithmicDifference = cat(2, obj.DataPercentLogarithmicDifference, arr(5));
                    obj.DataObservedApparentConductivity = cat(2, obj.DataObservedApparentConductivity, arr(6));
                    
                    tline = fgets(fid);
                end
            else % If the general format hasn't been used, skip all of this section.
                disp('...Skipping BLOCK 3: Differences')
                while ~contains(tline,'/')
                    tline = fgets(fid);
                end
            end
            %% BLOCK 4: Sensitivities
            %{
/The following section gives the relative sensitivity and
/percentage uncertainity of the model resistivity values.
/The x and z coordinates of the centres of the model blocks
/and their resistivity values are also given.
            %}
            % Read headers (includes RMS error from last block)
            while contains(tline,'/')
                if contains(tline,'error')
                    err = str2double(strsplit(tline));
                    obj.rmserror = err(~isnan(err));
                    disp(['Error measurement is ', num2str(obj.rmserror), '%'])
                end
                
                tline = fgets(fid);
            end
            disp('...Reading BLOCK 4: Sensitivities');
            % Read data [x, depth, res, rel.Sens, smoothed.sens, %Uncert.]
            while ~contains(tline,'/')
                arr = str2num(tline);
                obj.RelativeSensitivity = cat(2, obj.RelativeSensitivity, arr(4));
                obj.SmoothedSensitivity = cat(2, obj.SmoothedSensitivity, arr(5));
                obj.PercentageUncertainty = cat(2, obj.PercentageUncertainty, arr(6));
                tline = fgets(fid);
            end
            %% BLOCK 5: Resolution
            % This block is skipped, as these values are listed in BLOCK 1.
            %{
/The following section gives the model resolution values
/The x and z coordinates of the centres of the model blocks
/and their resistivity values are also given.
            %}
            if obj.resolutionFlag == 1
                disp('...Skipping BLOCK 5: Resolution');
                while contains(tline,'/')
                    tline = fgets(fid);
                end
                while ~contains(tline,'/')
                    if feof(fid) == 1
                        disp('Reach EOF.');
                        break
                    end
                    tline = fgets(fid);
                end
            end
            %% BLOCK 6: Model Blocks w/o Topography
            
            disp('...Reading BLOCK 6: Model Blocks w/o Topography');
            %{
/Coordinates of model blocks (no topography).
/The following section gives the X- and Z-coordinates of the four
/corners of each model block, followed by the block resistivity.
            %}
            while contains(tline,'/')
                tline = fgets(fid);
            end
            while ~contains(tline,'/')
                arr = str2num(tline);
                obj.CellBlockCoordsNoTopo = cat(1, obj.CellBlockCoordsNoTopo, arr);
                tline = fgets(fid);
            end
            %% BLOCK 7: Model Blocks w/ Topography
            if obj.topographyFlag == 1
                disp('...Reading BLOCK 7: Model Blocks (Corners) w/ Topography');
                %{
/Coordinates of model blocks (with topography).
/The following section gives the X- and Z-coordinates of the four
/corners of each model block, followed by the block resistivity.
                %}
                while contains(tline,'/')
                    tline = fgets(fid);
                end
                while ~contains(tline,'/')
                    arr = str2num(tline);
                    obj.CellBlockCoordsTopo = cat(1, obj.CellBlockCoordsTopo, arr);
                    tline = fgets(fid);
                end
                
                %% BLOCK 8: Model Blocks w/ Topography
                disp('...Reading BLOCK 8: Model Blocks (Centers) w/ Topography');
                %{
/The following section gives the coordinates of the centers of
/the model blocks after incorporating the surface topography.
/The X and Z coordinates of the centres of the model blocks,
/The X coordinates are the surface distances, and not the true horizontal distance.
/the resistivity and conductivity of each blocks is given below.
                %}
                while contains(tline,'/')
                    tline = fgets(fid);
                end
                while ~contains(tline,'/')
                    if feof(fid) == 1
                        disp('Reach EOF.');
                        break
                    end
                    tline = fgets(fid);
                end
            end
            %% BLOCK 9: Model Blocks w/ GPS
            %{
/The following section gives the model output with the true or GPS coordinates
/The x, y and z coordinates of the centres of the model blocks, and
/The resistivity and conductivity of each block is given below.
            %}
            obj.GpsFlag = 0;
            disp('Checking GPS data...');
            while contains(tline,'/')
                if contains(tline,'GPS') == 1
                    obj.GpsFlag = 1;
                    disp('GPS data found.');
                end
                tline = fgets(fid);
            end
            if obj.GpsFlag == 1
                while ~contains(tline,'/')
                    if feof(fid) == 1
                        disp('Reach EOF.');
                        break
                    end
                    tline = fgets(fid);
                end
                %% BLOCK 10: Model Blocks w/ GPS & Topography
                %{
/The following section gives the coordinates of the centers of
/the model blocks after incorporating the surface topography.
/The X, Y and Z coordinates of the centres of the model blocks,
/the resistivity and conductivity of each blocks is given below.
                %}
                if obj.topographyFlag == 1
                    while contains(tline,'/')
                        tline = fgets(fid);
                    end
                    while ~contains(tline,'/')
                        if feof(fid) == 1
                            break
                        end
                        tline = fgets(fid);
                    end
                end
            end
            disp('Data loading finished');
            fclose(fid);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function plotModel_v2(obj,vals,titles)
            disp('Plotting...');
            %             figure('Color',[1 1 1],'Position',[0,0,1400,1000]);
            colormap jet;
            axis image;
            
            try size(obj.CellBlockCoordsTopo,2) == size(obj.CellBlockCoordsNoTopo,2);
                if obj.topographyFlag == 1
                    x1 = obj.CellBlockCoordsTopo(:,2);
                    y1 = obj.CellBlockCoordsTopo(:,3);
                    x2 = obj.CellBlockCoordsTopo(:,4);
                    y2 = obj.CellBlockCoordsTopo(:,5);
                    x3 = obj.CellBlockCoordsTopo(:,6);
                    y3 = obj.CellBlockCoordsTopo(:,7);
                    x4 = obj.CellBlockCoordsTopo(:,8);
                    y4 = obj.CellBlockCoordsTopo(:,9);
                    p = patch([x1,x2,x3,x4]',[y1,y2,y3,y4]',vals,'AlignVertexCenters','on');
                else
                    x1 = obj.CellBlockCoordsNoTopo(:,2);
                    y1 = -obj.CellBlockCoordsNoTopo(:,3);
                    x2 = obj.CellBlockCoordsNoTopo(:,4);
                    y2 = -obj.CellBlockCoordsNoTopo(:,5);
                    x3 = obj.CellBlockCoordsNoTopo(:,6);
                    y3 = -obj.CellBlockCoordsNoTopo(:,7);
                    x4 = obj.CellBlockCoordsNoTopo(:,8);
                    y4 = -obj.CellBlockCoordsNoTopo(:,9);
                    patch([x1,x2,x3,x4]',[y1,y2,y3,y4]',vals,'AlignVertexCenters','on');
                end
                
            catch
                disp(['Number of cells are not the same. ', ...
                    'This suggests the extended model was not used. '])
                
                disp('Expanding cells artificially...')
                
                j=1;
                newX1 = [];
                newY1 = [];
                newX2 = [];
                newY2 = [];
                newX3 = [];
                newY3 = [];
                newX4 = [];
                newY4 = [];
                newRho = []; % not required
                newReso1 = [];
                newReso2 = [];
                newVals = [];
                unitSpacing = median(obj.CellBlockCoordsNoTopo((2:end),2)-obj.CellBlockCoordsNoTopo((1:end-1),2));
                disp(['Detected unit cell spacing is ', num2str(unitSpacing)]);
                for i = 1:length(obj.CellBlockCoordsTopo)
                    a = round(obj.CellBlockCoordsTopo(i,2)./unitSpacing).*unitSpacing;
                    b = obj.CellBlockCoordsNoTopo(j,2);
                    
                    if a == b
                        if j >= length(obj.CellBlockCoordsNoTopo)
                            j = length(obj.CellBlockCoordsNoTopo);
                        else
                            j = j+1;
                        end
                        newX1(end+1,1) = obj.CellBlockCoordsTopo(i,2);
                        newY1(end+1,1) = obj.CellBlockCoordsTopo(i,3);
                        newX2(end+1,1) = obj.CellBlockCoordsTopo(i,4);
                        newY2(end+1,1) = obj.CellBlockCoordsTopo(i,5);
                        newX3(end+1,1) = obj.CellBlockCoordsTopo(i,6);
                        newY3(end+1,1) = obj.CellBlockCoordsTopo(i,7);
                        newX4(end+1,1) = obj.CellBlockCoordsTopo(i,8);
                        newY4(end+1,1) = obj.CellBlockCoordsTopo(i,9);
                        newReso1(end+1,1) = obj.CellBlockCoordsNoTopo(j,11);
                        newReso2(end+1,1) = obj.CellBlockCoordsNoTopo(j,12);
                        newVals(end+1,1) = vals(j);
                        
                    else
                        switch a-b ~= unitSpacing % && abs(a-b) < 3*unitSpacing
                            case a < b % If difference is on left side
                                newX1(end+1,1) = obj.CellBlockCoordsTopo(i,2);
                                newY1(end+1,1) = obj.CellBlockCoordsTopo(i,3);
                                newX2(end+1,1) = obj.CellBlockCoordsTopo(i,4);
                                newY2(end+1,1) = obj.CellBlockCoordsTopo(i,5);
                                newX3(end+1,1) = obj.CellBlockCoordsTopo(i,6);
                                newY3(end+1,1) = obj.CellBlockCoordsTopo(i,7);
                                newX4(end+1,1) = obj.CellBlockCoordsTopo(i,8);
                                newY4(end+1,1) = obj.CellBlockCoordsTopo(i,9);
                                newReso1(end+1,1) = obj.CellBlockCoordsNoTopo(j,11);
                                newReso2(end+1,1) = obj.CellBlockCoordsNoTopo(j,12);
                                %                                 newVals(end+1,1) = vals(j);
                                newVals(end+1,1) = nan;
                                i=i+1;
                            case a > b % If difference is on right side
                                newX1(end+1,1) = obj.CellBlockCoordsTopo(i,2);
                                newY1(end+1,1) = obj.CellBlockCoordsTopo(i,3);
                                newX2(end+1,1) = obj.CellBlockCoordsTopo(i,4);
                                newY2(end+1,1) = obj.CellBlockCoordsTopo(i,5);
                                newX3(end+1,1) = obj.CellBlockCoordsTopo(i,6);
                                newY3(end+1,1) = obj.CellBlockCoordsTopo(i,7);
                                newX4(end+1,1) = obj.CellBlockCoordsTopo(i,8);
                                newY4(end+1,1) = obj.CellBlockCoordsTopo(i,9);
                                newReso1(end+1,1) = obj.CellBlockCoordsNoTopo(j,11);
                                newReso2(end+1,1) = obj.CellBlockCoordsNoTopo(j,12);
                                %                                 newVals(end+1,1) = vals(j);
                                newVals(end+1,1) = nan;
                                i=i+1;
                        end
                    end
                end
                
                % Blank cells on sides with data (the weird side-cells)
                a = isnan(newVals());
                for i = 2:length(newVals);
                    if a(i)
                        newVals(i-1) = nan;
                    end
                end
                % Check the number of cells is as expected.
                xTest = round(obj.CellBlockCoordsTopo(:,2)./unitSpacing).*unitSpacing;
                if ~any(newX1 == xTest);
                    disp(['Number of cells matches dataset.']);
                else
                    disp(['Number of cells do not match!']);
                end
                
                x1 = newX1();
                y1 = newY1();
                x2 = newX2();
                y2 = newY2();
                x3 = newX3();
                y3 = newY3();
                x4 = newX4();
                y4 = newY4();
                %                 vals = newVals();
                
                % Plot
                patch([x1,x2,x3,x4]',[y1,y2,y3,y4]',newVals,'AlignVertexCenters','on');
            end
            
            ax = gca;
            % Labels and Annotations
            ax.FontSize = 18;
            ax.Title.String = [titles.plot];
            set(ax.Title, 'Interpreter', 'none');
            ax.Title.FontWeight = 'bold';
            box(ax,'off');
            xlabel('Distance (m)','Fontweight','bold');
            ylabel('Elevation (mASL)','Fontweight','bold');
            set(ax,'XMinorTick','on','YMinorTick','on', ...
                'TickDir','out','TickLength',[0.005,0.00125]);
        end
        function plotMismatch(obj)
            if obj.generalFormatFlag == 1
                % If no topo, z-coordinates are positive.
                if ~any(obj.DataPseudoDepth < 0)
                    obj.DataPseudoDepth = obj.DataPseudoDepth .* -1;
                end
                
                % Triangulate datapoints.
                TR = delaunayTriangulation(obj.DataMidPoint',obj.DataPseudoDepth');
                
                % Check unique values (for some reason, duplicates can happen).
                [C, ia, ic] = unique([obj.DataMidPoint;obj.DataPseudoDepth]','rows','stable');
                
                % Create new figure (white background)
                figure('Color',[1 1 1],'Position',[0,0,1920,1080])
                colormap jet
                
                % Setup three-row subplot
                obsVals = subplot(3,1,1);
                ax = gca;
                set(ax,'XMinorTick','on','YMinorTick','on', ...
                    'TickDir','out','TickLength',[0.005,0.00125]);
                ax.FontSize = 18;
                
                % Draw
                patch('faces',TR.ConnectivityList,'vertices',TR.Points, ...
                    'FaceColor','interp','FaceVertexCData',real(log10(obj.DataObservedApparentResistivity(ia)))', ...
                    'AlignVertexCenters','on', 'Linestyle','none');
                hold on;
                scatter(TR.Points(:,1),TR.Points(:,2),'.k');
                % Annotate
                title('Observed Apparent Resistivity','FontSize',18,'Fontweight','bold');
                ylabel('Psuedo-depth','FontSize',18);
                xlabel('Midpoint','FontSize',18);
                cb1 = colorbar('eastoutside');
                cb1.TickDirection = 'out';
                cb1.Label.String = '\Omega_{app}';
                dfTicks = cb1.Ticks;
                dfTicks(end+1) = max(caxis); % Add max c-axis value
                dfTicks = [min(caxis),dfTicks];
                cb1.Ticks = dfTicks;
                cb1.TickLabels = round((10.^dfTicks),2,'significant');
                
                
                calcVals = subplot(3,1,2);
                ax = gca;
                set(ax,'XMinorTick','on','YMinorTick','on', ...
                    'TickDir','out','TickLength',[0.005,0.00125]);
                ax.FontSize = 18;
                
                % Draw
                patch('faces',TR.ConnectivityList,'vertices',TR.Points, ...
                    'FaceColor','interp','FaceVertexCData', real(log10(obj.DataCalcApparentResistivity(ia)))', ...
                    'AlignVertexCenters','on', 'Linestyle','none');
                
                hold on;
                scatter(TR.Points(:,1),TR.Points(:,2),'.k');
                % Annotate
                title('Calculated Apparent Resistivity','FontSize',18,'Fontweight','bold');
                ylabel('Psuedo-depth','FontSize',18);
                xlabel('Midpoint','FontSize',18);
                cb2 = colorbar('eastoutside');
                cb2.Label.String = ['\Omega_{app}'];
                dfTicks = cb2.Ticks;
                dfTicks(end+1) = max(caxis);
                dfTicks = [min(caxis),dfTicks];
                cb2.Ticks = dfTicks;
                cb2.TickLabels = round((10.^dfTicks),2,'significant');
                cb2.TickDirection = 'out';
                
                misfitVals = subplot(3,1,3);
                ax = gca;
                set(ax,'XMinorTick','on','YMinorTick','on', ...
                    'TickDir','out','TickLength',[0.005,0.00125]);
                ax.FontSize = 18;
                
                % Draw
                patch('faces',TR.ConnectivityList,'vertices',TR.Points, ...
                    'FaceColor','interp','FaceVertexCData',obj.DataPercentLogarithmicDifference(ia)', ...
                    'AlignVertexCenters','on', 'Linestyle','none');
                
                hold on;
                scatter(TR.Points(:,1),TR.Points(:,2),'.k');
                
                % Annotate
                title('Psuedo-depth Datapoint Mismatch','FontSize',18,'Fontweight','bold');
                ylabel('Psuedo-depth','FontSize',18);
                xlabel('Midpoint','FontSize',18);
                cb3 = colorbar('eastoutside');
                cb3.Label.String = '% Mismatch';
                dfTicks = cb3.Ticks;
                
%                 dfTicks(end+1) = max(caxis);
%                 dfTicks = [min(caxis),dfTicks]
                
                cb3.Ticks = dfTicks;
                cb3.TickDirection = 'out';
                
                % Annotate Error
                p = plotboxpos;
                errbox = annotation(gcf, 'textbox', p, ...
                    'String', ['Global % Error = ', num2str(obj.rmserror)], ...
                    'verticalalignment', 'bottom', 'fitboxtotext', 'on', ...
                    'linestyle','none','FontSize', 18);
                set(errbox,'Position',[p(1),p(2)*1.15,p(3), p(4)])
            else
                disp('General format not used...cannot plot at this time.');
            end
        end
        
        function plotStats(obj)
            figure('Color',[1 1 1], 'Position',[250 250 1000,800])
            ax = gca;
            ax.FontSize = 18;

            h_ax = histogram(abs(obj.DataPercentLogarithmicDifference), ...
                'Normalization','probability', 'BinLimits',[0, 500], 'NumBins', 100);
            title({'Error Statistics';obj.modelName},'interpreter','none','FontSize',18,'Fontweight','bold');
            xlabel('%Error','FontSize',18,'Fontweight','normal');
            ylabel('Counts','FontSize',18,'Fontweight','normal');
            set(ax,'YMinorTick','on','YMinorGrid','off');
            set(ax,'XMinorTick','on','XMinorGrid','off');
            sc_ax = axes('Position',[0.5,0.45,0.35,0.4]);
            
            TF_median = isoutlier(obj.DataObservedApparentResistivity);
            scatter(obj.DataObservedApparentResistivity(~TF_median),obj.DataCalcApparentResistivity(~TF_median),'xk');
            title({'Observed vs Calculated Correlation';'Median outliers removed'});
            xlabel('Obs. App. Res. (Ohm.m)','FontSize',15,'Fontweight','normal');
            ylabel('Calc. App. Res (Ohm.m)','FontSize',15,'Fontweight','normal');
            set(sc_ax,'YMinorTick','on','YMinorGrid','on');
            set(sc_ax,'XMinorTick','on','XMinorGrid','on');
            
            median_sansOutliers = median(abs(obj.DataPercentLogarithmicDifference(~TF_median)));
            
            stats = {['#No. Outliers = ', num2str(sum(TF_median))], ...
                ['Global Err. % after outliers = ', num2str(median_sansOutliers)]};
            
            remBox = annotation(gcf, 'textbox', [0.5 0.2 0.2 0.2], ...
                    'String', stats , ...
                    'verticalalignment', 'bottom', 'fitboxtotext', 'on', ...
                    'linestyle','none','FontSize', 15);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Legacy plotting method (slow)
        function [vq_p] = plotModelTopo(obj,dx,dy, values, nContours, showCells, resoblank, blankFlag)
            disp('PLOTTING...');
            minX = min(obj.X);
            maxX = max(obj.X);
            xs = minX:dx:maxX;
            minY = min(obj.Elevation);
            maxY = max(obj.Elevation);
            ys = minY:dy:maxY;
            
            disp('Griding data...');
            tic;
            [xq,yq] = meshgrid(xs, ys);
            vq = griddata(obj.X,obj.Elevation, values, xq,yq);
            toc;
            
            disp('Boundary mapping...');
            tic;
            bounds = boundary([obj.X',obj.Elevation'],0.5);
            boundsPoly = [obj.X(bounds)',obj.Elevation(bounds)'];
            % 'inpolygon' take a long time. Needs updating somehow.
            in = inpolygon(xq,yq,boundsPoly(:,1),boundsPoly(:,2));
            vq(~in) = nan;
            toc;
            if size(resoblank) == 1
                p = prctile(vq(:),25);
                vq_p = (vq <= p);
                %                 vq(vq_p) = nan;
            elseif any(size(resoblank)>1) && blankFlag == 1
                vq(resoblank) = nan;
            end
            disp('Done.');
            
            disp('Drawing contours...');tic;
            contourf(xq,yq,vq,nContours,'LineColor','none');
            disp('Done.');toc;
            
            if showCells
                disp('Drawing cells...');tic;
                if obj.topographyFlag == 1
                    for i = 1 : 1 : size(obj.CellBlockCoordsNoTopo,1)
                        x1 = obj.CellBlockCoordsNoTopo(i,2);
                        y1 = obj.CellBlockCoordsNoTopo(i,3);
                        x2 = obj.CellBlockCoordsNoTopo(i,4);
                        y2 = obj.CellBlockCoordsNoTopo(i,5);
                        x3 = obj.CellBlockCoordsNoTopo(i,6);
                        y3 = obj.CellBlockCoordsNoTopo(i,7);
                        x4 = obj.CellBlockCoordsNoTopo(i,8);
                        y4 = obj.CellBlockCoordsNoTopo(i,9);
                        res = obj.CellBlockCoordsNoTopo(i,10);
                        hold on;
                        cArr = [0.1 0.1 0.1];
                        lineWidth = 0.1;
                        fill([x1;x2;x3;x4],[y1;y2;y3;y4],'r','EdgeColor', ...
                            cArr,'LineWidth',lineWidth,'FaceAlpha',0, ...
                            'AlignVertexCenters','on')
                        hold off;
                    end
                else
                    for i = 1 : 1 : size(obj.CellBlockCoordsTopo,1)
                        x1 = obj.CellBlockCoordsTopo(i,2);
                        y1 = obj.CellBlockCoordsTopo(i,3);
                        x2 = obj.CellBlockCoordsTopo(i,4);
                        y2 = obj.CellBlockCoordsTopo(i,5);
                        x3 = obj.CellBlockCoordsTopo(i,6);
                        y3 = obj.CellBlockCoordsTopo(i,7);
                        x4 = obj.CellBlockCoordsTopo(i,8);
                        y4 = obj.CellBlockCoordsTopo(i,9);
                        res = obj.CellBlockCoordsTopo(i,10);
                        hold on;
                        cArr = [0.1 0.1 0.1];
                        lineWidth = 0.1;
                        fill([x1;x2;x3;x4],[y1;y2;y3;y4],'r','EdgeColor', ...
                            cArr,'LineWidth',lineWidth,'FaceAlpha',0, ...
                            'AlignVertexCenters','on')
                        hold off;
                    end
                end
                disp('Done.'); toc;
            end
            
            disp('Drawing topography...');tic;
            hold on;
            plot(obj.offsets,obj.topo,'k','linewidth',2);
            hold off;
            disp('Done.'); toc;
            
        end
    end
end
