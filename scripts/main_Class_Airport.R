rm(list = ls())

devtools::document()
devtools::load_all()

# ↑ Objeto da classe Airport com dados processados
sbpa <- Airport$new("inst/extdata/ad_sbpa.json")
sbpa
sbpa$arp$lat
sbpa$arp$lon
sbpa$arp$elev_m
sbpa$pistas$`11/29`


# Análise de Pistas - exemplos válidos:
"11/29"  # Pista bidirecional
"14/32"  # Outra pista
"09L/27R" # Com sufixos L/R/C
"03/21"  # Números com zero à esquerda


# Coordenadas em graus decimais
# WGS84 como default
# CRS: EPSG:4326 (WGS84)
# Uso: Mapas web, Leaflet, Google
pista_sbpa_wgs84 <- runway_to_sf(sbpa, "11/29", proj = FALSE)
pista_sbpa_wgs84

# Coordenadas em metros
# CRS: EPSG:32722 (UTM 22S para SBPA)
# Uso: Análises métricas, cálculos de área, CAD
# pista_utm <- runway_to_sf(sbpa, "11/29", proj = TRUE)
# pista_utm
# Nenhuma impressão no console
# Só retorna o objeto sf
# pista <- runway_to_sf(sbpa, "11/29", debug = FALSE)
# Detalha a impressão no console
pista <- runway_to_sf(sbpa, "11/29", debug = TRUE)

mapa <- plot_all_runways_leaflet(lista_pistas = list(pista_sbpa_wgs84),
                                 cores_personalizadas = c("blue"))



sbpa$pistas$`11/29`

sbpa$faixas


faixa_11_29 <- runway_strip_to_sf(sbpa, "11/29", crs_final = 4326)

# Plot bonito
ggplot() +
  geom_sf(data = faixa_11_29, fill = "#a8d8ea", color = "#0066cc", size = 1.2) +
  geom_sf_label(data = faixa_11_29, aes(label = pista_id), nudge_y = 0.001) +
  theme_void() +
  labs(title = "Faixa de Pista 11/29 - SBPA (RBAC-154)",
       subtitle = "Largura: 325 m | Comprimento: 3320 m | ±140 m lateral | +60 m longitudinal")





