#' @title Read sjSDM Tier Tuning Artifact
#' @description
#' Reads the shared tier artifact table and selects the row matching one unit
#' model context.
#' @param store_path
#' Character scalar path to the dedicated tier-tuning targets store.
#' @param data_model_context
#' One-row model-context table.
#' @param read_target_function
#' Injectable target reader. Defaults to [targets::tar_read_raw()].
#' @return
#' One matching artifact row, or `NULL` when the shared target is unavailable
#' or does not yet contain the requested context.
#' @examples
#' \dontrun{
#' load_sjsdm_tier_tuning_artifact(
#'   store_path = "Data/targets/paleo/pipeline_sjsdm_tier_tuning",
#'   data_model_context = data_sjsdm_model_context
#' )
#' }
#' @export
load_sjsdm_tier_tuning_artifact <- function(
    store_path = NULL,
    data_model_context = NULL,
    read_target_function = targets::tar_read_raw) {
  vec_context_columns <-
    base::c(
      "tier_id",
      "taxonomic_resolution",
      "response_family",
      "predictor_structure",
      "candidate_table_hash"
    )

  assertthat::assert_that(
    base::is.character(store_path),
    base::length(store_path) == 1L,
    base::nzchar(store_path),
    msg = "store_path must be one non-empty path."
  )

  assertthat::assert_that(
    base::is.data.frame(data_model_context),
    base::nrow(data_model_context) == 1L,
    base::all(
      vec_context_columns %in%
        base::colnames(data_model_context)
    ),
    msg = "data_model_context must contain one complete context row."
  )

  assertthat::assert_that(
    base::is.function(read_target_function),
    msg = "read_target_function must be a function."
  )

  list_artifact_v2 <-
    tryCatch(
      expr = read_target_function(
        name = "list_sjsdm_tier_tuning_artifact",
        store = store_path
      ),
      error = function(error_condition) {
        NULL
      }
    )

  data_artifacts <-
    if (
      base::is.null(list_artifact_v2)
    ) {
      tryCatch(
        expr = read_target_function(
          name = "data_sjsdm_tier_regularization_artifacts",
          store = store_path
        ),
        error = function(error_condition) {
          NULL
        }
      )
    } else {
      validate_sjsdm_artifact_envelope(
        list_artifact = list_artifact_v2,
        expected_artifact_type = "sjsdm_tier_tuning"
      )

      list_artifact_v2[["payload"]][[
        "data_regularization_selection"
      ]]
    }

  if (
    base::is.null(data_artifacts)
  ) {
    return(NULL)
  }

  assertthat::assert_that(
    base::is.data.frame(data_artifacts),
    base::all(
      vec_context_columns %in% base::colnames(data_artifacts)
    ),
    msg = "The tier artifact target has an invalid schema."
  )

  flag_matching <-
    vec_context_columns |>
    purrr::map(
      .f = ~ data_artifacts[[.x]] ==
        data_model_context[[.x]][[1L]]
    ) |>
    purrr::reduce(.f = `&`)

  data_matching <-
    data_artifacts[flag_matching, , drop = FALSE]

  if (
    base::nrow(data_matching) == 0L
  ) {
    return(NULL)
  }

  if (
    base::nrow(data_matching) > 1L
  ) {
    cli::cli_abort("Tier artifact context keys must be unique.")
  }

  return(data_matching)
}
