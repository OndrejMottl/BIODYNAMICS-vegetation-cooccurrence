#' @title Plot Bipartite Network Metrics by Age
#' @description
#' Creates a faceted line-and-point plot of bipartite community
#' network metrics (e.g. connectance, nestedness, modularity)
#' across time slices (ages). Each metric is shown in its own
#' panel with a free y-axis scale.
#' @param data_network_metrics
#' A data frame or tibble with columns \code{age} (numeric),
#' \code{metric} (character), and \code{value} (numeric).
#' Typically the output of
#' \code{\link{compute_network_metrics}()} aggregated across
#' time slices and with the age column already parsed to numeric.
#' @param title
#' Optional character string for the plot title.
#' Defaults to \code{NULL} (no title).
#' @param subtitle
#' Optional character string for the plot subtitle.
#' Defaults to \code{NULL} (no subtitle).
#' @return
#' A \code{ggplot} object.
#' @details
#' The x-axis is reversed so that older ages appear on the left.
#' Each metric is shown in a separate facet panel with an
#' independent y-axis scale (\code{scales = "free_y"}) because
#' connectance, nestedness, and modularity occupy different
#' numeric ranges. Each panel shows a coloured line with points.
#' @seealso [compute_network_metrics()]
#' @export
plot_network_metrics_by_age <- function(
    data_network_metrics,
    title = NULL,
    subtitle = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_network_metrics),
    msg = "'data_network_metrics' must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      c("age", "metric", "value") %in%
        base::names(data_network_metrics)
    ),
    msg = paste0(
      "'data_network_metrics' must have columns",
      " 'age', 'metric', and 'value'."
    )
  )

  assertthat::assert_that(
    base::is.numeric(data_network_metrics[["age"]]),
    msg = "Column 'age' in 'data_network_metrics' must be numeric."
  )

  assertthat::assert_that(
    base::is.numeric(data_network_metrics[["value"]]),
    msg = "Column 'value' in 'data_network_metrics' must be numeric."
  )

  res <-
    data_network_metrics |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = age,
        y = value,
        colour = metric,
        group = metric
      )
    ) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::scale_x_continuous(
      trans = "reverse"
    ) +
    ggplot2::facet_wrap(
      facets = ggplot2::vars(metric),
      scales = "free_y"
    ) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Age (cal yr BP)",
      y = "Metric value",
      colour = "Metric"
    ) +
    ggplot2::theme(
      legend.position = "none"
    )

  return(res)
}
