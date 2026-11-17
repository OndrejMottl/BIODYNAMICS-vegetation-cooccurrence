#' @title Load the Production Model Store Index
#' @description
#' Lists every targets store that feeds published model results: spatial
#' unit stores, temporal stores, tier-tuning stores, and common-regularization
#' sensitivity stores of the selected configuration profiles.
#' @param vec_profile_ids
#' Optional character vector of profile identifiers. When `NULL`, every
#' profile whose `_profile` block has role `main` and status `active` is used.
#' @param path_store_root
#' Root directory under which the profiles' relative `target_store` paths are
#' resolved. Defaults to the repository root; point it at a folder holding
#' store copies with the same relative layout to inspect the copies.
#' @param file_config
#' Path to the generated root configuration file.
#' @param path_spatial_grid
#' Path to the spatial grid catalogue listing spatial unit `scale_id` values.
#' @return
#' A tibble with one row per store and columns `store_kind`, `profile_id`,
#' `data_source`, `scale`, `scale_id`, `pipeline_script`, `store_path`,
#' `store_path_relative`, and `store_exists`. `store_path_relative` is the
#' store path relative to `path_store_root`, so ledger rows written for
#' production stores also match copies under another root.
#' @details
#' Spatial profiles contribute one unit store per `scale_id` of their scale
#' (from [build_spatial_model_store_index()]), plus the tier-tuning and
#' sensitivity stores below their `target_store`. Temporal profiles contribute
#' their temporal store and tier-tuning store. Stores are listed whether or
#' not they exist; `store_exists` records presence.
#' @seealso [resolve_pipeline_store_path()],
#'   [diagnose_model_store_freshness()]
#' @examples
#' \dontrun{
#' load_model_store_index(vec_profile_ids = "project_paleo_temporal_europe")
#' }
#' @export
load_model_store_index <- function(
    vec_profile_ids = NULL,
    path_store_root = here::here(),
    file_config = here::here("config.yml"),
    path_spatial_grid = here::here("Data/Input/spatial_grid.csv")) {
  assertthat::assert_that(
    base::is.null(vec_profile_ids) ||
      (
        base::is.character(vec_profile_ids) &&
          base::length(vec_profile_ids) > 0L &&
          base::all(!base::is.na(vec_profile_ids))
      ),
    msg = "`vec_profile_ids` must be NULL or a non-empty character vector."
  )
  assertthat::assert_that(
    assertthat::is.string(path_store_root),
    base::nzchar(path_store_root),
    msg = "`path_store_root` must be one non-empty path."
  )
  assertthat::assert_that(
    assertthat::is.string(file_config),
    base::file.exists(file_config),
    msg = "`file_config` must be one existing file."
  )

  vec_profile_ids_selected <-
    if (
      base::is.null(vec_profile_ids)
    ) {
      yaml::read_yaml(
        file = file_config,
        handlers = base::list(expr = function(value) value)
      ) |>
        base::names() |>
        base::setdiff("default") |>
        purrr::keep(
          .p = ~ {
            list_profile_meta <-
              load_config_value(
                config_id = .x,
                value = "_profile",
                file = file_config
              )
            base::identical(list_profile_meta[["role"]], "main") &&
              base::identical(list_profile_meta[["status"]], "active")
          }
        )
    } else {
      vec_profile_ids
    }

  path_root_absolute <-
    fs::path_abs(path_store_root)

  res <-
    vec_profile_ids_selected |>
    purrr::map(
      .f = ~ {
        profile_id <- .x

        list_profile_meta <-
          load_config_value(
            config_id = profile_id,
            value = "_profile",
            file = file_config
          )
        pipeline_kind <-
          list_profile_meta[["pipeline"]]
        target_store <-
          load_config_value(
            config_id = profile_id,
            value = "target_store",
            file = file_config
          )

        assertthat::assert_that(
          assertthat::is.string(pipeline_kind),
          pipeline_kind %in%
            base::c("paleo_spatial", "modern_spatial", "paleo_temporal"),
          msg = stringr::str_glue(
            "Profile `{profile_id}` has no supported model pipeline."
          )
        )
        assertthat::assert_that(
          assertthat::is.string(target_store),
          base::nzchar(target_store),
          msg = stringr::str_glue(
            "Profile `{profile_id}` has no `target_store`."
          )
        )

        path_target_store <-
          fs::path(path_root_absolute, target_store)

        data_shared_stores <-
          tibble::tibble(
            store_kind = base::c("tier_tuning", "sensitivity"),
            pipeline_script = base::c(
              "R/Pipelines/pipeline_sjsdm_tier_tuning.R",
              "R/Pipelines/pipeline_sjsdm_common_regularization_sensitivity.R"
            )
          )

        if (
          pipeline_kind == "paleo_temporal"
        ) {
          data_unit_stores <-
            tibble::tibble(
              store_kind = "temporal",
              data_source = "paleo",
              scale = NA_character_,
              scale_id = NA_character_,
              pipeline_script = "R/Pipelines/pipeline_paleo_temporal.R"
            )
          data_shared_stores <-
            data_shared_stores |>
            dplyr::filter(.data[["store_kind"]] == "tier_tuning")
        } else {
          data_source <-
            stringr::str_remove(pipeline_kind, "_spatial$")
          scale <-
            target_store |>
            base::basename() |>
            stringr::str_remove("^(paleo|modern)_spatial_")

          data_unit_stores <-
            build_spatial_model_store_index(
              data_source = data_source,
              scales = scale,
              path_spatial_grid = path_spatial_grid
            ) |>
            dplyr::mutate(
              store_kind = "spatial_unit",
              pipeline_script = stringr::str_glue(
                "R/Pipelines/{.data[['pipeline_name']]}.R"
              ) |>
                base::as.character()
            ) |>
            dplyr::select(
              "store_kind",
              "data_source",
              "scale",
              "scale_id",
              "pipeline_script"
            )
        }

        data_shared_rows <-
          data_shared_stores |>
          dplyr::mutate(
            data_source = data_unit_stores[["data_source"]][[1L]],
            scale = data_unit_stores[["scale"]][[1L]],
            scale_id = NA_character_
          )

        dplyr::bind_rows(data_unit_stores, data_shared_rows) |>
          dplyr::mutate(
            profile_id = profile_id,
            store_path = purrr::map2_chr(
              .x = .data[["pipeline_script"]],
              .y = .data[["scale_id"]],
              .f = ~ base::as.character(
                resolve_pipeline_store_path(
                  pipeline_script = .x,
                  target_store = base::as.character(path_target_store),
                  store_suffix = if (
                    base::is.na(.y)
                  ) {
                    NULL
                  } else {
                    .y
                  }
                )
              )
            )
          )
      }
    ) |>
    purrr::list_rbind() |>
    dplyr::mutate(
      store_path_relative = base::as.character(
        fs::path_rel(
          path = .data[["store_path"]],
          start = path_root_absolute
        )
      ),
      store_exists = base::dir.exists(.data[["store_path"]])
    ) |>
    dplyr::select(
      "store_kind",
      "profile_id",
      "data_source",
      "scale",
      "scale_id",
      "pipeline_script",
      "store_path",
      "store_path_relative",
      "store_exists"
    )

  return(res)
}
