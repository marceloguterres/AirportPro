# R/validate_airport_json.R
#' Valida estrutura básica de JSON de aeroporto
#'
#' @param json Lista JSON carregada
#' @return Logical indicando se estrutura é válida
#' @keywords internal
.validate_airport_json <- function(json) {

  # Validação básica de tipo
  if (!is.list(json)) {
    return(FALSE)
  }

  # Verificar seção aeroporto
  if (!"aeroporto" %in% names(json)) {
    return(FALSE)
  }

  aero <- json$aeroporto
  if (!is.list(aero)) {
    return(FALSE)
  }

  # Campos obrigatórios (flexível para geodesia/referencia)
  required_fields <- c("icao", "pistas")
  has_required <- all(required_fields %in% names(aero))

  # Verificar se tem geodesia OU referencia
  has_geo <- any(c("geodesia", "referencia") %in% names(aero))

  return(has_required && has_geo)
}
