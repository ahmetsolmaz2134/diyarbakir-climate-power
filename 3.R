# ==============================================================================
# PROJE: Diyarbak??r Hydroclimatic & Solar Analytics (1981-2023)
# ADIM 3: Tar??msal Kurakl??k G??stergesi - Consecutive Dry Days (CDD)
# ==============================================================================

library(tidyverse)
library(viridis)

# 1. Veri Okuma
diyarbakir_df <- readRDS("data/raw_power_diyarbakir.rds")

# 2. CDD (Kesintisiz Ya??????s??z G??n) Hesaplama Algoritmas?? (Ya?????? < 1.0 mm/g??n)
cdd_annual <- diyarbakir_df %>%
  mutate(
    YEAR = as.numeric(YEAR),
    is_dry = if_else(PRECTOTCORR < 1.0, 1, 0)
  ) %>%
  arrange(YYYYMMDD) %>%
  group_by(YEAR) %>%
  summarise(
    Max_CDD = {
      runs <- rle(is_dry)
      dry_runs <- runs$lengths[runs$values == 1]
      if(length(dry_runs) == 0) 0 else max(dry_runs)
    },
    Total_Annual_Rain = sum(PRECTOTCORR, na.rm = TRUE),
    .groups = "drop"
  )

# Lineer Trend ??statistikleri
lm_cdd <- lm(Max_CDD ~ YEAR, data = cdd_annual)
slope_cdd_decade <- coef(lm_cdd)["YEAR"] * 10
p_val_cdd <- summary(lm_cdd)$coefficients["YEAR", "Pr(>|t|)"]
mean_cdd <- mean(cdd_annual$Max_CDD)
max_cdd_row <- cdd_annual %>% filter(Max_CDD == max(Max_CDD))

# ==============================================================================
# GRAF??K: Consecutive Dry Days (CDD) Trend Line Plot
# ==============================================================================

p3 <- ggplot(cdd_annual, aes(x = YEAR, y = Max_CDD)) +
  geom_line(color = "chocolate4", linewidth = 0.9, alpha = 0.7) +
  geom_point(aes(size = Total_Annual_Rain, color = Max_CDD), alpha = 0.9) +
  geom_hline(yintercept = mean_cdd, linetype = "dashed", color = "darkblue", linewidth = 0.8) +
  geom_smooth(method = "lm", se = TRUE, color = "sienna3", fill = "sienna", alpha = 0.15) +
  
  # En Uzun Kurak D??nem ????aret??isi
  annotate("segment", x = max_cdd_row$YEAR, xend = max_cdd_row$YEAR,
           y = max_cdd_row$Max_CDD + 15, yend = max_cdd_row$Max_CDD + 3,
           arrow = arrow(length = unit(0.2, "cm")), color = "firebrick3", linewidth = 0.8) +
  annotate("text", x = max_cdd_row$YEAR, y = max_cdd_row$Max_CDD + 20,
           label = sprintf("Peak Drought: %d\n(%d Consecutive Dry Days)", max_cdd_row$YEAR, max_cdd_row$Max_CDD),
           fontface = "bold", size = 3.2, color = "firebrick3") +
  
  # ??statistiksel Bilgi Kutusu
  annotate("text", x = 1982, y = max(cdd_annual$Max_CDD) * 0.95,
           label = sprintf("43-Yr Mean CDD: %.1f Days\nLinear Rate: %+.2f Days/Decade\np-value: %.4f\nThreshold: Rain < 1.0 mm/day",
                           mean_cdd, slope_cdd_decade, p_val_cdd),
           hjust = 0, vjust = 1, fontface = "bold", size = 3.3,
           bbox = list(boxstyle = "round,pad=0.5", fill = "linen", alpha = 0.9)) +
  
  scale_color_viridis_c(option = "magma", direction = -1, name = "Max CDD (Days)") +
  scale_size_continuous(range = c(2, 6), name = "Total Rain (mm)") +
  scale_x_continuous(breaks = seq(1981, 2023, by = 5)) +
  scale_y_continuous(labels = scales::number_format(suffix = " days")) +
  
  labs(
    title = "Agricultural Drought Indicator: Maximum Consecutive Dry Days (CDD) in Diyarbak??r",
    subtitle = "Multi-Decadal Evolution of Uninterrupted Dry Spells (1981???2023) | NASA POWER Reanalysis",
    x = "Year",
    y = "Maximum Annual Consecutive Dry Days (CDD)",
    caption = "Point size corresponds to total annual precipitation | Data Source: NASA POWER"
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13, color = "#1a1a1a"),
    plot.subtitle = element_text(size = 10, color = "#4a4a4a"),
    axis.title = element_text(face = "bold", size = 11),
    legend.position = "right"
  )

# Kaydetme
ggsave("output/figures/consecutive_dry_days.png", plot = p3, width = 11, height = 6, dpi = 300)
message(">> 'output/figures/consecutive_dry_days.png' ba??ar??yla kaydedildi.")