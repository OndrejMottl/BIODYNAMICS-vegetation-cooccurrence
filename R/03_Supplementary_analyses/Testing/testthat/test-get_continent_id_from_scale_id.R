testthat::test_that(
  "get_continent_id_from_scale_id() maps regional id in repo csv",
  {
    res <-
      get_continent_id_from_scale_id(
        scale_id = "eu_r005",
        file = here::here("Data/Input/spatial_grid.csv")
      )

    testthat::expect_equal(res, "europe")
  }
)

testthat::test_that(
  "get_continent_id_from_scale_id() keeps continental id",
  {
    res <-
      get_continent_id_from_scale_id(
        scale_id = "america",
        file = here::here("Data/Input/spatial_grid.csv")
      )

    testthat::expect_type(res, "character")
    testthat::expect_equal(res, "america")
  }
)

testthat::test_that(
  "get_continent_id_from_scale_id() validates scale_id type",
  {
    withr::with_tempdir(
      {
        path_grid <-
          base::file.path(
            base::getwd(),
            "spatial_grid.csv"
          )

        data_grid <-
          tibble::tibble(
            scale_id = "eu_r005",
            continent_id = "europe"
          )

        readr::write_csv(
          x = data_grid,
          file = path_grid
        )

        testthat::expect_error(
          get_continent_id_from_scale_id(
            scale_id = 1L,
            file = path_grid
          ),
          regexp = "single non-empty character string"
        )
      }
    )
  }
)

testthat::test_that(
  "get_continent_id_from_scale_id() validates scale_id content",
  {
    withr::with_tempdir(
      {
        path_grid <-
          base::file.path(
            base::getwd(),
            "spatial_grid.csv"
          )

        data_grid <-
          tibble::tibble(
            scale_id = "eu_r005",
            continent_id = "europe"
          )

        readr::write_csv(
          x = data_grid,
          file = path_grid
        )

        testthat::expect_error(
          get_continent_id_from_scale_id(
            scale_id = "",
            file = path_grid
          ),
          regexp = "single non-empty character string"
        )
      }
    )
  }
)

testthat::test_that(
  "get_continent_id_from_scale_id() validates file path",
  {
    testthat::expect_error(
      get_continent_id_from_scale_id(
        scale_id = "eu_r005",
        file = "missing_grid.txt"
      ),
      regexp = "readable CSV file"
    )
  }
)

testthat::test_that(
  "get_continent_id_from_scale_id() errors on missing columns",
  {
    withr::with_tempdir(
      {
        path_grid <-
          base::file.path(
            base::getwd(),
            "spatial_grid.csv"
          )

        data_grid <-
          tibble::tibble(
            scale_id = "eu_r005",
            parent_id = "europe"
          )

        readr::write_csv(
          x = data_grid,
          file = path_grid
        )

        testthat::expect_error(
          get_continent_id_from_scale_id(
            scale_id = "eu_r005",
            file = path_grid
          ),
          regexp = "must contain columns: scale_id, continent_id"
        )
      }
    )
  }
)

testthat::test_that(
  "get_continent_id_from_scale_id() errors on absent scale_id",
  {
    withr::with_tempdir(
      {
        path_grid <-
          base::file.path(
            base::getwd(),
            "spatial_grid.csv"
          )

        data_grid <-
          tibble::tibble(
            scale_id = base::c("eu_r005", "eu_r006"),
            continent_id = base::c("europe", "europe")
          )

        readr::write_csv(
          x = data_grid,
          file = path_grid
        )

        testthat::expect_error(
          get_continent_id_from_scale_id(
            scale_id = "am_r001",
            file = path_grid
          ),
          regexp = "Expected exactly 1 row for scale_id 'am_r001'. Found: 0"
        )
      }
    )
  }
)

testthat::test_that(
  "get_continent_id_from_scale_id() errors on duplicate scale_id",
  {
    withr::with_tempdir(
      {
        path_grid <-
          base::file.path(
            base::getwd(),
            "spatial_grid.csv"
          )

        data_grid <-
          tibble::tibble(
            scale_id = base::c("eu_r005", "eu_r005"),
            continent_id = base::c("europe", "europe")
          )

        readr::write_csv(
          x = data_grid,
          file = path_grid
        )

        testthat::expect_error(
          get_continent_id_from_scale_id(
            scale_id = "eu_r005",
            file = path_grid
          ),
          regexp = "Expected exactly 1 row for scale_id 'eu_r005'. Found: 2"
        )
      }
    )
  }
)

testthat::test_that(
  "get_continent_id_from_scale_id() errors on missing continent_id",
  {
    withr::with_tempdir(
      {
        path_grid <-
          base::file.path(
            base::getwd(),
            "spatial_grid.csv"
          )

        data_grid <-
          tibble::tibble(
            scale_id = "eu_r005",
            continent_id = NA_character_
          )

        readr::write_csv(
          x = data_grid,
          file = path_grid
        )

        testthat::expect_error(
          get_continent_id_from_scale_id(
            scale_id = "eu_r005",
            file = path_grid
          ),
          regexp = "Missing continent_id for scale_id 'eu_r005'"
        )
      }
    )
  }
)

testthat::test_that(
  "get_continent_id_from_scale_id() errors on empty continent_id",
  {
    withr::with_tempdir(
      {
        path_grid <-
          base::file.path(
            base::getwd(),
            "spatial_grid.csv"
          )

        data_grid <-
          tibble::tibble(
            scale_id = "eu_r005",
            continent_id = ""
          )

        readr::write_csv(
          x = data_grid,
          file = path_grid
        )

        testthat::expect_error(
          get_continent_id_from_scale_id(
            scale_id = "eu_r005",
            file = path_grid
          ),
          regexp = "Missing continent_id for scale_id 'eu_r005'"
        )
      }
    )
  }
)