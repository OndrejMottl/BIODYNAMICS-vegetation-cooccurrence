#' @title Load a Model Evaluation Target
#' @description
#' Loads one explicit fitted or cross-validated model-evaluation target from a
#' targets store. If the target cannot be read, `NULL` is returned.
#' @param store_path
#' A single character string with the targets store path.
#' @param resolution_id
#' A single non-empty character string identifying the model resolution.
#' @param evaluation_type
#' Evaluation target type. One of `"fitted"` or `"cross_validated"`.
#' @param read_target_fn
#' Function used to read the target. Defaults to
#' [targets::tar_read_raw()].
#' @return
#' The model evaluation object, or `NULL` if it cannot be read.
#' @examples
#' \dontrun{
#' load_model_evaluation_target(
#'   store_path = "Data/targets/modern_spatial_continental/europe",
#'   resolution_id = "genus",
#'   evaluation_type = "cross_validated"
#' )
#' }
#' @export
load_model_evaluation_target <- function(
    store_path,
    resolution_id,
    evaluation_type = base::c("fitted", "cross_validated"),
    read_target_fn = targets::tar_read_raw) {
  assertthat::assert_that(
    base::is.character(store_path) &&
      base::length(store_path) == 1L &&
      base::nchar(store_path) > 0L,
    msg = "`store_path` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(resolution_id) &&
      base::length(resolution_id) == 1L &&
      base::nchar(resolution_id) > 0L,
    msg = "`resolution_id` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.function(read_target_fn),
    msg = "`read_target_fn` must be a function."
  )

  assertthat::assert_that(
    base::is.character(evaluation_type),
    base::length(evaluation_type) >= 1L,
    base::all(
      evaluation_type %in% base::c("fitted", "cross_validated")
    ),
    msg = stringr::str_c(
      "`evaluation_type` must be either 'fitted' or",
      " 'cross_validated'."
    )
  )

  evaluation_type_selected <-
    base::match.arg(evaluation_type)

  res <-
    if (
      evaluation_type_selected == "fitted"
    ) {
      target_name <-
        stringr::str_glue(
          "list_jsdm_evaluation_fitted_{resolution_id}"
        ) |>
        base::as.character()

      purrr::possibly(
        .f = function() {
          read_target_fn(
            name = target_name,
            store = store_path
          )
        },
        otherwise = NULL
      )()
    } else {
      purrr::possibly(
        .f = function() {
          load_sjsdm_cv_payload_field(
            store_path = store_path,
            v2_target_name = stringr::str_glue(
              "list_sjsdm_cv_evaluation_artifact_{resolution_id}"
            ) |>
              base::as.character(),
            artifact_type = "sjsdm_cv_evaluation",
            payload_name = "list_pooled_evaluation",
            read_target_function = read_target_fn
          )
        },
        otherwise = NULL
      )()
    }

  return(res)
}
