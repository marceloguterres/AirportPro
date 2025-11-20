# R/add_to_map.R
#' Adiciona camada ao mapa com gerenciamento correto de grupos
#'
#' @param mapa Objeto leaflet existente ou NULL para criar novo
#' @param camada Objeto sf com geometria a ser adicionada
#' @param nome_camada String com nome da camada
#' @param cor Cor da camada (hex)
#' @param opacidade Opacidade da camada (0-1)
#' @param popup Lógico, incluir popup automático
#' @param grupo Nome do grupo da camada
#' @param zoom_automatico Lógico, ajustar zoom automaticamente
#' @return Objeto leaflet
#' @export
add_to_map <- function(mapa = NULL,
                       camada,
                       nome_camada = "Camada",
                       cor = "#0066cc",
                       opacidade = 0.5,
                       popup = TRUE,
                       grupo = "Camadas",
                       zoom_automatico = TRUE) {

  # Validações
  if (!inherits(camada, "sf")) {
    stop("camada deve ser um objeto sf")
  }

  if (nrow(camada) == 0) {
    warning("camada está vazia - não será adicionada ao mapa")
    return(mapa)
  }

  # Inicializar mapa se necessário
  if (is.null(mapa)) {
    mapa <- create_base_map()
    mapa$x$grupos_overlay <- character(0)
  }

  # Processar geometria
  camada_2d <- prepare_layer_geometry(camada)

  # Criar popup se solicitado
  labels <- if (popup && nrow(camada_2d) > 0) {
    create_layer_popup(camada_2d, nome_camada, cor)
  } else {
    NULL
  }

  # Adicionar camada ao mapa
  mapa <- mapa %>%
    leaflet::addPolygons(
      data = camada_2d,
      fillColor = cor,
      fillOpacity = opacidade,
      color = "white",
      weight = 2,
      popup = labels,
      label = nome_camada,
      group = grupo,
      highlightOptions = leaflet::highlightOptions(
        weight = 5,
        color = "#000",
        fillOpacity = 0.9,
        bringToFront = TRUE
      )
    )

  # Gerenciar grupos overlay
  mapa <- update_layer_controls(mapa, grupo)

  # Ajustar zoom se necessário
  if (zoom_automatico) {
    mapa <- fit_bounds_safe(mapa, camada_2d)
  }

  # Adicionar extras na primeira vez
  mapa <- add_map_extras_once(mapa)

  invisible(mapa)
}

#' Cria mapa base padrão
#' @keywords internal
create_base_map <- function() {
  leaflet::leaflet(options = leaflet::leafletOptions(minZoom = 12, maxZoom = 20)) %>%
    leaflet::addTiles(group = "OpenStreetMap") %>%
    leaflet::addProviderTiles(leaflet::providers$Esri.WorldImagery, group = "Satélite") %>%
    leaflet::addProviderTiles(leaflet::providers$CartoDB.Positron, group = "Claro")
}

#' Processa geometria da camada
#' @keywords internal
prepare_layer_geometry <- function(camada) {
  tryCatch({
    camada %>%
      sf::st_zm(drop = TRUE) %>%
      sf::st_transform(4326) %>%
      sf::st_make_valid() %>%
      sf::st_cast("POLYGON", warn = FALSE)
  }, error = function(e) {
    stop("Erro ao processar geometria da camada: ", e$message)
  })
}

#' Cria popup para camada
#' @keywords internal
create_layer_popup <- function(camada_2d, nome_camada, cor) {
  tryCatch({
    sapply(1:nrow(camada_2d), function(i) {
      row_data <- camada_2d[i, ] %>% sf::st_drop_geometry()

      info_items <- sapply(names(row_data), function(col_name) {
        valor <- row_data[[col_name]]
        valor_texto <- if (is.numeric(valor)) {
          round(valor, 3)
        } else if (is.na(valor) || is.null(valor)) {
          "—"
        } else {
          as.character(valor)
        }
        paste0("<b>", col_name, ":</b> ", valor_texto)
      })

      info_html <- paste(info_items, collapse = "<br>")

      sprintf(
        "<div style='font-family: Arial; font-size: 13px; max-width: 300px;'>
         <h4 style='margin: 0 0 8px; color: %s;'>%s</h4>
         %s
         </div>",
        cor, nome_camada, info_html
      )
    })
  }, error = function(e) {
    warning("Erro ao criar popup: ", e$message)
    NULL
  })
}

#' Atualiza controles de camadas
#' @keywords internal
update_layer_controls <- function(mapa, grupo) {
  if (is.null(mapa$x$grupos_overlay)) {
    mapa$x$grupos_overlay <- character(0)
  }

  if (!grupo %in% mapa$x$grupos_overlay) {
    mapa$x$grupos_overlay <- c(mapa$x$grupos_overlay, grupo)

    # Remover controles existentes
    if (!is.null(mapa$x$calls)) {
      mapa$x$calls <- Filter(function(call) {
        !((!is.null(call$method)) && call$method == "addLayersControl")
      }, mapa$x$calls)
    }

    # Adicionar novo controle
    mapa <- mapa %>%
      leaflet::addLayersControl(
        baseGroups = c("OpenStreetMap", "Satélite", "Claro"),
        overlayGroups = mapa$x$grupos_overlay,
        options = leaflet::layersControlOptions(collapsed = FALSE)
      )
  }

  mapa
}

#' Ajusta bounds com segurança
#' @keywords internal
fit_bounds_safe <- function(mapa, camada_2d) {
  tryCatch({
    bbox <- sf::st_bbox(camada_2d)
    mapa %>%
      leaflet::fitBounds(
        lng1 = as.numeric(bbox["xmin"]),
        lat1 = as.numeric(bbox["ymin"]),
        lng2 = as.numeric(bbox["xmax"]),
        lat2 = as.numeric(bbox["ymax"])
      )
  }, error = function(e) {
    warning("Não foi possível ajustar zoom automaticamente: ", e$message)
    mapa
  })
}

#' Adiciona mini-mapa e escala uma vez
#' @keywords internal
add_map_extras_once <- function(mapa) {
  tryCatch({
    num_calls <- if (!is.null(mapa$x$calls)) length(mapa$x$calls) else 0
    if (num_calls <= 8) {
      mapa %>%
        leaflet::addMiniMap(toggleDisplay = TRUE, position = "bottomright") %>%
        leaflet::addScaleBar(position = "bottomleft")
    } else {
      mapa
    }
  }, error = function(e) {
    warning("Não foi possível adicionar mini-mapa ou escala: ", e$message)
    mapa
  })
}
