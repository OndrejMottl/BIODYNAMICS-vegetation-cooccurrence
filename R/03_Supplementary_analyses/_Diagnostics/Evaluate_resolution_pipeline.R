#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               Evaluate resolution pipeline
#         validation gate (project_cz_paleo testbed)
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Compares the outputs of `pipeline_paleo_resolution_test.R`
#   (store: `Data/targets/cz_paleo/pipeline_paleo_resolution_test`)
#   against the reference `pipeline_paleo_core.R` output
#   (store: `Data/targets/cz_paleo/pipeline_paleo_core`) to verify
#   that:
#     1. The genus branch is a regression-exact match.
#     2. The family branch produces a coarser community matrix.
#     3. The functional-type (FT) branch produces integer FT labels.
#   Run this script interactively after completing a fresh run of
#   `pipeline_paleo_resolution_test.R`.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

Sys.setenv(R_CONFIG_ACTIVE = "project_cz_paleo")

store_basic <-
  here::here("Data/targets/cz_paleo/pipeline_paleo_core")

store_test <-
  here::here("Data/targets/cz_paleo/pipeline_paleo_resolution_test")


#----------------------------------------------------------#
# 1. Pipeline status -----
#----------------------------------------------------------#

# Report any errored or cancelled targets in the test store.
meta_test <-
  targets::tar_meta(
    store  = store_test,
    fields = c("name", "error", "warnings")
  )

n_errors <-
  sum(!is.na(meta_test$error))

if (
  n_errors == 0L
) {
  cli::cli_alert_success("{n_errors} errored targets — clean run.")
} else {
  cli::cli_alert_danger("{n_errors} errored target(s):")
  meta_test |>
    dplyr::filter(!is.na(error)) |>
    dplyr::select(name, error) |>
    print()
}

n_warnings <-
  sum(!is.na(meta_test$warnings))

cli::cli_alert_info("{n_warnings} target(s) produced warnings.")


#----------------------------------------------------------#
# 2. Genus regression check -----
#----------------------------------------------------------#

#--------------------------------------------------#
## 2.1. Community data -----
#--------------------------------------------------#

data_community_basic <-
  targets::tar_read(
    data_community_analysis_subset,
    store = store_basic
  )

data_community_genus <-
  targets::tar_read(
    data_community_analysis_subset_genus,
    store = store_test
  )

n_taxa_basic <-
  dplyr::n_distinct(data_community_basic$taxon)

n_taxa_genus <-
  dplyr::n_distinct(data_community_genus$taxon)

n_samples_basic <-
  dplyr::n_distinct(data_community_basic$dataset_name, data_community_basic$age)

n_samples_genus <-
  dplyr::n_distinct(data_community_genus$dataset_name, data_community_genus$age)

taxa_only_basic <-
  dplyr::setdiff(
    unique(data_community_basic$taxon),
    unique(data_community_genus$taxon)
  )

taxa_only_genus <-
  dplyr::setdiff(
    unique(data_community_genus$taxon),
    unique(data_community_basic$taxon)
  )

cli::cli_text(
  "pipeline_paleo_core  — n_taxa: {n_taxa_basic}, n_samples: {n_samples_basic}"
)
cli::cli_text(
  "test_res genus  — n_taxa: {n_taxa_genus}, n_samples: {n_samples_genus}"
)

taxa_match <-
  length(taxa_only_basic) == 0L && length(taxa_only_genus) == 0L

samples_match <-
  n_samples_basic == n_samples_genus

if (
  taxa_match && samples_match
) {
  cli::cli_alert_success(
    "Community matrices identical — same taxa and sample count."
  )
} else {
  if (
    !taxa_match
  ) {
    cli::cli_alert_danger(
      "Taxa mismatch: {length(taxa_only_basic)} only in basic, {length(taxa_only_genus)} only in genus branch."
    )
    if (
      length(taxa_only_basic) > 0
    ) {
      cli::cli_text("Only in basic: {taxa_only_basic}")
    }
    if (
      length(taxa_only_genus) > 0
    ) {
      cli::cli_text("Only in genus: {taxa_only_genus}")
    }
  }
  if (
    !samples_match
  ) {
    cli::cli_alert_danger(
      "Sample count differs: basic = {n_samples_basic}, genus = {n_samples_genus}"
    )
  }
}


#--------------------------------------------------#
## 2.2. ANOVA variance partitioning -----
#--------------------------------------------------#

model_anova_basic <-
  targets::tar_read(
    model_anova,
    store = store_basic
  )

model_anova_genus <-
  targets::tar_read(
    model_anova_genus,
    store = store_test
  )

results_basic <-
  model_anova_basic$results

results_genus <-
  model_anova_genus$results

cli::cli_text("pipeline_paleo_core  N = {model_anova_basic$N}")
cli::cli_text("test_res genus  N = {model_anova_genus$N}")

anova_match <-
  isTRUE(
    all.equal(results_basic, results_genus, tolerance = 1e-6)
  )

if (
  anova_match
) {
  cli::cli_alert_success("Variance partitioning tables identical (tolerance 1e-6).")
} else {
  cli::cli_alert_danger("Variance partitioning tables differ — investigate!")
  cli::cli_text("pipeline_paleo_core results:")
  print(results_basic)
  cli::cli_text("\ntest_res genus results:")
  print(results_genus)
}


#----------------------------------------------------------#
# 3. Family branch spot checks -----
#----------------------------------------------------------#

data_community_family <-
  targets::tar_read(
    data_community_analysis_subset_family,
    store = store_test
  )

n_taxa_family <-
  dplyr::n_distinct(data_community_family$taxon)

n_samples_family <-
  dplyr::n_distinct(
    data_community_family$dataset_name,
    data_community_family$age
  )

prop_range_family <-
  data_community_family |>
  dplyr::group_by(dataset_name, age) |>
  dplyr::summarise(total = sum(pollen_prop, na.rm = TRUE), .groups = "drop") |>
  dplyr::pull(total) |>
  range()

cli::cli_text(
  "n_taxa (families): {n_taxa_family}  (genus reference: {n_taxa_genus})"
)
cli::cli_text(
  "n_samples: {n_samples_family}"
)
cli::cli_text(
  "pollen_prop sum per sample: [{round(prop_range_family[1], 3)} — {round(prop_range_family[2], 3)}]"
)
cli::cli_text(
  "Taxa: {stringr::str_c(sort(unique(data_community_family$taxon)), collapse = ', ')}"
)

if (
  n_taxa_family < n_taxa_genus
) {
  cli::cli_alert_success(
    "Family is coarser than genus ({n_taxa_family} < {n_taxa_genus} taxa)."
  )
} else {
  cli::cli_alert_danger(
    "Family should have fewer taxa than genus! family={n_taxa_family}, genus={n_taxa_genus}"
  )
}


#----------------------------------------------------------#
# 4. Functional-type branch spot checks -----
#----------------------------------------------------------#

data_community_ft <-
  targets::tar_read(
    data_community_analysis_subset_functional_type,
    store = store_test
  )

data_community_ft_resolved <-
  targets::tar_read(
    data_community_by_resolution_functional_type,
    store = store_test
  )

n_taxa_ft <-
  dplyr::n_distinct(data_community_ft$taxon)

n_samples_ft <-
  dplyr::n_distinct(data_community_ft$dataset_name, data_community_ft$age)

ft_labels <-
  sort(unique(data_community_ft$taxon))

all_ft_labelled <-
  all(stringr::str_detect(ft_labels, "^FT_\\d+$"))

prop_range_ft <-
  data_community_ft |>
  dplyr::group_by(dataset_name, age) |>
  dplyr::summarise(total = sum(pollen_prop, na.rm = TRUE), .groups = "drop") |>
  dplyr::pull(total) |>
  range()

cli::cli_text(
  "n_FT groups (subset): {n_taxa_ft}"
)
cli::cli_text(
  "n_FT groups (resolved, before n-taxa filter): {dplyr::n_distinct(data_community_ft_resolved$taxon)}"
)
cli::cli_text(
  "n_samples: {n_samples_ft}"
)
cli::cli_text(
  "pollen_prop sum per sample: [{round(prop_range_ft[1], 3)} — {round(prop_range_ft[2], 3)}]"
)
cli::cli_text(
  "FT labels: {stringr::str_c(ft_labels, collapse = ', ')}"
)

if (
  all_ft_labelled
) {
  cli::cli_alert_success("All taxa carry integer FT labels (FT_N format).")
} else {
  cli::cli_alert_danger(
    "Non-FT labels found: {ft_labels[!stringr::str_detect(ft_labels, '^FT_\\\\d+$')]}"
  )
}

# Pollen coverage: fraction of community pollen assigned to an FT.
# Values <100% are expected because taxa without trait data are dropped.
coverage <-
  data_community_ft_resolved |>
  dplyr::group_by(dataset_name, age) |>
  dplyr::summarise(total_ft = sum(pollen_prop, na.rm = TRUE), .groups = "drop") |>
  dplyr::inner_join(
    data_community_genus |>
      dplyr::group_by(dataset_name, age) |>
      dplyr::summarise(total_genus = sum(pollen_prop, na.rm = TRUE), .groups = "drop"),
    by = dplyr::join_by(dataset_name, age)
  ) |>
  dplyr::mutate(coverage_pct = total_ft / total_genus * 100)

median_coverage <-
  round(stats::median(coverage$coverage_pct, na.rm = TRUE), 1)

range_coverage <-
  round(range(coverage$coverage_pct, na.rm = TRUE), 1)

cli::cli_text(
  "Pollen coverage vs. genus (%%): median = {median_coverage}%%, range = [{range_coverage[1]} — {range_coverage[2]}]"
)
cli::cli_alert_info(
  "Coverage <100%% is expected — taxa without trait data in the FT table are dropped."
)


#----------------------------------------------------------#
# 5. Summary -----
#----------------------------------------------------------#

checks <-
  list(
    "No errored targets" = n_errors == 0L,
    "Genus taxa match pipeline_paleo_core" = taxa_match,
    "Genus samples match pipeline_paleo_core" = samples_match,
    "Genus ANOVA tables identical" = anova_match,
    "Family coarser than genus" = n_taxa_family < n_taxa_genus,
    "FT labels are integer FT_N format" = all_ft_labelled
  )

for (label in names(checks)) {
  if (
    checks[[label]]
  ) {
    cli::cli_alert_success(label)
  } else {
    cli::cli_alert_danger(label)
  }
}

gate_passed <-
  all(unlist(checks))

if (
  gate_passed
) {
  cli::cli_alert_success(
    "Validation gate PASSED — all criteria met. F2 and F3 are unblocked."
  )
} else {
  cli::cli_alert_danger(
    "Validation gate FAILED — fix failing checks before proceeding to F2/F3."
  )
}
