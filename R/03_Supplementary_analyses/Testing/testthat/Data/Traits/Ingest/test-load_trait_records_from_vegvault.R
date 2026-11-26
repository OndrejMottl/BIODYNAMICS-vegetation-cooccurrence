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

testthat::test_that(
  "load_trait_records_from_vegvault() keeps original taxon names",
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
        manifest_sha256 = "hash_accepted"
      )
    )

    DBI::dbDisconnect(connection_vault)

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )

    list_captured <-
      base::new.env()

    testthat::local_mocked_bindings(
      open_vault = function(...) base::list(),
      get_datasets = function(con, ...) con,
      select_dataset_by_type = function(con, ...) con,
      get_samples = function(con, ...) con,
      get_traits = function(con, ...) {
        list_captured[["classify_to"]] <-
          base::list(...)[["classify_to"]]
        base::stop("get_traits() reached")
      },
      .package = "vaultkeepr"
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = path_vault,
        data_vegvault_release = data_release,
        vec_trait_domain_names = "SLA"
      ),
      regexp = "get_traits[(][)] reached"
    )

    testthat::expect_identical(
      list_captured[["classify_to"]],
      "original"
    )
  }
)

testthat::test_that(
  "load_trait_records_from_vegvault() keeps records without a data source",
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
        manifest_sha256 = "hash_accepted"
      )
    )

    DBI::dbWriteTable(
      conn = connection_vault,
      name = "Datasets",
      value = tibble::tibble(
        dataset_id = base::c(1L, 2L),
        data_source_id = base::c(10L, NA_integer_)
      )
    )

    DBI::dbDisconnect(connection_vault)

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )

    data_records_fixture <-
      tibble::tibble(
        dataset_id = base::c(1L, 2L, 2L),
        dataset_name = base::c(
          "bien_traits_1",
          "bien_traits_2",
          "bien_traits_2"
        ),
        sample_id = base::c(11L, 21L, 22L),
        trait_id = base::c(1L, 1L, 1L),
        taxon_id = base::c(100L, 200L, 201L),
        trait_domain_name = "Plant heigh",
        trait_name = "whole plant height",
        trait_value = base::c(1.5, 2.5, 3.5)
      )

    testthat::local_mocked_bindings(
      open_vault = function(...) base::list(),
      get_datasets = function(con, ...) con,
      select_dataset_by_type = function(con, ...) con,
      get_samples = function(con, ...) con,
      get_traits = function(con, ...) con,
      select_traits_by_domain_name = function(con, ...) con,
      extract_data = function(...) data_records_fixture,
      .package = "vaultkeepr"
    )

    res <-
      load_trait_records_from_vegvault(
        path_vegvault = path_vault,
        data_vegvault_release = data_release,
        vec_trait_domain_names = "Plant heigh"
      )

    testthat::expect_equal(base::nrow(res), 3L)
    testthat::expect_equal(
      dplyr::pull(res, data_source_id),
      base::c(10L, NA_integer_, NA_integer_)
    )
    testthat::expect_equal(
      dplyr::pull(res, trait_value),
      base::c(1.5, 2.5, 3.5)
    )
  }
)

testthat::test_that(
  "load_trait_records_from_vegvault() stops on records of unknown datasets",
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
        manifest_sha256 = "hash_accepted"
      )
    )

    DBI::dbWriteTable(
      conn = connection_vault,
      name = "Datasets",
      value = tibble::tibble(
        dataset_id = 1L,
        data_source_id = 10L
      )
    )

    DBI::dbDisconnect(connection_vault)

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )

    data_records_fixture <-
      tibble::tibble(
        dataset_id = base::c(1L, 3L),
        dataset_name = base::c("bien_traits_1", "bien_traits_3"),
        sample_id = base::c(11L, 31L),
        trait_id = 1L,
        taxon_id = base::c(100L, 300L),
        trait_domain_name = "Plant heigh",
        trait_name = "whole plant height",
        trait_value = base::c(1.5, 4.5)
      )

    testthat::local_mocked_bindings(
      open_vault = function(...) base::list(),
      get_datasets = function(con, ...) con,
      select_dataset_by_type = function(con, ...) con,
      get_samples = function(con, ...) con,
      get_traits = function(con, ...) con,
      select_traits_by_domain_name = function(con, ...) con,
      extract_data = function(...) data_records_fixture,
      .package = "vaultkeepr"
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = path_vault,
        data_vegvault_release = data_release,
        vec_trait_domain_names = "Plant heigh"
      ),
      regexp = "must belong to a VegVault dataset"
    )
  }
)

testthat::test_that(
  "load_trait_records_from_vegvault() stops on a duplicated dataset row",
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
        manifest_sha256 = "hash_accepted"
      )
    )

    DBI::dbWriteTable(
      conn = connection_vault,
      name = "Datasets",
      value = tibble::tibble(
        dataset_id = base::c(1L, 1L),
        data_source_id = base::c(10L, 11L)
      )
    )

    DBI::dbDisconnect(connection_vault)

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )

    data_records_fixture <-
      tibble::tibble(
        dataset_id = 1L,
        dataset_name = "bien_traits_1",
        sample_id = 11L,
        trait_id = 1L,
        taxon_id = 100L,
        trait_domain_name = "Plant heigh",
        trait_name = "whole plant height",
        trait_value = 1.5
      )

    testthat::local_mocked_bindings(
      open_vault = function(...) base::list(),
      get_datasets = function(con, ...) con,
      select_dataset_by_type = function(con, ...) con,
      get_samples = function(con, ...) con,
      get_traits = function(con, ...) con,
      select_traits_by_domain_name = function(con, ...) con,
      extract_data = function(...) data_records_fixture,
      .package = "vaultkeepr"
    )

    testthat::expect_error(
      load_trait_records_from_vegvault(
        path_vegvault = path_vault,
        data_vegvault_release = data_release,
        vec_trait_domain_names = "Plant heigh"
      ),
      regexp = "exactly one data source"
    )
  }
)
