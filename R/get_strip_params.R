# R/get_strip_params.R
#' Calcula faixas de pista com metadados da consulta RBAC-154
#'
#' @param airport Objeto Airport
#' @return Lista com parâmetros + metadados para validação
#' @keywords internal
.get_strip_params <- function(airport) {
  if (is.null(airport$pistas) || length(airport$pistas) == 0) {
    return(list())
  }

  # Carregar parâmetros RBAC-154
  params_file <- system.file("extdata", "rbac154_strip_params.json", package = "AirportPro")
  if (!file.exists(params_file)) {
    stop("Arquivo RBAC-154 não encontrado: ", params_file)
  }

  rbac <- jsonlite::fromJSON(params_file, simplifyVector = FALSE)
  resultado <- list()

  for (pista_id in names(airport$pistas)) {
    p <- airport$pistas[[pista_id]]

    code_number <- p$codigo_referencia$numero
    approach_type <- p$approach_type

    # Validar dados obrigatórios
    if (is.null(code_number) || is.null(approach_type)) {
      stop(sprintf(
        "Faltam dados em pista %s: code=%s, approach_type=%s",
        pista_id,
        code_number %||% "NULL",
        approach_type %||% "NULL"
      ))
    }

    # Buscar parâmetros na tabela RBAC-154
    param_encontrado <- find_rbac_params(rbac$parametros, code_number, approach_type)

    if (is.null(param_encontrado)) {
      stop(sprintf(
        "RBAC-154: combinação inválida → Code %d + %s (pista %s)",
        code_number, approach_type, pista_id
      ))
    }

    # Montar resultado com metadados
    resultado[[pista_id]] <- create_strip_result(pista_id, p, param_encontrado)
  }

  resultado
}

#' Busca parâmetros RBAC-154 por código e tipo de aproximação
#' @keywords internal
find_rbac_params <- function(parametros, code_number, approach_type) {
  for (item in parametros) {
    if (item$code_number == code_number && item$approach_type == approach_type) {
      return(item)
    }
  }
  NULL
}

#' Cria resultado estruturado para uma pista
#' @keywords internal
create_strip_result <- function(pista_id, pista_data, params) {
  list(
    # Metadados para validação
    pista_id = pista_id,
    code_number = pista_data$codigo_referencia$numero,
    code_letter = pista_data$codigo_referencia$letra,
    approach_type = pista_data$approach_type,
    fonte_rbac = "RBAC-154 §154.207(c)",

    # Parâmetros RBAC-154
    lateral_width_m = params$lateral_width_m,
    longitudinal_ext_m = params$longitudinal_ext_m,

    # Dimensões finais da faixa
    largura_faixa_m = 2 * params$lateral_width_m,
    comprimento_faixa_m = pista_data$comprimento_m + 2 * params$longitudinal_ext_m,

    # Para desenho geométrico
    extensao_antes_m = params$longitudinal_ext_m,
    extensao_apos_m = params$longitudinal_ext_m,

    # Descrição para print
    descricao = sprintf(
      "Code %d%s | %s → ±%d m lateral | +%d m longitudinal",
      pista_data$codigo_referencia$numero,
      pista_data$codigo_referencia$letra,
      toupper(pista_data$approach_type),
      params$lateral_width_m,
      params$longitudinal_ext_m
    )
  )
}
