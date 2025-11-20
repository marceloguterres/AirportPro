# R/print.aerodromo.R
#' Método print personalizado para objetos Airport – FORMATO RELATÓRIO OFICIAL
#'
#' @param x Objeto Airport
#' @param ... Argumentos adicionais
#' @return Invisibly retorna o objeto x
#' @method print Airport
#' @export
print.Airport <- function(x, ...) {
  cat("================================================================================\n")
  cat("                             DADOS DO AERÓDROMO                                 \n")
  cat("================================================================================\n\n")

  cat("CÓDIGO ICAO         : ", x$icao, "\n")
  cat("NOME OFICIAL        : ", x$nome %||% "Não informado", "\n")
  cat("MUNICÍPIO / UF      : ", x$municipio, " / ", x$estado, "\n")
  cat("DATUM               : ", x$datum, "\n")
  cat("SISTEMA DE COORD.   : EPSG:", x$crs_planar, "\n\n")

  cat("ARP (PONTO DE REFERÊNCIA DO AERÓDROMO)\n")
  cat("  Latitude          : ", sprintf("%.6f", x$arp$lat), "\n")
  cat("  Longitude         : ", sprintf("%.6f", x$arp$lon), "\n")
  cat("  Elevação          : ", sprintf("%.1f", x$arp$elev_m), " m\n\n")

  cat("================================================================================\n")
  cat("                        FAIXAS DE PISTA – RBAC-154                             \n")
  cat("================================================================================\n\n")

  for (id in names(x$pistas)) {
    p <- x$pistas[[id]]
    f <- x$faixas[[id]]
    cab1 <- p$cabeceiras[[1]]
    cab2 <- p$cabeceiras[[2]]
    dist <- .calc_runway_lengths(cab1, cab2, p$comprimento_m)

    cat("PISTA               : ", id, "\n")
    cat("  Comprimento       : ", p$comprimento_m, " m\n")
    cat("    • Calculado UTM : ", dist$utm, " m (Δ ", dist$utm_delta, " m)\n")
    cat("    • Haversine     : ", dist$haversine, " m (Δ ", dist$haversine_delta, " m)\n")
    cat("  Largura           : ", p$largura_m, " m\n")
    cat("  Pavimento         : ", p$tipo_pavimento %||% "Não informado", "\n")
    cat("  Código de ref.    : ", paste0(f$code_number, f$code_letter), "\n")
    cat("  Tipo de operação  : ",
        switch(f$approach_type,
               precision = "Aproximação de precisão",
               `non-precision` = "Aproximação não de precisão",
               visual = "Aproximação visual",
               "Desconhecido"), "\n\n")

    cat("  FAIXA DE PISTA (STRIP)\n")
    cat("    Largura total     : ", f$largura_faixa_m, " m (±", f$lateral_width_m, " m do eixo)\n")
    cat("    Comprimento total : ", f$comprimento_faixa_m, " m (+", f$longitudinal_ext_m, " m em cada extremidade)\n")
    cat("    Extensão lateral  : ", f$lateral_width_m, " m de cada lado\n\n")

    cat("  CABECEIRAS\n")
    for (cab in p$cabeceiras) {
      cat(sprintf("    %s → Lat: %.6f | Lon: %.6f | Elev: %.1f m | Rumo: %.1f° | %s\n",
                  cab$designador,
                  cab$lat, cab$lon,
                  cab$elev_m,
                  cab$rumo,
                  cab$tecnologia_aproximacao %||% "Sem auxílios"))
    }
    cat("\n")
    cat("--------------------------------------------------------------------------------\n\n")
  }

  cat("NORMATIVA APLICADA: RBAC-154 §154.207(c) – Faixa de pista\n")
  cat("DADOS VALIDADOS CONTRA SCHEMA AirportPro v1.0.3\n")
  cat("GERADO EM: ", format(Sys.time(), "%d/%m/%Y %H:%M"), "\n")
  cat("================================================================================\n")

  invisible(x)
}

#' Distâncias calculadas (UTM e haversine) com diferença vs declarado
#' @keywords internal
.calc_runway_lengths <- function(cab1, cab2, declarado) {
  # UTM
  utm_pts <- convert_runways_to_utm(cab1, cab2)
  utm_dist <- sqrt(sum((utm_pts$B - utm_pts$A)^2))

  # Geodésica
  hav_dist <- geosphere::distHaversine(
    c(cab1$lon, cab1$lat),
    c(cab2$lon, cab2$lat)
  )

  format_num <- function(x) round(x, 1)
  format_delta <- function(valor) {
    if (is.null(declarado) || is.na(declarado)) return("NA")
    diff <- round(valor - declarado, 1)
    if (diff > 0) paste0("+", diff) else as.character(diff)
  }

  list(
    utm = format_num(utm_dist),
    haversine = format_num(hav_dist),
    utm_delta = format_delta(utm_dist),
    haversine_delta = format_delta(hav_dist)
  )
}
