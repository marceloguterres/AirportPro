#' Desenho textual simples da pista e da faixa (strip)
#'
#' @param apt Objeto \code{Airport}
#' @param pista_id Identificador da pista (ex: "12/30")
#' @param width_chars Largura máxima do desenho (em caracteres). Padrão: 60.
#'
#' @return Invisibly retorna \code{NULL} após imprimir no console.
#' @export
print_runway_diagram <- function(apt, pista_id, width_chars = 60) {
  if (!inherits(apt, "Airport")) {
    stop("apt deve ser da classe Airport")
  }
  p <- apt$pistas[[pista_id]]
  f <- apt$faixas[[pista_id]]
  if (is.null(p) || is.null(f)) {
    stop("Pista não encontrada: ", pista_id)
  }

  cab1 <- p$cabeceiras[[1]]
  cab2 <- p$cabeceiras[[2]]

  declared <- as.numeric(p$comprimento_m)
  ext <- as.numeric(f$extensao_antes_m)
  strip_total <- as.numeric(f$comprimento_faixa_m)

  # Escala aproximada para o desenho em caracteres (baseia-se no strip)
  strip_chars <- max(20, width_chars)
  ratio <- strip_chars / strip_total
  runway_chars <- max(10, round(declared * ratio))
  offset_chars <- max(1, round(ext * ratio))

  # Linha do strip (retângulo externo)
  strip_top <- paste0("+", strrep("-", strip_chars), "+")
  strip_mid <- paste0("|", strrep(" ", strip_chars), "|")

  # Linha da pista (retângulo interno) encaixada na linha do strip
  inner_line <- strsplit(strip_mid, "")[[1]]
  start_runway <- 1 + offset_chars  # após a barra vertical
  end_runway <- min(strip_chars, start_runway + runway_chars - 1)
  inner_line[start_runway:end_runway] <- "="
  runway_line <- paste(inner_line, collapse = "")

  # Labels de cabeceira na base
  label_line <- strrep(" ", strip_chars + 2)
  thr_left <- paste0("THR ", cab1$designador)
  thr_right <- paste0("THR ", cab2$designador)
  substr(label_line, 1, nchar(thr_left)) <- thr_left
  start_right <- nchar(label_line) - nchar(thr_right) + 1
  substr(label_line, start_right, start_right + nchar(thr_right) - 1) <- thr_right

  cat("================================================================================\n")
  cat("DESENHO DA PISTA E FAIXA —", pista_id, "\n")
  cat("================================================================================\n")
  cat("Comprimento declarado : ", declared, " m\n")
  cat("Strip (RBAC-154)      : ", strip_total, " m (+", ext, " m em cada extremidade)\n")
  cat("Largura da pista      : ", p$largura_m, " m | Strip: ", f$largura_faixa_m, " m (±", f$lateral_width_m, " m)\n")
  cat("Escala aproximada     : ", strip_chars, " caracteres ≈ ", strip_total, " m\n", sep = "")
  cat("--------------------------------------------------------------------------------\n")
  cat("    ", strip_top, "\n", sep = "")
  cat("    ", runway_line, "\n", sep = "")
  cat("    ", strip_top, "\n", sep = "")
  cat("    ", label_line, "\n", sep = "")
  cat("--------------------------------------------------------------------------------\n\n")

  invisible(NULL)
}
