#' @title Plot a Taxonomic Trait Comparison
#' @description
#' Builds a `ggplot2` log\ifelse{html}{\out{<sub>10</sub>}}{{10}}-scale
#' strip plot comparing the median trait value of a focal taxon against
#' taxa in the selected taxonomic group. Grey jittered dots represent
#' group members that meet the minimum record threshold;
#' a firebrick point marks the focal taxon.
#' @param data_taxonomic_trait_summary
#' A tibble of per-taxon summary statistics returned by
#' [summarise_taxonomic_group_traits()]. Must contain `taxon_name`,
#' `n_records`, and `median`.
#' @param data_focal_trait_summary
#' A single-row tibble of per-group QC statistics for the focal taxon,
#' as produced by [generate_trait_qc_report()]. Must contain a numeric
#' column `median` used to place the firebrick reference point.
#' @param focal_taxon
#' Character scalar. Name of the focal taxon. Used in the plot title.
#' @param trait_domain
#' Character scalar. Trait domain being inspected. Used in axis labels.
#' @param minimum_records
#' Positive integer scalar. Minimum number of records a taxon must
#' have to appear in the plot. Defaults to `5L`.
#' @param graphical_options
#' Named list with elements `width`, `height`, `units`, `dpi`, and
#' `bg`, as returned by `load_active_config_value("graphical")`. Passed to
#' `ggview::canvas()`.
#' @param verbose
#' Logical. If `TRUE` (default), the number of taxa shown in the plot
#' after the `minimum_records` filter is reported via
#' `cli::cli_inform()`.
#' @return
#' A `ggplot2` object. The plot is not printed; call `print()` on the
#' return value to display it.
#' @details
#' All taxa with `n_records >= minimum_records` are
#' shown as grey jittered points on a log\ifelse{html}{\out{<sub>
#' 10</sub>}}{{10}} x-axis. The focal taxon's median from
#' `data_focal_trait_summary` is overlaid as a larger firebrick point.
#' When no group members meet the threshold the grey
#' layer is empty and only the focal taxon point is drawn.
#'
#' Plot layer order follows project conventions: `ggplot2::ggplot()`
#' -> scales -> labels -> theme -> `ggview::canvas()` -> geoms.
#' @seealso
#' [summarise_taxonomic_group_traits()],
#' [plot_focal_trait_distribution()],
#' [generate_trait_qc_report()]
#' @examples
#' \dontrun{
#' data_taxonomic_trait_summary <-
#'   summarise_taxonomic_group_traits(
#'     data_trait_records = data_traits_raw,
#'     data_taxon_classification = data_classification,
#'     focal_taxon = "Anacyclus clavatus",
#'     trait_domain = "Leaf Area"
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
#'   load_active_config_value("graphical")
#'
#' p <-
#'   plot_taxonomic_trait_comparison(
#'     data_taxonomic_trait_summary = data_taxonomic_trait_summary,
#'     data_focal_trait_summary = data_summary,
#'     focal_taxon = "Anacyclus clavatus",
#'     trait_domain = "Leaf Area",
#'     minimum_records = 5L,
#'     graphical_options = graphical_options
#'   )
#'
#' base::print(p)
#' }
#' @export
plot_taxonomic_trait_comparison <- function(
    data_taxonomic_trait_summary,
    data_focal_trait_summary,
    focal_taxon,
    trait_domain,
    minimum_records = 5L,
    graphical_options,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_taxonomic_trait_summary),
    msg = "'data_taxonomic_trait_summary' must be a data frame."
  )

  assertthat::assert_that(
    base::all(
      c("taxon_name", "n_records", "median") %in%
        base::names(data_taxonomic_trait_summary)
    ),
    msg = stringr::str_c(
      "'data_taxonomic_trait_summary' must contain columns ",
      "'taxon_name', 'n_records', and 'median'."
    )
  )

  assertthat::assert_that(
    base::is.data.frame(data_focal_trait_summary),
    msg = "'data_focal_trait_summary' must be a data frame."
  )

  assertthat::assert_that(
    base::nrow(data_focal_trait_summary) == 1L,
    msg = "'data_focal_trait_summary' must have exactly one row."
  )

  assertthat::assert_that(
    "median" %in% base::names(data_focal_trait_summary),
    msg = "'data_focal_trait_summary' must contain a 'median' column."
  )

  assertthat::assert_that(
    base::is.character(focal_taxon),
    msg = "'focal_taxon' must be a character scalar."
  )

  assertthat::assert_that(
    base::length(focal_taxon) == 1L,
    msg = "'focal_taxon' must be a scalar (length 1)."
  )

  assertthat::assert_that(
    !base::is.na(focal_taxon),
    msg = "'focal_taxon' must not be NA."
  )

  assertthat::assert_that(
    base::is.character(trait_domain),
    msg = "'trait_domain' must be a character scalar."
  )

  assertthat::assert_that(
    base::length(trait_domain) == 1L,
    msg = "'trait_domain' must be a scalar (length 1)."
  )

  assertthat::assert_that(
    !base::is.na(trait_domain),
    msg = "'trait_domain' must not be NA."
  )

  assertthat::assert_that(
    base::is.numeric(minimum_records) ||
      base::is.integer(minimum_records),
    msg = "'minimum_records' must be a positive integer scalar."
  )

  assertthat::assert_that(
    base::length(minimum_records) == 1L,
    msg = "'minimum_records' must be a scalar (length 1)."
  )

  assertthat::assert_that(
    !base::is.na(minimum_records) && minimum_records >= 1L,
    msg = "'minimum_records' must be a positive integer (>= 1)."
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

  data_taxonomic_trait_filtered <-
    data_taxonomic_trait_summary |>
    dplyr::filter(.data[["n_records"]] >= minimum_records)

  n_taxa_shown <-
    base::nrow(data_taxonomic_trait_filtered)

  if (
    verbose
  ) {
    cli::cli_inform(
      stringr::str_glue(
        "Taxonomic comparison: {n_taxa_shown} taxa with ",
        "n_records >= {minimum_records} shown."
      )
    )
  }

  plot_taxonomic_comparison <-
    data_taxonomic_trait_filtered |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = .data[["median"]],
        y = 0
      )
    ) +
    ggplot2::scale_x_log10() +
    ggplot2::labs(
      x = stringr::str_glue(
        "{trait_domain} (median, log\u2081\u2080 scale)"
      ),
      y = NULL,
      title = stringr::str_glue(
        "{focal_taxon} within taxonomic group ",
        "(n \u2265 {minimum_records})"
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
      data = data_focal_trait_summary,
      mapping = ggplot2::aes(x = .data[["median"]]),
      colour = "firebrick",
      size = 3.5
    )

  return(plot_taxonomic_comparison)
}
