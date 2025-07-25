clear; clc; close all;

% Vehicle Parameters
m = 1400;
a = 1.14;
b = 1.33;
Cf = 25000;
Cr = 21000;
Iz = 2420;
u = 75 * 1000 / 3600; 
delta = 0.1;

%A and B matrices setup
A = [-(Cf + Cr)/(m*u), (-a*Cf + b*Cr)/(m*u) - u; -(a*Cf - b*Cr)/(Iz*u), -(a^2*Cf + b^2*Cr)/(Iz*u)];
B = [Cf/m; a*Cf/Iz];

% Time setup
% Define the time step and create a time vector from 0 to 5
h = 0.1; 
t = 0:h:5;
% Get the number of time points
N = length(t);

% Initialize vectors: [v_y; psi]
x_euler = zeros(2, N);
x_rk4   = zeros(2, N);

%Euler Method
for n = 1:N-1
    x_euler(:,n+1) = x_euler(:,n) + h * (A * x_euler(:,n) + B * delta);
end

%RK4 Method 
for n = 1:N-1
    k1 = A * x_rk4(:,n) + B * delta;
    k2 = A * (x_rk4(:,n) + 0.5*h*k1) + B * delta;
    k3 = A * (x_rk4(:,n) + 0.5*h*k2) + B * delta;
    k4 = A * (x_rk4(:,n) + h*k3) + B * delta;
    x_rk4(:,n+1) = x_rk4(:,n) + (h/6)*(k1 + 2*k2 + 2*k3 + k4);
end

%Plot Lateral Velocity
figure;
plot(t, x_euler(1,:), 'r', 'DisplayName', 'Euler lateral velocity'); %Euler Plot
hold on;
plot(t, x_rk4(1,:), 'b', 'DisplayName', 'RK4 lateral velocity'); %RK4 Plot
xlabel('Time (s)');
ylabel('Lateral Velocity (m/s)');
title('Lateral Velocity Response Euler vs RK4');
legend; 
grid on;

% Plot Yaw Rate
figure;
plot(t, x_euler(2,:), 'r', 'DisplayName', 'Euler yaw rate');
hold on;
plot(t, x_rk4(2,:), 'b','DisplayName', 'RK4 yaw rate');
xlabel('Time (s)');
ylabel('Yaw rate (rad/s)');
title('Yaw rate Response Euler vs RK4');
legend;
grid on;

%Grid Independence Check

% Time intervals reduced by half each time 
dt_vec = [0.1, 0.05, 0.025, 0.0125, 0.00625, 0.003125, 0.0015625, 0.00078125, 0.000390625];  

%Obtain RK4 for smallest dt
dt_ref = dt_vec(end);
t_ref = 0:dt_ref:5;
N_ref = length(t_ref);
x_ref = zeros(2, N_ref);
x_ref(:,1) = [0; 0];

%Reference RK4 solution at smallest time interal 
for n = 1:N_ref-1
    k1 = A * x_ref(:,n) + B * delta;
    k2 = A * (x_ref(:,n) + 0.5*dt_ref*k1) + B * delta;
    k3 = A * (x_ref(:,n) + 0.5*dt_ref*k2) + B * delta;
    k4 = A * (x_ref(:,n) + dt_ref*k3) + B * delta;
    x_ref(:,n+1) = x_ref(:,n) + (dt_ref/6)*(k1 + 2*k2 + 2*k3 + k4);
end

% Initialize vectors  
euler_final = zeros(size(dt_vec));
rk4_final   = zeros(size(dt_vec));

% Loop through each time step and compute.
for i = 1:length(dt_vec)    
    % Set time step
    h = dt_vec(i);
    t = 0:h:5;

    % Get the number of time points
    N = length(t);
    
    x_ref_interp = [interp1(t_ref, x_ref(1,:), t); 
                    interp1(t_ref, x_ref(2,:), t)];

    %Initial Conditions
    x0 = [0; 0]; 

    % 2xN matrix for Euler method results
    x_euler = zeros(2, N);

    % Initial condition
    x_euler(:,1) = x0;

    %Euler Method 
    for n = 1:N-1
        x_euler(:,n+1) = x_euler(:,n) + h * (A * x_euler(:,n) + B * delta);
    end

    % 2xN matrix to store results for the RK4 method
    x_rk4 = zeros(2, N);

    % Initial condition
    x_rk4(:,1) = x0;


    % RK4 method
    for n = 1:N-1 

        % Calculate the intermediate slopes
        k1 = A * x_rk4(:,n) + B * delta;
        k2 = A * (x_rk4(:,n) + 0.5*h*k1) + B * delta;
        k3 = A * (x_rk4(:,n) + 0.5*h*k2) + B * delta;
        k4 = A * (x_rk4(:,n) + h*k3) + B * delta;
        
        % Update the weighted average of the slopes
        x_rk4(:,n+1) = x_rk4(:,n) + (h/6)*(k1 + 2*k2 + 2*k3 + k4);
    end

    % L2 norm error across all time steps
    euler_err(i) = sqrt(sum(vecnorm(x_euler - x_ref_interp).^2) / N);
    rk4_err(i)   = sqrt(sum(vecnorm(x_rk4 - x_ref_interp).^2) / N);
end

% Grid Independence Log-log plot
figure;
loglog(dt_vec, euler_err, 'r', 'DisplayName', 'Euler Error');
hold on;
loglog(dt_vec, rk4_err, 'b', 'DisplayName', 'RK4 Error');
xlabel('Time (s)');
ylabel('Error');
title('Grid Independence Check of Euler and RK4');
legend;
grid on;