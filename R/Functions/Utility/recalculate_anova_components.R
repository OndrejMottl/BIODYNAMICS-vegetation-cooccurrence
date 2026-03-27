#' @title Recalculate ANOVA Components via Shapley-Allocated
#'   Percentages
#' @description
#' Converts a long-format ANOVA results table into per-age
#' percentages for the three unique variance-partitioning
#' components (Abiotic, Associations, Spatial) using a
#' Shapley equal-split allocation of intersection terms.
#' Negative Nagelkerke R² values are clamped to zero before
#' any computation.
#' @param data_source
#' A non-empty data frame with columns:
#' \describe{
#'   \item{age}{Numeric. Age (cal yr BP) of the time slice.}
#'   \item{component}{Character. Component label. May include
#'     any of the seven sjSDM variance-partitioning labels:
#'     \code{"Abiotic"}, \code{"Associations"},
#'     \code{"Spatial"}, \code{"Abiotic&Associations"},
#'     \code{"Abiotic&Spatial"},
#'     \code{"Associations&Spatial"}, and
#'     \code{"Abiotic&Associations&Spatial"}.
#'     Missing intersection labels are treated as zero.}
#'   \item{R2_Nagelkerke}{Numeric. Nagelkerke R² value.
#'     Values below zero are clamped to 0 internally.}
#' }
#' @return
#' A tibble with exactly 3 rows per age (one per unique
#' component) and columns \code{age}, \code{component},
#' \code{R2_Nagelkerke_adjusted}, and
#' \code{R2_Nagelkerke_percentage}:
#' \describe{
#'   \item{R2_Nagelkerke_adjusted}{Numeric.
#'     Shapley-adjusted R² for the component: the component's
#'     unique fraction plus an equal share of every
#'     intersection term that includes it.}
#'   \item{R2_Nagelkerke_percentage}{Numeric. Percentage of
#'     total adjusted R² explained by this component within
#'     the age slice:
#'     \code{R2_adjusted / sum(R2_adjusted) * 100}.
#'     \code{NA_real_} when the age-slice total is zero.}
#' }
#' @details
#' \strong{Negative clamping:} All \code{R2_Nagelkerke}
#' values are clamped to \eqn{[0, \infty)} before
#' allocation. Negative values arise from suppressor effects
#' and carry no directional attribution.
#'
#' \strong{Shapley equal-split allocation:} Each intersection
#' term is divided equally among its constituent unique
#' components, irrespective of unique-fraction magnitudes.
#' The three adjusted values therefore sum to the total of
#' all seven (clamped) fractions, preserving total explained
#' variance. Using equal splits rather than proportional
#' splits avoids a feedback loop in which a larger unique
#' fraction accumulates more shared variance, further
#' inflating its apparent importance.
#'
#' Concretely (where missing fractions are treated as 0):
#' \itemize{
#'   \item Abiotic_adj = F_A + F_AB/2 + F_AS/2 + F_ABS/3
#'   \item Assoc_adj   = F_B + F_AB/2 + F_BS/2 + F_ABS/3
#'   \item Spatial_adj = F_S + F_AS/2 + F_BS/2 + F_ABS/3
#' }
#' @seealso [extract_anova_fractions()],
#'   [aggregate_anova_components()]
#' @export
recalculate_anova_components <- function(data_source) {
  assertthat::assert_that(
    base::is.data.frame(data_source),
    base::nrow(data_source) > 0,
    msg = "'data_source' must be a non-empty data frame."
  )

  assertthat::assert_that(
    base::all(
      c("age", "component", "R2_Nagelkerke") %in%
        base::colnames(data_source)
    ),
    msg = paste0(
      "'data_source' must contain columns",
      " 'age', 'component', and 'R2_Nagelkerke'."
    )
  )

  # Return the clamped R2 for one component from a per-age
  #   slice. Returns 0 when the component row is absent.
  get_val <- function(data_slice, comp_name) {
    val <-
      data_slice |>
      dplyr::filter(.data$component == comp_name) |>
      dplyr::pull(.data$R2_clamped)
    if (base::length(val) == 0L) 0 else val[[1L]]
  }

  # Shapley equal-split allocation for one age group.
  #   Each intersection term is divided equally among its
  #   constituent unique components, regardless of their
  #   relative unique-fraction magnitudes.  This avoids the
  #   feedback loop where a larger unique fraction accumulates
  #   even more shared variance.
  compute_shapley <- function(.x, .y) {
    f_a   <- get_val(.x, "Abiotic")
    f_b   <- get_val(.x, "Associations")
    f_s   <- get_val(.x, "Spatial")
    f_ab  <- get_val(.x, "Abiotic&Associations")
    f_as  <- get_val(.x, "Abiotic&Spatial")
    f_bs  <- get_val(.x, "Associations&Spatial")
    f_abs <- get_val(.x, "Abiotic&Associations&Spatial")

    tibble::tibble(
      component = c("Abiotic", "Associations", "Spatial"),
      R2_Nagelkerke_adjusted = c(
        f_a + f_ab / 2 + f_as / 2 + f_abs / 3,
        f_b + f_ab / 2 + f_bs / 2 + f_abs / 3,
        f_s + f_as / 2 + f_bs / 2 + f_abs / 3
      )
    )
  }

  res <-
    data_source |>
    # Clamp negatives before allocation: negative values arise
    #   from suppressor effects and carry no directional
    #   attribution, so they should not reduce any component's
    #   share.
    dplyr::mutate(
      R2_clamped = base::pmax(.data$R2_Nagelkerke, 0)
    ) |>
    dplyr::group_by(.data$age) |>
    dplyr::group_modify(compute_shapley) |>
    dplyr::ungroup() |>
    dplyr::group_by(.data$age) |>
    dplyr::mutate(
      R2_Nagelkerke_percentage = {
        vec_sum <-
          base::sum(.data$R2_Nagelkerke_adjusted)
        if (vec_sum > 0) {
          .data$R2_Nagelkerke_adjusted / vec_sum * 100
        } else {
          base::rep(
            NA_real_,
            base::length(.data$R2_Nagelkerke_adjusted)
          )
        }
      }
    ) |>
    dplyr::ungroup()

  return(res)
}
