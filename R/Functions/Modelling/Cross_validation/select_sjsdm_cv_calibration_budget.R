#' @title Select a Stable sjSDM CV Calibration Budget
#' @description
#' Selects the smallest benchmark budget whose repeat-one winner is converged
#' and stable at the next rung, then confirms that candidate in repeat two as
#' either the exact winner or a practically equivalent candidate.
#' @param data_benchmark
#' Candidate-fold benchmark table containing repeat, budget, fit, convergence,
#' and normalized held-out loss columns.
#' @param rank_threshold
#' Minimum Spearman candidate-loss rank correlation. Defaults to `0.95`.
#' @param relative_loss_tolerance
#' Maximum relative winning-loss change between rungs and maximum relative
#' gap above the repeat-two winner. Defaults to `0.02`.
#' @param n_folds_expected
#' Required fold coverage for every candidate and budget. Defaults to five.
#' @param require_repeat_two
#' Whether acceptance requires repeat-two practical equivalence.
#' @return
#' One-row accepted budget and stability-evidence tibble.
#' @examples
#' \dontrun{
#' select_sjsdm_cv_calibration_budget(data_benchmark)
#' }
#' @export
select_sjsdm_cv_calibration_budget <- function(
    data_benchmark = NULL,
    rank_threshold = 0.95,
    relative_loss_tolerance = 0.02,
    n_folds_expected = 5L,
    require_repeat_two = TRUE) {
  vec_required_columns <-
    base::c(
      "repeat_id",
      "budget_order",
      "fold_id",
      "candidate_id",
      "n_iter",
      "n_sampling",
      "converged",
      "normalized_loss"
    )

  assertthat::assert_that(
    base::is.data.frame(data_benchmark),
    base::all(vec_required_columns %in% base::colnames(data_benchmark)),
    base::nrow(data_benchmark) > 0L,
    msg = "Benchmark evidence is incomplete."
  )

  assertthat::assert_that(
    base::is.numeric(n_folds_expected),
    base::length(n_folds_expected) == 1L,
    base::is.finite(n_folds_expected),
    n_folds_expected > 0L,
    n_folds_expected == base::as.integer(n_folds_expected),
    msg = "n_folds_expected must be one positive integer."
  )
  assertthat::assert_that(
    base::is.logical(require_repeat_two),
    base::length(require_repeat_two) == 1L,
    !base::is.na(require_repeat_two),
    msg = "require_repeat_two must be TRUE or FALSE."
  )

  data_candidate_budget <-
    data_benchmark |>
    dplyr::group_by(
      .data[["repeat_id"]],
      .data[["budget_order"]],
      .data[["n_iter"]],
      .data[["n_sampling"]],
      .data[["candidate_id"]]
    ) |>
    dplyr::summarise(
      n_folds = dplyr::n_distinct(.data[["fold_id"]]),
      all_converged = base::all(.data[["converged"]] %in% TRUE),
      all_losses_finite = base::all(
        base::is.finite(.data[["normalized_loss"]])
      ),
      candidate_loss_raw = base::mean(.data[["normalized_loss"]]),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      candidate_complete =
        .data[["n_folds"]] == n_folds_expected &
        .data[["all_converged"]] &
        .data[["all_losses_finite"]],
      candidate_loss = dplyr::if_else(
        .data[["candidate_complete"]],
        .data[["candidate_loss_raw"]],
        NA_real_
      )
    )

  data_winners <-
    data_candidate_budget |>
    dplyr::filter(.data[["candidate_complete"]]) |>
    dplyr::group_by(.data[["repeat_id"]], .data[["budget_order"]]) |>
    dplyr::arrange(
      .data[["candidate_loss"]],
      .data[["candidate_id"]],
      .by_group = TRUE
    ) |>
    dplyr::slice_head(n = 1L) |>
    dplyr::ungroup()

  vec_repeat_one_orders <-
    data_winners |>
    dplyr::filter(.data[["repeat_id"]] == 1L) |>
    dplyr::arrange(.data[["budget_order"]]) |>
    dplyr::pull("budget_order")

  list_checks <-
    vec_repeat_one_orders |>
    purrr::map(
      .f = function(budget_order) {
        next_order <-
          vec_repeat_one_orders[vec_repeat_one_orders > budget_order] |>
          utils::head(1L)

        if (
          base::length(next_order) == 0L
        ) {
          return(NULL)
        }

        data_current <-
          data_candidate_budget |>
          dplyr::filter(
            .data[["repeat_id"]] == 1L,
            .data[["budget_order"]] == .env[["budget_order"]],
            .data[["candidate_complete"]]
          )
        data_next <-
          data_candidate_budget |>
          dplyr::filter(
            .data[["repeat_id"]] == 1L,
            .data[["budget_order"]] == next_order,
            .data[["candidate_complete"]]
          )
        data_pair <-
          data_current |>
          dplyr::select(
            "candidate_id",
            current_loss = "candidate_loss"
          ) |>
          dplyr::inner_join(
            data_next |>
              dplyr::select(
                "candidate_id",
                next_loss = "candidate_loss"
              ),
            by = "candidate_id"
          )
        n_candidates_compared <-
          base::nrow(data_pair)

        current_winner <-
          data_winners |>
          dplyr::filter(
            .data[["repeat_id"]] == 1L,
            .data[["budget_order"]] == .env[["budget_order"]]
          )
        next_winner <-
          data_winners |>
          dplyr::filter(
            .data[["repeat_id"]] == 1L,
            .data[["budget_order"]] == next_order
          )

        rank_correlation <-
          if (
            n_candidates_compared >= 2L
          ) {
            stats::cor(
              data_pair[["current_loss"]],
              data_pair[["next_loss"]],
              method = "spearman"
            )
          } else {
            NA_real_
          }

        relative_loss_change <-
          base::abs(
            next_winner[["candidate_loss"]][[1L]] -
              current_winner[["candidate_loss"]][[1L]]
          ) /
          base::max(
            base::abs(current_winner[["candidate_loss"]][[1L]]),
            .Machine[["double.eps"]]
          )

        data_repeat_confirmation <-
          data_candidate_budget |>
          dplyr::filter(
            .data[["budget_order"]] == .env[["budget_order"]]
          ) |>
          evaluate_sjsdm_cv_repeat_confirmation(
            provisional_candidate_id =
              current_winner[["candidate_id"]][[1L]],
            relative_loss_tolerance = relative_loss_tolerance
          )

        dplyr::bind_cols(
          tibble::tibble(
            budget_order = budget_order,
            next_budget_order = next_order,
            n_iter_initial = current_winner[["n_iter"]][[1L]],
            n_sampling = current_winner[["n_sampling"]][[1L]],
            candidate_id = current_winner[["candidate_id"]][[1L]],
            n_candidates_compared = n_candidates_compared,
            next_winner_unchanged = base::identical(
              current_winner[["candidate_id"]][[1L]],
              next_winner[["candidate_id"]][[1L]]
            ),
            rank_correlation = rank_correlation,
            relative_loss_change = relative_loss_change
          ),
          data_repeat_confirmation
        )
      }
    ) |>
    purrr::compact()

  data_checks <-
    purrr::list_rbind(list_checks)

  if (
    base::is.null(data_checks) || base::nrow(data_checks) == 0L
  ) {
    cli::cli_abort("No benchmark budget satisfies the stability checks.")
  }

  data_accepted <-
    data_checks |>
    dplyr::filter(
      .data[["next_winner_unchanged"]],
      base::is.finite(.data[["rank_correlation"]]),
      .data[["rank_correlation"]] >= rank_threshold,
      .data[["relative_loss_change"]] <= relative_loss_tolerance,
      !require_repeat_two | .data[["repeat_two_confirmed"]]
    ) |>
    dplyr::arrange(.data[["budget_order"]]) |>
    dplyr::slice_head(n = 1L)

  if (
    base::nrow(data_accepted) == 0L
  ) {
    cli::cli_abort("No benchmark budget satisfies the stability checks.")
  }

  res <-
    data_accepted |>
    dplyr::mutate(
      n_iter_max = base::pmin(
        base::as.integer(.data[["n_iter_initial"]] * 4L),
        64000L
      ),
      .after = "n_iter_initial"
    )

  return(res)
}
