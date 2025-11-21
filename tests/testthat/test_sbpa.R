test_that("SBPA carrega, strip e superfícies", {
  sbpa_path <- system.file("extdata", "ad_sbpa.json", package = "AirportPro")
  sbpa <- Airport$new(sbpa_path)

  expect_s3_class(sbpa, "Airport")
  expect_equal(sbpa$icao, "SBPA")
  expect_equal(names(sbpa$pistas), "11/29")

  faixa <- sbpa$faixas[["11/29"]]
  expect_equal(faixa$comprimento_faixa_m, 3320)
  expect_equal(faixa$largura_faixa_m, 280)
  expect_equal(faixa$lateral_width_m, 140)

  expect_length(sbpa$superficies, 2)
})
