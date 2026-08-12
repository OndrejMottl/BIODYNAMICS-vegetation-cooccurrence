testthat::test_that(
  "load_sjsdm_tuning_summaries() reads every requested summary",
  {
    read_target_function <- function(name, store) {
      tibble::tibble(
        source_id = base::basename(store),
        taxonomic_resolution = stringr::str_remove(
          name,
          "^data_sjsdm_tuning_summary_"
        ),
        candidate_id = "candidate_001"
      )
    }

    res <-
      load_sjsdm_tuning_summaries(
        store_paths = base::c("store_a", "store_b"),
        resolution_ids = base::c("genus", "family"),
        target_prefix = "data_sjsdm_tuning_summary",
        read_target_function = read_target_function
      )

    testthat::expect_equal(base::nrow(res), 4L)
    testthat::expect_setequal(
      res[["source_store"]],
      base::c("store_a", "store_b")
    )
    testthat::expect_setequal(
      res[["resolution_id"]],
      base::c("genus", "family")
    )
  }
)

testthat::test_that(
  "load_sjsdm_tuning_summaries() reads native v2 artifacts",
  {
    read_target_function <- function(name, store) {
      data_candidates <-
        build_sjsdm_regularization_candidates(
          alpha_cov = 0,
          alpha_coef = 0,
          alpha_spatial = 0,
          lambda_cov = 0.1,
          lambda_coef = 0.1,
          lambda_spatial = 0.1
        )

      data_schedule <-
        build_sjsdm_tuning_schedule(
          tuning_strategy = "exhaustive",
          n_candidates = 1L,
          repeat_ids = 1L
        )

      data_empty_metrics <-
        build_sjsdm_empty_tuning_result()[["data_tuning"]]

      payload <-
        base::list(
          data_candidates = data_candidates,
          data_schedule = data_schedule,
          data_candidate_fold_metrics = data_empty_metrics,
          data_candidate_repeat_summary = tibble::tibble(
            repeat_id = 1L,
            candidate_id = "candidate_001",
            alpha_cov = 0,
            alpha_coef = 0,
            alpha_spatial = 0,
            lambda_cov = 0.1,
            lambda_coef = 0.1,
            lambda_spatial = 0.1,
            n_folds_total = 1L,
            n_folds_successful = 1L,
            n_response_values = 1L,
            negative_log_likelihood_test = 0.1,
            negative_log_likelihood_per_response = 0.1,
            auc_macro_test = 0.7,
            summary_status = "ok",
            cv_strategy = "spatially_stratified_group_kfold",
            regularization_source = "unit_cv",
            source_id = "unit",
            tier_id = "paleo",
            taxonomic_resolution = "genus",
            response_family = "binomial",
            predictor_structure = "full",
            candidate_table_hash = "candidate_hash"
          ),
          data_stage_timings = summarise_sjsdm_tuning_timings(
            list_prediction_cache = base::list()
          ),
          data_execution_provenance = summarise_sjsdm_tuning_execution(
            data_tuning = data_empty_metrics,
            data_schedule = data_schedule
          ),
          list_prediction_cache = base::list()
        )

      build_sjsdm_artifact_envelope(
        artifact_type = "sjsdm_cv_tuning",
        payload = payload,
        provenance = build_sjsdm_artifact_provenance(
          pipeline_id = "pipeline_paleo_core",
          configuration_profile = "project_cz_paleo"
        )
      )
    }

    res <-
      load_sjsdm_tuning_summaries(
        store_paths = "v2_store",
        resolution_ids = "genus",
        read_target_function = read_target_function
      )

    testthat::expect_identical(res[["source_store"]], "v2_store")
    testthat::expect_identical(res[["resolution_id"]], "genus")
    testthat::expect_identical(
      res[["candidate_id"]],
      "candidate_001"
    )
  }
)

testthat::test_that(
  "load_sjsdm_tuning_summaries() rejects partial evidence",
  {
    read_target_function <- function(name, store) {
      if (
        store == "store_b" &&
          name == "data_sjsdm_tuning_summary_family"
      ) {
        base::stop("target unavailable")
      }

      tibble::tibble(
        source_id = base::basename(store),
        candidate_id = "candidate_001"
      )
    }

    error_condition <-
      testthat::expect_error(
        load_sjsdm_tuning_summaries(
          store_paths = base::c("store_a", "store_b"),
          resolution_ids = base::c("genus", "family"),
          target_prefix = "data_sjsdm_tuning_summary",
          read_target_function = read_target_function
        )
      )

    error_message <-
      base::conditionMessage(error_condition)

    testthat::expect_match(
      error_message,
      "Could not read every requested tuning summary",
      fixed = TRUE
    )
    testthat::expect_match(
      error_message,
      "store_b",
      fixed = TRUE
    )
    testthat::expect_match(
      error_message,
      "data_sjsdm_tuning_summary_family",
      fixed = TRUE
    )
  }
)

testthat::test_that(
  "load_sjsdm_tuning_summaries() validates inputs",
  {
    testthat::expect_error(
      load_sjsdm_tuning_summaries(
        store_paths = base::character(),
        resolution_ids = "genus"
      ),
      "store_paths"
    )
  }
)

testthat::test_that(
  "load_sjsdm_tuning_summaries() identifies temporal branches",
  {
    read_target_function <- function(name, store) {
      tibble::tibble(
        source_id = "unit",
        candidate_id = "candidate_001"
      )
    }

    res <-
      load_sjsdm_tuning_summaries(
        store_paths = "temporal_store",
        resolution_ids = base::c("timeslice_0", "timeslice_500"),
        read_target_function = read_target_function
      )

    testthat::expect_setequal(
      res[["source_id"]],
      base::c("timeslice_0", "timeslice_500")
    )
  }
)

testthat::test_that(
  "load_sjsdm_tuning_summaries() reads explicit round targets",
  {
    environment_reads <-
      base::new.env(parent = base::emptyenv())

    environment_reads[["names"]] <-
      base::character()

    read_target_function <- function(name, store) {
      environment_reads[["names"]] <-
        base::c(environment_reads[["names"]], name)

      tibble::tibble(
        source_id = base::basename(store),
        candidate_id = "candidate_001"
      )
    }

    res <-
      load_sjsdm_tuning_summaries(
        store_paths = "store_a",
        resolution_ids = base::c("genus", "family"),
        target_prefix = "data_sjsdm_tuning_summary_round_2",
        read_target_function = read_target_function
      )

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_setequal(
      environment_reads[["names"]],
      base::c(
        "data_sjsdm_tuning_summary_round_2_genus",
        "data_sjsdm_tuning_summary_round_2_family"
      )
    )
  }
)

testthat::test_that(
  "load_sjsdm_tuning_summaries() reads exact direct-unit targets",
  {
    environment_reads <-
      base::new.env(parent = base::emptyenv())
    environment_reads[["names"]] <-
      base::character()

    read_target_function <- function(name, store) {
      environment_reads[["names"]] <-
        base::c(environment_reads[["names"]], name)

      tibble::tibble(
        source_id = "unit",
        taxonomic_resolution = "genus",
        candidate_id = "candidate_001"
      )
    }

    res <-
      load_sjsdm_tuning_summaries(
        store_paths = "direct_store",
        resolution_ids = "genus",
        target_names = "data_sjsdm_tuning_summary",
        read_target_function = read_target_function
      )

    testthat::expect_identical(
      environment_reads[["names"]],
      "data_sjsdm_tuning_summary"
    )
    testthat::expect_identical(res[["resolution_id"]], "genus")
  }
)

testthat::test_that(
  "load_sjsdm_tuning_summaries() validates the target prefix",
  {
    testthat::expect_error(
      load_sjsdm_tuning_summaries(
        store_paths = "store_a",
        resolution_ids = "genus",
        target_prefix = base::character()
      ),
      "target_prefix"
    )
  }
)
