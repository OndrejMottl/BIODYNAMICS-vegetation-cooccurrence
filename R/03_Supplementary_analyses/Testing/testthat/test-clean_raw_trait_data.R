# ── Helpers ───────────────────────────────────────────────────────────── #

make_valid_raw <- function() {
  tibble::tibble(
    taxon_id = base::c(1L, 2L, NA_integer_, 3L),
    trait_domain_name = base::c("SLA", "SLA", "SLA", "Height"),
    trait_name = base::c("sla_mm", "sla_mm", "sla_mm", "h_m"),
    trait_value = base::c(10.0, NA_real_, 5.0, 2.0)
  )
}

# ── data_raw type checks ──────────────────────────────────────────────── #

testthat::test_that(
  "clean_raw_trait_data() errors when data_raw is not a data frame",
  {
    testthat::expect_error(
      clean_raw_trait_data(data_raw = "not a df")
    )

    testthat::expect_error(
      clean_raw_trait_data(data_raw = NULL)
    )

    testthat::expect_error(
      clean_raw_trait_data(data_raw = 1L)
    )

    testthat::expect_error(
      clean_raw_trait_data(data_raw = base::list(taxon_id = 1L))
    )
  }
)

# ── Output structure ──────────────────────────────────────────────────── #

testthat::test_that(
  "clean_raw_trait_data() returns a data frame",
  {
    res <-
      clean_raw_trait_data(data_raw = make_valid_raw())
    testthat::expect_true(base::is.data.frame(res))
  }
)

testthat::test_that(
  "clean_raw_trait_data() returns expected column names",
  {
    res <-
      clean_raw_trait_data(data_raw = make_valid_raw())
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
  "clean_raw_trait_data() removes rows with NA taxon_id",
  {
    res <-
      clean_raw_trait_data(data_raw = make_valid_raw())
    testthat::expect_false(
      base::any(base::is.na(dplyr::pull(res, "taxon_id")))
    )
  }
)

testthat::test_that(
  "clean_raw_trait_data() removes rows with NA trait_value",
  {
    res <-
      clean_raw_trait_data(data_raw = make_valid_raw())
    testthat::expect_false(
      base::any(base::is.na(dplyr::pull(res, "trait_value")))
    )
  }
)

testthat::test_that(
  "clean_raw_trait_data() keeps correct number of rows",
  {
    # make_valid_raw() has 4 rows: one NA taxon_id, one NA trait_value
    # → 2 rows should survive
    res <-
      clean_raw_trait_data(data_raw = make_valid_raw())
    testthat::expect_equal(base::nrow(res), 2L)
  }
)

testthat::test_that(
  "clean_raw_trait_data() handles zero-row input without error",
  {
    data_empty <-
      tibble::tibble(
        taxon_id = base::integer(0),
        trait_domain_name = base::character(0),
        trait_name = base::character(0),
        trait_value = base::numeric(0)
      )
    res <-
      clean_raw_trait_data(data_raw = data_empty)
    testthat::expect_equal(base::nrow(res), 0L)
  }
)

testthat::test_that(
  "clean_raw_trait_data() tolerates missing optional columns",
  {
    data_no_trait_name <-
      tibble::tibble(
        taxon_id = base::c(1L, 2L),
        trait_domain_name = base::c("SLA", "Height"),
        trait_value = base::c(10.0, 2.0)
      )
    testthat::expect_no_error(
      clean_raw_trait_data(data_raw = data_no_trait_name)
    )
  }
)

testthat::test_that(
  "clean_raw_trait_data() returns all rows when no NAs present",
  {
    data_clean <-
      tibble::tibble(
        taxon_id = base::c(1L, 2L, 3L),
        trait_domain_name = base::c("SLA", "SLA", "Height"),
        trait_name = base::c("sla_mm", "sla_mm", "h_m"),
        trait_value = base::c(10.0, 12.0, 3.0)
      )
    res <-
      clean_raw_trait_data(data_raw = data_clean)
    testthat::expect_equal(base::nrow(res), 3L)
  }
)
