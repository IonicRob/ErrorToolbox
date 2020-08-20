%% BasicWeightedMean

function OutputStructure = BasicWeightedMean(values,errors,variables)
%%
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
%%
    fprintf('%s: Started for %s!\n',title,ID);
    ErrorOutputArray = ValuesErrorsCombine(values,errors);
    NumberOfEntries = size(ErrorOutputArray,1);
    NumberOfVars = size(ErrorOutputArray,2)/2;
    fprintf('NumberOfEntries = %d\nNumberOfVars = %d\n',NumberOfEntries,NumberOfVars);
    
    TableNumRows = NumberOfEntries + 1; 
    TableNumCols = NumberOfVars*2;
    fprintf('TableNumRows = %d\nTableNumCols = %d\n',TableNumRows,TableNumCols);
    clear VarTypes VarNames
    VarTypes = cell(1,TableNumCols);
    VarTypes(:) = {'double'};
    VarNames = cell(1,TableNumCols);
    
    for j = 1:NumberOfVars
%         disp(j);
        [ValCol,ErrCol] = colNums(j);
%         fprintf('ValCol = %d\nErrCol = %d\n',ValCol,ErrCol);
        VarNames(ValCol) = {sprintf('%s_val',variables(j))};
        VarNames(ErrCol) = {sprintf('%s_err',variables(j))};
    end
    disp('Done VarNames');
    
    rowNames = zeros(TableNumRows,1);
    rowNames = num2cell(rowNames);
    for L=1:NumberOfEntries
        rowNames{L} = sprintf('Entry_%d',L);
    end
    rowNames{end} = 'WeightedMean';
    disp(rowNames);
    disp(VarTypes);
    disp(VarNames);
    TableSize = [TableNumRows,TableNumCols];
    disp(TableSize);
    InputTableSize = [size(rowNames,1),size(VarNames,2)];
    disp(InputTableSize);
    ErrorCalcTable = table('Size',InputTableSize,'VariableTypes',VarTypes,'VariableNames',VarNames,'RowNames',rowNames);
    
    for i = 1:NumberOfVars
        [ValCol,ErrCol] = colNums(i);
        % This weights the above calculated data.
        [WeightedStruct]=WeightedMeanCalc(ErrorOutputArray(:,ValCol),ErrorOutputArray(:,ErrCol),ID);

        ErrorCalcTable(1:end-1,ValCol) = table(ErrorOutputArray(:,ValCol));
        ErrorCalcTable(1:end-1,ErrCol) = table(ErrorOutputArray(:,ErrCol));
        ErrorCalcTable(end,ValCol) = table(WeightedStruct.Mean);
        ErrorCalcTable(end,ErrCol) = table(WeightedStruct.StandardError);
    end
    
    OutputStructure.ID= ID;
    OutputStructure.ErrorCalcTable = ErrorCalcTable;

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