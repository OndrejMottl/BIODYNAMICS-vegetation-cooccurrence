testthat::test_that(
  "resolve_continent_ids_from_scale_ids() maps regional id in repo csv",
  {
    res <-
      resolve_continent_ids_from_scale_ids(
        scale_id = "eu_r005",
        file = here::here("Data/Input/spatial_grid.csv")
      )

    testthat::expect_equal(res, "europe")
  }
)

testthat::test_that(
  "resolve_continent_ids_from_scale_ids() keeps continental id",
  {
    res <-
      resolve_continent_ids_from_scale_ids(
        scale_id = "america",
        file = here::here("Data/Input/spatial_grid.csv")
      )

    testthat::expect_type(res, "character")
    testthat::expect_equal(res, "america")
  }
)

testthat::test_that(
  "resolve_continent_ids_from_scale_ids() maps vector in input order",
  {
    res <-
      resolve_continent_ids_from_scale_ids(
        scale_id = base::c("eu_r005", "america", "eu_r005"),
        file = here::here("Data/Input/spatial_grid.csv")
      )

    testthat::expect_equal(
      res,
      base::c("europe", "america", "europe")
    )
  }
)

testthat::test_that(
  "resolve_continent_ids_from_scale_ids() validates scale_id type",
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
          resolve_continent_ids_from_scale_ids(
            scale_id = 1L,
            file = path_grid
          ),
          regexp = "non-empty character vector"
        )
      }
    )
  }
)

testthat::test_that(
  "resolve_continent_ids_from_scale_ids() validates scale_id content",
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
          resolve_continent_ids_from_scale_ids(
            scale_id = "",
            file = path_grid
          ),
          regexp = "non-empty character vector"
        )
      }
    )
  }
)

testthat::test_that(
  "resolve_continent_ids_from_scale_ids() validates file path",
  {
    testthat::expect_error(
      resolve_continent_ids_from_scale_ids(
        scale_id = "eu_r005",
        file = "missing_grid.txt"
      ),
      regexp = "readable CSV file"
    )
  }
)

testthat::test_that(
  "resolve_continent_ids_from_scale_ids() errors on missing columns",
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
          resolve_continent_ids_from_scale_ids(
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
  "resolve_continent_ids_from_scale_ids() errors on absent scale_id",
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
          resolve_continent_ids_from_scale_ids(
            scale_id = "am_r001",
            file = path_grid
          ),
          regexp = "Expected exactly 1 row for each scale_id"
        )
      }
    )
  }
)

testthat::test_that(
  "resolve_continent_ids_from_scale_ids() errors on duplicate scale_id",
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
          resolve_continent_ids_from_scale_ids(
            scale_id = "eu_r005",
            file = path_grid
          ),
          regexp = "Expected exactly 1 row for each scale_id"
        )
      }
    )
  }
)

testthat::test_that(
  "resolve_continent_ids_from_scale_ids() errors on missing continent_id",
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
          resolve_continent_ids_from_scale_ids(
            scale_id = "eu_r005",
            file = path_grid
          ),
          regexp = "Missing continent_id for scale_id"
        )
      }
    )
  }
)

testthat::test_that(
  "resolve_continent_ids_from_scale_ids() errors on empty continent_id",
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
          resolve_continent_ids_from_scale_ids(
            scale_id = "eu_r005",
            file = path_grid
          ),
          regexp = "Missing continent_id for scale_id"
        )
      }
    )
  }
)
