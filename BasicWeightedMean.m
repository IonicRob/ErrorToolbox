%% BasicWeightedMean

function OutputStructure = BasicWeightedMean(SetUp,values,errors,variables)
%%
    title = mfilename; % Names the title what the function is called.

    EXAMPLE_ON = true;

    if EXAMPLE_ON == true
        clearvars('-except','title','EXAMPLE_ON');
        clc
        DLG = warndlg(sprintf('%s Running in Example Mode!',title));
        waitfor(DLG);
        ID = "Weighted Data Example";

        SetUp.debugON = true;
        
        variables = ["m","d","t"];
        syms(variables);
%         v = d/t;
%         f = 0.5.*m.*v^2;
%         helpdlg(string(f))
        
        % This sets up the values we wish to input for m,d, and t respectively.
        values = [4*10^-3,10,80*10^-3;...
                  4.1*10^-3,10,79*10^-3;...
                  4.0*10^-3,10,82*10^-3;...
                  4.2*10^-3,10,30*10^-3;];

        % This sets up the errrors we wish to input for m,d, and t respectively.
        errors = [5*10^-6,1*10^-2,1*10^-3;...
                  5*10^-6,1*10^-2,1*10^-3;...
                  5*10^-6,1*10^-2,1*10^-3;...
                  5*10^-6,1*10^-2,10*10^-3;];
    end
%% Main Body
    fprintf('%s: Started for %s!\n',title,ID);
    
    ErrorOutputArray = ValuesErrorsCombine(values,errors); % Prepares an array.
    NumberOfEntries = size(ErrorOutputArray,1); % Number of entries
    NumberOfVars = size(ErrorOutputArray,2)/2; % Number of variables
    
    TableNumRows = NumberOfEntries + 1; % Number of rows expected for results table
    TableNumCols = NumberOfVars*2; % Number of columns expected for results table
    
    if SetUp.debugON == true
        DLG = helpdlg(sprintf('Needed number of variables = %d\nDetected number of variables = %d\nDetected number of entries = %d\n',length(variables),size(values,2),size(values,1)));
        waitfor(DLG);
        fprintf('NumberOfEntries = %d\nNumberOfVars = %d\n',NumberOfEntries,NumberOfVars);
        fprintf('TableNumRows = %d\nTableNumCols = %d\n',TableNumRows,TableNumCols);
    end
    
    VarTypes = cell(1,TableNumCols); % This and the line below creates a cell array defining that each column should be a dounle
    VarTypes(:) = {'double'};
    
    VarNames = cell(1,TableNumCols); % This and the columns below names each variable's value and error columns
    for j = 1:NumberOfVars
        [ValCol,ErrCol] = colNums(j);
        VarNames(ValCol) = {sprintf('%s_val',variables(j))};
        VarNames(ErrCol) = {sprintf('%s_err',variables(j))};
    end
    
    rowNames = zeros(TableNumRows,1); % This sets up the names of the rows.
    rowNames = num2cell(rowNames);
    for L=1:NumberOfEntries
        rowNames{L} = sprintf('Entry_%d',L);
    end
    rowNames{end} = 'WeightedMean';
    
    % Creates the main results table
    ErrorCalcTable = table('Size',[size(rowNames,1),size(VarNames,2)],'VariableTypes',VarTypes,'VariableNames',VarNames,'RowNames',rowNames);
    
    % Creates the extra info table
    clear rowNames varNames
    rowNames = {'Standard Deviation','Internal Error','External Error','Z','COV (%)'};
    VarNames = variables;
    VarTypes = cell(1,length(VarNames));
    VarTypes(:) = {'double'};
    ExtraInfoTable = table('Size',[length(rowNames),NumberOfVars],'VariableTypes',VarTypes,'VariableNames',VarNames,'RowNames',rowNames);
    
    % Cycles through each variable
    for i = 1:NumberOfVars
        [ValCol,ErrCol] = colNums(i); % Determines the variable column and the error column
        
        % This weights the above calculated data.
        [WS]=WeightedMeanCalc(ErrorOutputArray(:,ValCol),ErrorOutputArray(:,ErrCol),ID);

        ErrorCalcTable(1:end-1,ValCol) = table(ErrorOutputArray(:,ValCol));
        ErrorCalcTable(1:end-1,ErrCol) = table(ErrorOutputArray(:,ErrCol));
        ErrorCalcTable(end,ValCol) = table(WS.Mean);
        ErrorCalcTable(end,ErrCol) = table(WS.StandardError);
        
        ExtraInfoTable(1,i) = table(WS.Error);
        ExtraInfoTable(2,i) = table(WS.InternalError);
        ExtraInfoTable(3,i) = table(WS.ExternalError);
        ExtraInfoTable(4,i) = table(WS.Z);
        ExtraInfoTable(5,i) = table(WS.COV*100);
        
        if SetUp.debugON == true
            message = {sprintf('Current variable = %s\nWeighted mean = %.2e\nStandard Error = %.2e\nStandard Deviation = %.2e\n\nInt.Error = %.2e\nExt.Error = %.2e\nZ = %.3g\nCOV (%%) = %.3g',variables{i},WS.Mean,WS.StandardError,WS.Error,WS.InternalError,WS.ExternalError,WS.Z,WS.COV*100)};
            DLG = helpdlg(message);
            waitfor(DLG)
        end
    end
    
    % This is what is outputted by the function
    OutputStructure.ID= ID;
    OutputStructure.ErrorCalcTable = ErrorCalcTable;
    OutputStructure.ExtraInfoTable = ExtraInfoTable;

    fprintf('%s: Complete for %s!\n',title,ID);
end

%%
function ErrorOutputArray = ValuesErrorsCombine(ValuesCols,ErrorsCols)

    ValuesSize = size(ValuesCols);
    ErrorsSize = size(ErrorsCols);

    if isequal(ValuesSize,ErrorsSize)
        ErrorOutputArray = nan(ValuesSize(1),ValuesSize(2)*2);
        for i = 1:ValuesSize(2)
            [ValCol,ErrCol] = colNums(i);
            ErrorOutputArray(:,ValCol) = ValuesCols(:,i);
            ErrorOutputArray(:,ErrCol) = ErrorsCols(:,i);
        end
    else
        DLG = errordlg('The values and errors arrays are not the same size!');
        waitfor(DLG);
    end

end

function [ValCol,ErrCol] = colNums(i)
    ValCol = (2*(i-1))+1;
    ErrCol = ValCol+1;
end