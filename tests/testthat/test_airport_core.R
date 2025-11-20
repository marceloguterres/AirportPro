test_that("SBFL carrega e calcula faixas", {
  sbfl_path <- system.file("extdata", "ad_sbfl.json", package = "AirportPro")
  sbfl <- Airport$new(sbfl_path)

  expect_s3_class(sbfl, "Airport")
  expect_equal(sbfl$icao, "SBFL")
  expect_equal(sort(names(sbfl$pistas)), c("03/21", "14/32"))

  faixa <- sbfl$faixas[["14/32"]]
  expect_equal(faixa$comprimento_faixa_m, 2520)
  expect_equal(faixa$largura_faixa_m, 280)
})

test_that("runway_to_sf retorna comprimentos UTM e haversine", {
  sbmt_path <- system.file("extdata", "ad_sbmt.json", package = "AirportPro")
  sbmt <- Airport$new(sbmt_path)

  sf_rw <- runway_to_sf(sbmt, "12/30", proj = FALSE, distance = "both")
  cab1 <- sbmt$pistas[["12/30"]]$cabeceiras[[1]]
  cab2 <- sbmt$pistas[["12/30"]]$cabeceiras[[2]]

  esperado_hav <- geosphere::distHaversine(
    c(cab1$lon, cab1$lat),
    c(cab2$lon, cab2$lat)
  )

  expect_gt(sf_rw$comprimento_m, 0)
  expect_equal(sf_rw$comprimento_declarado_m, sbmt$pistas[["12/30"]]$comprimento_m)
  expect_equal(sf_rw$comprimento_haversine_m, round(esperado_hav, 1))
})

test_that("Superfícies ICA são geradas para todas as cabeceiras", {
  sbpa_path <- system.file("extdata", "ad_sbpa.json", package = "AirportPro")
  sbpa <- Airport$new(sbpa_path)

  expect_length(sbpa$superficies, 2)
  expect_true(all(c("11/29_11", "11/29_29") %in% names(sbpa$superficies)))
})
