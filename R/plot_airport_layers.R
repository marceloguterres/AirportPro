# R/plot_airport_layers.R
#' Plota todas as camadas de um aeroporto de forma otimizada
#'
#' @param airport Objeto Airport
#' @param incluir_faixas Lógico. Incluir faixas? (padrão: TRUE)
#' @param cores_pistas Vetor de cores para pistas ou NULL para automático
#' @param cores_faixas Vetor de cores para faixas ou NULL para automático
#' @param opacidade_pistas Opacidade das pistas (0-1)
#' @param opacidade_faixas Opacidade das faixas (0-1)
#'
#' @return Objeto leaflet
#' @export
plot_airport_layers <- function(airport,
                                incluir_faixas = TRUE,
                                cores_pistas = NULL,
                                cores_faixas = NULL,
                                opacidade_pistas = 0.9,
                                opacidade_faixas = 0.4) {

  # Validações
  if (!inherits(airport, "Airport")) {
    stop("airport deve ser um objeto da classe Airport")
  }

  pistas_ids <- names(airport$pistas)
  if (length(pistas_ids) == 0) {
    stop("Aeroporto não possui pistas válidas")
  }

  # Gerar geometrias das pistas
  geometrias_pistas <- lapply(pistas_ids, function(id) {
    runway_to_sf(airport, id, proj = FALSE)
  })

  # Definir cores das pistas
  cores_pistas <- cores_pistas %||% c("#2E86AB", "#A23B72", "#F18F01", "#C73E1D")[1:length(pistas_ids)]
  cores_pistas <- rep(cores_pistas, length.out = length(pistas_ids))

  # Gerar geometrias das faixas se solicitado
  geometrias_faixas <- if (incluir_faixas) {
    lapply(pistas_ids, function(id) {
      runway_strip_to_sf(airport, id, crs_final = 4326)
    })
  } else {
    list()
  }

  # Definir cores das faixas
  cores_faixas <- cores_faixas %||% c("#85C1E9", "#F8C471", "#82E0AA", "#F1948A")[1:length(pistas_ids)]
  cores_faixas <- rep(cores_faixas, length.out = length(pistas_ids))

  # Calcular bounding box total
  todas_geom <- c(geometrias_pistas, geometrias_faixas)
  bboxes <- lapply(todas_geom, sf::st_bbox)

  bbox_total <- list(
    xmin = min(sapply(bboxes, function(x) x["xmin"])),
    ymin = min(sapply(bboxes, function(x) x["ymin"])),
    xmax = max(sapply(bboxes, function(x) x["xmax"])),
    ymax = max(sapply(bboxes, function(x) x["ymax"]))
  )

  # Inicializar mapa base - SEM PIPE
  mapa <- leaflet::leaflet(options = leaflet::leafletOptions(minZoom = 10, maxZoom = 22))
  mapa <- leaflet::addTiles(mapa, group = "OpenStreetMap")
  mapa <- leaflet::addProviderTiles(mapa, leaflet::providers$Esri.WorldImagery, group = "Satélite")
  mapa <- leaflet::addProviderTiles(mapa, leaflet::providers$CartoDB.Positron, group = "Claro")
  mapa <- leaflet::fitBounds(
    map = mapa,
    lng1 = bbox_total$xmin,
    lat1 = bbox_total$ymin,
    lng2 = bbox_total$xmax,
    lat2 = bbox_total$ymax
  )

  # Adicionar faixas (fundo) - SEM PIPE
  if (incluir_faixas) {
    for (i in seq_along(geometrias_faixas)) {
      faixa <- geometrias_faixas[[i]]

      # Preparar geometria 2D
      faixa_2d <- sf::st_zm(faixa, drop = TRUE)
      faixa_2d <- sf::st_make_valid(faixa_2d)

      popup_faixa <- create_strip_popup(faixa, cores_faixas[i], pistas_ids[i])

      mapa <- leaflet::addPolygons(
        map = mapa,
        data = faixa_2d,
        fillColor = cores_faixas[i],
        fillOpacity = opacidade_faixas,
        color = "white",
        weight = 1,
        popup = popup_faixa,
        label = paste("Faixa", pistas_ids[i]),
        group = "Faixas",
        highlightOptions = leaflet::highlightOptions(
          weight = 3,
          color = "#000",
          fillOpacity = 0.7,
          bringToFront = TRUE
        )
      )
    }
  }

  # Adicionar pistas (primeiro plano) - SEM PIPE
  for (i in seq_along(geometrias_pistas)) {
    pista <- geometrias_pistas[[i]]

    # Preparar geometria 2D
    pista_2d <- sf::st_zm(pista, drop = TRUE)
    pista_2d <- sf::st_make_valid(pista_2d)

    popup_pista <- create_runway_popup(pista, cores_pistas[i])

    mapa <- leaflet::addPolygons(
      map = mapa,
      data = pista_2d,
      fillColor = cores_pistas[i],
      fillOpacity = opacidade_pistas,
      color = "white",
      weight = 3,
      popup = popup_pista,
      label = paste("Pista", pistas_ids[i]),
      group = "Pistas",
      highlightOptions = leaflet::highlightOptions(
        weight = 5,
        color = "#FFD700",
        fillOpacity = 1.0,
        bringToFront = TRUE
      )
    )
  }

  # Finalizar mapa - SEM PIPE
  grupos_overlay <- if (incluir_faixas) c("Faixas", "Pistas") else "Pistas"

  mapa <- leaflet::addLayersControl(
    map = mapa,
    baseGroups = c("OpenStreetMap", "Satélite", "Claro"),
    overlayGroups = grupos_overlay,
    options = leaflet::layersControlOptions(collapsed = FALSE)
  )

  mapa <- leaflet::addScaleBar(mapa, position = "bottomleft")
  mapa <- leaflet::addMiniMap(mapa, toggleDisplay = TRUE, position = "bottomright")

  return(mapa)
}

#' Cria popup para faixa de pista
#' @keywords internal
create_strip_popup <- function(faixa, cor, pista_id) {
  sprintf(
    "<div style='font-family: Arial; max-width: 250px; padding: 10px;'>
     <h4 style='margin: 0 0 8px 0; color: %s;'>🛫 Faixa %s</h4>
     <table style='width: 100%%; font-size: 12px; border-collapse: collapse;'>
       <tr><td style='padding: 2px;'><b>Aeroporto:</b></td><td style='padding: 2px;'>%s</td></tr>
       <tr><td style='padding: 2px;'><b>Código Ref.:</b></td><td style='padding: 2px;'>%s</td></tr>
       <tr><td style='padding: 2px;'><b>Aproximação:</b></td><td style='padding: 2px;'>%s</td></tr>
       <tr><td style='padding: 2px;'><b>Largura Faixa:</b></td><td style='padding: 2px;'>%.0f m</td></tr>
       <tr><td style='padding: 2px;'><b>Comprimento:</b></td><td style='padding: 2px;'>%.0f m</td></tr>
       <tr><td style='padding: 2px;'><b>Área:</b></td><td style='padding: 2px;'>%.1f m²</td></tr>
       <tr><td style='padding: 2px;'><b>Norma:</b></td><td style='padding: 2px;'>%s</td></tr>
     </table>
     </div>",
    cor, pista_id,
    as.character(faixa$aeroporto_icao),
    as.character(faixa$codigo_referencia),
    as.character(faixa$approach_type),
    as.numeric(faixa$largura_faixa_m),
    as.numeric(faixa$comprimento_faixa_m),
    as.numeric(faixa$area_faixa_m2),
    as.character(faixa$norma)
  )
}

#' Cria popup para pista
#' @keywords internal
create_runway_popup <- function(pista, cor) {
  sprintf(
    "<div style='font-family: Arial; max-width: 220px; padding: 8px;'>
     <h4 style='margin: 0 0 8px 0; color: %s;'>🛩️ Pista %s</h4>
     <table style='width: 100%%; font-size: 13px; border-collapse: collapse;'>
       <tr><td style='padding: 2px;'><b>Comprimento:</b></td><td style='padding: 2px;'>%.1f m</td></tr>
       <tr><td style='padding: 2px;'><b>Largura:</b></td><td style='padding: 2px;'>%.0f m</td></tr>
       <tr><td style='padding: 2px;'><b>Elev. Thr A:</b></td><td style='padding: 2px;'>%.2f m</td></tr>
       <tr><td style='padding: 2px;'><b>Elev. Thr B:</b></td><td style='padding: 2px;'>%.2f m</td></tr>
       <tr><td style='padding: 2px;'><b>Declive:</b></td><td style='padding: 2px;'>%.3f %%</td></tr>
       <tr><td style='padding: 2px;'><b>Diferença:</b></td><td style='padding: 2px;'>%.1f m</td></tr>
     </table>
     </div>",
    cor,
    as.character(pista$pista_id),
    as.numeric(pista$comprimento_m),
    as.numeric(pista$largura_m),
    as.numeric(pista$elev_thr_a),
    as.numeric(pista$elev_thr_b),
    as.numeric(pista$declive_percent),
    as.numeric(pista$diferenca_m %||% 0)
  )
}
