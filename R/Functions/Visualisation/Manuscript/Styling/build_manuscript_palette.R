#' @title Build a Manuscript Figure Palette
#' @description
#' Returns a colourblind-aware named palette for a supported scientific
#' semantic domain. Mappings are stable across all main-analysis figures.
#' @param domain Character scalar selecting the semantic palette.
#' @return A named character vector of hexadecimal colours.
#' @export
build_manuscript_palette <- function(
    domain = base::c(
      "variance_component",
      "data_source",
      "taxonomic_resolution",
      "continent",
      "availability"
    )) {
  domain_selected <-
    base::match.arg(domain)

  list_palettes <-
    base::list(
      variance_component = base::c(
        "Biotic co-occurrence" = "#7B3294",
        "Climate" = "#E69F00",
        "Spatial" = "#0072B2",
        "Unexplained" = "#D9D9D9"
      ),
      data_source = base::c(
        "Paleo" = "#6A3D9A",
        "Modern" = "#009E73"
      ),
      taxonomic_resolution = base::c(
        "Genus" = "#0072B2",
        "Family" = "#D55E00",
        "Functional type" = "#CC79A7"
      ),
      continent = base::c(
        "america" = "#0072B2",
        "europe" = "#009E73",
        "asia" = "#D55E00"
      ),
      availability = base::c(
        "available" = "#4D4D4D",
        "expected_infeasible" = "#F0E442",
        "missing_model" = "#BDBDBD"
      )
    )

  res_palette <-
    list_palettes[[domain_selected]]

  return(res_palette)
}
