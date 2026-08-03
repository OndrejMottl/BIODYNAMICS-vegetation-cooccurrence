# ── Helpers ───────────────────────────────────────────────────────────── #

make_valid_raw <- function() {
  tibble::tibble(
    taxon_id = base::c(1L, 2L, NA_integer_, 3L),
    trait_domain_name = base::c("SLA", "SLA", "SLA", "Height"),
    trait_name = base::c("sla_mm", "sla_mm", "sla_mm", "h_m"),
    trait_value = base::c(10.0, NA_real_, 5.0, 2.0)
  )
}

# ── data_trait_records_raw type checks ────────────────────────────────── #

testthat::test_that(
  "filter_complete_trait_records() rejects non-data-frame records",
  {
    testthat::expect_error(
      filter_complete_trait_records(data_trait_records_raw = "not a df")
    )

    testthat::expect_error(
      filter_complete_trait_records(data_trait_records_raw = NULL)
    )

    testthat::expect_error(
      filter_complete_trait_records(data_trait_records_raw = 1L)
    )

    testthat::expect_error(
      filter_complete_trait_records(
        data_trait_records_raw = base::list(taxon_id = 1L)
      )
    )
  }
)

# ── Output structure ──────────────────────────────────────────────────── #

testthat::test_that(
  "filter_complete_trait_records() returns a data frame",
  {
    res <-
      filter_complete_trait_records(
        data_trait_records_raw =
          make_valid_raw()
      )
    testthat::expect_true(base::is.data.frame(res))
  }
)

testthat::test_that(
  "filter_complete_trait_records() returns expected column names",
  {
    res <-
      filter_complete_trait_records(
        data_trait_records_raw =
          make_valid_raw()
      )
    testthat::expect_true(
      "taxon_id" %in% base::colnames(res)
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

# ── NA filtering ──────────────────────────────────────────────────────── #

testthat::test_that(
  "filter_complete_trait_records() removes rows with NA taxon_id",
  {
    res <-
      filter_complete_trait_records(
        data_trait_records_raw =
          make_valid_raw()
    )
    testthat::expect_false(
      base::any(
        base::is.na(
          dplyr::pull(res, "taxon_id")
        )
      )
    )
  }
)

testthat::test_that(
  "filter_complete_trait_records() removes rows with NA trait_value",
  {
    res <-
      filter_complete_trait_records(
        data_trait_records_raw =
          make_valid_raw()
    )
    testthat::expect_false(
      base::any(
        base::is.na(
          dplyr::pull(res, "trait_value")
        )
      )
    )
  }
)

testthat::test_that(
  "filter_complete_trait_records() keeps correct number of rows",
  {
    # Four rows: one NA taxon_id and one NA trait_value.
    # -> 2 rows should survive
    res <-
      filter_complete_trait_records(
        data_trait_records_raw =
          make_valid_raw()
      )
    testthat::expect_equal(base::nrow(res), 2L)
  }
)

testthat::test_that(
  "filter_complete_trait_records() handles zero-row input without error",
  {
    data_empty <-
      tibble::tibble(
        taxon_id = base::integer(0),
        trait_domain_name = base::character(0),
        trait_name = base::character(0),
        trait_value = base::numeric(0)
      )
    res <-
      filter_complete_trait_records(data_trait_records_raw = data_empty)
    testthat::expect_equal(base::nrow(res), 0L)
  }
)

testthat::test_that(
  "filter_complete_trait_records() tolerates missing optional columns",
  {
    data_no_trait_name <-
      tibble::tibble(
        taxon_id = base::c(1L, 2L),
        trait_domain_name = base::c("SLA", "Height"),
        trait_value = base::c(10.0, 2.0)
      )
    testthat::expect_no_error(
      filter_complete_trait_records(data_trait_records_raw = data_no_trait_name)
    )
  }
)

testthat::test_that(
  "filter_complete_trait_records() returns all rows when no NAs present",
  {
    data_clean <-
      tibble::tibble(
        taxon_id = base::c(1L, 2L, 3L),
        trait_domain_name = base::c("SLA", "SLA", "Height"),
        trait_name = base::c("sla_mm", "sla_mm", "h_m"),
        trait_value = base::c(10.0, 12.0, 3.0)
      )
    res <-
      filter_complete_trait_records(data_trait_records_raw = data_clean)
    testthat::expect_equal(base::nrow(res), 3L)
  }
)
