function [outFinal,out2,out1] = ImpulsiveBipedHalfStanceIterate(U,D,guess,auxFinal)
% ImpulsiveBipedHalfStanceIterate calls ImpulsiveBipedHalfStance three
% times. The first two times, it uses rough solutions (one mesh
% iteration). These are downsampled and used
% as guesses for the next iteration. For the final iteration, the mesh
% iteration number is specified by auxFinal.meshiteration.
%
% --------------------------------------------------%
% Useage
% --------------------------------------------------%
% [outFinal,out2,out1] = ImpulsiveBipedHalfStanceIterate(U,D,guess,auxFinal) ...
%       Finds the optimal solution outFinal (and itermediate solutions out1
%       and out2) for given input speed (U) and step length (D) from a
%       specified initial guess with model and optimization parameters
%       specified in the struct auxFinal
% % [outFinal,out2,out1] = ImpulsiveBipedHalfStanceIterate(U,D,guess) ...
%       uses default values for auxFinal
% [outFinal,out2,out1] = ImpulsiveBipedHalfStanceIterate(U,D) ...
%       uses default values for auxFinal and a random guess
% 
%
% --------------------------------------------------%
% User inputs
% --------------------------------------------------%
%   auxFinal - a struct containing parameters for the model and optimization.
%         Parameters are given as fields, and are normalized to leg length,
%         gravitational acceleration and mass.
%       --Parameters--
%       D - (double) step length
%       U - (double) Average horizontal speed
%       Fmax - (double, default 10) Maximum leg-axial ground reaction force during 
%              stance 
%       Fdotmax - (double, default) Maximum rate of change of ground reaction force
%                 during stance
%       
%       maxiterations - (integer: default 10) maximum number of mesh 
%                       iterations
%       meshtol - (double: default 1e-7) mesh tolerance
%       snopttol - (double: default 1e-6) tolerance for SNOPT
%       s - (double) smoothing parameter for smoothed absolute value
%       function
%       Tmin - (double) minimum stance time
%   guess - | 'default' | a simple guess, moving at constant speed at leg
%           height and one body weight of ground reaction force
%           | 'rand' | guess pulls from random values within variable
%           bounds at 16 control points
%           | struct | a previous solution can be used as a guess. It will
%           be downsampled to 16 evenly spaced control points.


if nargin < 4 
    auxFinal = struct; % create blank struct
    if nargin < 3
        guess = 'rand';
    end
end
auxFinal.U = U;
auxFinal.D = D;
% set defaults for necessary fields, if not provided
auxFinal = addAuxDefaults(auxFinal);

%% Iteration 1
aux = auxFinal; % use most of the input values
aux.s = 0.1;
aux.maxiterations = 1;
out1 = ImpulsiveBipedHalfStance(aux,guess);

%% Iteration 2
% still uses one mesh iteration and low smoothing
out2 = ImpulsiveBipedHalfStance(aux,out1);

%% Iteration 3
aux.s = auxFinal.s;
aux.maxiterations = auxFinal.maxiterations;
outFinal = ImpulsiveBipedHalfStance(aux,out2);
end