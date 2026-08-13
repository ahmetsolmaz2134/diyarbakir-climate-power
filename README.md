README.md
# 🌤️ Hydroclimatic Dynamics and Solar Energy Potential in Diyarbakır (1981–2023)

![R](https://img.shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white)
![NASA POWER](https://img.shields.io/badge/Data-NASA%20POWER-blue?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

## 📌 Abstract & Overview
The Dicle (Tigris) River Basin in Southeastern Anatolia ($37.9138^\circ\text{N}, 38.9637^\circ\text{E}$) is situated in a climate-vulnerable region experiencing severe pressures from global climate change, prolonged droughts, and shifts in regional hydrological regimes. 

This project presents a high-resolution, multi-decadal hydroclimatic and renewable energy assessment for Diyarbakır across a 43-year period (**1981–2023**). By integrating daily continuous satellite and reanalysis data from the **NASA POWER Agroclimate API**, this open-access repository quantifies long-term thermal anomalies, extreme heat frequency, agricultural drought indicators, and solar radiation variability.

---

## 🎯 Key Hydroclimatic Indicators Analyzed

| Variable Code | Description | Unit | Analytical Focus |
| :--- | :--- | :--- | :--- |
| `T2M` | 2m Mean Air Temperature | °C | Thermal Anomaly & Baseline Shift ($\Delta T$) |
| `T2M_MAX` | Daily Maximum Temperature | °C | Extreme Heat Frequency ($T_{max} \ge 40^\circ\text{C}$) |
| `PRECTOTCORR` | Corrected Precipitation | mm/day | Agricultural Drought (Consecutive Dry Days - CDD) |
| `ALLSKY_SFC_SW_DWN` | Surface Shortwave Irradiance | MJ/m²/day | Solar Renewable Energy Potential (PV Heatmap) |

---

## 🔬 Methodology & Reproducibility
1. **Data Acquisition:** Continuous daily records (15,705 observations) programmatically extracted via `nasapower` R package.
2. **Data Pipeline:** Standardized `tidyverse` functions for spatial aggregation, anomaly modeling, and heatmaps.
3. **Statistical Trend Testing:** Non-parametric evaluation framework (Mann-Kendall & Sen's Slope analysis) applied to long-term time-series.

---

## 🚀 Quick Start & Code Execution

To reproduce the analysis locally:

```R
# Install required packages
install.packages(c("nasapower", "tidyverse", "viridis", "trend"))

# Run analysis scripts sequentially
source("R/01_fetch_data.R")
source("R/02_warming_stripes.R")
source("R/03_extreme_heat_cdd.R")
source("R/04_solar_heatmap.R")
