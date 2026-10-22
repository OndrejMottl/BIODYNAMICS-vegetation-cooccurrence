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
testthat::test_that("tier rounds retain partial units without missing reads", {
  path_store <-
    withr::local_tempdir()
  list_requests <- base::list()
  list_evidence <- base::list()
  run_sjsdm_tuning_sequence(unit_pipeline = "pipeline.R",
    target_store = path_store, tuning_strategy = "exhaustive", n_rounds = 1L,
    tuning_target_names = base::c("summary_genus", "summary_family"),
    unit_store_suffixes = base::c("a", "b"),
    unit_target_names = base::list(a = "summary_family",
      b = base::character()),
    run_pipeline_function = function(sel_script, target_names = NULL,
        store_suffix = NULL, ...) {
      if (
        sel_script == "pipeline.R"
      ) {
        list_requests[[store_suffix]] <<- target_names
      }
    },
    has_tuning_evidence_function = function(store_paths, target_names) {
      list_evidence[[base::basename(base::dirname(store_paths))]] <<-
        target_names
      TRUE
    })
  testthat::expect_identical(list_requests, base::list(a = "summary_family"))
  testthat::expect_identical(list_evidence, base::list(a = "summary_family"))
  data_requests <-
    readr::read_csv(fs::path(path_store, "sjsdm_tier_unit_requests.csv"),
      show_col_types = FALSE)
  testthat::expect_identical(data_requests[["target_name"]], "summary_family")
})

testthat::test_that("unexplained production failure blocks tier selection", {
  flag_tier_called <- FALSE
  testthat::expect_error(
    run_sjsdm_tuning_sequence(unit_pipeline = "pipeline.R",
      target_store = "test_store", tuning_strategy = "exhaustive",
      n_rounds = 1L, tuning_target_names = "summary_genus",
      unit_store_suffixes = "a", validate_tuning_targets = TRUE,
      run_pipeline_function = function(sel_script, ...) {
        if (
          sel_script == "pipeline.R"
        ) {
          base::stop("unexpected GPU failure")
        }
        flag_tier_called <<- TRUE
      }),
    "Unexplained tuning failures"
  )
  testthat::expect_false(flag_tier_called)
})
