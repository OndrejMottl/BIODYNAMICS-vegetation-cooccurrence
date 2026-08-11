#' @title Build sjSDM Artifact Provenance
#' @description
#' Constructs the common one-row provenance contract for native or migrated
#' cross-validation artifacts.
#' @param pipeline_id Pipeline identifier.
#' @param configuration_profile Active configuration profile.
#' @param created_at Finite artifact creation time.
#' @param source_schema_version Source artifact schema version.
#' @param migration_applied Whether a v1 conversion was applied.
#' @param migration_function Converter name, or `NA` for native v2 output.
#' @param stable_provenance Optional named list of stable scientific fields.
#' @return One-row provenance tibble.
#' @export
build_sjsdm_artifact_provenance <- function(
    pipeline_id = NULL,
    configuration_profile = NULL,
    created_at = base::Sys.time(),
    source_schema_version = "2.0.0",
    migration_applied = FALSE,
    migration_function = NA_character_,
    stable_provenance = base::list()) {
  assertthat::assert_that(
    base::is.list(stable_provenance),
    !base::any(base::duplicated(base::names(stable_provenance))),
    msg = "stable_provenance must be a uniquely named list."
  )

  data_common <-
    tibble::tibble(
      created_at = created_at,
      pipeline_id = pipeline_id,
      configuration_profile = configuration_profile,
      source_schema_version = source_schema_version,
      migration_applied = migration_applied,
      migration_function = migration_function
    )

  data_stable <-
    tibble::as_tibble(stable_provenance)

  if (
    base::ncol(data_stable) > 0L && base::nrow(data_stable) != 1L
  ) {
    cli::cli_abort("Stable provenance fields must each have size one.")
  }

  res <-
    if (
      base::ncol(data_stable) == 0L
    ) {
      data_common
    } else {
      dplyr::bind_cols(data_common, data_stable)
    }

  return(res)
}
