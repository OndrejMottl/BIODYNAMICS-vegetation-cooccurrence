#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#      Compare the partition between nested extents
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Compares every spatial unit with its parent unit on the taxa
#   present in both models, using the reconciled per-taxon
#   allocation on the additive deviance scale.
# Exploratory: units sharing a parent are not independent, so
#   the printed p-values are optimistic.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R/___setup_project___.R")
)

base::options(width = 220, pillar.sigfig = 2)

path_output <-
  here::here("Outputs/Tables/Diagnostics/Taxon_variance_partition")

# Fewer shared taxa make the ratio of sums unstable
n_shared_taxa_min <- 5L

vec_unit_keys <-
  c("data_source", "resolution_id", "definition")


#----------------------------------------------------------#
# 1. Inputs -----
#----------------------------------------------------------#

data_taxon_reconciled <-
  base::list.files(
    path = path_output,
    pattern = "^taxon_allocation_reconciled_.*[.]csv$",
    full.names = TRUE
  ) |>
  base::sort() |>
  utils::tail(n = 1) |>
  readr::read_csv(show_col_types = FALSE) |>
  dplyr::filter(.data[["scale"]] != "temporal") |>
  dplyr::mutate(
    region_id = dplyr::if_else(
      condition = .data[["scale"]] == "continental",
      true = NA_character_,
      false = stringr::str_extract(
        string = .data[["scale_id"]],
        pattern = "^[a-z]+_r[0-9]+"
      )
    )
  )

vec_id_columns <-
  c(
    "data_source", "scale", "scale_id", "continent_id",
    "region_id", "resolution_id", "n_taxa", "taxon"
  )

# Two definitions in one long table:
#    equal_split  shared fractions divided among components
#    unique       unique fractions only
data_taxon_long <-
  dplyr::bind_rows(
    data_taxon_reconciled |>
      dplyr::select(
        dplyr::all_of(vec_id_columns),
        "climate", "associations", "space"
      ) |>
      dplyr::mutate(definition = "equal_split"),
    data_taxon_reconciled |>
      dplyr::select(
        dplyr::all_of(vec_id_columns),
        climate = "climate_unique",
        associations = "associations_unique",
        space = "space_unique"
      ) |>
      dplyr::mutate(definition = "unique")
  )


#----------------------------------------------------------#
# 2. Helpers -----
#----------------------------------------------------------#

# Shares of a set of taxa as a ratio of sums; a sum below
#    zero is floored once, after the taxa are added up
summarise_taxon_set <- function(data_source, vec_group) {
  res <-
    data_source |>
    dplyr::group_by(
      dplyr::across(dplyr::all_of(vec_group))
    ) |>
    dplyr::summarise(
      n_taxa_set = dplyr::n(),
      dplyr::across(
        .cols = c("climate", "associations", "space"),
        .fns = ~ base::pmax(base::sum(.x), 0)
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      association_share = .data[["associations"]] /
        (
          .data[["climate"]] + .data[["associations"]] +
            .data[["space"]]
        ),
      climate_balance = .data[["climate"]] /
        (.data[["climate"]] + .data[["space"]])
    ) |>
    dplyr::select(-"climate", -"associations", -"space")

  return(res)
}

# One row per child unit: child and parent shares on the
#    shared taxa and on all taxa of each model
build_nested_contrast <- function(data_child,
                                  data_parent,
                                  vec_by,
                                  transition_name) {
  data_parent_renamed <-
    data_parent |>
    dplyr::select(
      dplyr::all_of(c(vec_unit_keys, vec_by, "taxon")),
      scale_id_parent = "scale_id",
      n_taxa_parent = "n_taxa"
    )

  # Taxa of the child that the parent model also holds
  data_child_shared <-
    data_child |>
    dplyr::inner_join(
      y = data_parent_renamed,
      by = c(vec_unit_keys, vec_by, "taxon")
    )

  # The same taxa as they appear in the parent model
  data_parent_shared <-
    data_parent |>
    dplyr::select(
      dplyr::all_of(c(vec_unit_keys, "taxon")),
      scale_id_parent = "scale_id",
      "climate", "associations", "space"
    ) |>
    dplyr::inner_join(
      y = data_child_shared |>
        dplyr::select(
          dplyr::all_of(c(vec_unit_keys, "taxon")),
          "scale_id", "scale_id_parent"
        ),
      by = c(vec_unit_keys, "taxon", "scale_id_parent")
    )

  vec_pair <-
    c(vec_unit_keys, "scale_id", "scale_id_parent")

  res <-
    summarise_taxon_set(
      data_source = data_child_shared,
      vec_group = c(vec_pair, "n_taxa", "n_taxa_parent")
    ) |>
    dplyr::inner_join(
      y = summarise_taxon_set(
        data_source = data_parent_shared,
        vec_group = vec_pair
      ),
      by = c(vec_pair, "n_taxa_set"),
      suffix = c("_child", "_parent")
    ) |>
    dplyr::filter(.data[["n_taxa_set"]] >= n_shared_taxa_min) |>
    dplyr::mutate(transition = transition_name)

  return(res)
}

# Median difference and the difference expected when parent
#    and child models hold the same number of taxa
summarise_contrast <- function(data_source, response) {
  res <-
    data_source |>
    dplyr::mutate(y = .data[[response]]) |>
    dplyr::filter(base::is.finite(.data[["y"]])) |>
    tidyr::nest(
      data_group = -dplyr::all_of(c(vec_unit_keys, "transition"))
    ) |>
    dplyr::mutate(
      list_summary = purrr::map(
        .x = .data[["data_group"]],
        .f = function(data_group) {
          mat_coefficients <-
            stats::lm(
              formula = y ~ log_size_ratio,
              data = data_group
            ) |>
            summary() |>
            purrr::chuck("coefficients")

          tibble::tibble(
            n_units = base::nrow(data_group),
            n_parents = dplyr::n_distinct(
              data_group[["scale_id_parent"]]
            ),
            median_size_ratio = stats::median(
              base::exp(data_group[["log_size_ratio"]])
            ),
            median_difference = stats::median(data_group[["y"]]),
            p_wilcoxon = stats::wilcox.test(
              x = data_group[["y"]],
              exact = FALSE
            )[["p.value"]],
            at_equal_size = mat_coefficients[1, 1],
            p_equal_size = mat_coefficients[1, 4],
            slope_size_ratio = mat_coefficients[2, 1],
            p_slope = mat_coefficients[2, 4]
          )
        }
      )
    ) |>
    dplyr::select(-"data_group") |>
    tidyr::unnest(cols = "list_summary") |>
    dplyr::arrange(
      .data[["definition"]],
      .data[["data_source"]],
      .data[["resolution_id"]],
      .data[["transition"]]
    ) |>
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::where(base::is.numeric),
        .fns = ~ base::signif(.x, 2)
      )
    )

  return(res)
}


#----------------------------------------------------------#
# 3. Nested contrasts -----
#----------------------------------------------------------#

data_local <-
  data_taxon_long |>
  dplyr::filter(.data[["scale"]] == "local")

data_regional <-
  data_taxon_long |>
  dplyr::filter(.data[["scale"]] == "regional")

data_continental <-
  data_taxon_long |>
  dplyr::filter(.data[["scale"]] == "continental")

# Shares of every model on all of its taxa
data_model_share <-
  summarise_taxon_set(
    data_source = data_taxon_long,
    vec_group = c(vec_unit_keys, "scale_id")
  ) |>
  dplyr::select(
    dplyr::all_of(c(vec_unit_keys, "scale_id")),
    association_share_all = "association_share",
    climate_balance_all = "climate_balance"
  )

data_contrasts <-
  dplyr::bind_rows(
    build_nested_contrast(
      data_child = data_local,
      data_parent = data_regional,
      vec_by = "region_id",
      transition_name = "1 local to regional"
    ),
    build_nested_contrast(
      data_child = data_regional,
      data_parent = data_continental,
      vec_by = "continent_id",
      transition_name = "2 regional to continental"
    ),
    build_nested_contrast(
      data_child = data_local,
      data_parent = data_continental,
      vec_by = "continent_id",
      transition_name = "3 local to continental"
    )
  ) |>
  dplyr::left_join(
    y = data_model_share,
    by = c(vec_unit_keys, "scale_id")
  ) |>
  dplyr::left_join(
    y = data_model_share |>
      dplyr::rename(scale_id_parent = "scale_id"),
    by = c(vec_unit_keys, "scale_id_parent"),
    suffix = c("_child", "_parent")
  ) |>
  dplyr::mutate(
    association_difference_shared =
      .data[["association_share_parent"]] -
      .data[["association_share_child"]],
    association_difference_all =
      .data[["association_share_all_parent"]] -
      .data[["association_share_all_child"]],
    balance_difference_shared =
      .data[["climate_balance_parent"]] -
      .data[["climate_balance_child"]],
    balance_difference_all =
      .data[["climate_balance_all_parent"]] -
      .data[["climate_balance_all_child"]],
    log_size_ratio = base::log(
      .data[["n_taxa_parent"]] / .data[["n_taxa"]]
    )
  )


#----------------------------------------------------------#
# 4. Outputs -----
#----------------------------------------------------------#

readr::write_csv(
  x = data_contrasts,
  file = base::file.path(
    path_output,
    stringr::str_glue(
      "nested_extent_contrasts_",
      "{base::format(base::Sys.Date(), '%Y-%m-%d')}.csv"
    )
  )
)


#----------------------------------------------------------#
# 5. Summaries -----
#----------------------------------------------------------#

data_contrasts_main <-
  data_contrasts |>
  dplyr::filter(
    .data[["resolution_id"]] %in% c("genus", "family")
  )

base::cat("\n== Association share, shared taxa: parent - child ==\n")
summarise_contrast(
  data_source = data_contrasts_main,
  response = "association_difference_shared"
) |>
  base::print(n = 30)

base::cat("\n== Association share, all taxa: parent - child ==\n")
summarise_contrast(
  data_source = data_contrasts_main,
  response = "association_difference_all"
) |>
  base::print(n = 30)

base::cat("\n== Climate balance, shared taxa: parent - child ==\n")
summarise_contrast(
  data_source = data_contrasts_main,
  response = "balance_difference_shared"
) |>
  base::print(n = 30)

base::cat("\n== Climate balance, all taxa: parent - child ==\n")
summarise_contrast(
  data_source = data_contrasts_main,
  response = "balance_difference_all"
) |>
  base::print(n = 30)
