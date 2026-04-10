#' @title Plot Raw Trait Value Distribution for One Taxon-Domain Group
#' @description
#' Builds a `ggplot2` strip + boxplot showing every raw trait value for
#' a single `taxon_name x trait_domain_name` group, with colour-coded
#' Tukey fence flags and horizontal fence lines for both the standard
#' (1.5x IQR) and extreme (3x IQR) thresholds.
#' @param data_group_raw
#' A tibble of raw trait observations for one taxon x domain group.
#' Must contain columns `trait_value` (numeric), `trait_name`
#' (character), and `trait_domain_name` (character).
#' @param data_group_summary
#' A single-row tibble of per-group QC statistics, as produced by
#' `generate_trait_qc_report()`. Must contain numeric columns `mean`,
#' `median`, `IQR`, and integer columns `n_suspected_outliers_taxon`
#' (integer) and `outlier_fraction` (numeric).
#' @param sel_taxon
#' Character scalar. Name of the taxon being inspected. Used in the
#' plot title.
#' @param sel_domain
#' Character scalar. Name of the trait domain being inspected. Used in
#' the plot title.
#' @param graphical_options
#' Named list with elements `width`, `height`, `units`, `dpi`, and
#' `bg`, as returned by `get_active_config("graphical")`. Passed to
#' `ggview::canvas()`.
#' @param verbose
#' Logical. If `TRUE` (default), the computed Tukey fence boundaries
#' are printed to the console via `cli::cli_inform()`.
#' @return
#' A `ggplot2` object. The plot is not printed; call `print()` on the
#' return value to display it.
#' @details
#' The function computes Q1, Q3, and IQR from `data_group_raw` and
#' derives four fence values:
#' - inner lower / upper: Q1 - 1.5 * IQR and Q3 + 1.5 * IQR
#' - outer lower / upper: Q1 - 3 * IQR and Q3 + 3 * IQR
#'
#' Each observation is classified as `"within fence"`,
#' `"mild outlier (1.5x IQR)"`, or `"extreme outlier (3x IQR)"`.
#' When `data_group_raw` contains more than one distinct `trait_name`,
#' observations are faceted by `trait_name`; otherwise the x-axis shows
#' `trait_domain_name`.
#'
#' Plot layer order follows project conventions: `ggplot()` -> facets
#' -> scales -> labels -> theme -> `ggview::canvas()` -> geoms.
#' @seealso
#' [generate_trait_qc_report()], [apply_trait_corrections()],
#' [validate_trait_corrections()]
#' @examples
#' \dontrun{
#' data_raw <-
#'   data_traits_raw |>
#'   dplyr::filter(
#'     taxon_name == "Anacyclus clavatus",
#'     trait_domain_name == "Leaf Area"
#'   ) |>
#'   dplyr::arrange(trait_value)
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
#'   plot_trait_group_distribution(
#'     data_group_raw = data_raw,
#'     data_group_summary = data_summary,
#'     sel_taxon = "Anacyclus clavatus",
#'     sel_domain = "Leaf Area",
#'     graphical_options = graphical_options
#'   )
#'
#' base::print(p)
#' }
#' @export
plot_trait_group_distribution <- function(
    data_group_raw,
    data_group_summary,
    sel_taxon,
    sel_domain,
    graphical_options,
    verbose = TRUE) {
  assertthat::assert_that(
    base::is.data.frame(data_group_raw),
    msg = "data_group_raw must be a data frame or tibble."
  )

  assertthat::assert_that(
    base::nrow(data_group_raw) >= 1L,
    msg = "data_group_raw must have at least one row."
  )

  assertthat::assert_that(
    base::all(
      c("trait_value", "trait_name", "trait_domain_name") %in%
        base::colnames(data_group_raw)
    ),
    msg = base::paste0(
      "data_group_raw must contain columns: ",
      "'trait_value', 'trait_name', 'trait_domain_name'."
    )
  )

  assertthat::assert_that(
    base::is.numeric(
      dplyr::pull(data_group_raw, trait_value)
    ),
    msg = "data_group_raw$trait_value must be numeric."
  )

  assertthat::assert_that(
    base::is.data.frame(data_group_summary),
    msg = "data_group_summary must be a data frame or tibble."
  )

  assertthat::assert_that(
    base::nrow(data_group_summary) == 1L,
    msg = "data_group_summary must have exactly one row."
  )

  assertthat::assert_that(
    base::all(
      c(
        "mean", "median", "IQR",
        "n_suspected_outliers_taxon", "outlier_fraction"
      ) %in% base::colnames(data_group_summary)
    ),
    msg = base::paste0(
      "data_group_summary must contain columns: 'mean', 'median', ",
      "'IQR', 'n_suspected_outliers_taxon', 'outlier_fraction'."
    )
  )

  assertthat::assert_that(
    base::is.character(sel_taxon),
    msg = "sel_taxon must be a character string."
  )

  assertthat::assert_that(
    base::length(sel_taxon) == 1L,
    msg = "sel_taxon must be a scalar (length 1)."
  )

  assertthat::assert_that(
    !base::is.na(sel_taxon),
    msg = "sel_taxon must not be NA."
  )

  assertthat::assert_that(
    base::is.character(sel_domain),
    msg = "sel_domain must be a character string."
  )

  assertthat::assert_that(
    base::length(sel_domain) == 1L,
    msg = "sel_domain must be a scalar (length 1)."
  )

  assertthat::assert_that(
    !base::is.na(sel_domain),
    msg = "sel_domain must not be NA."
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

  # Compute Tukey fence thresholds from raw values.
  vec_values <-
    dplyr::pull(data_group_raw, trait_value)

  q1 <-
    stats::quantile(vec_values, probs = 0.25, na.rm = TRUE)

  q3 <-
    stats::quantile(vec_values, probs = 0.75, na.rm = TRUE)

  iqr_val <-
    stats::IQR(vec_values, na.rm = TRUE)

  fence_inner_lwr <-
    q1 - 1.5 * iqr_val

  fence_inner_upr <-
    q3 + 1.5 * iqr_val

  fence_outer_lwr <-
    q1 - 3.0 * iqr_val

  fence_outer_upr <-
    q3 + 3.0 * iqr_val

  # Flag each raw observation for colour coding.
  data_group_flagged <-
    data_group_raw |>
    dplyr::mutate(
      flag_status = dplyr::case_when(
        trait_value < fence_outer_lwr |
          trait_value > fence_outer_upr ~
          "extreme outlier (3x IQR)",
        trait_value < fence_inner_lwr |
          trait_value > fence_inner_upr ~
          "mild outlier (1.5x IQR)",
        .default = "within fence"
      )
    )

  # Build data frame for horizontal fence lines.
  data_fences <-
    tibble::tibble(
      label = c(
        "inner lower (1.5x)", "inner upper (1.5x)",
        "outer lower (3x)", "outer upper (3x)"
      ),
      value = c(
        fence_inner_lwr, fence_inner_upr,
        fence_outer_lwr, fence_outer_upr
      ),
      fence_type = c("inner", "inner", "outer", "outer")
    )

  # Determine x-axis variable (use trait_name if >1 trait per domain).
  n_trait_names <-
    dplyr::n_distinct(
      dplyr::pull(data_group_raw, trait_name)
    )

  if (
    n_trait_names > 1L
  ) {
    x_var <- "trait_name"
    x_label <- "Trait name"
  } else {
    x_var <- "trait_domain_name"
    x_label <- "Trait domain"
  }

  res_plot <-
    data_group_flagged |>
    ggplot2::ggplot(
      mapping = ggplot2::aes(
        x = .data[[x_var]],
        y = trait_value,
        colour = flag_status
      )
    ) +
    ggplot2::facet_wrap(
      ggplot2::vars(.data[[x_var]]),
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
      title = base::paste0(sel_taxon, "  \u00d7  ", sel_domain),
      subtitle = base::paste0(
        "n = ", base::nrow(data_group_raw),
        "   |   mean = ",
        base::round(
          dplyr::pull(data_group_summary, mean), 3L
        ),
        "   |   median = ",
        base::round(
          dplyr::pull(data_group_summary, median), 3L
        ),
        "   |   IQR = ",
        base::round(
          dplyr::pull(data_group_summary, IQR), 3L
        ),
        "   |   flagged = ",
        dplyr::pull(
          data_group_summary, n_suspected_outliers_taxon
        ),
        " (",
        base::round(
          dplyr::pull(data_group_summary, outlier_fraction) * 100,
          1L
        ),
        "%)"
      ),
      x = x_label,
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
      data = data_fences,
      mapping = ggplot2::aes(
        yintercept = value,
        linetype = fence_type
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
        base::round(fence_inner_lwr, 3L), ", ",
        base::round(fence_inner_upr, 3L), "]",
        "   outer = [",
        base::round(fence_outer_lwr, 3L), ", ",
        base::round(fence_outer_upr, 3L), "]"
      )
    )
  }

  return(res_plot)
}
