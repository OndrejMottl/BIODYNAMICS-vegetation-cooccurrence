#' @title Load sjSDM Unit Tuning Store Paths
#' @description
#' Discovers existing unit stores for the tier pipeline from one resolved
#' tuning context.
#' @param list_tuning_context
#' Context containing `pipeline_name` and `nested_unit_stores`.
#' @param target_store
#' Root targets-store path.
#' @return
#' Existing unit tuning-store paths. When the tuning orchestrator supplies
#' `SJSMD_TUNING_UNIT_SUFFIXES`, only successful units are returned.
#' @export
load_sjsdm_unit_tuning_store_paths <- function(
    list_tuning_context = NULL,
    target_store = load_active_config_value("target_store")) {
  assertthat::assert_that(
    base::is.list(list_tuning_context),
    base::all(
      base::c("pipeline_name", "nested_unit_stores") %in%
        base::names(list_tuning_context)
    ),
    msg = "The tuning context is incomplete."
  )

  target_store_root <-
    here::here(target_store)

  vec_unit_store_roots <-
    if (
      list_tuning_context[["nested_unit_stores"]]
    ) {
      fs::dir_ls(
        path = target_store_root,
        type = "directory",
        recurse = FALSE
      )
    } else {
      target_store_root
    }

  res <-
    vec_unit_store_roots |>
    base::file.path(list_tuning_context[["pipeline_name"]]) |>
    purrr::keep(fs::dir_exists)

  value_allowed_suffixes <-
    base::Sys.getenv(
      "SJSMD_TUNING_UNIT_SUFFIXES",
      unset = NA_character_
    )
  if (
    !base::is.na(value_allowed_suffixes)
  ) {
    vec_allowed_suffixes <-
      base::strsplit(
        value_allowed_suffixes,
        split = .Platform[["path.sep"]],
        fixed = TRUE
      )[[1L]]
    vec_store_suffixes <-
      res |>
      base::dirname() |>
      base::basename()
    res <-
      res[vec_store_suffixes %in% vec_allowed_suffixes]
  }

  return(res)
}
