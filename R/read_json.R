# R/read_json.R
# Carregamento de pacotes
library(jsonlite)

#' Leitor seguro de JSON
#'
#' @param x Caminho para arquivo JSON ou lista já carregada
#' @return Lista com dados JSON carregados
#' @keywords internal
#'
#' @details
#' Esta função carrega dados JSON de forma segura, aceitando tanto
#' caminhos de arquivo quanto listas já carregadas. Inclui validações
#' básicas e mensagens de erro descritivas.
#'
#' @examples
#' # Uso interno apenas
#' dados <- .read_json("caminho/para/arquivo.json")
#' dados <- .read_json(lista_existente)
.read_json <- function(x) {

  # Validação de entrada
  if (is.null(x)) {
    stop("Entrada não pode ser NULL")
  }

  # Caso 1: Caminho de arquivo
  if (is.character(x)) {
    if (length(x) != 1) {
      stop("Forneça apenas um caminho de arquivo")
    }

    if (!file.exists(x)) {
      stop("Arquivo não encontrado: ", x)
    }

    if (!grepl("\\.json$", x, ignore.case = TRUE)) {
      warning("Arquivo não tem extensão .json: ", x)
    }

    tryCatch({
      result <- read_json(x, simplifyVector = FALSE)
      return(result)
    }, error = function(e) {
      stop("Erro ao ler arquivo JSON '", x, "': ", e$message)
    })
  }

  # Caso 2: Lista já carregada
  if (is.list(x)) {
    return(x)
  }

  # Caso 3: Tipo inválido
  stop("Entrada deve ser caminho de arquivo válido ou lista JSON. ",
       "Tipo recebido: ", class(x)[1])
}

