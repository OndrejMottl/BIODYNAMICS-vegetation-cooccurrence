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
  list(
    results = tibble::tibble(
      models = c("F_A", "F_B", "F_S", "F_AB", "F_AS", "F_BS", "F_ABS"),
      `R2 Nagelkerke` = c(1, 2, 3, 0, 0, 0, 0)
    )
  )
}

testthat::test_that(
  "read_spatial_model_results skips missing stores without reading metadata",
  {
    res <-
      read_spatial_model_results(
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
  "read_spatial_model_results skips stores without successful ANOVA target",
  {
    path_store <-
      base::tempfile()
    base::dir.create(path_store)

    res <-
      read_spatial_model_results(
        store_index = make_test_store_index(path_store),
        resolution_ids = "genus",
        meta_fn = function(...) {
          tibble::tibble(
            name = "model_anova_family",
            error = NA_character_
          )
        }
      )

    testthat::expect_equal(base::nrow(res), 0L)
  }
)

testthat::test_that(
  "read_spatial_model_results extracts ANOVA components and AUC summary",
  {
    path_store <-
      base::tempfile()
    base::dir.create(path_store)

    res <-
      read_spatial_model_results(
        store_index = make_test_store_index(path_store),
        resolution_ids = "genus",
        meta_fn = function(...) {
          tibble::tibble(
            name = c("model_anova_genus", "model_evaluation_genus"),
            error = c(NA_character_, NA_character_)
          )
        },
        read_target_fn = function(name, store) {
          if (
            name == "model_anova_genus"
          ) {
            return(make_test_anova())
          }

          list(
            species = tibble::tibble(
              species = c("taxon_a", "taxon_b"),
              AUC = c(0.7, 0.9)
            )
          )
        }
      )

    testthat::expect_equal(base::nrow(res), 3L)
    testthat::expect_setequal(
      res$component,
      c("Abiotic", "Associations", "Spatial")
    )
    testthat::expect_equal(res$resolution_id, rep("genus", 3L))
    testthat::expect_equal(unique(res$auc_mean), 0.8)
    testthat::expect_equal(unique(res$auc_median), 0.8)
    testthat::expect_equal(unique(res$auc_n), 2L)
    testthat::expect_equal(
      base::sum(res$R2_Nagelkerke_percentage),
      100
    )
  }
)

testthat::test_that(
  "read_spatial_model_results can require non-empty results",
  {
    testthat::expect_error(
      read_spatial_model_results(
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
