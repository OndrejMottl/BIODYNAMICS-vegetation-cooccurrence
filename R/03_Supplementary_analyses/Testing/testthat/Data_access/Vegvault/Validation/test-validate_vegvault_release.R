testthat::test_that(
  "validate_vegvault_release() passes when the file holds the release",
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
        git_commit = base::c(NA_character_, "f19d588"),
        manifest_sha256 = base::c(NA_character_, "hash_accepted")
      )
    )
    DBI::dbDisconnect(connection_vault)

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )

    testthat::expect_invisible(
      validate_vegvault_release(
        path_to_vegvault = path_vault,
        data_vegvault_release = data_release
      )
    )

    res <-
      validate_vegvault_release(
        path_to_vegvault = path_vault,
        data_vegvault_release = data_release
      )

    testthat::expect_true(res)
  }
)

testthat::test_that(
  "validate_vegvault_release() stops on a rebuilt file of the same version",
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

    testthat::expect_error(
      validate_vegvault_release(
        path_to_vegvault = path_vault,
        data_vegvault_release = data_release
      ),
      class = "biodynamics_vegvault_release_mismatch"
    )

    testthat::expect_error(
      validate_vegvault_release(
        path_to_vegvault = path_vault,
        data_vegvault_release = data_release
      ),
      regexp = "manifest_sha256"
    )
  }
)

testthat::test_that(
  "validate_vegvault_release() stops on another version",
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
        id = 4L,
        version = "1.0.0"
      )
    )
    DBI::dbDisconnect(connection_vault)

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      )

    testthat::expect_error(
      validate_vegvault_release(
        path_to_vegvault = path_vault,
        data_vegvault_release = data_release
      ),
      class = "biodynamics_vegvault_version_mismatch"
    )
  }
)

testthat::test_that(
  "validate_vegvault_release() treats NA as equal only to NA",
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
        id = 4L,
        version = "1.0.0"
      )
    )
    DBI::dbDisconnect(connection_vault)

    data_release_without_build <-
      tibble::tibble(
        vegvault_version = "1.0.0",
        git_commit = NA_character_,
        manifest_sha256 = NA_character_
      )

    data_release_with_build <-
      tibble::tibble(
        vegvault_version = "1.0.0",
        git_commit = "f19d588",
        manifest_sha256 = NA_character_
      )

    res <-
      validate_vegvault_release(
        path_to_vegvault = path_vault,
        data_vegvault_release = data_release_without_build
      )

    testthat::expect_true(res)

    testthat::expect_error(
      validate_vegvault_release(
        path_to_vegvault = path_vault,
        data_vegvault_release = data_release_with_build
      ),
      class = "biodynamics_vegvault_release_mismatch"
    )
  }
)

testthat::test_that(
  "validate_vegvault_release() validates the release record",
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

    data_release <-
      tibble::tibble(
        vegvault_version = "2.0.0",
        git_commit = NA_character_,
        manifest_sha256 = NA_character_
      )

    testthat::expect_error(
      validate_vegvault_release(
        path_to_vegvault = path_vault,
        data_vegvault_release = base::as.list(data_release)
      ),
      regexp = "data_vegvault_release"
    )

    testthat::expect_error(
      validate_vegvault_release(
        path_to_vegvault = path_vault,
        data_vegvault_release = dplyr::select(data_release, -git_commit)
      ),
      regexp = "data_vegvault_release"
    )

    testthat::expect_error(
      validate_vegvault_release(
        path_to_vegvault = path_vault,
        data_vegvault_release = dplyr::bind_rows(data_release, data_release)
      ),
      regexp = "data_vegvault_release"
    )

    testthat::expect_error(
      validate_vegvault_release(
        path_to_vegvault = path_vault,
        data_vegvault_release = dplyr::mutate(
          data_release,
          vegvault_version = NA_character_
        )
      ),
      regexp = "data_vegvault_release"
    )

    testthat::expect_error(
      validate_vegvault_release(
        path_to_vegvault = base::file.path(
          base::tempdir(),
          "no_such_vault.sqlite"
        ),
        data_vegvault_release = data_release
      ),
      regexp = "path_to_vegvault"
    )
  }
)
