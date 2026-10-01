#' @title Get Model Tuning Parameters
#' @description
#' Reads model-fitting parameters for one analysis, spatial unit, and
#' resolution from the model tuning CSV catalogue.
#' @param analysis_id
#' A single non-empty character string identifying the analysis family,
#' such as `"paleo_spatial"` or `"modern_spatial"`.
#' @param scale_id
#' A single non-empty character string identifying the spatial unit.
#' Must match exactly one row in the selected tuning file.
#' @param resolution_id
#' A single character string identifying the model resolution. `"genus"`
#' reads the `*_genus.csv` file, `"family"` reads the `*_family.csv`
#' file, and `"functional_type"`, `"ft_paleo"`, and `"ft_modern"` read
#' the `*_ft.csv` file.
#' @param dir
#' Directory containing model tuning CSV files.
#' Default: `here::here("Data/Input/Model_tuning")`.
#' @param fit_stage
#' Fitting stage to load. `"final"` returns the historical full-data model
#' budget. `"cross_validation"` returns the independent CV fit budget.
#' @return
#' A named stage-specific fitting list. Missing step-size and early-stopping
#' values are returned as `NULL`.
#' @export
load_model_tuning_parameters <- function(
    analysis_id,
    scale_id,
    resolution_id,
    dir = here::here("Data/Input/Model_tuning"),
    fit_stage = c("final", "cross_validation")) {
  fit_stage <-
    base::match.arg(fit_stage)

  assertthat::assert_that(
    base::is.character(analysis_id) &&
      base::length(analysis_id) == 1L &&
      base::nchar(analysis_id) > 0L,
    msg = "`analysis_id` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(scale_id) &&
      base::length(scale_id) == 1L &&
      base::nchar(scale_id) > 0L,
    msg = "`scale_id` must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.character(resolution_id) &&
      base::length(resolution_id) == 1L &&
      resolution_id %in% c(
        "genus",
        "family",
        "functional_type",
        "ft_paleo",
        "ft_modern"
      ),
    msg = stringr::str_glue(
      "`resolution_id` must be one of 'genus', 'family', ",
      "'functional_type', 'ft_paleo', or 'ft_modern'. Got: ",
      "'{resolution_id}'."
    )
  )

  assertthat::assert_that(
    base::is.character(dir) &&
      base::length(dir) == 1L &&
      base::dir.exists(dir),
    msg = "`dir` must be an existing directory."
  )

  assertthat::assert_that(
    stringr::str_detect(analysis_id, "^[A-Za-z0-9_]+$"),
    msg = "`analysis_id` may only contain letters, numbers, and underscores."
  )

  resolution_suffix <-
    dplyr::case_when(
      resolution_id == "genus" ~ "genus",
      resolution_id == "family" ~ "family",
      resolution_id %in% c("functional_type", "ft_paleo", "ft_modern") ~ "ft"
    )

  file_tuning <-
    base::file.path(
      dir,
      stringr::str_glue(
        "model_tuning_{analysis_id}_{resolution_suffix}.csv"
      )
    )

  assertthat::assert_that(
    base::file.exists(file_tuning) &&
      assertthat::has_extension(file_tuning, "csv"),
    msg = stringr::str_glue(
      "Model tuning file not found or not a CSV: {file_tuning}"
    )
  )

  data_tuning <-
    readr::read_csv(
      file = file_tuning,
      show_col_types = FALSE,
      na = c("", "NA")
    )

  vec_required_cols <-
    if (
      fit_stage == "final"
    ) {
      base::c(
        "scale_id",
        "n_iter",
        "n_step_size",
        "n_sampling",
        "n_samples_anova",
        "n_early_stopping"
      )
    } else {
      base::c(
        "scale_id",
        "cv_n_iter_initial",
        "cv_n_iter_max",
        "cv_n_sampling",
        "cv_n_step_size",
        "cv_n_early_stopping"
      )
    }

  assertthat::assert_that(
    base::all(vec_required_cols %in% base::names(data_tuning)),
    msg = if (
      fit_stage == "cross_validation"
    ) {
      stringr::str_c(
        "Production CV fitting cannot start because the tuning file does ",
        "not contain cv_n_iter_initial and the other CV-budget columns. ",
        "Prepare folds with ",
        "stage 01 preparation, then run stage 02 model calibration under ",
        "R/02_Main_analyses/02_Model_calibration, ",
        "regenerate config.yml, unset the flag, and rerun production."
      )
    } else {
      stringr::str_glue(
        "`file_tuning` must contain columns: ",
        "{stringr::str_c(vec_required_cols, collapse = ', ')}."
      )
    }
  )

  data_row <-
    data_tuning |>
    dplyr::filter(
      .data$scale_id == .env$scale_id
    )

  assertthat::assert_that(
    base::nrow(data_row) == 1L,
    msg = stringr::str_glue(
      "Expected exactly 1 row for scale_id '{scale_id}' in ",
      "{file_tuning}. Found: {base::nrow(data_row)}."
    )
  )

  if (
    fit_stage == "cross_validation"
  ) {
    vec_required_cv_columns <-
      base::c(
        "cv_n_iter_initial",
        "cv_n_iter_max",
        "cv_n_sampling"
      )
    vec_invalid_cv_columns <-
      vec_required_cv_columns[
        purrr::map_lgl(
          data_row[vec_required_cv_columns],
          ~ base::length(.x) != 1L ||
            !base::is.numeric(.x) ||
            !base::is.finite(.x) ||
            .x <= 0L ||
            .x != base::as.integer(.x)
        )
      ]

    if (
      base::length(vec_invalid_cv_columns) > 0L
    ) {
      cli::cli_abort(
        base::c(
          "Production CV fitting is not ready for this analysis unit.",
          "x" = stringr::str_glue(
            "Unpublished or invalid fields for {analysis_id}/{scale_id}/",
            "{resolution_id}: ",
            "{stringr::str_c(vec_invalid_cv_columns, collapse = ', ')}."
          ),
          "1" = paste(
            "Run R/02_Main_analyses/01_Preparation/",
            "01_run_preparation.R to cache current prepared folds."
          ),
          "2" = paste(
            "Run R/02_Main_analyses/02_Model_calibration/",
            "01_run_model_calibration.R."
          ),
          "3" = paste(
            "Then run R/02_Main_analyses/03_Model_fitting/",
            "01_run_model_fitting.R; cached preprocessing will be reused."
          ),
          "i" = paste(
            "Final-model n_iter and n_sampling values are deliberately not",
            "used as CV fallbacks."
          )
        )
      )
    }
  }

  if (
    fit_stage == "final"
  ) {
    res <-
      list(
        n_iter = extract_model_tuning_integer(
          data_tuning_row = data_row,
          column_name = "n_iter",
          scale_id = scale_id
        ),
        n_step_size = extract_model_tuning_integer(
          data_tuning_row = data_row,
          column_name = "n_step_size",
          scale_id = scale_id,
          required = FALSE
        ),
        n_sampling = extract_model_tuning_integer(
          data_tuning_row = data_row,
          column_name = "n_sampling",
          scale_id = scale_id
        ),
        n_samples_anova = extract_model_tuning_integer(
          data_tuning_row = data_row,
          column_name = "n_samples_anova",
          scale_id = scale_id
        ),
        n_early_stopping = extract_model_tuning_integer(
          data_tuning_row = data_row,
          column_name = "n_early_stopping",
          scale_id = scale_id,
          required = FALSE
        )
      )

    return(res)
  }

  res <-
    list(
      n_iter_initial = extract_model_tuning_integer(
        data_tuning_row = data_row,
        column_name = "cv_n_iter_initial",
        scale_id = scale_id
      ),
      n_iter_max = extract_model_tuning_integer(
        data_tuning_row = data_row,
        column_name = "cv_n_iter_max",
        scale_id = scale_id
      ),
      n_sampling = extract_model_tuning_integer(
        data_tuning_row = data_row,
        column_name = "cv_n_sampling",
        scale_id = scale_id
      ),
      n_step_size = extract_model_tuning_integer(
        data_tuning_row = data_row,
        column_name = "cv_n_step_size",
        scale_id = scale_id,
        required = FALSE
      ),
      n_early_stopping = extract_model_tuning_integer(
        data_tuning_row = data_row,
        column_name = "cv_n_early_stopping",
        scale_id = scale_id,
        required = FALSE
      )
    )

  vec_positive_names <-
    base::c("n_iter_initial", "n_iter_max", "n_sampling")

  assertthat::assert_that(
    base::all(
      purrr::map_lgl(
        res[vec_positive_names],
        ~ base::is.numeric(.x) &&
          base::length(.x) == 1L &&
          base::is.finite(.x) &&
          .x > 0L
      )
    ),
    msg = stringr::str_c(
      "CV n_iter_initial, n_iter_max, and n_sampling must be ",
      "positive finite integers."
    )
  )

  assertthat::assert_that(
    res[["n_iter_max"]] >= res[["n_iter_initial"]],
    msg = "CV n_iter_max must be at least n_iter_initial."
  )

  return(res)
}
