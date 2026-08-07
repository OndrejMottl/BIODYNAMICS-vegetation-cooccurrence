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
#' @return
#' A named list with `n_iter`, `n_step_size`, `n_sampling`,
#' `n_samples_anova`, and `n_early_stopping`. Missing `n_step_size` and
#' `n_early_stopping` values are returned as `NULL`.
#' @export
load_model_tuning_parameters <- function(
    analysis_id,
    scale_id,
    resolution_id,
    dir = here::here("Data/Input/Model_tuning")) {
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
    c(
      "scale_id",
      "n_iter",
      "n_step_size",
      "n_sampling",
      "n_samples_anova",
      "n_early_stopping"
    )

  assertthat::assert_that(
    base::all(vec_required_cols %in% base::names(data_tuning)),
    msg = stringr::str_glue(
      "`file_tuning` must contain columns: ",
      "{stringr::str_c(vec_required_cols, collapse = ', ')}."
    )
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
