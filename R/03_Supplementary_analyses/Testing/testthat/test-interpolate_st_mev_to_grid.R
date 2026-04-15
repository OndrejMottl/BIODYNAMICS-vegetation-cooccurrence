# Helper: minimal valid inputs reused across all tests.

.make_st_mev_samples <- function() {
  data_out <-
    tibble::tibble(
      .rn = c(
        "site_a__0", "site_a__500",
        "site_b__0", "site_b__500",
        "site_c__0", "site_c__500"
      ),
      mev_1 = c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6),
      mev_2 = c(0.6, 0.5, 0.4, 0.3, 0.2, 0.1)
    ) |>
    tibble::column_to_rownames(".rn")
  return(data_out)
}

.make_coords_train <- function() {
  data_out <-
    tibble::tibble(
      .rn = c("site_a", "site_b", "site_c"),
      coord_x_km = c(100.0, 500.0, 900.0),
      coord_y_km = c(100.0, 500.0, 900.0)
    ) |>
    tibble::column_to_rownames(".rn")
  return(data_out)
}

.make_coords_pred <- function() {
  data_out <-
    tibble::tibble(
      .rn = c("grid_1", "grid_2"),
      coord_x_km = c(100.0, 700.0),
      coord_y_km = c(100.0, 700.0)
    ) |>
    tibble::column_to_rownames(".rn")
  return(data_out)
}

.make_scale_attrs <- function() {
  list_out <-
    base::list(
      mev_1 = base::list(
        "scaled:center" = 0.0,
        "scaled:scale" = 1.0
      ),
      mev_2 = base::list(
        "scaled:center" = 0.0,
        "scaled:scale" = 1.0
      )
    )
  return(list_out)
}

# ---- input validation: data_st_mev_samples ----

testthat::test_that(
  "errors when data_st_mev_samples is NULL",
  {
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = NULL,
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      ),
      regexp = "data_st_mev_samples must be a non-empty data frame"
    )
  }
)

testthat::test_that(
  "errors when data_st_mev_samples is not a data frame",
  {
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = base::list(mev_1 = 1.0),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      ),
      regexp = "data_st_mev_samples must be a non-empty data frame"
    )
  }
)

testthat::test_that(
  "errors when data_st_mev_samples has zero rows",
  {
    data_empty <-
      tibble::tibble(mev_1 = base::numeric(0))
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = data_empty,
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      ),
      regexp = "data_st_mev_samples must be a non-empty data frame"
    )
  }
)

# ---- input validation: data_coords_projected_train ----

testthat::test_that(
  "errors when data_coords_projected_train is NULL",
  {
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = NULL,
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      ),
      regexp = "data_coords_projected_train"
    )
  }
)

testthat::test_that(
  "errors when data_coords_projected_train is not a data frame",
  {
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = "not_a_df",
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      ),
      regexp = "data_coords_projected_train"
    )
  }
)

testthat::test_that(
  "errors when data_coords_projected_train lacks coord_x_km",
  {
    data_train_bad <-
      tibble::tibble(
        .rn = c("site_a", "site_b", "site_c"),
        coord_y_km = c(100.0, 500.0, 900.0)
      ) |>
      tibble::column_to_rownames(".rn")
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = data_train_bad,
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      ),
      regexp = "coord_x_km"
    )
  }
)

# ---- input validation: data_coords_projected_pred ----

testthat::test_that(
  "errors when data_coords_projected_pred is NULL",
  {
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = NULL,
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      ),
      regexp = "data_coords_projected_pred"
    )
  }
)

testthat::test_that(
  "errors when data_coords_projected_pred is not a data frame",
  {
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = 42L,
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      ),
      regexp = "data_coords_projected_pred"
    )
  }
)

testthat::test_that(
  "errors when data_coords_projected_pred lacks coord_y_km",
  {
    data_pred_bad <-
      tibble::tibble(
        .rn = c("grid_1", "grid_2"),
        coord_x_km = c(100.0, 700.0)
      ) |>
      tibble::column_to_rownames(".rn")
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = data_pred_bad,
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      ),
      regexp = "coord_y_km"
    )
  }
)

# ---- input validation: pred_age ----

testthat::test_that(
  "errors when pred_age is NULL",
  {
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = NULL,
        spatial_scale_attributes = .make_scale_attrs()
      ),
      regexp = "pred_age"
    )
  }
)

testthat::test_that(
  "errors when pred_age is character",
  {
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = "zero",
        spatial_scale_attributes = .make_scale_attrs()
      ),
      regexp = "pred_age"
    )
  }
)

testthat::test_that(
  "errors when pred_age has length greater than one",
  {
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = c(0L, 500L),
        spatial_scale_attributes = .make_scale_attrs()
      ),
      regexp = "pred_age"
    )
  }
)

# ---- input validation: spatial_scale_attributes ----

testthat::test_that(
  "errors when spatial_scale_attributes is NULL",
  {
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = 0L,
        spatial_scale_attributes = NULL
      ),
      regexp = "spatial_scale_attributes"
    )
  }
)

testthat::test_that(
  "errors when spatial_scale_attributes is an empty list",
  {
    testthat::expect_error(
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = 0L,
        spatial_scale_attributes = base::list()
      ),
      regexp = "spatial_scale_attributes"
    )
  }
)

# ---- output structure ----

testthat::test_that(
  "returns a data frame for valid inputs",
  {
    res <-
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      )
    testthat::expect_true(
      base::is.data.frame(res)
    )
  }
)

testthat::test_that(
  "returns a data frame with 2 rows",
  {
    res <-
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      )
    testthat::expect_equal(
      base::nrow(res),
      2L
    )
  }
)

testthat::test_that(
  "returns columns mev_1 and mev_2",
  {
    res <-
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      )
    testthat::expect_true(
      base::all(
        c("mev_1", "mev_2") %in% base::names(res)
      )
    )
  }
)

testthat::test_that(
  "row names match data_coords_projected_pred",
  {
    res <-
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      )
    testthat::expect_equal(
      base::rownames(res),
      c("grid_1", "grid_2")
    )
  }
)

testthat::test_that(
  "all output values are finite numbers",
  {
    res <-
      interpolate_st_mev_to_grid(
        data_st_mev_samples = .make_st_mev_samples(),
        data_coords_projected_train = .make_coords_train(),
        data_coords_projected_pred = .make_coords_pred(),
        pred_age = 0L,
        spatial_scale_attributes = .make_scale_attrs()
      )
    testthat::expect_true(
      base::all(
        base::is.finite(
          base::as.matrix(res)
        )
      )
    )
  }
)
