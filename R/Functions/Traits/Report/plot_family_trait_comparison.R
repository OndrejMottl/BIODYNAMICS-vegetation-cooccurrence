#' @title Plot Family-Level Trait Comparison for a Focal Taxon
#' @description
#' Builds a `ggplot2` log\ifelse{html}{\out{<sub>10</sub>}}{{10}}-scale
#' strip plot comparing the median trait value of a focal taxon against
#' all other taxa in the same taxonomic family. Grey jittered dots
#' represent all family members that meet the minimum record threshold;
#' a firebrick point marks the focal taxon.
#' @param data_family_comparison
#' A tibble of per-taxon summary statistics for all taxa in the same
#' taxonomic family as `sel_taxon`, as returned by
#' [get_family_trait_summary()]. Must contain columns `taxon_name`
#' (character), `n` (integer), and `median` (numeric).
#' @param data_group_summary
#' A single-row tibble of per-group QC statistics for the focal taxon,
#' as produced by [generate_trait_qc_report()]. Must contain a numeric
#' column `median` used to place the firebrick reference point.
#' @param sel_taxon
#' Character scalar. Name of the focal taxon. Used in the plot title.
#' @param sel_domain
#' Character scalar. Trait domain being inspected. Used in axis labels.
#' @param sel_min_n
#' Positive integer scalar. Minimum number of records a taxon must
#' have to appear in the plot. Defaults to `5L`.
#' @param graphical_options
#' Named list with elements `width`, `height`, `units`, `dpi`, and
#' `bg`, as returned by `get_active_config("graphical")`. Passed to
#' `ggview::canvas()`.
#' @param verbose
#' Logical. If `TRUE` (default), the number of taxa shown in the plot
#' after the `sel_min_n` filter is reported via `cli::cli_inform()`.
#' @return
#' A `ggplot2` object. The plot is not printed; call `print()` on the
#' return value to display it.
#' @details
#' All taxa in `data_family_comparison` with `n >= sel_min_n` are
#' shown as grey jittered points on a log\ifelse{html}{\out{<sub>
#' 10</sub>}}{{10}} x-axis. The focal taxon's median  (from
#' `data_group_summary`) is overlaid as a larger firebrick point.
#' When no family members meet the `sel_min_n` threshold the grey
#' layer is empty and only the focal taxon point is drawn.
#'
#' Plot layer order follows project conventions: `ggplot2::ggplot()`
#' → scales → labels → theme → `ggview::canvas()` → geoms.
#' @seealso
#' [get_family_trait_summary()], [plot_trait_group_distribution()],
#' [generate_trait_qc_report()]
#' @examples
#' \dontrun{
#' data_family <-
#'   get_family_trait_summary(
#'     data_traits_raw = data_traits_raw,
#'     data_classification = data_classification,
#'     sel_taxon = "Anacyclus clavatus",
#'     sel_domain = "Leaf Area"
#'   )
#'
#' data_summary <-
#'   data_qc_report |>
#'   dplyr::filter(
#'     taxon_name == "Anacyclus clavatus",
#'     trait_domain_name == "Leaf Area"
#'   )
#'
#' graphical_options <-
#'   get_active_config("graphical")
#'
#' p <-
#'   plot_family_trait_comparison(
#'     data_family_comparison = data_family,
#'     data_group_summary = data_summary,
#'     sel_taxon = "Anacyclus clavatus",
#'     sel_domain = "Leaf Area",
#'     sel_min_n = 5L,
#'     graphical_options = graphical_options
#'   )
#'
#' base::print(p)
#' }
#' @export
plot_family_trait_comparison <- function(
    data_family_comparison,
    data_group_summary,
    sel_taxon,
    sel_domain,
    sel_min_n = 5L,
    graphical_options,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_family_comparison),
    msg = "'data_family_comparison' must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      c("taxon_name", "n", "median") %in%
        base::names(data_family_comparison)
    ),
    msg = stringr::str_c(
      "'data_family_comparison' must contain columns ",
      "'taxon_name', 'n', and 'median'."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_group_summary),
    msg = "'data_group_summary' must be a data frame."
  )

  assertthat::assert_that(
    base::nrow(data_group_summary) == 1L,
    msg = "'data_group_summary' must have exactly one row."
  )

  assertthat::assert_that(
    "median" %in% base::names(data_group_summary),
    msg = "'data_group_summary' must contain a 'median' column."
  )

  assertthat::assert_that(
    base::is.character(sel_taxon),
    msg = "'sel_taxon' must be a character scalar."
  )

  assertthat::assert_that(
    base::length(sel_taxon) == 1L,
    msg = "'sel_taxon' must be a scalar (length 1)."
  )

  assertthat::assert_that(
    !base::is.na(sel_taxon),
    msg = "'sel_taxon' must not be NA."
  )

  assertthat::assert_that(
    base::is.character(sel_domain),
    msg = "'sel_domain' must be a character scalar."
  )

  assertthat::assert_that(
    base::length(sel_domain) == 1L,
    msg = "'sel_domain' must be a scalar (length 1)."
  )

  assertthat::assert_that(
    !base::is.na(sel_domain),
    msg = "'sel_domain' must not be NA."
  )

  assertthat::assert_that(
    base::is.numeric(sel_min_n) || base::is.integer(sel_min_n),
    msg = "'sel_min_n' must be a positive integer scalar."
  )

  assertthat::assert_that(
    base::length(sel_min_n) == 1L,
    msg = "'sel_min_n' must be a scalar (length 1)."
  )

  assertthat::assert_that(
    !base::is.na(sel_min_n) && sel_min_n >= 1L,
    msg = "'sel_min_n' must be a positive integer (>= 1)."
  )

  assertthat::assert_that(
    base::is.list(graphical_options),
    msg = "'graphical_options' must be a named list."
  )

  assertthat::assert_that(
    base::all(
      c("width", "height", "units", "dpi", "bg") %in%
        base::names(graphical_options)
    ),
    msg = stringr::str_c(
      "'graphical_options' must contain elements: ",
      "'width', 'height', 'units', 'dpi', 'bg'."
    )
  )

  assertthat::assert_that(
    base::is.logical(verbose),
    msg = "'verbose' must be logical (TRUE or FALSE)."
  )

  assertthat::assert_that(
    base::length(verbose) == 1L,
    msg = "'verbose' must be a scalar (length 1)."
  )

  # Filter family data to taxa that meet the minimum record threshold.
  data_family_filtered <-
    data_family_comparison |>
    dplyr::filter(.data[["n"]] >= sel_min_n)

  n_shown <-
    base::nrow(data_family_filtered)

  if (
    verbose
  ) {
    cli::cli_inform(
      stringr::str_glue(
        "Family comparison: {n_shown} taxa with n >= {sel_min_n} shown."
      )
    )
  }

  res_plot <-
    data_family_filtered |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = .data[["median"]],
        y = 0
      )
    ) +
    ggplot2::scale_x_log10() +
    ggplot2::labs(
      x = stringr::str_glue(
        "{sel_domain} (median, log\u2081\u2080 scale)"
      ),
      y = NULL,
      title = stringr::str_glue(
        "{sel_taxon} within family (n \u2265 {sel_min_n})"
      )
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank()
    ) +
    ggview::canvas(
      width = purrr::chuck(graphical_options, "width"),
      height = purrr::chuck(graphical_options, "height"),
      units = purrr::chuck(graphical_options, "units"),
      dpi = purrr::chuck(graphical_options, "dpi"),
      bg = purrr::chuck(graphical_options, "bg")
    ) +
    ggplot2::geom_jitter(
      alpha = 0.4,
      height = 0.1,
      colour = "grey50",
      size = 1.5
    ) +
    ggplot2::geom_point(
      data = data_group_summary,
      mapping = ggplot2::aes(x = .data[["median"]]),
      colour = "firebrick",
      size = 3.5
    )

  return(res_plot)
}
