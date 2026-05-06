# Input Validation (no external database required)

testthat::test_that(
  "build_vegvault_plan errors for invalid path type",
  {
    testthat::expect_error(
      build_vegvault_plan(path_to_vegvault = 123),
      regexp = "character"
    )

    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = "nonexistent.sqlite"
      ),
      regexp = "VegVault"
    )
  }
)

testthat::test_that(
  "build_vegvault_plan errors for invalid x_lim",
  {
    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        x_lim = "12",
        y_lim = base::c(48, 52),
        age_lim = base::c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      ),
      regexp = "x_lim"
    )

    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        x_lim = base::c(12, 13, 14),
        y_lim = base::c(48, 52),
        age_lim = base::c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      ),
      regexp = "x_lim"
    )

    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        x_lim = NULL,
        y_lim = base::c(48, 52),
        age_lim = base::c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      ),
      regexp = "x_lim"
    )
  }
)

testthat::test_that(
  "build_vegvault_plan errors for invalid y_lim",
  {
    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        x_lim = base::c(12, 19),
        y_lim = "48",
        age_lim = base::c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      ),
      regexp = "y_lim"
    )

    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        x_lim = base::c(12, 19),
        y_lim = 48,
        age_lim = base::c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      ),
      regexp = "y_lim"
    )

    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        x_lim = base::c(12, 19),
        y_lim = NULL,
        age_lim = base::c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      ),
      regexp = "y_lim"
    )
  }
)

testthat::test_that(
  "build_vegvault_plan errors for invalid age_lim",
  {
    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        x_lim = base::c(12, 19),
        y_lim = base::c(48, 52),
        age_lim = "c(0, 5000)",
        sel_dataset_type = "fossil_pollen_archive"
      ),
      regexp = "age_lim"
    )

    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        x_lim = base::c(12, 19),
        y_lim = base::c(48, 52),
        age_lim = base::c(0, 5000, 10000),
        sel_dataset_type = "fossil_pollen_archive"
      ),
      regexp = "age_lim"
    )

    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        x_lim = base::c(12, 19),
        y_lim = base::c(48, 52),
        age_lim = NULL,
        sel_dataset_type = "fossil_pollen_archive"
      ),
      regexp = "age_lim"
    )
  }
)

testthat::test_that(
  "build_vegvault_plan errors for invalid sel_dataset_type",
  {
    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        x_lim = base::c(12, 19),
        y_lim = base::c(48, 52),
        age_lim = base::c(0, 5000),
        sel_dataset_type = 1L
      ),
      regexp = "sel_dataset_type"
    )

    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        x_lim = base::c(12, 19),
        y_lim = base::c(48, 52),
        age_lim = base::c(0, 5000),
        sel_dataset_type = NULL
      ),
      regexp = "sel_dataset_type"
    )
  }
)

testthat::test_that(
  "build_vegvault_plan errors when plan assembly fails",
  {
    tmp_db <-
      base::tempfile(fileext = ".sqlite")

    db_con <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = tmp_db
      )

    DBI::dbDisconnect(conn = db_con)

    testthat::local_mocked_bindings(
      open_vault = function(...) {
        base::stop("Simulated vaultkeepr plan error")
      },
      .package = "vaultkeepr"
    )

    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = tmp_db,
        x_lim = base::c(12, 19),
        y_lim = base::c(48, 52),
        age_lim = base::c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      ),
      regexp = "vaultkeepr query plan"
    )

    base::file.remove(tmp_db)
  }
)

# Output Structure (VegVault database required)

testthat::test_that(
  "build_vegvault_plan returns a non-NULL plan for fossil archives",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = base::c(12, 18.9),
        y_lim = base::c(48.5, 51.5),
        age_lim = base::c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    testthat::expect_false(base::is.null(res))
  }
)

testthat::test_that(
  "build_vegvault_plan works with multiple dataset types",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = base::c(12, 18.9),
        y_lim = base::c(48.5, 51.5),
        age_lim = base::c(0, 5000),
        sel_dataset_type = base::c(
          "vegetation_plot",
          "fossil_pollen_archive"
        )
      )

    testthat::expect_false(base::is.null(res))
  }
)
