
  HYBRID WIND & SOLAR ENERGY SYSTEM — MATLAB PROJECT
  Renewable Energy Systems | Course Project (10 Marks)


AUTHOR     : [Your Name / Roll No.]
COURSE     : Renewable Energy Systems / Power Electronics
SITE       : Coastal Tamil Nadu, India
SOFTWARE   : MATLAB R2021b or later (no toolboxes required)

--------------------------------------------------------
PROJECT OVERVIEW
--------------------------------------------------------
This project models, simulates and economically evaluates
a grid-connected Hybrid Renewable Energy System (HRES)
consisting of:

  • 4 kWp Solar PV Array  (10 × Trina TSM-400 modules)
  • 2 kW Small Wind Turbine
  • 10 kWh Li-ion Battery Bank
  • Location: Chennai / Coastal Tamil Nadu

--------------------------------------------------------
FILE STRUCTURE
--------------------------------------------------------
  main.m               ← Run this file first
  solar_model.m        ← PV single-diode model
  wind_model.m         ← Wind turbine + Weibull model
  hybrid_analysis.m    ← Energy balance + battery sim
  economic_analysis.m  ← LCOE, NPV, CO₂ analysis
  README.txt           ← This file

--------------------------------------------------------
HOW TO RUN
--------------------------------------------------------
  1. Open MATLAB
  2. Set the project folder as your Current Folder
  3. Type in the Command Window:
       >> main
  4. All 11 figures will be generated automatically.
  5. Results are also printed to the Command Window.

  Alternatively, run each script independently in order:
       >> solar_model
       >> wind_model
       >> hybrid_analysis
       >> economic_analysis

--------------------------------------------------------
FIGURES GENERATED
--------------------------------------------------------
  Fig 1  — Solar I-V curves vs Irradiance
  Fig 2  — Solar I-V curves vs Temperature
  Fig 3  — Daily Solar Generation Profile
  Fig 4  — Wind Turbine Power Curve
  Fig 5  — Cp vs Tip Speed Ratio (Betz theory)
  Fig 6  — Weibull Distribution + Wind × Power
  Fig 7  — Daily Wind Power Profile
  Fig 8  — Hybrid System Power Flow (full day)
  Fig 9  — Battery SOC & Energy Share Pie
  Fig 10 — Cash Flow & NPV Analysis
  Fig 11 — Sustainability Dashboard

--------------------------------------------------------
PHYSICAL MODELS USED
--------------------------------------------------------
Solar PV — Single-Diode Model (5-parameter):
  I = Iph - I0*(exp((V+I*Rs)/(n*Vt)) - 1) - (V+I*Rs)/Rsh
  Solved iteratively via Newton-Raphson method

Wind Turbine — Betz Theory + Cp-λ model:
  P = 0.5 * ρ * A * Cp(λ) * v³   (cubic region)
  Cp from empirical tip-speed-ratio characteristic

Wind Statistics — 2-parameter Weibull distribution:
  f(v) = (k/c)*(v/c)^(k-1)*exp(-(v/c)^k)
  Site: k=2.1, c=7.5 m/s (coastal Tamil Nadu)

Battery — Simple energy balance with SOC tracking:
  SOC(t) = SOC(t-1) ± ΔE/E_cap   (with η_ch, η_dis)

Economics — Standard energy project metrics:
  LCOE  = Total lifecycle cost / Total discounted energy
  NPV   = -CAPEX + Σ [Net cash flow / (1+r)^t]

--------------------------------------------------------
KEY RESULTS SUMMARY (Typical Output)
--------------------------------------------------------
  Daily Solar Energy   : ~14–18 kWh/day
  Daily Wind Energy    : ~12–16 kWh/day
  Self-sufficiency     : ~85–95%
  LCOE                 : INR 4–6/kWh
  Simple Payback       : 6–9 years
  25-yr NPV            : INR 2–5 Lakhs
  CO₂ Avoided          : ~80–120 tonnes (lifetime)

--------------------------------------------------------
REFERENCES
--------------------------------------------------------
  [1] Villalva et al., "Comprehensive approach to modeling
      and simulation of PV arrays," IEEE Trans. Power
      Electronics, 2009.
  [2] Manwell, McGowan & Rogers, "Wind Energy Explained,"
      Wiley, 2009.
  [3] CEA India Grid Emission Factor Report, 2023.
  [4] MNRE Solar Tariff Data, India, 2024.
  [5] IEC 61724 — Photovoltaic System Performance Monitoring.

========================================================
