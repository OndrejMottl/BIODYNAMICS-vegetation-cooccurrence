#' @title Run Common-Regularization sjSDM Sensitivity Models
#' @description
#' Reads prepared representative-model inputs, refits each model with a common
#' spatial regularization artifact, and returns decomposition and provenance.
#' @param data_model_index
#' Model index with model_id, tier_id, scale_id, resolution_id, and store_path.
#' @param data_artifacts
#' Common artifacts from [build_sjsdm_common_regularization_artifacts()].
#' @param read_target_function
#' Injectable target reader. Defaults to [targets::tar_read_raw()].
#' @param fit_function
#' Injectable high-level model-fitting function. It receives prepared input,
#' formula, fitting configuration, and one regularization artifact.
#' @param standard_error_function
#' Injectable standard-error function. Defaults to [compute_jsdm_se()].
#' @param anova_function
#' Injectable decomposition function. Defaults to
#' [compute_jsdm_variance_partition()].
#' @param extract_function
#' Injectable ANOVA extractor. Defaults to
#' [extract_jsdm_variance_fractions()].
#' @return
#' Named list containing fitted models, ANOVA objects, model-level provenance,
#' and a long decomposition table. Individual failures are retained with an
#' explicit status and do not discard successful representative models.
#' @export
run_sjsdm_common_regularization_sensitivity <- function(
    data_model_index = NULL,
    data_artifacts = NULL,
    read_target_function = targets::tar_read_raw,
    fit_function = NULL,
    standard_error_function = compute_jsdm_se,
    anova_function = compute_jsdm_variance_partition,
    extract_function = extract_jsdm_variance_fractions) {
  vec_index_columns <-
    base::c(
      "model_id",
      "tier_id",
      "scale_id",
      "resolution_id",
      "store_path"
    )

  vec_artifact_columns <-
    base::c(
      "taxonomic_resolution",
      "response_family",
      "candidate_table_hash",
      "candidate_id",
      "alpha_cov",
      "alpha_coef",
      "alpha_spatial",
      "lambda_cov",
      "lambda_coef",
      "lambda_spatial",
      "regularization_source",
      "source_tier",
      "weighting_rule"
    )

  assertthat::assert_that(
    base::is.data.frame(data_model_index),
    base::nrow(data_model_index) > 0L,
    base::all(vec_index_columns %in% base::colnames(data_model_index)),
    !base::anyDuplicated(data_model_index[["model_id"]]),
    msg = "data_model_index must contain representative model rows."
  )

  assertthat::assert_that(
    base::is.data.frame(data_artifacts),
    base::nrow(data_artifacts) > 0L,
    base::all(
      vec_artifact_columns %in% base::colnames(data_artifacts)
    ),
    msg = "data_artifacts must contain common regularization rows."
  )

  assertthat::assert_that(
    base::is.function(read_target_function),
    base::is.null(fit_function) || base::is.function(fit_function),
    base::is.function(standard_error_function),
    base::is.function(anova_function),
    base::is.function(extract_function),
    msg = "Sensitivity workflow backends must be functions."
  )

  data_primary_provenance_defaults <-
    tibble::tibble(
      cv_strategy = NA_character_,
      effective_folds = NA_integer_,
      n_locations = NA_integer_,
      n_samples = NA_integer_,
      n_taxa = NA_integer_,
      n_effective_mev = NA_integer_
    )

  list_results <-
    base::seq_len(base::nrow(data_model_index)) |>
    purrr::map(
      .f = ~ {
        data_index_row <-
          data_model_index[.x, , drop = FALSE]

        model_id <-
          data_index_row[["model_id"]][[1L]]

        store_path <-
          data_index_row[["store_path"]][[1L]]

        resolution_id <-
          data_index_row[["resolution_id"]][[1L]]

        tryCatch(
          expr = {
            data_model_context <-
              read_target_function(
                name = stringr::str_c(
                  "data_sjsdm_model_context_",
                  resolution_id
                ),
                store = store_path
              )

            data_regularization <-
              data_artifacts |>
              dplyr::filter(
                .data[["taxonomic_resolution"]] ==
                  data_model_context[["taxonomic_resolution"]][[1L]],
                .data[["response_family"]] ==
                  data_model_context[["response_family"]][[1L]],
                .data[["candidate_table_hash"]] ==
                  data_model_context[["candidate_table_hash"]][[1L]]
              )

            if (
              base::nrow(data_regularization) != 1L
            ) {
              cli::cli_abort(
                "Exactly one compatible common artifact is required."
              )
            }

            data_model_input <-
              read_target_function(
                name = stringr::str_c(
                  "data_model_input_",
                  resolution_id
                ),
                store = store_path
              )

            model_formula <-
              read_target_function(
                name = stringr::str_c(
                  "model_formula_",
                  resolution_id
                ),
                store = store_path
              )

            config_model_fitting <-
              read_target_function(
                name = stringr::str_c(
                  "config_model_fitting_",
                  resolution_id
                ),
                store = store_path
              )

            data_primary_provenance <-
              read_target_function(
                name = stringr::str_c(
                  "data_sjsdm_model_provenance_",
                  resolution_id
                ),
                store = store_path
              )

            data_primary_provenance_first <-
              if (
                base::is.data.frame(data_primary_provenance) &&
                  base::nrow(data_primary_provenance) > 0L
              ) {
                data_primary_provenance |>
                  dplyr::slice_head(n = 1L)
              } else {
                tibble::tibble()
              }

            data_primary_provenance_complete <-
              dplyr::bind_rows(
                data_primary_provenance_first,
                data_primary_provenance_defaults
              ) |>
              dplyr::slice_head(n = 1L)

            model_fit <-
              if (
                base::is.null(fit_function)
              ) {
                fit_jsdm_model(
                  data_to_fit = data_model_input,
                  abiotic_method = "linear",
                  sel_abiotic_formula = model_formula,
                  spatial_method = if (
                    base::isTRUE(
                      config_model_fitting[["use_spatial"]]
                    )
                  ) {
                    "linear"
                  } else {
                    "none"
                  },
                  sel_spatial_formula = ~ 0 + .,
                  error_family =
                    config_model_fitting[["error_family"]],
                  device = "gpu",
                  parallel = config_model_fitting[["n_cores"]],
                  sampling = config_model_fitting[["n_sampling"]],
                  iter = config_model_fitting[["n_iter"]],
                  step_size = config_model_fitting[["n_step_size"]],
                  n_early_stopping =
                    config_model_fitting[["n_early_stopping"]],
                  seed = 900723,
                  verbose = TRUE,
                  compute_se = FALSE,
                  alpha_cov =
                    data_regularization[["alpha_cov"]][[1L]],
                  alpha_coef =
                    data_regularization[["alpha_coef"]][[1L]],
                  alpha_spatial =
                    data_regularization[["alpha_spatial"]][[1L]],
                  lambda_cov =
                    data_regularization[["lambda_cov"]][[1L]],
                  lambda_coef =
                    data_regularization[["lambda_coef"]][[1L]],
                  lambda_spatial =
                    data_regularization[["lambda_spatial"]][[1L]]
                )
              } else {
                fit_function(
                  data_model_input = data_model_input,
                  model_formula = model_formula,
                  config_model_fitting = config_model_fitting,
                  data_regularization = data_regularization
                )
              }

            model_with_se <-
              standard_error_function(
                mod_jsdm = model_fit,
                parallel = config_model_fitting[["n_cores"]],
                verbose = TRUE
              )

            model_anova <-
              anova_function(
                mod = model_with_se,
                n_samples =
                  config_model_fitting[["n_samples_anova"]],
                verbose = TRUE
              )

            data_provenance <-
              tibble::tibble(
                model_id = model_id,
                tier_id = data_index_row[["tier_id"]][[1L]],
                scale_id = data_index_row[["scale_id"]][[1L]],
                resolution_id = resolution_id,
                predictor_structure =
                  data_model_context[["predictor_structure"]][[1L]],
                candidate_table_hash =
                  data_model_context[["candidate_table_hash"]][[1L]],
                cv_strategy =
                  data_primary_provenance_complete[[
                    "cv_strategy"
                  ]][[1L]],
                effective_folds =
                  data_primary_provenance_complete[[
                    "effective_folds"
                  ]][[1L]],
                n_locations =
                  data_primary_provenance_complete[[
                    "n_locations"
                  ]][[1L]],
                n_samples =
                  data_primary_provenance_complete[["n_samples"]][[1L]],
                n_taxa =
                  data_primary_provenance_complete[["n_taxa"]][[1L]],
                n_effective_mev =
                  data_primary_provenance_complete[[
                    "n_effective_mev"
                  ]][[1L]],
                candidate_id =
                  data_regularization[["candidate_id"]][[1L]],
                regularization_source =
                  data_regularization[[
                    "regularization_source"
                  ]][[1L]],
                source_tier =
                  data_regularization[["source_tier"]][[1L]],
                weighting_rule =
                  data_regularization[["weighting_rule"]][[1L]],
                fit_status = "ok",
                fit_error = NA_character_
              )

            data_decomposition <-
              extract_function(
                anova_object = model_anova,
                clamp_negative = TRUE
              ) |>
              dplyr::mutate(
                model_id = model_id,
                tier_id = data_index_row[["tier_id"]][[1L]],
                scale_id = data_index_row[["scale_id"]][[1L]],
                resolution_id = resolution_id,
                predictor_structure =
                  data_model_context[["predictor_structure"]][[1L]],
                candidate_id =
                  data_regularization[["candidate_id"]][[1L]],
                regularization_source =
                  data_regularization[[
                    "regularization_source"
                  ]][[1L]],
                source_tier =
                  data_regularization[["source_tier"]][[1L]],
                weighting_rule =
                  data_regularization[["weighting_rule"]][[1L]],
                .before = 1L
              )

            base::list(
              model = model_with_se,
              anova = model_anova,
              data_provenance = data_provenance,
              data_decomposition = data_decomposition
            )
          },
          error = function(error_condition) {
            base::list(
              model = NULL,
              anova = NULL,
              data_provenance = tibble::tibble(
                model_id = model_id,
                tier_id = data_index_row[["tier_id"]][[1L]],
                scale_id = data_index_row[["scale_id"]][[1L]],
                resolution_id = resolution_id,
                predictor_structure = NA_character_,
                candidate_table_hash = NA_character_,
                cv_strategy = NA_character_,
                effective_folds = NA_integer_,
                n_locations = NA_integer_,
                n_samples = NA_integer_,
                n_taxa = NA_integer_,
                n_effective_mev = NA_integer_,
                candidate_id = NA_character_,
                regularization_source =
                  "common_spatial_sensitivity",
                source_tier = "common_spatial",
                weighting_rule = "equal_tier_equal_id",
                fit_status = "error",
                fit_error = base::conditionMessage(error_condition)
              ),
              data_decomposition = NULL
            )
          }
        )
      }
    )

  model_ids <-
    data_model_index[["model_id"]]

  data_decomposition <-
    list_results |>
    purrr::map("data_decomposition") |>
    purrr::compact() |>
    purrr::list_rbind()

  if (
    base::is.null(data_decomposition)
  ) {
    data_decomposition <-
      tibble::tibble(
        model_id = base::character(),
        tier_id = base::character(),
        scale_id = base::character(),
        resolution_id = base::character(),
        predictor_structure = base::character(),
        candidate_id = base::character(),
        regularization_source = base::character(),
        source_tier = base::character(),
        weighting_rule = base::character(),
        component = base::character(),
        R2_Nagelkerke = base::numeric()
      )
  }

  res <-
    base::list(
      list_models = list_results |>
        purrr::map("model") |>
        rlang::set_names(model_ids),
      list_anova = list_results |>
        purrr::map("anova") |>
        rlang::set_names(model_ids),
      data_provenance = list_results |>
        purrr::map("data_provenance") |>
        purrr::list_rbind(),
      data_decomposition = data_decomposition
    )

  return(res)
}
