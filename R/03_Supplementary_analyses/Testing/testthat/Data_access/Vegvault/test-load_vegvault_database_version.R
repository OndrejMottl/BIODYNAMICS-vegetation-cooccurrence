testthat::test_that(
  "load_vegvault_database_version() returns the current release record",
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
        id = base::c(4L, 5L),
        version = base::c("1.0.0", "2.0.0"),
        update_date = base::c("2025-01-20", "2026-11-25"),
        changelog = base::c("First release", "Second release"),
        build_profile = base::c(NA_character_, "release"),
        git_commit = base::c(NA_character_, "f19d588"),
        manifest_sha256 = base::c(NA_character_, "94516fdf")
      )
    )
    DBI::dbDisconnect(connection_vault)

    res <-
      load_vegvault_database_version(
        path_to_vegvault = path_vault,
        vegvault_version = "2.0.0"
      )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_named(
      res,
      base::c("vegvault_version", "git_commit", "manifest_sha256")
    )
    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_identical(
      dplyr::pull(res, vegvault_version),
      "2.0.0"
    )
    testthat::expect_identical(dplyr::pull(res, git_commit), "f19d588")
    testthat::expect_identical(
      dplyr::pull(res, manifest_sha256),
      "94516fdf"
    )
  }
)

testthat::test_that(
  "load_vegvault_database_version() orders releases by id, not text",
  {
    path_vault_newer_last <-
      withr::local_tempfile(fileext = ".sqlite")
    connection_vault_newer_last <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = path_vault_newer_last
      )
    DBI::dbWriteTable(
      conn = connection_vault_newer_last,
      name = "version_control",
      value = tibble::tibble(
        id = base::c(1L, 2L),
        version = base::c("2.9.0", "2.10.0"),
        git_commit = base::c("commit_a", "commit_b"),
        manifest_sha256 = base::c("hash_a", "hash_b")
      )
    )
    DBI::dbDisconnect(connection_vault_newer_last)

    path_vault_newer_first <-
      withr::local_tempfile(fileext = ".sqlite")
    connection_vault_newer_first <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = path_vault_newer_first
      )
    DBI::dbWriteTable(
      conn = connection_vault_newer_first,
      name = "version_control",
      value = tibble::tibble(
        id = base::c(1L, 2L),
        version = base::c("2.10.0", "2.9.0"),
        git_commit = base::c("commit_a", "commit_b"),
        manifest_sha256 = base::c("hash_a", "hash_b")
      )
    )
    DBI::dbDisconnect(connection_vault_newer_first)

    res_newer_last <-
      load_vegvault_database_version(
        path_to_vegvault = path_vault_newer_last,
        vegvault_version = "2.10.0"
      )

    res_newer_first <-
      load_vegvault_database_version(
        path_to_vegvault = path_vault_newer_first,
        vegvault_version = "2.9.0"
      )

    testthat::expect_identical(
      dplyr::pull(res_newer_last, vegvault_version),
      "2.10.0"
    )
    testthat::expect_identical(
      dplyr::pull(res_newer_last, git_commit),
      "commit_b"
    )
    testthat::expect_identical(
      dplyr::pull(res_newer_first, vegvault_version),
      "2.9.0"
    )
    testthat::expect_identical(
      dplyr::pull(res_newer_first, manifest_sha256),
      "hash_b"
    )
  }
)

testthat::test_that(
  "load_vegvault_database_version() skips rows without a version",
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
        id = base::c(1L, 2L, 3L),
        version = base::c("0.0.4", "1.0.0", NA_character_),
        update_date = base::c("2024-12-19", "2025-01-20", "2025-02-01")
      )
    )
    DBI::dbDisconnect(connection_vault)

    res <-
      load_vegvault_database_version(
        path_to_vegvault = path_vault,
        vegvault_version = "1.0.0"
      )

    testthat::expect_identical(
      dplyr::pull(res, vegvault_version),
      "1.0.0"
    )
  }
)

testthat::test_that(
  "load_vegvault_database_version() gives NA build fields before 2.0.0",
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
        id = base::c(3L, 4L),
        version = base::c("0.0.4", "1.0.0"),
        update_date = base::c("2024-12-19", "2025-01-20"),
        changelog = base::c("Update", "First release")
      )
    )
    DBI::dbDisconnect(connection_vault)

    res <-
      load_vegvault_database_version(
        path_to_vegvault = path_vault,
        vegvault_version = "1.0.0"
      )

    testthat::expect_named(
      res,
      base::c("vegvault_version", "git_commit", "manifest_sha256")
    )
    testthat::expect_identical(
      dplyr::pull(res, git_commit),
      NA_character_
    )
    testthat::expect_identical(
      dplyr::pull(res, manifest_sha256),
      NA_character_
    )
  }
)

testthat::test_that(
  "load_vegvault_database_version() stops on a version mismatch",
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
        id = base::c(3L, 4L),
        version = base::c("0.0.4", "1.0.0")
      )
    )
    DBI::dbDisconnect(connection_vault)

    testthat::expect_error(
      load_vegvault_database_version(
        path_to_vegvault = path_vault,
        vegvault_version = "2.0.0"
      ),
      class = "biodynamics_vegvault_version_mismatch"
    )

    testthat::expect_error(
      load_vegvault_database_version(
        path_to_vegvault = path_vault,
        vegvault_version = "2.0.0"
      ),
      regexp = "1\\.0\\.0.*2\\.0\\.0|2\\.0\\.0.*1\\.0\\.0"
    )
  }
)

testthat::test_that(
  "load_vegvault_database_version() stops without a version record",
  {
    path_vault_no_table <-
      withr::local_tempfile(fileext = ".sqlite")
    connection_vault_no_table <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = path_vault_no_table
      )
    DBI::dbWriteTable(
      conn = connection_vault_no_table,
      name = "Datasets",
      value = tibble::tibble(dataset_id = 1L)
    )
    DBI::dbDisconnect(connection_vault_no_table)

    path_vault_no_version <-
      withr::local_tempfile(fileext = ".sqlite")
    connection_vault_no_version <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = path_vault_no_version
      )
    DBI::dbWriteTable(
      conn = connection_vault_no_version,
      name = "version_control",
      value = tibble::tibble(
        id = 1L,
        version = NA_character_
      )
    )
    DBI::dbDisconnect(connection_vault_no_version)

    testthat::expect_error(
      load_vegvault_database_version(
        path_to_vegvault = path_vault_no_table,
        vegvault_version = "2.0.0"
      ),
      regexp = "version_control"
    )

    testthat::expect_error(
      load_vegvault_database_version(
        path_to_vegvault = path_vault_no_version,
        vegvault_version = "2.0.0"
      ),
      regexp = "version_control"
    )
  }
)

testthat::test_that(
  "load_vegvault_database_version() validates its arguments",
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
        id = 1L,
        version = "2.0.0"
      )
    )
    DBI::dbDisconnect(connection_vault)

    testthat::expect_error(
      load_vegvault_database_version(
        path_to_vegvault = 1,
        vegvault_version = "2.0.0"
      ),
      regexp = "path_to_vegvault"
    )

    testthat::expect_error(
      load_vegvault_database_version(
        path_to_vegvault = base::c(path_vault, path_vault),
        vegvault_version = "2.0.0"
      ),
      regexp = "path_to_vegvault"
    )

    testthat::expect_error(
      load_vegvault_database_version(
        path_to_vegvault = base::file.path(
          base::tempdir(),
          "no_such_vault.sqlite"
        ),
        vegvault_version = "2.0.0"
      ),
      regexp = "path_to_vegvault"
    )

    testthat::expect_error(
      load_vegvault_database_version(
        path_to_vegvault = path_vault,
        vegvault_version = 2
      ),
      regexp = "vegvault_version"
    )

    testthat::expect_error(
      load_vegvault_database_version(
        path_to_vegvault = path_vault,
        vegvault_version = NA_character_
      ),
      regexp = "vegvault_version"
    )

    testthat::expect_error(
      load_vegvault_database_version(
        path_to_vegvault = path_vault,
        vegvault_version = ""
      ),
      regexp = "vegvault_version"
    )

    testthat::expect_error(
      load_vegvault_database_version(
        path_to_vegvault = path_vault,
        vegvault_version = base::c("2.0.0", "2.0.0")
      ),
      regexp = "vegvault_version"
    )
  }
)

testthat::test_that(
  "load_vegvault_database_version() leaves the file unchanged",
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
        id = 1L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "94516fdf"
      )
    )
    DBI::dbDisconnect(connection_vault)

    hash_before <-
      digest::digest(
        object = path_vault,
        algo = "sha256",
        file = TRUE
      )

    res_first <-
      load_vegvault_database_version(
        path_to_vegvault = path_vault,
        vegvault_version = "2.0.0"
      )

    res_second <-
      load_vegvault_database_version(
        path_to_vegvault = path_vault,
        vegvault_version = "2.0.0"
      )

    hash_after <-
      digest::digest(
        object = path_vault,
        algo = "sha256",
        file = TRUE
      )

    testthat::expect_s3_class(res_first, "tbl_df")
    testthat::expect_identical(res_first, res_second)
    testthat::expect_identical(hash_before, hash_after)
  }
)
