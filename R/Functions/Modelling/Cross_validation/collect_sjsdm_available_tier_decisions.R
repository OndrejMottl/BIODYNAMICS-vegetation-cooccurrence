#' @title Collect Available sjSDM Tier Decisions
#' @description
#' Discovers consecutive completed staged-round decisions in the isolated
#' tier store. A missing next round is a normal orchestration boundary;
#' errored targets, decision gaps, and malformed existing artifacts abort.
#' @param store_path
#' Character scalar path to the dedicated tier-tuning targets store.
#' @param data_model_context
#' One-row model-context table used to select decision rows.
#' @param n_non_final_rounds
#' Non-negative integer count of rounds that publish survivor decisions.
#' @param read_meta_function
#' Injectable metadata reader compatible with [load_targets_store_metadata()].
#' @param read_decision_function
#' Injectable decision reader compatible with
#' [read_sjsdm_tier_survivor_decisions()].
#' @return
#' Ordered list of consecutive decision tibbles beginning with round one.
#' @export
collect_sjsdm_available_tier_decisions <- function(
    store_path = NULL,
    data_model_context = NULL,
    n_non_final_rounds = NULL,
    read_meta_function = load_targets_store_metadata,
    read_decision_function = read_sjsdm_tier_survivor_decisions) {
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
    msg = "data_model_context must contain one row."
  )

  flag_valid_round_count <-
    base::is.numeric(n_non_final_rounds) &&
    base::length(n_non_final_rounds) == 1L &&
    base::is.finite(n_non_final_rounds) &&
    n_non_final_rounds >= 0L &&
    n_non_final_rounds == base::as.integer(n_non_final_rounds)

  assertthat::assert_that(
    flag_valid_round_count,
    msg = "n_non_final_rounds must be one non-negative integer."
  )

  assertthat::assert_that(
    base::is.function(read_meta_function),
    base::is.function(read_decision_function),
    msg = "Metadata and decision readers must be functions."
  )

  n_non_final_rounds <-
    base::as.integer(n_non_final_rounds)

  if (
    n_non_final_rounds == 0L
  ) {
    return(base::list())
  }

  data_meta <-
    read_meta_function(store_path = store_path)

  if (
    base::is.null(data_meta)
  ) {
    return(base::list())
  }

  assertthat::assert_that(
    base::is.data.frame(data_meta),
    base::all(base::c("name", "error") %in% base::colnames(data_meta)),
    msg = "Tier-store metadata must contain name and error columns."
  )

  vec_round_ids <-
    base::seq_len(n_non_final_rounds)

  vec_target_names <-
    stringr::str_c(
      "data_sjsdm_tier_survivor_decisions_round_",
      vec_round_ids
    )

  flag_target_exists <-
    vec_target_names %in% data_meta[["name"]]

  if (
    base::any(base::diff(base::as.integer(flag_target_exists)) > 0L)
  ) {
    cli::cli_abort(
      "Tier survivor targets contain a round gap."
    )
  }

  data_round_meta <-
    data_meta |>
    dplyr::filter(.data[["name"]] %in% .env[["vec_target_names"]])

  flag_errored <-
    !base::is.na(data_round_meta[["error"]]) &
    base::nzchar(data_round_meta[["error"]])

  if (
    base::any(flag_errored)
  ) {
    cli::cli_abort(
      "An existing tier survivor target is errored."
    )
  }

  n_available_rounds <-
    base::sum(flag_target_exists)

  if (
    n_available_rounds == 0L
  ) {
    return(base::list())
  }

  vec_available_rounds <-
    base::seq_len(n_available_rounds)

  res <-
    vec_available_rounds |>
    purrr::map(
      .f = ~ read_decision_function(
        store_path = store_path,
        data_model_context = data_model_context,
        round_id = .x
      )
    ) |>
    rlang::set_names(
      stringr::str_c("round_", vec_available_rounds)
    )

  return(res)
}
