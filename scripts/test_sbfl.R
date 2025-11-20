# ================================================================
# TESTE COMPLETO SBFL – DUAS PISTAS – SUPERFÍCIES + MAPA + PDF
# AirportPro v1.0 – 09/11/2025
# ================================================================

rm(list = ls())
cat("\014")  # limpa console

# -------------------------------
# 1. CARREGA O PACOTE
# -------------------------------
devtools::document()
devtools::load_all()

# -------------------------------
# 2. CARREGA O AEROPORTO SBFL
# -------------------------------

sbfl <- Airport$new("inst/extdata/ad_sbfl.json")
print.Airport(sbfl)   # print bonito do aeroporto
print.superficies(sbfl)

# -------------------------------
# 3. GEOMETRIAS DAS PISTAS
# -------------------------------
pista_14_32 <- runway_to_sf(sbfl, "14/32", proj = FALSE)
pista_03_21 <- runway_to_sf(sbfl, "03/21", proj = FALSE)

faixa_14_32 <- runway_strip_to_sf(sbfl, "14/32", crs_final = 4326)
faixa_03_21 <- runway_strip_to_sf(sbfl, "03/21", crs_final = 4326)

# -------------------------------
# 4. MAPA INTERATIVO COM TODAS AS CAMADAS
# -------------------------------
mapa <- plot_airport_layers(sbfl,
                            incluir_faixas = TRUE)

# Salva como HTML independente
htmlwidgets::saveWidget(mapa,
                        file = "inst/docs/SBFL_Hercilio_Luz.html",
                        selfcontained = TRUE,
                        title = "SBFL – Florianópolis – Hercílio Luz")

browseURL("inst/docs/SBFL_Hercilio_Luz.html")

