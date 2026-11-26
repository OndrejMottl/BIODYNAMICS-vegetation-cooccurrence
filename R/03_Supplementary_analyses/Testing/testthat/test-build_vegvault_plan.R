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
      withr::local_tempfile(fileext = ".sqlite")

    db_con <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = tmp_db
      )

    DBI::dbWriteTable(
      conn = db_con,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )
    )

    DBI::dbDisconnect(conn = db_con)

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )

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
        sel_dataset_type = "fossil_pollen_archive",
        data_vegvault_release = data_release
      ),
      regexp = "vaultkeepr query plan"
    )
  }
)

testthat::test_that(
  "build_vegvault_plan types an opaque empty query as no records",
  {
    tmp_db <-
      withr::local_tempfile(fileext = ".sqlite")

    db_con <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = tmp_db
      )

    DBI::dbWriteTable(
      conn = db_con,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )
    )

    DBI::dbDisconnect(conn = db_con)

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )

    testthat::local_mocked_bindings(
      open_vault = function(...) {
        base::stop(".")
      },
      .package = "vaultkeepr"
    )

    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = tmp_db,
        x_lim = base::c(12, 19),
        y_lim = base::c(48, 52),
        age_lim = base::c(0, 5000),
        sel_dataset_type = "vegetation_plot",
        data_vegvault_release = data_release
      ),
      regexp = "query returned no records",
      class = "biodynamics_vegvault_no_records"
    )
  }
)

testthat::test_that(
  "build_vegvault_plan stops before opening another release",
  {
    tmp_db <-
      withr::local_tempfile(fileext = ".sqlite")

    db_con <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = tmp_db
      )

    DBI::dbWriteTable(
      conn = db_con,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_rebuilt"
      )
    )

    DBI::dbDisconnect(conn = db_con)

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )

    testthat::local_mocked_bindings(
      open_vault = function(...) {
        base::stop("The vault was opened.")
      },
      .package = "vaultkeepr"
    )

    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = tmp_db,
        x_lim = base::c(12, 19),
        y_lim = base::c(48, 52),
        age_lim = base::c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive",
        data_vegvault_release = data_release
      ),
      class = "biodynamics_vegvault_release_mismatch"
    )
  }
)

testthat::test_that(
  "build_vegvault_plan requires the release record",
  {
    tmp_db <-
      withr::local_tempfile(fileext = ".sqlite")

    db_con <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = tmp_db
      )

    DBI::dbWriteTable(
      conn = db_con,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0"
      )
    )

    DBI::dbDisconnect(conn = db_con)

    testthat::local_mocked_bindings(
      open_vault = function(...) {
        base::stop("The vault was opened.")
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
      regexp = "data_vegvault_release"
    )
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

    data_release <-
      load_vegvault_database_version(
        path_to_vegvault = test_db,
        vegvault_version = load_config_value(
          config_id = "default",
          value = base::c("vegvault_data", "vegvault_version")
        )
      )

    res <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        data_vegvault_release = data_release,
        x_lim = base::c(12, 18.9),
        y_lim = base::c(48.5, 51.5),
        age_lim = base::c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    testthat::expect_false(base::is.null(res))
  }
)

testthat::test_that(
  "build_vegvault_plan names the empty record type when only gridpoints remain",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    data_release <-
      load_vegvault_database_version(
        path_to_vegvault = test_db,
        vegvault_version = load_config_value(
          config_id = "default",
          value = base::c("vegvault_data", "vegvault_version")
        )
      )

    # Central Sahara window with gridpoints but no fossil-pollen archive;
    #   vaultkeepr would later stop with an empty message. The Eastern
    #   Siberia window used before (unit as_r006) holds two fossil-pollen
    #   datasets from VegVault 2.0.0 on.
    testthat::expect_error(
      build_vegvault_plan(
        path_to_vegvault = test_db,
        data_vegvault_release = data_release,
        x_lim = base::c(10, 20),
        y_lim = base::c(20, 25),
        age_lim = base::c(0, 20000),
        sel_dataset_type = base::c("fossil_pollen_archive", "gridpoints")
      ),
      regexp = "No .fossil_pollen_archive. samples in this window",
      class = "biodynamics_vegvault_no_records"
    )
  }
)

testthat::test_that(
  "build_vegvault_plan keeps a window with records and gridpoints",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    data_release <-
      load_vegvault_database_version(
        path_to_vegvault = test_db,
        vegvault_version = load_config_value(
          config_id = "default",
          value = base::c("vegvault_data", "vegvault_version")
        )
      )

    res <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        data_vegvault_release = data_release,
        x_lim = base::c(12, 18.9),
        y_lim = base::c(48.5, 51.5),
        age_lim = base::c(0, 5000),
        sel_dataset_type = base::c("fossil_pollen_archive", "gridpoints")
      )

    testthat::expect_s3_class(res, "vault_pipe")
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

    data_release <-
      load_vegvault_database_version(
        path_to_vegvault = test_db,
        vegvault_version = load_config_value(
          config_id = "default",
          value = base::c("vegvault_data", "vegvault_version")
        )
      )

    res <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        data_vegvault_release = data_release,
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
