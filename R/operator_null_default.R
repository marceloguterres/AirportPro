# R/operator_null_default.R

#' Operador de valor padrão para NULL
#'
#' @param x Valor a ser testado
#' @param y Valor padrão se x for NULL
#' @return x se não for NULL, caso contrário y
#' @keywords internal
#'
#' @details
#' Este operador fornece um valor padrão quando o primeiro argumento é NULL.
#' É uma implementação do operador "null coalescing" comum em outras linguagens.
#'
#' @examples
#' # Uso interno apenas
#' valor <- NULL
#' resultado <- valor %||% "padrão"  # "padrão"
#'
#' valor <- "existe"
#' resultado <- valor %||% "padrão"  # "existe"
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
