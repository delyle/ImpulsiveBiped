function auxOut = addAuxDefaults(auxIn)
% This function takes an auxdata struct as input, checks for missing
% required fields, and adds in the default values.

auxOut = auxIn;

fieldNames = fields(auxIn)';
requiredFields = {'Fmax','Fdotmax','Tmin','s','maxiterations','meshtol','snopttol'};
missingFields = setdiff(requiredFields,fieldNames);


% set defaults
for i = 1:length(missingFields)
    currentField = missingFields{i};
    switch currentField
        case 'Fmax'
            auxOut.(currentField) = 10;
        case 'Tmin'
            auxOut.(currentField) = 0.01;
        case 'Fdotmax'
            auxOut.(currentField) = 100;
        case 's'
            auxOut.(currentField) = 0.001;
        case 'maxiterations'
            auxOut.(currentField) = 10;
        case 'meshtol'
            auxOut.(currentField) = 1e-7;
        case 'snopttol'
            auxOut.(currentField) = 1e-6;
    end
    fprintf('%s set to %g\n',currentField,auxOut.(currentField)) % print a message
end