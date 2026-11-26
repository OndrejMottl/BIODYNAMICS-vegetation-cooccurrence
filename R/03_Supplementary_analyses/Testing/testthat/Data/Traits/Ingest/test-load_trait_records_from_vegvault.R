testthat::test_that(
  "load_trait_records_from_vegvault() errors for non-character path",
  {
    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = 123,
        vec_trait_domain_names = "SLA"
      )
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = TRUE,
        vec_trait_domain_names = "SLA"
      )
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = base::list("a.sqlite"),
        vec_trait_domain_names = "SLA"
      )
    )
  }
)

testthat::test_that(
  "load_trait_records_from_vegvault() errors for path length > 1",
  {
    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = base::c("a.sqlite", "b.sqlite"),
        vec_trait_domain_names = "SLA"
      )
    )
  }
)

testthat::test_that(
  "load_trait_records_from_vegvault() errors for invalid domains",
  {
    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = "somefile.sqlite",
        vec_trait_domain_names = 123
      )
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = "somefile.sqlite",
        vec_trait_domain_names = NULL
      )
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = "somefile.sqlite",
        vec_trait_domain_names = base::character(0)
      )
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = "somefile.sqlite",
        vec_trait_domain_names = TRUE
      )
    )
  }
)

testthat::test_that(
  "load_trait_records_from_vegvault() errors for missing database",
  {
    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = "nonexistent_path.sqlite",
        vec_trait_domain_names = "SLA"
      )
    )
  }
)

testthat::test_that(
  "load_trait_records_from_vegvault() stops on another VegVault release",
  {
    path_vault <-
      withr::local_tempfile(fileext = ".sqlite")

    connection_vault <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = path_vault
      )

    DBI::dbWriteTable(
      conn = connection_vault,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_rebuilt"
      )
    )

    DBI::dbDisconnect(connection_vault)

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
      load_trait_records_from_vegvault(
        path_vegvault = path_vault,
        vec_trait_domain_names = "SLA",
        data_vegvault_release = data_release
      ),
      class = "biodynamics_vegvault_release_mismatch"
    )
  }
)

testthat::test_that(
  "load_trait_records_from_vegvault() requires the release record",
  {
    path_vault <-
      withr::local_tempfile(fileext = ".sqlite")

    connection_vault <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = path_vault
      )

    DBI::dbWriteTable(
      conn = connection_vault,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0"
      )
    )

    DBI::dbDisconnect(connection_vault)

    testthat::local_mocked_bindings(
      open_vault = function(...) {
        base::stop("The vault was opened.")
      },
      .package = "vaultkeepr"
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = path_vault,
        vec_trait_domain_names = "SLA"
      ),
      regexp = "data_vegvault_release"
    )
  }
)
