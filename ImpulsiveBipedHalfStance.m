function out = ImpulsiveBipedHalfStance(aux,guess)
% Optimal bipedal locomotion with Symmetrical contacts, based on Srinivasan
% and Ruina 2006 (Nature), using GPOPS-II
%
% The optimal control problem is to determine the work-minimizing
% symmetrical bipedal gait for a given stride length (D) and average speed
% (U). All variables are normalized to leg length, body mass, and
% gravitational acceleration.
%
% The problem starts with contact after flight phase, with an impulsive
% contact. Stance is simulated until midstance, and the behaviour is
% reflected (in reverse) through the rest of stance and the next flight
% phase.
%
% The objective is regularized by penalizing rapid changes in force. The
% level of regularization can be adjusted with aux.FdotMax (see below)
% 
% --------------------------------------------------%
% Useage
% --------------------------------------------------%
%   out = ImpulsiveBipedHalfStance(aux) returns GPOPS output with a default
%   guess, given auxdata
%   
%   out = ImpulsiveBipedHalfStance(aux,guess) returns GPOPS output with
%   guess given by string input
%
% --------------------------------------------------%
% User inputs
% --------------------------------------------------%
%   aux - a struct containing parameters for the model and optimization.
%         Parameters are given as fields
%       --Parameters--
%       D - (double) stride length
%       U - (double) Average horizontal speed
%       Fmax - (double) Maximum leg-axial ground reaction force during 
%              stance 
%       Fdotmax - (double) Maximum rate of change of ground reaction force
%                 during stance
%       
%       maxiterations - (integer: default 10) maximum number of mesh 
%                       iterations
%       meshtol - (double) mesh tolerance
%       snopttol - (double) tolerance for SNOPT
%   guess - | 'default' | a simple guess, moving at constant speed at leg
%           height and one body weight of ground reaction force
%           | 'rand' | guess pulls from random values within variable
%           bounds at 16 control points
%           | struct | a previous solution can be used as a guess. It will
%           be downsampled to 16 evenly spaced control points.
%
%---------------------------------------------------%
% Symmetrical biped with impulsive contacts:        %
%---------------------------------------------------%
% The problem solved here is given as follows:      %
%   Minimize W = int_0^1 |F.V| dt + 0.5*(Pn)^2      %
% subject to the dynamic constraints                %
%    l = sqrt(x^2 + y^2)
%    dx/dt = u;                                     %
%    du/dt = F(t)*x/l;                              %
%    dy/dt = v;
%    dv/dt = F(t)*y/l - 1;
% through contacts where
%    uf + Pp*xf/l - u0 =  - Pn*x0/l;
%    (vf + Pp*yf/l) - t_fl = v0 - Pn*y0/l;
% where Pp is the positive impulse just before contact and Pn is the
% absolute (negative) impulse just after contact
% The problem is technically single phase, but an implicit flight phase is
% included.
% In stance phase, the x and y positions are bounded s.t.
%    l^2 = x^2 + y^2 <= 1
%    y > 0
% The control is bounded as
%    F > 0
% The endpoint conditions are                     %
%    t_fl = (vf - v0);
%    vf >= v0
%    xf - x0 + uf*t_fl = D
%    yf - y0 = (vf - v0)/2*t_fl
%    tf = D/U - t_fl
% The state bounds are
%    y > 0
% The control bounds are
%    F > 0
% The first part of the objective is
%     J1 = int F*|x*u + y*v|/l dt
% With the absolute value function partitioned with slack variables
% The second part is
%     J2 = |
% smoothed as
%  |z|^+ ~ ( z + 2/pi*arctan(z/s) )/2, where 0 < s << 1 is a smoothing parameter
%
%---------------------------------------------------%

if nargin < 2
    guess = 'default';
end

D = aux.D; 
U = aux.U;

%-------------------------------------------------------------------------%
%----------------------- Setup for Problem Bounds ------------------------%
%-------------------------------------------------------------------------%

% Bounds on time
t0 = 0; % time must start at 0
tfmin = aux.Tmin; tfmax = D/U/2; % stance time can last as long as half a stride time
bounds.phase.initialtime.lower = t0;
bounds.phase.initialtime.upper = t0; 
bounds.phase.finaltime.lower = tfmin;
bounds.phase.finaltime.upper = tfmax;

% Bounds on states. States are:
% [x, y, u, v, F]
% x, y - horizontal and vertical position of the center of mass
% u, v - horizontal and vertical velocity of the center of mass
% F - pushing force along leg

x0min = -1; % Can't start stance more than a leg length away
x0max = 0; % Can't start past midstance
xmin = -1; ymin = 0; 
umin = -Inf; vmin = -Inf;
xmax = 0; ymax = 1;
umax = Inf; vmax = Inf;
xfmin = 0; xfmax = 0;
Fmin = 0; Fmax = aux.Fmax; % Forces must be pushing (no suction)
bounds.phase.initialstate.lower = [x0min,ymin,umin,vmin,Fmin];
bounds.phase.initialstate.upper = [x0max,ymax,umax,vmax,Fmax];
bounds.phase.state.lower = [xmin,ymin,umin,vmin,Fmin];
bounds.phase.state.upper = [xmax,ymax,umax,vmax,Fmax];
bounds.phase.finalstate.lower = [xfmin,ymin,umin,0,Fmin];
bounds.phase.finalstate.upper = [xfmax,ymax,umax,0,Fmax];

% Bounds on controls. Controls are:
% [Fdot, p, q]
% Fdot - time derivative of force
% p, q - positive and negative parts of power (slack variables)

Fdotmin = -aux.Fdotmax; Fdotmax = aux.Fdotmax;
bounds.phase.control.lower = [Fdotmin,0,0];
bounds.phase.control.upper = [Fdotmax,Fmax*U,Fmax*U];
bounds.phase.integral.lower = [0 0];
bounds.phase.integral.upper = [Inf Inf];

% Bounds on parameters. Parameter is:
% Pn - negative impulse at touchdown
bounds.parameter.lower = 0;
bounds.parameter.upper = Inf;

% Bounds on path constraints. These are
% [leg length^2, Power - p + q]
bounds.phase.path.lower = [0,0]; 
bounds.phase.path.upper = [1,0];

% Bounds on endpoint events. These are
% [Time of flight, ...
%  simulated stride length - given stride length, ..
%  simulated stride time - given time
bounds.eventgroup.lower = zeros(1,3);
bounds.eventgroup.upper = [D/U, zeros(1,2)];

%-------------------------------------------------------------------------%
%---------------------- Provide Guess of Solution ------------------------%
%-------------------------------------------------------------------------%

if ischar(guess)
    s = lower(guess);
    guess = struct;
    switch s
        case 'default'    
            guess.phase.time    = [0;tfmin];
            guess.phase.state   = [[-D/2; 0],[1; 1],[U;U],[-1; 1],[1;1]];
            guess.phase.control = [0 0 0; 0 0 0];
            guess.phase.integral = [0 0];
            guess.parameter = 1;
        case 'rand'
            rng('shuffle')
            n = 16;
            guess.phase.time = linspace(0,rand*D/U,n)';
            guess.phase.state = [rand(n,2),4*U*(rand(n,2)-1/2),Fmax*rand(n,1)];
            guess.phase.control = [(2*rand(n,1)-1)*Fdotmax,rand(n,2)];
            guess.phase.integral = rand(1,2);
            guess.parameter = rand;
    end
elseif isstruct(guess)
    n = 16;
    guessIn = guess.result.interpsolution;
    guess = struct;
    t = guessIn.phase.time;
    tq = linspace(0,t(end),n)';
    guess.phase.time = tq;
    guess.phase.state = interp1(t,guessIn.phase.state,tq);
    guess.phase.control = interp1(t,guessIn.phase.control,tq);
    guess.phase.integral = guessIn.phase.integral;
    guess.parameter = guessIn.parameter;
end
%-------------------------------------------------------------------------%
%----------Provide Mesh Refinement Method and Initial Mesh ---------------%
%-------------------------------------------------------------------------%
mesh.method       = 'hp-PattersonRao';
mesh.tolerance    = 1e-7;
if ~isfield(aux,'maxiterations')
    aux.maxiterations = 10;
end
mesh.maxiterations = aux.maxiterations;
if isfield(aux,'meshtol')
    mesh.tolerance = aux.meshtol;
end
mesh.colpointsmin = 4;
mesh.colpointsmax = 10;

%-------------------------------------------------------------------------%
%------------- Assemble Information into Problem Structure ---------------%
%-------------------------------------------------------------------------%
setup.name                        = 'ImpBipOpt';
setup.functions.continuous        = @ImpBipContinuous;
setup.functions.endpoint          = @ImpBipEndpoint;
setup.auxdata                     = aux;
setup.bounds                      = bounds;
setup.guess                       = guess;
setup.mesh                        = mesh;
setup.nlp.solver                  = 'snopt';
setup.nlp.snoptoptions.maxiterations = 500;
if isfield(aux,'snopttol')    
    setup.nlp.snoptoptions.tolerance = aux.snopttol;
end
setup.derivatives.supplier        = 'sparseCD';
setup.derivatives.derivativelevel = 'first';
setup.method                      = 'RPM-Integration';

%-------------------------------------------------------------------------%
%------------------------- Solve Problem Using GPOP2 ---------------------%
%-------------------------------------------------------------------------%
out   = gpops2(setup);
end

function phaseout = ImpBipContinuous(input)
s                 = input.auxdata.s;
x                 = input.phase.state(:,1);
y                 = input.phase.state(:,2);
u                 = input.phase.state(:,3);
v                 = input.phase.state(:,4);
F                 = input.phase.state(:,5);
Fdot              = input.phase.control(:,1);
p                 = input.phase.control(:,2);
q                 = input.phase.control(:,3);
lsqr              = x.^2 + y.^2;
l                 = sqrt(lsqr);
xdot              = u;
ydot              = v;
udot              = F.*x./l;
vdot              = F.*y./l - 1;
z                 = (x.*u + y.*v );
Power             = F.*z./l;
phaseout.dynamics = [xdot, ydot, udot, vdot, Fdot];
phaseout.integrand = [p+q,s(1)*p.*q];
phaseout.path = [lsqr,Power - p + q];
end

function endout = ImpBipEndpoint(input)

%    u0 - uf = Pp*xf/lf - Pn*x0/l0;
%    v0 - vf = Pp*yf/lf - Pn*y0/l0;
% where Pp is the positive impulse just before contact and Pn is the
% absolute (negative) impulse just after contact
% The problem is technically single phase, but an implicit flight phase is
% included.
% The endpoint conditions are                     %
%    t_fl = (vf - v0);
%    vf >= v0
%    xf - x0 + uf*t_fl = D
%    y0 - yf = (vf + v0)/2*t_fl
%    tf = D/U - t_fl
tf = 2*input.phase.finaltime;
X0 = input.phase.initialstate;
%Xf = input.phase.finalstate;
Pn = input.parameter(1);
Pp = Pn; % reflect negative impulse
x0 = X0(1);
y0 = X0(2);
u0 = X0(3);
v0 = X0(4);
xf = -x0;
yf = y0;
uf = u0;
vf = -v0;

l0 = sqrt(x0^2 + y0^2);
lf = sqrt(xf^2 + yf^2);
% velocities after touchdown, due to negative impulse
UTD = u0-Pn*x0/l0; 
VTD = v0-Pn*y0/l0;
UTO = uf+Pp*xf/lf;
VTO = vf+Pp*yf/lf;

t_fl = VTO - VTD; % flight time. Note that g = 1

D = input.auxdata.D;
U = input.auxdata.U;

endout.eventgroup.event = t_fl;
endout.eventgroup.event(2) = xf - x0 + UTO*t_fl - D;
endout.eventgroup.event(3) = tf + t_fl - D/U;
En = UTD^2 + VTD^2;
E0 = u0^2 + v0^2;
s = input.auxdata.s;
endout.objective = sum(input.phase.integral) + 0.5*abs_smooth(En - E0,s);
end

function z = abs_smooth(x,s)
    z = sqrt(x.^2 + s);
end