rm(list = ls())

# Carregar pacote
devtools::clean_dll()
devtools::document()
devtools::load_all()

sbmt <- Airport$new("inst/extdata/ad_sbmt.json")
print.Airport(sbmt )

mapa_completo <- plot_airport_layers(sbmt, incluir_faixas = TRUE)
mapa_completo


pista_12_30 <- runway_to_sf(sbmt, "12/30", proj = FALSE, debug = TRUE, distance = "both")


#
