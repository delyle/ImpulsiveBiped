blankSlate
d = 0.1:0.25:1.9;
u = 0.1:0.25:1.5;
[umat,dmat] = meshgrid(u,d);
[objgrid,gaitgrid] = deal(NaN(size(umat)));
for i = 1:length(umat(:))
    aux.D = dmat(i);
    aux.U = umat(i);
    aux.s = 0.01;
    aux.Fmax = 10;
    aux.Tmin = 0.01;
    aux.Fdotmax = 50;
    
    aux.maxiterations = 1;
    try
        out1 = ImpBipOptSmoothFHalfStance(aux,'rand');
    catch
        out1 = ImpBipOptSmoothFHalfStance(aux,'rand');
    end
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
    
    objgrid(i) = out3.result.objective;
    
    
    close all
    gaitgrid(i) = plotImpBipHalfStance(out3,11);
    cdir = strrep(['U',num2str(aux.U),'/D',num2str(aux.D)],'.','p');
    mkdir(cdir)
    savename = strrep([cdir,'/U',num2str(aux.U),'D',num2str(aux.D)],'.','p');
    export_fig([savename,'.pdf'])
    save(savename,'out*','aux')
end


%%
for i = 1:length(umat(:))
    aux.D = dmat(i);
    aux.U = umat(i);
    cdir = strrep(['U',num2str(aux.U),'/D',num2str(aux.D)],'.','p');
    savename = strrep([cdir,'/U',num2str(aux.U),'D',num2str(aux.D)],'.','p');
    A = load(savename);
    close all
    gaitgrid(i) = plotImpBipHalfStance(A.out3,11);
    disp(gaitgrid(i));
    
end

close all
surf(umat,dmat,gaitgrid)
xlabel('U')
ylabel('D')