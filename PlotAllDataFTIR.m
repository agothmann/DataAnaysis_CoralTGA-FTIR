
%Run just this section to plot ALL the data together, H2O or CO2

file_tot = 9; %This number will need to be manually changed to reflect the number of coral samples

for A = 1:file_tot
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
    
    %ONE TIME read in of excel sheet, finding the right sample name
    SpaData = readcell('C:\Users\lizzy_u4nmadb\OneDrive\Documents\MATLAB\TGAFTIR_DATA\SPA_Time_Data.xlsx');
    sizeSpa = size(SpaData);
    rowSpa = sizeSpa(1,1);
    
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
        WaterDataA(jj,:) = MasterDataA(3768,2,jj); %*(-1);
        CO2DataA(jj,:) = MasterDataA(7256,2,jj); %*(-1);
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

    %formatting for backcor
    FTIR_temp_A = FTIR_temp_A.';
    WaterDataA = WaterDataA.';
    CO2DataA = CO2DataA.';

    %Cutting CO2 data at temp 50
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

    %Cut H2O data at temp 40
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

    ord_A = 4;
    CO2ord_A = 2;
    s = 0.01;
    fct = 'atq';

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
    [z_A, a_A, it_A, ord_A, s_A, fct_A] = backcor(FTIR_temp_H2O_A,WaterDataA);
    [zz_A, aa_A, itit_A, ordord_A, ss_A, fctfct_A] = backcor(FTIR_temp_CO2_A, CO2DataA);
    %}


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



    colorA = [rand rand rand];
    figure(1) %WATER PEAKS
    plot(FTIR_temp_H2O_A,WaterDataA-z_A, "LineWidth",1,"Color",colorA)
    legstr{A}=filenameA;
    hold on

    %{
    figure(2) %CO2 PEAKS
    plot(FTIR_temp_CO2_A,CO2DataA-zz_A, "LineWidth",1,"Color",colorA)
    legstr{A}=filenameA;
    hold on
%}
end
legend(legstr, "Location","northwest")
title("All H2O Peaks (BKG CORR) ")
xlabel("Temp (C)")
ylabel("H2O Absorption")
grid on
hold off

%{
%CO2
legend(legstr, "Location","northwest")
title("All CO2 Peaks (BKG CORR)")
xlabel("Temp (C)")
ylabel("CO2 Absorption")
grid on
hold off
%}




%%

%Run just this section if you want a comparison between ERP and CWC
%START WITH ERP

ERP_tot = 5;


for A = 1:ERP_tot
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
    
    %ONE TIME read in of excel sheet, finding the right sample name
    SpaData = readcell('C:\Users\lizzy_u4nmadb\OneDrive\Documents\MATLAB\TGAFTIR_DATA\SPA_Time_Data.xlsx');
    sizeSpa = size(SpaData);
    rowSpa = sizeSpa(1,1);
    
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
        WaterDataA(jj,:) = MasterDataA(3768,2,jj); %*(-1);
        CO2DataA(jj,:) = MasterDataA(7256,2,jj); %*(-1);
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

    %formatting for backcor
    FTIR_temp_A = FTIR_temp_A.';
    WaterDataA = WaterDataA.';
    CO2DataA = CO2DataA.';

    %Cutting CO2 data at temp 50
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

    %Cut H2O data at temp 40
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

    ord_A = 4;
    CO2ord_A = 2;
    s = 0.01;
    fct = 'atq';

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
    [z_A, a_A, it_A, ord_A, s_A, fct_A] = backcor(FTIR_temp_H2O_A,WaterDataA);
    [zz_A, aa_A, itit_A, ordord_A, ss_A, fctfct_A] = backcor(FTIR_temp_CO2_A, CO2DataA);
    %}


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



    colorA = [rand rand rand];
    figure(2) %WATER PEAKS
    plot(FTIR_temp_H2O_A,WaterDataA-z_A, "LineWidth",1,"Color",colorA)
    legstr{A}=filenameA;
    hold on

    %{
    figure(2) %CO2 PEAKS
    plot(FTIR_temp_CO2_A,CO2DataA-zz_A, "LineWidth",1,"Color",colorA)
    legstr{A}=filenameA;
    hold on
%}
end
legend(legstr, "Location","northwest")
title("H2O Data - ERP absorption (BKG CORR)")
xlabel("Temp (C)")
ylabel("H2O Absorption")
grid on
hold off

%{
%CO2
legend(legstr, "Location","northwest")
title("CO2 Data - ERP absorption (BKG CORR)")
xlabel("Temp (C)")
ylabel("CO2 Absorption")
grid on
hold off
%}




%IMPORTING CWC%%%%%%%


CWC_tot = 4;


for A = 1:CWC_tot
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
    
    %ONE TIME read in of excel sheet, finding the right sample name
    SpaData = readcell('C:\Users\lizzy_u4nmadb\OneDrive\Documents\MATLAB\TGAFTIR_DATA\SPA_Time_Data.xlsx');
    sizeSpa = size(SpaData);
    rowSpa = sizeSpa(1,1);
    
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
        WaterDataA(jj,:) = MasterDataA(3768,2,jj); %*(-1);
        CO2DataA(jj,:) = MasterDataA(7256,2,jj); %*(-1);
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

    %formatting for backcor
    FTIR_temp_A = FTIR_temp_A.';
    WaterDataA = WaterDataA.';
    CO2DataA = CO2DataA.';

    %Cutting CO2 data at temp 50
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

    %Cut H2O data at temp 40
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

    ord_A = 4;
    CO2ord_A = 2;
    s = 0.01;
    fct = 'atq';

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
    [z_A, a_A, it_A, ord_A, s_A, fct_A] = backcor(FTIR_temp_H2O_A,WaterDataA);
    [zz_A, aa_A, itit_A, ordord_A, ss_A, fctfct_A] = backcor(FTIR_temp_CO2_A, CO2DataA);
    %}


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



    colorA = [rand rand rand];
    figure(3) %WATER PEAKS
    plot(FTIR_temp_H2O_A,WaterDataA-z_A, "LineWidth",1,"Color",colorA)
    legstr{A}=filenameA;
    hold on

    %{
    figure(3) %CO2 PEAKS
    plot(FTIR_temp_CO2_A,CO2DataA-zz_A, "LineWidth",1,"Color",colorA)
    legstr{A}=filenameA;
    hold on
%}
end
%WATER
legend(legstr, "Location","northwest")
title("H2O Data - CWC absorption (BKG CORR)")
xlabel("Temp (C)")
ylabel("H2O Absorption")
grid on
hold off

%{
%CO2
legend(legstr, "Location","northwest")
title("CO2 Data - CWC absorption (BKG CORR)")
xlabel("Temp (C)")
ylabel("CO2 Absorption")
grid on
hold off
%}

