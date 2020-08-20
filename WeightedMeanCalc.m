%% WeightedMeanCalc
% Made by Robert J Scales

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