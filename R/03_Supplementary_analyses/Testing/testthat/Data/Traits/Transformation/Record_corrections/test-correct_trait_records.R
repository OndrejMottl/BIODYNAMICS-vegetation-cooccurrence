testthat::test_that(
  "errors if data_trait_records is not a data frame",
  {
    data_trait_corrections_empty <-
      tibble::tibble(
        taxon_name = character(),
        trait_domain_name = character(),
        action = character(),
        scale_factor = numeric()
      )

    testthat::expect_error(
      correct_trait_records(
        data_trait_records = "not a data frame",
        data_trait_corrections = data_trait_corrections_empty
      )
    )

    testthat::expect_error(
      correct_trait_records(
        data_trait_records = NULL,
        data_trait_corrections = data_trait_corrections_empty
      )
    )

    testthat::expect_error(
      correct_trait_records(
        data_trait_records = base::c(1, 2, 3),
        data_trait_corrections = data_trait_corrections_empty
      )
    )
  }
)


testthat::test_that(
  "errors if data_trait_records missing required columns",
  {
    data_trait_corrections_empty <-
      tibble::tibble(
        taxon_name = character(),
        trait_domain_name = character(),
        action = character(),
        scale_factor = numeric()
      )

    testthat::expect_error(
      correct_trait_records(
        data_trait_records = tibble::tibble(
          trait_domain_name = "SLA",
          trait_value = 10
        ),
        data_trait_corrections = data_trait_corrections_empty
      )
    )

    testthat::expect_error(
      correct_trait_records(
        data_trait_records = tibble::tibble(
          taxon_name = "Quercus",
          trait_value = 10
        ),
        data_trait_corrections = data_trait_corrections_empty
      )
    )

    testthat::expect_error(
      correct_trait_records(
        data_trait_records = tibble::tibble(
          taxon_name = "Quercus",
          trait_domain_name = "SLA"
        ),
        data_trait_corrections = data_trait_corrections_empty
      )
    )
  }
)


testthat::test_that(
  "errors if data_trait_corrections is not a data frame",
  {
    data_trait_records_minimal <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        trait_value = 10
      )

    testthat::expect_error(
      correct_trait_records(
        data_trait_records = data_trait_records_minimal,
        data_trait_corrections = "not a data frame"
      )
    )

    testthat::expect_error(
      correct_trait_records(
        data_trait_records = data_trait_records_minimal,
        data_trait_corrections = NULL
      )
    )
  }
)


testthat::test_that(
  "errors if data_trait_corrections missing required columns",
  {
    data_trait_records_minimal <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        trait_value = 10
      )

    testthat::expect_error(
      correct_trait_records(
        data_trait_records = data_trait_records_minimal,
        data_trait_corrections = tibble::tibble(
          taxon_name = character(),
          trait_domain_name = character(),
          scale_factor = numeric()
        )
      )
    )

    testthat::expect_error(
      correct_trait_records(
        data_trait_records = data_trait_records_minimal,
        data_trait_corrections = tibble::tibble(
          taxon_name = character(),
          trait_domain_name = character(),
          action = character()
        )
      )
    )

    testthat::expect_error(
      correct_trait_records(
        data_trait_records = data_trait_records_minimal,
        data_trait_corrections = tibble::tibble(
          trait_domain_name = character(),
          action = character(),
          scale_factor = numeric()
        )
      )
    )

    testthat::expect_error(
      correct_trait_records(
        data_trait_records = data_trait_records_minimal,
        data_trait_corrections = tibble::tibble(
          taxon_name = character(),
          action = character(),
          scale_factor = numeric()
        )
      )
    )
  }
)


testthat::test_that(
  "returns a tibble with same columns as data_trait_records",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Pinus"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_value = base::c(10, 20)
      )

    data_trait_corrections_empty <-
      tibble::tibble(
        taxon_name = character(),
        trait_domain_name = character(),
        action = character(),
        scale_factor = numeric()
      )

    res <-
      correct_trait_records(
        data_trait_records = data_trait_records,
        data_trait_corrections = data_trait_corrections_empty
      )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_named(
      res,
      base::colnames(data_trait_records)
    )
  }
)


testthat::test_that(
  "exclude action removes matching rows",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Pinus", "Quercus"),
        trait_domain_name = base::c("SLA", "SLA", "Height"),
        trait_value = base::c(10, 20, 5)
      )

    data_trait_corrections <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        action = "exclude",
        scale_factor = NA_real_
      )

    res <-
      correct_trait_records(
        data_trait_records = data_trait_records,
        data_trait_corrections = data_trait_corrections
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_false(
      base::any(
        dplyr::pull(res, taxon_name) == "Quercus" &
          dplyr::pull(res, trait_domain_name) == "SLA"
      )
    )
  }
)


testthat::test_that(
  "non-matching rows are preserved after exclude",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Pinus"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_value = base::c(10, 20)
      )

    data_trait_corrections <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        action = "exclude",
        scale_factor = NA_real_
      )

    res <-
      correct_trait_records(
        data_trait_records = data_trait_records,
        data_trait_corrections = data_trait_corrections
      )

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(
      dplyr::pull(res, taxon_name),
      "Pinus"
    )
  }
)


testthat::test_that(
  "multiple exclude actions all take effect",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Pinus", "Betula"),
        trait_domain_name = base::c("SLA", "SLA", "SLA"),
        trait_value = base::c(10, 20, 30)
      )

    data_trait_corrections <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Pinus"),
        trait_domain_name = base::c("SLA", "SLA"),
        action = base::c("exclude", "exclude"),
        scale_factor = base::c(NA_real_, NA_real_)
      )

    res <-
      correct_trait_records(
        data_trait_records = data_trait_records,
        data_trait_corrections = data_trait_corrections
      )

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_equal(
      dplyr::pull(res, taxon_name),
      "Betula"
    )
  }
)


testthat::test_that(
  "scale action multiplies trait_value by scale_factor",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        trait_value = 10
      )

    data_trait_corrections <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        action = "scale",
        scale_factor = 2.0
      )

    res <-
      correct_trait_records(
        data_trait_records = data_trait_records,
        data_trait_corrections = data_trait_corrections
      )

    testthat::expect_equal(
      dplyr::pull(res, trait_value),
      20
    )
  }
)


testthat::test_that(
  "scale action applies to all matching records",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Quercus"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_value = base::c(10, 20)
      )

    data_trait_corrections <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        action = "scale",
        scale_factor = 3.0
      )

    res <-
      correct_trait_records(
        data_trait_records = data_trait_records,
        data_trait_corrections = data_trait_corrections
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_equal(
      dplyr::pull(res, trait_value),
      base::c(30, 60)
    )
  }
)


testthat::test_that(
  "scale_factor of 1.0 leaves trait_value unchanged",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        trait_value = 15.5
      )

    data_trait_corrections <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        action = "scale",
        scale_factor = 1.0
      )

    res <-
      correct_trait_records(
        data_trait_records = data_trait_records,
        data_trait_corrections = data_trait_corrections
      )

    testthat::expect_equal(
      dplyr::pull(res, trait_value),
      15.5
    )
  }
)


testthat::test_that(
  "unmatched correction emits a warning",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = "Pinus",
        trait_domain_name = "SLA",
        trait_value = 20
      )

    data_trait_corrections <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        action = "exclude",
        scale_factor = NA_real_
      )

    testthat::expect_warning(
      correct_trait_records(
        data_trait_records = data_trait_records,
        data_trait_corrections = data_trait_corrections
      )
    )
  }
)


testthat::test_that(
  "no warning when all corrections match trait records",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        trait_value = 10
      )

    data_trait_corrections <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        action = "exclude",
        scale_factor = NA_real_
      )

    testthat::expect_no_warning(
      correct_trait_records(
        data_trait_records = data_trait_records,
        data_trait_corrections = data_trait_corrections
      )
    )
  }
)


testthat::test_that(
  "empty corrections return data_trait_records unchanged",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Pinus"),
        trait_domain_name = base::c("SLA", "Height"),
        trait_value = base::c(10, 20)
      )

    data_trait_corrections_empty <-
      tibble::tibble(
        taxon_name = character(),
        trait_domain_name = character(),
        action = character(),
        scale_factor = numeric()
      )

    res <-
      correct_trait_records(
        data_trait_records = data_trait_records,
        data_trait_corrections = data_trait_corrections_empty
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_equal(
      dplyr::pull(res, trait_value),
      base::c(10, 20)
    )
  }
)


testthat::test_that(
  "mix of exclude and scale actions handled correctly",
  {
    data_trait_records <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Pinus", "Betula"),
        trait_domain_name = base::c("SLA", "SLA", "SLA"),
        trait_value = base::c(10, 20, 30)
      )

    data_trait_corrections <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Betula"),
        trait_domain_name = base::c("SLA", "SLA"),
        action = base::c("exclude", "scale"),
        scale_factor = base::c(NA_real_, 2.0)
      )

    res <-
      correct_trait_records(
        data_trait_records = data_trait_records,
        data_trait_corrections = data_trait_corrections
      )

    testthat::expect_equal(base::nrow(res), 2L)

    data_pinus_value <-
      dplyr::pull(
        dplyr::filter(res, taxon_name == "Pinus"),
        trait_value
      )
    testthat::expect_equal(data_pinus_value, 20)

    data_betula_value <-
      dplyr::pull(
        dplyr::filter(res, taxon_name == "Betula"),
        trait_value
      )
    testthat::expect_equal(data_betula_value, 60)
  }
)
