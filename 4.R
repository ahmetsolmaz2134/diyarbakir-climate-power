# ==============================================================================
# PROJE: Diyarbak??r Hydroclimatic & Solar Analytics (1981-2023)
# ADIM 2: Akademik G??rselle??tirme Beti??i (Ekrana ????kt?? & G??rsel Kay??t)
# ==============================================================================

library(tidyverse)
library(viridis)
library(grid)

# 1. Veriyi Okuma ve Dizin Haz??rl??????
diyarbakir_df <- readRDS("data/raw_power_diyarbakir.rds")
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

# 2. Y??ll??k ??statistiklerin Derlenmesi
annual_stats <- diyarbakir_df %>%
  mutate(YEAR = as.numeric(YEAR)) %>%
  group_by(YEAR) %>%
  summarise(
    T_mean = mean(T2M, na.rm = TRUE),
    Days_Above_40 = sum(T2M_MAX >= 40, na.rm = TRUE),
    Max_CDD = {
      runs <- rle(if_else(PRECTOTCORR < 1.0, 1, 0))
      dry_runs <- runs$lengths[runs$values == 1]
      if(length(dry_runs) == 0) 0 else max(dry_runs, na.rm = TRUE)
    },
    .groups = "drop"
  )

# Baseline Ortalamas?? (1981-2010 ??klim Referans D??nemi)
baseline_temp <- annual_stats %>%
  filter(YEAR >= 1981 & YEAR <= 2010) %>%
  summarise(base_mean = mean(T_mean, na.rm = TRUE)) %>%
  pull(base_mean)

annual_stats <- annual_stats %>%
  mutate(Anomaly = T_mean - baseline_temp)

# ==============================================================================
# GRAF??K 1: Temperature Anomaly & Warming Stripes (Say??sal Detayl??)
# ==============================================================================

lm_anomaly <- lm(Anomaly ~ YEAR, data = annual_stats)
slope_anno <- coef(lm_anomaly)["YEAR"] * 10
p_anno <- summary(lm_anomaly)$coefficients["YEAR", "Pr(>|t|)"]
max_anno <- annual_stats %>% filter(Anomaly == max(Anomaly, na.rm = TRUE))

p1 <- ggplot(annual_stats, aes(x = YEAR, y = Anomaly, fill = Anomaly)) +
  geom_col(width = 0.85) +
  geom_hline(yintercept = 0, color = "black", linewidth = 0.8) +
  geom_smooth(method = "lm", se = FALSE, color = "darkred", linetype = "dashed", linewidth = 1) +
  
  # ??statistiksel Bilgi Kutusu
  annotate("text", x = 1982, y = max(annual_stats$Anomaly) * 0.9,
           label = sprintf("Baseline (1981-2010): %.2f ??C\nLinear Slope: +%.3f ??C/decade\nSignificance: p = %.4f", 
                           baseline_temp, slope_anno, p_anno),
           hjust = 0, vjust = 1, fontface = "bold", size = 3.5,
           bbox = list(boxstyle = "round,pad=0.5", fill = "white", alpha = 0.85)) +
  
  # En S??cak Y??l Ok ve Etiket
  annotate("segment", x = max_anno$YEAR, xend = max_anno$YEAR,
           y = max_anno$Anomaly + 0.35, yend = max_anno$Anomaly + 0.05,
           arrow = arrow(length = unit(0.2, "cm")), color = "darkred", linewidth = 0.8) +
  annotate("text", x = max_anno$YEAR, y = max_anno$Anomaly + 0.5,
           label = sprintf("Warmest Year: %d\n(+%.2f ??C Anomaly)", max_anno$YEAR, max_anno$Anomaly),
           fontface = "bold", size = 3, color = "darkred") +
  
  scale_fill_gradient2(low = "#2166ac", mid = "#f7f7f7", high = "#b2182b", midpoint = 0, name = "Anomaly (??C)") +
  scale_x_continuous(breaks = seq(1981, 2023, by = 5), expand = c(0.01, 0.01)) +
  scale_y_continuous(labels = scales::number_format(suffix = " ??C")) +
  
  labs(
    title = "Annual Surface Air Temperature Anomalies in Diyarbak??r (1981???2023)",
    subtitle = "Relative to 1981???2010 Climatological Baseline | NASA POWER Reanalysis Data",
    x = "Year", y = "Temperature Anomaly (??C)",
    caption = "Analytical Methodology: Linear & Non-parametric Trend Evaluation | Spatial Location: 37.9138?? N, 38.9637?? E"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    axis.title = element_text(face = "bold"),
    legend.position = "bottom", legend.key.width = unit(1.8, "cm")
  )

# Ekrana Bas ve Disk Y??kle
print(p1)
ggsave("output/figures/warming_stripes.png", plot = p1, width = 10, height = 6, dpi = 300)

# ==============================================================================
# GRAF??K 2: Annual Extreme Heat Days (Tmax >= 40??C)
# ==============================================================================

lm_days <- lm(Days_Above_40 ~ YEAR, data = annual_stats)
slope_days <- coef(lm_days)["YEAR"] * 10
p_days <- summary(lm_days)$coefficients["YEAR", "Pr(>|t|)"]
mean_days <- mean(annual_stats$Days_Above_40, na.rm = TRUE)

p2 <- ggplot(annual_stats, aes(x = YEAR, y = Days_Above_40)) +
  geom_segment(aes(x = YEAR, xend = YEAR, y = 0, yend = Days_Above_40), color = "gray60", linewidth = 0.7) +
  geom_point(aes(color = Days_Above_40), size = 3.5, show.legend = FALSE) +
  geom_hline(yintercept = mean_days, linetype = "dotted", color = "blue", linewidth = 0.8) +
  geom_smooth(method = "lm", se = TRUE, color = "red3", fill = "red", alpha = 0.15) +
  
  # De??er Etiketleri
  geom_text(data = annual_stats %>% filter(Days_Above_40 >= mean_days + 4),
            aes(label = Days_Above_40), vjust = -0.8, size = 2.8, fontface = "bold") +
  
  annotate("text", x = 1982, y = max(annual_stats$Days_Above_40) * 0.95,
           label = sprintf("43-Year Mean: %.1f Days/Year\nRate of Increase: +%.2f Days/Decade\np-value: %.4f",
                           mean_days, slope_days, p_days),
           hjust = 0, vjust = 1, fontface = "bold", size = 3.5,
           bbox = list(boxstyle = "round,pad=0.5", fill = "ghostwhite", alpha = 0.9)) +
  
  scale_color_viridis_c(option = "inferno", direction = -1) +
  scale_x_continuous(breaks = seq(1981, 2023, by = 5)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  
  labs(
    title = "Annual Frequency of Extreme Heat Days (Tmax ??? 40??C) in Diyarbak??r",
    subtitle = "Multi-Decadal Trend Analysis (1981???2023) Based on Daily Agroclimate Data",
    x = "Year", y = "Number of Days (Tmax ??? 40??C)",
    caption = "Dotted line represents historical mean | High frequency years annotated with exact counts"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    axis.title = element_text(face = "bold")
  )

# Ekrana Bas ve Disk Y??kle
print(p2)
ggsave("output/figures/extreme_heat_days.png", plot = p2, width = 10, height = 6, dpi = 300)

# ==============================================================================
# GRAF??K 3: Solar Radiation Heatmap (Ayl??k/Y??ll??k Matris)
# ==============================================================================

monthly_solar <- diyarbakir_df %>%
  mutate(
    YEAR = as.numeric(YEAR),
    MONTH = as.numeric(MM),
    Month_Name = factor(month.abb[MONTH], levels = month.abb)
  ) %>%
  group_by(YEAR, Month_Name) %>%
  summarise(Mean_Solar = mean(ALLSKY_SFC_SW_DWN, na.rm = TRUE), .groups = "drop")

p3 <- ggplot(monthly_solar, aes(x = YEAR, y = Month_Name, fill = Mean_Solar)) +
  geom_tile(color = "white", linewidth = 0.15) +
  scale_fill_viridis_c(option = "plasma", name = "Irradiance\n(MJ/m??/day)") +
  scale_x_continuous(breaks = seq(1981, 2023, by = 5), expand = c(0, 0)) +
  scale_y_discrete(limits = rev(month.abb)) +
  
  labs(
    title = "Surface Shortwave Solar Irradiance Heatmap Matrix (Diyarbak??r, 1981???2023)",
    subtitle = "Monthly Mean Surface All-Sky Solar Irradiance Potential | NASA POWER API",
    x = "Year", y = "Month",
    caption = "Spatial Coordinates: 37.9138?? N, 38.9637?? E | Unit: Megajoules per square meter per day"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    axis.title = element_text(face = "bold"),
    axis.text.y = element_text(face = "bold"),
    panel.grid = element_blank()
  )

# Ekrana Bas ve Disk Y??kle
print(p3)
ggsave("output/figures/solar_heatmap.png", plot = p3, width = 11, height = 6.5, dpi = 300)

message(">> T??m akademik grafikler ekrana bas??ld?? ve 'output/figures/' klas??r??ne kaydoldu!")