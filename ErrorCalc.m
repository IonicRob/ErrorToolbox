%% ErrorCalc
% By Robert J Scales July 2020


function [OutPut,InPut] = ErrorCalc(f,variables,values,errors,SetUp,ID)
    %% Example Initialisation
    % This example is the firing bullet example formatted for this code. The
    % kinetic energy is E=m*v, where v=d/t.
    title = mfilename; % Names the title what the function is called.
    
    EXAMPLE_ON = false;

    if EXAMPLE_ON == true
        clearvars('-except','title','EXAMPLE_ON');
        DLG = warndlg(sprintf('%s Running in Example Mode!',title));
        waitfor(DLG);
        ID = "Example";
        SetUp.DisplayEquations = true;
        SetUp.LatexFormatEquations = false;
        SetUp.DisplayEndResult = true;
        SetUp.Debug = true;
        SetUp.FloatingPoint = false;
        SetUp.ProgressBox = true;


        % String array containing all of the variables needed in function f, which
        % when broken down to all of its inputs is mass, distance, and time.
        variables = ["m","d","t"];
        
        % This function generates from each element a symbolic class variable.
        syms(variables);

        %The following is for the initation of our function f.
        % We can make our function f look cleaner by grouping some of the terms
        % into terms into which they are used in e.g. here distance and time make
        % up velocity (v), which v is then automatically a symbolic class.
        v = d/t;
        
        % This is our final function f that we want to work with. We need to use
        % full-stops before each multiplication or division in order to make
        % Matlab happy.
        f = 0.5.*m.*v^2;
        
        % Note, as shown in the displayed result on the line below,
        % how Matlab automatically puts d and t into v when defining what f is.
        disp(f);

        % This sets up the values we wish to input for m,d, and t respectively.
        values = [4*10^-3,10,80*10^-3];

        % This sets up the errrors we wish to input for m,d, and t respectively.
        errors = [5*10^-6,1*10^-2,1*10^-3];
    end
    %% Main Body
    % This section is always applied when used as a function.
    
    DebugON = SetUp.Debug;
    
    if DebugON
        fprintf("%s: Working on '%s'... \n", title, ID);
    end

    % If sympref is set to true/false then output will be decimal/fractional.
    sympref('FloatingPointOutput',SetUp.FloatingPoint);


    NumOfVariables = length(variables);
    NumOfValues = length(values);
    NumOfErrors = length(errors);

    % This is the generation of the table from which it is easier to read the
    % variables, their values, and their errors, in order to double-check if
    % they are in the correct order.
    varTypes = {'string','double','double'};
    varNames = {'Variable','Value','Error'};
    TableOfInputs = table('Size',[NumOfVariables length(varTypes)],'VariableTypes',varTypes,'VariableNames',varNames);
    clear varTypes varNames
    TableOfInputs(:,1) = table(transpose(variables));

    if NumOfValues~=0
        TableOfInputs(:,2) = table(transpose(values));
    else
        TableOfInputs(:,2) = table(NaN(NumOfVariables,1));
        fprintf("%s: No values detected for '%s'! \n", title, ID);
    end
    if NumOfErrors~=0
        TableOfInputs(:,3) = table(transpose(errors));
    else
        TableOfInputs(:,3) = table(NaN(NumOfVariables,1));
        fprintf("%s: No values detected for '%s'! \n", title, ID);
    end

    % add_err is an in-built function that creates a cell array where the
    % variable names in variables have "err_" added before them, and then like
    % before they are converted into symbolics.
    err_cell_array = add_err(variables);
    syms(err_cell_array);

    % FractionErrorCalc is an in-built function that generates the fractional
    % error as a symbolic class variable.
    fraction_error = FractionErrorCalc(f,variables,err_cell_array);

    % These are used for the Latex equation outputs, where func is representing
    % function f.
    syms func err_func

    % This represents what Matlab interpretted of your input code.
    InputEqu = func == f;
    InPut.f = latex(InputEqu);
    InPut.Table = TableOfInputs;
    
    % This represents what Matlab interpretted as the error equation.
    OutputEqu = err_func/func == fraction_error;

    if SetUp.DisplayEquations
        fprintf("%s: Input equation was...\n\t%s \n", title, string(InputEqu));
        fprintf("%s: Error equation was...\n\t%s \n", title, string(OutputEqu));
    end

    if SetUp.LatexFormatEquations
        % This converts what Matlab interpretted as the input code into LaTex
        % format
        LatexInput = latex(InputEqu);
        % This converts what Matlab interpretted as the error equation
        % code into LaTex format.
        LatexOuput = latex(OutputEqu);
    end

    % Example Initiatialisation: Note how the displayed error equation matches
    % that which we calculated in "Data Analysis for New Scientists".


    %% Inputting Data Into Error Equation
    % This initial bit needs evaluation for depending on what the user inputs
    % and what they want to see.

    VariableArray1 = sym('A',[length(variables),1]);
    VariableArray1(:,1) = sym(variables);
    VariableArray2 = sym('B',[length(variables),1]);
    VariableArray2(:,1) = sym(err_cell_array);
    VariableArray = [VariableArray1;VariableArray2];


    % This substitutes the variable values into the error equation
    subbed_frac_error_values = subs(fraction_error,VariableArray1,transpose(values));
    
    % This substitutes the variable errors into the error equation
    subbed_frac_error_errors = subs(fraction_error,VariableArray2,transpose(errors));

    subbed_frac_error = subs(subbed_frac_error_values,VariableArray2,transpose(errors));

    if SetUp.DisplayEquations
        fprintf("%s: Subbed variables =...\n\t=%s \n", title, string(subbed_frac_error_values));
        fprintf("%s: Subbed errors =...\n\t=%s \n", title, string(subbed_frac_error_errors));
        fprintf("%s: Subbed equ. =...\n\t=%s \n", title, string(subbed_frac_error));
    end

    % This substitutes the values into the function equation.
    % N.B. If not all of the variables are inputted then the output won't be
    % able to be converted to a number by double().
    subbed_func_value = subs(f,VariableArray1,transpose(values));
    
    % This formats the end result of the substituted function no
    OutPut.LatexEquations.func_value = latex(subbed_func_value);
    
    
    
    % This checks to see if the substituted function gives a value that is a
    % constant, which happens if all variable inputs are given.
    if isSymType(subbed_func_value,'constant')==1
        % Gives the result of equation f with all of the substituted values
        func_value_success = true;
        func_value = double(subbed_func_value);
    else
        DebugPopUp('Could not produce value of function!',title,'error',SetUp.Debug);
        %DebugBox = errordlg('Could not produce value of function!',title);
        func_value_success = false;
        func_value = nan; % Makes it not-a-number (NaN)
    end

    % Same as above but with the fractional error equation.
    if isSymType(subbed_frac_error,'constant')==1
        FracErr_value_success = true;
        FracErr_value = double(subbed_frac_error); % Gives the fractional error value
    else
        DebugPopUp('Could not produce fractional error value!',title,'error',SetUp.Debug);
        %DebugBox = errordlg('Could not produce fractional error value!',title);
        FracErr_value_success = false;
        FracErr_value = nan;
    end



    % This only procedes if both the function and the fractional error equation
    % are both numbers i.e. both have all of the required input values.
    if func_value_success && FracErr_value_success
        ErrorValue = FracErr_value*func_value; % This is the value of the error!
    else
        DebugPopUp('Could not produce error value!',title,'error',SetUp.Debug);
        %DebugBox = errordlg('Could not produce error value!',title);
        ErrorValue = nan;
    end

    if SetUp.DisplayEndResult
        fprintf("%s: For '%s'\n\t%g+-%g \n", title, ID,func_value,ErrorValue)
    end


    OutPut.Values.f = func_value;
    OutPut.Values.fractErr = FracErr_value;
    OutPut.Values.Err = ErrorValue;


    if DebugON
        fprintf("%s: Completed '%s'!\n", title, ID);
    end
end
%% In-built Functions

function [err_cell_array] = add_err(variables)

    err_cell_array = cell(1,length(variables));
    for L=1:length(variables)
        currVar = char(variables(1,L));
        currErr = sprintf('err_%s',currVar);
        err_cell_array{1,L} = currErr;
    end
    %syms(err_cell_array);

end



% This generates the terms of the 
function fraction_error = FractionErrorCalc(f,variables,err_cell_array)
    % This intialises the terms symbolic array
    terms = sym(0);
    for i=1:length(variables)
        currVar = char(variables(1,i)); % Finds the variable in column "i"
        
        % Finds the error counterpart to the variable.
        currErr = err_cell_array{1,i};
        
        % Creates the term in the sqrt summation. Uses the inbuilt
        % function at the end of the code
        term = (PartialComp(f,currVar)*sym(currErr).^2);
        
        % Adds this calculated term into the summation
        terms = terms + term;
    end
    % This sqrts the above to give the final fractional error equation
    % with no values inputted
    fraction_error = (terms).^0.5;
end



% This function down below gives the first partial differentation, squares
% it, then divides by the square of the original equation.
function B = PartialComp(f,x)
    Diff = diff(f,x,1); %First differential of f wrt variable x
    B = Diff.^2; % Sqaure the above
    f2 = f.^2; %Square of the function f
    B = B./f2; % This divides by the square of the function, which is equal to dividing the terms all in the square root by the function, thus giving the fractional error.
end



function DebugPopUp(message,title,icon,OnOFF)
    if OnOFF==true
        msgbox(message,title,icon);
    end
end

% function ProgressBoxPopUp(x,ProgressBox,message,OnOFF)
%     if OnOFF
%         waitbar(x,ProgressBox,message);
%     end
% end