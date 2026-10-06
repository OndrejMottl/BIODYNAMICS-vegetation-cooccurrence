testthat::test_that(
  "run_sjsdm_tuning_sequence() repairs legacy tuning caches",
  {
    environment_test <- base::new.env(parent = base::emptyenv())
    environment_test[["diagnostic_calls"]] <- 0L
    environment_test[["invalidated"]] <- base::character()
    environment_test[["pipeline_calls"]] <- 0L

    run_pipeline_function <- function(...) {
      environment_test[["pipeline_calls"]] <-
        environment_test[["pipeline_calls"]] + 1L
      base::invisible(NULL)
    }
    diagnose_endpoints_function <- function(...) {
      environment_test[["diagnostic_calls"]] <-
        environment_test[["diagnostic_calls"]] + 1L
      if (environment_test[["diagnostic_calls"]] == 1L) {
        return(
          tibble::tibble(
            target_name = "summary_genus",
            endpoint_status = "cache_format_incompatible",
            data_hash = NA_character_,
            error_message = "there is no package called 'qs'"
          )
        )
      }
      tibble::tibble(
        target_name = "summary_genus",
        endpoint_status = "prepared",
        data_hash = "current_hash",
        error_message = NA_character_
      )
    }
    load_metadata_function <- function(...) {
      tibble::tibble(
        name = "failed_branch",
        error = paste(
          "could not load dependency 'formula_genus';",
          "there is no package called 'qs'"
        ),
        time = base::Sys.time()
      )
    }
    invalidate_target_function <- function(names, store) {
      environment_test[["invalidated"]] <- names
      base::invisible(NULL)
    }

    run_sjsdm_tuning_sequence(
      unit_pipeline = "R/Pipelines/pipeline_unit.R",
      tuning_target_names = "summary_genus",
      unit_store_suffixes = "unit_001",
      tuning_strategy = "exhaustive",
      n_rounds = 1L,
      run_pipeline_function = run_pipeline_function,
      has_tuning_evidence_function = function(...) TRUE,
      target_store = "Data/targets/test",
      load_metadata_function = load_metadata_function,
      diagnose_endpoints_function = diagnose_endpoints_function,
      read_target_function = function(...) NULL,
      invalidate_target_function = invalidate_target_function,
      validate_tuning_targets = TRUE
    )

    testthat::expect_setequal(
      environment_test[["invalidated"]],
      base::c(
        "summary_genus",
        "failed_branch",
        "formula_genus"
      )
    )
    testthat::expect_equal(
      environment_test[["diagnostic_calls"]],
      2L
    )
    testthat::expect_equal(
      environment_test[["pipeline_calls"]],
      3L
    )
  }
)

testthat::test_that(
  "run_sjsdm_tuning_unit_round() reports literal error braces",
  {
    data_status <-
      testthat::expect_message(
        run_sjsdm_tuning_unit_round(
          round_id = 1L,
          unit_pipeline = "R/Pipelines/pipeline_unit.R",
          tuning_target_names = "summary_genus",
          unit_store_suffixes = "unit_001",
          run_pipeline_function = function(...) {
            base::stop("Run {targets} first.")
          }
        ),
        "Run \\{targets\\} first"
      )

    testthat::expect_identical(
      data_status[["pipeline_status"]],
      "error"
    )
    testthat::expect_identical(
      data_status[["error_message"]],
      "Run {targets} first."
    )
  }
)
