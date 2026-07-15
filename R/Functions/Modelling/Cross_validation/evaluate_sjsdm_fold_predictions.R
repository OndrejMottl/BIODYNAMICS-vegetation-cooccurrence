#' @title Evaluate sjSDM Predictions Within Cross-Validation Folds
#' @description
#' Calculates model and prevalence-null prediction metrics separately within
#' each repeat, fold, and taxon.
#' @param data_predictions
#' Long selected-candidate OOF prediction table returned in the data-prediction
#' element of [run_sjsdm_selected_candidate_folds()].
#' @param epsilon
#' Probability clipping tolerance passed to
#' [evaluate_binary_log_loss()]. Defaults to 1e-6.
#' @return
#' Tibble with one row per repeat, fold, taxon, prediction source, and metric.
#' Prediction sources are model and prevalence_null; metrics are Tjur R2,
#' AUC, and binary log loss.
#' @details
#' Unlike [evaluate_sjsdm_cross_validated_predictions()], this function never
#' pools probabilities from separately fitted fold models. Model and null
#' predictions are evaluated independently, so an unavailable model prediction
#' does not suppress a valid prevalence-null diagnostic.
#' @examples
#' \dontrun{
#' evaluate_sjsdm_fold_predictions(
#'   data_predictions = data_predictions
#' )
#' }
#' @export
evaluate_sjsdm_fold_predictions <- function(
    data_predictions = NULL,
    epsilon = 1e-6) {
  assertthat::assert_that(
    base::is.data.frame(data_predictions),
    msg = "data_predictions must be a data frame."
  )

  vec_required_columns <-
    base::c(
      "repeat_id",
      "fold_id",
      "row_index",
      "taxon",
      "observed",
      "predicted_probability",
      "null_probability",
      "prediction_status"
    )

  assertthat::assert_that(
    base::all(
      vec_required_columns %in% base::colnames(data_predictions)
    ),
    msg = "data_predictions must preserve all required columns."
  )

  flag_valid_epsilon <-
    base::is.numeric(epsilon) &&
    base::length(epsilon) == 1L &&
    base::is.finite(epsilon) &&
    epsilon > 0 &&
    epsilon < 0.5

  assertthat::assert_that(
    flag_valid_epsilon,
    msg = "epsilon must be one finite number between zero and 0.5."
  )

  assertthat::assert_that(
    base::is.numeric(data_predictions[["observed"]]),
    base::is.numeric(data_predictions[["predicted_probability"]]),
    base::is.numeric(data_predictions[["null_probability"]]),
    base::is.character(data_predictions[["prediction_status"]]),
    msg = "Prediction values and statuses have invalid types."
  )

  if (
    base::nrow(data_predictions) == 0L
  ) {
    res_empty <-
      tibble::tibble(
        repeat_id = base::integer(),
        fold_id = base::integer(),
        taxon = base::character(),
        prediction_source = base::character(),
        metric_id = base::character(),
        estimate = base::numeric(),
        metric_status = base::character(),
        n_observations = base::integer(),
        n_presences = base::integer(),
        n_absences = base::integer(),
        prevalence = base::numeric()
      )

    return(res_empty)
  }

  data_duplicate_keys <-
    data_predictions |>
    dplyr::count(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["row_index"]],
      .data[["taxon"]],
      name = "n_rows"
    ) |>
    dplyr::filter(.data[["n_rows"]] != 1L)

  if (
    base::nrow(data_duplicate_keys) > 0L
  ) {
    cli::cli_abort(
      "Repeat, fold, row, and taxon prediction keys must be unique."
    )
  }

  flag_valid_observed <-
    base::all(base::is.finite(data_predictions[["observed"]])) &&
    base::all(data_predictions[["observed"]] %in% base::c(0, 1))

  if (
    !flag_valid_observed
  ) {
    cli::cli_abort("Observed values must be finite and binary.")
  }

  vec_null_probability_finite <-
    data_predictions[["null_probability"]][
      base::is.finite(data_predictions[["null_probability"]])
    ]

  flag_valid_null_bounds <-
    base::all(
      vec_null_probability_finite >= 0 &
        vec_null_probability_finite <= 1
    )

  if (
    !flag_valid_null_bounds
  ) {
    cli::cli_abort("Finite null probabilities must lie between zero and one.")
  }

  data_ok_predictions <-
    data_predictions |>
    dplyr::filter(.data[["prediction_status"]] == "ok")

  flag_valid_model_probabilities <-
    base::all(
      base::is.finite(data_ok_predictions[["predicted_probability"]])
    ) &&
    base::all(
      data_ok_predictions[["predicted_probability"]] >= 0 &
        data_ok_predictions[["predicted_probability"]] <= 1
    )

  if (
    !flag_valid_model_probabilities
  ) {
    cli::cli_abort(
      "Rows with prediction status ok must contain valid probabilities."
    )
  }

  data_inconsistent_null <-
    data_predictions |>
    dplyr::filter(base::is.finite(.data[["null_probability"]])) |>
    dplyr::group_by(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["taxon"]]
    ) |>
    dplyr::summarise(
      n_null_probabilities =
        dplyr::n_distinct(.data[["null_probability"]]),
      .groups = "drop"
    ) |>
    dplyr::filter(.data[["n_null_probabilities"]] > 1L)

  if (
    base::nrow(data_inconsistent_null) > 0L
  ) {
    cli::cli_abort(
      "Fold-training null probabilities must be constant within each group."
    )
  }

  evaluate_source <- function(
      vec_observed,
      vec_probability,
      prediction_source,
      flag_complete,
      incomplete_status) {
    n_observations <-
      base::length(vec_observed)

    n_presences <-
      base::sum(vec_observed == 1)

    n_absences <-
      n_observations - n_presences

    prevalence <-
      n_presences / n_observations

    if (
      !flag_complete
    ) {
      res_incomplete <-
        tibble::tibble(
          prediction_source = prediction_source,
          metric_id = base::c("tjur_r2", "auc", "log_loss"),
          estimate = NA_real_,
          metric_status = incomplete_status,
          n_observations = base::as.integer(n_observations),
          n_presences = base::as.integer(n_presences),
          n_absences = base::as.integer(n_absences),
          prevalence = prevalence
        )

      return(res_incomplete)
    }

    data_tjur <-
      evaluate_tjur_r2(
        observed = vec_observed,
        predicted_probability = vec_probability
      ) |>
      dplyr::mutate(
        metric_id = "tjur_r2",
        estimate = .data[["tjur_r2"]]
      ) |>
      dplyr::select(
        "metric_id",
        "estimate",
        "metric_status",
        "n_observations",
        "n_presences",
        "n_absences",
        "prevalence"
      )

    data_auc <-
      evaluate_binary_auc(
        observed = vec_observed,
        predicted_probability = vec_probability
      ) |>
      dplyr::mutate(
        metric_id = "auc",
        estimate = .data[["auc"]]
      ) |>
      dplyr::select(
        "metric_id",
        "estimate",
        "metric_status",
        "n_observations",
        "n_presences",
        "n_absences",
        "prevalence"
      )

    data_log_loss <-
      evaluate_binary_log_loss(
        observed = vec_observed,
        predicted_probability = vec_probability,
        epsilon = epsilon
      ) |>
      dplyr::mutate(
        metric_id = "log_loss",
        estimate = .data[["log_loss"]]
      ) |>
      dplyr::select(
        "metric_id",
        "estimate",
        "metric_status",
        "n_observations",
        "n_presences",
        "n_absences",
        "prevalence"
      )

    res_source <-
      base::list(data_tjur, data_auc, data_log_loss) |>
      purrr::list_rbind() |>
      dplyr::mutate(
        prediction_source = prediction_source,
        .before = 1L
      )

    return(res_source)
  }

  data_group_keys <-
    data_predictions |>
    dplyr::distinct(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["taxon"]]
    ) |>
    dplyr::arrange(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["taxon"]]
    )

  data_fold_metrics <-
    purrr::pmap(
      .l = base::list(
        data_group_keys[["repeat_id"]],
        data_group_keys[["fold_id"]],
        data_group_keys[["taxon"]]
      ),
      .f = ~ {
        repeat_id_value <- ..1
        fold_id_value <- ..2
        taxon_value <- ..3

        data_group <-
          data_predictions |>
          dplyr::filter(
            .data[["repeat_id"]] == repeat_id_value,
            .data[["fold_id"]] == fold_id_value,
            .data[["taxon"]] == taxon_value
          ) |>
          dplyr::arrange(.data[["row_index"]])

        vec_observed <-
          data_group[["observed"]]

        vec_model_probability <-
          data_group[["predicted_probability"]]

        vec_null_probability <-
          data_group[["null_probability"]]

        flag_model_complete <-
          base::all(data_group[["prediction_status"]] == "ok") &&
          base::all(base::is.finite(vec_model_probability))

        flag_null_complete <-
          base::all(base::is.finite(vec_null_probability))

        data_model <-
          evaluate_source(
            vec_observed = vec_observed,
            vec_probability = vec_model_probability,
            prediction_source = "model",
            flag_complete = flag_model_complete,
            incomplete_status = "incomplete_predictions"
          )

        data_null <-
          evaluate_source(
            vec_observed = vec_observed,
            vec_probability = vec_null_probability,
            prediction_source = "prevalence_null",
            flag_complete = flag_null_complete,
            incomplete_status = "incomplete_null_predictions"
          )

        res_group <-
          base::list(data_model, data_null) |>
          purrr::list_rbind() |>
          dplyr::mutate(
            repeat_id = repeat_id_value,
            fold_id = fold_id_value,
            taxon = taxon_value,
            .before = 1L
          )

        return(res_group)
      }
    ) |>
    purrr::list_rbind() |>
    dplyr::arrange(
      .data[["repeat_id"]],
      .data[["fold_id"]],
      .data[["taxon"]],
      base::match(
        .data[["prediction_source"]],
        base::c("model", "prevalence_null")
      ),
      base::match(
        .data[["metric_id"]],
        base::c("tjur_r2", "auc", "log_loss")
      )
    )

  return(data_fold_metrics)
}
