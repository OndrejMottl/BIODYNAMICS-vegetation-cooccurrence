testthat::test_that("fitting preflight preserves viable resolutions", {
  data_metadata <-
    tibble::tibble(
      name = "data_community_rare_filtered_genus",
      error = "No taxa found in data. The minimum_proportion is too high."
    )
  vec_calls <- base::character()
  res <-
    run_sjsdm_unit_fitting_preflight(
      unit_pipeline = "pipeline.R",
      target_store = "stores",
      scale_ids = "unit_a",
      resolution_ids = base::c("genus", "family"),
      load_metadata_function = function(...) data_metadata,
      diagnose_endpoints_function = function(target_names, ...) {
        tibble::tibble(target_name = target_names,
          endpoint_status = "prepared", data_hash = "current")
      },
      run_pipeline_function = function(target_names, ...) {
        vec_calls <<- base::c(vec_calls, target_names)
        rlang::abort("No taxa remain", "sjsdm_unit_expected_infeasible")
      },
      verbose = FALSE
    )
  testthat::expect_identical(res[["fitting_status"]],
    base::c("expected_infeasible", "eligible"))
  testthat::expect_identical(vec_calls,
    "data_community_rare_filtered_genus")
})

testthat::test_that("shared failure is revalidated once per unit", {
  n_calls <- 0L
  res <-
    run_sjsdm_unit_fitting_preflight(
      unit_pipeline = "pipeline.R",
      target_store = "stores",
      scale_ids = "unit_a",
      resolution_ids = base::c("genus", "family"),
      load_metadata_function = function(...) tibble::tibble(
        name = "list_abiotic_collinearity",
        error = stringr::str_c("No columns with non-zero variance remain ",
          "after removing constant columns.")),
      run_pipeline_function = function(...) {
        n_calls <<- n_calls + 1L
        rlang::abort("Constant predictors", "sjsdm_unit_expected_infeasible")
      },
      diagnose_endpoints_function = function(...) base::stop("not needed"),
      verbose = FALSE
    )
  testthat::expect_identical(n_calls, 1L)
  testthat::expect_identical(res[["fitting_status"]],
    base::rep("expected_infeasible", 2L))
})

testthat::test_that("stale exclusions and unexplained errors block fitting", {
  data_metadata <-
    tibble::tibble(name = "data_community_rare_filtered_genus",
      error = "No taxa found in data. The minimum_proportion is too high.")
  for (
    flag_failure in base::c(FALSE, TRUE)
  ) {
    testthat::expect_error(
      run_sjsdm_unit_fitting_preflight(
        unit_pipeline = "pipeline.R", target_store = "stores",
        scale_ids = "unit_a", resolution_ids = "genus",
        load_metadata_function = function(...) data_metadata,
        run_pipeline_function = function(...) {
          if (
            flag_failure
          ) {
            base::stop("unexpected backend failure")
          }
        },
        verbose = FALSE
      ),
      "stage 01|01_Preparation"
    )
  }
})

testthat::test_that("missing folds block without executing production", {
  testthat::expect_error(
    run_sjsdm_unit_fitting_preflight(
      unit_pipeline = "pipeline.R", target_store = "stores",
      scale_ids = "unit_a", resolution_ids = "genus",
      load_metadata_function = function(...) tibble::tibble(
        name = base::character(), error = base::character()),
      diagnose_endpoints_function = function(target_names, ...) {
        tibble::tibble(target_name = target_names,
          endpoint_status = "missing", data_hash = NA_character_)
      },
      run_pipeline_function = function(...) base::stop("must not run"),
      verbose = FALSE
    ),
    "01_Preparation"
  )
})
testthat::test_that("warm failures exclude only their own fitting branch", {
  path_root <-
    withr::local_tempdir()
  path_script <-
    fs::path(path_root, "pipeline_fixture.R")
  path_input <-
    fs::path(path_root, "input.rds")
  base::saveRDS(FALSE, path_input)
  vec_script <-
    base::c(
      "targets::tar_option_set(format = 'qs', error = 'continue')",
      "list(",
      "targets::tar_target(file_input, INPUT, format = 'file'),",
      "targets::tar_target(data_community_rare_filtered_genus, {",
      "if (!readRDS(file_input)) stop(",
      "'No taxa found in data. The minimum_proportion is too high.')",
      "1L }),",
      "targets::tar_target(list_sjsdm_prepared_tuning_folds_genus,",
      "list(data_community_rare_filtered_genus)),",
      "targets::tar_target(list_sjsdm_prepared_tuning_folds_family,",
      "list(1L)),",
      "targets::tar_target(mod_jsdm_family,",
      "length(list_sjsdm_prepared_tuning_folds_family)),",
      "targets::tar_target(mod_jsdm_genus,",
      "length(list_sjsdm_prepared_tuning_folds_genus)))"
    )
  vec_script_prepared <-
    stringr::str_replace_all(vec_script, "INPUT",
      stringr::str_c("'", path_input, "'"))
  base::writeLines(vec_script_prepared, path_script)
  rlang::local_bindings(
    load_active_config_value = function(...) path_root,
    .env = base::environment(run_pipeline),
    .frame = base::environment())
  function_runner <- function(...) {
    run_pipeline(..., flag_validate_profile_selection = FALSE,
      callr_function = NULL)
  }
  testthat::expect_error(base::suppressWarnings(function_runner(
    sel_script = path_script, store_suffix = "a", plot_progress = FALSE)),
    class = "sjsdm_unit_expected_infeasible")
  store_path <-
    resolve_pipeline_store_path(path_script, path_root, "a")
  data_before <-
    targets::tar_meta(store = store_path)
  data_plan <-
    base::suppressWarnings(run_sjsdm_unit_fitting_preflight(
      unit_pipeline = path_script, target_store = path_root, scale_ids = "a",
      resolution_ids = base::c("genus", "family"),
      run_pipeline_function = function_runner, verbose = FALSE))
  testthat::expect_identical(data_plan[["fitting_status"]],
    base::c("expected_infeasible", "eligible"))
  data_after <-
    targets::tar_meta(store = store_path)
  testthat::expect_identical(
    data_before[data_before[["name"]] == "mod_jsdm_family", ],
    data_after[data_after[["name"]] == "mod_jsdm_family", ])
  base::saveRDS(TRUE, path_input)
  testthat::expect_error(run_sjsdm_unit_fitting_preflight(
    unit_pipeline = path_script, target_store = path_root, scale_ids = "a",
    resolution_ids = base::c("genus", "family"),
    run_pipeline_function = function_runner, verbose = FALSE),
    "Formerly infeasible preparation changed")
})
testthat::test_that("unrequested resolution errors are not shared failures", {
  res <-
    run_sjsdm_unit_fitting_preflight(
      unit_pipeline = "pipeline.R", target_store = "stores",
      scale_ids = "unit_a", resolution_ids = "family",
      load_metadata_function = function(...) tibble::tibble(
        name = "data_community_rare_filtered_genus",
        error = "No taxa found in data. The minimum_proportion is too high."),
      run_pipeline_function = function(...) {
        rlang::abort("No taxa", "sjsdm_unit_expected_infeasible")
      },
      diagnose_endpoints_function = function(target_names, ...) {
        tibble::tibble(target_name = target_names,
          endpoint_status = "prepared", data_hash = "current")
      }, verbose = FALSE)
  testthat::expect_identical(res[["fitting_status"]], "eligible")
})
