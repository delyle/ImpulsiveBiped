blankSlate
D = 1.2;
U = 0.3;

out3 = ImpulsiveBipedHalfStanceIterate(U,D);


plotImpulsiveBipedHalfStance(out3,11);


fprintf('Solution found with total work of %.4f\n',2*out3.result.objective)