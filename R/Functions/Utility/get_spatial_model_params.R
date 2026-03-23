#' @title Get Spatial Model Fitting Parameters from Grid Catalogue
#' @description
#' Retrieves the model fitting parameters for a given spatial unit ID
#' from the project's spatial grid CSV catalogue.
#' @param scale_id
#' A single character string identifying the spatial unit.
#' Must match exactly one row in the catalogue file.
#' @param file
#' Path to the spatial grid CSV file.
#' Default: `here::here("Data/Input/spatial_grid.csv")`.
#' @return
#' A named list with five elements:
#' \describe{
#'   \item{`n_iter`}{Integer. Number of training iterations.}
#'   \item{`n_step_size`}{
#'     Integer or `NULL`. SGD mini-batch size.
#'     `NULL` means auto (10 \% of sites), corresponding to
#'     an `NA` value in the CSV.
#'   }
#'   \item{`n_sampling`}{
#'     Integer. Monte Carlo samples per epoch.
#'   }
#'   \item{`n_samples_anova`}{
#'     Integer. Monte Carlo samples for ANOVA
#'     variation partitioning.
#'   }
#'   \item{`n_early_stopping`}{
#'     Integer or `NULL`. Early stopping patience — number of epochs
#'     without loss improvement before training halts.
#'     `NULL` means auto (20 \% of `iter`), corresponding to
#'     an `NA` value in the CSV.
#'     Passed as the `n_early_stopping` argument of
#'     `fit_jsdm_model()`.
#'   }
#' }
#' @details
#' Reads the CSV using `readr::read_csv`, filters to the row whose
#' `scale_id` column matches the supplied `scale_id` argument, and
#' constructs the parameter list. Validation ensures the file is
#' readable, has a `.csv` extension, contains the required columns,
#' and that exactly one row matches the requested `scale_id`.
#' `NA` values in the `n_step_size` and `n_early_stopping` columns are
#' converted to `NULL`.
#' @seealso get_spatial_window, get_active_config
#' @export
get_spatial_model_params <- function(
    scale_id,
    file = here::here("Data/Input/spatial_grid.csv")) {
  assertthat::assert_that(
    is.character(scale_id) && length(scale_id) == 1,
    msg = paste0(
      "`scale_id` must be a single character string.",
      " Got length: ", length(scale_id)
    )
  )

  assertthat::assert_that(
    assertthat::is.readable(file) &&
      assertthat::has_extension(file, "csv"),
    msg = "`file` must be a readable CSV file."
  )

  data_grid <-
    readr::read_csv(
      file = file,
      show_col_types = FALSE
    )

  vec_required_cols <-
    c(
      "scale_id",
      "n_iter",
      "n_step_size",
      "n_sampling",
      "n_samples_anova",
      "n_early_stopping"
    )

  assertthat::assert_that(
    base::all(vec_required_cols %in% base::names(data_grid)),
    msg = paste0(
      "`file` must contain columns: ",
      base::paste(vec_required_cols, collapse = ", "), "."
    )
  )

  data_row <-
    data_grid |>
    dplyr::filter(
      .data$scale_id == .env$scale_id
    )

  assertthat::assert_that(
    base::nrow(data_row) == 1,
    msg = paste0(
      "Expected exactly 1 row for scale_id '", scale_id, "'.",
      " Found: ", base::nrow(data_row)
    )
  )

  n_step_size_raw <-
    dplyr::pull(data_row, n_step_size)

  n_early_stopping_raw <-
    dplyr::pull(data_row, n_early_stopping)

  res <-
    list(
      n_iter = dplyr::pull(data_row, n_iter),
      n_step_size = if (
        base::is.na(n_step_size_raw)
      ) {
        NULL
      } else {
        n_step_size_raw
      },
      n_sampling = dplyr::pull(data_row, n_sampling),
      n_samples_anova = dplyr::pull(data_row, n_samples_anova),
      n_early_stopping = if (
        base::is.na(n_early_stopping_raw)
      ) {
        NULL
      } else {
        n_early_stopping_raw
      }
    )

  return(res)
}
