testthat::test_that(
  "get_functional_type_classification_path_from_store() picks latest",
  {
    withr::with_tempdir(
      {
        path_grid <-
          base::file.path(
            base::getwd(),
            "spatial_grid.csv"
          )

        path_processed <-
          base::file.path(
            base::getwd(),
            "Traits"
          )

        base::dir.create(
          path = path_processed,
          showWarnings = FALSE
        )

        data_grid <-
          tibble::tibble(
            scale_id = base::c("eu_r005", "america"),
            continent_id = base::c("europe", "america")
          )

        readr::write_csv(
          x = data_grid,
          file = path_grid
        )

        file_old <-
          base::file.path(
            path_processed,
            "data_ft_classification_europe_2026-01-15.qs"
          )

        file_new <-
          base::file.path(
            path_processed,
            "data_ft_classification_europe_2026-04-15.qs"
          )

        file_other <-
          base::file.path(
            path_processed,
            "data_ft_classification_america_2026-04-15.qs"
          )

        base::file.create(file_old)
        base::file.create(file_new)
        base::file.create(file_other)

        res <-
          get_functional_type_classification_path_from_store(
            store = base::file.path(
              "Data/targets/paleo_spatial_regional/eu_r005",
              "pipeline_paleo_spatial_resolution"
            ),
            path_spatial_grid = path_grid,
            path_processed = path_processed
          )

        testthat::expect_equal(res, file_new)
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification_path_from_store() uses local",
  {
    withr::with_tempdir(
      {
        path_grid <-
          base::file.path(
            base::getwd(),
            "spatial_grid.csv"
          )

        path_processed <-
          base::file.path(
            base::getwd(),
            "Traits"
          )

        base::dir.create(
          path = path_processed,
          showWarnings = FALSE
        )

        data_grid <-
          tibble::tibble(
            scale_id = "eu_r005_l001",
            continent_id = "europe"
          )

        readr::write_csv(
          x = data_grid,
          file = path_grid
        )

        file_path <-
          base::file.path(
            path_processed,
            "data_ft_classification_europe_2026-04-15.qs"
          )

        base::file.create(file_path)

        res <-
          get_functional_type_classification_path_from_store(
            store = base::file.path(
              "Data/targets/paleo_spatial_local/eu_r005_l001",
              "pipeline_paleo_spatial_resolution"
            ),
            path_spatial_grid = path_grid,
            path_processed = path_processed
          )

        testthat::expect_type(res, "character")
        testthat::expect_equal(res, file_path)
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification_path_from_store() supports modern prefix",
  {
    withr::with_tempdir(
      {
        path_grid <-
          base::file.path(
            base::getwd(),
            "spatial_grid.csv"
          )

        path_processed <-
          base::file.path(
            base::getwd(),
            "Traits"
          )

        base::dir.create(
          path = path_processed,
          showWarnings = FALSE
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

        file_paleo_newer <-
          base::file.path(
            path_processed,
            "data_ft_classification_europe_2026-05-15.qs"
          )

        file_modern_old <-
          base::file.path(
            path_processed,
            "data_ft_classification_modern_europe_2026-03-15.qs"
          )

        file_modern_new <-
          base::file.path(
            path_processed,
            "data_ft_classification_modern_europe_2026-04-15.qs"
          )

        base::file.create(file_paleo_newer)
        base::file.create(file_modern_old)
        base::file.create(file_modern_new)

        res <-
          get_functional_type_classification_path_from_store(
            store = base::file.path(
              "Data/targets/paleo_spatial_regional/eu_r005",
              "pipeline_paleo_spatial_resolution"
            ),
            path_spatial_grid = path_grid,
            path_processed = path_processed,
            data_source_prefix = "modern"
          )

        testthat::expect_equal(res, file_modern_new)
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification_path_from_store() validates store",
  {
    withr::with_tempdir(
      {
        path_grid <-
          base::file.path(
            base::getwd(),
            "spatial_grid.csv"
          )

        readr::write_csv(
          x = tibble::tibble(
            scale_id = "eu_r005",
            continent_id = "europe"
          ),
          file = path_grid
        )

        testthat::expect_error(
          get_functional_type_classification_path_from_store(
            store = 1L,
            path_spatial_grid = path_grid,
            path_processed = base::getwd()
          ),
          regexp = "single character string"
        )
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification_path_from_store() errors on project",
  {
    withr::with_tempdir(
      {
        path_grid <-
          base::file.path(
            base::getwd(),
            "spatial_grid.csv"
          )

        path_processed <-
          base::file.path(
            base::getwd(),
            "Traits"
          )

        base::dir.create(
          path = path_processed,
          showWarnings = FALSE
        )

        readr::write_csv(
          x = tibble::tibble(
            scale_id = "eu_r005",
            continent_id = "europe"
          ),
          file = path_grid
        )

        testthat::expect_error(
          get_functional_type_classification_path_from_store(
            store = base::file.path(
              "Data/targets/cz_paleo",
              "pipeline_paleo_spatial_resolution"
            ),
            path_spatial_grid = path_grid,
            path_processed = path_processed
          ),
          regexp = "requires a spatial store path"
        )
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification_path_from_store() errors on missing",
  {
    withr::with_tempdir(
      {
        path_grid <-
          base::file.path(
            base::getwd(),
            "spatial_grid.csv"
          )

        path_processed <-
          base::file.path(
            base::getwd(),
            "Traits"
          )

        base::dir.create(
          path = path_processed,
          showWarnings = FALSE
        )

        readr::write_csv(
          x = tibble::tibble(
            scale_id = "eu_r005",
            continent_id = "europe"
          ),
          file = path_grid
        )

        testthat::expect_error(
          get_functional_type_classification_path_from_store(
            store = base::file.path(
              "Data/targets/paleo_spatial_regional/eu_r005",
              "pipeline_paleo_spatial_resolution"
            ),
            path_spatial_grid = path_grid,
            path_processed = path_processed
          ),
          regexp = "No FT classification file found for continent 'europe'"
        )
      }
    )
  }
)

testthat::test_that(
  "get_functional_type_classification_path_from_store() validates grid",
  {
    withr::with_tempdir(
      {
        path_processed <-
          base::file.path(
            base::getwd(),
            "Traits"
          )

        base::dir.create(
          path = path_processed,
          showWarnings = FALSE
        )

        testthat::expect_error(
          get_functional_type_classification_path_from_store(
            store = base::file.path(
              "Data/targets/paleo_spatial_regional/eu_r005",
              "pipeline_paleo_spatial_resolution"
            ),
            path_spatial_grid = "missing_grid.txt",
            path_processed = path_processed
          ),
          regexp = "readable CSV file"
        )
      }
    )
  }
)
