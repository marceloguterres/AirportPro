test_that("SBMT carrega, strip e distâncias de pista", {
  sbmt_path <- system.file("extdata", "ad_sbmt.json", package = "AirportPro")
  sbmt <- Airport$new(sbmt_path)

  expect_s3_class(sbmt, "Airport")
  expect_equal(sbmt$icao, "SBMT")
  expect_equal(names(sbmt$pistas), "12/30")

  faixa <- sbmt$faixas[["12/30"]]
  expect_equal(faixa$comprimento_faixa_m, 1720)
  expect_equal(faixa$largura_faixa_m, 150)
  expect_equal(faixa$lateral_width_m, 75)

  expect_length(sbmt$superficies, 2)

  rw <- runway_to_sf(sbmt, "12/30", proj = FALSE, distance = "both")
  expect_s3_class(rw, "sf")
  expect_true(all(c("comprimento_m", "comprimento_haversine_m", "diferenca_m") %in% names(rw)))
  expect_gt(rw$comprimento_m, 0)
  expect_gt(rw$comprimento_haversine_m, 0)
})
