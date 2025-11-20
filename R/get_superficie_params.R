# R/get_superficie_params.R
# Tudo em um arquivo: cálculo + métodos públicos + print bonito
# AirportPro — ICA 11-408 feito com carinho

# ===========================================================================
# FUNÇÃO INTERNA: calcula todas as superfícies
# ===========================================================================
#' @keywords internal
.get_superficie_params <- function(airport) {
  if (is.null(airport$pistas) || length(airport$pistas) == 0) return(list())

  params_file <- system.file("extdata", "ica_11_408_tabela_4_3_dados_v1.0.0.json",
                             package = "AirportPro")
  if (!file.exists(params_file)) {
    stop("Tabela ICA 11-408 não encontrada. Reinstale o pacote.")
  }

  ica <- jsonlite::fromJSON(params_file, simplifyVector = FALSE)$parametros
  resultado <- list()

  for (pista_id in names(airport$pistas)) {
    p <- airport$pistas[[pista_id]]
    for (cab in p$cabeceiras) {
      id <- paste0(pista_id, "_", cab$designador)
      cat_prec <- .detect_precision_category(p$approach_type, cab$tecnologia_aproximacao)
      params <- .find_ica_params(ica, p$codigo_referencia$numero, p$approach_type, cat_prec)

      if (is.null(params)) {
        stop(sprintf("ICA 11-408: sem parâmetro para %s (Code %d | %s | %s)",
                     id, p$codigo_referencia$numero, p$approach_type, cat_prec %||% "não precision"))
      }

      resultado[[id]] <- .create_superficie_result(id, p, cab, params, cat_prec)
    }
  }
  resultado
}

# ===========================================================================
# FUNÇÕES AUXILIARES
# ===========================================================================
.detect_precision_category <- function(approach_type, tech) {
  if (approach_type != "precision") return(NULL)
  if (is.null(tech) || tech %in% c("Sem auxílios", "")) return("CAT_I")
  if (grepl("CAT.?II|CAT.?III", tech, ignore.case = TRUE)) return("CAT_II_III")
  "CAT_I"
}

.find_ica_params <- function(lista, code_num, approach, cat_prec) {
  for (item in lista) {
    if (item$code_number == code_num &&
        item$approach_type == approach &&
        identical(item$cat_precision, cat_prec)) {
      return(item)
    }
  }
  NULL
}

.create_superficie_result <- function(id, pista, cab, params, cat_prec) {
  list(
    cabeceira_id = id,
    pista_id = strsplit(id, "_")[[1]][1],
    designador = cab$designador,
    code_number = pista$codigo_referencia$numero,
    code_letter = pista$codigo_referencia$letra,
    approach_type = pista$approach_type,
    cat_precision = cat_prec,
    tecnologia_aproximacao = cab$tecnologia_aproximacao %||% "Sem auxílios",
    latitude_thr = cab$lat,
    longitude_thr = cab$lon,
    elevacao_thr_m = cab$elev_m,
    rumo_verdadeiro_graus = cab$rumo,
    fonte_ica = "ICA 11-408 Tabela 4-3",
    lookup_executado_em = Sys.time(),
    descricao = sprintf("Code %d%s | %s%s → %s",
                        pista$codigo_referencia$numero,
                        pista$codigo_referencia$letra,
                        toupper(pista$approach_type),
                        if (is.null(cat_prec)) "" else paste(" ", cat_prec),
                        cab$tecnologia_aproximacao %||% "Sem auxílios"),
    superficie_aproximacao = params$superficie_aproximacao,
    superficie_decolagem = params$superficie_decolagem,
    superficie_transicao = params$superficie_transicao,
    superficie_horizontal_interna = params$superficie_horizontal_interna,
    superficie_conica = params$superficie_conica,
    superficie_horizontal_externa = params$superficie_horizontal_externa,
    superficie_aproximacao_interna = params$superficie_aproximacao_interna,
    superficie_transicao_interna = params$superficie_transicao_interna,
    superficie_pouso_interrompido = params$superficie_pouso_interrompido
  )
}

# ===========================================================================
# MÉTODOS PÚBLICOS
# ===========================================================================
#' Lista todas as cabeceiras com suas superfícies ICA 11-408 – FORMATO RELATÓRIO OFICIAL
#' @param apt Objeto Airport
#' @export
list_superficies <- function(apt) {
  if (length(apt$superficies) == 0) {
    cat("Nenhuma superfície calculada.\n")
    return(invisible(character(0)))
  }

  cat("================================================================================\n")
  cat("                  SUPERFÍCIES LIMITADORAS – ICA 11-408 TABELA 4-3               \n")
  cat("================================================================================\n\n")

  for (id in names(apt$superficies)) {
    s <- apt$superficies[[id]]

    cat("CABECEIRA           : ", s$designador, "\n")
    cat("  Pista             : ", s$pista_id, "\n")
    cat("  Código de ref.    : ", sprintf("%d%s", s$code_number, s$code_letter), "\n")
    cat("  Operação          : ", toupper(s$approach_type))
    if (!is.null(s$cat_precision)) cat(" ", s$cat_precision)
    cat(" → ", s$tecnologia_aproximacao %||% "Sem auxílios", "\n")
    cat("  THR               :  Lat ", sprintf("%.6f", s$latitude_thr),
        " | Lon ", sprintf("%.6f", s$longitude_thr),
        " | Elev ", sprintf("%.1f", s$elevacao_thr_m), " m",
        " | Rumo ", sprintf("%.1f", s$rumo_verdadeiro_graus), "°\n")
    cat("--------------------------------------------------------------------------------\n\n")
  }

  cat("TOTAL DE CABECEIRAS : ", length(apt$superficies), "\n")
  cat("FONTE               : ICA 11-408 Tabela 4-3\n")
  cat("GERADO EM           : ", format(Sys.time(), "%d/%m/%Y %H:%M"), "\n")
  cat("================================================================================\n")

  invisible(names(apt$superficies))
}

#' @export
get_superficie <- function(apt, id = NULL, pista_id = NULL, designador = NULL) {
  if (is.null(id)) {
    if (is.null(pista_id) || is.null(designador)) {
      stop("Use 'id' ou 'pista_id' + 'designador'")
    }
    id <- paste0(pista_id, "_", designador)
  }
  if (!id %in% names(apt$superficies)) {
    stop(sprintf("Cabeceira não encontrada: %s\nUse list_superficies(apt)", id))
  }
  apt$superficies[[id]]
}

