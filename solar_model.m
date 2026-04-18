%% =========================================================
%  SOLAR_MODEL.M  —  Photovoltaic (PV) System Modelling
%  Single-diode model | I-V & P-V curves | Real parameters
%% =========================================================
%
%  Physical model used:
%      I = Iph - I0 * (exp((V + I*Rs)/(n*Vt)) - 1) - (V + I*Rs)/Rsh
%
%  Reference module: Trina Solar TSM-400 (400 W, 72-cell)
%
%% =========================================================

%% ── Module Parameters (Standard Test Conditions, STC) ───
% STC: G = 1000 W/m², Tc = 25 °C, AM 1.5

Isc_ref   = 9.93;        % Short-circuit current (A)
Voc_ref   = 49.5;        % Open-circuit voltage (V)
Impp_ref  = 9.38;        % MPP current (A)
Vmpp_ref  = 42.6;        % MPP voltage (V)
Pmpp_ref  = 400;         % Rated power (W)
Ns        = 72;          % Cells in series
n_ideal   = 1.3;         % Ideality factor
T_ref     = 25 + 273.15; % Reference temp (K)
G_ref     = 1000;        % Reference irradiance (W/m²)

% Temperature coefficients
alpha_Isc =  0.05e-2;    % /°C  (fraction)
beta_Voc  = -0.30e-2;    % /°C

% Derived physical constants
q  = 1.602e-19;          % Electron charge (C)
k  = 1.381e-23;          % Boltzmann constant (J/K)

%% ── Helper: Compute I-V curve via Newton-Raphson ─────────
function [V_vec, I_vec, P_vec] = iv_curve(Iph, I0, Rs, Rsh, n, Vt, Voc)
    V_vec = linspace(0, Voc*1.01, 500);
    I_vec = zeros(size(V_vec));
    I_est = Iph;                        % initial guess
    for j = 1:length(V_vec)
        V = V_vec(j);
        for iter = 1:50                 % Newton-Raphson
            F  = I_est - Iph + I0*(exp((V + I_est*Rs)/(n*Vt)) - 1) ...
                       + (V + I_est*Rs)/Rsh;
            dF = 1 + I0*Rs/(n*Vt)*exp((V + I_est*Rs)/(n*Vt)) + Rs/Rsh;
            I_new = I_est - F/dF;
            if abs(I_new - I_est) < 1e-9, break; end
            I_est = I_new;
        end
        I_vec(j) = max(I_est, 0);
    end
    P_vec = V_vec .* I_vec;
end

%% ── Baseline STC Parameters ──────────────────────────────
Tc   = T_ref;
G    = G_ref;
Vt   = n_ideal * k * Tc / q;

% Photocurrent
Iph  = (G/G_ref) * (Isc_ref + alpha_Isc*(Tc - T_ref));

% Saturation current (from Voc)
% Approximate Rs and Rsh from datasheet slopes
Rs   = 0.35;    % Ω  (series resistance)
Rsh  = 300;     % Ω  (shunt resistance)

% I0 from open-circuit: 0 = Iph - I0*(exp(Voc/(n*Vt))-1) - Voc/Rsh
I0   = (Iph - Voc_ref/Rsh) / (exp(Voc_ref/(n_ideal*Vt)) - 1);

fprintf('  ── Solar Module Parameters (STC) ──\n');
fprintf('     Iph  = %.4f A\n', Iph);
fprintf('     I0   = %.3e A\n', I0);
fprintf('     Rs   = %.2f Ω,  Rsh = %.0f Ω\n', Rs, Rsh);
fprintf('     Vt   = %.4f V\n\n', Vt);

%% ── Figure 1: I-V & P-V at Different Irradiances ─────────
figure('Name','Solar PV — Irradiance Effect','NumberTitle','off',...
       'Color','white','Position',[100 100 900 420]);

irradiances = [200, 400, 600, 800, 1000];   % W/m²
colors = [0.1 0.4 0.8; 0.2 0.6 0.3; 0.9 0.6 0.1; ...
          0.8 0.2 0.2; 0.4 0.1 0.6];

subplot(1,2,1); hold on; grid on;
subplot(1,2,2); hold on; grid on;

mpp_G = zeros(length(irradiances), 3);   % store [V_mpp, I_mpp, P_mpp]
for i = 1:length(irradiances)
    G_i   = irradiances(i);
    Iph_i = (G_i/G_ref) * Isc_ref;
    [V_i, I_i, P_i] = iv_curve(Iph_i, I0, Rs, Rsh, n_ideal, Vt, Voc_ref);

    [Pmpp_i, idx] = max(P_i);
    mpp_G(i,:) = [V_i(idx), I_i(idx), Pmpp_i];

    subplot(1,2,1);
    plot(V_i, I_i, 'Color', colors(i,:), 'LineWidth', 1.8);
    plot(V_i(idx), I_i(idx), 'o', 'Color', colors(i,:), ...
         'MarkerFaceColor', colors(i,:), 'MarkerSize', 7);

    subplot(1,2,2);
    plot(V_i, P_i, 'Color', colors(i,:), 'LineWidth', 1.8,...
         'DisplayName', sprintf('G = %d W/m²', G_i));
    plot(V_i(idx), Pmpp_i, 'o', 'Color', colors(i,:), ...
         'MarkerFaceColor', colors(i,:), 'MarkerSize', 7);
end

subplot(1,2,1);
xlabel('Voltage (V)', 'FontSize', 11);
ylabel('Current (A)', 'FontSize', 11);
title('I–V Characteristics', 'FontSize', 12, 'FontWeight', 'bold');
xlim([0 55]); ylim([0 12]);
legend(arrayfun(@(g) sprintf('G=%d W/m²',g), irradiances, 'UniformOutput',false),...
       'Location','southwest','FontSize',8);

subplot(1,2,2);
xlabel('Voltage (V)', 'FontSize', 11);
ylabel('Power (W)', 'FontSize', 11);
title('P–V Characteristics (MPP marked)', 'FontSize', 12, 'FontWeight', 'bold');
xlim([0 55]); ylim([0 500]);
legend('Location','northwest','FontSize',8);
sgtitle('Solar PV Module — Effect of Irradiance (T = 25 °C)',...
        'FontSize', 13, 'FontWeight', 'bold');

%% ── Figure 2: Effect of Temperature ─────────────────────
figure('Name','Solar PV — Temperature Effect','NumberTitle','off',...
       'Color','white','Position',[100 560 900 420]);

temps_C = [0, 15, 25, 45, 65];   % °C
colors2 = [0.0 0.5 0.9; 0.3 0.7 0.3; 0.1 0.1 0.1; ...
           0.9 0.4 0.0; 0.8 0.1 0.1];

subplot(1,2,1); hold on; grid on;
subplot(1,2,2); hold on; grid on;

mpp_T = zeros(length(temps_C), 3);
for i = 1:length(temps_C)
    Tc_i  = temps_C(i) + 273.15;
    Vt_i  = n_ideal * k * Tc_i / q;
    dT    = Tc_i - T_ref;
    Iph_i = Isc_ref * (1 + alpha_Isc * dT);
    Voc_i = Voc_ref  * (1 + beta_Voc  * dT);
    I0_i  = (Iph_i - Voc_i/Rsh) / (exp(Voc_i/(n_ideal*Vt_i)) - 1);

    [V_i, I_i, P_i] = iv_curve(Iph_i, I0_i, Rs, Rsh, n_ideal, Vt_i, Voc_i);
    [Pmpp_i, idx] = max(P_i);
    mpp_T(i,:) = [V_i(idx), I_i(idx), Pmpp_i];

    subplot(1,2,1);
    plot(V_i, I_i, 'Color', colors2(i,:), 'LineWidth', 1.8);
    plot(V_i(idx), I_i(idx), 'o', 'Color', colors2(i,:),...
         'MarkerFaceColor', colors2(i,:), 'MarkerSize', 7);

    subplot(1,2,2);
    plot(V_i, P_i, 'Color', colors2(i,:), 'LineWidth', 1.8,...
         'DisplayName', sprintf('T = %d °C', temps_C(i)));
    plot(V_i(idx), Pmpp_i, 'o', 'Color', colors2(i,:),...
         'MarkerFaceColor', colors2(i,:), 'MarkerSize', 7);
end

subplot(1,2,1);
xlabel('Voltage (V)','FontSize',11); ylabel('Current (A)','FontSize',11);
title('I–V Characteristics','FontSize',12,'FontWeight','bold');
xlim([0 58]); ylim([0 12]);
legend(arrayfun(@(t) sprintf('T=%d °C',t), temps_C,'UniformOutput',false),...
       'Location','southwest','FontSize',8);

subplot(1,2,2);
xlabel('Voltage (V)','FontSize',11); ylabel('Power (W)','FontSize',11);
title('P–V Characteristics (MPP marked)','FontSize',12,'FontWeight','bold');
xlim([0 58]); ylim([0 500]);
legend('Location','northwest','FontSize',8);
sgtitle('Solar PV Module — Effect of Cell Temperature (G = 1000 W/m²)',...
        'FontSize',13,'FontWeight','bold');

%% ── Figure 3: Daily Solar Generation Profile ─────────────
figure('Name','Solar — Daily Energy Profile','NumberTitle','off',...
       'Color','white','Position',[1020 100 620 420]);

hours = 0:0.5:23.5;
% Typical irradiance profile (clear day, south-facing panel, Chennai)
G_day = max(0, 950 * sin(pi*(hours - 5.5)/13).^1.3 .* (hours>=5.5 & hours<=18.5));
% Random cloud variation
rng(42);
cloud = 1 - 0.15*rand(size(G_day));
G_day = G_day .* cloud;

% Cell temperature follows ambient + NOCT correction
T_amb  = 28 + 8*sin(pi*(hours-6)/12);   % °C
NOCT   = 45;
Tc_day = T_amb + (NOCT - 20)/800 .* G_day;

% Power output per module
P_day = zeros(size(hours));
for i = 1:length(hours)
    if G_day(i) < 10, continue; end
    Tc_i  = Tc_day(i) + 273.15;
    Vt_i  = n_ideal * k * Tc_i / q;
    dT    = Tc_i - T_ref;
    Iph_i = (G_day(i)/G_ref) * (Isc_ref + alpha_Isc*dT);
    Voc_i = Voc_ref * (1 + beta_Voc*dT);
    I0_i  = max(1e-15,(Iph_i - Voc_i/Rsh)/(exp(Voc_i/(n_ideal*Vt_i))-1));
    [~, ~, P_i] = iv_curve(Iph_i, I0_i, Rs, Rsh, n_ideal, Vt_i, Voc_i);
    P_day(i) = max(P_i);
end

% Scale to 10-module array (4 kW system)
N_modules  = 10;
eta_inv    = 0.97;
P_array    = P_day * N_modules * eta_inv / 1000;   % kW

% Energy (kWh) — trapezoidal integration
E_daily_solar = trapz(hours, P_array);

yyaxis left
area(hours, G_day, 'FaceColor',[1 0.85 0.3],'EdgeColor',[0.9 0.7 0],...
     'FaceAlpha',0.6,'DisplayName','Irradiance (W/m²)');
ylabel('Solar Irradiance (W/m²)','FontSize',11);
ylim([0 1300]);

yyaxis right
plot(hours, P_array, 'b-','LineWidth',2,'DisplayName','PV Output (kW)');
ylabel('Array Power Output (kW)','FontSize',11);
ylim([0 5.5]);

xlabel('Time of Day (h)','FontSize',11);
title(sprintf('Daily Solar PV Generation Profile\n(10 × 400 W modules, E_{daily} = %.2f kWh)',...
      E_daily_solar),'FontSize',12,'FontWeight','bold');
legend('Location','north','FontSize',9);
grid on; xlim([0 24]);
xticks(0:2:24);

fprintf('  ── Solar Array Results ──\n');
fprintf('     Array size      : %d modules × %d W = %.1f kW\n',...
        N_modules, Pmpp_ref, N_modules*Pmpp_ref/1000);
fprintf('     Daily energy     : %.2f kWh\n', E_daily_solar);
fprintf('     Peak irradiance  : %.0f W/m²\n\n', max(G_day));

% Export variables for hybrid analysis
save('solar_results.mat','P_array','E_daily_solar','G_day','Tc_day','hours');
