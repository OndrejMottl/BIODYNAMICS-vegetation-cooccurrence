#' @title Read sjSDM Tier Survivor Decisions
#' @description
#' Reads one round's survivor decisions from the isolated tier-tuning store
#' and selects the rows matching one unit model context. Missing, malformed,
#' or ambiguous evidence aborts so unit pipelines cannot prune locally.
#' @param store_path
#' Character scalar path to the dedicated tier-tuning targets store.
#' @param data_model_context
#' One-row model-context table.
#' @param round_id
#' Positive integer identifier of the completed tier tuning round.
#' @param read_target_function
#' Injectable target reader. Defaults to [targets::tar_read_raw()].
#' @return
#' Tier-wide decision tibble for the requested model context and round.
#' @export
load_sjsdm_tier_survivor_decisions <- function(
    store_path = NULL,
    data_model_context = NULL,
    round_id = NULL,
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
    !base::is.na(store_path),
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

  flag_valid_round_id <-
    base::is.numeric(round_id) &&
    base::length(round_id) == 1L &&
    base::is.finite(round_id) &&
    round_id >= 1L &&
    round_id == base::as.integer(round_id)

  assertthat::assert_that(
    flag_valid_round_id,
    msg = "round_id must be one positive integer."
  )

  assertthat::assert_that(
    base::is.function(read_target_function),
    msg = "read_target_function must be a function."
  )

  target_name <-
    stringr::str_glue(
      "data_sjsdm_tier_survivor_decisions_round_{round_id}"
    ) |>
    base::as.character()

  data_decisions <-
    tryCatch(
      expr = read_target_function(
        name = target_name,
        store = store_path
      ),
      error = function(error_condition) {
        error_condition
      }
    )

  if (
    base::inherits(data_decisions, "error")
  ) {
    cli::cli_abort(
      c(
        "Could not read tier survivor decisions.",
        "x" = base::conditionMessage(data_decisions)
      )
    )
  }

  vec_required_columns <-
    base::c(
      vec_context_columns,
      "round_id",
      "candidate_id",
      "staged_decision"
    )

  assertthat::assert_that(
    base::is.data.frame(data_decisions),
    base::all(
      vec_required_columns %in% base::colnames(data_decisions)
    ),
    msg = "The tier survivor target has an invalid schema."
  )

  flag_matching <-
    vec_context_columns |>
    purrr::map(
      .f = ~ data_decisions[[.x]] ==
        data_model_context[[.x]][[1L]]
    ) |>
    purrr::reduce(.f = `&`)

  flag_matching <-
    flag_matching & data_decisions[["round_id"]] == round_id

  res <-
    data_decisions[flag_matching, , drop = FALSE]

  if (
    base::nrow(res) == 0L
  ) {
    cli::cli_abort(
      "No tier survivor decisions match the requested context."
    )
  }

  flag_valid_decisions <-
    base::is.character(res[["candidate_id"]]) &&
    !base::any(base::duplicated(res[["candidate_id"]])) &&
    base::all(
      res[["staged_decision"]] %in% base::c("survive", "prune")
    )

  if (
    !flag_valid_decisions
  ) {
    cli::cli_abort(
      "Tier survivor decisions must be unique and valid."
    )
  }

  return(res)
}
