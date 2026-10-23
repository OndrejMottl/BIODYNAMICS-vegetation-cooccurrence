#' @title Run Ordered Conditional Likelihood Calls with Progress
#' @description
#' Preserves sjSDM's iteration order and simplification while reporting each
#' taxon's start, completion, and elapsed time without drawing random numbers.
#' @param X Ordered indices supplied by sjSDM's conditional likelihood helper.
#' @param FUN Per-taxon likelihood function supplied by sjSDM.
#' @param ... Additional arguments forwarded unchanged to FUN.
#' @param simplify,USE.NAMES Simplification controls from the upstream call.
#' @param verbose Logical; print timestamped likelihood progress.
#' @param progress_state Optional private environment tracking ANOVA pass names.
#' @return An array or list with the same values as the upstream mapping.
#' @examples
#' run_sjsdm_likelihood_sequence(
#'   X = 1:3,
#'   FUN = base::identity,
#'   verbose = FALSE
#' )
#' @export
run_sjsdm_likelihood_sequence <- function(
    X,
    FUN,
    ...,
    simplify = TRUE,
    USE.NAMES = TRUE,
    verbose = TRUE,
    progress_state = NULL) {
  assertthat::assert_that(
    base::is.function(FUN),
    assertthat::is.flag(verbose),
    !base::is.na(verbose),
    base::is.null(progress_state) || base::is.environment(progress_state),
    msg = "Supply a likelihood function and logical verbose."
  )
  n_taxa <-
    base::length(X)
  list_arguments <-
    base::list(...)
  text_pass <- ""
  if (
    !base::is.null(progress_state)
  ) {
    progress_state[["index_pass"]] <-
      progress_state[["index_pass"]] + 1L
    index_pass <-
      progress_state[["index_pass"]]
    text_pass <-
      stringr::str_c(progress_state[["phase_ids"]][[index_pass]], ", ")
  }
  list_results <-
    base::seq_along(X) |>
    purrr::map(
      .f = ~ {
        index_taxon <- .x
        time_started <-
          base::proc.time()[["elapsed"]]
        if (
          base::isTRUE(verbose)
        ) {
          text_time_started <-
            base::format(base::Sys.time(), tz = "UTC", usetz = TRUE)
          cli::cli_inform(stringr::str_glue(
            "[{text_time_started}] ",
            "likelihood {text_pass}taxon {index_taxon}/{n_taxa}: starting"
          ))
        }
        vec_result <-
          base::do.call(
            what = FUN,
            args = base::c(base::list(X[[index_taxon]]), list_arguments)
          )
        n_seconds <-
          base::proc.time()[["elapsed"]] - time_started
        if (
          base::isTRUE(verbose)
        ) {
          text_time_finished <-
            base::format(base::Sys.time(), tz = "UTC", usetz = TRUE)
          cli::cli_inform(stringr::str_glue(
            "[{text_time_finished}] ",
            "likelihood {text_pass}taxon {index_taxon}/{n_taxa}: ",
            "completed ",
            "({base::round(n_seconds, 3L)} seconds)"
          ))
        }
        vec_result
      }
    )
  if (
    base::isTRUE(USE.NAMES)
  ) {
    base::names(list_results) <-
      if (
        base::is.character(X) && base::is.null(base::names(X))
      ) {
        X
      } else {
        base::names(X)
      }
  }
  res <-
    if (
      !base::identical(simplify, FALSE) && base::length(list_results) > 0L
    ) {
      base::simplify2array(
        x = list_results,
        higher = base::identical(simplify, "array")
      )
    } else {
      list_results
    }
  return(res)
}
