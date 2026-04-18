%% =========================================================
%  ECONOMIC_ANALYSIS.M  —  Financial & Sustainability Metrics
%  LCOE | NPV | Payback period | CO₂ avoided
%% =========================================================

load('hybrid_results.mat');

%% ── System Cost Parameters ───────────────────────────────
% Capital costs (INR)
C_solar_per_kW  = 45000;    % INR/kWp (installed cost, India 2024)
C_wind_per_kW   = 70000;    % INR/kW
C_batt_per_kWh  = 25000;    % INR/kWh (Li-ion)
C_inv_per_kW    = 8000;     % INR/kW (inverter)
C_misc          = 25000;    % Civil, wiring, monitoring

P_solar_kWp     = 4.0;      % kWp
P_wind_kW       = 2.0;      % kW
E_batt_kWh      = 10.0;     % kWh

CAPEX = C_solar_per_kW * P_solar_kWp  + ...
        C_wind_per_kW  * P_wind_kW    + ...
        C_batt_per_kWh * E_batt_kWh   + ...
        C_inv_per_kW   * (P_solar_kWp + P_wind_kW) + C_misc;

% Operating costs
O_M_annual      = 0.015 * CAPEX;   % 1.5% of CAPEX per year (O&M)
project_life    = 25;              % years
discount_rate   = 0.08;            % 8% (India discount rate)
electricity_tariff = 7.5;          % INR/kWh (Tamil Nadu commercial)
tariff_escalation  = 0.04;         % 4% annual tariff increase

% Degradation
solar_deg       = 0.005;   % 0.5%/yr  (PV degradation)
wind_deg        = 0.003;   % 0.3%/yr  (turbine ageing)

% Battery replacement at year 10
C_batt_replacement = C_batt_per_kWh * E_batt_kWh;

fprintf('  ── System Cost Summary ──\n');
fprintf('     CAPEX breakdown:\n');
fprintf('       Solar PV   : INR %,.0f\n', C_solar_per_kW * P_solar_kWp);
fprintf('       Wind       : INR %,.0f\n', C_wind_per_kW  * P_wind_kW);
fprintf('       Battery    : INR %,.0f\n', C_batt_per_kWh * E_batt_kWh);
fprintf('       Inverter   : INR %,.0f\n', C_inv_per_kW*(P_solar_kWp+P_wind_kW));
fprintf('       Misc.      : INR %,.0f\n', C_misc);
fprintf('     TOTAL CAPEX  : INR %,.0f\n\n', CAPEX);

%% ── Annual Energy & Revenue ──────────────────────────────
E_annual_base = (E_solar_gen + E_wind_gen) * 365;   % kWh/yr

years      = 1:project_life;
E_annual   = zeros(project_life,1);
Revenue    = zeros(project_life,1);
NPV_flow   = zeros(project_life,1);

for y = 1:project_life
    solar_factor = (1 - solar_deg)^y;
    wind_factor  = (1 - wind_deg )^y;
    E_yr         = E_solar_gen*365*solar_factor + E_wind_gen*365*wind_factor;
    E_annual(y)  = E_yr;

    tariff_y     = electricity_tariff * (1 + tariff_escalation)^y;
    revenue_y    = E_yr * tariff_y;
    opex_y       = O_M_annual;
    
    % Battery replacement cost in year 10
    if y == 10
        opex_y = opex_y + C_batt_replacement;
    end

    net_flow_y   = revenue_y - opex_y;
    NPV_flow(y)  = net_flow_y / (1 + discount_rate)^y;
    Revenue(y)   = revenue_y;
end

NPV         = -CAPEX + sum(NPV_flow);
cum_NPV     = cumsum(NPV_flow) - CAPEX;

% Payback period (simple)
cum_revenue = cumsum(Revenue - O_M_annual);
pb_idx      = find(cum_revenue >= CAPEX, 1);
if isempty(pb_idx)
    payback_yr = NaN;
else
    payback_yr = pb_idx;
end

% LCOE = (CAPEX + PV of O&M) / total discounted energy
total_E_discounted = sum(E_annual ./ (1+discount_rate).^years');
LCOE = (CAPEX + sum(O_M_annual./(1+discount_rate).^years') + ...
        C_batt_replacement/(1+discount_rate)^10) / total_E_discounted;

fprintf('  ── Financial Metrics ──\n');
fprintf('     Annual energy (yr1) : %.0f kWh\n', E_annual(1));
fprintf('     LCOE                : INR %.2f/kWh\n', LCOE);
fprintf('     Grid tariff (INR)   : INR %.2f/kWh\n', electricity_tariff);
fprintf('     Simple payback      : %d years\n', payback_yr);
fprintf('     NPV (25 yr)         : INR %,.0f\n\n', NPV);

%% ── CO₂ & Sustainability ─────────────────────────────────
% India grid emission factor: 0.716 kg CO₂/kWh (CEA 2023)
EF_grid     = 0.716;   % kg CO₂/kWh
CO2_avoided = sum(E_annual) * EF_grid / 1000;   % tonnes CO₂ over lifetime

% Tree equivalent (1 tree absorbs ~21 kg CO₂/yr)
trees_eq    = CO2_avoided * 1000 / (21 * project_life);

fprintf('  ── Sustainability Impact ──\n');
fprintf('     CO₂ avoided (lifetime) : %.1f tonnes\n', CO2_avoided);
fprintf('     Equivalent trees       : %.0f trees\n', trees_eq);
fprintf('     Grid energy displaced  : %.0f kWh\n\n', sum(E_annual));

%% ── Figure 10: Cash Flow & NPV ───────────────────────────
figure('Name','Economic — Cash Flow & NPV','NumberTitle','off',...
       'Color','white','Position',[100 100 900 430]);

subplot(1,2,1); hold on; grid on;
bar(years, Revenue/1000, 'FaceColor',[0.2 0.7 0.3],'EdgeColor','none',...
    'DisplayName','Annual Revenue');
bar(years, -(O_M_annual/1000)*ones(size(years)),'FaceColor',[0.9 0.3 0.2],...
    'EdgeColor','none','DisplayName','O&M Cost');
bar(10, -C_batt_replacement/1000,'FaceColor',[0.8 0.1 0.7],'EdgeColor','none',...
    'DisplayName','Battery replacement');
yline(0,'k-');
xlabel('Year','FontSize',11); ylabel('Cash Flow (× 10³ INR)','FontSize',11);
title('Annual Cash Flows','FontSize',12,'FontWeight','bold');
legend('FontSize',8,'Location','northwest'); xlim([0 26]);

subplot(1,2,2); hold on; grid on;
fill([0, years, years(end)],[0, cum_NPV'/1000, 0],[0.3 0.7 1],...
     'FaceAlpha',0.25,'EdgeColor','none');
plot([0, years], [0, cum_NPV']/1000, 'b-','LineWidth',2.2,...
     'DisplayName','Cumulative NPV');
yline(0,'k--','LineWidth',1.3,'DisplayName','Break-even');
xline(payback_yr,'--r','LineWidth',1.5,...
      'DisplayName',sprintf('Payback: %d yr',payback_yr));
scatter(project_life, NPV/1000, 80,'r','filled',...
        'DisplayName',sprintf('Final NPV: INR %.0f k',NPV/1000));
xlabel('Year','FontSize',11); ylabel('Cumulative NPV (× 10³ INR)','FontSize',11);
title('Net Present Value Analysis','FontSize',12,'FontWeight','bold');
legend('FontSize',8,'Location','northwest'); xlim([0 26]);
sgtitle('Economic Analysis — Hybrid Wind + Solar System',...
        'FontSize',13,'FontWeight','bold');

%% ── Figure 11: CO₂ & Summary Dashboard ──────────────────
figure('Name','Sustainability Dashboard','NumberTitle','off',...
       'Color','white','Position',[100 100 950 420]);

subplot(1,3,1);
bar_data = [E_solar_gen*365, E_wind_gen*365];
b = bar(bar_data/1000, 'FaceColor','flat');
b.CData = [1.0 0.85 0.2; 0.4 0.7 1.0];
set(gca,'XTickLabel',{'Solar','Wind'},'FontSize',11);
ylabel('Annual Energy (MWh/yr)','FontSize',11);
title('Annual Generation','FontSize',11,'FontWeight','bold');
grid on;
text(1, bar_data(1)/1000*1.03, sprintf('%.2f MWh',bar_data(1)/1000),...
     'HorizontalAlignment','center','FontSize',9);
text(2, bar_data(2)/1000*1.03, sprintf('%.2f MWh',bar_data(2)/1000),...
     'HorizontalAlignment','center','FontSize',9);

subplot(1,3,2);
co2_per_yr = E_annual * EF_grid / 1000;   % tonnes/yr
plot(years, co2_per_yr,'g-','LineWidth',2);
hold on; grid on;
fill([years, fliplr(years)],[co2_per_yr',zeros(size(years))],[0.2 0.8 0.2],...
     'FaceAlpha',0.3,'EdgeColor','none');
xlabel('Year','FontSize',11); ylabel('CO₂ Avoided (tonnes/yr)','FontSize',11);
title('Annual CO₂ Savings','FontSize',11,'FontWeight','bold');
text(12.5, max(co2_per_yr)*0.6, sprintf('Total: %.1f t', CO2_avoided),...
     'FontSize',10,'Color','darkgreen','FontWeight','bold',...
     'HorizontalAlignment','center');

subplot(1,3,3);
metrics  = {'CAPEX\n(INR L)', 'LCOE\n(INR/kWh)', 'Payback\n(yr)', 'NPV\n(INR L)'};
values   = [CAPEX/1e5, LCOE, payback_yr, NPV/1e5];
norm_val = values ./ max(abs(values));
theta    = linspace(0, 2*pi, 5);
theta    = theta(1:4);

% Simple bar summary (radar chart alternative)
clrs = [0.2 0.5 0.9; 0.3 0.8 0.3; 0.9 0.5 0.1; 0.7 0.2 0.7];
for j = 1:4
    hb = bar(j, values(j),'FaceColor',clrs(j,:));
    hold on;
end
set(gca,'XTick',1:4,'XTickLabel',{'CAPEX (L)','LCOE','Payback (yr)','NPV (L)'},...
        'FontSize',8);
ylabel('Value','FontSize',10);
title('Key Metrics Summary','FontSize',11,'FontWeight','bold');
grid on;

sgtitle('Hybrid System — Sustainability & Economic Dashboard',...
        'FontSize',13,'FontWeight','bold');

fprintf('  ── Project Summary ──────────────────────\n');
fprintf('     System        : 4 kWp Solar + 2 kW Wind + 10 kWh Battery\n');
fprintf('     CAPEX         : INR %.2f Lakhs\n', CAPEX/1e5);
fprintf('     LCOE          : INR %.2f/kWh\n', LCOE);
fprintf('     Payback       : %d years\n', payback_yr);
fprintf('     25-yr NPV     : INR %.2f Lakhs\n', NPV/1e5);
fprintf('     CO₂ avoided   : %.1f tonnes\n', CO2_avoided);
fprintf('     Self-suff.    : %.1f %%\n', RF);
fprintf('  ──────────────────────────────────────────\n');
