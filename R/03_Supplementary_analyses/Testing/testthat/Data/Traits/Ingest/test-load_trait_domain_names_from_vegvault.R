# Helper path – a minimal SQLite created and removed inside each
# DB-dependent test. Using a project-relative path so that
# validate_vegvault_presence() can resolve it via here::here().
path_test_db <-
  "R/03_Supplementary_analyses/Testing/testthat/trait_domains_test.sqlite"

# Release record matching the version_control row written into each
#   DB-dependent test database.
data_release_test <-
  tibble::tibble(
    vegvault_version = "2.0.0",
    git_commit = "f19d588",
    manifest_sha256 = "hash_accepted"
  )

# ----------------------------------------------------------#
# Input Validation -----
# ----------------------------------------------------------#

testthat::test_that(
  "load_trait_domain_names_from_vegvault() errors on non-char path",
  {
    testthat::expect_error(
      load_trait_domain_names_from_vegvault(
        path_vegvault = 123
      )
    )

    testthat::expect_error(
      load_trait_domain_names_from_vegvault(
        path_vegvault = TRUE
      )
    )

    testthat::expect_error(
      load_trait_domain_names_from_vegvault(
        path_vegvault = NULL
      )
    )
  }
)

testthat::test_that(
  "load_trait_domain_names_from_vegvault() errors on path length > 1",
  {
    testthat::expect_error(
      load_trait_domain_names_from_vegvault(
        path_vegvault = base::c("a.sqlite", "b.sqlite")
      )
    )
  }
)

testthat::test_that(
  "load_trait_domain_names_from_vegvault() errors on non-logical verbose",
  {
    testthat::expect_error(
      load_trait_domain_names_from_vegvault(
        path_vegvault = "any.sqlite",
        verbose = "yes"
      )
    )

    testthat::expect_error(
      load_trait_domain_names_from_vegvault(
        path_vegvault = "any.sqlite",
        verbose = 1L
      )
    )
  }
)

testthat::test_that(
  "load_trait_domain_names_from_vegvault() errors for missing database",
  {
    testthat::expect_error(
      load_trait_domain_names_from_vegvault(
        path_vegvault = "nonexistent_path.sqlite",
        verbose = FALSE
      )
    )
  }
)

# ----------------------------------------------------------#
# Output Structure -----
# ----------------------------------------------------------#

testthat::test_that(
  "load_trait_domain_names_from_vegvault() returns character vector",
  {
    conn <-
      DBI::dbConnect(
        RSQLite::SQLite(),
        here::here(path_test_db)
      )

    DBI::dbWriteTable(
      conn = conn,
      name = "TraitsDomain",
      value = base::data.frame(
        trait_domain_name = base::c("SLA", "Plant height"),
        stringsAsFactors = FALSE
      ),
      overwrite = TRUE
    )

    DBI::dbWriteTable(
      conn = conn,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      ),
      overwrite = TRUE
    )

    DBI::dbDisconnect(conn)

    result <-
      load_trait_domain_names_from_vegvault(
        path_vegvault = here::here(path_test_db),
        data_vegvault_release = data_release_test,
        verbose = FALSE
      )

    testthat::expect_type(result, "character")

    base::unlink(here::here(path_test_db))
  }
)

testthat::test_that(
  "load_trait_domain_names_from_vegvault() returns length >= 1",
  {
    conn <-
      DBI::dbConnect(
        RSQLite::SQLite(),
        here::here(path_test_db)
      )

    DBI::dbWriteTable(
      conn = conn,
      name = "TraitsDomain",
      value = base::data.frame(
        trait_domain_name = base::c("SLA", "Plant height"),
        stringsAsFactors = FALSE
      ),
      overwrite = TRUE
    )

    DBI::dbWriteTable(
      conn = conn,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      ),
      overwrite = TRUE
    )

    DBI::dbDisconnect(conn)

    result <-
      load_trait_domain_names_from_vegvault(
        path_vegvault = here::here(path_test_db),
        data_vegvault_release = data_release_test,
        verbose = FALSE
      )

    testthat::expect_true(base::length(result) >= 1L)

    base::unlink(here::here(path_test_db))
  }
)

# ----------------------------------------------------------#
# Functional Correctness -----
# ----------------------------------------------------------#

testthat::test_that(
  "load_trait_domain_names_from_vegvault() returns correct values",
  {
    vec_expected_domains <- base::c("SLA", "Plant height")

    conn <-
      DBI::dbConnect(
        RSQLite::SQLite(),
        here::here(path_test_db)
      )

    DBI::dbWriteTable(
      conn = conn,
      name = "TraitsDomain",
      value = base::data.frame(
        trait_domain_name = vec_expected_domains,
        stringsAsFactors = FALSE
      ),
      overwrite = TRUE
    )

    DBI::dbWriteTable(
      conn = conn,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      ),
      overwrite = TRUE
    )

    DBI::dbDisconnect(conn)

    result <-
      load_trait_domain_names_from_vegvault(
        path_vegvault = here::here(path_test_db),
        data_vegvault_release = data_release_test,
        verbose = FALSE
      )

    testthat::expect_true(
      base::all(vec_expected_domains %in% result)
    )

    base::unlink(here::here(path_test_db))
  }
)

testthat::test_that(
  "load_trait_domain_names_from_vegvault() filters out NA values",
  {
    conn <-
      DBI::dbConnect(
        RSQLite::SQLite(),
        here::here(path_test_db)
      )

    DBI::dbWriteTable(
      conn = conn,
      name = "TraitsDomain",
      value = base::data.frame(
        trait_domain_name = base::c("SLA", NA_character_),
        stringsAsFactors = FALSE
      ),
      overwrite = TRUE
    )

    DBI::dbWriteTable(
      conn = conn,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      ),
      overwrite = TRUE
    )

    DBI::dbDisconnect(conn)

    result <-
      load_trait_domain_names_from_vegvault(
        path_vegvault = here::here(path_test_db),
        data_vegvault_release = data_release_test,
        verbose = FALSE
      )

    testthat::expect_false(base::any(base::is.na(result)))

    base::unlink(here::here(path_test_db))
  }
)

testthat::test_that(
  "load_trait_domain_names_from_vegvault() errors when all NA",
  {
    conn <-
      DBI::dbConnect(
        RSQLite::SQLite(),
        here::here(path_test_db)
      )

    DBI::dbWriteTable(
      conn = conn,
      name = "TraitsDomain",
      value = base::data.frame(
        trait_domain_name = NA_character_,
        stringsAsFactors = FALSE
      ),
      overwrite = TRUE
    )

    DBI::dbWriteTable(
      conn = conn,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      ),
      overwrite = TRUE
    )

    DBI::dbDisconnect(conn)

    testthat::expect_error(
      load_trait_domain_names_from_vegvault(
        path_vegvault = here::here(path_test_db),
        data_vegvault_release = data_release_test,
        verbose = FALSE
      )
    )

    base::unlink(here::here(path_test_db))
  }
)

# ----------------------------------------------------------#
# Verbose Behavior -----
# ----------------------------------------------------------#

testthat::test_that(
  "verbose = FALSE suppresses console output",
  {
    conn <-
      DBI::dbConnect(
        RSQLite::SQLite(),
        here::here(path_test_db)
      )

    DBI::dbWriteTable(
      conn = conn,
      name = "TraitsDomain",
      value = base::data.frame(
        trait_domain_name = "SLA",
        stringsAsFactors = FALSE
      ),
      overwrite = TRUE
    )

    DBI::dbWriteTable(
      conn = conn,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      ),
      overwrite = TRUE
    )

    DBI::dbDisconnect(conn)

    testthat::expect_no_message(
      load_trait_domain_names_from_vegvault(
        path_vegvault = here::here(path_test_db),
        data_vegvault_release = data_release_test,
        verbose = FALSE
      )
    )

    base::unlink(here::here(path_test_db))
  }
)

testthat::test_that(
  "verbose = TRUE produces a console message",
  {
    conn <-
      DBI::dbConnect(
        RSQLite::SQLite(),
        here::here(path_test_db)
      )

    DBI::dbWriteTable(
      conn = conn,
      name = "TraitsDomain",
      value = base::data.frame(
        trait_domain_name = "SLA",
        stringsAsFactors = FALSE
      ),
      overwrite = TRUE
    )

    DBI::dbWriteTable(
      conn = conn,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_accepted"
      ),
      overwrite = TRUE
    )

    DBI::dbDisconnect(conn)

    testthat::expect_message(
      load_trait_domain_names_from_vegvault(
        path_vegvault = here::here(path_test_db),
        data_vegvault_release = data_release_test,
        verbose = TRUE
      )
    )

    base::unlink(here::here(path_test_db))
  }
)

# ----------------------------------------------------------#
# Release Check -----
# ----------------------------------------------------------#

testthat::test_that(
  "load_trait_domain_names_from_vegvault() stops on another release",
  {
    path_vault <-
      withr::local_tempfile(fileext = ".sqlite")

    conn <-
      DBI::dbConnect(
        RSQLite::SQLite(),
        path_vault
      )

    DBI::dbWriteTable(
      conn = conn,
      name = "TraitsDomain",
      value = base::data.frame(
        trait_domain_name = "SLA",
        stringsAsFactors = FALSE
      )
    )

    DBI::dbWriteTable(
      conn = conn,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0",
        git_commit = "f19d588",
        manifest_sha256 = "hash_rebuilt"
      )
    )

    DBI::dbDisconnect(conn)

    testthat::expect_error(
      load_trait_domain_names_from_vegvault(
        path_vegvault = path_vault,
        data_vegvault_release = data_release_test,
        verbose = FALSE
      ),
      class = "biodynamics_vegvault_release_mismatch"
    )
  }
)

testthat::test_that(
  "load_trait_domain_names_from_vegvault() requires the release record",
  {
    path_vault <-
      withr::local_tempfile(fileext = ".sqlite")

    conn <-
      DBI::dbConnect(
        RSQLite::SQLite(),
        path_vault
      )

    DBI::dbWriteTable(
      conn = conn,
      name = "TraitsDomain",
      value = base::data.frame(
        trait_domain_name = "SLA",
        stringsAsFactors = FALSE
      )
    )

    DBI::dbWriteTable(
      conn = conn,
      name = "version_control",
      value = tibble::tibble(
        id = 5L,
        version = "2.0.0"
      )
    )

    DBI::dbDisconnect(conn)

    testthat::expect_error(
      load_trait_domain_names_from_vegvault(
        path_vegvault = path_vault,
        verbose = FALSE
      ),
      regexp = "data_vegvault_release"
    )
  }
)
