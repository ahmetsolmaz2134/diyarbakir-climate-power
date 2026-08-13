# ==============================================================================
# PROJE: Diyarbak??r Hydroclimatic & Solar Analytics (1981-2023)
# ADIM 1: NASA POWER API Veri ??ekme Beti??i (D??zeltilmi??)
# KONUM: Diyarbak??r Merkez (37.9138?? N, 38.9637?? E)
# ==============================================================================

# 1. K??t??phanelerin Y??klenmesi
library(nasapower)
library(tidyverse)

# 2. Parametrelerin ve Koordinatlar??n Tan??mlanmas??
lon <- 38.9637
lat <- 37.9138
start_date <- "1981-01-01"
end_date   <- "2023-12-31"

message(">> Diyarbak??r iklim verileri NASA POWER sunucular??ndan indiriliyor...")

# 3. NASA POWER API'den G??nl??k Verilerin ??ekilmesi
diyarbakir_raw <- get_power(
  community = "ag", # G??ncel nasapower paketinde "agrimeteorology" yerine "ag" kullan??l??r
  pars = c("T2M", "T2M_MAX", "T2M_MIN", "PRECTOTCORR", "ALLSKY_SFC_SW_DWN"),
  temporal_api = "daily",
  lonlat = c(lon, lat),
  dates = c(start_date, end_date)
)

# 4. Veri Yap??s??n??n Kontrol Edilmesi
message(">> Veri ??ekme i??lemi tamamland??! Toplam sat??r say??s??: ", nrow(diyarbakir_raw))
print(head(diyarbakir_raw))

# 5. Dizin Yap??s??n??n Kontrol?? ve Verinin Kaydedilmesi
dir.create("data", showWarnings = FALSE)

# RDS format??nda saklama
saveRDS(diyarbakir_raw, file = "data/raw_power_diyarbakir.rds")

# CSV olarak d????a aktarma
write_csv(diyarbakir_raw, file = "data/raw_power_diyarbakir.csv")

message(">> Veriler 'data/raw_power_diyarbakir.rds' ve 'data/raw_power_diyarbakir.csv' olarak kaydedildi.")