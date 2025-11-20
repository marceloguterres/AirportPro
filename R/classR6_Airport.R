# R/classR6_Airport.R
#' Airport R6 Class — OLS ICA 11-408 + RBAC-154
#'
#' @description
#' Carrega aeroporto de JSON e calcula automaticamente faixas e superfícies ICA 11-408.
#'
#' @field icao Código ICAO do aeroporto
#' @field nome Nome oficial
#' @field municipio Município
#' @field estado UF
#' @field arp Airport Reference Point (lat, lon, elev_m)
#' @field datum Datum geodésico utilizado
#' @field crs_planar CRS planar recomendado (ex: EPSG:31982)
#' @field pistas Lista de pistas processadas
#' @field faixas Parâmetros RBAC-154 das faixas
#' @field superficies Superfícies ICA 11-408 por cabeceira
#'
#' @export
Airport <- R6::R6Class("Airport",
                       public = list(
                         icao = NULL,
                         nome = NULL,
                         municipio = NULL,
                         estado = NULL,
                         arp = NULL,
                         datum = NULL,
                         crs_planar = NULL,
                         pistas = NULL,
                         faixas = NULL,
                         superficies = NULL,

                         #' @description
                         #' Inicializa o aeroporto a partir de um arquivo JSON
                         #' @param json_path Caminho para o JSON do aeroporto
                         initialize = function(json_path) {
                           if (!file.exists(json_path)) {
                             stop("Arquivo não encontrado: ", json_path)
                           }
                           json <- jsonlite::read_json(json_path)
                           aero <- json$aeroporto
                           geo  <- aero$geodesia %||% aero$referencia

                           self$icao       <- aero$icao
                           self$nome       <- aero$nome
                           self$municipio  <- aero$municipio
                           self$estado     <- aero$estado
                           self$datum      <- geo$geoid %||% "SIRGAS2000"
                           self$crs_planar <- geo$crs_planar %||% 32722

                           self$arp <- list(
                             lat    = as.numeric(geo$latitude_arp),
                             lon    = as.numeric(geo$longitude_arp),
                             elev_m = as.numeric(geo$elevacao_arp_m)
                           )

                           self$pistas      <- .process_runways(aero$pistas)
                           self$faixas      <- .get_strip_params(self)
                           self$superficies <- .get_superficie_params(self)
                         },

                         #' @description Lista todas as cabeceiras com suas superfícies ICA 11-408
                         list_superficies = function() { list_superficies(self)
                         },

                         #' @description
                         #' Retorna os parâmetros completos de uma cabeceira
                         #' @param id ID completo (ex: "11_11") ou pista_id + designador
                         #' @param pista_id ID da pista (ex: "11/29")
                         #' @param designador Cabeceira (ex: "11")
                         #' @return Lista com todos os parâmetros ICA 11-408
                         get_superficie = function(id = NULL, pista_id = NULL, designador = NULL) {
                           get_superficie(self, id, pista_id, designador)
                         }
                       )
)
