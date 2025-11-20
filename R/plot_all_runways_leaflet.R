# R/plot_all_runways_leaflet.R
#' Mapa Interativo Avançado de Pistas (Leaflet)
#'
#' Cria um mapa web interativo com múltiplas camadas de fundo, controle de visibilidade,
#' popup detalhado, highlight ao passar o mouse, mini-mapa e escala.
#'
#' @param lista_pistas Lista de objetos sf gerados por runway_to_sf
#' @param cores_personalizadas Vetor de cores hex (opcional). Se NULL, usa paleta automática.
#'
#' @return Objeto leaflet (impresso automaticamente)
#' @export
plot_all_runways_leaflet <- function(lista_pistas, cores_personalizadas = NULL) {

  # Validações
  if (!is.list(lista_pistas) || length(lista_pistas) == 0) {
    stop("lista_pistas deve ser uma lista não vazia de objetos sf")
  }
  if (!all(sapply(lista_pistas, inherits, "sf"))) {
    stop("Todos os itens de lista_pistas devem ser objetos sf")
  }

  # Preparação das geometrias
  pistas_2d <- lapply(lista_pistas, sf::st_zm)
  n_pistas <- length(pistas_2d)

  # Definir cores (paleta hardcoded)
  cores <- if (is.null(cores_personalizadas)) {
    if (n_pistas <= 8) {
      c("#66C2A5", "#FC8D62", "#8DA0CB", "#E78AC3",
        "#A6D854", "#FFD92F", "#E5C494", "#B3B3B3")[1:n_pistas]
    } else {
      rainbow(n_pistas)
    }
  } else {
    rep(cores_personalizadas, length.out = n_pistas)
  }

  # Extrair nomes das pistas
  nomes_pistas <- sapply(pistas_2d, function(x) x$pista_id[1])

  # Criar mapa base - SEM PIPE
  mapa <- leaflet::leaflet()
  mapa <- leaflet::addTiles(mapa, group = "OpenStreetMap")
  mapa <- leaflet::addProviderTiles(mapa, leaflet::providers$Esri.WorldImagery, group = "Satélite")
  mapa <- leaflet::addProviderTiles(mapa, leaflet::providers$CartoDB.Positron, group = "Claro")

  # Adicionar cada pista
  for (i in seq_len(n_pistas)) {
    pista <- pistas_2d[[i]]

    popup_content <- create_runway_popup_simple(pista, cores[i])

    mapa <- leaflet::addPolygons(
      map = mapa,
      data = pista,
      fillColor = cores[i],
      fillOpacity = 0.8,
      color = "white",
      weight = 2,
      popup = popup_content,
      label = paste("Pista", pista$pista_id[1]),
      group = paste("Pista", pista$pista_id[1]),
      highlightOptions = leaflet::highlightOptions(
        weight = 5,
        fillOpacity = 1,
        bringToFront = TRUE
      )
    )
  }

  # Calcular bounds e finalizar mapa - SEM PIPE
  bounds_matrix <- do.call(rbind, lapply(pistas_2d, sf::st_bbox))

  mapa <- leaflet::fitBounds(
    map = mapa,
    lng1 = min(bounds_matrix[, "xmin"]),
    lat1 = min(bounds_matrix[, "ymin"]),
    lng2 = max(bounds_matrix[, "xmax"]),
    lat2 = max(bounds_matrix[, "ymax"])
  )

  mapa <- leaflet::addLayersControl(
    map = mapa,
    baseGroups = c("OpenStreetMap", "Satélite", "Claro"),
    overlayGroups = paste("Pista", nomes_pistas),
    options = leaflet::layersControlOptions(collapsed = FALSE)
  )

  mapa <- leaflet::addScaleBar(mapa, position = "bottomleft")
  mapa <- leaflet::addMiniMap(mapa, toggleDisplay = TRUE, position = "bottomright")

  return(mapa)
}

#' Cria popup HTML simples para pista
#' @keywords internal
create_runway_popup_simple <- function(pista, cor) {
  sprintf(
    "<div style='font-family: Arial; max-width: 220px; padding: 8px;'>
     <h4 style='margin: 0 0 8px 0; color: %s;'>Pista %s</h4>
     <table style='width: 100%%; font-size: 13px; border-collapse: collapse;'>
       <tr><td style='padding: 2px;'><b>Comprimento:</b></td><td style='padding: 2px;'>%.1f m</td></tr>
       <tr><td style='padding: 2px;'><b>Largura:</b></td><td style='padding: 2px;'>%.0f m</td></tr>
       <tr><td style='padding: 2px;'><b>Elev. Thr A:</b></td><td style='padding: 2px;'>%.2f m</td></tr>
       <tr><td style='padding: 2px;'><b>Elev. Thr B:</b></td><td style='padding: 2px;'>%.2f m</td></tr>
       <tr><td style='padding: 2px;'><b>Declive:</b></td><td style='padding: 2px;'>%.3f %%</td></tr>
     </table>
     </div>",
    cor,
    pista$pista_id[1],
    as.numeric(pista$comprimento_m),
    as.numeric(pista$largura_m),
    as.numeric(pista$elev_thr_a),
    as.numeric(pista$elev_thr_b),
    as.numeric(pista$declive_percent)
  )
}
