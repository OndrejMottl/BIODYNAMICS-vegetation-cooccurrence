# ── Helpers ───────────────────────────────────────────────────────────── #

make_clean_traits <- function() {
  tibble::tibble(
    taxon_id = base::c(1L, 2L, 3L),
    trait_domain_name = base::c("SLA", "SLA", "Height"),
    trait_name = base::c("sla_mm", "sla_mm", "h_m"),
    trait_value = base::c(10.0, 12.0, 3.0)
  )
}

path_fake <- "nonexistent.sqlite"

# ── data_clean type checks ────────────────────────────────────────────── #

testthat::test_that(
  "resolve_trait_taxon_ids() errors when data_clean not a data frame",
  {
    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_clean = "not a df",
        path_to_vegvault = path_fake
      )
    )

    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_clean = NULL,
        path_to_vegvault = path_fake
      )
    )

    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_clean = 1L,
        path_to_vegvault = path_fake
      )
    )
  }
)

testthat::test_that(
  "resolve_trait_taxon_ids() errors when taxon_id column missing",
  {
    data_no_id <-
      tibble::tibble(
        trait_domain_name = "SLA",
        trait_value = 10.0
      )
    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_clean = data_no_id,
        path_to_vegvault = path_fake
      )
    )
  }
)

# ── path_to_vegvault checks ───────────────────────────────────────────── #

testthat::test_that(
  "resolve_trait_taxon_ids() errors for non-character path",
  {
    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_clean = make_clean_traits(),
        path_to_vegvault = 123
      )
    )

    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_clean = make_clean_traits(),
        path_to_vegvault = TRUE
      )
    )
  }
)

testthat::test_that(
  "resolve_trait_taxon_ids() errors for path length > 1",
  {
    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_clean = make_clean_traits(),
        path_to_vegvault = base::c("a.sqlite", "b.sqlite")
      )
    )
  }
)

testthat::test_that(
  "resolve_trait_taxon_ids() errors for missing db file",
  {
    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_clean = make_clean_traits(),
        path_to_vegvault = "nonexistent_path.sqlite"
      )
    )
  }
)

# ── Output structure ──────────────────────────────────────────────────── #

testthat::test_that(
  "resolve_trait_taxon_ids() output has no taxon_id column",
  {
    # We can only verify column names by using a mock/temp SQLite DB
    tmp_db <-
      base::tempfile(fileext = ".sqlite")

    con <-
      DBI::dbConnect(RSQLite::SQLite(), tmp_db)

    DBI::dbWriteTable(
      con,
      "Taxa",
      tibble::tibble(
        taxon_id = base::c(1L, 2L, 3L),
        taxon_name = base::c("Quercus", "Betula", "Pinus")
      )
    )

    DBI::dbDisconnect(con)

    res <-
      resolve_trait_taxon_ids(
        data_clean = make_clean_traits(),
        path_to_vegvault = tmp_db
      )

    testthat::expect_false(
      "taxon_id" %in% base::colnames(res)
    )

    testthat::expect_true(
      "taxon_name" %in% base::colnames(res)
    )

    testthat::expect_true(
      "trait_domain_name" %in% base::colnames(res)
    )

    testthat::expect_true(
      "trait_name" %in% base::colnames(res)
    )

    testthat::expect_true(
      "trait_value" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "resolve_trait_taxon_ids() returns correct taxon names",
  {
    tmp_db <-
      base::tempfile(fileext = ".sqlite")

    con <-
      DBI::dbConnect(RSQLite::SQLite(), tmp_db)

    DBI::dbWriteTable(
      con,
      "Taxa",
      tibble::tibble(
        taxon_id = base::c(1L, 2L, 3L),
        taxon_name = base::c("Quercus", "Betula", "Pinus")
      )
    )

    DBI::dbDisconnect(con)

    res <-
      resolve_trait_taxon_ids(
        data_clean = make_clean_traits(),
        path_to_vegvault = tmp_db
      )

    testthat::expect_equal(
      base::sort(dplyr::pull(res, "taxon_name")),
      base::c("Betula", "Pinus", "Quercus")
    )
  }
)

testthat::test_that(
  "resolve_trait_taxon_ids() returns same row count as input",
  {
    tmp_db <-
      base::tempfile(fileext = ".sqlite")

    con <-
      DBI::dbConnect(RSQLite::SQLite(), tmp_db)

    DBI::dbWriteTable(
      con,
      "Taxa",
      tibble::tibble(
        taxon_id = base::c(1L, 2L, 3L),
        taxon_name = base::c("Quercus", "Betula", "Pinus")
      )
    )

    DBI::dbDisconnect(con)

    data_input <-
      make_clean_traits()

    res <-
      resolve_trait_taxon_ids(
        data_clean = data_input,
        path_to_vegvault = tmp_db
      )

    testthat::expect_equal(
      base::nrow(res),
      base::nrow(data_input)
    )
  }
)

testthat::test_that(
  "resolve_trait_taxon_ids() returns a data frame",
  {
    tmp_db <-
      base::tempfile(fileext = ".sqlite")

    con <-
      DBI::dbConnect(RSQLite::SQLite(), tmp_db)

    DBI::dbWriteTable(
      con,
      "Taxa",
      tibble::tibble(
        taxon_id = 1L,
        taxon_name = "Quercus"
      )
    )

    DBI::dbDisconnect(con)

    data_one <-
      tibble::tibble(
        taxon_id = 1L,
        trait_domain_name = "SLA",
        trait_name = "sla_mm",
        trait_value = 10.0
      )

    res <-
      resolve_trait_taxon_ids(
        data_clean = data_one,
        path_to_vegvault = tmp_db
      )

    testthat::expect_true(base::is.data.frame(res))
  }
)
