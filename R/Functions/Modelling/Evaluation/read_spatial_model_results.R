#' @title Read Spatial Model Results
#' @description
#' Reads successful spatial model ANOVA and evaluation targets from
#' indexed targets stores and returns one summary row per
#' store-resolution-component combination.
#' @param store_index
#' Data frame returned by [build_spatial_model_store_index()].
#' @param resolution_ids
#' Character vector of model resolution identifiers.
#' @param read_target_fn
#' Function used to read one target. Defaults to
#' [targets::tar_read_raw()].
#' @param meta_fn
#' Function used to read target metadata. Defaults to
#' [targets::tar_meta()].
#' @param require_non_empty
#' Logical. If `TRUE`, error when no rows are read.
#' @return
#' A tibble with ANOVA component percentages and AUC summaries.
#' @export
read_spatial_model_results <- function(
    store_index,
    resolution_ids,
    read_target_fn = targets::tar_read_raw,
    meta_fn = targets::tar_meta,
    require_non_empty = FALSE) {
  assertthat::assert_that(
    base::is.data.frame(store_index),
    msg = "`store_index` must be a data frame."
  )

  vec_required_cols <-
    c(
      "data_source",
      "scale",
      "scale_id",
      "pipeline_name",
      "store_path",
      "store_exists"
    )

  assertthat::assert_that(
    base::all(vec_required_cols %in% base::colnames(store_index)),
    msg = stringr::str_glue(
      "`store_index` must contain columns: ",
      "{stringr::str_c(vec_required_cols, collapse = ', ')}."
    )
  )

  assertthat::assert_that(
    base::is.character(resolution_ids) &&
      base::length(resolution_ids) > 0L,
    msg = "`resolution_ids` must be a non-empty character vector."
  )

  assertthat::assert_that(
    base::is.function(read_target_fn),
    msg = "`read_target_fn` must be a function."
  )

  assertthat::assert_that(
    base::is.function(meta_fn),
    msg = "`meta_fn` must be a function."
  )

  assertthat::assert_that(
    assertthat::is.flag(require_non_empty),
    msg = "`require_non_empty` must be a single logical value."
  )

  read_store_meta <- function(store_path) {
    purrr::possibly(
      .f = ~ meta_fn(
        fields = c("name", "error"),
        complete_only = FALSE,
        store = .x
      ),
      otherwise = NULL
    )(store_path)
  }

  target_succeeded <- function(data_meta, target_name) {
    if (
      base::is.null(data_meta) ||
        !base::all(c("name", "error") %in% base::colnames(data_meta))
    ) {
      return(FALSE)
    }

    target_row <-
      data_meta |>
      dplyr::filter(
        .data$name == .env$target_name
      )

    base::nrow(target_row) > 0L &&
      base::any(base::is.na(target_row$error))
  }

  read_target_or_null <- function(target_name, store_path) {
    purrr::possibly(
      .f = ~ read_target_fn(
        name = target_name,
        store = store_path
      ),
      otherwise = NULL
    )()
  }

  summarise_auc <- function(model_evaluation) {
    if (
      base::is.null(model_evaluation) ||
        !("species" %in% base::names(model_evaluation))
    ) {
      return(
        tibble::tibble(
          auc_mean = NA_real_,
          auc_median = NA_real_,
          auc_n = 0L
        )
      )
    }

    data_species <-
      purrr::pluck(model_evaluation, "species")

    if (
      !base::is.data.frame(data_species) ||
        !("AUC" %in% base::colnames(data_species))
    ) {
      return(
        tibble::tibble(
          auc_mean = NA_real_,
          auc_median = NA_real_,
          auc_n = 0L
        )
      )
    }

    vec_auc <-
      data_species$AUC |>
      base::as.numeric()

    vec_auc <-
      vec_auc[base::is.finite(vec_auc)]

    if (
      base::length(vec_auc) == 0L
    ) {
      return(
        tibble::tibble(
          auc_mean = NA_real_,
          auc_median = NA_real_,
          auc_n = 0L
        )
      )
    }

    tibble::tibble(
      auc_mean = base::mean(vec_auc),
      auc_median = stats::median(vec_auc),
      auc_n = base::length(vec_auc)
    )
  }

  read_one_resolution <- function(store_row, data_meta, resolution_id) {
    target_anova <-
      stringr::str_glue("model_anova_{resolution_id}")

    if (
      !target_succeeded(data_meta, target_anova)
    ) {
      return(
        tibble::tibble(
          data_source = base::character(),
          scale = base::character(),
          scale_id = base::character(),
          pipeline_name = base::character(),
          store_path = base::character(),
          resolution_id = base::character(),
          component = base::character(),
          R2_Nagelkerke_adjusted = base::numeric(),
          R2_Nagelkerke_percentage = base::numeric(),
          auc_mean = base::numeric(),
          auc_median = base::numeric(),
          auc_n = base::integer()
        )
      )
    }

    model_anova <-
      read_target_or_null(
        target_name = target_anova,
        store_path = store_row$store_path
      )

    if (
      base::is.null(model_anova)
    ) {
      return(
        tibble::tibble(
          data_source = base::character(),
          scale = base::character(),
          scale_id = base::character(),
          pipeline_name = base::character(),
          store_path = base::character(),
          resolution_id = base::character(),
          component = base::character(),
          R2_Nagelkerke_adjusted = base::numeric(),
          R2_Nagelkerke_percentage = base::numeric(),
          auc_mean = base::numeric(),
          auc_median = base::numeric(),
          auc_n = base::integer()
        )
      )
    }

    data_anova <-
      extract_anova_fractions(
        anova_object = model_anova,
        clamp_negative = TRUE
      ) |>
      dplyr::mutate(
        age = 0
      )

    if (
      base::nrow(data_anova) == 0L
    ) {
      return(
        tibble::tibble(
          data_source = base::character(),
          scale = base::character(),
          scale_id = base::character(),
          pipeline_name = base::character(),
          store_path = base::character(),
          resolution_id = base::character(),
          component = base::character(),
          R2_Nagelkerke_adjusted = base::numeric(),
          R2_Nagelkerke_percentage = base::numeric(),
          auc_mean = base::numeric(),
          auc_median = base::numeric(),
          auc_n = base::integer()
        )
      )
    }

    target_evaluation <-
      stringr::str_glue("model_evaluation_{resolution_id}")

    model_evaluation <-
      if (
        target_succeeded(data_meta, target_evaluation)
      ) {
        read_target_or_null(
          target_name = target_evaluation,
          store_path = store_row$store_path
        )
      } else {
        NULL
      }

    data_auc <-
      summarise_auc(model_evaluation)

    data_anova |>
      recalculate_anova_components() |>
      dplyr::mutate(
        data_source = store_row$data_source,
        scale = store_row$scale,
        scale_id = store_row$scale_id,
        pipeline_name = store_row$pipeline_name,
        store_path = store_row$store_path,
        resolution_id = resolution_id,
        auc_mean = data_auc$auc_mean,
        auc_median = data_auc$auc_median,
        auc_n = data_auc$auc_n
      ) |>
      dplyr::select(
        data_source,
        scale,
        scale_id,
        pipeline_name,
        store_path,
        resolution_id,
        component,
        R2_Nagelkerke_adjusted,
        R2_Nagelkerke_percentage,
        auc_mean,
        auc_median,
        auc_n
      )
  }

  res <-
    store_index |>
    dplyr::filter(
      .data$store_exists
    ) |>
    dplyr::mutate(
      row_id = dplyr::row_number(),
      data_meta = purrr::map(
        .x = .data$store_path,
        .f = read_store_meta
      )
    ) |>
    dplyr::group_split(
      .data$row_id,
      .keep = FALSE
    ) |>
    purrr::map(
      .f = ~ {
        store_row <- .x
        data_meta <- store_row$data_meta[[1L]]

        resolution_ids |>
          purrr::map(
            .f = ~ read_one_resolution(
              store_row = store_row,
              data_meta = data_meta,
              resolution_id = .x
            )
          ) |>
          purrr::list_rbind()
      }
    ) |>
    purrr::list_rbind()

  if (
    base::is.null(res)
  ) {
    res <-
      tibble::tibble(
        data_source = base::character(),
        scale = base::character(),
        scale_id = base::character(),
        pipeline_name = base::character(),
        store_path = base::character(),
        resolution_id = base::character(),
        component = base::character(),
        R2_Nagelkerke_adjusted = base::numeric(),
        R2_Nagelkerke_percentage = base::numeric(),
        auc_mean = base::numeric(),
        auc_median = base::numeric(),
        auc_n = base::integer()
      )
  }

  if (
    base::isTRUE(require_non_empty) &&
      base::nrow(res) == 0L
  ) {
    cli::cli_abort(
      "No successful spatial model results were found in existing stores."
    )
  }

  return(res)
}
