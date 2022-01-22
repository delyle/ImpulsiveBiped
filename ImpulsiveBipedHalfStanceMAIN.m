clear; close all;

D = 1;
U = 1;

% solve the problem
out3 = ImpulsiveBipedHalfStanceIterate(U,D);


% plot the solution, and get the gait type
i = plotImpulsiveBipedHalfStance(out3,11);


fprintf('Solution found with total work of %.4f\nGait type %i\n',2*out3.result.objective,i)