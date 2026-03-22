# Helper: minimal valid inputs reused across multiple tests
# 5 sites, 3 ages each  -> 15 samples

.make_coords <- function() {
  tibble::tibble(
    dataset_name = c(
      "site_A", "site_B", "site_C", "site_D", "site_E"
    ),
    coord_x_km = c(100.0, 400.0, 700.0, 200.0, 600.0),
    coord_y_km = c(100.0, 500.0, 900.0, 300.0, 700.0)
  ) |>
    tibble::column_to_rownames("dataset_name")
}

.make_sample_ids <- function() {
  tidyr::expand_grid(
    dataset_name = c(
      "site_A", "site_B", "site_C", "site_D", "site_E"
    ),
    age = c(500L, 1000L, 2000L)
  )
}

# ---- input validation: data_coords_projected ----

testthat::test_that(
  "errors when data_coords_projected is not a data frame",
  {
    testthat::expect_error(
      compute_spatiotemporal_mev(
        data_coords_projected = "not_a_df",
        data_sample_ids = .make_sample_ids(),
        n_mev = 2L
      ),
      regexp = "data_coords_projected must be a data frame"
    )
  }
)

testthat::test_that(
  "errors when coord_x_km column is missing",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C"
        ),
        coord_y_km = c(400.0, 500.0, 600.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    testthat::expect_error(
      compute_spatiotemporal_mev(
        data_coords_projected = data_coords,
        data_sample_ids = .make_sample_ids(),
        n_mev = 2L
      ),
      regexp = "coord_x_km.*coord_y_km|coord_x_km"
    )
  }
)

testthat::test_that(
  "errors when coord_y_km column is missing",
  {
    data_coords <-
      tibble::tibble(
        dataset_name = c(
          "site_A", "site_B", "site_C"
        ),
        coord_x_km = c(100.0, 200.0, 300.0)
      ) |>
      tibble::column_to_rownames("dataset_name")

    testthat::expect_error(
      compute_spatiotemporal_mev(
        data_coords_projected = data_coords,
        data_sample_ids = .make_sample_ids(),
        n_mev = 2L
      ),
      regexp = "coord_x_km.*coord_y_km|coord_y_km"
    )
  }
)

# ---- input validation: data_sample_ids ----

testthat::test_that(
  "errors when data_sample_ids is not a data frame",
  {
    testthat::expect_error(
      compute_spatiotemporal_mev(
        data_coords_projected = .make_coords(),
        data_sample_ids = 42L,
        n_mev = 2L
      ),
      regexp = "data_sample_ids must be a data frame"
    )
  }
)

testthat::test_that(
  "errors when data_sample_ids is missing dataset_name",
  {
    data_ids <-
      tibble::tibble(
        age = c(500L, 1000L, 2000L)
      )

    testthat::expect_error(
      compute_spatiotemporal_mev(
        data_coords_projected = .make_coords(),
        data_sample_ids = data_ids,
        n_mev = 2L
      ),
      regexp = "dataset_name"
    )
  }
)

testthat::test_that(
  "errors when data_sample_ids is missing age",
  {
    data_ids <-
      tibble::tibble(
        dataset_name = c("site_A", "site_B", "site_C")
      )

    testthat::expect_error(
      compute_spatiotemporal_mev(
        data_coords_projected = .make_coords(),
        data_sample_ids = data_ids,
        n_mev = 2L
      ),
      regexp = "age"
    )
  }
)

# ---- input validation: n_mev ----

testthat::test_that(
  "errors when n_mev is zero",
  {
    testthat::expect_error(
      compute_spatiotemporal_mev(
        data_coords_projected = .make_coords(),
        data_sample_ids = .make_sample_ids(),
        n_mev = 0L
      ),
      regexp = "n_mev must be a single positive integer"
    )
  }
)

testthat::test_that(
  "errors when n_mev is negative",
  {
    testthat::expect_error(
      compute_spatiotemporal_mev(
        data_coords_projected = .make_coords(),
        data_sample_ids = .make_sample_ids(),
        n_mev = -1L
      ),
      regexp = "n_mev must be a single positive integer"
    )
  }
)

testthat::test_that(
  "errors when n_mev is a character",
  {
    testthat::expect_error(
      compute_spatiotemporal_mev(
        data_coords_projected = .make_coords(),
        data_sample_ids = .make_sample_ids(),
        n_mev = "two"
      ),
      regexp = "n_mev must be a single positive integer"
    )
  }
)

testthat::test_that(
  "warns and clamps n_mev when it exceeds positive EVs",
  {
    # 15 samples: 5 sites x 3 ages; likely produces only a
    # handful of positive EVs. Requesting 100 must warn
    # and clamp to the actual count.
    res <-
      testthat::expect_warning(
        compute_spatiotemporal_mev(
          data_coords_projected = .make_coords(),
          data_sample_ids = .make_sample_ids(),
          n_mev = 100L
        ),
        regexp = "Lowering n_mev"
      )

    testthat::expect_true(
      base::ncol(res) < 100L
    )
  }
)

# ---- happy-path output checks ----

testthat::test_that(
  "returns a data frame on valid input",
  {
    res <-
      compute_spatiotemporal_mev(
        data_coords_projected = .make_coords(),
        data_sample_ids = .make_sample_ids(),
        n_mev = 2L
      )

    testthat::expect_true(
      base::is.data.frame(res)
    )
  }
)

testthat::test_that(
  "result has exactly n_mev columns",
  {
    res <-
      compute_spatiotemporal_mev(
        data_coords_projected = .make_coords(),
        data_sample_ids = .make_sample_ids(),
        n_mev = 2L
      )

    testthat::expect_equal(
      base::ncol(res),
      2L
    )
  }
)

testthat::test_that(
  "result columns are named mev_1, mev_2",
  {
    res <-
      compute_spatiotemporal_mev(
        data_coords_projected = .make_coords(),
        data_sample_ids = .make_sample_ids(),
        n_mev = 2L
      )

    testthat::expect_equal(
      base::colnames(res),
      c("mev_1", "mev_2")
    )
  }
)

testthat::test_that(
  "result has one row per sample (nrow == nrow sample_ids)",
  {
    data_sample_ids <-
      .make_sample_ids()

    res <-
      compute_spatiotemporal_mev(
        data_coords_projected = .make_coords(),
        data_sample_ids = data_sample_ids,
        n_mev = 2L
      )

    testthat::expect_equal(
      base::nrow(res),
      base::nrow(data_sample_ids)
    )
  }
)

testthat::test_that(
  "row names follow dataset_name__age format",
  {
    res <-
      compute_spatiotemporal_mev(
        data_coords_projected = .make_coords(),
        data_sample_ids = .make_sample_ids(),
        n_mev = 2L
      )

    # dataset names may contain single underscores;
    # separator is double underscore followed by digits
    pattern <- "^.+__[0-9]+$"
    vec_row_names <-
      base::rownames(res)

    testthat::expect_true(
      base::all(
        base::grepl(pattern = pattern, x = vec_row_names)
      )
    )
  }
)

testthat::test_that(
  "result contains only finite numeric values",
  {
    res <-
      compute_spatiotemporal_mev(
        data_coords_projected = .make_coords(),
        data_sample_ids = .make_sample_ids(),
        n_mev = 2L
      )

    testthat::expect_true(
      base::all(
        base::is.finite(base::as.matrix(res))
      )
    )
  }
)

testthat::test_that(
  "sites with different ages receive different MEV values",
  {
    res <-
      compute_spatiotemporal_mev(
        data_coords_projected = .make_coords(),
        data_sample_ids = .make_sample_ids(),
        n_mev = 2L
      )

    # Extract rows for site_A at two different ages
    row_a_500 <-
      dplyr::filter(
        tibble::rownames_to_column(res, "row_name"),
        row_name == "site_A__500"
      ) |>
      dplyr::select(-row_name)

    row_a_2000 <-
      dplyr::filter(
        tibble::rownames_to_column(res, "row_name"),
        row_name == "site_A__2000"
      ) |>
      dplyr::select(-row_name)

    # 3-D MEVs must differ between ages (unlike 2-D MEVs
    # which are identical across ages for the same site)
    testthat::expect_false(
      base::isTRUE(
        base::all.equal(
          base::as.numeric(row_a_500),
          base::as.numeric(row_a_2000)
        )
      )
    )
  }
)
