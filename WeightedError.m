%% WeightedError Adv.
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



