#' @title Load Review Submission Candidates
#' @description
#' Reads the immutable headerless review submission and extracts only
#' its taxon-domain review keys into a normalized derived tibble.
#' @param path_review_submission
#' Character scalar path to the immutable headerless review CSV.
#' @return
#' A tibble with `taxon_name`, `trait_domain_name`, and
#' `source_reference`.
#' @export
load_review_submission_candidates <- function(path_review_submission) {
  assertthat::assert_that(
    base::is.character(path_review_submission) &&
      base::length(path_review_submission) == 1L &&
      base::file.exists(path_review_submission),
    msg = "'path_review_submission' must identify an existing file."
  )

  data_submission <-
    readr::read_csv(
      path_review_submission,
      col_names = FALSE,
      col_types = readr::cols(.default = readr::col_character()),
      name_repair = "minimal",
      progress = FALSE,
      show_col_types = FALSE,
      trim_ws = FALSE
    )
  if (base::ncol(data_submission) < 2L) {
    cli::cli_abort(
      "Review submission must contain taxon and trait-domain columns."
    )
  }

  data_source_candidates <-
    data_submission |>
    dplyr::transmute(
      taxon_name = .data[["X1"]] |>
        stringr::str_replace_all("\u2212", "-") |>
        stringr::str_squish(),
      trait_domain_name = .data[["X2"]] |>
        stringr::str_squish(),
      source_reference = stringr::str_c(
        "review_submission_csv:",
        dplyr::row_number()
      )
    )
  if (
    base::any(
      base::is.na(data_source_candidates[["taxon_name"]]) |
        data_source_candidates[["taxon_name"]] == "" |
        base::is.na(data_source_candidates[["trait_domain_name"]]) |
        data_source_candidates[["trait_domain_name"]] == ""
    )
  ) {
    cli::cli_abort("Review submission contains blank review keys.")
  }

  return(data_source_candidates)
}
