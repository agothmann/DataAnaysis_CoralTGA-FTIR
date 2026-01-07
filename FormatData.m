function [fn, F_temp, Water, D2O, D2O_2, D2O_3, CO2] = FormatData(SpaPath, H, C, D, D2, D3)
   
    % Script to read in TGA FTIR data and plot absorption at a wavenumber as a
    % function of temp. 
    
    %None of the code in this script will inverse any data, nor will it
    %subtract the initial run background from the data
    
    
    %This code promts us to select the first data sample
    [filename, pathname] = uigetfile( ...
    {  '*.xlsx', 'Excel files (*.xlsx)'; ...
       '*.*',  'All Files (*.*)'}, ...
       'Select an XLSX file', './MATLAB/');
    
    TEXTfiles = readmatrix([pathname filename],'OutputType','char');
    
    sz = zeros(1,2,length(TEXTfiles));
    MasterData = zeros(14105,2,(length(TEXTfiles))); % 14105 is the number of unique wavenumbers collected by the TGAFTIR instrument
    
    WaveNumber = readmatrix([pathname char(TEXTfiles(length(TEXTfiles)))]);
    for i = 1:(length(TEXTfiles))
        sz(:,:,i) = size(readmatrix([pathname char(TEXTfiles(i))]));
        if sz(:,2,i) < 3
            %This code is checking if the data in the correct size, and
            %proceeding only if it is
            
            MasterData(:,:,i) = readmatrix([pathname char(TEXTfiles(i))]); %-readmatrix([pathname char(TEXTfiles(length(TEXTfiles)))]);
            MasterData(:,1,i) = WaveNumber(:,1);
        else
        end
    end
    
    filename = split(filename, '_Filenames.xlsx');
    
    
    %ONE TIME read in of excel sheet, finding the right sample name
    SpaData = readcell(SpaPath);
    sizeSpa = size(SpaData);
    rowSpa = sizeSpa(1,1);
    
    for i = 1:1:rowSpa
        str1 = string(SpaData{i,1});
        str2 = string(filename{1:1});
        if strcmp(str1,str2)
            DataRow = i;
        end
    end
    
    %reading in data from the above Excel sheet
    RunStart = SpaData{DataRow,2}; %sample run START time
    RunEnd = SpaData{DataRow,3}; %sample run END time
    RunDivision = SpaData{DataRow,4}; %number of SPA files for this particular dataset
    subtract = SpaData{DataRow,5}; %data time correction, if needed
    
    STEP = ((RunEnd-RunStart)/(RunDivision-1));
    FTIR_time = RunStart:STEP:RunEnd;
    
    
    %continuing finishing converting filename to a usable label
    filename = char(strrep(filename,'_','-'));
    
    %initializing Water and CO2 data arrays
    WaterData = zeros((length(TEXTfiles)),1);
    CO2Data = zeros((length(TEXTfiles)),1);
    D2OData = zeros((length(TEXTfiles)),1);
    D2OData2 = zeros((length(TEXTfiles)),1);
    D2OData3 = zeros((length(TEXTfiles)),1);
    
    
    for jj = 1:(length(TEXTfiles))
        WaterData(jj,:) = MasterData(H,2,jj); %*(-1); this is where you would do the average of local wave numbers
        CO2Data(jj,:) = MasterData(C,2,jj); %*(-1);
        D2OData(jj,:) = MasterData(D,2,jj);
        if D2 ~= 0
            D2OData2(jj,:) = MasterData(D2, 2, jj);
        end
        if D3 ~= 0
            D2OData3(jj,:) = MasterData(D3, 2, jj);
        end
    end
    
    
    %This code promts us to read in the TEXT file from the selected sample
    %Read in the TGA time and temp
    [TGAfile, TGApath] = uigetfile('*.txt', 'Select ' + convertCharsToStrings(filename) + ' TEXT file');
    TGA_data = readcell([TGApath TGAfile]);
    
    %find where "StartOfData" is written in the file
    for r = 1:length(TGA_data(:,1))
        str3 = string(TGA_data(r,1));
        chop = "StartOfData";
        if strcmp(str3,chop) == true
            ChopAfter = r;
        end
    end
    
    TGA_data = TGA_data(ChopAfter+2:end,1:4);
    %This is ChopAfter + 2 because we don't want to include the row with
    %"StartOfData", nor do we want the first row of "actual data", because it
    %looks weird
    
    %{
    Col1	Time (min)
    Col2	Temperature (°C)
    Col3	Weight (mg)
    Col4	Balance Purge Flow (mL/min)
    Col5	Sample Purge Flow (mL/min)
    %}
    
    TGA_time = TGA_data(:,1);
    TGA_time = cell2mat(TGA_time)-subtract; %subtracting warm up time period, if needed
    TGA_time = (TGA_time.');
    
    TGA_temp = cell2mat(TGA_data(:,2));
    weight = cell2mat(TGA_data(:,3));
    
    %INTERPOLATE instead of curve fit
    FTIR_temp = interp1(TGA_time,TGA_temp,FTIR_time);
    
    
    %getting rid of weird zero datapoints
    pp=1;
    while pp <= (length(FTIR_time))-1
        if WaterData(pp) == 0
            disp('true')
            WaterData(pp)=[];
            CO2Data(pp)=[];
            D2OData(pp)=[];
            D2OData2(pp)=[];
            D2OData3(pp)=[];
            FTIR_temp(pp)=[];        
            FTIR_time(pp)=[];
        else
            pp=pp+1;
        end
    end
    
    F_temp = FTIR_temp;
    Water = WaterData;
    D2O = D2OData;
    D2O_2 = D2OData2;
    D2O_3 = D2OData3;
    CO2 = CO2Data;
    fn = filename;



end