clc;
x_bar = 0;
wb = waitbar(x_bar, "Seabed generation", "Name", "Progress");
%------variables
shape = evalin('base', 'shape');
%seabed's dimensions
if shape ~= "Mediterranean Sea"
    x = evalin('base','x'); %m
    y = evalin('base','y'); %m
    %seabed sampling step
    dx = 0.1; %m
    dy = 0.1; %m
    assignin('base','dx', dx);
    assignin('base','dy', dy);
    %starting depth
    z_base = evalin('base','z_base'); %m
end
%--echosounder
%source level
SL = evalin('base','SL'); %dB
%detection threshold
DT = evalin('base','DT'); %dB
%damping coefficient
alfa = evalin('base','alfa')/1000; %dB/m
%target strength
TS = evalin('base','seabedType'); %dB
%noise
N = evalin('base','N'); %dB
%signal frequency
f = evalin('base','f'); %Hz
%signal duration
Td = evalin('base','Td'); %sec
%sampling resolution
N_x = evalin('base','N_x');
N_y = evalin('base','N_y');
%auv mission depth
z_auv = evalin('base','z_auv'); %m
%sound speed
c = evalin('base', 'c');%m/s
%max ping rate
PRmax = evalin('base', 'PRmax');%Hz

%seabed dimension including padding
if shape ~= "Mediterranean Sea"
    x_ext = x + 20;
    y_ext = y + 20;
    assignin('base','x_ext', x_ext);
    assignin('base','y_ext', y_ext);
end
%control
noise_active = evalin('base', 'noise_active');
outliers_active = evalin('base', 'outliers_active');
interpolation = evalin('base', 'interpolation');
use_previous_data = evalin('base', 'use_previous_data');

addpath("./seabedFunctions");

if shape ~= "Mediterranean Sea"
    Dx_index = ceil(x / (N_x * dx));
    Dy_index = ceil(y / (N_y * dx));
    assignin('base','Dx_index', Dx_index);
    assignin('base','Dy_index', Dy_index);
    %increasing resolution
    N_x = N_x + 1;
    N_y = N_y + 1;

    %matrix dimensions
    res_x = x / dx;
    res_y = y / dx;
    assignin('base','res_x', res_x);
    assignin('base','res_y', res_y);
    res_x_ext = x_ext / dx;
    res_y_ext = y_ext / dx;
    assignin('base','res_x_ext', res_x_ext);
    assignin('base','res_y_ext', res_y_ext);
else
    MediterraneanSeabed
end

if use_previous_data == 0
    %creating matrix
    switch(shape)
        case "Plane"
            planeSeabed
            limits = [-303 -297]; %step, plane and sin
            label = "m";
        case "Step"
            stepSeabed
            limits = [-303 -297];
            label = "m";
        case "Sin product"
            sinProdSeabed
            limits = [-303 -297];
            label = "m";
        case "Gaussian"
            gaussianSeabed
            limits = [-315 -285]; %gaussian
            label = "m";
        case "Mediterranean Sea"
            limits = [-3010 -2700];
            label = "Km";
    end
    assignin('base','M_seabed', M_seabed);
    assignin('base','limits', limits);
    assignin('base','label', label);
    %mission simulation
    x_bar = .25;
    waitbar(x_bar, wb, "Mission simulation");
    echosounder
    assignin('base','M_eco_pow', M_eco_pow);
    %depths from signals
    x_bar = .5;
    waitbar(x_bar, wb, "Post-mission data elaboration");
    postMissionElaboration
    %M_dep_samples = arrayfun(@(x) eco2R(x, SL, 0, 0), M_eco_pow);
    %M_dep_samples = eval(M_dep_samples);
else
    M_seabed = evalin('base', 'M_seabed');
    M_dep_samples = evalin('base','M_dep_samples');
    limits = evalin('base','limits');
    label = evalin('base','label');
end
%data format for algoritm
[samples_XY, samples] = matrix2scatteredData(M_dep_samples, Dx_index, Dy_index);
[seabed_XY, seabed_values] = matrix2scatteredData(M_seabed(1:res_x, 1:res_y), 1, 1);
[samples_X, samples_Y] = ndgrid(1:Dx_index:(N_x*Dx_index), 1:Dy_index:(N_y*Dy_index));
[seabed_X, seabed_Y] = ndgrid(1:1:res_x, 1:1:res_y);

%drawing mission path
auvPath

plotSurface(-M_seabed(1:res_x, 1:res_y), "Seabed", limits, dx, dy, label);
x_bar = .75;
waitbar(x_bar, wb, "Interpolation");
switch(interpolation)
    case "Linear"
        linearInterpolation
        plotSurface(M_linear, 'Linear interpolation', limits, dx, dy, label);
    case "RBF"
        RBFInterpolation
        plotSurface(M_RBF_grnn, 'RBF interpolation - newgrnn', limits, dx, dy, label);
    case "Natural Neighbour"
        naturalNeighbourInterpolation
        plotSurface(M_natural, 'Natural neighbour interpolation', limits, dx, dy, label);
    case "Nearest Neighbour"
        nearestNeighbourInterpolation
        plotSurface(M_nearest, 'Nearest neighbour interpolation', limits, dx, dy, label);
    case "Kriging"
        krigingInterpolation
        plotSurface(M_kriging, "Kriging interpolation", limits, dx, dy, label);
    case "Shepard"
        shepardInterpolation
        plotSurface(M_shepard, 'Shepard interpolation', limits, dx, dy, label);
    case "Minimum Curvature"
        minimumCurvatureInterpolation
        plotSurface(M_mincurv,'Minimum curvature interpolation', limits, dx, dy, label);
    case "Biharmonic Spline"
        v4Interpolation
        plotSurface(M_v4, 'v4 interpolation', limits, dx, dy, label);
    case "Spline"
        splineInterpolation
        plotSurface(M_spline, 'Spline interpolation', limits, dx, dy, label);
end
close(wb)
clear wb x_bar

msgbox(sprintf("Execution time (s): %.3f \nMSE(m^2): %.1f", time, error), "result", "help");
fprintf("%.3f \n%.1\n", time, error);