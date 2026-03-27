testthat::test_that("gets scale_id for local spatial store", {
  res <-
    get_scale_id_from_store(
      store = paste0(
        "Data/targets/spatial_local/",
        "eu_r005_l001/pipeline_basic"
      ),
      file = here::here("Data/Input/spatial_grid.csv")
    )
  testthat::expect_equal(res, "eu_r005_l001")
})

testthat::test_that("returns NULL for non-spatial project store", {
  res <-
    get_scale_id_from_store(
      store = "Data/targets/project_cz/pipeline_basic",
      file = here::here("Data/Input/spatial_grid.csv")
    )
  testthat::expect_null(res)
})

testthat::test_that("returns NULL for default _targets store", {
  res <-
    get_scale_id_from_store(
      store = "_targets",
      file = here::here("Data/Input/spatial_grid.csv")
    )
  testthat::expect_null(res)
})

testthat::test_that("returns NULL gracefully when CSV is absent", {
  res <-
    get_scale_id_from_store(
      store = paste0(
        "Data/targets/spatial_local/",
        "eu_r005_l001/pipeline_basic"
      ),
      file = "non_existent_spatial_grid.csv"
    )
  testthat::expect_null(res)
})

testthat::test_that("works for continental scale_id", {
  res <-
    get_scale_id_from_store(
      store = paste0(
        "Data/targets/spatial_continental/",
        "europe/pipeline_basic"
      ),
      file = here::here("Data/Input/spatial_grid.csv")
    )
  testthat::expect_equal(res, "europe")
})

testthat::test_that("works for regional scale_id", {
  res <-
    get_scale_id_from_store(
      store = "Data/targets/spatial_regional/eu_r001/pipeline_basic",
      file = here::here("Data/Input/spatial_grid.csv")
    )
  testthat::expect_equal(res, "eu_r001")
})

testthat::test_that("return type is character for spatial, NULL otherwise", {
  res_spatial <-
    get_scale_id_from_store(
      store = paste0(
        "Data/targets/spatial_local/",
        "eu_r005_l001/pipeline_basic"
      ),
      file = here::here("Data/Input/spatial_grid.csv")
    )
  testthat::expect_type(res_spatial, "character")

  res_project <-
    get_scale_id_from_store(
      store = "Data/targets/project_cz/pipeline_basic",
      file = here::here("Data/Input/spatial_grid.csv")
    )
  testthat::expect_null(res_project)
})

testthat::test_that("errors when store is not a single string", {
  testthat::expect_error(
    get_scale_id_from_store(
      store = 123,
      file = here::here("Data/Input/spatial_grid.csv")
    )
  )

  testthat::expect_error(
    get_scale_id_from_store(
      store = c("path_a", "path_b"),
      file = here::here("Data/Input/spatial_grid.csv")
    )
  )
})
