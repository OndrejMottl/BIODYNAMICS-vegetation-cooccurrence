#' @title Compute a Reusable Spatial MEM Basis
#' @description
#' Computes exact or low-rank Moran eigenvectors and retains explicit state
#' required to project the same basis to held-out locations.
#' @param data_coords_projected
#' Data frame with `coord_x_km` and `coord_y_km` columns and unique row names.
#' @param n_mev
#' Positive integer giving the number of public eigenvectors requested.
#' @param strategy,exact_max_locations,fast_eigenvectors
#' Shared strategy settings validated by [resolve_spatial_mev_strategy()].
#' @param fast_seed
#' Positive integer used locally for deterministic Nyström knot selection.
#' @param exact_function
#' Exact Moran-eigenvector function. Defaults to
#' [sjSDM::generateSpatialEV()].
#' @param fast_function
#' Fast Moran-eigenvector function. Defaults to [spmoran::meigen_f()].
#' @return
#' Named list with `data_mev`, `projection_basis`, and one-row
#' `data_provenance`.
#' @details
#' Exact results retain the current sjSDM values unchanged. Fast results use
#' an exponential-kernel basis and orient each selected eigenvector
#' deterministically. The orientation is retained for matching projection.
#' @export
compute_spatial_mev_basis <- function(
    data_coords_projected = NULL,
    n_mev = 20L,
    strategy = "exact",
    exact_max_locations = 1999L,
    fast_eigenvectors = 200L,
    fast_seed = 900723L,
    exact_function = sjSDM::generateSpatialEV,
    fast_function = spmoran::meigen_f) {
  assertthat::assert_that(
    base::is.data.frame(data_coords_projected),
    msg = "data_coords_projected must be a data frame"
  )

  assertthat::assert_that(
    base::all(
      base::c("coord_x_km", "coord_y_km") %in%
        base::colnames(data_coords_projected)
    ),
    msg = stringr::str_c(
      "data_coords_projected must contain columns ",
      "'coord_x_km' and 'coord_y_km'"
    )
  )

  assertthat::assert_that(
    base::nrow(data_coords_projected) > 3L,
    msg = stringr::str_c(
      "data_coords_projected must have more than 3 rows ",
      "(required by spatial MEM construction)"
    )
  )

  assertthat::assert_that(
    !base::is.null(base::rownames(data_coords_projected)),
    !base::anyDuplicated(base::rownames(data_coords_projected)),
    msg = "`data_coords_projected` must have unique row names."
  )

  mat_coords <-
    data_coords_projected |>
    dplyr::select("coord_x_km", "coord_y_km") |>
    base::as.matrix()

  assertthat::assert_that(
    base::is.numeric(mat_coords),
    base::all(base::is.finite(mat_coords)),
    msg = "Projected spatial coordinates must contain only finite numbers."
  )

  assertthat::assert_that(
    base::is.numeric(fast_seed),
    base::length(fast_seed) == 1L,
    base::is.finite(fast_seed),
    fast_seed >= 1,
    fast_seed == base::as.integer(fast_seed),
    msg = "`fast_seed` must be one finite positive integer."
  )

  assertthat::assert_that(
    base::is.numeric(n_mev) || base::is.integer(n_mev),
    base::length(n_mev) == 1L,
    base::is.finite(n_mev),
    n_mev >= 1,
    n_mev == base::as.integer(n_mev),
    msg = "n_mev must be a single positive integer"
  )

  assertthat::assert_that(
    base::is.function(exact_function),
    base::is.function(fast_function),
    msg = "Exact and fast MEM construction arguments must be functions."
  )

  fast_seed_integer <-
    base::as.integer(fast_seed)

  list_strategy <-
    resolve_spatial_mev_strategy(
      strategy = strategy,
      n_locations = base::nrow(mat_coords),
      n_mev = n_mev,
      exact_max_locations = exact_max_locations,
      fast_eigenvectors = fast_eigenvectors
    )

  n_mev_integer <-
    list_strategy[["n_mev"]]

  n_unique_locations <-
    mat_coords |>
    base::as.data.frame() |>
    dplyr::distinct() |>
    base::nrow()

  if (
    list_strategy[["strategy_selected"]] == "fast" &&
      n_unique_locations <= list_strategy[["fast_eigenvectors"]]
  ) {
    cli::cli_abort(
      c(
        "Fast MEM construction has insufficient unique coordinates.",
        "i" = stringr::str_glue(
          "{n_unique_locations} unique locations were supplied."
        ),
        "i" = stringr::str_glue(
          "More than {list_strategy[['fast_eigenvectors']]} are required."
        )
      )
    )
  }

  start_time <-
    base::proc.time()[["elapsed"]]

  if (
    list_strategy[["strategy_selected"]] == "exact"
  ) {
    mat_mev_all <-
      exact_function(coords = mat_coords) |>
      base::as.matrix()

    list_fast_basis <- NULL
    engine_method <- "sjsdm_exact"
    projection_method <- "idw"
  } else {
    list_fast_basis <-
      withr::with_seed(
        seed = fast_seed_integer,
        code = fast_function(
          coords = mat_coords,
          model = "exp",
          enum = list_strategy[["fast_eigenvectors"]],
          threshold = 0,
          interact = FALSE
        )
      )

    assertthat::assert_that(
      base::is.list(list_fast_basis),
      base::is.matrix(list_fast_basis[["sf"]]),
      msg = "Fast MEM construction must return a matrix in `sf`."
    )

    mat_mev_all <-
      list_fast_basis[["sf"]]

    fast_flag <-
      list_fast_basis |>
      purrr::chuck("other", "fast")

    if (
      !base::identical(base::as.integer(fast_flag), 1L)
    ) {
      cli::cli_abort(
        c(
          "The requested fast MEM strategy did not use Nyström.",
          "i" = "Use at least 2,000 locations for the package fast path."
        )
      )
    }

    engine_method <- "spmoran_nystrom"
    projection_method <- engine_method
  }

  assertthat::assert_that(
    base::nrow(mat_mev_all) == base::nrow(mat_coords),
    base::ncol(mat_mev_all) > 0L,
    base::all(base::is.finite(mat_mev_all)),
    msg = "MEM construction must return finite values for every input row."
  )

  n_mev_produced <-
    base::ncol(mat_mev_all)

  if (
    n_mev_integer > n_mev_produced
  ) {
    cli::cli_warn(
      c(
        "{n_mev_integer} MEV(s) requested; only {n_mev_produced} available.",
        "i" = stringr::str_glue(
          "Lowering n_mev from ",
          "{n_mev_integer} to {n_mev_produced}."
        )
      )
    )

    n_mev_selected <- n_mev_produced
  } else {
    n_mev_selected <- n_mev_integer
  }

  vec_column_indices <-
    base::seq_len(n_mev_selected)

  mat_mev_selected_raw <-
    mat_mev_all[, vec_column_indices, drop = FALSE]

  vec_column_signs <-
    if (
      list_strategy[["strategy_selected"]] == "fast"
    ) {
      vec_anchor_rows <-
        vec_column_indices |>
        purrr::map_int(
          .f = ~ base::which.max(
            base::abs(mat_mev_selected_raw[, .x])
          )
        )

      purrr::map2_dbl(
        .x = vec_anchor_rows,
        .y = vec_column_indices,
        .f = ~ if (
          mat_mev_selected_raw[.x, .y] < 0
        ) {
          -1
        } else {
          1
        }
      )
    } else {
      base::rep(1, n_mev_selected)
    }

  mat_signs <-
    base::matrix(
      vec_column_signs,
      nrow = base::nrow(mat_mev_selected_raw),
      ncol = n_mev_selected,
      byrow = TRUE
    )

  mat_mev_selected <-
    mat_mev_selected_raw * mat_signs

  data_mev <-
    base::as.data.frame(mat_mev_selected)

  base::colnames(data_mev) <-
    stringr::str_c("mev_", vec_column_indices)

  base::rownames(data_mev) <-
    base::rownames(data_coords_projected)

  projection_basis <-
    if (
      list_strategy[["strategy_selected"]] == "fast"
    ) {
      base::list(
        method = projection_method,
        spmoran_basis = list_fast_basis,
        column_indices = vec_column_indices,
        column_signs = vec_column_signs
      )
    } else {
      NULL
    }

  elapsed_seconds <-
    base::as.numeric(base::proc.time()[["elapsed"]] - start_time)

  basis_bytes <-
    base::as.numeric(
      utils::object.size(
        base::list(
          data_mev = data_mev,
          projection_basis = projection_basis
        )
      )
    )

  estimated_dense_matrix_bytes <-
    base::as.numeric(base::nrow(mat_coords))^2 * 8

  data_provenance <-
    tibble::tibble(
      strategy_requested = list_strategy[["strategy_requested"]],
      strategy_selected = list_strategy[["strategy_selected"]],
      strategy_version = list_strategy[["strategy_version"]],
      engine_method = engine_method,
      projection_method = projection_method,
      n_input_locations = base::nrow(mat_coords),
      n_unique_locations = n_unique_locations,
      n_mev_requested = n_mev_integer,
      n_mev_available = n_mev_selected,
      fast_eigenvectors = list_strategy[["fast_eigenvectors"]],
      fast_seed = fast_seed_integer,
      elapsed_seconds = elapsed_seconds,
      basis_bytes = basis_bytes,
      estimated_dense_matrix_bytes = estimated_dense_matrix_bytes
    )

  res <-
    base::list(
      data_mev = data_mev,
      projection_basis = projection_basis,
      data_provenance = data_provenance
    )

  return(res)
}
