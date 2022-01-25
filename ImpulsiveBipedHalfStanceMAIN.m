clear; close all;

D = 1.2;
U = 0.5;

% solve the problem
out = ImpulsiveBipedHalfStanceIterate(U,D,'rand');

%%
% plot the solution, and get the gait type
i = plotImpulsiveBipedHalfStance(out,'TextLocation','inside');


fprintf('Solution found with total work of %.4f\nGait type %i\n',2*out.result.objective,i)