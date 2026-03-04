testthat::test_that(
  "assemble_data_to_fit() errors if community not a matrix",
  {
    data_abiotic_scaled_list <- base::list(
      data_abiotic_scaled = tibble::tibble(
        .row_name = c("A__0", "B__0"),
        age = c(-50, 50),
        temp = c(-1.0, 1.0)
      ) |>
        tibble::column_to_rownames(".row_name"),
      scale_attributes = base::list()
    )
    data_coords_to_fit <- tibble::tibble(
      .row_name = c("A__0", "B__0"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames(".row_name")
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = base::as.data.frame(
          base::matrix(c(0, 1, 1, 0), nrow = 2)
        ),
        data_abiotic_scaled_list = data_abiotic_scaled_list,
        data_coords_to_fit = data_coords_to_fit
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() errors if abiotic list missing keys",
  {
    data_community_filtered <- base::matrix(
      c(0, 1, 1, 0),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    data_coords_to_fit <- tibble::tibble(
      .row_name = c("A__0", "B__0"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames(".row_name")
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = base::list(
          data_abiotic_scaled = tibble::tibble()
          # scale_attributes missing
        ),
        data_coords_to_fit = data_coords_to_fit
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() errors if coords is not a df",
  {
    data_community_filtered <- base::matrix(
      c(0, 1, 1, 0),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    data_abiotic_scaled_list <- base::list(
      data_abiotic_scaled = tibble::tibble(
        .row_name = c("A__0", "B__0"),
        age = c(-50, 50),
        temp = c(-1.0, 1.0)
      ) |>
        tibble::column_to_rownames(".row_name"),
      scale_attributes = base::list()
    )
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list,
        data_coords_to_fit = "not_a_df"
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() errors on mismatched row counts",
  {
    data_community_filtered <- base::matrix(
      c(0, 1, 1, 0),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    # abiotic has 3 rows but community has 2
    data_abiotic_scaled_list <- base::list(
      data_abiotic_scaled = tibble::tibble(
        .row_name = c("A__0", "B__0", "C__0"),
        age = c(-50, 0, 50),
        temp = c(-1.0, 0.0, 1.0)
      ) |>
        tibble::column_to_rownames(".row_name"),
      scale_attributes = base::list()
    )
    data_coords_to_fit <- tibble::tibble(
      .row_name = c("A__0", "B__0"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames(".row_name")
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list,
        data_coords_to_fit = data_coords_to_fit
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() errors on mismatched row names",
  {
    data_community_filtered <- base::matrix(
      c(0, 1, 1, 0),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    data_abiotic_scaled_list <- base::list(
      data_abiotic_scaled = tibble::tibble(
        .row_name = c("A__0", "C__0"),
        age = c(-50, 50),
        temp = c(-1.0, 1.0)
      ) |>
        tibble::column_to_rownames(".row_name"),
      scale_attributes = base::list()
    )
    data_coords_to_fit <- tibble::tibble(
      .row_name = c("A__0", "B__0"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames(".row_name")
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list,
        data_coords_to_fit = data_coords_to_fit
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() returns a named list",
  {
    data_community_filtered <- base::matrix(
      c(0, 1, 1, 0),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    data_abiotic_scaled_list <- base::list(
      data_abiotic_scaled = tibble::tibble(
        .row_name = c("A__0", "B__0"),
        age = c(-50, 50),
        temp = c(-1.0, 1.0)
      ) |>
        tibble::column_to_rownames(".row_name"),
      scale_attributes = base::list(
        age = base::list("scaled:center" = 50)
      )
    )
    data_coords_to_fit <- tibble::tibble(
      .row_name = c("A__0", "B__0"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames(".row_name")
    res <- assemble_data_to_fit(
      data_community_filtered = data_community_filtered,
      data_abiotic_scaled_list = data_abiotic_scaled_list,
      data_coords_to_fit = data_coords_to_fit
    )
    testthat::expect_true(
      base::is.list(res)
    )
    testthat::expect_true(
      base::all(
        c(
          "data_community_to_fit",
          "data_abiotic_to_fit",
          "data_coords_to_fit",
          "scale_attributes"
        ) %in% base::names(res)
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() community element is the input matrix",
  {
    data_community_filtered <- base::matrix(
      c(0, 1, 1, 0),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    data_abiotic_scaled_list <- base::list(
      data_abiotic_scaled = tibble::tibble(
        .row_name = c("A__0", "B__0"),
        age = c(-50, 50),
        temp = c(-1.0, 1.0)
      ) |>
        tibble::column_to_rownames(".row_name"),
      scale_attributes = base::list()
    )
    data_coords_to_fit <- tibble::tibble(
      .row_name = c("A__0", "B__0"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames(".row_name")
    res <- assemble_data_to_fit(
      data_community_filtered = data_community_filtered,
      data_abiotic_scaled_list = data_abiotic_scaled_list,
      data_coords_to_fit = data_coords_to_fit
    )
    community_out <- purrr::pluck(res, "data_community_to_fit")
    testthat::expect_true(
      base::is.matrix(community_out)
    )
    testthat::expect_equal(
      community_out,
      data_community_filtered
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() abiotic element is the scaled df",
  {
    data_community_filtered <- base::matrix(
      c(0, 1, 1, 0),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    data_abiotic_df <- tibble::tibble(
      .row_name = c("A__0", "B__0"),
      age = c(-50, 50),
      temp = c(-1.0, 1.0)
    ) |>
      tibble::column_to_rownames(".row_name")
    data_abiotic_scaled_list <- base::list(
      data_abiotic_scaled = data_abiotic_df,
      scale_attributes = base::list()
    )
    data_coords_to_fit <- tibble::tibble(
      .row_name = c("A__0", "B__0"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames(".row_name")
    res <- assemble_data_to_fit(
      data_community_filtered = data_community_filtered,
      data_abiotic_scaled_list = data_abiotic_scaled_list,
      data_coords_to_fit = data_coords_to_fit
    )
    abiotic_out <- purrr::pluck(res, "data_abiotic_to_fit")
    testthat::expect_true(
      base::is.data.frame(abiotic_out)
    )
    testthat::expect_equal(
      abiotic_out,
      data_abiotic_df
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() scale_attributes passed through",
  {
    data_community_filtered <- base::matrix(
      c(0, 1, 1, 0),
      nrow = 2,
      ncol = 2,
      dimnames = base::list(
        c("A__0", "B__0"),
        c("Pinus", "Betula")
      )
    )
    vec_scale_center <- 50.0
    data_abiotic_scaled_list <- base::list(
      data_abiotic_scaled = tibble::tibble(
        .row_name = c("A__0", "B__0"),
        age = c(-50, 50),
        temp = c(-1.0, 1.0)
      ) |>
        tibble::column_to_rownames(".row_name"),
      scale_attributes = base::list(
        age = base::list(
          "scaled:center" = vec_scale_center
        )
      )
    )
    data_coords_to_fit <- tibble::tibble(
      .row_name = c("A__0", "B__0"),
      coord_long = c(15.0, 16.0),
      coord_lat = c(50.0, 51.0)
    ) |>
      tibble::column_to_rownames(".row_name")
    res <- assemble_data_to_fit(
      data_community_filtered = data_community_filtered,
      data_abiotic_scaled_list = data_abiotic_scaled_list,
      data_coords_to_fit = data_coords_to_fit
    )
    attrs_out <- purrr::pluck(res, "scale_attributes")
    testthat::expect_true(
      "age" %in% base::names(attrs_out)
    )
    testthat::expect_equal(
      purrr::pluck(attrs_out, "age", "scaled:center"),
      vec_scale_center
    )
  }
)
