# Helper path – a minimal SQLite created and removed inside each
# DB-dependent test. Using a project-relative path so that
# check_presence_of_vegvault() can resolve it via here::here().
path_test_db <-
  "R/03_Supplementary_analyses/testthat/trait_domains_test.sqlite"

# ----------------------------------------------------------#
# Input Validation -----
# ----------------------------------------------------------#

testthat::test_that(
  "get_trait_domain_names_from_vegvault() errors on non-char path",
  {
    testthat::expect_error(
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = 123
      )
    )

    testthat::expect_error(
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = TRUE
      )
    )

    testthat::expect_error(
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = NULL
      )
    )
  }
)

testthat::test_that(
  "get_trait_domain_names_from_vegvault() errors on path length > 1",
  {
    testthat::expect_error(
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = base::c("a.sqlite", "b.sqlite")
      )
    )
  }
)

testthat::test_that(
  "get_trait_domain_names_from_vegvault() errors on non-logical verbose",
  {
    testthat::expect_error(
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = "any.sqlite",
        verbose = "yes"
      )
    )

    testthat::expect_error(
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = "any.sqlite",
        verbose = 1L
      )
    )
  }
)

testthat::test_that(
  "get_trait_domain_names_from_vegvault() errors for missing database",
  {
    testthat::expect_error(
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = "nonexistent_path.sqlite",
        verbose = FALSE
      )
    )
  }
)

# ----------------------------------------------------------#
# Output Structure -----
# ----------------------------------------------------------#

testthat::test_that(
  "get_trait_domain_names_from_vegvault() returns character vector",
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

    DBI::dbDisconnect(conn)

    result <-
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = here::here(path_test_db),
        verbose = FALSE
      )

    testthat::expect_type(result, "character")

    base::unlink(here::here(path_test_db))
  }
)

testthat::test_that(
  "get_trait_domain_names_from_vegvault() returns length >= 1",
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

    DBI::dbDisconnect(conn)

    result <-
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = here::here(path_test_db),
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
  "get_trait_domain_names_from_vegvault() returns correct values",
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

    DBI::dbDisconnect(conn)

    result <-
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = here::here(path_test_db),
        verbose = FALSE
      )

    testthat::expect_true(
      base::all(vec_expected_domains %in% result)
    )

    base::unlink(here::here(path_test_db))
  }
)

testthat::test_that(
  "get_trait_domain_names_from_vegvault() filters out NA values",
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

    DBI::dbDisconnect(conn)

    result <-
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = here::here(path_test_db),
        verbose = FALSE
      )

    testthat::expect_false(base::any(base::is.na(result)))

    base::unlink(here::here(path_test_db))
  }
)

testthat::test_that(
  "get_trait_domain_names_from_vegvault() errors when all NA",
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

    DBI::dbDisconnect(conn)

    testthat::expect_error(
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = here::here(path_test_db),
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

    DBI::dbDisconnect(conn)

    testthat::expect_no_message(
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = here::here(path_test_db),
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

    DBI::dbDisconnect(conn)

    testthat::expect_message(
      get_trait_domain_names_from_vegvault(
        path_to_vegvault = here::here(path_test_db),
        verbose = TRUE
      )
    )

    base::unlink(here::here(path_test_db))
  }
)
