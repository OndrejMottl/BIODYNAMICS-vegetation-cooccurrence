#' @title Load a Versioned sjSDM Artifact
#' @description
#' Reads the canonical v2 target first and falls back to a documented v1
#' target group that is upgraded by a pure converter.
#' @param store_path Targets store path.
#' @param v2_target_name Canonical v2 target name.
#' @param v1_target_names Documented v1 target names.
#' @param artifact_type Expected artifact type.
#' @param converter_function Function accepting the named v1 target bundle.
#' @param read_target_function Injectable target reader.
#' @return Validated native or converted v2 artifact.
#' @export
load_sjsdm_versioned_artifact <- function(
    store_path = NULL,
    v2_target_name = NULL,
    v1_target_names = NULL,
    artifact_type = NULL,
    converter_function = NULL,
    read_target_function = targets::tar_read_raw) {
  assertthat::assert_that(
    base::is.character(store_path),
    base::length(store_path) == 1L,
    base::nzchar(store_path),
    base::is.character(v2_target_name),
    base::length(v2_target_name) == 1L,
    base::nzchar(v2_target_name),
    base::is.character(v1_target_names),
    base::length(v1_target_names) > 0L,
    base::all(base::nzchar(v1_target_names)),
    base::is.function(converter_function),
    base::is.function(read_target_function),
    msg = "Versioned artifact loader inputs are invalid."
  )

  list_v2 <-
    tryCatch(
      read_target_function(
        name = v2_target_name,
        store = store_path
      ),
      error = function(error_condition) NULL
    )

  if (
    !base::is.null(list_v2)
  ) {
    validate_sjsdm_artifact_envelope(
      list_artifact = list_v2,
      expected_artifact_type = artifact_type
    )
    return(list_v2)
  }

  list_v1 <-
    stats::setNames(
      purrr::map(
        v1_target_names,
        ~ read_target_function(name = .x, store = store_path)
      ),
      v1_target_names
    )

  res <-
    converter_function(list_v1)

  validate_sjsdm_artifact_envelope(
    list_artifact = res,
    expected_artifact_type = artifact_type
  )

  return(res)
}
