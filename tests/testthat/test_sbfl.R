test_that("SBFL carrega e calcula strip e superfícies", {
  sbfl_path <- system.file("extdata", "ad_sbfl.json", package = "AirportPro")
  sbfl <- Airport$new(sbfl_path)

  expect_s3_class(sbfl, "Airport")
  expect_equal(sbfl$icao, "SBFL")
  expect_equal(sort(names(sbfl$pistas)), c("03/21", "14/32"))

  faixa <- sbfl$faixas[["14/32"]]
  expect_equal(faixa$comprimento_faixa_m, 2520)
  expect_equal(faixa$largura_faixa_m, 280)
  expect_equal(faixa$lateral_width_m, 140)

  expect_length(sbfl$superficies, 4)
})
