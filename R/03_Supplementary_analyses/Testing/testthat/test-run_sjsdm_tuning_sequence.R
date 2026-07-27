testthat::test_that(
  "run_sjsdm_tuning_sequence() alternates units and tier rounds",
  {
    environment_calls <-
      base::new.env(parent = base::emptyenv())

    environment_calls[["data"]] <-
      tibble::tibble(
        script = base::character(),
        suffix = base::character(),
        targets = base::character(),
        max_round = base::character(),
        fresh_run = base::logical(),
        prebuild_interpolation = base::logical(),
        vec_allowed_profile_roles = base::character(),
        vec_allowed_profile_statuses = base::character(),
        plot_progress = base::logical(),
        callr_isolated = base::logical()
      )

    run_pipeline_function <- function(
        sel_script,
        store_suffix = NULL,
        target_names = NULL,
        prebuild_interpolation = FALSE,
        fresh_run = FALSE,
        vec_allowed_profile_roles = NULL,
        vec_allowed_profile_statuses = NULL,
        plot_progress = TRUE,
        callr_function = callr::r) {
      environment_calls[["data"]] <-
        dplyr::bind_rows(
          environment_calls[["data"]],
          tibble::tibble(
            script = sel_script,
            suffix = dplyr::coalesce(store_suffix, "tier"),
            targets = stringr::str_c(target_names, collapse = ","),
            max_round = base::Sys.getenv(
              "SJSMD_TUNING_MAX_ROUND",
              unset = ""
            ),
            fresh_run = fresh_run,
            prebuild_interpolation = prebuild_interpolation,
            vec_allowed_profile_roles =
              stringr::str_c(
                vec_allowed_profile_roles,
                collapse = ","
              ),
            vec_allowed_profile_statuses =
              stringr::str_c(
                vec_allowed_profile_statuses,
                collapse = ","
              ),
            plot_progress = plot_progress,
            callr_isolated = !base::is.null(callr_function)
          )
        )

      return(base::invisible(NULL))
    }

    res <-
      run_sjsdm_tuning_sequence(
        unit_pipeline = "unit_pipeline.R",
        tuning_target_names = base::c("summary_genus", "summary_family"),
        unit_store_suffixes = base::c("unit_a", "unit_b"),
        prebuild_interpolation = TRUE,
        fresh_run = TRUE,
        tuning_strategy = "staged",
        n_rounds = 3L,
        run_pipeline_function = run_pipeline_function,
        vec_allowed_profile_roles = "reference",
        vec_allowed_profile_statuses = "frozen",
        has_tuning_evidence_function = function(...) TRUE
      )

    data_calls <-
      environment_calls[["data"]]

    testthat::expect_null(res)
    testthat::expect_equal(base::nrow(data_calls), 9L)
    testthat::expect_identical(
      data_calls[["script"]],
      base::rep(
        base::c(
          "unit_pipeline.R",
          "unit_pipeline.R",
          "R/Pipelines/pipeline_sjsdm_tier_tuning.R"
        ),
        times = 3L
      )
    )
    testthat::expect_identical(
      data_calls[["targets"]][[3L]],
      "data_sjsdm_tier_survivor_decisions_round_1"
    )
    testthat::expect_identical(
      data_calls[["targets"]][[6L]],
      "data_sjsdm_tier_survivor_decisions_round_2"
    )
    testthat::expect_identical(
      data_calls[["targets"]][[9L]],
      "data_sjsdm_tier_regularization_artifacts"
    )
    testthat::expect_identical(
      data_calls[["max_round"]],
      base::c("1", "1", "", "2", "2", "", "3", "3", "")
    )
    testthat::expect_identical(
      data_calls[["fresh_run"]],
      base::c(
        TRUE,
        TRUE,
        TRUE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE,
        FALSE
      )
    )
    testthat::expect_identical(
      data_calls[["prebuild_interpolation"]],
      base::c(TRUE, TRUE, FALSE, base::rep(FALSE, 6L))
    )
    testthat::expect_identical(
      data_calls[["plot_progress"]],
      base::c(base::rep(FALSE, 8L), TRUE)
    )
    testthat::expect_identical(
      data_calls[["callr_isolated"]],
      base::rep(base::c(TRUE, TRUE, FALSE), times = 3L)
    )
    testthat::expect_identical(
      base::unique(data_calls[["vec_allowed_profile_roles"]]),
      "reference"
    )
    testthat::expect_identical(
      base::unique(data_calls[["vec_allowed_profile_statuses"]]),
      "frozen"
    )
  }
)

testthat::test_that(
  "run_sjsdm_tuning_sequence() preserves exhaustive execution",
  {
    environment_calls <-
      base::new.env(parent = base::emptyenv())

    environment_calls[["n"]] <- 0L

    run_pipeline_function <- function(...) {
      environment_calls[["n"]] <-
        environment_calls[["n"]] + 1L

      return(base::invisible(NULL))
    }

    res <-
      run_sjsdm_tuning_sequence(
        unit_pipeline = "unit_pipeline.R",
        tuning_target_names = "summary_genus",
        unit_store_suffixes = base::c("unit_a", "unit_b"),
        tuning_strategy = "exhaustive",
        n_rounds = 3L,
        run_pipeline_function = run_pipeline_function,
        has_tuning_evidence_function = function(...) TRUE
      )

    testthat::expect_null(res)
    testthat::expect_identical(environment_calls[["n"]], 3L)
  }
)

testthat::test_that(
  "run_sjsdm_tuning_sequence() supports one temporal store",
  {
    environment_calls <-
      base::new.env(parent = base::emptyenv())

    environment_calls[["n"]] <- 0L

    run_pipeline_function <- function(...) {
      environment_calls[["n"]] <-
        environment_calls[["n"]] + 1L

      return(base::invisible(NULL))
    }

    run_sjsdm_tuning_sequence(
      unit_pipeline = "temporal_pipeline.R",
      tuning_target_names = "summary_timeslice_0",
      tuning_strategy = "staged",
      n_rounds = 3L,
      run_pipeline_function = run_pipeline_function,
      has_tuning_evidence_function = function(...) TRUE
    )

    testthat::expect_identical(environment_calls[["n"]], 6L)
  }
)

testthat::test_that(
  "run_sjsdm_tuning_sequence() stops when all unit evidence is empty",
  {
    environment_calls <- base::new.env(parent = base::emptyenv())
    environment_calls[["data"]] <- tibble::tibble()
    environment_calls[["evidence_checks"]] <- 0L

    run_pipeline_function <- function(
        sel_script,
        store_suffix = NULL,
        ...) {
      environment_calls[["data"]] <-
        dplyr::bind_rows(
          environment_calls[["data"]],
          tibble::tibble(
            script = sel_script,
            suffix = dplyr::coalesce(store_suffix, "tier")
          )
        )

      return(base::invisible(NULL))
    }

    has_tuning_evidence_function <- function(store_paths, target_names) {
      environment_calls[["evidence_checks"]] <-
        environment_calls[["evidence_checks"]] + 1L

      testthat::expect_setequal(
        store_paths,
        base::file.path(
          "targets_root",
          base::c("unit_a", "unit_b"),
          "unit_pipeline"
        )
      )
      testthat::expect_identical(target_names, "summary_genus")

      return(FALSE)
    }

    res <-
      run_sjsdm_tuning_sequence(
        unit_pipeline = "unit_pipeline.R",
        tuning_target_names = "summary_genus",
        unit_store_suffixes = base::c("unit_a", "unit_b"),
        tuning_strategy = "staged",
        n_rounds = 3L,
        run_pipeline_function = run_pipeline_function,
        has_tuning_evidence_function = has_tuning_evidence_function,
        target_store = "targets_root"
      )

    testthat::expect_null(res)
    testthat::expect_identical(
      environment_calls[["data"]],
      tibble::tibble(
        script = base::rep("unit_pipeline.R", 2L),
        suffix = base::c("unit_a", "unit_b")
      )
    )
    testthat::expect_identical(
      environment_calls[["evidence_checks"]],
      1L
    )
  }
)

testthat::test_that(
  "shared spatial and temporal runners use the tuning sequence",
  {
    vec_runner_paths <-
      base::c(
        here::here(
          "R/02_Main_analyses/01_Spatial/01_Paleo/",
          base::c(
            "01_Run_spatial_continental.R",
            "02_Run_spatial_regional.R",
            "03_Run_spatial_local.R"
          )
        ),
        here::here(
          "R/02_Main_analyses/01_Spatial/02_Contemporary/",
          base::c(
            "01_Run_modern_continental.R",
            "02_Run_modern_regional.R",
            "03_Run_modern_local.R"
          )
        ),
        here::here(
          "R/02_Main_analyses/02_Temporal_Paleo/",
          base::c(
            "01_Run_temporal_europe.R",
            "02_Run_temporal_america.R",
            "03_Run_temporal_asia.R"
          )
        )
      )

    purrr::walk(
      vec_runner_paths,
      .f = ~ testthat::expect_match(
        readr::read_file(.x),
        "run_sjsdm_tuning_sequence(",
        fixed = TRUE
      )
    )
  }
)

testthat::test_that(
  "shared runners skip redundant post-selection interpolation",
  {
    vec_runner_paths <-
      base::c(
        here::here(
          "R/02_Main_analyses/01_Spatial/01_Paleo/",
          base::c(
            "01_Run_spatial_continental.R",
            "02_Run_spatial_regional.R",
            "03_Run_spatial_local.R"
          )
        ),
        here::here(
          "R/02_Main_analyses/01_Spatial/02_Contemporary/",
          base::c(
            "01_Run_modern_continental.R",
            "02_Run_modern_regional.R",
            "03_Run_modern_local.R"
          )
        ),
        here::here(
          "R/02_Main_analyses/02_Temporal_Paleo/",
          base::c(
            "01_Run_temporal_europe.R",
            "02_Run_temporal_america.R",
            "03_Run_temporal_asia.R"
          )
        ),
        here::here(
          "R/02_Main_analyses/Run_CZ_paleo_cv_staged_reference_gpu.R"
        )
      )

    purrr::walk(
      vec_runner_paths,
      .f = ~ testthat::expect_match(
        readr::read_file(.x),
        "prebuild_interpolation = FALSE",
        fixed = TRUE
      )
    )
  }
)
