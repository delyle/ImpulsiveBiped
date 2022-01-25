clear; close all;

D = 0.4;
U = 0.5;

% solve the problem
out = ImpulsiveBipedHalfStanceIterate(U,D,'default');

%%
% plot the solution, and get the gait type
i = plotImpulsiveBipedHalfStance(out,'TextLocation','outside');


fprintf('Solution found with total work of %.4f\nGait type %i\n',2*out.result.objective,i)