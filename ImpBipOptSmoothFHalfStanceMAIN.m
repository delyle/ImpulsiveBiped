blankSlate
aux.D = 1.5;
aux.U = 0.5;
aux.s = 0.01;
aux.Fmax = 10;
aux.Tmin = 0.01;
aux.Fdotmax = 50;

aux.maxiterations = 1;
out1 = ImpBipOptSmoothFHalfStance(aux,'rand');
aux.maxiterations = 8;
aux.s = 0.01;
aux.Tmin = 0.01;
out2 = ImpBipOptSmoothFHalfStance(aux,out1);
aux.maxiterations = 10;
aux.s = 0.1;
aux.Fdotmax = 100;
aux.snopttol = 1e-8;
aux.meshtol = 1e-5;
aux.Tmin = 0.001;
out3 = ImpBipOptSmoothFHalfStance(aux,out2);
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
plotImpBipHalfStance(out3,11)

%ImpBipOptVerify(out3)
out3.result.solution.phase.integral
out3.result.solution.parameter
out3.result.objective