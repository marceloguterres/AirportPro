rm(list = ls())

devtools::document()
devtools::load_all()


cat("🚀 Carregando Centro de Lançamento de Alcântara")
cat(" (SNCW)\n")
sncw <- Airport$new("inst/extdata/ad_sncw.json")
print(sncw)
cat("\n📐 Criando geometrias da pista 09/27...\n")
pista_09_27 <- runway_to_sf(sncw, "09/27", proj = FALSE, debug = TRUE)
faixa_09_27 <- runway_strip_to_sf(sncw, "09/27", crs_final = 4326)

mapa_completo <- plot_airport_layers(sncw , incluir_faixas = TRUE)
mapa_completo
