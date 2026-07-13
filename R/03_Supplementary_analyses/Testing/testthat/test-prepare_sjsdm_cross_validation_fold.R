make_sjsdm_cv_adapter_data <- function() {
  data_community_matrix <-
    base::matrix(
      data = base::c(
        1, 0,
        1, 1,
        0, 1,
        0, 0
      ),
      nrow = 4,
      byrow = TRUE,
      dimnames = base::list(
        base::c("a__0", "b__0", "c__0", "d__0"),
        base::c("taxon_a", "taxon_b")
      )
    )

  data_abiotic_wide <-
    tibble::tibble(
      dataset_name = base::c("a", "b", "c", "d"),
      age = base::c(0, 0, 0, 0),
      bio = base::c(10, 12, 14, 16)
    )

  data_coords_projected <-
    base::data.frame(
      coord_x_km = base::c(0, 10, 20, 30),
      coord_y_km = base::c(0, 0, 0, 0),
      row.names = base::c("a", "b", "c", "d")
    )

  data_sample_ids <-
    tibble::tibble(
      sample_id = base::c("a__0", "b__0", "c__0", "d__0"),
      row_index = base::seq_len(4L),
      location_id = base::c("a", "b", "c", "d"),
      dataset_name = base::c("a", "b", "c", "d"),
      age = base::c(0, 0, 0, 0)
    )

  res <-
    base::list(
      data_community_matrix = data_community_matrix,
      data_abiotic_wide = data_abiotic_wide,
      data_coords_projected = data_coords_projected,
      data_sample_ids = data_sample_ids
    )

  return(res)
}

testthat::test_that(
  "prepare_sjsdm_cross_validation_fold() maps row indices to samples",
  {
    list_data <-
      make_sjsdm_cv_adapter_data()

    res <-
      prepare_sjsdm_cross_validation_fold(
        data_community_matrix = list_data[["data_community_matrix"]],
        data_abiotic_wide = list_data[["data_abiotic_wide"]],
        data_coords_projected = list_data[["data_coords_projected"]],
        data_sample_ids = list_data[["data_sample_ids"]],
        train_indices = base::c(1L, 2L, 3L),
        test_indices = 4L,
        config_model_fitting = base::list(
          error_family = "binomial",
          use_spatial = FALSE,
          spatial_mode = "spatial",
          n_mev = 1L,
          age_scale_mode = "center"
        ),
        config_data_processing = base::list(min_n_taxa = 1L),
        repeat_id = 1L,
        fold_id = 1L
      )

    testthat::expect_equal(
      res[["train_sample_ids"]],
      base::c("a__0", "b__0", "c__0")
    )
    testthat::expect_equal(res[["test_sample_ids"]], "d__0")
    testthat::expect_false(
      "data_spatial_to_fit" %in% base::names(res[["data_train_input"]])
    )
  }
)

testthat::test_that(
  "prepare_sjsdm_cross_validation_fold() derives legacy sample IDs",
  {
    list_data <-
      make_sjsdm_cv_adapter_data()

    data_sample_ids_legacy <-
      list_data[["data_sample_ids"]] |>
      dplyr::select("dataset_name", "age")

    res <-
      prepare_sjsdm_cross_validation_fold(
        data_community_matrix = list_data[["data_community_matrix"]],
        data_abiotic_wide = list_data[["data_abiotic_wide"]],
        data_coords_projected = list_data[["data_coords_projected"]],
        data_sample_ids = data_sample_ids_legacy,
        train_indices = base::c(1L, 2L, 3L),
        test_indices = 4L,
        config_model_fitting = base::list(
          error_family = "binomial",
          use_spatial = FALSE,
          spatial_mode = "spatial",
          n_mev = 1L,
          age_scale_mode = "center"
        ),
        config_data_processing = base::list(min_n_taxa = 1L),
        repeat_id = 1L,
        fold_id = 1L
      )

    testthat::expect_equal(
      res[["train_sample_ids"]],
      base::c("a__0", "b__0", "c__0")
    )
    testthat::expect_equal(res[["test_sample_ids"]], "d__0")
  }
)

testthat::test_that(
  "prepare_sjsdm_cross_validation_fold() builds fold-local spatial inputs",
  {
    list_data <-
      make_sjsdm_cv_adapter_data()

    compute_spatial_function <- function(data_coords_projected, n_mev) {
      data_mev <-
        base::data.frame(mev_1 = data_coords_projected[["coord_x_km"]])

      base::rownames(data_mev) <-
        base::rownames(data_coords_projected)

      return(data_mev)
    }

    interpolate_spatial_function <- function(
        data_coords_projected_train,
        data_mev_core,
        data_coords_projected_pred,
        spatial_scale_attributes) {
      data_mev <-
        base::data.frame(mev_1 = data_coords_projected_pred[["coord_x_km"]])

      base::rownames(data_mev) <-
        base::rownames(data_coords_projected_pred)

      return(data_mev)
    }

    res <-
      prepare_sjsdm_cross_validation_fold(
        data_community_matrix = list_data[["data_community_matrix"]],
        data_abiotic_wide = list_data[["data_abiotic_wide"]],
        data_coords_projected = list_data[["data_coords_projected"]],
        data_sample_ids = list_data[["data_sample_ids"]],
        train_indices = base::c(1L, 2L, 3L),
        test_indices = 4L,
        config_model_fitting = base::list(
          error_family = "binomial",
          use_spatial = TRUE,
          spatial_mode = "spatial",
          n_mev = 1L,
          age_scale_mode = "center"
        ),
        config_data_processing = base::list(min_n_taxa = 1L),
        repeat_id = 1L,
        fold_id = 1L,
        compute_spatial_function = compute_spatial_function,
        interpolate_spatial_function = interpolate_spatial_function
      )

    testthat::expect_true(
      "data_spatial_to_fit" %in% base::names(res[["data_train_input"]])
    )
    testthat::expect_true(
      "data_spatial_diagnostics" %in% base::names(res)
    )
    testthat::expect_equal(
      res[["data_spatial_diagnostics"]][["n_test_locations"]],
      1L
    )
  }
)
