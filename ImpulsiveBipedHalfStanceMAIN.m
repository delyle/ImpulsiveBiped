%% Solve the problem at a default guess
clear; close all;
D = 0.4;
U = 0.5;

% solve the problem using a default guess
[out3,~,out1] = ImpulsiveBipedHalfStanceIterate(U,D,'default');

% plot the solution, and get the gait type
i = plotImpulsiveBipedHalfStance(out3,'TextLocation','outside');

fprintf('Solution found with total work of %.4f\nGait type %i\n',2*out.result.objective,i)

%% Solve the problem at a random guess.
clear; close all; clc
D = 1.2; U = 0.6;

% use a random guess
out = ImpulsiveBipedHalfStanceIterate(U,D);

% plot the solution at 21 evenly spaced points in stance

plotImpulsiveBipedHalfStance(out,21);

%% Specify a larger minimum time in stance, and smaller maximum rate of change of force in stance

auxFinal.Fdotmax = 10;
auxFinal.Tmin = 0.1;
U = 2;
D = 2.5;

out = ImpulsiveBipedHalfStanceIterate(U,D,'default',auxFinal);
plotImpulsiveBipedHalfStance(out);

%% Call the main GPOPS-II wrapper function directly

aux.U = 1.5;
aux.D = 2;
guess = 'default';
out = ImpulsiveBipedHalfStance(aux,guess);
plotImpulsiveBipedHalfStance(out,5);