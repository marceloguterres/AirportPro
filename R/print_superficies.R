#' Relatório completo ICA 11-408 – TODOS OS TEXTOS EM PRETO
#' @export
print.superficies <- function(apt) {
  if (length(apt$superficies) == 0) {
    cat("Nenhuma superfície calculada.\n")
    return(invisible(apt))
  }

  cat("================================================================================\n")
  cat("               SUPERFÍCIES DE PROTEÇÃO – ICA 11-408 TABELA 4-3                 \n")
  cat("================================================================================\n")
  cat("Aeroporto: ", apt$icao, " – ", apt$nome, "\n")
  cat("Gerado em: ", format(Sys.time(), "%d/%m/%Y %H:%M"), "\n")
  cat("================================================================================\n\n")

  for (id in names(apt$superficies)) {
    s <- apt$superficies[[id]]

    cat("CABECEIRA: ", s$designador,
        " | Pista: ", s$pista_id,
        " | Código de Referência: ", sprintf("%d%s", s$code_number, s$code_letter), "\n")

    cat("Operação: ", toupper(s$approach_type))
    if (!is.null(s$cat_precision)) cat(" ", s$cat_precision)
    cat(" → ", s$tecnologia_aproximacao %||% "Sem auxílios", "\n")

    cat("THR: Lat ", sprintf("%.6f", s$latitude_thr),
        " | Lon ", sprintf("%.6f", s$longitude_thr),
        " | Elev ", s$elevacao_thr_m, "m",
        " | Rumo ", s$rumo_verdadeiro_graus, "°\n")

    cat("--------------------------------------------------------------------------------\n")

    # Aproximação
    a <- s$superficie_aproximacao
    cat("SUPERFÍCIE DE APROXIMAÇÃO\n")
    cat("  1ª seção : ", a$comprimento_m, "m × ", a$largura_borda_interna_m, "m (gradiente ", a$gradiente_pct, "%)\n")
    if (!is.null(a$segunda_secao)) {
      cat("  2ª seção : ", a$segunda_secao$comprimento_m, "m (gradiente ", a$segunda_secao$gradiente_pct, "%)\n")
    }
    cat("  Horizontal: ", a$secao_horizontal$comprimento_m, "m\n\n")

    # Decolagem
    d <- s$superficie_decolagem
    cat("SUPERFÍCIE DE DECOLAGEM\n")
    cat("  15.000 m | ", d$gradiente_pct, "% → largura final ", d$largura_final_m, "m\n\n")

    # Outras
    cat("OUTRAS SUPERFÍCIES\n")
    cat("  Transição:           ", s$superficie_transicao$gradiente_pct, "%\n")
    cat("  Horizontal Interna:  45 m (raio 4.000 m)\n")
    cat("  Cônica:              100 m (5%)\n")
    cat("  Horizontal Externa: 145 m (raio 20.000 m)\n")

    # CAT II/III
    if (!is.null(s$cat_precision) && s$cat_precision == "CAT_II_III") {
      cat("\nSUPERFÍCIES INTERNAS (CAT II/III)\n")
      cat("   Aproximação interna: 900 m × 120 m (2%)\n")
      cat("   Transição interna:   33,3%\n")
      cat("   Pouso interrompido:  120 m (offset 1.800 m) → 3,33%\n")
    }

    cat("\nFonte: ", s$fonte_ica, "\n")
    cat("================================================================================\n\n")
  }

  cat("TODAS AS SUPERFÍCIES CALCULADAS COM SUCESSO!\n")
  cat("Use apt$get_superficie(\"11/29_11\") para dados brutos.\n")
  invisible(apt)
}
