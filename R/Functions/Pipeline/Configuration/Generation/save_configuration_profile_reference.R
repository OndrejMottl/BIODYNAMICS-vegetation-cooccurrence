#' @title Save an Updated Configuration Profile Reference
#' @description
#' Replaces the resolved profiles of the configuration semantic reference with
#' new ones, but only when every difference was declared in advance.
#' @param list_reference
#' Current semantic reference, as read from its `.rds` file.
#' @param list_profiles_new
#' Named list of new resolved profiles, prepared exactly as the generator
#' compares them with the reference.
#' @param data_declared_changes
#' Data frame with columns `change_id`, `profile_id`, `key_path`, `issue`,
#' and `rationale`. `profile_id` may be `*` to declare a change for every
#' profile.
#' @param path_reference
#' File to write the updated reference to.
#' @return
#' Invisibly, the updated reference list.
#' @details
#' Differences are found with [build_configuration_reference_diff()]. The
#' function aborts when any difference is undeclared. Declared rows without
#' a current difference are treated as already applied. The updated reference
#' keeps its structure: `resolved_profiles`, `semantic_hashes` (SHA-256 of
#' each profile), and `aggregate_semantic_sha256` are recomputed as
#' `create_configuration_profile_reference.R` defined them, and the applied
#' differences are appended to `revision_changes`.
#' @seealso [run_configuration_generation()]
#' @examples
#' \dontrun{
#' save_configuration_profile_reference(
#'   list_reference = readRDS(path_reference),
#'   list_profiles_new = list_profiles,
#'   data_declared_changes = readr::read_csv(path_changes),
#'   path_reference = path_reference
#' )
#' }
#' @export
save_configuration_profile_reference <- function(
    list_reference,
    list_profiles_new,
    data_declared_changes,
    path_reference) {
  assertthat::assert_that(
    base::is.list(list_reference),
    base::all(
      base::c("profile_ids", "semantic_hashes", "resolved_profiles") %in%
        base::names(list_reference)
    ),
    msg = "`list_reference` is not a configuration semantic reference."
  )
  assertthat::assert_that(
    base::is.list(list_profiles_new),
    base::setequal(
      base::names(list_profiles_new),
      list_reference[["profile_ids"]]
    ),
    msg = "`list_profiles_new` must hold every reference profile."
  )
  assertthat::assert_that(
    base::is.data.frame(data_declared_changes),
    base::all(
      base::c("change_id", "profile_id", "key_path", "issue", "rationale") %in%
        base::names(data_declared_changes)
    ),
    msg = "`data_declared_changes` does not use the declared-changes schema."
  )
  assertthat::assert_that(
    assertthat::is.string(path_reference),
    msg = "`path_reference` must be one path."
  )

  vec_profile_ids <-
    list_reference[["profile_ids"]]

  data_differences <-
    build_configuration_reference_diff(
      list_profiles_current = list_profiles_new[vec_profile_ids],
      list_profiles_reference =
        list_reference[["resolved_profiles"]][vec_profile_ids]
    )

  data_declared_expanded <-
    data_declared_changes |>
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::all_of(base::c("change_id", "profile_id", "key_path")),
        .fns = base::as.character
      ),
      profile_id = purrr::map(
        .x = .data[["profile_id"]],
        .f = ~ if (
          .x == "*"
        ) {
          vec_profile_ids
        } else {
          .x
        }
      )
    ) |>
    tidyr::unnest_longer(col = "profile_id")

  data_undeclared <-
    data_differences |>
    dplyr::anti_join(
      data_declared_expanded,
      by = dplyr::join_by(profile_id, key_path)
    )

  if (
    base::nrow(data_undeclared) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "Undeclared changes to the configuration semantic reference.",
        "x" = stringr::str_c(
          data_undeclared[["profile_id"]],
          ": ",
          data_undeclared[["key_path"]]
        ),
        "i" = "Declare each intended change in the reference-changes file."
      ),
      class = "configuration_reference_undeclared_change"
    )
  }

  data_applied <-
    data_differences |>
    dplyr::inner_join(
      data_declared_expanded |>
        dplyr::select("change_id", "profile_id", "key_path", "issue"),
      by = dplyr::join_by(profile_id, key_path),
      relationship = "many-to-one"
    ) |>
    dplyr::mutate(applied_on = base::as.character(base::Sys.Date()))

  list_resolved_profiles <-
    list_profiles_new[vec_profile_ids]

  vec_semantic_hashes <-
    list_resolved_profiles |>
    purrr::map_chr(
      .f = ~ digest::digest(object = .x, algo = "sha256")
    )

  list_reference_updated <- list_reference
  list_reference_updated[["resolved_profiles"]] <- list_resolved_profiles
  list_reference_updated[["semantic_hashes"]] <- vec_semantic_hashes
  list_reference_updated[["aggregate_semantic_sha256"]] <-
    digest::digest(object = list_resolved_profiles, algo = "sha256")
  list_reference_updated[["revision_changes"]] <-
    dplyr::bind_rows(
      list_reference[["revision_changes"]],
      data_applied
    )

  base::dir.create(
    path = base::dirname(path_reference),
    recursive = TRUE,
    showWarnings = FALSE
  )
  base::saveRDS(
    object = list_reference_updated,
    file = path_reference,
    version = 3L
  )

  cli::cli_inform(
    base::c(
      "v" = "Configuration semantic reference updated.",
      "i" = "{base::nrow(data_applied)} declared difference(s) applied."
    )
  )

  return(base::invisible(list_reference_updated))
}
