%% =========================================================
%  WIND_MODEL.M  —  Wind Turbine Power System Modelling
%  Betz theory | Power curve | Weibull distribution | AEP
%  Reference turbine: Vestas V90-2MW (scaled for demo)
%% =========================================================

%% ── Turbine Parameters ───────────────────────────────────
P_rated   = 2000;    % Rated power (W) — scaled to 2 kW for rooftop demo
R         = 1.5;     % Rotor radius (m)
v_cut_in  = 2.5;     % Cut-in wind speed (m/s)
v_rated   = 11.0;    % Rated wind speed (m/s)
v_cut_out = 25.0;    % Cut-out wind speed (m/s)
rho_air   = 1.225;   % Air density (kg/m³) at sea level, 15 °C
Cp_max    = 0.45;    % Max power coefficient (Betz limit = 0.593)
eta_gen   = 0.92;    % Generator + gearbox efficiency

A_rotor   = pi * R^2;   % Swept area (m²)

fprintf('  ── Wind Turbine Parameters ──\n');
fprintf('     Rated power  : %.1f kW\n', P_rated/1000);
fprintf('     Rotor radius : %.1f m  |  Swept area: %.3f m²\n', R, A_rotor);
fprintf('     Cut-in / Rated / Cut-out: %.1f / %.1f / %.1f m/s\n\n',...
        v_cut_in, v_rated, v_cut_out);

%% ── Helper: Power Curve ──────────────────────────────────
function P = turbine_power(v, v_ci, v_r, v_co, P_r, rho, A, Cp, eta)
    P = zeros(size(v));
    for i = 1:numel(v)
        vi = v(i);
        if vi < v_ci || vi > v_co
            P(i) = 0;
        elseif vi >= v_ci && vi < v_r
            % Cubic region
            P(i) = 0.5 * rho * A * Cp * eta * vi^3;
            P(i) = min(P(i), P_r);
        else
            P(i) = P_r;
        end
    end
end

%% ── Figure 4: Turbine Power Curve ────────────────────────
figure('Name','Wind Turbine — Power Curve','NumberTitle','off',...
       'Color','white','Position',[100 100 750 380]);

v_range = 0:0.1:30;
P_curve = turbine_power(v_range, v_cut_in, v_rated, v_cut_out,...
                        P_rated, rho_air, A_rotor, Cp_max, eta_gen);

% Ideal Betz power (Cp = 0.593)
P_betz  = min(0.5 * rho_air * A_rotor * 0.593 * v_range.^3, P_rated*1.5);

hold on; grid on;
fill([v_cut_in v_cut_in v_cut_out v_cut_out], [0 2200 2200 0],...
     [0.9 0.97 0.9], 'EdgeColor','none','FaceAlpha',0.3,...
     'DisplayName','Operating zone');
plot(v_range, P_betz/1000,  '--', 'Color',[0.6 0.6 0.6], 'LineWidth',1.3,...
     'DisplayName','Betz ideal (C_P=0.593)');
plot(v_range, P_curve/1000, 'b-', 'LineWidth', 2.5,...
     'DisplayName','Actual power curve');

xline(v_cut_in,  '-.r', 'LineWidth',1.2, 'DisplayName', ...
      sprintf('Cut-in: %.1f m/s', v_cut_in));
xline(v_rated,   '-.g', 'LineWidth',1.2, 'DisplayName', ...
      sprintf('Rated: %.1f m/s', v_rated));
xline(v_cut_out, '-.k', 'LineWidth',1.2, 'DisplayName', ...
      sprintf('Cut-out: %.1f m/s', v_cut_out));
yline(P_rated/1000, '--m', 'LineWidth',1.2,'DisplayName','Rated power');

xlabel('Wind Speed (m/s)','FontSize',11);
ylabel('Output Power (kW)','FontSize',11);
title('Wind Turbine Power Curve (C_P = 0.45, \eta = 0.92)',...
      'FontSize',12,'FontWeight','bold');
legend('Location','northwest','FontSize',8);
xlim([0 30]); ylim([0 2.5]);

%% ── Figure 5: Betz Efficiency & Cp vs TSR ────────────────
figure('Name','Wind — Cp vs Tip Speed Ratio','NumberTitle','off',...
       'Color','white','Position',[870 100 600 360]);

lambda = linspace(0, 14, 300);   % Tip speed ratio
% Empirical Cp-lambda-beta curve (beta=0 pitch)
Cp_lambda = 0.5176 * (116./( 1./(lambda+0.08) - 0.035) - 5) ...
            .* exp(-21./(1./(lambda+0.08) - 0.035)) + 0.0068*lambda;
Cp_lambda = max(Cp_lambda, 0);

[Cp_peak, idx_peak] = max(Cp_lambda);
lambda_opt = lambda(idx_peak);

hold on; grid on;
plot(lambda, Cp_lambda, 'b-','LineWidth',2.2,'DisplayName','C_P(λ)');
plot(lambda_opt, Cp_peak,'ro','MarkerSize',9,'MarkerFaceColor','r',...
     'DisplayName',sprintf('C_{P,max}=%.3f at λ=%.1f', Cp_peak, lambda_opt));
yline(0.593, '--k','LineWidth',1.3,'DisplayName','Betz limit (0.593)');
xlabel('Tip Speed Ratio λ = ωR/v','FontSize',11);
ylabel('Power Coefficient C_P','FontSize',11);
title('C_P–λ Characteristic (Pitch Angle β = 0°)',...
      'FontSize',12,'FontWeight','bold');
legend('Location','northeast','FontSize',9);
ylim([0 0.65]); xlim([0 14]);

%% ── Weibull Wind Speed Distribution ─────────────────────
% Site: Coastal Tamil Nadu (representative)
k_weib = 2.1;    % Shape parameter
c_weib = 7.5;    % Scale parameter (m/s)  → mean ~6.6 m/s

v_w   = 0:0.1:25;
pdf_w = (k_weib/c_weib) .* (v_w/c_weib).^(k_weib-1) ...
        .* exp(-(v_w/c_weib).^k_weib);
cdf_w = 1 - exp(-(v_w/c_weib).^k_weib);

% Mean and most-probable wind speed
v_mean = c_weib * gamma(1 + 1/k_weib);
v_mode = c_weib * ((k_weib-1)/k_weib)^(1/k_weib);

%% ── Figure 6: Weibull Distribution + Power Curve ─────────
figure('Name','Wind — Weibull Distribution','NumberTitle','off',...
       'Color','white','Position',[100 530 900 400]);

subplot(1,2,1); hold on; grid on;
area(v_w, pdf_w,'FaceColor',[0.4 0.7 1],'FaceAlpha',0.5,...
     'EdgeColor',[0.1 0.4 0.8],'LineWidth',1.5,'DisplayName','PDF');
xline(v_mean,'--r','LineWidth',1.5,'DisplayName',sprintf('Mean=%.1f m/s',v_mean));
xline(v_mode,'--g','LineWidth',1.5,'DisplayName',sprintf('Mode=%.1f m/s',v_mode));
xline(v_cut_in,'-.k','LineWidth',1.2);
xline(v_rated,'-.k','LineWidth',1.2);
xlabel('Wind Speed (m/s)','FontSize',11);
ylabel('Probability Density','FontSize',11);
title(sprintf('Weibull PDF  (k=%.1f, c=%.1f m/s)', k_weib, c_weib),...
      'FontSize',12,'FontWeight','bold');
legend('FontSize',8,'Location','northeast');

subplot(1,2,2); hold on; grid on;
P_weib = turbine_power(v_w, v_cut_in, v_rated, v_cut_out,...
                       P_rated, rho_air, A_rotor, Cp_max, eta_gen);
% Weighted power generation
P_weighted = P_weib .* pdf_w * 0.1;  % per 0.1 m/s bin

yyaxis left
bar(v_w, pdf_w*0.1,'FaceColor',[0.7 0.85 1],'EdgeColor','none',...
    'DisplayName','Wind freq.');
ylabel('Probability per Bin','FontSize',10);

yyaxis right
plot(v_w, P_weib/1000,'b-','LineWidth',2,'DisplayName','Power curve');
fill([v_w, fliplr(v_w)], [P_weighted/1000*10, zeros(size(v_w))],...
     [0.1 0.4 0.9],'FaceAlpha',0.25,'EdgeColor','none',...
     'DisplayName','Energy contribution');
ylabel('Power (kW)','FontSize',10);
xlabel('Wind Speed (m/s)','FontSize',11);
title('Wind Speed × Power Curve','FontSize',12,'FontWeight','bold');
legend('FontSize',8,'Location','northeast');
sgtitle('Wind Resource & Turbine Performance — Coastal Tamil Nadu Site',...
        'FontSize',13,'FontWeight','bold');

%% ── Annual Energy Production (AEP) ──────────────────────
% AEP = integral of P(v) * f(v) dv  × 8760 h/yr
dv       = 0.01;
v_aep    = 0:dv:30;
pdf_aep  = (k_weib/c_weib).*(v_aep/c_weib).^(k_weib-1)...
            .*exp(-(v_aep/c_weib).^k_weib);
P_aep    = turbine_power(v_aep, v_cut_in, v_rated, v_cut_out,...
                         P_rated, rho_air, A_rotor, Cp_max, eta_gen);

AEP_Wh   = trapz(v_aep, P_aep .* pdf_aep) * 8760;    % Wh/yr
AEP_kWh  = AEP_Wh / 1000;
CF        = AEP_kWh / (P_rated/1000 * 8760) * 100;   % Capacity factor %

% Capacity factor check (30–45% is typical for coastal sites)
fprintf('  ── Wind Turbine Annual Results ──\n');
fprintf('     Mean wind speed  : %.2f m/s\n', v_mean);
fprintf('     AEP              : %.1f kWh/yr\n', AEP_kWh);
fprintf('     Capacity factor  : %.1f %%\n\n', CF);

%% ── Daily Wind Power Profile ─────────────────────────────
% Synthetic 24-h wind speed profile (diurnal pattern, coastal)
rng(7);
hours  = 0:0.5:23.5;
v_base = v_mean + 2.5*sin(2*pi*(hours-14)/24);  % diurnal: peak afternoon
v_turb = 0.8 * randn(size(hours));               % turbulence
v_day  = max(0, v_base + v_turb);

P_wind_day = turbine_power(v_day, v_cut_in, v_rated, v_cut_out,...
                            P_rated, rho_air, A_rotor, Cp_max, eta_gen)/1000;

E_daily_wind = trapz(hours, P_wind_day);   % kWh

figure('Name','Wind — Daily Power Profile','NumberTitle','off',...
       'Color','white','Position',[1020 100 620 420]);

yyaxis left
bar(hours, v_day, 0.6,'FaceColor',[0.7 0.85 1],'EdgeColor','none');
ylabel('Wind Speed (m/s)','FontSize',11);
ylim([0 20]);

yyaxis right
plot(hours, P_wind_day,'b-','LineWidth',2.2);
fill([hours, fliplr(hours)],[P_wind_day, zeros(size(hours))],[0.1 0.3 0.8],...
     'FaceAlpha',0.3,'EdgeColor','none');
ylabel('Power Output (kW)','FontSize',11);
ylim([0 2.8]);

xlabel('Time of Day (h)','FontSize',11);
title(sprintf('Daily Wind Turbine Power Profile\n(E_{daily} = %.2f kWh/day)', E_daily_wind),...
      'FontSize',12,'FontWeight','bold');
grid on; xlim([0 24]); xticks(0:2:24);
legend({'Wind speed','Wind power'},'Location','northwest','FontSize',9);

fprintf('  ── Daily Wind Profile ──\n');
fprintf('     Daily wind energy : %.2f kWh\n\n', E_daily_wind);

save('wind_results.mat','P_wind_day','E_daily_wind','v_day','AEP_kWh','CF','hours');
