# Script de demonstração/manual – execute com source("scripts/demo_airportpro.R")
# Percorre os datasets de exemplo e imprime saídas chave para lembrar as funcionalidades.

rm(list = ls())

# Carregar o pacote a partir do código-fonte
if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all()
} else {
  stop("Instale o devtools para rodar o script de demonstração (install.packages('devtools')).")
}

banner <- function(txt) {
  cat("\n", strrep("=", 80), "\n", txt, "\n", strrep("=", 80), "\n", sep = "")
}

# Helpers para mostrar objetos de forma controlada
show_superficie <- function(apt, id) {
  s <- get_superficie(apt, id)
  cat("Superfície", id, "| Aproach:", s$approach_type, s$cat_precision %||% "", "\n")
  cat("  THR:", s$designador, "| Lat", s$latitude_thr, "| Lon", s$longitude_thr, "| Rumo", s$rumo_verdadeiro_graus, "°\n\n")
}

# -------------------------------------------------------------------------
# SBFL – Florianópolis (duas pistas, precision + visual)
# -------------------------------------------------------------------------
banner("SBFL - Florianópolis")
sbfl <- Airport$new(system.file("extdata", "ad_sbfl.json", package = "AirportPro"))

cat("\nDados básicos:\n")
print(sbfl)

cat("\nSuperfícies disponíveis:\n")
list_superficies(sbfl)
show_superficie(sbfl, "14/32_14")

cat("Geometrias (sf) da pista 14/32 com distâncias UTM e haversine:\n")
rw_sbfl <- runway_to_sf(sbfl, "14/32", proj = FALSE, distance = "both", debug = TRUE)
print(rw_sbfl[, c("pista_id", "comprimento_m", "comprimento_haversine_m", "comprimento_declarado_m", "diferenca_m")])

cat("\nFaixa (strip) 14/32:\n")
strip_sbfl <- runway_strip_to_sf(sbfl, "14/32", crs_final = 4326)
print(strip_sbfl[, c("largura_faixa_m", "comprimento_faixa_m")])

cat("\nDiagrama ASCII pista/strip 14/32:\n")
print_runway_diagram(sbfl, "14/32", width_chars = 70)

if (interactive()) {
  cat("Abrindo mapa completo (pistas + faixas)...\n")
  plot_airport_layers(sbfl, incluir_faixas = TRUE)
}

# -------------------------------------------------------------------------
# SBPA – Porto Alegre (uma pista precision)
# -------------------------------------------------------------------------
banner("SBPA - Porto Alegre")
sbpa <- Airport$new(system.file("extdata", "ad_sbpa.json", package = "AirportPro"))

print(sbpa)
list_superficies(sbpa)
show_superficie(sbpa, "11/29_11")

rw_sbpa <- runway_to_sf(sbpa, "11/29", proj = FALSE, distance = "both", debug = TRUE)
print(rw_sbpa[, c("pista_id", "comprimento_m", "comprimento_haversine_m", "diferenca_m")])

# -------------------------------------------------------------------------
# SBMT – Campo de Marte (visual, comprimento declarado x calculado)
# -------------------------------------------------------------------------
banner("SBMT - Campo de Marte")
sbmt <- Airport$new(system.file("extdata", "ad_sbmt.json", package = "AirportPro"))

print(sbmt)
rw_sbmt <- runway_to_sf(sbmt, "12/30", proj = FALSE, distance = "both", debug = TRUE)
print(rw_sbmt[, c("pista_id", "comprimento_m", "comprimento_haversine_m", "comprimento_declarado_m", "diferenca_m", "diferenca_haversine_m")])

# -------------------------------------------------------------------------
# SNCW – Alcântara (non-precision)
# -------------------------------------------------------------------------
banner("SNCW - Alcântara")
sncw <- Airport$new(system.file("extdata", "ad_sncw.json", package = "AirportPro"))

print(sncw)
list_superficies(sncw)
print("Faixa 09/27:")
print(sncw$faixas[["09/27"]][c("comprimento_faixa_m", "largura_faixa_m")])

cat("\nDemonstração concluída.\n")

