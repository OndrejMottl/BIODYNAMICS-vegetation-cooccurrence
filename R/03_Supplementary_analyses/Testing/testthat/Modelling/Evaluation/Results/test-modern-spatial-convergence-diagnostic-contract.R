testthat::test_that(
  "modern convergence audit reads canonical fitted diagnostics",
  {
    list_expressions <-
      base::parse(file = here::here(
        "R/03_Supplementary_analyses/Sensitivity/Modelling/Spatial/Modern/",
        "tune_modern_spatial_convergence.R"))
    expr_convergence <-
      purrr::keep(list_expressions, ~ base::is.call(.x) &&
        base::identical(.x[[1L]], base::as.name("<-")) &&
        base::identical(.x[[2L]], base::as.name("data_convergence")))[[1L]]
    expr_non_converged <-
      purrr::keep(list_expressions, ~ base::is.call(.x) &&
        base::identical(.x[[1L]], base::as.name("<-")) &&
        base::identical(.x[[2L]], base::as.name("data_non_converged")))[[1L]]
    list_evaluation <-
      base::list(list_convergence_diagnostics = base::list(
        linear_trend_slope = 0.002, median_diff = 0.25,
        epochs_run = 400L, early_stopping_triggered = TRUE))
    environment_command <-
      base::new.env(parent = base::globalenv())
    environment_command[["data_store_index"]] <-
      tibble::tibble(data_source = "modern", scale = "continental",
        scale_id = "europe", pipeline_name = "unit_pipeline",
        store_path = "fixture_store", store_path_display = "fixture_store",
        store_exists = TRUE, data_meta = base::list(tibble::tibble(
          name = "list_jsdm_evaluation_fitted_genus", error = NA_character_)))
    environment_command[["vec_resolution_ids"]] <- "genus"
    environment_command[["threshold_linear_trend_slope"]] <- 0.01
    environment_command[["threshold_median_diff"]] <- 1
    environment_command[["load_model_evaluation_target"]] <- function(...) {
      return(list_evaluation)
    }
    data_convergence <-
      base::eval(expr = expr_convergence[[3L]], envir = environment_command)
    testthat::expect_identical(data_convergence[["linear_trend_slope"]],
      0.002)
    testthat::expect_identical(data_convergence[["median_diff"]], 0.25)
    testthat::expect_identical(data_convergence[["epochs_run"]], 400L)
    testthat::expect_identical(data_convergence[["early_stopping_triggered"]],
      TRUE)
    testthat::expect_identical(data_convergence[["converged"]], TRUE)
    list_evaluation[["list_convergence_diagnostics"]][[
      "linear_trend_slope"]] <- NA_real_
    environment_command[["data_convergence"]] <-
      base::eval(expr = expr_convergence[[3L]], envir = environment_command)
    data_unresolved <-
      base::eval(expr = expr_non_converged[[3L]], envir = environment_command)
    testthat::expect_equal(base::nrow(data_unresolved), 1L)
  }
)
