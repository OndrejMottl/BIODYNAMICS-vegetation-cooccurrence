#' @title Plot a Focal Taxon-Domain Trait Distribution
#' @description
#' Builds a `ggplot2` strip + boxplot showing every raw trait value for
#' one focal `taxon_name x trait_domain_name` slice, with colour-coded
#' Tukey fence flags and horizontal fence lines for both the standard
#' (1.5x IQR) and extreme (3x IQR) thresholds.
#' @param data_focal_trait_records
#' A tibble of raw trait observations for one focal taxon-domain slice.
#' Must contain columns `trait_value` (numeric), `trait_name`
#' (character), and `trait_domain_name` (character).
#' @param data_focal_trait_summary
#' A single-row tibble of focal-slice QC statistics, as produced by
#' `write_trait_quality_control_report()`. Must contain numeric columns `mean`,
#' `median`, `IQR`, and integer columns `n_suspected_outliers_taxon`
#' (integer) and `outlier_fraction` (numeric).
#' @param focal_taxon
#' Character scalar. Name of the taxon being inspected. Used in the
#' plot title.
#' @param trait_domain
#' Character scalar. Name of the trait domain being inspected. Used in
#' the plot title.
#' @param graphical_options
#' Named list with elements `width`, `height`, `units`, `dpi`, and
#' `bg`, as returned by `load_active_config_value("graphical")`. Passed to
#' `ggview::canvas()`.
#' @param verbose
#' Logical. If `TRUE` (default), the computed Tukey fence boundaries
#' are printed to the console via `cli::cli_inform()`.
#' @return
#' A `ggplot2` object. The plot is not printed; call `print()` on the
#' return value to display it.
#' @details
#' The function computes Q1, Q3, and IQR from `data_focal_trait_records` and
#' derives four fence values:
#' - inner lower / upper: Q1 - 1.5 * IQR and Q3 + 1.5 * IQR
#' - outer lower / upper: Q1 - 3 * IQR and Q3 + 3 * IQR
#'
#' Each observation is classified as `"within fence"`,
#' `"mild outlier (1.5x IQR)"`, or `"extreme outlier (3x IQR)"`.
#' When `data_focal_trait_records` contains more than one distinct `trait_name`,
#' observations are faceted by `trait_name`; otherwise the x-axis shows
#' `trait_domain_name`.
#'
#' Plot layer order follows project conventions: `ggplot()` -> facets
#' -> scales -> labels -> theme -> `ggview::canvas()` -> geoms.
#' @seealso
#' [write_trait_quality_control_report()], [load_trait_corrections()],
#' [validate_trait_corrections()], [correct_trait_records()]
#' @examples
#' \dontrun{
#' data_focal_trait_records <-
#'   data_traits_raw |>
#'   dplyr::filter(
#'     taxon_name == "Anacyclus clavatus",
#'     trait_domain_name == "Leaf Area"
#'   ) |>
#'   dplyr::arrange(trait_value)
#'
#' data_focal_trait_summary <-
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
#'   plot_focal_trait_distribution(
#'     data_focal_trait_records = data_focal_trait_records,
#'     data_focal_trait_summary = data_focal_trait_summary,
#'     focal_taxon = "Anacyclus clavatus",
#'     trait_domain = "Leaf Area",
#'     graphical_options = graphical_options
#'   )
#'
#' base::print(p)
#' }
#' @export
plot_focal_trait_distribution <- function(
    data_focal_trait_records,
    data_focal_trait_summary,
    focal_taxon,
    trait_domain,
    graphical_options,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_focal_trait_records),
    msg = "data_focal_trait_records must be a data frame or tibble."
  )

  assertthat::assert_that(
    base::nrow(data_focal_trait_records) >= 1L,
    msg = "data_focal_trait_records must have at least one row."
  )

  assertthat::assert_that(
    base::all(
      c("trait_value", "trait_name", "trait_domain_name") %in%
        base::colnames(data_focal_trait_records)
    ),
    msg = base::paste0(
      "data_focal_trait_records must contain columns: ",
      "'trait_value', 'trait_name', 'trait_domain_name'."
    )
  )

  assertthat::assert_that(
    base::is.numeric(
      dplyr::pull(data_focal_trait_records, trait_value)
    ),
    msg = "data_focal_trait_records$trait_value must be numeric."
  )

  assertthat::assert_that(
    base::is.data.frame(data_focal_trait_summary),
    msg = "data_focal_trait_summary must be a data frame or tibble."
  )

  assertthat::assert_that(
    base::nrow(data_focal_trait_summary) == 1L,
    msg = "data_focal_trait_summary must have exactly one row."
  )

  assertthat::assert_that(
    base::all(
      c(
        "mean", "median", "IQR",
        "n_suspected_outliers_taxon", "outlier_fraction"
      ) %in% base::colnames(data_focal_trait_summary)
    ),
    msg = base::paste0(
      "data_focal_trait_summary must contain columns: 'mean', 'median', ",
      "'IQR', 'n_suspected_outliers_taxon', 'outlier_fraction'."
    )
  )

  assertthat::assert_that(
    base::is.character(focal_taxon),
    msg = "focal_taxon must be a character string."
  )

  assertthat::assert_that(
    base::length(focal_taxon) == 1L,
    msg = "focal_taxon must be a scalar (length 1)."
  )

  assertthat::assert_that(
    !base::is.na(focal_taxon),
    msg = "focal_taxon must not be NA."
  )

  assertthat::assert_that(
    base::is.character(trait_domain),
    msg = "trait_domain must be a character string."
  )

  assertthat::assert_that(
    base::length(trait_domain) == 1L,
    msg = "trait_domain must be a scalar (length 1)."
  )

  assertthat::assert_that(
    !base::is.na(trait_domain),
    msg = "trait_domain must not be NA."
  )

  assertthat::assert_that(
    base::is.list(graphical_options),
    msg = "graphical_options must be a named list."
  )

  assertthat::assert_that(
    base::all(
      c("width", "height", "units", "dpi", "bg") %in%
        base::names(graphical_options)
    ),
    msg = base::paste0(
      "graphical_options must contain elements: ",
      "'width', 'height', 'units', 'dpi', 'bg'."
    )
  )

  assertthat::assert_that(
    base::is.logical(verbose),
    msg = "verbose must be logical (TRUE or FALSE)."
  )

  assertthat::assert_that(
    base::length(verbose) == 1L,
    msg = "verbose must be a scalar (length 1)."
  )

  trait_values <-
    dplyr::pull(data_focal_trait_records, .data[["trait_value"]])

  lower_quartile <-
    stats::quantile(
      trait_values,
      probs = 0.25,
      na.rm = TRUE,
      names = FALSE
    )

  upper_quartile <-
    stats::quantile(
      trait_values,
      probs = 0.75,
      na.rm = TRUE,
      names = FALSE
    )

  interquartile_range <-
    stats::IQR(trait_values, na.rm = TRUE)

  inner_lower_fence <-
    lower_quartile - 1.5 * interquartile_range

  inner_upper_fence <-
    upper_quartile + 1.5 * interquartile_range

  outer_lower_fence <-
    lower_quartile - 3.0 * interquartile_range

  outer_upper_fence <-
    upper_quartile + 3.0 * interquartile_range

  data_focal_trait_flagged <-
    data_focal_trait_records |>
    dplyr::mutate(
      flag_status = dplyr::case_when(
        .data[["trait_value"]] < outer_lower_fence |
          .data[["trait_value"]] > outer_upper_fence ~
          "extreme outlier (3x IQR)",
        .data[["trait_value"]] < inner_lower_fence |
          .data[["trait_value"]] > inner_upper_fence ~
          "mild outlier (1.5x IQR)",
        .default = "within fence"
      )
    )

  data_trait_fences <-
    tibble::tibble(
      label = c(
        "inner lower (1.5x)", "inner upper (1.5x)",
        "outer lower (3x)", "outer upper (3x)"
      ),
      value = c(
        inner_lower_fence, inner_upper_fence,
        outer_lower_fence, outer_upper_fence
      ),
      fence_type = c("inner", "inner", "outer", "outer")
    )

  n_trait_names <-
    dplyr::n_distinct(
      dplyr::pull(
        data_focal_trait_records,
        .data[["trait_name"]]
      )
    )

  if (
    n_trait_names > 1L
  ) {
    x_variable <- "trait_name"
    x_axis_label <- "Trait name"
  } else {
    x_variable <- "trait_domain_name"
    x_axis_label <- "Trait domain"
  }

  plot_focal_distribution <-
    data_focal_trait_flagged |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = .data[[x_variable]],
        y = .data[["trait_value"]],
        colour = .data[["flag_status"]]
      )
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data[[x_variable]]),
      scales = "free_x",
      nrow = 1L
    ) +
    ggplot2::scale_colour_manual(
      values = c(
        "within fence" = "#2c7bb6",
        "mild outlier (1.5x IQR)" = "#fdae61",
        "extreme outlier (3x IQR)" = "#d7191c"
      ),
      name = "Flag status"
    ) +
    ggplot2::labs(
      title = base::paste0(focal_taxon, "  \u00d7  ", trait_domain),
      subtitle = base::paste0(
        "n = ", base::nrow(data_focal_trait_records),
        "   |   mean = ",
        base::round(
          dplyr::pull(
            data_focal_trait_summary,
            .data[["mean"]]
          ),
          3L
        ),
        "   |   median = ",
        base::round(
          dplyr::pull(
            data_focal_trait_summary,
            .data[["median"]]
          ),
          3L
        ),
        "   |   IQR = ",
        base::round(
          dplyr::pull(
            data_focal_trait_summary,
            .data[["IQR"]]
          ),
          3L
        ),
        "   |   flagged = ",
        dplyr::pull(
          data_focal_trait_summary,
          .data[["n_suspected_outliers_taxon"]]
        ),
        " (",
        base::round(
          dplyr::pull(
            data_focal_trait_summary,
            .data[["outlier_fraction"]]
          ) * 100,
          1L
        ),
        "%)"
      ),
      x = x_axis_label,
      y = "Trait value"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title = ggplot2::element_text(face = "bold")
    ) +
    ggview::canvas(
      width = purrr::chuck(graphical_options, "width"),
      height = purrr::chuck(graphical_options, "height"),
      units = purrr::chuck(graphical_options, "units"),
      dpi = purrr::chuck(graphical_options, "dpi"),
      bg = purrr::chuck(graphical_options, "bg")
    ) +
    ggplot2::geom_hline(
      data = data_trait_fences,
      mapping = ggplot2::aes(
        yintercept = .data[["value"]],
        linetype = .data[["fence_type"]]
      ),
      colour = "grey40",
      linewidth = 0.5
    ) +
    ggplot2::geom_boxplot(
      alpha = 0,
      outlier.shape = NA,
      colour = "grey30",
      width = 0.4
    ) +
    ggplot2::geom_jitter(
      width = 0.1,
      size = 2L,
      alpha = 0.8
    )

  if (
    base::isTRUE(verbose)
  ) {
    cli::cli_inform(
      base::paste0(
        "Fences: inner = [",
        base::round(inner_lower_fence, 3L), ", ",
        base::round(inner_upper_fence, 3L), "]",
        "   outer = [",
        base::round(outer_lower_fence, 3L), ", ",
        base::round(outer_upper_fence, 3L), "]"
      )
    )
  }

  return(plot_focal_distribution)
}
