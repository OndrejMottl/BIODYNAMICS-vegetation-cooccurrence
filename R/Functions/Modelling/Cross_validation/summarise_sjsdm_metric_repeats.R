#' @title Summarise sjSDM Metric Repeats
#' @description
#' Summarises the distribution of repeat-level source estimates and paired
#' improvements returned by [summarise_sjsdm_fold_metrics()].
#' @param list_fold_metric_summaries
#' Named list returned by [summarise_sjsdm_fold_metrics()].
#' @return
#' Named list containing `data_source_repeat_distributions` and
#' `data_paired_repeat_distributions`. Each table reports the mean, median,
#' standard deviation, empirical 95 percent repeat interval, repeat counts, and
#' fold-taxon coverage across repeats. Paired output also reports the proportion
#' of evaluable repeats with positive model improvement.
#' @details
#' The 95 percent bounds are the 2.5th and 97.5th percentiles of repeat-level
#' estimates. They describe stability across the supplied repeated splits and
#' are not population-level confidence intervals.
#' @examples
#' \dontrun{
#' summarise_sjsdm_metric_repeats(
#'   list_fold_metric_summaries = list_fold_metric_summaries
#' )
#' }
#' @export
summarise_sjsdm_metric_repeats <- function(
    list_fold_metric_summaries = NULL) {
  assertthat::assert_that(
    base::is.list(list_fold_metric_summaries),
    msg = "list_fold_metric_summaries must be a list."
  )

  vec_required_elements <-
    base::c("data_source_summaries", "data_paired_improvements")

  assertthat::assert_that(
    base::all(
      vec_required_elements %in% base::names(list_fold_metric_summaries)
    ),
    msg = "list_fold_metric_summaries must preserve required elements."
  )

  data_source_summaries <-
    list_fold_metric_summaries |>
    purrr::chuck("data_source_summaries")

  data_paired_improvements <-
    list_fold_metric_summaries |>
    purrr::chuck("data_paired_improvements")

  assertthat::assert_that(
    base::is.data.frame(data_source_summaries),
    base::is.data.frame(data_paired_improvements),
    msg = "Fold metric summary elements must be data frames."
  )

  vec_required_source_columns <-
    base::c(
      "repeat_id",
      "prediction_source",
      "metric_id",
      "aggregation_id",
      "estimate",
      "fold_taxon_coverage"
    )

  vec_required_paired_columns <-
    base::c(
      "repeat_id",
      "metric_id",
      "improvement_direction",
      "aggregation_id",
      "estimate",
      "fold_taxon_coverage"
    )

  assertthat::assert_that(
    base::all(
      vec_required_source_columns %in%
        base::colnames(data_source_summaries)
    ),
    msg = "Source summaries must preserve all required columns."
  )

  assertthat::assert_that(
    base::all(
      vec_required_paired_columns %in%
        base::colnames(data_paired_improvements)
    ),
    msg = "Paired improvements must preserve all required columns."
  )

  assertthat::assert_that(
    base::is.numeric(data_source_summaries[["repeat_id"]]),
    base::is.character(data_source_summaries[["prediction_source"]]),
    base::is.character(data_source_summaries[["metric_id"]]),
    base::is.character(data_source_summaries[["aggregation_id"]]),
    base::is.numeric(data_source_summaries[["estimate"]]),
    base::is.numeric(data_source_summaries[["fold_taxon_coverage"]]),
    msg = "Source summary columns have invalid types."
  )

  assertthat::assert_that(
    base::is.numeric(data_paired_improvements[["repeat_id"]]),
    base::is.character(data_paired_improvements[["metric_id"]]),
    base::is.character(
      data_paired_improvements[["improvement_direction"]]
    ),
    base::is.character(data_paired_improvements[["aggregation_id"]]),
    base::is.numeric(data_paired_improvements[["estimate"]]),
    base::is.numeric(
      data_paired_improvements[["fold_taxon_coverage"]]
    ),
    msg = "Paired improvement columns have invalid types."
  )

  data_source_duplicate_keys <-
    data_source_summaries |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["prediction_source"]],
      .data[["metric_id"]],
      .data[["aggregation_id"]],
      name = "n_rows"
    ) |>
    dplyr::filter(.data[["n_rows"]] != 1L)

  data_paired_duplicate_keys <-
    data_paired_improvements |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["metric_id"]],
      .data[["improvement_direction"]],
      .data[["aggregation_id"]],
      name = "n_rows"
    ) |>
    dplyr::filter(.data[["n_rows"]] != 1L)

  if (
    base::nrow(data_source_duplicate_keys) > 0L ||
      base::nrow(data_paired_duplicate_keys) > 0L
  ) {
    cli::cli_abort("Repeat summary keys must be unique.")
  }

  flag_valid_source_estimates <-
    base::all(
      base::is.na(data_source_summaries[["estimate"]]) |
        base::is.finite(data_source_summaries[["estimate"]])
    )

  flag_valid_paired_estimates <-
    base::all(
      base::is.na(data_paired_improvements[["estimate"]]) |
        base::is.finite(data_paired_improvements[["estimate"]])
    )

  if (
    !flag_valid_source_estimates || !flag_valid_paired_estimates
  ) {
    cli::cli_abort("Repeat estimates must be finite or missing.")
  }

  flag_valid_source_coverage <-
    base::all(
      base::is.finite(
        data_source_summaries[["fold_taxon_coverage"]]
      )
    ) &&
    base::all(
      data_source_summaries[["fold_taxon_coverage"]] >= 0 &
        data_source_summaries[["fold_taxon_coverage"]] <= 1
    )

  flag_valid_paired_coverage <-
    base::all(
      base::is.finite(
        data_paired_improvements[["fold_taxon_coverage"]]
      )
    ) &&
    base::all(
      data_paired_improvements[["fold_taxon_coverage"]] >= 0 &
        data_paired_improvements[["fold_taxon_coverage"]] <= 1
    )

  if (
    !flag_valid_source_coverage || !flag_valid_paired_coverage
  ) {
    cli::cli_abort("Fold-taxon coverage must lie between zero and one.")
  }

  data_source_repeat_distributions <-
    if (
      base::nrow(data_source_summaries) == 0L
    ) {
      tibble::tibble(
        prediction_source = base::character(),
        metric_id = base::character(),
        aggregation_id = base::character(),
        estimate_mean = base::numeric(),
        estimate_median = base::numeric(),
        estimate_standard_deviation = base::numeric(),
        lwr_95 = base::numeric(),
        upr_95 = base::numeric(),
        n_repeats_evaluable = base::integer(),
        n_repeats_total = base::integer(),
        fold_taxon_coverage_mean = base::numeric(),
        fold_taxon_coverage_min = base::numeric(),
        fold_taxon_coverage_max = base::numeric()
      )
    } else {
      data_source_summaries |>
      dplyr::group_by(
      .data[["prediction_source"]],
      .data[["metric_id"]],
      .data[["aggregation_id"]]
    ) |>
    dplyr::summarise(
      estimate_mean = if (
        base::all(base::is.na(.data[["estimate"]]))
      ) {
        NA_real_
      } else {
        base::mean(.data[["estimate"]], na.rm = TRUE)
      },
      estimate_median = if (
        base::all(base::is.na(.data[["estimate"]]))
      ) {
        NA_real_
      } else {
        stats::median(.data[["estimate"]], na.rm = TRUE)
      },
      estimate_standard_deviation = if (
        base::sum(base::is.finite(.data[["estimate"]])) > 1L
      ) {
        stats::sd(.data[["estimate"]], na.rm = TRUE)
      } else {
        NA_real_
      },
      lwr_95 = if (
        base::all(base::is.na(.data[["estimate"]]))
      ) {
        NA_real_
      } else {
        stats::quantile(
          x = .data[["estimate"]],
          probs = 0.025,
          na.rm = TRUE,
          names = FALSE
        )
      },
      upr_95 = if (
        base::all(base::is.na(.data[["estimate"]]))
      ) {
        NA_real_
      } else {
        stats::quantile(
          x = .data[["estimate"]],
          probs = 0.975,
          na.rm = TRUE,
          names = FALSE
        )
      },
      n_repeats_evaluable = base::sum(
        base::is.finite(.data[["estimate"]])
      ),
      n_repeats_total = dplyr::n(),
      fold_taxon_coverage_mean = base::mean(
        .data[["fold_taxon_coverage"]]
      ),
      fold_taxon_coverage_min = base::min(
        .data[["fold_taxon_coverage"]]
      ),
      fold_taxon_coverage_max = base::max(
        .data[["fold_taxon_coverage"]]
      ),
      .groups = "drop"
    ) |>
      dplyr::arrange(
        .data[["prediction_source"]],
        .data[["metric_id"]],
        .data[["aggregation_id"]]
      )
    }

  data_paired_repeat_distributions <-
    if (
      base::nrow(data_paired_improvements) == 0L
    ) {
      tibble::tibble(
        metric_id = base::character(),
        improvement_direction = base::character(),
        aggregation_id = base::character(),
        estimate_mean = base::numeric(),
        estimate_median = base::numeric(),
        estimate_standard_deviation = base::numeric(),
        lwr_95 = base::numeric(),
        upr_95 = base::numeric(),
        n_repeats_evaluable = base::integer(),
        n_repeats_total = base::integer(),
        proportion_repeats_positive = base::numeric(),
        fold_taxon_coverage_mean = base::numeric(),
        fold_taxon_coverage_min = base::numeric(),
        fold_taxon_coverage_max = base::numeric()
      )
    } else {
      data_paired_improvements |>
      dplyr::group_by(
      .data[["metric_id"]],
      .data[["improvement_direction"]],
      .data[["aggregation_id"]]
    ) |>
    dplyr::summarise(
      estimate_mean = if (
        base::all(base::is.na(.data[["estimate"]]))
      ) {
        NA_real_
      } else {
        base::mean(.data[["estimate"]], na.rm = TRUE)
      },
      estimate_median = if (
        base::all(base::is.na(.data[["estimate"]]))
      ) {
        NA_real_
      } else {
        stats::median(.data[["estimate"]], na.rm = TRUE)
      },
      estimate_standard_deviation = if (
        base::sum(base::is.finite(.data[["estimate"]])) > 1L
      ) {
        stats::sd(.data[["estimate"]], na.rm = TRUE)
      } else {
        NA_real_
      },
      lwr_95 = if (
        base::all(base::is.na(.data[["estimate"]]))
      ) {
        NA_real_
      } else {
        stats::quantile(
          x = .data[["estimate"]],
          probs = 0.025,
          na.rm = TRUE,
          names = FALSE
        )
      },
      upr_95 = if (
        base::all(base::is.na(.data[["estimate"]]))
      ) {
        NA_real_
      } else {
        stats::quantile(
          x = .data[["estimate"]],
          probs = 0.975,
          na.rm = TRUE,
          names = FALSE
        )
      },
      n_repeats_evaluable = base::sum(
        base::is.finite(.data[["estimate"]])
      ),
      n_repeats_total = dplyr::n(),
      proportion_repeats_positive = if (
        base::sum(base::is.finite(.data[["estimate"]])) == 0L
      ) {
        NA_real_
      } else {
        base::sum(.data[["estimate"]] > 0, na.rm = TRUE) /
          base::sum(base::is.finite(.data[["estimate"]]))
      },
      fold_taxon_coverage_mean = base::mean(
        .data[["fold_taxon_coverage"]]
      ),
      fold_taxon_coverage_min = base::min(
        .data[["fold_taxon_coverage"]]
      ),
      fold_taxon_coverage_max = base::max(
        .data[["fold_taxon_coverage"]]
      ),
      .groups = "drop"
    ) |>
      dplyr::arrange(
        .data[["metric_id"]],
        .data[["aggregation_id"]]
      )
    }

  res <-
    base::list(
      data_source_repeat_distributions =
        data_source_repeat_distributions,
      data_paired_repeat_distributions =
        data_paired_repeat_distributions
    )

  return(res)
}
