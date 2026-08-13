# ==============================================================================
# PROJE: Diyarbak??r Hydroclimatic & Solar Analytics (1981-2023)
# ADIM 2: Y??ll??k S??cakl??k Anomalileri ve A????r?? S??cak G??n Trendleri
# ==============================================================================

library(tidyverse)
library(viridis)
library(grid)

# 1. Veriyi Okuma
diyarbakir_df <- readRDS("data/raw_power_diyarbakir.rds")

# Dizin Kontrol??
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)

# 2. Y??ll??k ??statistiklerin Hesaplanmas??
annual_stats <- diyarbakir_df %>%
  mutate(YEAR = as.numeric(YEAR)) %>%
  group_by(YEAR) %>%
  summarise(
    T_mean = mean(T2M, na.rm = TRUE),
    Days_Above_40 = sum(T2M_MAX >= 40, na.rm = TRUE),
    .groups = "drop"
  )

# Baseline Ortalamas?? (1981-2010 ??klim Referans D??nemi)
baseline_temp <- annual_stats %>%
  filter(YEAR >= 1981 & YEAR <= 2010) %>%
  summarise(base_mean = mean(T_mean)) %>%
  pull(base_mean)

# Anomali Hesaplama ve Trend E??imi
annual_stats <- annual_stats %>%
  mutate(Anomaly = T_mean - baseline_temp)

# Lineer Trend Modeli
lm_anomaly <- lm(Anomaly ~ YEAR, data = annual_stats)
slope_deg_decade <- coef(lm_anomaly)["YEAR"] * 10
p_val_anomaly <- summary(lm_anomaly)$coefficients["YEAR", "Pr(>|t|)"]

# Max Anomali Y??l??
max_anno_row <- annual_stats %>% filter(Anomaly == max(Anomaly))

# ==============================================================================
# GRAF??K 1: Temperature Anomaly & Warming Bars (With Exact Values)
# ==============================================================================

p1 <- ggplot(annual_stats, aes(x = YEAR, y = Anomaly, fill = Anomaly)) +
  geom_col(width = 0.85, show.legend = TRUE) +
  geom_hline(yintercept = 0, color = "black", linewidth = 0.8, linetype = "solid") +
  geom_smooth(method = "lm", se = FALSE, color = "darkred", linetype = "dashed", linewidth = 1) +
  
  # Say??sal Etiketler ve Oklar
  annotate("text", x = 1983, y = max(annual_stats$Anomaly) * 0.9,
           label = sprintf("Baseline (1981-2010): %.2f ??C\nLinear Trend: +%.3f ??C/decade\n(p = %.4f)", 
                           baseline_temp, slope_deg_decade, p_val_anomaly),
           hjust = 0, vjust = 1, fontface = "bold", size = 3.5,
           bbox = list(boxstyle = "round,pad=0.5", fill = "white", alpha = 0.8)) +
  
  # En S??cak Y??l ????aret??isi
  annotate("segment", x = max_anno_row$YEAR, xend = max_anno_row$YEAR,
           y = max_anno_row$Anomaly + 0.3, yend = max_anno_row$Anomaly + 0.05,
           arrow = arrow(length = unit(0.2, "cm")), color = "darkred", linewidth = 0.8) +
  annotate("text", x = max_anno_row$YEAR, y = max_anno_row$Anomaly + 0.45,
           label = sprintf("Warmest Year: %d\n(+%.2f ??C Anomaly)", max_anno_row$YEAR, max_anno_row$Anomaly),
           fontface = "bold", size = 3, color = "darkred") +
  
  scale_fill_gradient2(
    low = "#2166ac", mid = "#f7f7f7", high = "#b2182b",
    midpoint = 0, name = "Anomaly (??C)"
  ) +
  scale_x_continuous(breaks = seq(1981, 2023, by = 5), expand = c(0.01, 0.01)) +
  scale_y_continuous(labels = scales::number_format(suffix = " ??C")) +
  
  labs(
    title = "Annual Surface Air Temperature Anomalies in Diyarbak??r (1981???2023)",
    subtitle = "Relative to 1981???2010 Climatological Baseline | Data Source: NASA POWER API",
    x = "Year",
    y = "Temperature Anomaly (??C)",
    caption = "Analytical Methodology: Non-parametric & Linear Trend Fitting | Spatial Location: 37.9138?? N, 38.9637?? E"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, color = "#1a1a1a"),
    plot.subtitle = element_text(size = 10, color = "#4a4a4a", margin = margin(b = 10)),
    axis.title = element_text(face = "bold", size = 11),
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.key.width = unit(2, "cm")
  )

# Kaydetme 1
ggsave("output/figures/warming_stripes.png", plot = p1, width = 10, height = 6, dpi = 300)
message(">> 'output/figures/warming_stripes.png' ba??ar??yla kaydedildi.")

# ==============================================================================
# GRAF??K 2: Annual Extreme Heat Days (Tmax >= 40??C) Trend Analysis
# ==============================================================================

lm_days <- lm(Days_Above_40 ~ YEAR, data = annual_stats)
slope_days_decade <- coef(lm_days)["YEAR"] * 10
p_val_days <- summary(lm_days)$coefficients["YEAR", "Pr(>|t|)"]
mean_days <- mean(annual_stats$Days_Above_40)

p2 <- ggplot(annual_stats, aes(x = YEAR, y = Days_Above_40)) +
  geom_segment(aes(x = YEAR, xend = YEAR, y = 0, yend = Days_Above_40), color = "gray60", linewidth = 0.7) +
  geom_point(aes(color = Days_Above_40), size = 3.5, show.legend = FALSE) +
  geom_hline(yintercept = mean_days, linetype = "dotted", color = "blue", linewidth = 0.8) +
  geom_smooth(method = "lm", se = TRUE, color = "red3", fill = "red", alpha = 0.15) +
  
  # Say??sal De??er Etiketleri (Sadece Ortalamadan Y??ksek Y??llar ????in)
  geom_text(data = annual_stats %>% filter(Days_Above_40 >= mean_days + 5),
            aes(label = Days_Above_40), vjust = -0.8, size = 2.8, fontface = "bold") +
  
  # ??statistiksel Not Kutusu
  annotate("text", x = 1983, y = max(annual_stats$Days_Above_40) * 0.95,
           label = sprintf("Mean Frequency: %.1f Days/Year\nRate of Change: +%.2f Days/Decade\nStatistical Significance: p = %.4f",
                           mean_days, slope_days_decade, p_val_days),
           hjust = 0, vjust = 1, fontface = "bold", size = 3.5,
           bbox = list(boxstyle = "round,pad=0.5", fill = "ghostwhite", alpha = 0.9)) +
  
  scale_color_viridis_c(option = "inferno", direction = -1) +
  scale_x_continuous(breaks = seq(1981, 2023, by = 5)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  
  labs(
    title = "Annual Frequency of Extreme Heat Days (Tmax ??? 40??C) in Diyarbak??r",
    subtitle = "43-Year Trend Analysis (1981???2023) Based on Daily Satellite Reanalysis",
    x = "Year",
    y = "Number of Days (Tmax ??? 40??C)",
    caption = "Dotted line represents 43-year historical mean | Data Source: NASA POWER"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14, color = "#1a1a1a"),
    plot.subtitle = element_text(size = 10, color = "#4a4a4a"),
    axis.title = element_text(face = "bold", size = 11),
    panel.grid.minor = element_blank()
  )

# Kaydetme 2
ggsave("output/figures/extreme_heat_days.png", plot = p2, width = 10, height = 6, dpi = 300)
message(">> 'output/figures/extreme_heat_days.png' ba??ar??yla kaydedildi.")