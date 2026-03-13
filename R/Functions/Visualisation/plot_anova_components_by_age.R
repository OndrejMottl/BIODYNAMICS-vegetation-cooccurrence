#' @title Plot ANOVA Variance Components by Age
#' @description
#' Creates a line-and-point plot of sjSDM ANOVA variance
#' components (Nagelkerke R²) across time slices (ages).
#' @param data_anova_components
#' A data frame or tibble with columns \code{age} (numeric),
#' \code{component} (character), and \code{R2_Nagelkerke}
#' (numeric). Typically the output of
#' \code{\link{aggregate_anova_components}()}.
#' @param title
#' Optional character string for the plot title.
#' Defaults to \code{NULL} (no title).
#' @param subtitle
#' Optional character string for the plot subtitle.
#' Defaults to \code{NULL} (no subtitle).
#' @return
#' A \code{ggplot} object.
#' @details
#' The x-axis is reversed so that older ages appear on the left
#' and the y-axis is clamped to [0, NA]. Each variance component
#' is drawn as a coloured line with points.
#' @seealso [aggregate_anova_components()]
#' @export
plot_anova_components_by_age <- function(
    data_anova_components,
    title = NULL,
    subtitle = NULL) {
  assertthat::assert_that(
    base::is.data.frame(data_anova_components),
    msg = "'data_anova_components' must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      c("age", "component", "R2_Nagelkerke") %in%
        base::names(data_anova_components)
    ),
    msg = paste0(
      "'data_anova_components' must have columns",
      " 'age', 'component', and 'R2_Nagelkerke'."
    )
  )

  res <-
    data_anova_components |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = age,
        y = R2_Nagelkerke,
        colour = component,
        group = component
      )
    ) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::scale_x_continuous(
      trans = "reverse"
    ) +
    ggplot2::coord_cartesian(
      ylim = c(0, NA)
    ) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Age (cal yr BP)",
      y = expression(R^2 ~ "(Nagelkerke)"),
      colour = "Component"
    )

  return(res)
}
