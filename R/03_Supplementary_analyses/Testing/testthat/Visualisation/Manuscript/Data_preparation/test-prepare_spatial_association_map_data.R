testthat::test_that(
  "prepare_spatial_association_map_data() distinguishes unavailable models",
  {
    data_grid <-
      tibble::tibble(
        scale = base::rep("local", 4L),
        scale_id = base::c("a", "b", "c", "d"),
        continent_id = base::rep("europe", 4L),
        x_min = 1:4,
        x_max = 2:5,
        y_min = 40:43,
        y_max = 41:44
      )
    data_unit <-
      tibble::tibble(
        scale = "local",
        scale_id = "a",
        resolution_id = "genus",
        component = "Associations",
        R2_Nagelkerke_percentage = 30
      )
    data_inventory <-
      tibble::tibble(
        analysis_id = base::rep("paleo_spatial", 4L),
        tier_id = base::rep("local", 4L),
        scale_id = base::c("a", "b", "c", "d"),
        resolution_id = base::rep("genus", 4L),
        preparation_status = base::c(
          "prepared",
          "expected_infeasible",
          "prepared",
          "prepared"
        ),
        cv_feasibility_status = base::c(
          "grouped_kfold_feasible",
          "full_model_infeasible",
          "full_model_infeasible",
          "grouped_kfold_feasible"
        ),
        n_samples = base::c(20, 2, 4, 15),
        n_taxa = base::c(8, 1, 3, 7)
      )

    res <-
      prepare_spatial_association_map_data(
        data_unit = data_unit,
        data_spatial_grid = data_grid,
        data_preparation_inventory = data_inventory,
        resolution_ids = "genus"
      )

    testthat::expect_equal(base::nrow(res), 4L)
    testthat::expect_identical(
      dplyr::pull(res, .data$availability_status),
      base::c(
        "available",
        "expected_infeasible",
        "expected_infeasible",
        "missing_model"
      )
    )
    testthat::expect_true(
      base::is.na(
        dplyr::pull(res, .data$association_percentage)[[4L]]
      )
    )
    testthat::expect_equal(
      dplyr::pull(res, .data$glyph_x),
      base::c(1.5, 2.5, 3.5, 4.5)
    )
    testthat::expect_equal(
      dplyr::pull(res, .data$glyph_y),
      base::c(40.5, 41.5, 42.5, 43.5)
    )
  }
)

testthat::test_that(
  "prepare_spatial_association_map_data() offsets resolution glyphs",
  {
    data_grid <-
      tibble::tibble(
        scale = "local",
        scale_id = "a",
        continent_id = "europe",
        x_min = 0,
        x_max = 10,
        y_min = 40,
        y_max = 50
      )
    data_unit <-
      tidyr::crossing(
        scale = "local",
        scale_id = "a",
        resolution_id = base::c(
          "genus",
          "family",
          "functional_type"
        ),
        component = "Associations"
      ) |>
      dplyr::mutate(
        R2_Nagelkerke_percentage = base::c(20, 30, 40)
      )
    data_inventory <-
      data_unit |>
      dplyr::transmute(
        analysis_id = "paleo_spatial",
        tier_id = .data$scale,
        scale_id = .data$scale_id,
        resolution_id = .data$resolution_id,
        preparation_status = "prepared",
        cv_feasibility_status = "grouped_kfold_feasible",
        n_samples = 20,
        n_taxa = 8
      )

    res <-
      prepare_spatial_association_map_data(
        data_unit,
        data_grid,
        data_inventory
      )

    testthat::expect_equal(
      dplyr::pull(res, .data$glyph_x),
      base::c(2.7, 5, 7.3)
    )
    testthat::expect_true(
      base::all(dplyr::pull(res, .data$glyph_y) == 45)
    )
  }
)

testthat::test_that(
  "prepare_spatial_association_map_data() rejects duplicate results",
  {
    data_unit <-
      tibble::tibble(
        scale = base::rep("local", 2L),
        scale_id = base::rep("a", 2L),
        resolution_id = base::rep("genus", 2L),
        component = base::rep("Associations", 2L),
        R2_Nagelkerke_percentage = base::c(20, 30)
      )
    data_grid <-
      tibble::tibble(
        scale = "local",
        scale_id = "a",
        continent_id = "europe",
        x_min = 1,
        x_max = 2,
        y_min = 40,
        y_max = 41
      )
    data_inventory <-
      tibble::tibble(
        analysis_id = "paleo_spatial",
        tier_id = "local",
        scale_id = "a",
        resolution_id = "genus",
        preparation_status = "prepared",
        cv_feasibility_status = "grouped_kfold_feasible",
        n_samples = 20,
        n_taxa = 8
      )

    testthat::expect_error(
      prepare_spatial_association_map_data(
        data_unit,
        data_grid,
        data_inventory,
        "genus"
      ),
      "duplicate"
    )
  }
)
