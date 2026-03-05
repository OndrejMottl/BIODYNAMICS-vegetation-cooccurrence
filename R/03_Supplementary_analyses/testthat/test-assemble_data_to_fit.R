testthat::test_that(
  "assemble_data_to_fit() errors if community not a matrix",
  {
    data_abiotic_scaled_list <-
      base::list(
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
        data_community_filtered = base::as.data.frame(
          base::matrix(c(0, 1, 1, 0), nrow = 2)
        ),
        data_abiotic_scaled_list = data_abiotic_scaled_list
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() errors if abiotic list missing keys",
  {
    data_community_filtered <-
      base::matrix(
        c(0, 1, 1, 0),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("A__0", "B__0"),
          c("Pinus", "Betula")
        )
      )
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = base::list(
          data_abiotic_scaled = tibble::tibble()
          # scale_attributes missing
        )
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() errors on mismatched row counts",
  {
    data_community_filtered <-
      base::matrix(
        c(0, 1, 1, 0),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("A__0", "B__0"),
          c("Pinus", "Betula")
        )
      )
    # abiotic has 3 rows but community has 2
    data_abiotic_scaled_list <-
      base::list(
        data_abiotic_scaled = tibble::tibble(
          .row_name = c("A__0", "B__0", "C__0"),
          age = c(-50, 0, 50),
          temp = c(-1.0, 0.0, 1.0)
        ) |>
          tibble::column_to_rownames(".row_name"),
        scale_attributes = base::list()
      )
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() errors on mismatched row names",
  {
    data_community_filtered <-
      base::matrix(
        c(0, 1, 1, 0),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("A__0", "B__0"),
          c("Pinus", "Betula")
        )
      )
    data_abiotic_scaled_list <-
      base::list(
        data_abiotic_scaled = tibble::tibble(
          .row_name = c("A__0", "C__0"),
          age = c(-50, 50),
          temp = c(-1.0, 1.0)
        ) |>
          tibble::column_to_rownames(".row_name"),
        scale_attributes = base::list()
      )
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() returns a named list",
  {
    data_community_filtered <-
      base::matrix(
        c(0, 1, 1, 0),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("A__0", "B__0"),
          c("Pinus", "Betula")
        )
      )
    data_abiotic_scaled_list <-
      base::list(
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
    res <-
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list
      )
    testthat::expect_true(base::is.list(res))
    testthat::expect_true(
      base::all(
        c(
          "data_community_to_fit",
          "data_abiotic_to_fit",
          "scale_attributes"
        ) %in% base::names(res)
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() community element is the input matrix",
  {
    data_community_filtered <-
      base::matrix(
        c(0, 1, 1, 0),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("A__0", "B__0"),
          c("Pinus", "Betula")
        )
      )
    data_abiotic_scaled_list <-
      base::list(
        data_abiotic_scaled = tibble::tibble(
          .row_name = c("A__0", "B__0"),
          age = c(-50, 50),
          temp = c(-1.0, 1.0)
        ) |>
          tibble::column_to_rownames(".row_name"),
        scale_attributes = base::list()
      )
    res <-
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list
      )
    community_out <-
      purrr::pluck(res, "data_community_to_fit")
    testthat::expect_true(base::is.matrix(community_out))
    testthat::expect_equal(
      community_out,
      data_community_filtered
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() abiotic element is the scaled df",
  {
    data_community_filtered <-
      base::matrix(
        c(0, 1, 1, 0),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("A__0", "B__0"),
          c("Pinus", "Betula")
        )
      )
    data_abiotic_df <-
      tibble::tibble(
        .row_name = c("A__0", "B__0"),
        age = c(-50, 50),
        temp = c(-1.0, 1.0)
      ) |>
      tibble::column_to_rownames(".row_name")
    data_abiotic_scaled_list <-
      base::list(
        data_abiotic_scaled = data_abiotic_df,
        scale_attributes = base::list()
      )
    res <-
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list
      )
    abiotic_out <-
      purrr::pluck(res, "data_abiotic_to_fit")
    testthat::expect_true(base::is.data.frame(abiotic_out))
    testthat::expect_equal(
      abiotic_out,
      data_abiotic_df
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() scale_attributes passed through",
  {
    data_community_filtered <-
      base::matrix(
        c(0, 1, 1, 0),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("A__0", "B__0"),
          c("Pinus", "Betula")
        )
      )
    vec_scale_center <- 50.0
    data_abiotic_scaled_list <-
      base::list(
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
    res <-
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list
      )
    attrs_out <-
      purrr::pluck(res, "scale_attributes")
    testthat::expect_true(
      "age" %in% base::names(attrs_out)
    )
    testthat::expect_equal(
      purrr::pluck(attrs_out, "age", "scaled:center"),
      vec_scale_center
    )
  }
)

#----------------------------------------------------------#
# data_spatial_scaled_list parameter tests -----
#----------------------------------------------------------#

testthat::test_that(
  "assemble_data_to_fit() errors if spatial list missing keys",
  {
    data_community_filtered <-
      base::matrix(
        c(0, 1, 1, 0),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("A__0", "B__0"),
          c("Pinus", "Betula")
        )
      )
    data_abiotic_scaled_list <-
      base::list(
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
        data_spatial_scaled_list = base::list(
          data_spatial_scaled = tibble::tibble()
          # spatial_scale_attributes missing
        )
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() errors on spatial row count mismatch",
  {
    data_community_filtered <-
      base::matrix(
        c(0, 1, 1, 0),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("A__0", "B__0"),
          c("Pinus", "Betula")
        )
      )
    data_abiotic_scaled_list <-
      base::list(
        data_abiotic_scaled = tibble::tibble(
          .row_name = c("A__0", "B__0"),
          age = c(-50, 50),
          temp = c(-1.0, 1.0)
        ) |>
          tibble::column_to_rownames(".row_name"),
        scale_attributes = base::list()
      )
    # 3 rows but community has 2
    data_spatial_scaled_list <-
      base::list(
        data_spatial_scaled = tibble::tibble(
          .row_name = c("A__0", "B__0", "C__0"),
          coord_x_km = c(-0.5, 0.0, 0.5),
          coord_y_km = c(-0.5, 0.0, 0.5)
        ) |>
          tibble::column_to_rownames(".row_name"),
        spatial_scale_attributes = base::list()
      )
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list,
        data_spatial_scaled_list = data_spatial_scaled_list
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() errors on spatial row name mismatch",
  {
    data_community_filtered <-
      base::matrix(
        c(0, 1, 1, 0),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("A__0", "B__0"),
          c("Pinus", "Betula")
        )
      )
    data_abiotic_scaled_list <-
      base::list(
        data_abiotic_scaled = tibble::tibble(
          .row_name = c("A__0", "B__0"),
          age = c(-50, 50),
          temp = c(-1.0, 1.0)
        ) |>
          tibble::column_to_rownames(".row_name"),
        scale_attributes = base::list()
      )
    # same row count but wrong names
    data_spatial_scaled_list <-
      base::list(
        data_spatial_scaled = tibble::tibble(
          .row_name = c("A__0", "C__0"),
          coord_x_km = c(-0.5, 0.5),
          coord_y_km = c(-0.5, 0.5)
        ) |>
          tibble::column_to_rownames(".row_name"),
        spatial_scale_attributes = base::list()
      )
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list,
        data_spatial_scaled_list = data_spatial_scaled_list
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() includes spatial in result when given",
  {
    data_community_filtered <-
      base::matrix(
        c(0, 1, 1, 0),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("A__0", "B__0"),
          c("Pinus", "Betula")
        )
      )
    data_abiotic_scaled_list <-
      base::list(
        data_abiotic_scaled = tibble::tibble(
          .row_name = c("A__0", "B__0"),
          age = c(-50, 50),
          temp = c(-1.0, 1.0)
        ) |>
          tibble::column_to_rownames(".row_name"),
        scale_attributes = base::list()
      )
    data_spatial_df <-
      tibble::tibble(
        .row_name = c("A__0", "B__0"),
        coord_x_km = c(-0.5, 0.5),
        coord_y_km = c(-0.5, 0.5)
      ) |>
      tibble::column_to_rownames(".row_name")
    data_spatial_scaled_list <-
      base::list(
        data_spatial_scaled = data_spatial_df,
        spatial_scale_attributes = base::list(
          coord_x_km = base::list("scaled:center" = 4500),
          coord_y_km = base::list("scaled:center" = 2900)
        )
      )
    res <-
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list,
        data_spatial_scaled_list = data_spatial_scaled_list
      )
    testthat::expect_true(
      "data_spatial_to_fit" %in% base::names(res)
    )
    testthat::expect_equal(
      purrr::pluck(res, "data_spatial_to_fit"),
      data_spatial_df
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() spatial_scale_attributes in result",
  {
    data_community_filtered <-
      base::matrix(
        c(0, 1, 1, 0),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("A__0", "B__0"),
          c("Pinus", "Betula")
        )
      )
    data_abiotic_scaled_list <-
      base::list(
        data_abiotic_scaled = tibble::tibble(
          .row_name = c("A__0", "B__0"),
          age = c(-50, 50),
          temp = c(-1.0, 1.0)
        ) |>
          tibble::column_to_rownames(".row_name"),
        scale_attributes = base::list()
      )
    vec_center_x <- 4500.0
    data_spatial_scaled_list <-
      base::list(
        data_spatial_scaled = tibble::tibble(
          .row_name = c("A__0", "B__0"),
          coord_x_km = c(-0.5, 0.5),
          coord_y_km = c(-0.5, 0.5)
        ) |>
          tibble::column_to_rownames(".row_name"),
        spatial_scale_attributes = base::list(
          coord_x_km = base::list("scaled:center" = vec_center_x)
        )
      )
    res <-
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list,
        data_spatial_scaled_list = data_spatial_scaled_list
      )
    testthat::expect_true(
      "spatial_scale_attributes" %in% base::names(res)
    )
    testthat::expect_equal(
      purrr::pluck(
        res,
        "spatial_scale_attributes",
        "coord_x_km",
        "scaled:center"
      ),
      vec_center_x
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() omits spatial keys when NULL",
  {
    data_community_filtered <-
      base::matrix(
        c(0, 1, 1, 0),
        nrow = 2,
        ncol = 2,
        dimnames = base::list(
          c("A__0", "B__0"),
          c("Pinus", "Betula")
        )
      )
    data_abiotic_scaled_list <-
      base::list(
        data_abiotic_scaled = tibble::tibble(
          .row_name = c("A__0", "B__0"),
          age = c(-50, 50),
          temp = c(-1.0, 1.0)
        ) |>
          tibble::column_to_rownames(".row_name"),
        scale_attributes = base::list()
      )
    res <-
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list
      )
    testthat::expect_false(
      "data_spatial_to_fit" %in% base::names(res)
    )
    testthat::expect_false(
      "spatial_scale_attributes" %in% base::names(res)
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
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = base::list(
          data_abiotic_scaled = tibble::tibble()
          # scale_attributes missing
        )
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
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list
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
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list
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
    res <- assemble_data_to_fit(
      data_community_filtered = data_community_filtered,
      data_abiotic_scaled_list = data_abiotic_scaled_list
    )
    testthat::expect_true(base::is.list(res))
    testthat::expect_true(
      base::all(
        c(
          "data_community_to_fit",
          "data_abiotic_to_fit",
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
    res <- assemble_data_to_fit(
      data_community_filtered = data_community_filtered,
      data_abiotic_scaled_list = data_abiotic_scaled_list
    )
    community_out <- purrr::pluck(res, "data_community_to_fit")
    testthat::expect_true(base::is.matrix(community_out))
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
    res <- assemble_data_to_fit(
      data_community_filtered = data_community_filtered,
      data_abiotic_scaled_list = data_abiotic_scaled_list
    )
    abiotic_out <- purrr::pluck(res, "data_abiotic_to_fit")
    testthat::expect_true(base::is.data.frame(abiotic_out))
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
    res <- assemble_data_to_fit(
      data_community_filtered = data_community_filtered,
      data_abiotic_scaled_list = data_abiotic_scaled_list
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

#----------------------------------------------------------#
# data_spatial_scaled_list parameter tests -----
#----------------------------------------------------------#

testthat::test_that(
  "assemble_data_to_fit() errors if spatial list missing keys",
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
        data_spatial_scaled_list = base::list(
          data_spatial_scaled = tibble::tibble()
          # spatial_scale_attributes missing
        )
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() errors on spatial row count mismatch",
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
    # 3 rows but community has 2
    data_spatial_scaled_list <- base::list(
      data_spatial_scaled = tibble::tibble(
        .row_name = c("A__0", "B__0", "C__0"),
        coord_x_km = c(-0.5, 0.0, 0.5),
        coord_y_km = c(-0.5, 0.0, 0.5)
      ) |>
        tibble::column_to_rownames(".row_name"),
      spatial_scale_attributes = base::list()
    )
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list,
        data_spatial_scaled_list = data_spatial_scaled_list
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() errors on spatial row name mismatch",
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
    # same row count but wrong names
    data_spatial_scaled_list <- base::list(
      data_spatial_scaled = tibble::tibble(
        .row_name = c("A__0", "C__0"),
        coord_x_km = c(-0.5, 0.5),
        coord_y_km = c(-0.5, 0.5)
      ) |>
        tibble::column_to_rownames(".row_name"),
      spatial_scale_attributes = base::list()
    )
    testthat::expect_error(
      assemble_data_to_fit(
        data_community_filtered = data_community_filtered,
        data_abiotic_scaled_list = data_abiotic_scaled_list,
        data_spatial_scaled_list = data_spatial_scaled_list
      )
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() includes spatial in result when given",
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
    data_spatial_df <- tibble::tibble(
      .row_name = c("A__0", "B__0"),
      coord_x_km = c(-0.5, 0.5),
      coord_y_km = c(-0.5, 0.5)
    ) |>
      tibble::column_to_rownames(".row_name")
    data_spatial_scaled_list <- base::list(
      data_spatial_scaled = data_spatial_df,
      spatial_scale_attributes = base::list(
        coord_x_km = base::list("scaled:center" = 4500),
        coord_y_km = base::list("scaled:center" = 2900)
      )
    )
    res <- assemble_data_to_fit(
      data_community_filtered = data_community_filtered,
      data_abiotic_scaled_list = data_abiotic_scaled_list,
      data_spatial_scaled_list = data_spatial_scaled_list
    )
    testthat::expect_true(
      "data_spatial_to_fit" %in% base::names(res)
    )
    testthat::expect_equal(
      purrr::pluck(res, "data_spatial_to_fit"),
      data_spatial_df
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() spatial_scale_attributes in result",
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
    vec_center_x <- 4500.0
    data_spatial_scaled_list <- base::list(
      data_spatial_scaled = tibble::tibble(
        .row_name = c("A__0", "B__0"),
        coord_x_km = c(-0.5, 0.5),
        coord_y_km = c(-0.5, 0.5)
      ) |>
        tibble::column_to_rownames(".row_name"),
      spatial_scale_attributes = base::list(
        coord_x_km = base::list("scaled:center" = vec_center_x)
      )
    )
    res <- assemble_data_to_fit(
      data_community_filtered = data_community_filtered,
      data_abiotic_scaled_list = data_abiotic_scaled_list,
      data_spatial_scaled_list = data_spatial_scaled_list
    )
    testthat::expect_true(
      "spatial_scale_attributes" %in% base::names(res)
    )
    testthat::expect_equal(
      purrr::pluck(
        res,
        "spatial_scale_attributes",
        "coord_x_km",
        "scaled:center"
      ),
      vec_center_x
    )
  }
)

testthat::test_that(
  "assemble_data_to_fit() omits spatial keys when NULL",
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
    res <- assemble_data_to_fit(
      data_community_filtered = data_community_filtered,
      data_abiotic_scaled_list = data_abiotic_scaled_list
    )
    testthat::expect_false(
      "data_spatial_to_fit" %in% base::names(res)
    )
    testthat::expect_false(
      "spatial_scale_attributes" %in% base::names(res)
    )
  }
)
