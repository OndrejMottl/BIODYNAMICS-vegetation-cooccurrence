#' @title Compute Bipartite Network Metrics from Community Data
#' @description
#' Extracts the binary community matrix from a `data_to_fit`
#' list, binarizes it (any value > 0 becomes 1), and computes
#' whole-network metrics via `bipartite::networklevel()`.
#' Returns a tidy tibble with one row per metric.
#' @param data_to_fit
#' A named list as returned by `assemble_data_to_fit()`. Must
#' contain the element `data_community_to_fit`, a numeric
#' matrix with samples as rows and taxa as columns.
#' @param vec_indices
#' Character vector of network-level indices to compute, passed
#' directly to the `index` argument of
#' `bipartite::networklevel()`. Default:
#' `c("connectance", "nestedness", "modularity")`.
#' @return
#' A `tibble` with two columns:
#' \describe{
#'   \item{`metric`}{Character. Name of the network metric.}
#'   \item{`value`}{Numeric. Computed value of the metric.}
#' }
#' @details
#' The function treats the community matrix as a
#' lower-level (samples) × upper-level (taxa) bipartite
#' network. Only the binary incidence (presence/absence) is
#' used: all values > 0 are set to 1 before passing to
#' `bipartite::networklevel()`.
#'
#' If the binarized matrix has no positive entries (i.e. no
#' species observed in any sample), an error is raised.
#' @seealso [assemble_data_to_fit()],
#'   [binarize_community_data()]
#' @export
compute_network_metrics <- function(
    data_to_fit = NULL,
    vec_indices = c("connectance", "nestedness", "modularity")) {
  assertthat::assert_that(
    is.list(data_to_fit),
    msg = "data_to_fit must be a list"
  )

  assertthat::assert_that(
    "data_community_to_fit" %in% names(data_to_fit),
    msg = paste(
      "data_to_fit must contain an element named",
      "'data_community_to_fit'"
    )
  )

  data_community_matrix <-
    purrr::chuck(data_to_fit, "data_community_to_fit")

  assertthat::assert_that(
    is.matrix(data_community_matrix),
    msg = "data_to_fit$data_community_to_fit must be a matrix"
  )

  assertthat::assert_that(
    is.numeric(data_community_matrix),
    msg = paste(
      "data_to_fit$data_community_to_fit must be a",
      "numeric matrix"
    )
  )

  assertthat::assert_that(
    is.character(vec_indices),
    msg = "vec_indices must be a character vector"
  )

  assertthat::assert_that(
    length(vec_indices) >= 1L,
    msg = "vec_indices must contain at least one index name"
  )

  mat_binary <-
    (data_community_matrix > 0) * 1L

  assertthat::assert_that(
    base::sum(mat_binary) > 0,
    msg = paste(
      "The binarized community matrix contains no positive",
      "entries; cannot compute network metrics."
    )
  )

  vec_raw <-
    bipartite::networklevel(
      web = mat_binary,
      index = vec_indices
    )

  res <-
    tibble::tibble(
      metric = base::names(vec_raw),
      value = base::as.numeric(vec_raw)
    )

  return(res)
}
