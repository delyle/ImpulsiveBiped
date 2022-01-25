function gaittype = plotImpulsiveBipedHalfStance(GPOPSoutput,varargin)
% plotImpulsiveBipedHalfStance plots GPOPS-II outputs from
% ImpulsiveBipedHalfStance in the sagittal (x,y) plane and returns the
% gaitType
%
% ----- Useage -----
% gaittype = plotImpulsiveBipedHalfStance(GPOPSoutput,N) plots the leg and
%   center of mass at N evenly spaced points in time (from start of stance
%   to end) over two steps.
%
% gaittype = plotImpulsiveBipedHalfStance(GPOPSoutput), defaults to 11
%   evenly spaced points
%
% gaittype =
% plotImpulsiveBipedHalfStance(____,NAME,VALUE) specifies plotting properties using one or more of the name-value pairs 
%  
%
% -- Name Value Pairs --
% 'TextLocation' - where to place text
%   'outside' | 'inside'
%   Whether to place the text inside or outside the plotting area. In both
%   cases, text are aligned to the right vertical axis.
%
% 'ForceTolerance' - minimum force to plot legs
%   0.01 (default) | scalar double < 1
%   Minimum value, in body weights, for plotting the legs
% 
%
% ----- Output -----
% gaittype can be 1, 2 or 3.
%   1 = Walk
%   3 = Run
%   2 = Other

p = inputParser;
p.StructExpand = false; % accepts structure as argument
isNumScalar = @(x) isnumeric(x) && isscalar(x);
addRequired(p,'GPOPSoutput',@isstruct)
addOptional(p,'N',11,isNumScalar);
validStr = {'INSIDE','OUTSIDE'};
addParameter(p,'TextLocation','INSIDE',@(x) any(strcmpi(x,validStr)))
addParameter(p,'ForceTolerance',0.01,isNumScalar)
addParameter(p,'ImpulseTolerance',0.01,isNumScalar)

parse(p,GPOPSoutput,varargin{:})

TextLocation = upper(p.Results.TextLocation);
N = p.Results.N;

o = GPOPSoutput;
aux = o.result.setup.auxdata;
D = aux.D;

t1 = o.result.interpsolution.phase.time; % time for the first half of stance
t2 = t1(end)+abs(t1(end)-flipud(t1)); % time for the second half
t = [t1;t2(2:end)]; % combine time
X1 = o.result.interpsolution.phase.state; % Kinematics and Forces for the first half of stance
X2 = flipud(X1); % in the second half of stance, kinematics run in reverse...
X2(:,[1,4]) = -X2(:,[1,4]); % ... but the sign on x and v change!
X = [X1;X2(2:end,:)]; %  combine states

F = X(:,5);
figure('color','w')

tq = linspace(0,t(end),N);
I = find_closest(tq,t);
for ii = 0:1
    X(:,1) = X(:,1) + ii*D;
    for i = I
        plot(X(i,1),X(i,2),'ro','markersize',10)
        hold on
        if F(i) > 0.01
            plot([ii*D X(i,1)],[0 X(i,2)],'b-')
        end
    end
    x0 = X(1,1);
    y0 = X(1,2);
    xf = X(end,1);
    yf = X(end,2);
    l0 = sqrt((x0-ii*D)^2 + y0^2);
    lf = sqrt((xf-ii*D)^2 + yf^2);
    [uf, vf] = deal(X(end,3),X(end,4));
    
    
    Pn = o.result.solution.parameter;
    Pp = Pn;
    
    
    T_fl = (2*Pn)*y0/l0; % equivalent to -(v0 - Pn*y0/l0) + (vf + Pp*yf/lf);
    t_fl = linspace(0,T_fl);
    x_fl = xf + (uf+Pp*(xf-ii*D)/lf)*t_fl;
    y_fl = yf + (vf+Pp*yf/lf)*t_fl - 1/2*t_fl.^2;
    plot(x_fl,y_fl,'k--')
end

yl = ylim;

ylim([0 yl(2)])
axis equal
xlim([x0-D*1.1, x_fl(end)+D/10])

xlabel('Horizontal, Leg Lengths')
ylabel('Vertical, Leg Lengths')

switch TextLocation
    case 'INSIDE'
        TextX = 0.9;
        horAlignment = 'right';
    case 'OUTSIDE'
        TextX = 1.1;
        horAlignment = 'left';
end

textToDisplay = ['U = ',num2str(aux.U),', D = ',num2str(aux.D),newline,...
                 'Stance time ',num2str(aux.D/aux.U - T_fl),newline,...
                 'Flight time ',num2str(T_fl),newline,...
                 'Stance length ',num2str(xf-x0)];

text(TextX,0.05,textToDisplay,'units','normalized','horizontalalignment',horAlignment,'verticalalignment','bottom')

if T_fl*aux.U/aux.D < 0.01
    gaittype = 1;
elseif T_fl*aux.U/aux.D > 0.99
    gaittype = 3;
else
    gaittype = 2;
end

function Idx = find_closest(xq,x,max_indices)
% FIND_CLOSEST This function finds the index Idx of x such that x(Idx) is 
%              closest to xq.
%   xq = the value of interest.
%   x  = the array to search
%   max_indices = the maximum number of indices that the user wants, should
%                 there be multiple values of x that are equally close to
%                 n (default is to return all indices).

[~, Idx] = min(abs(x-xq));
if nargin < 3
   max_indices = length(Idx); 
elseif length(Idx) < max_indices
    max_indices = length(Idx);
end
Idx = Idx(1:max_indices);
end
