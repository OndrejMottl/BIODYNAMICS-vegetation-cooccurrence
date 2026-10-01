#' @title Load Frozen Presentation Results Snapshot
#' @description
#' Loads and validates the presentation-local frozen-results metadata.
#' @param path
#' Character scalar. Path to the results snapshot JSON file.
#' @return
#' A validated named list describing the frozen result artifacts and counts.
#' @examples
#' \dontrun{
#' load_results_snapshot()
#' }
#' @export
load_results_snapshot <- function(
    path = base::file.path(
      resolve_cspe_presentation_directory(),
      "results_snapshot.json"
    )) {
  assertthat::assert_that(
    base::is.character(path),
    base::length(path) == 1L,
    !base::is.na(path),
    base::nzchar(path),
    msg = "'path' must be one non-empty character string."
  )

  if (
    !base::file.exists(path)
  ) {
    cli::cli_abort(
      c(
        "The results snapshot file does not exist.",
        "i" = "Expected path: {.path {path}}."
      )
    )
  }

  list_snapshot <-
    jsonlite::read_json(
      path = path,
      simplifyVector = TRUE
    )

  vec_required_fields <-
    base::c(
      "schema_version",
      "mode",
      "snapshot_id",
      "snapshot_display_date",
      "source_presentation",
      "spatial_targets_archive",
      "rationale",
      "summary_counts"
    )

  vec_missing_fields <-
    base::setdiff(
      x = vec_required_fields,
      y = base::names(list_snapshot)
    )

  if (
    base::length(vec_missing_fields) > 0L
  ) {
    cli::cli_abort(
      c(
        "The results snapshot is missing required fields.",
        "i" = "Missing: {base::toString(vec_missing_fields)}."
      )
    )
  }

  if (
    !base::identical(
      list_snapshot[["mode"]],
      "frozen_iavs_artifacts"
    )
  ) {
    cli::cli_abort(
      "The results snapshot must use mode 'frozen_iavs_artifacts'."
    )
  }

  vec_required_counts <-
    base::c(
      "cores",
      "communities",
      "taxa",
      "trait_values",
      "functional_types",
      "models"
    )

  vec_missing_counts <-
    base::setdiff(
      x = vec_required_counts,
      y = base::names(list_snapshot[["summary_counts"]])
    )

  if (
    base::length(vec_missing_counts) > 0L
  ) {
    cli::cli_abort(
      c(
        "The results snapshot is missing required summary counts.",
        "i" = "Missing: {base::toString(vec_missing_counts)}."
      )
    )
  }

  vec_summary_counts <-
    base::unlist(
      x = list_snapshot[["summary_counts"]][vec_required_counts],
      use.names = TRUE
    )

  if (
    !base::is.numeric(vec_summary_counts) ||
      base::any(!base::is.finite(vec_summary_counts)) ||
      base::any(vec_summary_counts < 0) ||
      base::any(vec_summary_counts != base::round(vec_summary_counts))
  ) {
    cli::cli_abort(
      "All frozen summary counts must be finite non-negative integers."
    )
  }

  return(list_snapshot)
}