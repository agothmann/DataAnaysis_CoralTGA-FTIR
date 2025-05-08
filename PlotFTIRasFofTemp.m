% Script to read in TGA FTIR data and plot absorption at a wavenumber as a
% function of temp. 

% None of the code in this script will inverse any data, nor will it
% subtract the initial run background from the data

% To run this script, make sure our version of the backcor function is in
% the same folder as this script


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

% configuring the filename just for data acquision and graph title purposes
filename = split(filename, '_Filenames.xlsx');


%ONE TIME read in of excel sheet, finding the right sample name
% This is also used for sample A, but is not re-imported
SpaData = readcell('C:\Users\lizzy_u4nmadb\OneDrive\Documents\MATLAB\TGAFTIR_DATA\SPA_Time_Data.xlsx');
sizeSpa = size(SpaData);
rowSpa = sizeSpa(1,1);

%This is using the input sample name to find the data for the right sample
for i = 1:1:rowSpa
    str1 = string(SpaData{i,1});
    str2 = string(filename{1:1});
    if strcmp(str1,str2)
        %as it runs through the rows of SpaData, if the string it sees in
        %the row is the same as the string of the filename we input
        DataRow = i;
        %then take note of that row, and assign it to DataRow
    end
end

%reading in the correct data from the above Excel sheet
RunStart = SpaData{DataRow,2}; %sample run START time
RunEnd = SpaData{DataRow,3}; %sample run END time
RunDivision = SpaData{DataRow,4}; %number of SPA files for this particular dataset
subtract = SpaData{DataRow,5}; %data time correction, if needed
back_corr = SpaData{DataRow,6}; % 0 or 1 on whether the sample needs background subtraction

STEP = ((RunEnd-RunStart)/(RunDivision-1));
FTIR_time = RunStart:STEP:RunEnd;


%continuing finishing converting filename to a usable label
filename = char(strrep(filename,'_','-'));

%initializing Water and CO2 data arrays
WaterData = zeros((length(TEXTfiles)),1);
CO2Data = zeros((length(TEXTfiles)),1);

% selecting the specific wavenumber for Water and CO2
for jj = 1:(length(TEXTfiles))
    WaterData(jj,:) = MasterData(3768,2,jj);
    CO2Data(jj,:) = MasterData(7256,2,jj);
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
        %when iterating through all the rows of the text file, when the row
        %reads "StartOfData", assign that row index to ChopAfter
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
weight = cell2mat(TGA_data(:,3)); %not currently used



% NEW ADDITION FOR BACKGROUND SUBTRACTION

% Cut FTIR_time off when it starts getting bigger than the end value of
% TGA_time

%find the last value of TGA_time
lastTGA = TGA_time(1,end);
cutData = zeros(length(FTIR_time),1);

index = 1;
for val = 1:length(FTIR_time)
    %iterate through the indices of FTIR_time
    if lastTGA < FTIR_time(1,val)
        %if the highest value of the TGA data is less than a data value in
        %FTIR time, then take note of the index
        cutData(index) = val;
        %taking note of each index where above is true, and appending it to
        %a list, but we only will need the value in the FIRST index of this
        index = index + 1;
    end
end

FTIR_time = FTIR_time(1,1:(cutData(1,1))-1);
%end FTIR time before the values start getting larger than the existing TGA
%data

% END NEW ADDITION




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
        FTIR_temp(pp)=[];        
        FTIR_time(pp)=[];
    else
        pp=pp+1;
    end
end




%IMPORTING A SECOND RUN, labeled A

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
back_corr_A = SpaData{DataRow_A,6};

STEP_A = ((RunEnd_A-RunStart_A)/(RunDivision_A-1));
FTIR_time_A = RunStart_A:STEP_A:RunEnd_A;

filenameA = char(strrep(filenameA,'_','-'));


WaterDataA = zeros((length(TEXTfilesA)),1);
CO2DataA = zeros((length(TEXTfilesA)),1);


for jj = 1:(length(TEXTfilesA))
    WaterDataA(jj,:) = MasterDataA(3768,2,jj);
    CO2DataA(jj,:) = MasterDataA(7256,2,jj);
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






% NEW ADDITION FOR BACKGROUND SUBTRACTION

% Cut FTIR_time off when it starts getting bigger than the end value of
% TGA_time

%find the last value of TGA_time
lastTGA_A = TGA_time_A(1,end);
cutData_A = zeros(length(FTIR_time_A),1);

index_A = 1;
for val_A = 1:length(FTIR_time_A) %comments in section above
    if lastTGA_A < FTIR_time_A(1,val_A)
        
        cutData_A(index_A) = val_A;
        index_A = index_A + 1;
    end
end

FTIR_time_A = FTIR_time_A(1,1:(cutData_A(1,1))-1);

%END NEW ADDITION





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
        FTIR_temp_A(pp)=[];
        FTIR_time_A(pp)=[];
    else
        pp=pp+1;
    end
end



%% BACKGROUND SUBTRACTION SET UP

%Need to change the formatting of these arrays so backcor will take them
FTIR_temp = FTIR_temp.';
WaterData = WaterData.';
CO2Data = CO2Data.';

FTIR_temp_A = FTIR_temp_A.';
WaterDataA = WaterDataA.';
CO2DataA = CO2DataA.';

%%
% cut the CO2 data for every datapoint before the temp 50 to get rid of
% outlying data points at the beginning of the run
CO2_cut = 50;
new_CO2_start = 0;
o = 1;
while new_CO2_start == 0
    %while nothing has changed with the initialized variable
    if floor(FTIR_temp(o,1)) > CO2_cut
        %if the rounded down value in the 'oth' row of FTIR temp data is
        %BIGGER than 50
        new_CO2_start = o;
        %set the initialized variable to the first index where that is true
    end
    o = o + 1;
    %it continues interating only if new_CO2_start is unchanged, as in, 0
end
%need to cut BOTH the CO2Data and the FTIR temp data in order to use the
%backcor function and graph the data correctly
CO2Data = CO2Data(1, new_CO2_start:end);
FTIR_temp_CO2 = FTIR_temp(new_CO2_start:end, 1);

CO2_cut = 50;
new_CO2_start = 0;
o = 1;
while new_CO2_start == 0
    if floor(FTIR_temp_A(o,1)) > CO2_cut
        new_CO2_start = o;
    end
    o = o + 1;
end
CO2DataA = CO2DataA(1, new_CO2_start:end);
FTIR_temp_CO2_A = FTIR_temp_A(new_CO2_start:end, 1);

%cutting the H2o at temp 40
%everything is the same for water, except the data is cut off at 40 degrees
H2O_cut = 40;
new_H2O_start = 0;
o = 1;
while new_H2O_start == 0
    if floor(FTIR_temp(o,1)) > H2O_cut
        new_H2O_start = o;
    end
    o = o + 1;
end
WaterData = WaterData(1, new_H2O_start:end);
FTIR_temp_H2O = FTIR_temp(new_H2O_start:end, 1);

H2O_cut = 40;
new_H2O_start = 0;
o = 1;
while new_H2O_start == 0
    if floor(FTIR_temp_A(o,1)) > H2O_cut
        new_H2O_start = o;
    end
    o = o + 1;
end
WaterDataA = WaterDataA(1, new_H2O_start:end);
FTIR_temp_H2O_A = FTIR_temp_A(new_H2O_start:end, 1);

%% BACKGROUND CORRECTION FUNCTION

ord = 4; %Good order for water has been 4
CO2ord = 2; %Good order for CO2 has been 2

% If the sample selected doesn't need background correction, the program
% will figure that out from the Spa Data excel, and it will set the
% variable back_corr to 0, so that this next loop will set the ord to 1
if back_corr == 0
    ord = 1;
    CO2ord = 1;
end

% s is the threshold number (how low of number will be considered positive)
s = 0.01;
% fct is the type of function used to estimate the background
% so far the fct has not seemed to matter
fct = 'atq';

%THIS FUNCTION HAS NO POP UP
[z,a,it,ord,s,fct] = backcor(FTIR_temp_H2O, WaterData, ord, s, fct);
[zz, aa, itit, ordord, ss, fctfct] = backcor(FTIR_temp_CO2, CO2Data, CO2ord, s, fct);


ord_A = 4;
CO2ord_A = 2;

if back_corr_A == 0
    ord_A = 1;
    CO2ord_A = 1;
end

%THIS FUNCTION HAS NO POP UP
[z_A,a_A,it_A,ord_A,s_A,fct_A] = backcor(FTIR_temp_H2O_A, WaterDataA, ord_A, s, fct);
[zz_A, aa_A, itit_A, ordord_A, ss_A, fctfct_A] = backcor(FTIR_temp_CO2_A, CO2DataA, CO2ord_A, s, fct);


%{
%THIS FUNCTION HAS A POP UP ASKING YOU TO VERIFY THE BACKGROUND ORDER
%AND IT WILL SET THE THRESHOLD AND FUNC FOR YOU

[z, a, it, ord, s, fct] = backcor(FTIR_temp_H2O, WaterData);
[zz, aa, itit, ordord, ss, fctfct] = backcor(FTIR_temp_CO2, CO2Data);

[z_A, a_A, it_A, ord_A, s_A, fct_A] = backcor(FTIR_temp_H2O_A,WaterDataA);
[zz_A, aa_A, itit_A, ordord_A, ss_A, fctfct_A] = backcor(FTIR_temp_CO2_A, CO2DataA);
%}


%Sorting and formatting more data in order to plot correctly
% !! taken from demo.m given with the backcor function !!
if ~isempty(z)
    
    [FTIR_temp_H2O,i] = sort(FTIR_temp_H2O);
    WaterData = WaterData(i);
    z = z(i);
    z = z.';
    
end

if ~isempty(zz)
    
    [FTIR_temp_CO2,i] = sort(FTIR_temp_CO2);
    CO2Data = CO2Data(i);
    zz = zz(i);
    zz = zz.';
    
end

if ~isempty(z_A)
    
    [FTIR_temp_H2O_A,i] = sort(FTIR_temp_H2O_A);
    WaterDataA = WaterDataA(i);
    z_A = z_A(i);
    z_A = z_A.';
    
end

if ~isempty(zz_A)
    
    [FTIR_temp_CO2_A,i] = sort(FTIR_temp_CO2_A);
    CO2DataA = CO2DataA(i);
    zz_A = zz_A(i);
    zz_A = zz_A.';
    
end


%% PLOTTING

%{
% Combined sample plots of water and CO2 data
figure(1) 
%Water
subplot(1,2,1)
plot(FTIR_temp_H2O,WaterData-z, "LineWidth",1,"Color","b")
%z is the background that is being subtracted from WaterData
hold on
plot(FTIR_temp_H2O_A,WaterDataA-z_A, "LineWidth",1,"Color","c")
title('Both samples')
subtitle("H2O Data (BKG CORR)")
xlabel("Temp (C)")
ylabel("H2O Absorption")
legend(filename, filenameA, "Location","northwest")
grid on
hold off
%Co2
subplot(1,2,2)
plot(FTIR_temp_CO2,CO2Data-zz, "LineWidth",1,"Color","#7E2F8E")
hold on
plot(FTIR_temp_CO2_A,CO2DataA-zz_A, "LineWidth",1,"Color","#FF00FF")
subtitle("CO2 Data (BKG CORR)")
xlabel("Temp (C)")
ylabel("CO2 Absorption")
legend(filename, filenameA, "Location","northwest")
grid on
hold off
%}


%Separate plots
figure(1) %comparing the water peaks of the two samples
plot(FTIR_temp_H2O,WaterData-z, "LineWidth",1,"Color","b")
hold on
plot(FTIR_temp_H2O_A,WaterDataA-z_A, "LineWidth",1,"Color","c")
title("H2O Data - absorption at peak wavenumber (BKG CORR)")
xlabel("Temp (C)")
ylabel("H2O Absorption")
legend(filename, filenameA, "Location","northwest")
grid on
hold off

figure(2) %comparing the CO2 peaks of the two samples
plot(FTIR_temp_CO2,CO2Data-zz, "LineWidth",1,"Color","#7E2F8E")
hold on
plot(FTIR_temp_CO2_A,CO2DataA-zz_A, "LineWidth",1,"Color","#FF00FF")
title("CO2 Data - absorption at peak wavenumber (BKG CORR)")
xlabel("Temp (C)")
ylabel("CO2 Absorption")
legend(filename, filenameA, "Location","northwest")
grid on
hold off
%}


figure(3) %Water and CO2 data of just sample 1
plot(FTIR_temp_H2O,WaterData-z,"LineWidth",1,"Color","b")
hold on
plot(FTIR_temp_CO2,CO2Data-zz,"LineWidth",1,"Color","r")
title(filename)
subtitle('H2O vs CO2 (BKG CORR)')
xlabel("Temp (C)")
ylabel("Absorption value")
legend("H2O","CO2","Location","northwest")
grid on
hold off

figure(4) %Water and CO2 data of just sample 2
plot(FTIR_temp_H2O_A,WaterDataA-z_A,"LineWidth",1,"Color","b")
hold on
plot(FTIR_temp_CO2_A,CO2DataA-zz_A,"LineWidth",1,"Color","r")
title(filenameA)
subtitle('H2O vs CO2 (BKG CORR)')
xlabel("Temp (C)")
ylabel("Absorption value")
legend("H2O","CO2","Location","northwest")
grid on
hold off




%% BACKGROUND PLOTTING
% Each plot will only display IF their corresponding sample needed
% background correction

% Sample 1 water and CO2 background correction
if back_corr == 0
    disp('no back corr for sample 1')
else
    figure;
    subplot(2,2,1)
    plot(FTIR_temp_H2O,WaterData,'b',FTIR_temp_H2O,z,'r');
    xlabel('Temp (C)')
    ylabel('H2O abs')
    legend('Spec','Bkg est');
    title(filename)
    subtitle(['Estimation with function ''' fct ''', order = ' num2str(ord) ' and threshold = ' num2str(s)])
    subplot(2,2,3)
    plot(FTIR_temp_H2O,WaterData-z,'r')
    xlabel('Temp (C)')
    ylabel('H2O abs')
    subtitle('Corrected spectrum')
    %legend('Estimated corrected spectrum')
    
    subplot(2,2,2)
    plot(FTIR_temp_CO2,CO2Data,'b',FTIR_temp_CO2,zz,'r')
    xlabel('Temp (C)')
    ylabel('CO2 abs')
    legend('Spec','Bkg est','Location','north')
    %title(filename)
    subtitle(['Estimation with function ''' fctfct ''', order = ' num2str(ordord) ' and threshold = ' num2str(ss)])
    subplot(2,2,4)
    plot(FTIR_temp_CO2,CO2Data-zz,'r')
    xlabel('Temp (C)')
    ylabel('CO2 abs')
    subtitle('Corrected spectrum')
    %legend('Estimated corrected spectrum')
end



% Sample 2 water and CO2 background plotting
if back_corr_A == 0
    disp('no back corr for sample 2')
else
    figure;
    subplot(2,2,1)
    plot(FTIR_temp_H2O_A,WaterDataA,'b',FTIR_temp_H2O_A,z_A,'r')
    xlabel('Temp (C)')
    ylabel('H2O abs')
    legend('Spec','Bkg est')
    title(filenameA)
    subtitle(['Estimation with function ''' fct_A ''', order = ' num2str(ord_A) ' and threshold = ' num2str(s_A)])
    subplot(2,2,3)
    plot(FTIR_temp_H2O_A,WaterDataA-z_A,'r')
    xlabel('Temp (C)')
    ylabel('H2O abs')
    subtitle('Corrected spectrum')
    %legend('Estimated corrected spectrum')
    
    subplot(2,2,2)
    plot(FTIR_temp_CO2_A,CO2DataA,'b',FTIR_temp_CO2_A,zz_A,'r')
    xlabel('Temp (C)')
    ylabel('CO2 abs')
    legend('Spec','Bkg est','Location','north')
    %title(filenameA)
    subtitle(['Estimation with function ''' fctfct_A ''', order = ' num2str(ordord_A) ' and threshold = ' num2str(ss_A)])
    subplot(2,2,4)
    plot(FTIR_temp_CO2_A,CO2DataA-zz_A,'r')
    xlabel('Temp (C)')
    ylabel('CO2 abs')
    subtitle('Corrected spectrum')
    %legend('Estimated corrected spectrum')
end



%% EXTRA PLOTTING

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