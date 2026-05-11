#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#   Age uncertainty - compare consensus vs. uncertainty-aware
#         Age_uncertainty_exploration_2026-05-04.R
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Compares the current consensus-age interpolation to the
# uncertainty-aware approach (median over age-model iterations)
# for the Czech project (project_paleo_core_cz).
#
# Two-part comparison:
#   Part A - single selected core: spaghetti plot + scatter
#   Part B - all Czech cores: distribution of absolute differences


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  verbose = FALSE
)

# Set Czech project config BEFORE sourcing setup so that
# get_active_config() resolves the correct values.
Sys.setenv(R_CONFIG_ACTIVE = "project_paleo_core_cz")

suppressMessages(
  suppressWarnings(
    source(here::here("R/___setup_project___.R"))
  )
)

graphical_options <-
  get_active_config("graphical")

# Printing a ggplot that contains ggview::canvas() calls rstudioapi and
# errors outside RStudio. Wrap every plot print with this helper so the
# script also runs cleanly via Rscript.
print_safe <- function(p) {
  try(base::print(p), silent = TRUE)
}

path_vegvault <- here::here("Data/Input/VegVault.sqlite")

# Number of age-model iterations to use in the all-Czech aggregate
# comparison (reduces runtime; set to Inf to use all iterations).
n_iter_use <- 100L


#----------------------------------------------------------#
# 1. Read project configuration -----
#----------------------------------------------------------#

x_lim <-
  get_active_config(c("vegvault_data", "x_lim"))

y_lim <-
  get_active_config(c("vegvault_data", "y_lim"))

age_lim <-
  get_active_config(c("vegvault_data", "age_lim"))

timestep <-
  get_active_config(c("data_processing", "time_step"))

age_min <- base::min(age_lim)
age_max <- base::max(age_lim)


#----------------------------------------------------------#
# 2. Build VegVault plan for fossil cores only -----
#----------------------------------------------------------#
# Only fossil_pollen_archive datasets have age-depth models and
# therefore age uncertainty. The plan is intentionally limited to
# this type so that get_age_uncertainty() has a valid scope.

plan_cores <-
  vaultkeepr::open_vault(path = path_vegvault) |>
  vaultkeepr::get_datasets() |>
  vaultkeepr::select_dataset_by_type(
    sel_dataset_type = "fossil_pollen_archive"
  ) |>
  vaultkeepr::select_dataset_by_geo(
    long_lim = x_lim,
    lat_lim = y_lim,
    verbose = FALSE
  ) |>
  vaultkeepr::get_samples() |>
  vaultkeepr::select_samples_by_age(
    age_lim = age_lim,
    verbose = FALSE
  )


#----------------------------------------------------------#
# 3. Retrieve age uncertainty -----
#----------------------------------------------------------#
# get_age_uncertainty() is a companion call on the plan — it is NOT
# a pipe step and cannot be chained with |>.

data_age_unc_wide <-
  vaultkeepr::get_age_uncertainty(con = plan_cores)

n_samples_with_unc <-
  nrow(data_age_unc_wide)
n_iterations <-
  ncol(data_age_unc_wide) - 1L # subtract sample_name column



# Pivot to long format — one row per (sample_name, iteration)
data_age_unc_long <-
  data_age_unc_wide |>
  tidyr::pivot_longer(
    cols = -sample_name,
    names_to = "iteration",
    names_prefix = "iteration_",
    values_to = "age_uncertainty"
  ) |>
  dplyr::mutate(
    iteration = base::as.integer(iteration)
  )


#----------------------------------------------------------#
# 4. Extract & process community data -----
#----------------------------------------------------------#
# Reuse the existing project helper so the debug script receives the
# same structured object as the actual pipeline.

data_vegvault_extracted <-
  build_vegvault_plan(
    path_to_vegvault = path_vegvault,
    x_lim = x_lim,
    y_lim = y_lim,
    age_lim = age_lim,
    sel_dataset_type = c("fossil_pollen_archive", "gridpoints")
  ) |>
  extract_data_from_vegvault(
    sel_abiotic_var_name = c("bio1")
  )

data_community <-
  get_community_data(data_vegvault_extracted)

data_community_long <-
  make_community_data_long(data_community)

data_sample_ages <-
  get_sample_ages(data_vegvault_extracted)

data_community_long_ages <-
  add_age_to_samples(
    data_community = data_community_long,
    data_ages = data_sample_ages
  )

data_community_proportions <-
  make_community_proportions(data = data_community_long_ages)

n_datasets <-
  dplyr::n_distinct(
    dplyr::pull(data_community_proportions, dataset_name)
  )

n_taxa <-
  dplyr::n_distinct(
    dplyr::pull(data_community_proportions, taxon)
  )


#----------------------------------------------------------#
# 5. Link age uncertainty to community data -----
#----------------------------------------------------------#

# Add dataset_name to the age uncertainty via the sample_ages lookup.
# sample_name is expected to be unique across datasets in VegVault
# (FOSSILPOL sample names carry the site identifier). A warning is
# raised if this assumption is violated.
data_age_unc_long_with_dataset <-
  data_age_unc_long |>
  dplyr::inner_join(
    data_sample_ages |>
      dplyr::select("dataset_name", "sample_name") |>
      dplyr::distinct(),
    by = "sample_name"
  )

n_rows_expected <- nrow(data_age_unc_long)
n_rows_actual <- nrow(data_age_unc_long_with_dataset)

if (
  n_rows_actual != n_rows_expected
) {
  cli::cli_warn(
    c(
      "!" = "sample_name appears non-unique across datasets.",
      "i" = "Expected ~{n_rows_expected} rows after join; got {n_rows_actual}.",
      "i" = "Results may be incorrect."
    )
  )
}

n_samples_matched <-
  data_age_unc_long_with_dataset |>
  dplyr::pull(sample_name) |>
  dplyr::n_distinct()

n_samples_total <-
  data_community_proportions |>
  dplyr::pull(sample_name) |>
  dplyr::n_distinct()

base::cat(
  stringr::str_glue(
    "Samples matched to age uncertainty: {n_samples_matched} / {n_samples_total}\n\n"
  )
)

# Build per-iteration community data frame:
# replace consensus age with the iteration-specific age estimate,
# and add the iteration column so interpolate_data() can nest by it.
data_community_iter <-
  data_community_proportions |>
  dplyr::select("dataset_name", "sample_name", "taxon", "pollen_prop") |>
  dplyr::inner_join(
    data_age_unc_long_with_dataset,
    by = c("dataset_name", "sample_name"),
    relationship = "many-to-many"
  ) |>
  dplyr::rename(age = age_uncertainty) |>
  dplyr::filter(!is.na(age))


#----------------------------------------------------------#
# 6. Select representative core & taxon -----
#----------------------------------------------------------#

# Core with the most samples — most data for a clean spaghetti.
sel_dataset_name <-
  data_community_proportions |>
  dplyr::filter(
    dataset_name %in% dplyr::pull(
      dplyr::distinct(data_age_unc_long_with_dataset, dataset_name)
    )
  ) |>
  dplyr::summarise(
    n_samples = dplyr::n_distinct(sample_name),
    .by = dataset_name
  ) |>
  dplyr::slice_max(n_samples, n = 1, with_ties = FALSE) |>
  dplyr::pull(dataset_name)

# Most abundant taxon in that core (by mean proportion).
sel_taxon <-
  data_community_proportions |>
  dplyr::filter(dataset_name == sel_dataset_name) |>
  dplyr::summarise(
    mean_prop = base::mean(pollen_prop, na.rm = TRUE),
    .by = taxon
  ) |>
  dplyr::slice_max(mean_prop, n = 1, with_ties = FALSE) |>
  dplyr::pull(taxon)


#----------------------------------------------------------#
# 7. Current approach (consensus ages) -----
#----------------------------------------------------------#

data_current_raw <-
  data_community_proportions |>
  dplyr::filter(
    dataset_name == sel_dataset_name,
    taxon == sel_taxon
  )

data_current <-
  interpolate_community_data(
    data = data_community_proportions,
    timestep = timestep,
    age_min = age_min,
    age_max = age_max
  )

# Current (consensus) for the same core/taxon.
data_current_single <-
  data_current |>
  dplyr::filter(
    dataset_name == sel_dataset_name,
    taxon == sel_taxon
  )

data_current_age_error <-
  data_age_unc_long |>
  dplyr::group_by(sample_name) |>
  dplyr::summarise(
    age_lwr = stats::quantile(age_uncertainty, 0.025, na.rm = TRUE),
    age_upr = stats::quantile(age_uncertainty, 0.975, na.rm = TRUE)
  )

data_current_raw_with_age_error <-
  data_current_raw |>
  dplyr::inner_join(
    data_current_age_error,
    by = "sample_name"
  )

#----------------------------------------------------------#
# 8. Part A — Single-core spaghetti analysis -----
#----------------------------------------------------------#


#--------------------------------------------------#
## 8.1. Per-iteration interpolation (single core, all iterations) -----
#--------------------------------------------------#

data_iter_single <-
  data_community_iter |>
  dplyr::filter(
    dataset_name == sel_dataset_name,
    taxon == sel_taxon
  ) |>
  interpolate_data(
    by = c("dataset_name", "taxon", "iteration"),
    timestep = timestep,
    age_min = age_min,
    age_max = age_max
  )

# Median across iterations at each grid point.
data_new_single <-
  data_iter_single |>
  dplyr::summarise(
    pollen_prop = stats::median(pollen_prop, na.rm = TRUE),
    .by = c(dataset_name, taxon, age)
  )


#--------------------------------------------------#
## 8.2. Spaghetti plot -----
#--------------------------------------------------#

plot_spaghetti <-
  data_iter_single |>
  dplyr::filter(!is.na(pollen_prop)) |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(x = age, y = pollen_prop)
  ) +
  ggplot2::scale_x_continuous(
    trans = "reverse",
    name = "Age (cal yr BP)"
  ) +
  ggplot2::scale_y_continuous(
    name = "Pollen proportion"
  ) +
  ggplot2::labs(
    title = "Age uncertainty spaghetti",
    subtitle = stringr::str_glue(
      "{sel_taxon} at {sel_dataset_name}"
    ),
    caption = stringr::str_glue(
      "red dashed = current (consensus)\n",
      "blue solid = new (median of iterations)\n",
      "{n_iterations} age-model iterations",
    )
  ) +
  ggplot2::theme_classic() +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]]
  ) +
  ggplot2::geom_vline(
    xintercept = data_current_single$age,
    colour = "grey70",
    linetype = "dashed",
    alpha = 0.5
  ) +
  ggplot2::geom_line(
    mapping = ggplot2::aes(group = iteration),
    colour = "#2166ac",
    alpha = 0.05,
    linewidth = 0.3
  ) +
  ggplot2::geom_linerange(
    data = data_current_raw_with_age_error,
    mapping = ggplot2::aes(
      x = age,
      y = pollen_prop,
      xmin = age_lwr,
      xmax = age_upr
    ),
    orientation = "y",
    colour = "grey50"
  ) +
  ggplot2::geom_point(
    data = data_current_raw,
    color = "grey50",
    size = 1
  ) +
  ggplot2::geom_line(
    data = data_current_single,
    colour = "#d73027",
    linewidth = 1.2,
    linetype = "dashed"
  ) +
  ggplot2::geom_point(
    data = data_current_single,
    colour = "#d73027",
    size = 2
  ) +
  ggplot2::geom_line(
    data = data_new_single,
    colour = "#0b325a",
    linewidth = 1.2
  )

print_safe(plot_spaghetti)

ggview::save_ggplot(
  plot = plot_spaghetti,
  file = here::here(
    "Outputs/Figures/Supplementary/",
    "interpolation_uncertainty_comparison_single_taxon.png"
  )
)

#--------------------------------------------------#
## 8.3. New approach for all taxa in the selected core -----
#--------------------------------------------------#

data_iter_core_all_taxa <-
  data_community_iter |>
  dplyr::filter(dataset_name == sel_dataset_name) |>
  interpolate_data(
    by = c("dataset_name", "taxon", "iteration"),
    timestep = timestep,
    age_min = age_min,
    age_max = age_max
  ) |>
  dplyr::summarise(
    pollen_prop_new = stats::median(pollen_prop, na.rm = TRUE),
    .by = c(dataset_name, taxon, age)
  )

data_comparison_core <-
  data_current |>
  dplyr::filter(dataset_name == sel_dataset_name) |>
  dplyr::rename(pollen_prop_current = pollen_prop) |>
  dplyr::inner_join(
    data_iter_core_all_taxa,
    by = c("dataset_name", "taxon", "age")
  ) |>
  dplyr::filter(
    !is.na(pollen_prop_current),
    !is.na(pollen_prop_new)
  ) |>
  dplyr::mutate(
    pollen_prop_current_perc = pollen_prop_current * 100,
    pollen_prop_new_perc = pollen_prop_new * 100
  )


#--------------------------------------------------#
## 8.4. Comparison scatter (single core, all taxa) -----
#--------------------------------------------------#

max_prop_val <-
  base::max(
    base::max(
      dplyr::pull(data_comparison_core, pollen_prop_new_perc),
      na.rm = TRUE
    ),
    base::max(
      dplyr::pull(data_comparison_core, pollen_prop_current_perc),
      na.rm = TRUE
    )
  )

plot_comparison_core <-
  data_comparison_core |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(
      x = pollen_prop_current_perc,
      y = pollen_prop_new_perc,
      colour = age
    )
  ) +
  ggplot2::scale_x_continuous(
    name = "Current approach (consensus age)\nPollen proportion (%)",
    limits = c(0, max_prop_val)
  ) +
  ggplot2::scale_y_continuous(
    name = "New approach (median of iterations)\nPollen proportion (%)",
    limits = c(0, max_prop_val)
  ) +
  ggplot2::scale_colour_viridis_c(
    name = "Age (yr BP)",
    option = "plasma"
  ) +
  ggplot2::labs(
    title = stringr::str_glue(
      "Current vs. uncertainty-median: {sel_dataset_name}"
    ),
    subtitle = stringr::str_glue(
      "All taxa at all ages | ",
      "points near the 1:1 diagonal = approaches agree"
    )
  ) +
  ggplot2::theme_classic() +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]]
  ) +
  ggplot2::geom_abline(
    slope = 1,
    intercept = 0,
    colour = "grey40",
    linetype = "dashed"
  ) +
  ggplot2::geom_point(alpha = 0.6, size = 1.5)

print_safe(plot_comparison_core)

ggview::save_ggplot(
  plot = plot_comparison_core,
  file = here::here(
    "Outputs/Figures/Supplementary/",
    "interpolation_uncertainty_comparison_all_taxa.png"
  )
)

#----------------------------------------------------------#
# 9. Part B — All-Czech aggregate analysis -----
#----------------------------------------------------------#


#--------------------------------------------------#
## 9.1. Limit iterations for speed -----
#--------------------------------------------------#

n_iter_actual <-
  base::min(n_iter_use, n_iterations)

set.seed(get_active_config("seed"))
vec_random_iterations <-
  base::sample(
    x = seq_len(n_iterations),
    size = n_iter_actual,
    replace = FALSE
  )

data_community_iter_limited <-
  data_community_iter |>
  dplyr::filter(iteration %in% vec_random_iterations)



#--------------------------------------------------#
## 9.2. Per-iteration interpolation (all cores) -----
#--------------------------------------------------#

data_iter_all <-
  data_community_iter_limited |>
  interpolate_data(
    by = c("dataset_name", "taxon", "iteration"),
    timestep = timestep,
    age_min = age_min,
    age_max = age_max
  )

data_new_all <-
  data_iter_all |>
  dplyr::summarise(
    pollen_prop_new = stats::median(pollen_prop, na.rm = TRUE),
    .by = c(dataset_name, taxon, age)
  )


#--------------------------------------------------#
## 9.3. Compute absolute differences -----
#--------------------------------------------------#

data_comparison_all <-
  data_current |>
  dplyr::rename(pollen_prop_current = pollen_prop) |>
  dplyr::inner_join(
    data_new_all,
    by = c("dataset_name", "taxon", "age")
  ) |>
  dplyr::filter(
    !is.na(pollen_prop_current),
    !is.na(pollen_prop_new)
  ) |>
  dplyr::mutate(
    pollen_prop_current_perc = pollen_prop_current * 100,
    pollen_prop_new_perc = pollen_prop_new * 100
  ) |>
  dplyr::mutate(
    abs_diff_perc = base::abs(pollen_prop_new_perc - pollen_prop_current_perc)
  )

# Summary statistics printed to console.
summary_stats <-
  data_comparison_all |>
  dplyr::summarise(
    n = dplyr::n(),
    mean_diff = base::mean(abs_diff_perc, na.rm = TRUE),
    median_diff = stats::median(abs_diff_perc, na.rm = TRUE),
    pct90_diff = stats::quantile(abs_diff_perc, 0.9, na.rm = TRUE),
    max_diff = base::max(abs_diff_perc, na.rm = TRUE)
  )

summary_stats


#--------------------------------------------------#
## 9.4. Distribution of differences -----
#--------------------------------------------------#

plot_diff_dist <-
  data_comparison_all |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(x = abs_diff_perc)
  ) +
  ggplot2::scale_x_continuous(
    name = "Pollen proportion difference (%)\n|New \u2212 Current|"
  ) +
  ggplot2::scale_y_continuous(
    name = "Density (proportion of points)",
    trans = "log1p"
  ) +
  ggplot2::labs(
    title = "Distribution of differences: uncertainty-median vs. consensus approach",
    subtitle = stringr::str_glue(
      "Czech project | {n_datasets} cores | {n_iter_actual} of {n_iterations} iterations"
    )
  ) +
  ggplot2::theme_classic() +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]]
  ) +
  ggplot2::geom_histogram(
    mapping = ggplot2::aes(y = ggplot2::after_stat(density)),
    binwidth = 1,
    fill = "#4393c3",
    colour = "white",
  ) +
  ggplot2::geom_density(
    colour = "#2166ac",
    linewidth = 0.5
  )

print_safe(plot_diff_dist)

ggview::save_ggplot(
  plot = plot_diff_dist,
  file = here::here(
    "Outputs/Figures/Supplementary/",
    "interpolation_uncertainty_comparison_histogram.png"
  )
)

#--------------------------------------------------#
## 9.5. Difference by age -----
#--------------------------------------------------#

plot_diff_by_age <-
  data_comparison_all |>
  dplyr::summarise(
    mean_diff = base::mean(abs_diff_perc, na.rm = TRUE),
    median_diff = stats::median(abs_diff_perc, na.rm = TRUE),
    pct90_diff = stats::quantile(abs_diff_perc, 0.9, na.rm = TRUE),
    .by = age
  ) |>
  tidyr::pivot_longer(
    cols = c(mean_diff, median_diff, pct90_diff),
    names_to = "metric",
    values_to = "value"
  ) |>
  ggplot2::ggplot(
    mapping = ggplot2::aes(x = age, y = value, colour = metric)
  ) +
  ggplot2::scale_x_continuous(
    trans = "reverse",
    name = "Age (cal yr BP)"
  ) +
  ggplot2::scale_y_continuous(
    name = "Pollen proportion difference (%)\n|New \u2212 Current|"
  ) +
  ggplot2::scale_colour_manual(
    name = "Statistic",
    values = c(
      mean_diff = "#1a9641",
      median_diff = "#2166ac",
      pct90_diff = "#d73027"
    ),
    labels = c(
      mean_diff = "Mean",
      median_diff = "Median",
      pct90_diff = "90th pctile"
    )
  ) +
  ggplot2::labs(
    title = "How does the difference vary across time?",
    subtitle = stringr::str_glue(
      "Czech project | {n_datasets} cores | {n_iter_actual} of {n_iterations} iterations"
    )
  ) +
  ggplot2::theme_classic() +
  ggview::canvas(
    width = graphical_options[["width"]],
    height = graphical_options[["height"]],
    units = graphical_options[["units"]]
  ) +
  ggplot2::geom_line(linewidth = 1) +
  ggplot2::geom_point(size = 2)

print_safe(plot_diff_by_age)

ggview::save_ggplot(
  plot = plot_diff_by_age,
  file = here::here(
    "Outputs/Figures/Supplementary/",
    "interpolation_uncertainty_comparison_by_age.png"
  )
)
