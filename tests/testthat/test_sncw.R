test_that("SNCW carrega, strip e superfícies", {
  sncw_path <- system.file("extdata", "ad_sncw.json", package = "AirportPro")
  sncw <- Airport$new(sncw_path)

  expect_s3_class(sncw, "Airport")
  expect_equal(sncw$icao, "SNCW")
  expect_equal(names(sncw$pistas), "09/27")

  faixa <- sncw$faixas[["09/27"]]
  expect_equal(faixa$comprimento_faixa_m, 2720)
  expect_equal(faixa$largura_faixa_m, 280)
  expect_equal(faixa$lateral_width_m, 140)

  expect_length(sncw$superficies, 2)
})
