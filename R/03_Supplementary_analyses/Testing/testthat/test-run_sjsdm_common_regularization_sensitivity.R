testthat::test_that(
  "run_sjsdm_common_regularization_sensitivity() retains provenance",
  {
    data_model_index <-
      tibble::tibble(
        model_id = base::c(
          "regional/eu_r005/genus",
          "continental/europe/genus"
        ),
        tier_id = base::c(
          "paleo_spatial_regional",
          "paleo_spatial_continental"
        ),
        scale_id = base::c("eu_r005", "europe"),
        resolution_id = "genus",
        store_path = base::c("regional_store", "continental_store")
      )

    data_artifacts <-
      tibble::tibble(
        taxonomic_resolution = "genus",
        response_family = "binomial",
        candidate_table_hash = "candidate_hash",
        candidate_id = "candidate_002",
        alpha_cov = 0.5,
        alpha_coef = 0.5,
        alpha_spatial = 0.5,
        lambda_cov = 0.1,
        lambda_coef = 0,
        lambda_spatial = 0,
        regularization_source = "common_spatial_sensitivity",
        source_tier = "common_spatial",
        weighting_rule = "equal_tier_equal_id",
        source_tiers = base::list(
          base::c("continental", "regional", "local")
        )
      )

    read_target_function <- function(name, store) {
      base::switch(
        name,
        data_model_input_genus = base::list(store = store),
        model_formula_genus = stats::as.formula("~ bio1"),
        config_model_fitting_genus = base::list(
          n_cores = 2L,
          n_samples_anova = 10L
        ),
        data_sjsdm_model_context_genus = tibble::tibble(
          tier_id = "paleo_spatial_regional",
          taxonomic_resolution = "genus",
          response_family = "binomial",
          predictor_structure = "n_mev=4",
          candidate_table_hash = "candidate_hash"
        ),
        data_sjsdm_model_provenance_genus = tibble::tibble(
          cv_strategy = "grouped_kfold",
          effective_folds = 5L,
          n_locations = 20L,
          n_samples = 30L,
          n_taxa = 8L,
          n_effective_mev = 4L
        )
      )
    }

    fit_function <- function(
        data_model_input,
        model_formula,
        config_model_fitting,
        data_regularization) {
      structure(
        base::list(
          candidate_id = data_regularization[["candidate_id"]][[1L]],
          store = data_model_input[["store"]]
        ),
        class = "fake_model"
      )
    }

    standard_error_function <- function(
        mod_jsdm,
        parallel,
        verbose) {
      mod_jsdm
    }

    anova_function <- function(mod, n_samples, verbose) {
      structure(base::list(results = TRUE), class = "fake_anova")
    }

    extract_function <- function(anova_object, clamp_negative) {
      tibble::tibble(
        component = "Abiotic",
        R2_Nagelkerke = 0.4
      )
    }

    res <-
      run_sjsdm_common_regularization_sensitivity(
        data_model_index = data_model_index,
        data_artifacts = data_artifacts,
        read_target_function = read_target_function,
        fit_function = fit_function,
        standard_error_function = standard_error_function,
        anova_function = anova_function,
        extract_function = extract_function
      )

    testthat::expect_equal(
      res[["data_provenance"]][["fit_status"]],
      base::rep("ok", 2L)
    )
    testthat::expect_equal(
      res[["data_provenance"]][["candidate_id"]],
      base::rep("candidate_002", 2L)
    )
    testthat::expect_equal(
      res[["data_provenance"]][["cv_strategy"]],
      base::rep("grouped_kfold", 2L)
    )
    testthat::expect_equal(
      res[["data_decomposition"]][["regularization_source"]],
      base::rep("common_spatial_sensitivity", 2L)
    )
    testthat::expect_equal(
      res[["list_models"]][["regional/eu_r005/genus"]][["candidate_id"]],
      "candidate_002"
    )
    testthat::expect_equal(
      res[["list_models"]][["regional/eu_r005/genus"]][["store"]],
      "regional_store"
    )
    testthat::expect_equal(
      res[["list_models"]][["continental/europe/genus"]][["store"]],
      "continental_store"
    )
  }
)

testthat::test_that(
  "run_sjsdm_common_regularization_sensitivity() records fit errors",
  {
    data_model_index <-
      tibble::tibble(
        model_id = "model_a",
        tier_id = "regional",
        scale_id = "id_a",
        resolution_id = "genus",
        store_path = "store_a"
      )

    read_target_function <- function(name, store) {
      if (
        stringr::str_starts(name, "data_sjsdm_model_context_")
      ) {
        return(
          tibble::tibble(
            tier_id = "regional",
            taxonomic_resolution = "genus",
            response_family = "binomial",
            predictor_structure = "n_mev=4",
            candidate_table_hash = "candidate_hash"
          )
        )
      }

      if (
        stringr::str_starts(name, "config_model_fitting_")
      ) {
        return(base::list(n_cores = 1L, n_samples_anova = 1L))
      }

      if (
        stringr::str_starts(name, "data_sjsdm_model_provenance_")
      ) {
        return(tibble::tibble(cv_strategy = "grouped_kfold"))
      }

      base::list()
    }

    data_artifacts <-
      tibble::tibble(
        taxonomic_resolution = "genus",
        response_family = "binomial",
        candidate_table_hash = "candidate_hash",
        candidate_id = "candidate_001",
        alpha_cov = 0.5,
        alpha_coef = 0.5,
        alpha_spatial = 0.5,
        lambda_cov = 0,
        lambda_coef = 0,
        lambda_spatial = 0,
        regularization_source = "common_spatial_sensitivity",
        source_tier = "common_spatial",
        weighting_rule = "equal_tier_equal_id"
      )

    res <-
      run_sjsdm_common_regularization_sensitivity(
        data_model_index = data_model_index,
        data_artifacts = data_artifacts,
        read_target_function = read_target_function,
        fit_function = function(...) base::stop("fit failed")
      )

    testthat::expect_equal(
      res[["data_provenance"]][["fit_status"]],
      "error"
    )
    testthat::expect_match(
      res[["data_provenance"]][["fit_error"]],
      "fit failed"
    )
    testthat::expect_equal(base::nrow(res[["data_decomposition"]]), 0L)
  }
)
