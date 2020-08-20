%% Error Calculation & Weighted Mean Combo
% Made by Robert J Scales. No grouping of data capability right now, that
% has to be done before this code.

function [OutputStructure]=WeightedError(f,variables,values,errors,SetUp,ID)
%% Example Initialisation
title = mfilename; % Names the title what the function is called.

EXAMPLE_ON = true;

if EXAMPLE_ON == true
    clearvars('-except','title','EXAMPLE_ON');
    clc
    DLG = warndlg(sprintf('%s Running in Example Mode!',title));
    waitfor(DLG);
    ID = "Weighted Data Example";
    SetUp.DisplayEquations = false;
    SetUp.LatexFormatEquations = false;
    SetUp.DisplayEndResult = false;
    SetUp.Debug = false;
    SetUp.FloatingPoint = false;
    SetUp.ProgressBox = false;
    
    variables = ["m","d","t"];
    syms(variables);

    v = d/t;
    f = 0.5.*m.*v^2;
    
    helpdlg(string(f))

    % This sets up the values we wish to input for m,d, and t respectively.
    values = [4*10^-3,10,80*10^-3;
              4.1*10^-3,10,79*10^-3;
              4.0*10^-3,10,82*10^-3;
              4.2*10^-3,10,30*10^-3;];

    % This sets up the errrors we wish to input for m,d, and t respectively.
    errors = [5*10^-6,1*10^-2,1*10^-3;
              5*10^-6,1*10^-2,1*10^-3;
              5*10^-6,1*10^-2,1*10^-3;
              5*10^-6,1*10^-2,10*10^-3;];
    
    helpdlg(sprintf('Needed number of variables = %d\nDetected number of variables = %d\nDetected number of entries = %d\n',length(variables),size(values,2),size(values,1)))
          
end

%% Debug Initialisation
fprintf('%s: Started for %s...\n', title,ID);

DebugON = SetUp.Debug;

NumberOfEntries = size(values,1);
NumberOfVariables = length(variables);

if size(values,2)~=NumberOfVariables || size(errors,2)~=NumberOfVariables
    disp('Input data does not match with number of variables')
end

if size(errors,1)~=NumberOfEntries
    disp('Input error data does not have the same number of entries as the values')
end

%subs(test_array, 2, a)

% The following paragraph converts the variables cell array into a symbolic
% variables, then makes their "err_" counterparts for the errors in them.
syms(variables);
err_cell_array = cell(1,length(variables));
for L=1:length(variables)
    currVar = char(variables(1,L));
    currErr = sprintf('err_%s',currVar);
    err_cell_array{1,L} = currErr;
end
syms(err_cell_array);

%% Main Chunk

ErrorOutputArray = zeros(NumberOfEntries,2);

% The below bit of code fills in the values stated above using the two
% structures of var and err for the value and error in the variables
% respectively.
for CurrentEntryNumber=1:NumberOfEntries
    if DebugON
        fprintf('%s: Current entry number is %.0d...\n', title,CurrentEntryNumber);
    end
    % Now the ErrorCalc code has everything it needs to run the error
    % calculation.
    [Error_OutPut,Error_InPut] = ErrorCalc(f,variables,values(CurrentEntryNumber,:),errors(CurrentEntryNumber,:),SetUp,sprintf('Entry %.0d',CurrentEntryNumber));
    FunctionValue = Error_OutPut.Values.f;
    FunctionError = Error_OutPut.Values.Err;
    % The value and error for that specific entry is stored in an array.
    ErrorOutputArray(CurrentEntryNumber,1) = FunctionValue;
    ErrorOutputArray(CurrentEntryNumber,2) = FunctionError;
    if DebugON
        fprintf('%s: For #%.0d: value=%g\terror=%g\n',title,CurrentEntryNumber,FunctionValue,FunctionError);
    end
end
%ErrorFuncEquation = latex(Error_OutPut)
%% Weighting Section & Final Bits

% This weights the above calculated data.
[WeightedStruct]=WeightedMeanCalc(ErrorOutputArray(:,1),ErrorOutputArray(:,2),ID);

VarTypes = {'double','double'};
VarNames = {'Value','Error'};
rowNames = zeros(NumberOfEntries,1);
rowNames = num2cell(rowNames);
for L=1:NumberOfEntries
    rowNames{L} = sprintf('Entry_%d',L);
end
ErrorCalcTable = table('Size',[NumberOfEntries,length(VarTypes)],'VariableTypes',VarTypes,'VariableNames',VarNames,'RowNames',rowNames);
ErrorCalcTable(:,1) = table(ErrorOutputArray(:,1));
ErrorCalcTable(:,2) = table(ErrorOutputArray(:,2));

OutputStructure.ID= ID;
OutputStructure.TableOfInputs = WeightedErrorTable(variables,values,errors,ErrorOutputArray(:,1),ErrorOutputArray(:,2),WeightedStruct.Mean,WeightedStruct.StandardError);
% OutputStructure.Inputs.Values = values;
% OutputStructure.Inputs.Errors = errors;
OutputStructure.ErrorCalcTable = ErrorCalcTable;

OutputStructure.WeightedMeanCalc = WeightedStruct;
OutputStructure.Mean = WeightedStruct.Mean;
OutputStructure.Error = WeightedStruct.Error;
OutputStructure.StandardError= WeightedStruct.StandardError;
OutputStructure.Z= WeightedStruct.Z;

fprintf('%s: Complete for %s!\n',title,ID);
end

%% In-built functions

function [Output]=WeightedMeanCalc(Y,err_Y,Description)

    Output.Description = Description;
    if length(Y)>1
        W = (err_Y).^-2; % Weight array
        W(isinf(W)|isnan(W)) = 0; % Replace NaNs and infinite values with zeros 
        WeightedMean_denom = sum(W);
        WeightedMean_numer = sum(W.*Y);
        WeightedMean = WeightedMean_numer/WeightedMean_denom;

        ExternalError = (sum(((Y-WeightedMean).^2).*W)/((length(Y)-1)*sum(W)))^0.5;
        InternalError = ( (sum(W))^-1 )^0.5;
        Z = ExternalError/InternalError;
        WeightedMeanError = (ExternalError^2 + InternalError^2)^0.5;
        Output.Mean = WeightedMean;
        Output.ExternalError = ExternalError;
        Output.InternalError = InternalError;
        Output.Z = Z;
        Output.Error = WeightedMeanError;
        Output.StandardError = WeightedMeanError/((length(Y))^0.5);
    else
        Output.Mean = Y;
        Output.ExternalError = nan;
        Output.InternalError = nan;
        Output.Z = nan;
        Output.Error = err_Y;
        Output.StandardError = err_Y/((length(Y))^0.5);
    end
    
end

function TableOfInputs = WeightedErrorTable(variables,values,errors,f_values,f_errors,mean,standardError)
    NumberOfEntries = size(values,1);
    NumOfVariables = length(variables);
    K = 2*(NumOfVariables+1);
    varNames = cell(1,K);
    varTypes = cell(1,K);
    rowNames = cell(NumberOfEntries+1,1);
    for n = 0:(NumOfVariables)
        currVarNum = n+1;
        place = (2*n)+1;
        varTypes{place} = 'double';
        varTypes{place+1} = 'double';
        if n == NumOfVariables
            varNames{end-1} = '"f value';
            varNames{end} = 'f std. error';
        else
            varNames{place} = char(sprintf("%s value",variables(currVarNum)));
            varNames{place+1} = char(sprintf("%s error",variables(currVarNum)));
        end
    end
%     varNames{place} = char(sprintf("%s value",variables(currVarNum)));
%     varNames{place+1} = char(sprintf("%s std. error",variables(currVarNum)));
%     
    TableOfInputs = table('Size',[NumberOfEntries+1 length(varNames)],'VariableTypes',varTypes,'VariableNames',varNames);
    clear varTypes varNames
    
    % The below is designed to be filled in with two nested for loops, the
    % first one for each entry (j), and the second for each variable (n).
    
    for j=1:NumberOfEntries
        for n = 0:(NumOfVariables)
            % This is the location in the relevant arrays to obtain for
            % the correct variable data.
            currVarNum = n+1;
            
            % This is the location in the column to place the variable data
            % in the table.
            place = (2*n)+1;
            
            % This if statement checks for if its the function output
            % section if not, fill it in with the raw input data.
            if n==NumOfVariables
                TableOfInputs(j,place) = table(f_values(j));
                TableOfInputs(j,place+1) = table(f_errors(j));
            else
                % This makes sure the row it is filling is no the last row,
                % if it is the last row it then fills that like normal but
                % changes the relevant parts as NaN
                if j~=NumberOfEntries
                    TableOfInputs(j,place) = table(values(j,currVarNum));
                    TableOfInputs(j,place+1) = table(errors(j,currVarNum));
                else
                    Num = NumberOfEntries;
                    TableOfInputs(Num,place) = table(values(j,currVarNum));
                    TableOfInputs(Num,place+1) = table(errors(j,currVarNum));
                    TableOfInputs(Num+1,place) = table(nan);
                    TableOfInputs(Num+1,place+1) = table(nan);
                end
            end
        end
        % This sets the row names for all of the entries
        rowNames{j} = char(sprintf('Entry %.0d', j));
    end
    % The two following lines put the output data as the final row in the
    % table.
    TableOfInputs(end,end-1) = table(mean);
    TableOfInputs(end,end) = table(standardError);
    rowNames{end} = 'Output';
    TableOfInputs.Properties.RowNames = rowNames; 
end