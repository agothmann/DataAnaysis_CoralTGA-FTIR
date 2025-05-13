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
SpaData = readcell('C:/Users/peter/OneDrive/Documents/MATLAB/CSVs/SPA_Time_Data (1).xlsx');
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


for jj = 1:(length(TEXTfiles))
    WaterData(jj,:) = MasterData(3768,2,jj); %*(-1); this is where you would do the average of local wave numbers
    CO2Data(jj,:) = MasterData(7256,2,jj); %*(-1);
    D2OData(jj,:) = MasterData(8797,2,jj);
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


%{
%This figure graphs the TGA time vs temp
figure(10)
plot(TGA_time,TGA_temp,"LineWidth",1,"Color","m")
hold on
title("TGA time vs temp")
xlabel("Time (min)")
ylabel("Temp (C)")
plot(FTIR_time,FTIR_temp,"Linewidth",1,"Color",'b')
legend("Time.v.Temp","Interpolation", "Location","northwest")
grid on
hold off
%}

%getting rid of weird zero datapoints
pp=1;
while pp <= (length(FTIR_time))-1
    if WaterData(pp) == 0
        disp('true')
        WaterData(pp)=[];
        CO2Data(pp)=[];
        D2OData(pp)=[];
        FTIR_temp(pp)=[];        
        FTIR_time(pp)=[];
    else
        pp=pp+1;
    end
end


%% 

%IMPORTING A SECOND RUN, labeled A
%{
[filenameA, pathnameA] = uigetfile( ...
{  '*.xlsx', 'Excel files (*.xlsx)'; ...
   '*.*',  'All Files (*.*)'}, ...
   'Select an XLSX file', './MATLAB/');

TEXTfilesA = readmatrix([pathnameA filenameA],'OutputType','char');

sz = zeros(1,2,length(TEXTfilesA));
MasterDataA = zeros(14105,2,(length(TEXTfilesA))); 

WaveNumberA = readmatrix([pathnameA char(TEXTfilesA(length(TEXTfilesA)))]);
for i = 1:(length(TEXTfilesA))
    sz(:,:,i) = size(readmatrix([pathnameA char(TEXTfilesA(i))]));
    if sz(:,2,i) < 3
        MasterDataA(:,:,i) = readmatrix([pathnameA char(TEXTfilesA(i))]); %-readmatrix([pathname char(TEXTfiles(length(TEXTfiles)))]);
        MasterDataA(:,1,i) = WaveNumberA(:,1);
    else
    end
end

filenameA = split(filenameA, '_Filenames.xlsx');


%Already imported the file in the first run
for i = 1:1:rowSpa
    str1 = string(SpaData{i,1});
    str2 = string(filenameA{1:1});
    if strcmp(str1,str2)
        DataRow_A = i;
    end
end

RunStart_A = SpaData{DataRow_A,2};
RunEnd_A = SpaData{DataRow_A,3}; 
RunDivision_A = SpaData{DataRow_A,4};
subtract_A = SpaData{DataRow_A,5};

STEP_A = ((RunEnd_A-RunStart_A)/(RunDivision_A-1));
FTIR_time_A = RunStart_A:STEP_A:RunEnd_A;

filenameA = char(strrep(filenameA,'_','-'));


WaterDataA = zeros((length(TEXTfilesA)),1);
CO2DataA = zeros((length(TEXTfilesA)),1);
D2ODataA = zeros((length(TEXTfilesA)),1);


for jj = 1:(length(TEXTfilesA))
    WaterDataA(jj,:) = MasterDataA(3768,2,jj); %*(-1);
    CO2DataA(jj,:) = MasterDataA(7256,2,jj); %*(-1);
    D2ODataA(jj,:) = MasterDataA(8797,2,jj);
end


%Read in the TGA time vs temp
[TGAfile_A, TGApath_A] = uigetfile('*.txt', 'Select ' + convertCharsToStrings(filenameA) + ' TEXT file');
TGA_data_A = readcell([TGApath_A TGAfile_A]);

%find where "StartOfData" is written in the file
for r = 1:length(TGA_data_A(:,1))
    str3 = string(TGA_data_A(r,1));
    chop = "StartOfData";
    if strcmp(str3,chop) == true
        ChopAfterA = r;
    end
end

TGA_data_A = TGA_data_A(ChopAfterA+2:end,1:4);
%This is ChopAfter + 2 because we don't want to include the row with
%"StartOfData", nor do we want the first row of "actual data", because it
%looks weird

TGA_time_A = TGA_data_A(:,1);
TGA_time_A = cell2mat(TGA_time_A)-(subtract_A); %Subtract the warm up time period if needed
TGA_time_A = (TGA_time_A.'); %convert time to a row instead of column

TGA_temp_A = cell2mat(TGA_data_A(:,2));
weight_A = cell2mat(TGA_data_A(:,3));

%INTERPOLATE instead of curve fit
FTIR_temp_A = interp1(TGA_time_A,TGA_temp_A,FTIR_time_A);


%{
%This figure graphs the TGA time vs temp
figure(11)
plot(TGA_time_A,TGA_temp_A,"LineWidth",1,"Color","m")
hold on
title("TGA time vs temp Sample A")
xlabel("Time (min)")
ylabel("Temp (C)")
plot(FTIR_time_A,FTIR_temp_A,"Linewidth",1,"Color",'b')
legend("Time.v.Temp","Interpolation", "Location","northwest")
grid on
hold off
%}


%getting rid of weird zero datapoints
pp=1;
while pp <= length(FTIR_time_A)
    if WaterDataA(pp) == 0
        disp('true')
        WaterDataA(pp)=[];
        CO2DataA(pp)=[];
        D2ODataA(pp)=[];
        FTIR_temp_A(pp)=[];
        FTIR_time_A(pp)=[];
    else
        pp=pp+1;
    end
end
%}


%%

%{

figure(1) %comparing the water peaks of the two samples
plot(FTIR_temp,WaterData, "LineWidth",1,"Color","b")
hold on
plot(FTIR_temp_A,WaterDataA, "LineWidth",1,"Color","c")
title("H2O Data - absorption at peak wavenumber")
xlabel("Temp (C)")
ylabel("H2O Absorption")
legend(filename, filenameA, "Location","northwest")
grid on
hold off

figure(2) %comparing the CO2 peaks of the two samples
plot(FTIR_temp,CO2Data, "LineWidth",1,"Color","#7E2F8E")
hold on
plot(FTIR_temp_A,CO2DataA, "LineWidth",1,"Color","#FF00FF")
title("CO2 Data - absorption at peak wavenumber")
xlabel("Temp (C)")
ylabel("CO2 Absorption")
legend(filename, filenameA, "Location","northwest")
grid on
hold off

figure(3) %Water and CO2 data of just sample 1
plot(FTIR_temp,WaterData,"LineWidth",1,"Color","b")
hold on
plot(FTIR_temp,CO2Data,"LineWidth",1,"Color","r")
title(filename)
subtitle('H2O vs CO2')
xlabel("Temp (C)")
ylabel("Absorption value")
legend("H2O","CO2","Location","northwest")
grid on
hold off


figure(4) %Water and CO2 data of just sample 2
plot(FTIR_temp_A,WaterDataA,"LineWidth",1,"Color","b")
hold on
plot(FTIR_temp_A,CO2DataA,"LineWidth",1,"Color","r")
title(filenameA)
subtitle('H2O vs CO2')
xlabel("Temp (C)")
ylabel("Absorption value")
legend("H2O","CO2","Location","northwest")
grid on
hold off

%}

figure(13) % Water and D2O data of sample 1

plot(FTIR_temp, WaterData, "LineWidth", 1.5, "Color", "b") % H2O in blue
hold on
plot(FTIR_temp, D2OData, "LineWidth", 1.5, "Color", [0.5 0.5 0.5]) % D2O in gray

title(filename, 'FontSize', 26)
subtitle('H2O vs D2O', 'FontSize', 16)
xlabel("Temp (C)", 'FontSize', 16)
ylabel("Absorption value", 'FontSize', 16)
legend("H2O", "D2O", "Location", "northwest", 'FontSize', 14)

ax = gca; % get current axes
ax.FontSize = 14; % set font size for tick labels

grid on
hold off





%%

%{


%These are the numbers to add to n for each corresponding dataset
num = floor(length(TEXTfiles)/9);
numA = floor(length(TEXTfilesA)/9);

%focus in on CO2 peaks, seeing if we are focusing on the right one

figure(5)
n = 1;
for l = 1:9
    subplot(3,3,l) %Plotting 9 little plots in a 3 by 3 grid
    sgtitle(filename)
    plot(MasterData(:,1,n), MasterData(:,2,n),"Color","r"); %*(-1);
    
    title("slice " + n + " of run") %or title(print(n))
    ylabel("Absorption Value", "FontSize",7)
    xlabel("Wavenumber", "FontSize",7)
    n = n + num;
    xlim([1120 1160]) %These are wavenumbers. we are focusing in around the 
    % wavenumbers associated with the data peak to hone the row number we 
    % correspond with it
end

%CO2 data peaks for the SECOND SET of data input
figure(6)
n = 1;
for l = 1:9
    subplot(3,3,l) %Plotting 9 little plots in a 3 by 3 grid
    sgtitle(filenameA)
    plot(MasterDataA(:,1,n), MasterDataA(:,2,n),"Color","r");
    
    title("slice " + n + " of run") %or title(print(n))
    ylabel("Absorption Value", "FontSize",7)
    xlabel("Wavenumber", "FontSize",7)
    n = n + numA;
    xlim([2355 2365])
end

%WATER DATA peak comparison for sample 1

figure(7)
n = 1;
for l = 1:9
    subplot(3,3,l) %Plotting 9 little plots in a 3 by 3 grid
    sgtitle(filename)
    plot(MasterData(:,1,n), MasterData(:,2,n),"Color","b");
    
    title("slice " + n + " of " + length(TEXTfiles))
    ylabel("Absorption Value", "FontSize",7)
    xlabel("Wavenumber", "FontSize",7)
    n = n + num;
    xlim([500 4100]) %zoom out
    %xlim([1540 1570]) %zoom in
end

%WATER DATA peak comparison for SAMPLE 2

figure(8)
n = 1;
for l = 1:9
    subplot(3,3,l) %Plotting 9 little plots in a 3 by 3 grid
    sgtitle(filenameA)
    plot(MasterDataA(:,1,n), MasterDataA(:,2,n),"Color","b");
    
    title("slice " + n + " of " + length(TEXTfilesA))
    ylabel("Absorption Value", "FontSize",7)
    xlabel("Wavenumber", "FontSize",7)
    n = n + numA;
    xlim([500 4100]) %zoom out
    %xlim([1540 1570]) %zoom in
end


%}