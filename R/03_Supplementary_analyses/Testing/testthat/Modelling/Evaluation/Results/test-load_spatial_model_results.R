make_test_store_index <- function(store_path, store_exists = TRUE) {
  tibble::tibble(
    data_source = "modern",
    scale = "continental",
    scale_id = "europe",
    pipeline_name = "pipeline_modern_spatial_resolution",
    store_path = store_path,
    store_exists = store_exists
  )
}

make_test_anova <- function() {
  base::list(
    results = tibble::tibble(
      models = base::c(
        "F_A",
        "F_B",
        "F_S",
        "F_AB",
        "F_AS",
        "F_BS",
        "F_ABS"
      ),
      `R2 Nagelkerke` = base::c(1, 2, 3, 0, 0, 0, 0)
    )
  )
}

testthat::test_that(
  "load_spatial_model_results skips missing stores without reading metadata",
  {
    res <-
      load_spatial_model_results(
        store_index = make_test_store_index(
          store_path = "missing-store",
          store_exists = FALSE
        ),
        resolution_ids = "genus",
        meta_fn = function(...) {
          base::stop("metadata should not be read")
        }
      )

    testthat::expect_equal(base::nrow(res), 0L)
  }
)

testthat::test_that(
  "load_spatial_model_results skips stores without successful ANOVA target",
  {
    path_store <-
      base::tempfile()
    base::dir.create(path_store)

    res <-
      load_spatial_model_results(
        store_index = make_test_store_index(path_store),
        resolution_ids = "genus",
        meta_fn = function(...) {
          tibble::tibble(
            name = "list_jsdm_variance_partition_family",
            error = NA_character_
          )
        }
      )

    testthat::expect_equal(base::nrow(res), 0L)
  }
)

testthat::test_that(
  "load_spatial_model_results separates fitted and predictive metrics",
  {
    path_store <-
      base::tempfile()
    base::dir.create(path_store)

    res <-
      load_spatial_model_results(
        store_index = make_test_store_index(path_store),
        resolution_ids = "genus",
        meta_fn = function(...) {
          tibble::tibble(
            name = base::c(
              "list_jsdm_variance_partition_genus",
              "list_jsdm_evaluation_fitted_genus",
              "model_evaluation_cross_validated_genus",
              "data_sjsdm_model_provenance_genus"
            ),
            error = base::rep(NA_character_, 4L)
          )
        },
        read_target_fn = function(name, store) {
          if (
            name == "list_sjsdm_cv_evaluation_artifact_genus"
          ) {
            base::stop("canonical target unavailable")
          }

          if (
            name == "list_jsdm_variance_partition_genus"
          ) {
            return(make_test_anova())
          }

          if (
            name == "list_jsdm_evaluation_fitted_genus"
          ) {
            return(
              base::list(
                data_taxon_metrics = tibble::tibble(
                  taxon_name = base::c("taxon_a", "taxon_b"),
                  auc = base::c(0.7, 0.9)
                )
              )
            )
          }

          if (
            name == "data_sjsdm_model_provenance_genus"
          ) {
            return(
              tibble::tibble(
                cv_strategy =
                  "spatially_stratified_group_kfold",
                effective_folds = 5L,
                cv_feasibility_status = "grouped_kfold_feasible",
                n_locations = 12L,
                n_samples = 40L,
                n_taxa = 8L,
                n_effective_mev = 3L,
                regularization_source = "unit_cv",
                source_tier = NA_character_,
                candidate_id = "candidate_001"
              )
            )
          }

          base::list(
            data_community_summary = tibble::tibble(
              repeat_id = base::rep(1:2, each = 3L),
              metric_id = base::rep(
                base::c("tjur_r2", "auc", "log_loss"),
                times = 2L
              ),
              summary_statistic = "mean",
              estimate = base::c(0.2, 0.7, 0.4, 0.4, 0.9, 0.6),
              n_taxa_evaluable = 2L,
              metric_status = "ok"
            )
          )
        }
      )

    testthat::expect_equal(base::nrow(res), 3L)
    testthat::expect_setequal(
      res[["component"]],
      base::c("Abiotic", "Associations", "Spatial")
    )
    testthat::expect_equal(
      res[["resolution_id"]],
      base::rep("genus", 3L)
    )
    testthat::expect_equal(base::unique(res[["fitted_auc_mean"]]), 0.8)
    testthat::expect_equal(base::unique(res[["fitted_auc_median"]]), 0.8)
    testthat::expect_equal(base::unique(res[["fitted_auc_n"]]), 2L)
    testthat::expect_equal(
      base::unique(res[["predictive_tjur_r2_mean"]]),
      0.3
    )
    testthat::expect_equal(
      base::unique(res[["predictive_auc_mean"]]),
      0.8
    )
    testthat::expect_equal(
      base::unique(res[["predictive_log_loss_mean"]]),
      0.5
    )
    testthat::expect_equal(
      base::unique(res[["cv_strategy"]]),
      "spatially_stratified_group_kfold"
    )
    testthat::expect_equal(
      base::unique(res[["regularization_source"]]),
      "unit_cv"
    )
    testthat::expect_equal(base::unique(res[["n_effective_mev"]]), 3L)
    testthat::expect_equal(
      base::sum(res[["R2_Nagelkerke_percentage"]]),
      100
    )
  }
)

testthat::test_that(
  "load_spatial_model_results can require non-empty results",
  {
    testthat::expect_error(
      load_spatial_model_results(
        store_index = make_test_store_index(
          store_path = "missing-store",
          store_exists = FALSE
        ),
        resolution_ids = "genus",
        require_non_empty = TRUE
      ),
      regexp = "No successful spatial model results"
    )
  }
)

testthat::test_that(
  "load_spatial_model_results preserves evaluation store validation",
  {
    testthat::expect_error(
      load_spatial_model_results(
        store_index = make_test_store_index(store_path = 1),
        resolution_ids = "genus",
        meta_fn = function(...) {
          tibble::tibble(
            name = base::c(
              "list_jsdm_variance_partition_genus",
              "list_jsdm_evaluation_fitted_genus"
            ),
            error = base::rep(NA_character_, 2L)
          )
        },
        read_target_fn = function(name, store) {
          if (
            name == "list_jsdm_variance_partition_genus"
          ) {
            return(make_test_anova())
          }

          base::list(
            data_taxon_metrics = tibble::tibble(auc = 0.8)
          )
        }
      ),
      regexp = "store_path"
    )
  }
)
