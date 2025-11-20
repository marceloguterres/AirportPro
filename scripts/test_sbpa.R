rm(list = ls())

# Carregar pacote
devtools::clean_dll()
devtools::document()
devtools::load_all()

sbpa<- Airport$new("inst/extdata/ad_sbpa.json")
print.Airport(sbpa)

pista_11_29 <- runway_to_sf(sbpa, "11/29", debug = TRUE) # Com diagnóstico

# Cria os polígonos pistas
rw_11_29 <- runway_to_sf(sbpa, "11/29", proj = FALSE)
rw_11_29

faixa_11_29 <- runway_strip_to_sf(sbpa, "11/29", crs_final = 4326)

mapa_completo <- plot_airport_layers(sbpa, incluir_faixas = TRUE)
mapa_completo


sbpa$list_superficies()
sbpa$get_superficie("11/29_11")

print.superficies(sbpa)
