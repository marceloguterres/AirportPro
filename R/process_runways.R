# R/process_runways.R
#' Processa dados JSON de pistas para estrutura interna
#'
#' @param pistas_json Lista de pistas do JSON do aeroporto
#' @return Lista estruturada com dados das pistas
#' @keywords internal
.process_runways <- function(pistas_json) {

  if (is.null(pistas_json) || length(pistas_json) == 0) {
    return(list())
  }

  resultado <- list()

  for (p in pistas_json) {
    id <- p$identificacao

    # Validar dados obrigatórios
    if (is.null(id) || is.null(p$cabeceiras)) {
      stop(sprintf("Dados inválidos na pista: id=%s", id %||% "NULL"))
    }

    resultado[[id]] <- create_runway_structure(p)
  }

  resultado
}

#' Cria estrutura padronizada para uma pista
#' @keywords internal
create_runway_structure <- function(pista_data) {
  list(
    identificacao     = pista_data$identificacao,
    comprimento_m     = pista_data$comprimento_m,
    largura_m         = pista_data$largura_m,
    tipo_pavimento    = pista_data$tipo_pavimento %||% "NÃO INFORMADO",
    codigo_referencia = pista_data$codigo_referencia,
    approach_type     = pista_data$approach_type,
    cabeceiras        = process_runway_thresholds(pista_data$cabeceiras)
  )
}

#' Processa dados das cabeceiras
#' @keywords internal
process_runway_thresholds <- function(cabeceiras_json) {

  if (is.null(cabeceiras_json) || length(cabeceiras_json) != 2) {
    stop("Pista deve ter exatamente 2 cabeceiras")
  }

  lapply(cabeceiras_json, function(c) {
    # Validar dados obrigatórios da cabeceira
    required_fields <- c("designador", "latitude_thr", "longitude_thr",
                         "elevacao_thr_m", "rumo_verdadeiro_graus")

    missing_fields <- required_fields[!required_fields %in% names(c)]
    if (length(missing_fields) > 0) {
      stop(sprintf("Campos obrigatórios faltando na cabeceira %s: %s",
                   c$designador %||% "UNKNOWN",
                   paste(missing_fields, collapse = ", ")))
    }

    list(
      designador             = c$designador,
      lat                    = as.numeric(c$latitude_thr),
      lon                    = as.numeric(c$longitude_thr),
      elev_m                 = as.numeric(c$elevacao_thr_m),
      rumo                   = as.numeric(c$rumo_verdadeiro_graus),
      tecnologia_aproximacao = c$tecnologia_aproximacao %||% "Sem auxílios"
    )
  })
}
