%% =========================================================
%  HYBRID WIND & SOLAR ENERGY SYSTEM — MAIN SCRIPT
%  Course Project | Renewable Energy Systems
%  Run this file to execute the full project analysis
%% =========================================================

clc; clear; close all;

fprintf('============================================\n');
fprintf('  HYBRID WIND & SOLAR ENERGY SYSTEM\n');
fprintf('  Real-Life Application Project\n');
fprintf('============================================\n\n');

%% ── 1. Solar PV Analysis ─────────────────────────────────
fprintf('[1/4] Running Solar PV Analysis...\n');
solar_model;

%% ── 2. Wind Turbine Analysis ─────────────────────────────
fprintf('[2/4] Running Wind Turbine Analysis...\n');
wind_model;

%% ── 3. Hybrid System Energy Balance ─────────────────────
fprintf('[3/4] Running Hybrid System Analysis...\n');
hybrid_analysis;

%% ── 4. Economic & CO₂ Analysis ──────────────────────────
fprintf('[4/4] Running Economic & Sustainability Analysis...\n');
economic_analysis;

fprintf('\n============================================\n');
fprintf('  All analyses complete. See figures.\n');
fprintf('============================================\n');
