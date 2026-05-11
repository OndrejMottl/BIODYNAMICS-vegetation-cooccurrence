#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#            Trait QC interactive review tool
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Interactive tool for reviewing flagged trait groups,
#   inspecting raw value distributions, and entering manual
#   corrections into Data/Input/trait_manual_corrections.csv.
#
# Workflow:
#   1. Source Section 0 and Section 1 once per R session.
#   2. Edit `sel_taxon` / `sel_domain` and source Section 2
#      for a domain-wide flagging overview.
#   3. Set `sel_taxon` + `sel_domain`, source Section 3 to
#      inspect the raw distribution of one group.
#   4. Set all `sel_*` correction fields, source Section 4
#      to write one correction row to the corrections CSV.
#   5. Source Section 5 at any time to validate the full
#      corrections file via `validate_trait_corrections()`.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

# --- User-configurable variables --------------------------
# Set these before sourcing individual sections below.

# Taxon to inspect / correct. Set to NULL to skip taxon
#   filtering in Section 2.
sel_taxon <- "Anacyclus clavatus"

# Trait domain to inspect / correct. Set to NULL to skip
#   domain filtering in Section 2.
sel_domain <- "Leaf Area"

# For Section 4: correction action ("exclude" or "scale").
sel_action <- "exclude"

# For Section 4: scale factor. Required when
#   sel_action == "scale"; leave as NA_real_ otherwise.
sel_scale_factor <- NA_real_

# For Section 4: free-text reason / notes (optional).
sel_notes <- ""

# Minimum number of measurements for a taxon to appear in the
#   filtered family comparison table and plot in Section 3.4.
sel_min_n <- 5L

# ----------------------------------------------------------

# Graphical options shared across all plots in this script.
graphical_options <-
  get_active_config("graphical")

# Path to the manual corrections file.
path_corrections <-
  here::here("Data/Input/trait_manual_corrections.csv")

# Target store for the traits pipeline.
path_traits_store <-
  here::here("Data/targets/traits_reference_reference/pipeline_traits_reference")


#----------------------------------------------------------#
# 1. Load data -----
#----------------------------------------------------------#

#--------------------------------------------------#
## 1.1. QC report -----
#--------------------------------------------------#

# Auto-detect the most-recent QC report in Data/Temp/.
vec_qc_report_paths <-
  fs::dir_ls(
    here::here("Data/Temp"),
    regexp = "trait_qc_report_\\d{4}-\\d{2}-\\d{2}\\.csv$"
  )

if (
  base::length(vec_qc_report_paths) == 0L
) {
  base::stop(
    "No trait_qc_report_*.csv found in Data/Temp/.\n",
    "Run the traits pipeline to generate it."
  )
}

path_qc_report <-
  vec_qc_report_paths |>
  base::sort() |>
  utils::tail(1L)

base::message("Using QC report: ", base::basename(path_qc_report))

data_qc_report <-
  readr::read_csv(
    path_qc_report,
    show_col_types = FALSE
  ) |>
  dplyr::mutate(
    outlier_fraction = n_suspected_outliers_taxon / n_records
  )


#--------------------------------------------------#
## 1.2. Raw trait values -----
#--------------------------------------------------#

if (
  !fs::dir_exists(path_traits_store)
) {
  base::stop(
    "Traits target store not found at: ", path_traits_store, "\n",
    "Run the traits pipeline first."
  )
}

data_traits_raw <-
  targets::tar_read(
    data_traits_raw,
    store = path_traits_store
  )

base::message(
  "Loaded data_traits_raw: ",
  base::nrow(data_traits_raw), " rows, ",
  dplyr::n_distinct(dplyr::pull(data_traits_raw, taxon_name)), " taxa, ",
  dplyr::n_distinct(dplyr::pull(data_traits_raw, trait_domain_name)), " domains."
)


#--------------------------------------------------#
## 1.3. Corrections file -----
#--------------------------------------------------#

if (
  !base::file.exists(path_corrections)
) {
  base::stop(
    "Corrections file not found at: ", path_corrections, "\n",
    "Run generate_trait_qc_report() to create the template."
  )
}

data_corrections_current <-
  readr::read_csv(
    path_corrections,
    show_col_types = FALSE
  )

base::message(
  "Corrections file loaded: ",
  base::nrow(data_corrections_current), " existing row(s)."
)


#----------------------------------------------------------#
# 2. Overview of flagged groups -----
#----------------------------------------------------------#
# Source this section to see a summary of flagged taxa.
# Filter by sel_domain (NULL = all domains).

data_flagged <-
  data_qc_report |>
  dplyr::filter(n_suspected_outliers_taxon > 0L)

# Apply domain filter if set.
if (
  !base::is.null(sel_domain)
) {
  data_flagged <-
    data_flagged |>
    dplyr::filter(trait_domain_name == sel_domain)
}

# Mark groups that already have a correction entry.
data_flagged <-
  data_flagged |>
  dplyr::left_join(
    data_corrections_current |>
      dplyr::select(taxon_name, trait_domain_name) |>
      dplyr::mutate(correction_exists = TRUE),
    by = dplyr::join_by(taxon_name, trait_domain_name)
  ) |>
  dplyr::mutate(
    correction_exists = tidyr::replace_na(correction_exists, FALSE)
  )

#------------------------------------------#
### 2.1. Domain-level summary -----
#------------------------------------------#

base::message("\n--- Flagged groups by domain ---")
data_flagged |>
  dplyr::group_by(trait_domain_name) |>
  dplyr::summarise(
    n_flagged_groups = dplyr::n(),
    n_corrected = base::sum(correction_exists),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(n_flagged_groups)) |>
  base::print(n = Inf)

#------------------------------------------#
### 2.2. Top groups by outlier fraction -----
#------------------------------------------#

base::message("\n--- Top 25 flagged groups by outlier fraction ---")
data_flagged |>
  dplyr::arrange(dplyr::desc(outlier_fraction), dplyr::desc(n_records)) |>
  dplyr::select(
    trait_domain_name, taxon_name, n_records,
    n_suspected_outliers_taxon, outlier_fraction,
    correction_exists
  ) |>
  dplyr::slice_head(n = 25L) |>
  base::print(n = Inf)


#----------------------------------------------------------#
# 3. Single-group inspection -----
#----------------------------------------------------------#
# Requires both sel_taxon and sel_domain to be set.
# Prints: QC summary row, sorted raw values, distribution plot.

if (
  base::is.null(sel_taxon) ||
    base::is.null(sel_domain)
) {
  base::stop(
    "Set both `sel_taxon` and `sel_domain` in Section 0 ",
    "before sourcing Section 3."
  )
}

#--------------------------------------------------#
## 3.1. QC summary row -----
#--------------------------------------------------#

data_group_summary <-
  data_qc_report |>
  dplyr::filter(
    taxon_name == sel_taxon,
    trait_domain_name == sel_domain
  )

if (
  base::nrow(data_group_summary) == 0L
) {
  base::stop(
    "No QC report entry found for taxon '", sel_taxon,
    "' in domain '", sel_domain, "'.\n",
    "Check the spelling or run generate_trait_qc_report() again."
  )
}

base::message("\n--- QC summary: ", sel_taxon, " x ", sel_domain, " ---")
data_group_summary |>
  dplyr::select(
    trait_domain_name, taxon_name, n_records, mean, median,
    sd, IQR, n_suspected_outliers_taxon, outlier_fraction
  ) |>
  base::print()


#--------------------------------------------------#
## 3.2. Raw values (sorted) -----
#--------------------------------------------------#

data_group_raw <-
  data_traits_raw |>
  dplyr::filter(
    taxon_name == sel_taxon,
    trait_domain_name == sel_domain
  ) |>
  dplyr::arrange(trait_value)

base::message("\n--- Raw values (ascending) ---")
data_group_raw |>
  base::print(n = Inf)


#--------------------------------------------------#
## 3.3. Distribution plot -----
#--------------------------------------------------#

plot_group <-
  plot_trait_group_distribution(
    data_group_raw = data_group_raw,
    data_group_summary = data_group_summary,
    sel_taxon = sel_taxon,
    sel_domain = sel_domain,
    graphical_options = graphical_options
  )

base::print(plot_group)


#--------------------------------------------------#
## 3.4. Family-level comparison -----
#--------------------------------------------------#

data_classification <-
  targets::tar_read(
    data_combined_classification_table_traits,
    store = path_traits_store
  )

data_family_comparison <-
  get_family_trait_summary(
    data_traits_raw = data_traits_raw,
    data_classification = data_classification,
    sel_taxon = sel_taxon,
    sel_domain = sel_domain,
    sel_rank = "family",
    verbose = TRUE
  )

# Annotate with mean/median ratio to flag taxa with
#   probable internal outliers (ratio >> 1 is suspicious).
data_family_comparison_annotated <-
  data_family_comparison |>
  dplyr::mutate(
    mean_median_ratio = dplyr::if_else(
      .data[["median"]] > 0,
      .data[["mean"]] / .data[["median"]],
      NA_real_
    ),
    taxon_name = dplyr::if_else(
      .data[["taxon_name"]] == sel_taxon,
      stringr::str_glue("{taxon_name}  *"),
      .data[["taxon_name"]]
    )
  )

# Full table sorted by median.
base::message(
  "\n--- All taxa (n = ",
  base::nrow(data_family_comparison_annotated),
  ") ---"
)
base::print(data_family_comparison_annotated, n = Inf)

# Filtered table: only taxa with at least sel_min_n measurements.
data_family_filtered <-
  data_family_comparison_annotated |>
  dplyr::filter(.data[["n"]] >= sel_min_n)

base::message(
  "\n--- Filtered: n >= ", sel_min_n,
  " (", base::nrow(data_family_filtered), " taxa) ---"
)
base::print(data_family_filtered, n = Inf)

# Percentile rank of sel_taxon in the filtered distribution.
vec_sel_median <-
  data_family_comparison |>
  dplyr::filter(.data[["taxon_name"]] == sel_taxon) |>
  dplyr::pull(.data[["median"]])

if (
  base::length(vec_sel_median) > 0L &&
    !base::is.na(vec_sel_median[[1L]])
) {
  vec_filtered_medians <-
    data_family_filtered |>
    dplyr::pull(.data[["median"]])

  percentile_rank <-
    base::round(
      base::mean(vec_filtered_medians < vec_sel_median[[1L]]) * 100,
      digits = 1L
    )

  base::message(
    "\n", sel_taxon, " sits at the ",
    percentile_rank, "th percentile of the filtered family distribution."
  )
}

# Log-scale strip plot: grey dots = all filtered taxa,
#   red dot = sel_taxon.
plot_family_comparison <-
  plot_family_trait_comparison(
    data_family_comparison = data_family_comparison,
    data_group_summary = data_group_summary,
    sel_taxon = sel_taxon,
    sel_domain = sel_domain,
    sel_min_n = sel_min_n,
    graphical_options = graphical_options
  )

base::print(plot_family_comparison)


#----------------------------------------------------------#
# 4. Write correction -----
#----------------------------------------------------------#
# Source this section to append ONE correction row for
#   sel_taxon x sel_domain to the corrections CSV.
#
# Required in Section 0 before sourcing this section:
#   sel_taxon      -- character, must not be NULL
#   sel_domain     -- character, must not be NULL
#   sel_action     -- "exclude" or "scale"
#   sel_scale_factor -- numeric if action = "scale", else NA_real_
#   sel_notes      -- character (may be empty string)


#------------------------------------------#
### 4.1. Pre-flight checks -----
#------------------------------------------#

if (
  base::is.null(sel_taxon) ||
    base::is.null(sel_domain)
) {
  base::stop("Set both `sel_taxon` and `sel_domain` before sourcing Section 4.")
}

if (
  !sel_taxon %in% dplyr::pull(data_traits_raw, taxon_name)
) {
  base::stop(
    "'", sel_taxon, "' not found in data_traits_raw.\n",
    "Check the spelling."
  )
}

if (
  !sel_domain %in% dplyr::pull(data_traits_raw, trait_domain_name)
) {
  base::stop(
    stringr::str_glue(
      "'{sel_domain}' not found in data_traits_raw.\n",
      "Valid domains: {stringr::str_c(base::unique(dplyr::pull(data_traits_raw, trait_domain_name)), collapse = ', ')}"
    )
  )
}

if (
  !sel_action %in% c("exclude", "scale")
) {
  base::stop(
    "sel_action must be \"exclude\" or \"scale\"; got: '", sel_action, "'"
  )
}

if (
  sel_action == "scale" &&
    (base::is.na(sel_scale_factor) ||
      !base::is.numeric(sel_scale_factor))
) {
  base::stop(
    "sel_scale_factor must be a numeric value when sel_action = \"scale\"."
  )
}

# Guard: no duplicate entry.
data_already_corrected <-
  data_corrections_current |>
  dplyr::filter(
    taxon_name == sel_taxon,
    trait_domain_name == sel_domain
  )

if (
  base::nrow(data_already_corrected) > 0L
) {
  base::message(
    "A correction row already exists for '", sel_taxon,
    "' x '", sel_domain, "':"
  )
  base::print(data_already_corrected)
  base::stop(
    "Remove or update the existing entry manually before adding a new one."
  )
}


#------------------------------------------#
### 4.2. Build and append row -----
#------------------------------------------#

data_new_correction <-
  tibble::tibble(
    taxon_name = sel_taxon,
    trait_domain_name = sel_domain,
    action = sel_action,
    scale_factor = sel_scale_factor,
    notes = sel_notes,
    CHECKED = TRUE
  )

data_corrections_updated <-
  dplyr::bind_rows(
    data_corrections_current,
    data_new_correction
  )

readr::write_csv(
  data_corrections_updated,
  path_corrections
)

# Reload current state so Section 2 / Section 5 stay in sync.
data_corrections_current <-
  readr::read_csv(
    path_corrections,
    show_col_types = FALSE
  )

base::message(
  "Correction written for '", sel_taxon, "' x '", sel_domain, "'.",
  "\n  action = ", sel_action,
  if (sel_action == "scale") stringr::str_glue("  scale_factor = {sel_scale_factor}"),
  "\n  Total corrections: ", base::nrow(data_corrections_current)
)


#----------------------------------------------------------#
# 5. Validate corrections -----
#----------------------------------------------------------#
# Source this section at any time to run the pipeline guard.
# validate_trait_corrections() aborts if any CHECKED != TRUE.

data_corrections_validated <-
  validate_trait_corrections(
    path_corrections = path_corrections
  )

base::message(
  "\nCorrections file is valid. ",
  base::nrow(data_corrections_validated), " row(s) ready for the pipeline."
)

base::message("\n--- All current corrections ---")
data_corrections_validated |>
  dplyr::select(
    trait_domain_name, taxon_name, action,
    scale_factor, notes, CHECKED
  ) |>
  base::print(n = Inf)
