# Test get_random_structure_for_model function - only space

testthat::test_that(
  desc = "get_random_structure_for_model() - only space - correct class",
  code = {
    data_community_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000", "dataset3__1500"),
        species1 = c(1, 2, 3),
        species2 = c(4, 5, 6)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_abiotic_example <-
      data.frame(
        row_name = c("dataset0__0", "dataset1__500", "dataset2__1000"),
        abiotic1 = c(5, 6, 7),
        abiotic2 = c(8, 9, 10)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_coords_example <-
      data.frame(
        row_name = c("dataset0", "dataset1", "dataset2", "dataset3"),
        coord_long = c(9, 10, 11, 12),
        coord_lat = c(12, 13, 14, 15)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_dummy <-
      check_and_prepare_data_for_fit(
        data_community = data_community_example,
        data_abiotic = data_abiotic_example,
        data_coords = data_coords_example
      )

    result <-
      get_random_structure_for_model(data_dummy, type = "space")

    # Check the structure of the result
    testthat::expect_type(result, "list")

    testthat::expect_length(result, 2)

    testthat::expect_named(result, c("random_levels", "study_design"))

    result_random_effects <-
      result %>%
      purrr::chuck("random_levels")

    purrr::walk(
      .x = result_random_effects,
      .f = ~ testthat::expect_s3_class(.x, "HmscRandomLevel")
    )

    result_study_design <-
      result %>%
      purrr::chuck("study_design")

    testthat::expect_s3_class(result_study_design, "data.frame")
  }
)

testthat::test_that(
  desc = "get_random_structure_for_model function - only space - correct values",
  code = {
    data_community_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000", "dataset3__1500"),
        species1 = c(1, 2, 3),
        species2 = c(4, 5, 6)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_abiotic_example <-
      data.frame(
        row_name = c("dataset0__0", "dataset1__500", "dataset2__1000"),
        abiotic1 = c(5, 6, 7),
        abiotic2 = c(8, 9, 10)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_coords_example <-
      data.frame(
        row_name = c("dataset0", "dataset1", "dataset2", "dataset3"),
        coord_long = c(9, 10, 11, 12),
        coord_lat = c(12, 13, 14, 15)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_dummy <-
      check_and_prepare_data_for_fit(
        data_community = data_community_example,
        data_abiotic = data_abiotic_example,
        data_coords = data_coords_example
      )

    result <-
      get_random_structure_for_model(data_dummy, type = "space")


    result_random_effects <-
      result %>%
      purrr::chuck("random_levels")

    testthat::expect_length(result_random_effects, 1)

    testthat::expect_named(result_random_effects, "dataset_name")

    result_random_effects <-
      result_random_effects %>%
      purrr::chuck("dataset_name")


    expected_result_random_effects_names <-
      c(
        "pi", "s", "sDim", "spatialMethod", "x", "xDim", "N",
        "distMat", "xMat", "nfMax", "nfMin", "nNeighbours", "sKnot", "nu", "a1",
        "b1", "a2", "b2", "alphapw", "call"
      )

    testthat::expect_equal(
      names(result_random_effects),
      expected_result_random_effects_names
    )

    result_study_design <-
      result %>%
      purrr::chuck("study_design")

    expected_result_study_design <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000"),
        dataset_name = factor(c("dataset1", "dataset2"))
      ) %>%
      tibble::column_to_rownames("row_name")

    testthat::expect_equal(
      result_study_design,
      expected_result_study_design
    )
  }
)

testthat::test_that(
  desc = "get_random_structure_for_model function - space and age - correct class",
  code = {
    data_community_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000", "dataset3__1500"),
        species1 = c(1, 2, 3),
        species2 = c(4, 5, 6)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_abiotic_example <-
      data.frame(
        row_name = c("dataset0__0", "dataset1__500", "dataset2__1000"),
        abiotic1 = c(5, 6, 7),
        abiotic2 = c(8, 9, 10)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_coords_example <-
      data.frame(
        row_name = c("dataset0", "dataset1", "dataset2", "dataset3"),
        coord_long = c(9, 10, 11, 12),
        coord_lat = c(12, 13, 14, 15)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_dummy <-
      check_and_prepare_data_for_fit(
        data_community = data_community_example,
        data_abiotic = data_abiotic_example,
        data_coords = data_coords_example
      )

    result <-
      get_random_structure_for_model(data_dummy, type = c("space", "age"))

    # Check the structure of the result
    testthat::expect_type(result, "list")

    testthat::expect_length(result, 2)

    testthat::expect_named(result, c("random_levels", "study_design"))

    result_random_effects <-
      result %>%
      purrr::chuck("random_levels")

    purrr::walk(
      .x = result_random_effects,
      .f = ~ testthat::expect_s3_class(.x, "HmscRandomLevel")
    )

    result_study_design <-
      result %>%
      purrr::chuck("study_design")

    testthat::expect_s3_class(result_study_design, "data.frame")
  }
)

testthat::test_that(
  desc = "get_random_structure_for_model function - space and age - correct values",
  code = {
    data_community_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000", "dataset3__1500"),
        species1 = c(1, 2, 3),
        species2 = c(4, 5, 6)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_abiotic_example <-
      data.frame(
        row_name = c("dataset0__0", "dataset1__500", "dataset2__1000"),
        abiotic1 = c(5, 6, 7),
        abiotic2 = c(8, 9, 10)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_coords_example <-
      data.frame(
        row_name = c("dataset0", "dataset1", "dataset2", "dataset3"),
        coord_long = c(9, 10, 11, 12),
        coord_lat = c(12, 13, 14, 15)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_dummy <-
      check_and_prepare_data_for_fit(
        data_community = data_community_example,
        data_abiotic = data_abiotic_example,
        data_coords = data_coords_example
      )

    result <-
      get_random_structure_for_model(data_dummy, type = c("space", "age"))

    result_random_effects <-
      result %>%
      purrr::chuck("random_levels")


    testthat::expect_length(result_random_effects, 2)

    testthat::expect_named(result_random_effects, c("age", "dataset_name"))

    result_random_effects_dataset_name <-
      result_random_effects %>%
      purrr::chuck("dataset_name")

    expected_result_random_effects_names_dataset_name <-
      c(
        "pi", "s", "sDim", "spatialMethod", "x", "xDim", "N",
        "distMat", "xMat", "nfMax", "nfMin", "nNeighbours", "sKnot", "nu", "a1",
        "b1", "a2", "b2", "alphapw", "call"
      )

    testthat::expect_equal(
      names(result_random_effects_dataset_name),
      expected_result_random_effects_names_dataset_name
    )

    result_random_effects_age <-
      result_random_effects %>%
      purrr::chuck("age")

    expected_result_random_effects_names_age <-
      c(
        "pi", "s", "sDim", "spatialMethod", "x", "xDim", "N",
        "distMat", "xMat", "nfMax", "nfMin", "nNeighbours", "nu", "a1",
        "b1", "a2", "b2", "alphapw", "call"
      )

    testthat::expect_equal(
      names(result_random_effects_age),
      expected_result_random_effects_names_age
    )

    result_study_design <-
      result %>%
      purrr::chuck("study_design")

    expected_result_study_design <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000"),
        dataset_name = factor(c("dataset1", "dataset2")),
        age = factor(c(500, 1000), levels = c(500, 1000), ordered = TRUE)
      ) %>%
      tibble::column_to_rownames("row_name")

    testthat::expect_equal(
      result_study_design,
      expected_result_study_design
    )
  }
)


testthat::test_that(
  desc = "get_random_structure_for_model function - handling error inputs",
  code = {
    data_community_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000", "dataset3__1500"),
        species1 = c(1, 2, 3),
        species2 = c(4, 5, 6)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_abiotic_example <-
      data.frame(
        row_name = c("dataset0__0", "dataset1__500", "dataset2__1000"),
        abiotic1 = c(5, 6, 7),
        abiotic2 = c(8, 9, 10)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_coords_example <-
      data.frame(
        row_name = c("dataset0", "dataset1", "dataset2", "dataset3"),
        coord_long = c(9, 10, 11, 12),
        coord_lat = c(12, 13, 14, 15)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_dummy <-
      check_and_prepare_data_for_fit(
        data_community = data_community_example,
        data_abiotic = data_abiotic_example,
        data_coords = data_coords_example
      )

    testthat::expect_error(
      get_random_structure_for_model(NULL)
    )

    testthat::expect_error(
      get_random_structure_for_model(list())
    )

    testthat::expect_error(
      get_random_structure_for_model("invalid_input")
    )

    testthat::expect_error(
      get_random_structure_for_model(data_dummy, type = NULL)
    )

    testthat::expect_error(
      get_random_structure_for_model(data_dummy, type = "invalid_type")
    )

    testthat::expect_error(
      get_random_structure_for_model(data_dummy, type = c("space", "invalid_type"))
    )

    testthat::expect_error(
      get_random_structure_for_model(data_dummy, min_knots_distance = "invalid_distance")
    )

    testthat::expect_error(
      get_random_structure_for_model(data_dummy, min_knots_distance = -1)
    )
  }
)
