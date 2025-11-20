# R/runway_strip_to_sf.R
#' Converte faixa de pista em polígono 3D (XYZ) com cota máxima da pista
#'
#' A faixa de pista é plana na cota máxima das cabeceiras (RBAC-154).
#' Retorna sf com geometria XYZ para uso em GIS 3D.
#'
#' @param airport Objeto Airport
#' @param pista_id Character. Ex: "11/29"
#' @param crs_final CRS de saída (ex: 4326 ou 32722)
#' @return sf com polígono 3D (XYZ) + cota máxima
#' @export
#'
#' @examples
#' \dontrun{
#' sbpa <- Airport$new(system.file("extdata", "ad_sbpa.json", package = "AirportPro"))
#' faixa_3d <- runway_strip_to_sf(sbpa, "11/29", crs_final = 4326)
#' plot(faixa_3d$geometry, axes = TRUE)
#' }
runway_strip_to_sf <- function(airport, pista_id, crs_final = 4326) {

  # Validações
  stopifnot(inherits(airport, "Airport"))
  stopifnot(pista_id %in% names(airport$pistas))

  p <- airport$pistas[[pista_id]]
  f <- airport$faixas[[pista_id]]

  # Extrair dados das cabeceiras
  cab1 <- p$cabeceiras[[1]]
  cab2 <- p$cabeceiras[[2]]

  # Cota máxima conforme RBAC-154
  z_max <- max(cab1$elev_m, cab2$elev_m)

  # Converter cabeceiras para UTM para cálculos métricos
  utm_coords <- convert_to_utm(cab1, cab2)

  # Calcular geometria da faixa em UTM
  strip_coords_utm <- calculate_strip_geometry(
    utm_coords$thr1,
    utm_coords$thr2,
    f$longitudinal_ext_m,
    f$largura_faixa_m
  )

  # Converter de volta para WGS84 e criar geometria 3D
  strip_geom <- create_strip_geometry_3d(
    strip_coords_utm,
    utm_coords$epsg_utm,
    z_max,
    crs_final
  )

  # Criar dataframe com metadados
  metadata <- create_strip_metadata(airport, pista_id, p, f, z_max)

  sf::st_sf(metadata, geometry = strip_geom)
}

#' Converte cabeceiras para coordenadas UTM
#' @keywords internal
convert_to_utm <- function(cab1, cab2) {
  # Criar pontos das cabeceiras
  pts <- data.frame(
    lon = c(cab1$lon, cab2$lon),
    lat = c(cab1$lat, cab2$lat)
  )

  pts_sf <- sf::st_as_sf(pts, coords = c("lon", "lat"), crs = 4326)

  # Determinar zona UTM automaticamente
  mean_lon <- mean(pts$lon)
  mean_lat <- mean(pts$lat)
  zone <- floor((mean_lon + 180) / 6) + 1
  epsg_utm <- if (mean_lat < 0) 32700 + zone else 32600 + zone

  # Converter para UTM
  pts_utm <- sf::st_transform(pts_sf, epsg_utm)
  xy_utm <- sf::st_coordinates(pts_utm)

  list(
    thr1 = xy_utm[1, ],
    thr2 = xy_utm[2, ],
    epsg_utm = epsg_utm
  )
}

#' Calcula geometria da faixa em coordenadas UTM
#' @keywords internal
calculate_strip_geometry <- function(thr1_utm, thr2_utm, ext_long, largura_total) {
  # Calcular vetores direcionais
  vec_utm <- thr2_utm - thr1_utm
  len_utm <- sqrt(sum(vec_utm^2))

  if (len_utm == 0) stop("Cabeceiras coincidentes")

  along_utm <- vec_utm / len_utm
  perp_utm <- c(-along_utm[2], along_utm[1])

  # Extensões para desenho geométrico
  ext_lat <- largura_total / 2  # Metade da largura total

  # 4 vértices da faixa (sentido anti-horário)
  p1_utm <- thr1_utm - along_utm * ext_long + perp_utm * ext_lat
  p2_utm <- thr1_utm - along_utm * ext_long - perp_utm * ext_lat
  p3_utm <- thr2_utm + along_utm * ext_long - perp_utm * ext_lat
  p4_utm <- thr2_utm + along_utm * ext_long + perp_utm * ext_lat

  rbind(p1_utm, p2_utm, p3_utm, p4_utm, p1_utm)
}

#' Cria geometria 3D da faixa
#' @keywords internal
create_strip_geometry_3d <- function(coords_utm_2d, epsg_utm, z_max, crs_final) {
  # Converter pontos UTM para WGS84
  temp_sf <- sf::st_as_sf(
    data.frame(x = coords_utm_2d[,1], y = coords_utm_2d[,2]),
    coords = c("x", "y"),
    crs = epsg_utm
  )

  coords_wgs84 <- sf::st_coordinates(sf::st_transform(temp_sf, 4326))

  # Adicionar elevação constante (cota máxima)
  coords_3d <- cbind(coords_wgs84, Z = z_max)

  # Criar polígono 3D SEM PIPE
  polygon_3d <- sf::st_polygon(list(coords_3d))
  sfc_3d <- sf::st_sfc(polygon_3d, crs = 4326, dim = "XYZ")
  final_geom <- sf::st_transform(sfc_3d, crs = crs_final)

  return(final_geom)
}

#' Cria metadados da faixa
#' @keywords internal
create_strip_metadata <- function(airport, pista_id, pista_data, faixa_params, z_max) {
  data.frame(
    aeroporto_icao      = airport$icao,
    pista_id            = pista_id,
    pista_comprimento_m = pista_data$comprimento_m,
    pista_largura_m     = pista_data$largura_m,
    tipo_pavimento      = pista_data$tipo_pavimento,
    codigo_referencia   = paste0(faixa_params$code_number, faixa_params$code_letter),
    approach_type       = faixa_params$approach_type,
    cota_maxima_m       = z_max,
    largura_faixa_m     = faixa_params$largura_faixa_m,
    comprimento_faixa_m = faixa_params$comprimento_faixa_m,
    extensao_lateral_m  = faixa_params$lateral_width_m,
    extensao_long_m     = faixa_params$longitudinal_ext_m,
    area_faixa_m2       = faixa_params$largura_faixa_m * faixa_params$comprimento_faixa_m,
    norma               = "RBAC-154 §154.207(c)",
    data_geracao        = as.character(Sys.Date()),
    stringsAsFactors    = FALSE
  )
}
