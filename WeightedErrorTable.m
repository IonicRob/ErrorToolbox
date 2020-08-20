%% WeightedErrorTable
% Made by Robert J Scales

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