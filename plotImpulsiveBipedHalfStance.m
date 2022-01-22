function gaittype = plotImpulsiveBipedHalfStance(GPOPSoutput,N)
% plotImpulsiveBipedHalfStance plots GPOPS-II outputs from
% ImpulsiveBipedHalfStance in the sagittal (x,y) plane and returns the
% gaitType
%
% ----- Useage -----
% gaittype = plotImpulsiveBipedHalfStance(GPOPSoutput,N) plots the leg and
%   center of mass at N evenly spaced points in time (from start of stance
%   to end) over two steps.
%
% ----- Output -----
% gaittype can be 1, 2 or 3.
%   1 = Walk
%   3 = Run
%   2 = Other


o = GPOPSoutput;
aux = o.result.setup.auxdata;
D = aux.D;

t1 = o.result.interpsolution.phase.time;
t2 = t1(end)+abs(t1(end)-flipud(t1));
t = [t1;t2(2:end)];
X1 = o.result.interpsolution.phase.state;
X2 = flipud(X1);
X2(:,[1,4]) = -X2(:,[1,4]);
X = [X1;X2(2:end,:)];

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
    l0 = sqrt(x0^2 + y0^2);
    lf = sqrt(xf^2 + yf^2);
    v0 = X(1,4);
    [uf, vf] = deal(X(end,3),X(end,4));
    
    
    Pn = o.result.solution.parameter;
    Pp = Pn;
    
    
    T_fl = -(v0 - Pn*y0/l0) + (vf + Pp*yf/lf);
    t_fl = linspace(0,T_fl);
    x_fl = xf + (uf+Pp*xf/lf)*t_fl;
    y_fl = yf + (vf+Pp*yf/lf)*t_fl - 1/2*t_fl.^2;
    plot(x_fl,y_fl,'k--')
end

yl = ylim;

ylim([0 yl(2)])
axis equal
xlim([x0-D*1.1, x_fl(end)+D/10])

xlabel('Horizontal, Leg Lengths')
ylabel('Vertical, Leg Lengths')

text(0.9,0.20,['U = ',num2str(aux.U),', D = ',num2str(aux.D)],'units','normalized','horizontalalignment','right')
text(0.9,0.15,['Stance time ',num2str(aux.D/aux.U - T_fl)],'units','normalized','horizontalalignment','right')
text(0.9,0.10,['Flight time ',num2str(T_fl)],'units','normalized','horizontalalignment','right')
text(0.9,0.05,['Stance length ',num2str(xf-x0)],'units','normalized','horizontalalignment','right')

if T_fl*aux.U/aux.D < 0.01
    gaittype = 1;
elseif T_fl*aux.U/aux.D > 0.99
    gaittype = 3;
else
    gaittype = 2;
end

