blankSlate
aux.D = 1.5;
aux.U = 0.5;
aux.s = 0.01;
aux.Fmax = 10;
aux.Tmin = 0.01;
aux.Fdotmax = 50;

aux.maxiterations = 1;
out1 = ImpulsiveBipedHalfStance(aux);
aux.maxiterations = 8;
aux.s = 0.01;
aux.Tmin = 0.01;
out2 = ImpulsiveBipedHalfStance(aux,out1);
aux.maxiterations = 10;
aux.s = 0.1;
aux.Fdotmax = 100;
aux.snopttol = 1e-8;
aux.meshtol = 1e-5;
aux.Tmin = 0.001;
out3 = ImpulsiveBipedHalfStance(aux,out2);
%%
close all;
t = out3.result.solution.phase.time;
X = out3.result.solution.phase.state;
U = out3.result.solution.phase.control;

plot(t,X(:,1))
plot(t,X(:,3:4))
figure;
plot(t,X(:,5))
hold on
plot(t,U(:,2:3));
plotImpulsiveBipedHalfStance(out3,11)


fprintf('Solution found with total work of %.4f\n',2*out3.result.objective)