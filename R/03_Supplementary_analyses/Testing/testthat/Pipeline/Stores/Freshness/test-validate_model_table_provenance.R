build_test_provenance_table <- function() {
  tibble::tibble(
    availability_status = base::c("available", "missing_model"),
    regularization_source = base::c("unit_cv", NA_character_),
    candidate_id = base::c("candidate_001", NA_character_),
    cv_strategy = base::c("grouped_kfold", NA_character_),
    final_model_built_at = base::as.POSIXct(
      base::c("2026-11-16 10:00:00", NA),
      tz = "UTC"
    ),
    variance_partition_built_at = base::as.POSIXct(
      base::c("2026-11-16 11:00:00", NA),
      tz = "UTC"
    ),
    vegvault_version = base::c("2.0.0", NA_character_)
  )
}

testthat::test_that(
  "validate_model_table_provenance() checks only available rows",
  {
    data_table <-
      build_test_provenance_table()

    testthat::expect_invisible(
      validate_model_table_provenance(
        data_table = data_table,
        availability_column = "availability_status"
      )
    )
    testthat::expect_error(
      validate_model_table_provenance(data_table = data_table),
      class = "model_table_provenance_missing_values"
    )
  }
)

testthat::test_that(
  "validate_model_table_provenance() requires the provenance columns",
  {
    testthat::expect_error(
      validate_model_table_provenance(
        data_table = build_test_provenance_table() |>
          dplyr::select(-"final_model_built_at"),
        table_label = "paleo table"
      ),
      class = "model_table_provenance_missing_columns"
    )
  }
)

testthat::test_that(
  "validate_model_table_provenance() requires the VegVault version",
  {
    testthat::expect_error(
      validate_model_table_provenance(
        data_table = build_test_provenance_table() |>
          dplyr::select(-"vegvault_version"),
        availability_column = "availability_status"
      ),
      class = "model_table_provenance_missing_columns"
    )

    testthat::expect_error(
      validate_model_table_provenance(
        data_table = build_test_provenance_table() |>
          dplyr::mutate(vegvault_version = NA_character_),
        availability_column = "availability_status"
      ),
      class = "model_table_provenance_missing_values"
    )
  }
)

testthat::test_that(
  "validate_model_table_provenance() rejects empty strings",
  {
    testthat::expect_error(
      validate_model_table_provenance(
        data_table = tibble::tibble(candidate_id = ""),
        vec_required_columns = "candidate_id"
      ),
      class = "model_table_provenance_missing_values"
    )
  }
)

testthat::test_that(
  "validate_model_table_provenance() validates its arguments",
  {
    testthat::expect_error(
      validate_model_table_provenance(data_table = "table"),
      "data frame"
    )
    testthat::expect_error(
      validate_model_table_provenance(
        data_table = build_test_provenance_table(),
        availability_column = "no_such_column"
      ),
      "availability_column"
    )
  }
)
