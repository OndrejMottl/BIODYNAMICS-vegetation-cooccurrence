#' @title Build Resolution-Aware Unit Target Requests
#' @description
#' Selects targets only for eligible resolutions, preserving requested unit
#' order. An empty request represents a wholly expected-infeasible unit.
#' @param data_preparation_plan
#' Classified unit-resolution rows returned by fitting preflight.
#' @param target_names Character vector of available resolution targets.
#' @return Named list of character target vectors, one per unit.
#' @examples
#' \dontrun{
#' build_sjsdm_unit_fitting_targets(data_preparation_plan, target_names)
#' }
#' @export
build_sjsdm_unit_fitting_targets <- function(
    data_preparation_plan,
    target_names) {
  assertthat::assert_that(
    base::is.data.frame(data_preparation_plan),
    base::all(base::c("scale_id", "resolution_id", "fitting_status") %in%
      base::names(data_preparation_plan)),
    base::all(data_preparation_plan[["fitting_status"]] %in%
      base::c("eligible", "expected_infeasible")),
    base::is.character(target_names), base::length(target_names) > 0L,
    base::all(!base::is.na(target_names)),
    base::all(base::nzchar(target_names)),
    msg = "Target requests require classified preparation and target names."
  )
  res <-
    base::unique(data_preparation_plan[["scale_id"]]) |>
    rlang::set_names() |>
    purrr::map(.f = ~ {
      scale_id <- .x
      vec_eligible_resolutions <-
        data_preparation_plan |>
        dplyr::filter(.data[["scale_id"]] == .env[["scale_id"]],
          .data[["fitting_status"]] == "eligible") |>
        dplyr::pull("resolution_id")
      vec_selected_targets <-
        if (
          base::length(vec_eligible_resolutions) == 0L
        ) {
          base::character()
        } else {
          target_names |>
          purrr::keep(.p = ~ base::any(stringr::str_ends(.x,
            stringr::str_c("_", vec_eligible_resolutions))))
        }
      if (
        base::length(vec_eligible_resolutions) > 0L &&
          base::length(vec_selected_targets) == 0L
      ) {
        cli::cli_abort("No fitting targets match eligible unit {scale_id}.")
      }
      return(vec_selected_targets)
    })
  return(res)
}
