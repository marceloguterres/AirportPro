rm(list = ls())
devtools::load_all()
library(AirportPro)

sbpa <- Airport$new(system.file("extdata", "ad_sbpa.json", package = "AirportPro"))

# Criar geometrias
faixa <- runway_strip_to_sf(sbpa, "11/29", crs_final = 4326)
pista <- runway_to_sf(sbpa, "11/29", proj = FALSE)

# Iniciar mapa
mapa <- NULL

# Adicionar faixa
mapa <- add_to_map(mapa, faixa,
                   nome_camada = "Faixa 11/29 - RBAC-154",
                   cor = "#a8d8ea",
                   opacidade = 0.6,
                   grupo = "Faixas")

# Adicionar pista
mapa <- add_to_map(mapa, pista,
                   nome_camada = "Pista 11/29",
                   cor = "#004080",
                   opacidade = 0.9,
                   grupo = "Pistas")

mapa  # Agora deve mostrar ambos os grupos!

