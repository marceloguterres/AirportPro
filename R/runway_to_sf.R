# R/runway_to_sf.R
#' Converte dados de pista em polígono sf georreferenciado 3D
#'
#' @param airport Objeto da classe Airport contendo dados processados do aeroporto
#' @param pista_id String identificando a pista (ex: "14/32", "09/27", "11/29")
#' @param proj Lógico. Se TRUE, retorna em projeção UTM (metros). Se FALSE, retorna em WGS84
#' @param debug Lógico. Se TRUE, imprime diagnóstico sobre diferenças entre comprimento declarado vs calculado
#' @param distance Método de cálculo de comprimento entre cabeceiras: "utm" (padrão),
#'   "haversine" ou "both" (imprime/computa as duas distâncias)
#'
#' @return Objeto sf (Simple Features) contendo polígono POLYGON Z com metadados
#'
#' @examples
#' \dontrun{
#' sbpa <- Airport$new("inst/extdata/ad_sbpa.json")
#' pista_web <- runway_to_sf(sbpa, "11/29", proj = FALSE)
#' pista_utm <- runway_to_sf(sbpa, "11/29", proj = TRUE)
#' pista_debug <- runway_to_sf(sbpa, "11/29", debug = TRUE)
#' }
#'
#' @export
runway_to_sf <- function(airport, pista_id, proj = FALSE, debug = FALSE,
                         distance = c("utm", "haversine", "both")) {

  distance <- match.arg(distance)

  # Validações
  if (!inherits(airport, "Airport")) {
    stop("airport deve ser da classe Airport")
  }

  p <- airport$pistas[[pista_id]]
  if (is.null(p)) {
    stop("Pista não encontrada: ", pista_id)
  }

  # Extrair dados das cabeceiras
  cab1 <- p$cabeceiras[[1]]
  cab2 <- p$cabeceiras[[2]]

  # Converter para UTM e calcular geometria
  utm_data <- convert_runways_to_utm(cab1, cab2)

  # Calcular distâncias e validar
  distances <- calculate_runway_distances(
    utm_data,
    comprimento_declarado = p$comprimento_m,
    pista_id = pista_id,
    debug = debug,
    distance = distance,
    cab1 = cab1,
    cab2 = cab2
  )

  # Construir geometria da pista
  runway_geom <- build_runway_geometry(utm_data, p$largura_m, cab1$elev_m, cab2$elev_m)

  # Converter para sistema final
  final_geom <- transform_runway_geometry(runway_geom, utm_data$epsg_utm, proj)

  # Criar metadados
  metadata <- create_runway_metadata(pista_id, p, cab1, cab2, distances)

  sf::st_sf(metadata, geometry = final_geom)
}

#' Converte cabeceiras para coordenadas UTM
#' @keywords internal
convert_runways_to_utm <- function(cab1, cab2) {
  pts <- data.frame(
    lon = c(cab1$lon, cab2$lon),
    lat = c(cab1$lat, cab2$lat)
  )

  pts_sf <- sf::st_as_sf(pts, coords = c("lon", "lat"), crs = 4326)

  # Determinar zona UTM
  mean_lon <- mean(pts$lon)
  mean_lat <- mean(pts$lat)
  zone <- floor((mean_lon + 180) / 6) + 1
  epsg_utm <- if (mean_lat < 0) 32700 + zone else 32600 + zone

  pts_utm <- sf::st_transform(pts_sf, epsg_utm)
  xy <- sf::st_coordinates(pts_utm)

  list(
    A = xy[1, ],  # Cabeceira 1
    B = xy[2, ],  # Cabeceira 2
    epsg_utm = epsg_utm
  )
}

#' Calcula distâncias e valida comprimentos
#' @keywords internal
calculate_runway_distances <- function(utm_data,
                                       comprimento_declarado,
                                       pista_id,
                                       debug,
                                       distance,
                                       cab1,
                                       cab2) {
  vetor_pista <- utm_data$B - utm_data$A
  distancia_utm <- sqrt(sum(vetor_pista^2))

  if (distancia_utm == 0) {
    stop("Cabeceiras coincidentes para pista: ", pista_id)
  }

  distancia_haversine <- if (distance %in% c("haversine", "both")) {
    geosphere::distHaversine(
      c(cab1$lon, cab1$lat),
      c(cab2$lon, cab2$lat)
    )
  } else {
    NA_real_
  }

  diferenca_utm <- if (!is.null(comprimento_declarado)) {
    abs(distancia_utm - comprimento_declarado)
  } else {
    NA_real_
  }

  diferenca_haversine <- if (!is.null(comprimento_declarado) && !is.na(distancia_haversine)) {
    abs(distancia_haversine - comprimento_declarado)
  } else {
    NA_real_
  }

  # Debug output
  if (debug && !is.null(comprimento_declarado)) {
    print_runway_debug(
      pista_id = pista_id,
      declarado = comprimento_declarado,
      distancia_utm = distancia_utm,
      diferenca_utm = diferenca_utm,
      distancia_haversine = distancia_haversine,
      diferenca_haversine = diferenca_haversine
    )
  }

  list(
    vetor_pista = vetor_pista,
    distancia_utm = distancia_utm,
    distancia_haversine = distancia_haversine,
    diferenca_utm = diferenca_utm,
    diferenca_haversine = diferenca_haversine
  )
}

#' Imprime diagnóstico da pista
#' @keywords internal
print_runway_debug <- function(pista_id,
                               declarado,
                               distancia_utm,
                               diferenca_utm,
                               distancia_haversine = NA_real_,
                               diferenca_haversine = NA_real_) {
  cat("=== Pista", pista_id, "===\n")
  cat("  Comprimento declarado:", declarado, "m\n")
  cat("  Distância UTM (cabeceiras):", round(distancia_utm, 1), "m\n")
  if (!is.na(distancia_haversine)) {
    cat("  Distância geodésica (haversine):", round(distancia_haversine, 1), "m\n")
  }
  cat("  Diferença UTM vs declarado:", round(diferenca_utm, 1), "m\n")
  if (!is.na(diferenca_haversine)) {
    cat("  Diferença haversine vs declarado:", round(diferenca_haversine, 1), "m\n")
  }

  max_diff <- max(diferenca_utm, diferenca_haversine, na.rm = TRUE)

  if (!is.finite(max_diff)) {
    cat("\n")
    return(invisible())
  }

  if (max_diff > 50) {
    cat("  ⚠️  ATENÇÃO: Diferença significativa (>50m)!\n")
  } else if (max_diff > 10) {
    cat("  ℹ️  Info: Pequena diferença (>10m)\n")
  } else {
    cat("  ✓ Diferença aceitável (<10m)\n")
  }
  cat("\n")
}

#' Constrói geometria 3D da pista
#' @keywords internal
build_runway_geometry <- function(utm_data, largura_m, elev_cab1, elev_cab2) {
  # Calcular vetores direcionais
  distancia <- sqrt(sum((utm_data$B - utm_data$A)^2))
  vetor_unitario <- (utm_data$B - utm_data$A) / distancia
  vetor_perp <- c(-vetor_unitario[2], vetor_unitario[1])
  half_width <- largura_m / 2

  # 4 vértices do retângulo
  coords_utm <- rbind(
    utm_data$A + vetor_perp * half_width,  # A + largura
    utm_data$A - vetor_perp * half_width,  # A - largura
    utm_data$B - vetor_perp * half_width,  # B - largura
    utm_data$B + vetor_perp * half_width,  # B + largura
    utm_data$A + vetor_perp * half_width   # Fechar polígono
  )

  # Elevações por cabeceira
  elevs <- c(elev_cab1, elev_cab1, elev_cab2, elev_cab2, elev_cab1)

  list(
    coords_utm = coords_utm,
    elevations = elevs,
    epsg_utm = utm_data$epsg_utm
  )
}

#' Converte geometria para sistema de coordenadas final
#' @keywords internal
transform_runway_geometry <- function(runway_geom, epsg_utm, proj) {
  coords_3d <- cbind(runway_geom$coords_utm, Z = runway_geom$elevations)

  # Criar polígono UTM
  polygon_utm <- sf::st_polygon(list(coords_3d))
  sfc_utm <- sf::st_sfc(polygon_utm, crs = epsg_utm, dim = "XYZ")

  # Converter para WGS84 se necessário
  if (!proj) {
    temp_sf <- sf::st_as_sf(
      data.frame(x = runway_geom$coords_utm[,1], y = runway_geom$coords_utm[,2]),
      coords = c("x","y"),
      crs = epsg_utm
    )
    coords_ll <- sf::st_coordinates(sf::st_transform(temp_sf, 4326))
    coords_3d_ll <- cbind(coords_ll, Z = runway_geom$elevations)
    polygon_ll <- sf::st_polygon(list(coords_3d_ll))
    sf::st_sfc(polygon_ll, crs = 4326, dim = "XYZ")
  } else {
    sfc_utm
  }
}

#' Cria metadados da pista
#' @keywords internal
create_runway_metadata <- function(pista_id, pista_data, cab1, cab2, distances) {
  data.frame(
    pista_id = pista_id,
    largura_m = pista_data$largura_m,
    elev_thr_a = cab1$elev_m,
    elev_thr_b = cab2$elev_m,
    comprimento_m = round(distances$distancia_utm, 1),
    comprimento_haversine_m = if (!is.na(distances$distancia_haversine)) {
      round(distances$distancia_haversine, 1)
    } else {
      NA_real_
    },
    comprimento_declarado_m = pista_data$comprimento_m %||% NA,
    diferenca_m = if (!is.na(distances$diferenca_utm)) round(distances$diferenca_utm, 1) else NA,
    diferenca_haversine_m = if (!is.na(distances$diferenca_haversine)) {
      round(distances$diferenca_haversine, 1)
    } else {
      NA_real_
    },
    declive_percent = round((cab2$elev_m - cab1$elev_m) / distances$distancia_utm * 100, 4),
    stringsAsFactors = FALSE
  )
}
