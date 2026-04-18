%% =========================================================
%  HYBRID_ANALYSIS.M  —  Wind + Solar Hybrid Energy System
%  Energy balance | Battery storage | Load matching
%  System: 4 kWp PV + 2 kW Wind + 10 kWh Battery Bank
%% =========================================================

load('solar_results.mat');   % P_array (kW), E_daily_solar
load('wind_results.mat');    % P_wind_day (kW), E_daily_wind

%% ── Load Profile ─────────────────────────────────────────
% Typical residential + small office load (Tamil Nadu)
% Peaks: 7–9 AM (morning), 6–9 PM (evening)
load_base  = 1.2;   % kW baseline
load_day   = load_base + ...
    1.5 * exp(-0.5*((hours - 8 ).^2/1.5^2)) + ...  % morning peak
    2.0 * exp(-0.5*((hours - 19).^2/1.5^2)) + ...  % evening peak
    0.5 * (hours >= 12 & hours <= 14);              % noon AC load
load_day   = load_day + 0.1*randn(size(hours));
load_day   = max(load_day, 0.4);
E_daily_load = trapz(hours, load_day);

%% ── Hybrid Supply ────────────────────────────────────────
P_hybrid   = P_array + P_wind_day;   % Total generation (kW)
P_surplus  = P_hybrid - load_day;    % + surplus, – deficit

%% ── Battery Simulation ───────────────────────────────────
E_batt_cap = 10.0;   % kWh — battery bank capacity
SOC_min    = 0.15;   % 15% minimum SOC
SOC_max    = 1.00;   % 100% max
eta_ch     = 0.95;   % Charging efficiency
eta_dis    = 0.95;   % Discharging efficiency

SOC        = 0.5 * ones(length(hours), 1);  % Initial SOC = 50%
P_batt     = zeros(length(hours), 1);       % Battery flow (+charge/-discharge)
P_curt     = zeros(length(hours), 1);       % Curtailed power
P_unmet    = zeros(length(hours), 1);       % Unmet demand
dt         = 0.5;   % time step (hours)

for i = 2:length(hours)
    surplus_i = P_surplus(i);
    soc_i     = SOC(i-1);

    if surplus_i > 0
        % Charge battery
        E_in       = surplus_i * eta_ch * dt;
        soc_new    = soc_i + E_in / E_batt_cap;
        if soc_new > SOC_max
            P_batt(i)  = (SOC_max - soc_i) * E_batt_cap / (eta_ch * dt);
            P_curt(i)  = surplus_i - P_batt(i);
            SOC(i)     = SOC_max;
        else
            P_batt(i)  = surplus_i;
            SOC(i)     = soc_new;
        end
    else
        % Discharge battery
        E_out      = abs(surplus_i) * dt / eta_dis;
        soc_new    = soc_i - E_out / E_batt_cap;
        if soc_new < SOC_min
            avail      = (soc_i - SOC_min) * E_batt_cap * eta_dis / dt;
            P_batt(i)  = -avail;
            P_unmet(i) = abs(surplus_i) - avail;
            SOC(i)     = SOC_min;
        else
            P_batt(i)  = surplus_i;
            SOC(i)     = soc_new;
        end
    end
end

%% ── Energy Summary ───────────────────────────────────────
E_solar_gen  = trapz(hours, P_array);
E_wind_gen   = trapz(hours, P_wind_day);
E_hybrid_gen = E_solar_gen + E_wind_gen;
E_load       = trapz(hours, load_day);
E_curt       = trapz(hours, P_curt);
E_unmet      = trapz(hours, P_unmet);
E_batt_net   = trapz(hours, P_batt);    % net energy to/from battery
RF           = (E_load - E_unmet) / E_load * 100;   % Reliability / self-sufficiency

fprintf('  ── Hybrid System Daily Energy Summary ──\n');
fprintf('     Solar generation   : %6.2f kWh\n', E_solar_gen);
fprintf('     Wind generation    : %6.2f kWh\n', E_wind_gen);
fprintf('     Total generation   : %6.2f kWh\n', E_hybrid_gen);
fprintf('     Load demand        : %6.2f kWh\n', E_load);
fprintf('     Energy curtailed   : %6.2f kWh\n', E_curt);
fprintf('     Unmet demand       : %6.2f kWh\n', E_unmet);
fprintf('     Self-sufficiency   : %5.1f %%\n\n', RF);

%% ── Figure 8: Power Flow — Full Day ─────────────────────
figure('Name','Hybrid — Power Flow','NumberTitle','off',...
       'Color','white','Position',[100 100 1050 500]);

ax1 = subplot(2,1,1); hold on; grid on;
area(hours, P_array,     'FaceColor',[1.0 0.85 0.2],'FaceAlpha',0.7,...
     'EdgeColor','none','DisplayName','Solar (kW)');
area(hours, P_wind_day,  'FaceColor',[0.4 0.7 1.0],'FaceAlpha',0.7,...
     'EdgeColor','none','DisplayName','Wind (kW)');
plot(hours, load_day,    'r-','LineWidth',2.2,'DisplayName','Load demand (kW)');
plot(hours, P_hybrid,    'k--','LineWidth',1.5,'DisplayName','Total generation (kW)');
ylabel('Power (kW)','FontSize',11);
title('Hybrid System Power Flow','FontSize',12,'FontWeight','bold');
legend('Location','north','Orientation','horizontal','FontSize',9);
xlim([0 24]); xticks(0:2:24);

ax2 = subplot(2,1,2); hold on; grid on;
% Battery charge/discharge
pos_batt = max(P_batt, 0);   neg_batt = min(P_batt, 0);
area(hours,  pos_batt, 'FaceColor',[0.2 0.8 0.3],'FaceAlpha',0.6,...
     'EdgeColor','none','DisplayName','Battery charging (kW)');
area(hours, -neg_batt, 'FaceColor',[0.8 0.3 0.1],'FaceAlpha',0.6,...
     'EdgeColor','none','DisplayName','Battery discharging (kW)');
area(hours,  P_curt,   'FaceColor',[0.7 0.7 0.7],'FaceAlpha',0.5,...
     'EdgeColor','none','DisplayName','Curtailed (kW)');
plot(hours, P_unmet,   'm-','LineWidth',1.8,'DisplayName','Unmet demand (kW)');

yyaxis right
plot(hours, SOC*100,'b-','LineWidth',2.2,'DisplayName','Battery SOC (%)');
ylabel('State of Charge (%)','FontSize',10);
ylim([0 120]);

yyaxis left
ylabel('Power (kW)','FontSize',11);
xlabel('Time of Day (h)','FontSize',11);
legend('Location','north','Orientation','horizontal','FontSize',8);
xlim([0 24]); xticks(0:2:24);

linkaxes([ax1, ax2],'x');
sgtitle('Hybrid Wind–Solar System with Battery Storage',...
        'FontSize',13,'FontWeight','bold');

%% ── Figure 9: SOC & Energy Flows Pie ────────────────────
figure('Name','Hybrid — Energy Balance','NumberTitle','off',...
       'Color','white','Position',[100 100 900 400]);

subplot(1,2,1);
plot(hours, SOC*100,'b-','LineWidth',2);
hold on; grid on;
yline(SOC_min*100,'--r','LineWidth',1.2,'DisplayName','Min SOC (15%)');
yline(80,'--g','LineWidth',1.2,'DisplayName','Target (80%)');
fill([hours, fliplr(hours)], [SOC'*100, zeros(size(hours))], ...
     [0.7 0.85 1],'FaceAlpha',0.4,'EdgeColor','none');
xlabel('Time of Day (h)','FontSize',11);
ylabel('Battery State of Charge (%)','FontSize',11);
title('Battery SOC Profile','FontSize',12,'FontWeight','bold');
legend('FontSize',8,'Location','best');
xlim([0 24]); ylim([0 110]); xticks(0:4:24);

subplot(1,2,2);
pie_vals   = [E_solar_gen, E_wind_gen, E_unmet];
pie_labels = {sprintf('Solar\n%.2f kWh', E_solar_gen),...
              sprintf('Wind\n%.2f kWh', E_wind_gen),...
              sprintf('Unmet\n%.2f kWh', E_unmet)};
pie_colors = {[1.0 0.85 0.2], [0.4 0.7 1.0], [0.9 0.3 0.3]};

p = pie(pie_vals, pie_labels);
for j = 1:length(pie_colors)
    p(j*2-1).FaceColor = pie_colors{j};
end
title(sprintf('Daily Energy Share\n(Self-sufficiency = %.1f%%)', RF),...
      'FontSize',12,'FontWeight','bold');

save('hybrid_results.mat','E_solar_gen','E_wind_gen','E_hybrid_gen',...
     'E_load','E_curt','E_unmet','RF','SOC','load_day','P_batt','hours');
