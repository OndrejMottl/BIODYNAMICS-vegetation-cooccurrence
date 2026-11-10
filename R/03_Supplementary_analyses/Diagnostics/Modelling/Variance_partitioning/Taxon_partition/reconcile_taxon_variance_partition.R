#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     Reconcile per-taxon and model-level partition
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Explains why shares aggregated from per-taxon fractions
#   differ from the published model-level shares.
# The published share splits the seven fractions equally among
#   climate, associations, and space after clamping each at
#   zero on the Nagelkerke scale.
# Nagelkerke R2 of a fraction is 1 - exp(-deviance / n_samples)
#   with the deviance summed over taxa, so only the deviance
#   is additive across taxa and across fractions.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

base::source(
  here::here("R/___setup_project___.R")
)

base::options(width = 200, pillar.sigfig = 3)

path_output <-
  here::here("Outputs/Tables/Diagnostics/Taxon_variance_partition")

path_unit_tables <-
  here::here("Outputs/Tables/Visualisation")

vec_fractions <-
  c("F_A", "F_B", "F_S", "F_AB", "F_AS", "F_BS", "F_ABS")

vec_model_keys <-
  c(
    "data_source", "scale", "scale_id", "continent_id",
    "resolution_id", "age", "n_taxa", "n_samples"
  )

vec_definitions <-
  c(
    "published", "deviance_clamped", "deviance_additive",
    "deviance_taxon_floor", "unique_taxon_floor"
  )


#----------------------------------------------------------#
# 1. Helpers -----
#----------------------------------------------------------#

# The newest file matching a pattern in a directory
resolve_newest_file <- function(path_directory, file_pattern) {
  res <-
    base::list.files(
      path = path_directory,
      pattern = file_pattern,
      full.names = TRUE
    ) |>
    base::sort() |>
    utils::tail(n = 1)

  return(res)
}

# Equal split of shared fractions among their components, the
#    rule of the pipeline's Shapley allocation step
allocate_equal_split <- function(data_wide) {
  res <-
    data_wide |>
    dplyr::mutate(
      climate = .data[["F_A"]] + .data[["F_AB"]] / 2 +
        .data[["F_AS"]] / 2 + .data[["F_ABS"]] / 3,
      associations = .data[["F_B"]] + .data[["F_AB"]] / 2 +
        .data[["F_BS"]] / 2 + .data[["F_ABS"]] / 3,
      space = .data[["F_S"]] + .data[["F_AS"]] / 2 +
        .data[["F_BS"]] / 2 + .data[["F_ABS"]] / 3
    ) |>
    dplyr::select(-dplyr::all_of(vec_fractions))

  return(res)
}

# R2 and slope of a share on log taxon number
summarise_size_dependence <- function(data_source, response) {
  data_model <-
    data_source |>
    dplyr::mutate(y = .data[[response]]) |>
    dplyr::filter(base::is.finite(.data[["y"]]))

  mod_size <-
    stats::lm(
      formula = y ~ log_n_taxa,
      data = data_model
    )

  res <-
    tibble::tibble(
      response = response,
      n_models = base::nrow(data_model),
      r2_log_taxa = summary(mod_size)[["r.squared"]],
      slope_log_taxa = stats::coef(mod_size)[["log_n_taxa"]]
    )

  return(res)
}


#----------------------------------------------------------#
# 2. Inputs -----
#----------------------------------------------------------#

data_model_raw <-
  resolve_newest_file(
    path_directory = path_output,
    file_pattern = "^model_variance_partition_.*[.]csv$"
  ) |>
  readr::read_csv(show_col_types = FALSE)

data_taxon_deviance <-
  resolve_newest_file(
    path_directory = path_output,
    file_pattern = "^taxon_variance_partition_.*[.]csv$"
  ) |>
  readr::read_csv(show_col_types = FALSE)

data_published <-
  c("paleo", "modern") |>
  purrr::map(
    .f = function(data_source_name) {
      resolve_newest_file(
        path_directory = path_unit_tables,
        file_pattern = stringr::str_glue(
          "^{data_source_name}_variance_partitioning_unit_.*[.]csv$"
        )
      ) |>
        readr::read_csv(show_col_types = FALSE) |>
        dplyr::filter(
          .data[["data_source"]] == data_source_name,
          .data[["component"]] == "Associations"
        )
    }
  ) |>
  purrr::list_rbind() |>
  dplyr::select(
    "data_source", "scale_id", "resolution_id",
    share_published = "R2_Nagelkerke_percentage"
  )


#----------------------------------------------------------#
# 3. Identity check -----
#----------------------------------------------------------#

# Taxon deviances must sum to the model deviance, and that
#    sum must give the model Nagelkerke R2
base::cat("\n== Identity: per-taxon values rebuild the model ==\n")
data_taxon_deviance |>
  dplyr::group_by(
    dplyr::across(dplyr::all_of(c(vec_model_keys, "fraction")))
  ) |>
  dplyr::summarise(
    deviance_from_taxa = base::sum(.data[["deviance"]]),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    nagelkerke_from_taxa = 1 - base::exp(
      -.data[["deviance_from_taxa"]] / .data[["n_samples"]]
    )
  ) |>
  dplyr::inner_join(
    y = data_model_raw,
    by = c(vec_model_keys, "fraction")
  ) |>
  # A fraction can be so negative that its R2 overflows
  dplyr::filter(base::is.finite(.data[["r2_nagelkerke"]])) |>
  dplyr::summarise(
    n_rows = dplyr::n(),
    max_deviance_error = base::max(
      base::abs(.data[["deviance_from_taxa"]] - .data[["deviance"]]) /
        base::pmax(base::abs(.data[["deviance"]]), 1)
    ),
    max_nagelkerke_error = base::max(
      base::abs(
        .data[["nagelkerke_from_taxa"]] - .data[["r2_nagelkerke"]]
      ) / base::pmax(base::abs(.data[["r2_nagelkerke"]]), 1)
    )
  ) |>
  base::print()


#----------------------------------------------------------#
# 4. Allocations under each definition -----
#----------------------------------------------------------#

data_model_fractions <-
  data_model_raw |>
  dplyr::filter(.data[["fraction"]] %in% vec_fractions)

# 4.1 Published: clamp each Nagelkerke fraction, equal split
data_published_rebuilt <-
  data_model_fractions |>
  dplyr::mutate(
    value = base::pmax(.data[["r2_nagelkerke"]], 0)
  ) |>
  dplyr::select(
    dplyr::all_of(c(vec_model_keys, "fraction", "value"))
  ) |>
  tidyr::pivot_wider(
    names_from = "fraction",
    values_from = "value"
  ) |>
  allocate_equal_split() |>
  dplyr::mutate(definition = "published")

# 4.2 Same rule on the additive deviance scale
data_deviance_clamped <-
  data_model_fractions |>
  dplyr::mutate(
    value = base::pmax(.data[["deviance"]], 0)
  ) |>
  dplyr::select(
    dplyr::all_of(c(vec_model_keys, "fraction", "value"))
  ) |>
  tidyr::pivot_wider(
    names_from = "fraction",
    values_from = "value"
  ) |>
  allocate_equal_split() |>
  dplyr::mutate(definition = "deviance_clamped")

# 4.3 Deviance without clamping: the three allocations sum
#    exactly to the deviance explained by the full model
data_deviance_additive <-
  data_model_fractions |>
  dplyr::select(
    dplyr::all_of(c(vec_model_keys, "fraction")),
    value = "deviance"
  ) |>
  tidyr::pivot_wider(
    names_from = "fraction",
    values_from = "value"
  ) |>
  allocate_equal_split() |>
  dplyr::mutate(definition = "deviance_additive")

# 4.4 Reconciled per-taxon allocation: a fraction that is
#    negative for the whole model is dropped for every taxon,
#    so taxa sum exactly to the clamped model allocation
data_fraction_kept <-
  data_model_fractions |>
  dplyr::mutate(flag_kept = .data[["deviance"]] > 0) |>
  dplyr::select(
    dplyr::all_of(c(vec_model_keys, "fraction", "flag_kept"))
  )

data_taxon_reconciled <-
  data_taxon_deviance |>
  dplyr::filter(.data[["fraction"]] %in% vec_fractions) |>
  dplyr::inner_join(
    y = data_fraction_kept,
    by = c(vec_model_keys, "fraction")
  ) |>
  dplyr::mutate(
    value = dplyr::if_else(
      condition = .data[["flag_kept"]],
      true = .data[["deviance"]],
      false = 0
    )
  ) |>
  dplyr::select(
    dplyr::all_of(c(vec_model_keys, "taxon", "fraction", "value"))
  ) |>
  tidyr::pivot_wider(
    names_from = "fraction",
    values_from = "value"
  ) |>
  allocate_equal_split() |>
  dplyr::left_join(
    y = data_taxon_deviance |>
      dplyr::filter(
        .data[["fraction"]] %in% c("F_A", "F_B", "F_S", "Full")
      ) |>
      dplyr::select(
        dplyr::all_of(c(vec_model_keys, "taxon", "fraction")),
        "deviance"
      ) |>
      tidyr::pivot_wider(
        names_from = "fraction",
        values_from = "deviance"
      ) |>
      dplyr::rename(
        climate_unique = "F_A",
        associations_unique = "F_B",
        space_unique = "F_S",
        deviance_full = "Full"
      ),
    by = c(vec_model_keys, "taxon")
  )

# 4.5 Per-taxon allocation without any model-level clamp,
#    floored for every taxon
data_taxon_allocation <-
  data_taxon_deviance |>
  dplyr::filter(.data[["fraction"]] %in% vec_fractions) |>
  dplyr::select(
    dplyr::all_of(c(vec_model_keys, "taxon", "fraction")),
    value = "deviance"
  ) |>
  tidyr::pivot_wider(
    names_from = "fraction",
    values_from = "value"
  ) |>
  allocate_equal_split()

data_deviance_taxon_floor <-
  data_taxon_allocation |>
  dplyr::group_by(
    dplyr::across(dplyr::all_of(vec_model_keys))
  ) |>
  dplyr::summarise(
    dplyr::across(
      .cols = c("climate", "associations", "space"),
      .fns = ~ base::sum(base::pmax(.x, 0))
    ),
    .groups = "drop"
  ) |>
  dplyr::mutate(definition = "deviance_taxon_floor")

# 4.6 Earlier exploration: unique Nagelkerke fractions only,
#    floored for every taxon and summed
data_unique_taxon_floor <-
  data_taxon_deviance |>
  dplyr::filter(.data[["fraction"]] %in% c("F_A", "F_B", "F_S")) |>
  dplyr::group_by(
    dplyr::across(dplyr::all_of(c(vec_model_keys, "fraction")))
  ) |>
  dplyr::summarise(
    value = base::sum(base::pmax(.data[["r2_nagelkerke"]], 0)),
    .groups = "drop"
  ) |>
  tidyr::pivot_wider(
    names_from = "fraction",
    values_from = "value"
  ) |>
  dplyr::rename(
    climate = "F_A",
    associations = "F_B",
    space = "F_S"
  ) |>
  dplyr::mutate(definition = "unique_taxon_floor")

data_shares <-
  dplyr::bind_rows(
    data_published_rebuilt,
    data_deviance_clamped,
    data_deviance_additive,
    data_deviance_taxon_floor,
    data_unique_taxon_floor
  ) |>
  dplyr::mutate(
    definition = base::factor(
      x = .data[["definition"]],
      levels = vec_definitions
    ),
    # A negative allocation is possible without clamping
    dplyr::across(
      .cols = c("climate", "associations", "space"),
      .fns = ~ base::pmax(.x, 0),
      .names = "{.col}_floor"
    ),
    association_share = .data[["associations_floor"]] /
      (
        .data[["climate_floor"]] + .data[["associations_floor"]] +
          .data[["space_floor"]]
      ),
    climate_balance = .data[["climate_floor"]] /
      (.data[["climate_floor"]] + .data[["space_floor"]]),
    log_n_taxa = base::log(.data[["n_taxa"]])
  )

data_full_model <-
  data_model_raw |>
  dplyr::filter(.data[["fraction"]] == "Full") |>
  dplyr::select(
    dplyr::all_of(vec_model_keys),
    nagelkerke_full = "r2_nagelkerke",
    mcfadden_full = "r2_mcfadden"
  )


#----------------------------------------------------------#
# 5. Outputs -----
#----------------------------------------------------------#

readr::write_csv(
  x = data_shares |>
    dplyr::left_join(
      y = data_full_model,
      by = vec_model_keys
    ),
  file = base::file.path(
    path_output,
    stringr::str_glue(
      "model_share_definitions_",
      "{base::format(base::Sys.Date(), '%Y-%m-%d')}.csv"
    )
  )
)

readr::write_csv(
  x = data_taxon_reconciled,
  file = base::file.path(
    path_output,
    stringr::str_glue(
      "taxon_allocation_reconciled_",
      "{base::format(base::Sys.Date(), '%Y-%m-%d')}.csv"
    )
  )
)


#----------------------------------------------------------#
# 6. Checks and summaries -----
#----------------------------------------------------------#

base::cat("\n== Reconciled taxon allocation sums to the model ==\n")
data_taxon_reconciled |>
  dplyr::group_by(
    dplyr::across(dplyr::all_of(vec_model_keys))
  ) |>
  dplyr::summarise(
    dplyr::across(
      .cols = c("climate", "associations", "space"),
      .fns = base::sum,
      .names = "{.col}_from_taxa"
    ),
    .groups = "drop"
  ) |>
  dplyr::inner_join(
    y = data_deviance_clamped,
    by = vec_model_keys
  ) |>
  dplyr::summarise(
    n_models = dplyr::n(),
    max_relative_error = base::max(
      base::abs(
        c(
          .data[["climate_from_taxa"]] - .data[["climate"]],
          .data[["associations_from_taxa"]] -
            .data[["associations"]],
          .data[["space_from_taxa"]] - .data[["space"]]
        )
      ) /
        base::pmax(
          c(
            .data[["climate"]],
            .data[["associations"]],
            .data[["space"]]
          ),
          1
        )
    )
  ) |>
  base::print()

base::cat("\n== Fractions negative for the whole model ==\n")
data_fraction_kept |>
  dplyr::group_by(
    .data[["data_source"]],
    .data[["fraction"]]
  ) |>
  dplyr::summarise(
    share_models_negative = base::mean(!.data[["flag_kept"]]),
    .groups = "drop"
  ) |>
  tidyr::pivot_wider(
    names_from = "fraction",
    values_from = "share_models_negative"
  ) |>
  base::print()

base::cat("\n== Rebuilt published share against the unit tables ==\n")
data_shares |>
  dplyr::filter(.data[["definition"]] == "published") |>
  dplyr::inner_join(
    y = data_published,
    by = c("data_source", "scale_id", "resolution_id")
  ) |>
  dplyr::summarise(
    n_models = dplyr::n(),
    max_difference_percent = base::max(
      base::abs(
        100 * .data[["association_share"]] -
          .data[["share_published"]]
      ),
      na.rm = TRUE
    )
  ) |>
  base::print()

base::cat("\n== Agreement with the published share (Spearman) ==\n")
data_shares |>
  dplyr::select(
    dplyr::all_of(c(vec_model_keys, "definition")),
    "association_share"
  ) |>
  tidyr::pivot_wider(
    names_from = "definition",
    values_from = "association_share"
  ) |>
  dplyr::group_by(.data[["data_source"]]) |>
  dplyr::summarise(
    dplyr::across(
      .cols = dplyr::all_of(vec_definitions[-1]),
      .fns = ~ stats::cor(
        x = .x,
        y = .data[["published"]],
        method = "spearman",
        use = "complete.obs"
      )
    )
  ) |>
  base::print()

base::cat("\n== Median association share by definition ==\n")
data_shares |>
  dplyr::filter(
    .data[["resolution_id"]] %in% c("genus", "family")
  ) |>
  dplyr::group_by(
    .data[["data_source"]],
    .data[["resolution_id"]],
    .data[["scale"]],
    .data[["definition"]]
  ) |>
  dplyr::summarise(
    n_models = dplyr::n(),
    median_taxa = stats::median(.data[["n_taxa"]]),
    share = stats::median(.data[["association_share"]], na.rm = TRUE),
    .groups = "drop"
  ) |>
  tidyr::pivot_wider(
    names_from = "definition",
    values_from = "share"
  ) |>
  dplyr::mutate(
    scale = base::factor(
      x = .data[["scale"]],
      levels = c("local", "regional", "continental", "temporal")
    )
  ) |>
  dplyr::arrange(
    .data[["data_source"]],
    .data[["resolution_id"]],
    .data[["scale"]]
  ) |>
  base::print(n = 40)

base::cat("\n== Median climate balance by definition (genus) ==\n")
data_shares |>
  dplyr::filter(.data[["resolution_id"]] == "genus") |>
  dplyr::group_by(
    .data[["data_source"]],
    .data[["scale"]],
    .data[["definition"]]
  ) |>
  dplyr::summarise(
    balance = stats::median(.data[["climate_balance"]], na.rm = TRUE),
    .groups = "drop"
  ) |>
  tidyr::pivot_wider(
    names_from = "definition",
    values_from = "balance"
  ) |>
  base::print(n = 40)

base::cat("\n== Full-model R2 by tier (genus) ==\n")
data_full_model |>
  dplyr::filter(.data[["resolution_id"]] == "genus") |>
  dplyr::group_by(
    .data[["data_source"]],
    .data[["scale"]]
  ) |>
  dplyr::summarise(
    n_models = dplyr::n(),
    median_taxa = stats::median(.data[["n_taxa"]]),
    nagelkerke_full = stats::median(.data[["nagelkerke_full"]]),
    mcfadden_full = stats::median(.data[["mcfadden_full"]]),
    .groups = "drop"
  ) |>
  base::print(n = 40)

base::cat("\n== Sum of the three published allocations ==\n")
data_shares |>
  dplyr::filter(
    .data[["definition"]] == "published",
    .data[["resolution_id"]] == "genus"
  ) |>
  dplyr::mutate(
    allocation_total = .data[["climate"]] +
      .data[["associations"]] + .data[["space"]]
  ) |>
  dplyr::group_by(
    .data[["data_source"]],
    .data[["scale"]]
  ) |>
  dplyr::summarise(
    median_total = stats::median(.data[["allocation_total"]]),
    share_above_one = base::mean(.data[["allocation_total"]] > 1),
    .groups = "drop"
  ) |>
  base::print()

base::cat("\n== Full-model R2 against taxon number (Spearman) ==\n")
data_full_model |>
  dplyr::filter(.data[["scale"]] != "temporal") |>
  dplyr::group_by(.data[["data_source"]]) |>
  dplyr::summarise(
    rho_nagelkerke = stats::cor(
      x = .data[["n_taxa"]],
      y = .data[["nagelkerke_full"]],
      method = "spearman"
    ),
    rho_mcfadden = stats::cor(
      x = .data[["n_taxa"]],
      y = .data[["mcfadden_full"]],
      method = "spearman"
    )
  ) |>
  base::print()

base::cat("\n== Share against log taxon number (spatial models) ==\n")
data_shares |>
  dplyr::filter(.data[["scale"]] != "temporal") |>
  tidyr::nest(
    data_group = -c("data_source", "definition")
  ) |>
  dplyr::mutate(
    list_summary = purrr::map(
      .x = .data[["data_group"]],
      .f = function(data_group) {
        dplyr::bind_rows(
          summarise_size_dependence(
            data_source = data_group,
            response = "association_share"
          ),
          summarise_size_dependence(
            data_source = data_group,
            response = "climate_balance"
          )
        )
      }
    )
  ) |>
  dplyr::select(-"data_group") |>
  tidyr::unnest(cols = "list_summary") |>
  dplyr::arrange(
    .data[["response"]],
    .data[["data_source"]],
    .data[["definition"]]
  ) |>
  base::print(n = 40)

base::cat("\n== Negative values before flooring ==\n")
dplyr::bind_rows(
  data_taxon_allocation |>
    dplyr::mutate(level = "taxon allocation (equal split)"),
  data_taxon_deviance |>
    dplyr::filter(.data[["fraction"]] %in% c("F_A", "F_B", "F_S")) |>
    dplyr::select(
      dplyr::all_of(c(vec_model_keys, "taxon", "fraction")),
      "deviance"
    ) |>
    tidyr::pivot_wider(
      names_from = "fraction",
      values_from = "deviance"
    ) |>
    dplyr::rename(
      climate = "F_A",
      associations = "F_B",
      space = "F_S"
    ) |>
    dplyr::mutate(level = "taxon unique fraction"),
  data_deviance_additive |>
    dplyr::mutate(level = "model allocation (equal split)")
) |>
  dplyr::group_by(
    .data[["level"]],
    .data[["data_source"]]
  ) |>
  dplyr::summarise(
    n_rows = dplyr::n(),
    dplyr::across(
      .cols = c("climate", "associations", "space"),
      .fns = ~ base::mean(.x < 0)
    ),
    .groups = "drop"
  ) |>
  base::print()
