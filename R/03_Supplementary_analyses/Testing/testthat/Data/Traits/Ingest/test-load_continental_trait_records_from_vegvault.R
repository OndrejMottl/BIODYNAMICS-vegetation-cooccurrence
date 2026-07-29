# ── Helpers ──────────────────────────────────────────────────────────────── #

# Minimal valid single-row data frame matching what the dynamic branch
# passes into the function.
make_continental_unit <- function() {
  tibble::tibble(
    scale_id = "europe",
    x_min = -25.0,
    x_max = 45.0,
    y_min = 35.0,
    y_max = 72.0
  )
}

vec_valid_domains <- base::c("SLA", "Plant height")
path_fake <- "nonexistent.sqlite"

# ── data_continental_unit ─────────────────────────────────────────────────

testthat::test_that(
  "load_continental_trait_records_from_vegvault() errors for non-df rows",
  {
    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = "europe",
        vec_trait_domain_names = vec_valid_domains,
        path_vegvault = path_fake,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = NULL,
        vec_trait_domain_names = vec_valid_domains,
        path_vegvault = path_fake,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = 1L,
        vec_trait_domain_names = vec_valid_domains,
        path_vegvault = path_fake,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "load_continental_trait_records_from_vegvault() errors for missing cols",
  {
    data_missing_col <-
      tibble::tibble(
        scale_id = "europe",
        x_min = -25.0,
        x_max = 45.0,
        y_min = 35.0
        # y_max is missing
      )

    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = data_missing_col,
        vec_trait_domain_names = vec_valid_domains,
        path_vegvault = path_fake,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "load_continental_trait_records_from_vegvault() errors for zero-row df",
  {
    data_empty <-
      tibble::tibble(
        scale_id = base::character(0),
        x_min = base::numeric(0),
        x_max = base::numeric(0),
        y_min = base::numeric(0),
        y_max = base::numeric(0)
      )

    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = data_empty,
        vec_trait_domain_names = vec_valid_domains,
        path_vegvault = path_fake,
        verbose = FALSE
      )
    )
  }
)

# ── vec_trait_domain_names ────────────────────────────────────────────────

testthat::test_that(
  "load_continental_trait_records_from_vegvault() errors for non-char domains",
  {
    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = make_continental_unit(),
        vec_trait_domain_names = 123,
        path_vegvault = path_fake,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = make_continental_unit(),
        vec_trait_domain_names = NULL,
        path_vegvault = path_fake,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = make_continental_unit(),
        vec_trait_domain_names = base::character(0),
        path_vegvault = path_fake,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = make_continental_unit(),
        vec_trait_domain_names = TRUE,
        path_vegvault = path_fake,
        verbose = FALSE
      )
    )
  }
)

# ── path_vegvault ──────────────────────────────────────────────────────

testthat::test_that(
  "load_continental_trait_records_from_vegvault() errors for non-char path",
  {
    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = make_continental_unit(),
        vec_trait_domain_names = vec_valid_domains,
        path_vegvault = 123,
        verbose = FALSE
      )
    )

    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = make_continental_unit(),
        vec_trait_domain_names = vec_valid_domains,
        path_vegvault = TRUE,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "load_continental_trait_records_from_vegvault() errors for path length > 1",
  {
    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = make_continental_unit(),
        vec_trait_domain_names = vec_valid_domains,
        path_vegvault = base::c("a.sqlite", "b.sqlite"),
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "load_continental_trait_records_from_vegvault() errors for missing db file",
  {
    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = make_continental_unit(),
        vec_trait_domain_names = vec_valid_domains,
        path_vegvault = "nonexistent_path.sqlite",
        verbose = FALSE
      )
    )
  }
)

# ── verbose ────────────────────────────────────────────────────────────────

testthat::test_that(
  "continental trait loading rejects non-logical verbose",
  {
    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = make_continental_unit(),
        vec_trait_domain_names = vec_valid_domains,
        path_vegvault = path_fake,
        verbose = "yes"
      )
    )

    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = make_continental_unit(),
        vec_trait_domain_names = vec_valid_domains,
        path_vegvault = path_fake,
        verbose = 1L
      )
    )

    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = make_continental_unit(),
        vec_trait_domain_names = vec_valid_domains,
        path_vegvault = path_fake,
        verbose = NULL
      )
    )
  }
)

testthat::test_that(
  "continental trait loading rejects multiple verbose values",
  {
    testthat::expect_error(
      load_continental_trait_records_from_vegvault(
        data_continental_unit = make_continental_unit(),
        vec_trait_domain_names = vec_valid_domains,
        path_vegvault = path_fake,
        verbose = base::c(TRUE, FALSE)
      )
    )
  }
)
