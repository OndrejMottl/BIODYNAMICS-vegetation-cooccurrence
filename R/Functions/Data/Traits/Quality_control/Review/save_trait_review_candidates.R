#' @title Save Trait Review Candidates
#' @description
#' Writes a generated trait-review queue and returns its path for a
#' `targets` file target.
#' @param data_trait_review_candidates
#' Candidate tibble from [build_trait_review_candidates()].
#' @param path_trait_review_candidates
#' Character scalar output CSV path.
#' @return
#' The normalized output path.
#' @export
save_trait_review_candidates <- function(
    data_trait_review_candidates,
    path_trait_review_candidates) {
  assertthat::assert_that(
    base::is.data.frame(data_trait_review_candidates),
    msg = "'data_trait_review_candidates' must be a data frame."
  )
  assertthat::assert_that(
    base::is.character(path_trait_review_candidates) &&
      base::length(path_trait_review_candidates) == 1L,
    msg = "'path_trait_review_candidates' must be one path."
  )

  base::dir.create(
    base::dirname(path_trait_review_candidates),
    recursive = TRUE,
    showWarnings = FALSE
  )
  readr::write_csv(
    data_trait_review_candidates,
    path_trait_review_candidates
  )

  return(path_trait_review_candidates)
}
