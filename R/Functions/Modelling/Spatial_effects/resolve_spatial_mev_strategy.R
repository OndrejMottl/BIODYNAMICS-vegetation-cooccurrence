#' @title Resolve the Shared Spatial MEM Construction Strategy
#' @description
#' Validates shared Moran eigenvector construction settings and resolves
#' `"auto"` to the exact or fast implementation using only the number of
#' input spatial locations.
#' @param strategy
#' Character scalar. One of `"exact"`, `"fast"`, or `"auto"`.
#' @param n_locations
#' Positive integer giving the number of input spatial locations.
#' @param n_mev
#' Positive integer giving the number of public Moran eigenvectors requested.
#' @param exact_max_locations
#' Positive integer giving the largest input allowed to use dense exact
#' construction.
#' @param fast_eigenvectors
#' Positive integer giving the low-rank basis size for fast construction. It
#' must be at least `n_mev`.
#' @return
#' Named list containing the requested and selected strategies, strategy
#' version, validated counts, and shared exact/fast settings.
#' @examples
#' resolve_spatial_mev_strategy(
#'   strategy = "auto",
#'   n_locations = 2000L,
#'   n_mev = 3L,
#'   exact_max_locations = 1999L,
#'   fast_eigenvectors = 200L
#' )
#' @export
resolve_spatial_mev_strategy <- function(
    strategy = NULL,
    n_locations = NULL,
    n_mev = NULL,
    exact_max_locations = NULL,
    fast_eigenvectors = NULL) {
  assertthat::assert_that(
    base::is.character(strategy),
    base::length(strategy) == 1L,
    !base::is.na(strategy),
    strategy %in% base::c("exact", "fast", "auto"),
    msg = "`strategy` must be one of 'exact', 'fast', or 'auto'."
  )

  assertthat::assert_that(
    base::is.numeric(n_locations),
    base::length(n_locations) == 1L,
    base::is.finite(n_locations),
    n_locations >= 1,
    n_locations == base::as.integer(n_locations),
    msg = "`n_locations` must be one finite positive integer."
  )

  assertthat::assert_that(
    base::is.numeric(n_mev),
    base::length(n_mev) == 1L,
    base::is.finite(n_mev),
    n_mev >= 1,
    n_mev == base::as.integer(n_mev),
    msg = "`n_mev` must be one finite positive integer."
  )

  assertthat::assert_that(
    base::is.numeric(exact_max_locations),
    base::length(exact_max_locations) == 1L,
    base::is.finite(exact_max_locations),
    exact_max_locations >= 4,
    exact_max_locations == base::as.integer(exact_max_locations),
    msg = "`exact_max_locations` must be an integer of at least four."
  )

  assertthat::assert_that(
    base::is.numeric(fast_eigenvectors),
    base::length(fast_eigenvectors) == 1L,
    base::is.finite(fast_eigenvectors),
    fast_eigenvectors >= 1,
    fast_eigenvectors == base::as.integer(fast_eigenvectors),
    msg = "`fast_eigenvectors` must be one finite positive integer."
  )

  n_locations_integer <-
    base::as.integer(n_locations)

  n_mev_integer <-
    base::as.integer(n_mev)

  exact_max_locations_integer <-
    base::as.integer(exact_max_locations)

  fast_eigenvectors_integer <-
    base::as.integer(fast_eigenvectors)

  if (
    fast_eigenvectors_integer < n_mev_integer
  ) {
    cli::cli_abort(
      "`fast_eigenvectors` must be greater than or equal to `n_mev`."
    )
  }

  strategy_selected <-
    if (
      strategy == "auto"
    ) {
      if (
        n_locations_integer <= exact_max_locations_integer
      ) {
        "exact"
      } else {
        "fast"
      }
    } else {
      strategy
    }

  if (
    strategy_selected == "exact" &&
      n_locations_integer > exact_max_locations_integer
  ) {
    cli::cli_abort(
      c(
        "Exact construction exceeds the shared dense MEM safety limit.",
        "i" = "{n_locations_integer} locations were supplied.",
        "i" = stringr::str_glue(
          "The configured exact limit is ",
          "{exact_max_locations_integer} locations."
        ),
        "i" = "Use the shared 'auto' or 'fast' strategy after validation."
      )
    )
  }

  strategy_version <-
    if (
      strategy_selected == "exact"
    ) {
      "spatial_mev_exact_v1"
    } else {
      "spatial_mev_nystrom_v1"
    }

  res <-
    base::list(
      strategy_requested = strategy,
      strategy_selected = strategy_selected,
      strategy_version = strategy_version,
      n_locations = n_locations_integer,
      n_mev = n_mev_integer,
      exact_max_locations = exact_max_locations_integer,
      fast_eigenvectors = fast_eigenvectors_integer
    )

  return(res)
}
