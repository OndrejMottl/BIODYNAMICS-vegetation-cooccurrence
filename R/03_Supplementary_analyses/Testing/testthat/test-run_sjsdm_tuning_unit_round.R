testthat::test_that(
  "run_sjsdm_tuning_unit_round() sets the cumulative round",
  {
    captured_round <- NA_character_
    run_sjsdm_tuning_unit_round(
      round_id = 2L,
      unit_pipeline = "unit.R",
      tuning_target_names = "summary",
      run_pipeline_function = function(...) {
        captured_round <<-
          base::Sys.getenv("SJSMD_TUNING_MAX_ROUND")
      }
    )
    testthat::expect_identical(captured_round, "2")
  }
)

testthat::test_that(
  "run_sjsdm_tuning_unit_round() continues after a failed unit",
  {
    vec_calls <- base::character()
    res <-
      testthat::expect_message(
        run_sjsdm_tuning_unit_round(
          round_id = 1L,
          unit_pipeline = "unit.R",
          tuning_target_names = "summary",
          unit_store_suffixes = base::c("unit_a", "unit_b"),
          run_pipeline_function = function(store_suffix, ...) {
            vec_calls <<- base::c(vec_calls, store_suffix)
            if (
              store_suffix == "unit_a"
            ) {
              base::stop("not enough taxa")
            }
          }
        ),
        "Skipping failed tuning unit unit_a"
      )

    testthat::expect_identical(vec_calls, base::c("unit_a", "unit_b"))
    testthat::expect_identical(
      res[["pipeline_status"]],
      base::c("error", "ok")
    )
    testthat::expect_identical(
      res[["error_message"]],
      base::c("not enough taxa", NA_character_)
    )
  }
)
testthat::test_that("tuning rounds request only verified viable targets", {
  list_calls <- base::list()
  res <-
    run_sjsdm_tuning_unit_round(round_id = 1L,
      unit_pipeline = "pipeline.R",
      tuning_target_names = base::c("tune_genus", "tune_family"),
      unit_store_suffixes = base::c("a", "b"),
      unit_target_names = base::list(a = "tune_family",
        b = base::character()),
      run_pipeline_function = function(store_suffix, target_names, ...) {
        list_calls[[store_suffix]] <<- target_names
      }, verbose = FALSE)
  testthat::expect_identical(list_calls, base::list(a = "tune_family"))
  testthat::expect_identical(res[["pipeline_status"]],
    base::c("ok", "expected_infeasible"))
})

testthat::test_that("tuning rounds retain typed failures and real errors", {
  res <-
    run_sjsdm_tuning_unit_round(round_id = 1L, unit_pipeline = "pipeline.R",
      tuning_target_names = "tune_genus",
      unit_store_suffixes = base::c("a", "b"),
      run_pipeline_function = function(store_suffix, ...) {
        if (
          store_suffix == "a"
        ) {
          rlang::abort("No taxa", "sjsdm_unit_expected_infeasible")
        }
        base::stop("unexpected failure")
      }, verbose = FALSE)
  testthat::expect_identical(res[["pipeline_status"]],
    base::c("expected_infeasible", "error"))
})
