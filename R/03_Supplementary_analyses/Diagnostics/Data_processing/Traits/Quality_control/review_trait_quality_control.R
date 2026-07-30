#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#      Trait quality-control interactive review tool
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
#   2. Edit `focal_taxon` / `trait_domain` and source Section 2
#      for a domain-wide flagging overview.
#   3. Set `focal_taxon` + `trait_domain`, source Section 3 to
#      inspect the raw distribution of one group.
#   4. Set all correction fields, then source Section 4
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
focal_taxon <- "Anacyclus clavatus"

# Trait domain to inspect / correct. Set to NULL to skip
#   domain filtering in Section 2.
trait_domain <- "Leaf Area"

# For Section 4: correction action ("exclude" or "scale").
correction_action <- "exclude"

# For Section 4: scale factor. Required when
#   correction_action == "scale"; leave as NA_real_ otherwise.
correction_scale_factor <- NA_real_

# For Section 4: free-text reason / notes (optional).
correction_notes <- ""

# Minimum number of records for a taxon to appear in the
#   taxonomic comparison table and plot in Section 3.4.
minimum_taxonomic_records <- 5L

# ----------------------------------------------------------

# Graphical options shared across all plots in this script.
graphical_options <-
  load_active_config_value("graphical")

# Path to the manual corrections file.
path_trait_corrections <-
  here::here("Data/Input/trait_manual_corrections.csv")

# Target store for the traits pipeline.
path_trait_store <-
  here::here(
    "Data/targets/traits_reference_reference/pipeline_traits_reference"
  )


#----------------------------------------------------------#
# 1. Load data -----
#----------------------------------------------------------#

#--------------------------------------------------#
## 1.1. QC report -----
#--------------------------------------------------#

# Auto-detect the most-recent QC report in Data/Temp/.
trait_quality_control_report_paths <-
  fs::dir_ls(
    here::here("Data/Temp"),
    regexp = "trait_qc_report_\\d{4}-\\d{2}-\\d{2}\\.csv$"
  )

if (
  base::length(trait_quality_control_report_paths) == 0L
) {
  base::stop(
    "No trait_qc_report_*.csv found in Data/Temp/.\n",
    "Run the traits pipeline to generate it."
  )
}

path_trait_quality_control_report <-
  trait_quality_control_report_paths |>
  base::sort() |>
  utils::tail(1L)

base::message(
  "Using QC report: ",
  base::basename(path_trait_quality_control_report)
)

data_trait_quality_control_report <-
  readr::read_csv(
    path_trait_quality_control_report,
    show_col_types = FALSE
  ) |>
  dplyr::mutate(
    outlier_fraction =
      .data[["n_suspected_outliers_taxon"]] /
        .data[["n_records"]]
  )


#--------------------------------------------------#
## 1.2. Raw trait values -----
#--------------------------------------------------#

if (
  !fs::dir_exists(path_trait_store)
) {
  base::stop(
    "Traits target store not found at: ", path_trait_store, "\n",
    "Run the traits pipeline first."
  )
}

data_traits_raw <-
  targets::tar_read(
    data_traits_raw,
    store = path_trait_store
  )

base::message(
  "Loaded data_traits_raw: ",
  base::nrow(data_traits_raw), " rows, ",
  dplyr::n_distinct(
    dplyr::pull(data_traits_raw, .data[["taxon_name"]])
  ),
  " taxa, ",
  dplyr::n_distinct(
    dplyr::pull(data_traits_raw, .data[["trait_domain_name"]])
  ),
  " domains."
)


#--------------------------------------------------#
## 1.3. Corrections file -----
#--------------------------------------------------#

if (
  !base::file.exists(path_trait_corrections)
) {
  base::stop(
    "Corrections file not found at: ", path_trait_corrections, "\n",
    "Run write_trait_quality_control_report() to create the template."
  )
}

data_corrections_current <-
  readr::read_csv(
    path_trait_corrections,
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
# Filter by trait_domain (NULL = all domains).

data_flagged_trait_groups <-
  data_trait_quality_control_report |>
  dplyr::filter(.data[["n_suspected_outliers_taxon"]] > 0L)

# Apply domain filter if set.
if (
  !base::is.null(trait_domain)
) {
  data_flagged_trait_groups <-
    data_flagged_trait_groups |>
    dplyr::filter(.data[["trait_domain_name"]] == trait_domain)
}

# Mark groups that already have a correction entry.
data_flagged_trait_groups <-
  data_flagged_trait_groups |>
  dplyr::left_join(
    data_corrections_current |>
      dplyr::select("taxon_name", "trait_domain_name") |>
      dplyr::mutate(correction_exists = TRUE),
    by = dplyr::join_by(taxon_name, trait_domain_name)
  ) |>
  dplyr::mutate(
    correction_exists =
      tidyr::replace_na(.data[["correction_exists"]], FALSE)
  )

#------------------------------------------#
### 2.1. Domain-level summary -----
#------------------------------------------#

base::message("\n--- Flagged groups by domain ---")
data_flagged_trait_groups |>
  dplyr::group_by(.data[["trait_domain_name"]]) |>
  dplyr::summarise(
    n_flagged_groups = dplyr::n(),
    n_corrected = base::sum(.data[["correction_exists"]]),
    .groups = "drop"
  ) |>
  dplyr::arrange(dplyr::desc(.data[["n_flagged_groups"]])) |>
  base::print(n = Inf)

#------------------------------------------#
### 2.2. Top groups by outlier fraction -----
#------------------------------------------#

base::message("\n--- Top 25 flagged groups by outlier fraction ---")
data_flagged_trait_groups |>
  dplyr::arrange(
    dplyr::desc(.data[["outlier_fraction"]]),
    dplyr::desc(.data[["n_records"]])
  ) |>
  dplyr::select(
    "trait_domain_name",
    "taxon_name",
    "n_records",
    "n_suspected_outliers_taxon",
    "outlier_fraction",
    "correction_exists"
  ) |>
  dplyr::slice_head(n = 25L) |>
  base::print(n = Inf)


#----------------------------------------------------------#
# 3. Single-group inspection -----
#----------------------------------------------------------#
# Requires both focal_taxon and trait_domain to be set.
# Prints: QC summary row, sorted raw values, distribution plot.

if (
  base::is.null(focal_taxon) ||
    base::is.null(trait_domain)
) {
  base::stop(
    "Set both `focal_taxon` and `trait_domain` in Section 0 ",
    "before sourcing Section 3."
  )
}

#--------------------------------------------------#
## 3.1. QC summary row -----
#--------------------------------------------------#

data_focal_trait_summary <-
  data_trait_quality_control_report |>
  dplyr::filter(
    .data[["taxon_name"]] == focal_taxon,
    .data[["trait_domain_name"]] == trait_domain
  )

if (
  base::nrow(data_focal_trait_summary) == 0L
) {
  base::stop(
    "No QC report entry found for taxon '", focal_taxon,
    "' in domain '", trait_domain, "'.\n",
    "Check the spelling or run write_trait_quality_control_report() again."
  )
}

base::message("\n--- QC summary: ", focal_taxon, " x ", trait_domain, " ---")
data_focal_trait_summary |>
  dplyr::select(
    "trait_domain_name",
    "taxon_name",
    "n_records",
    "mean",
    "median",
    "sd",
    "IQR",
    "n_suspected_outliers_taxon",
    "outlier_fraction"
  ) |>
  base::print()


#--------------------------------------------------#
## 3.2. Raw values (sorted) -----
#--------------------------------------------------#

data_focal_trait_records <-
  data_traits_raw |>
  dplyr::filter(
    .data[["taxon_name"]] == focal_taxon,
    .data[["trait_domain_name"]] == trait_domain
  ) |>
  dplyr::arrange(.data[["trait_value"]])

base::message("\n--- Raw values (ascending) ---")
data_focal_trait_records |>
  base::print(n = Inf)


#--------------------------------------------------#
## 3.3. Distribution plot -----
#--------------------------------------------------#

plot_focal_distribution <-
  plot_focal_trait_distribution(
    data_focal_trait_records = data_focal_trait_records,
    data_focal_trait_summary = data_focal_trait_summary,
    focal_taxon = focal_taxon,
    trait_domain = trait_domain,
    graphical_options = graphical_options
  )

base::print(plot_focal_distribution)


#--------------------------------------------------#
## 3.4. Taxonomic comparison -----
#--------------------------------------------------#

data_taxon_classification <-
  targets::tar_read(
    data_combined_classification_table_traits,
    store = path_trait_store
  )

data_taxonomic_trait_summary <-
  summarise_taxonomic_group_traits(
    data_trait_records = data_traits_raw,
    data_taxon_classification = data_taxon_classification,
    focal_taxon = focal_taxon,
    trait_domain = trait_domain,
    taxonomic_rank = "family",
    verbose = TRUE
  )

# Annotate with mean/median ratio to flag taxa with
#   probable internal outliers (ratio >> 1 is suspicious).
data_taxonomic_trait_summary_annotated <-
  data_taxonomic_trait_summary |>
  dplyr::mutate(
    mean_median_ratio = dplyr::if_else(
      .data[["median"]] > 0,
      .data[["mean"]] / .data[["median"]],
      NA_real_
    ),
    taxon_name = dplyr::if_else(
      .data[["taxon_name"]] == focal_taxon,
      base::paste0(.data[["taxon_name"]], "  *"),
      .data[["taxon_name"]]
    )
  )

# Full table sorted by median.
base::message(
  "\n--- All taxa (n = ",
  base::nrow(data_taxonomic_trait_summary_annotated),
  ") ---"
)
base::print(data_taxonomic_trait_summary_annotated, n = Inf)

# Filtered table: only taxa with enough records.
data_taxonomic_trait_filtered <-
  data_taxonomic_trait_summary_annotated |>
  dplyr::filter(
    .data[["n_records"]] >= minimum_taxonomic_records
  )

base::message(
  "\n--- Filtered: n >= ", minimum_taxonomic_records,
  " (", base::nrow(data_taxonomic_trait_filtered), " taxa) ---"
)
base::print(data_taxonomic_trait_filtered, n = Inf)

# Percentile rank of focal_taxon in the filtered distribution.
focal_taxon_median <-
  data_taxonomic_trait_summary |>
  dplyr::filter(.data[["taxon_name"]] == focal_taxon) |>
  dplyr::pull(.data[["median"]])

if (
  base::length(focal_taxon_median) > 0L &&
    !base::is.na(focal_taxon_median[[1L]])
) {
  filtered_taxon_medians <-
    data_taxonomic_trait_filtered |>
    dplyr::pull(.data[["median"]])

  percentile_rank <-
    base::round(
      base::mean(filtered_taxon_medians < focal_taxon_median[[1L]]) * 100,
      digits = 1L
    )

  base::message(
    "\n", focal_taxon, " sits at the ",
    percentile_rank,
    "th percentile of the filtered taxonomic-group distribution."
  )
}

# Log-scale strip plot: grey dots = all filtered taxa,
#   red dot = focal_taxon.
plot_taxonomic_comparison <-
  plot_taxonomic_trait_comparison(
    data_taxonomic_trait_summary = data_taxonomic_trait_summary,
    data_focal_trait_summary = data_focal_trait_summary,
    focal_taxon = focal_taxon,
    trait_domain = trait_domain,
    minimum_records = minimum_taxonomic_records,
    graphical_options = graphical_options
  )

base::print(plot_taxonomic_comparison)


#----------------------------------------------------------#
# 4. Write correction -----
#----------------------------------------------------------#
# Source this section to append ONE correction row for
#   focal_taxon x trait_domain to the corrections CSV.
#
# Required in Section 0 before sourcing this section:
#   focal_taxon      -- character, must not be NULL
#   trait_domain     -- character, must not be NULL
#   correction_action     -- "exclude" or "scale"
#   correction_scale_factor -- numeric if action = "scale", else NA_real_
#   correction_notes      -- character (may be empty string)


#------------------------------------------#
### 4.1. Pre-flight checks -----
#------------------------------------------#

if (
  base::is.null(focal_taxon) ||
    base::is.null(trait_domain)
) {
  base::stop(
    "Set both `focal_taxon` and `trait_domain` ",
    "before sourcing Section 4."
  )
}

if (
  !focal_taxon %in%
    dplyr::pull(data_traits_raw, .data[["taxon_name"]])
) {
  base::stop(
    "'", focal_taxon, "' not found in data_traits_raw.\n",
    "Check the spelling."
  )
}

if (
  !trait_domain %in%
    dplyr::pull(data_traits_raw, .data[["trait_domain_name"]])
) {
  base::stop(
    stringr::str_c(
      stringr::str_glue(
        "'{trait_domain}' not found in data_traits_raw.\n"
      ),
      "Valid domains: ",
      stringr::str_c(
        base::unique(
          dplyr::pull(
            data_traits_raw,
            .data[["trait_domain_name"]]
          )
        ),
        collapse = ", "
      )
    )
  )
}

if (
  !correction_action %in% base::c("exclude", "scale")
) {
  base::stop(
    "correction_action must be \"exclude\" or \"scale\"; got: '",
    correction_action,
    "'"
  )
}

if (
  correction_action == "scale" &&
    (base::is.na(correction_scale_factor) ||
      !base::is.numeric(correction_scale_factor))
) {
  base::stop(
    "correction_scale_factor must be numeric when ",
    "correction_action = \"scale\"."
  )
}

# Guard: no duplicate entry.
data_existing_correction <-
  data_corrections_current |>
  dplyr::filter(
    .data[["taxon_name"]] == focal_taxon,
    .data[["trait_domain_name"]] == trait_domain
  )

if (
  base::nrow(data_existing_correction) > 0L
) {
  base::message(
    "A correction row already exists for '", focal_taxon,
    "' x '", trait_domain, "':"
  )
  base::print(data_existing_correction)
  base::stop(
    "Remove or update the existing entry manually before adding a new one."
  )
}


#------------------------------------------#
### 4.2. Build and append row -----
#------------------------------------------#

data_new_correction <-
  tibble::tibble(
    taxon_name = focal_taxon,
    trait_domain_name = trait_domain,
    action = correction_action,
    scale_factor = correction_scale_factor,
    notes = correction_notes,
    CHECKED = TRUE
  )

data_corrections_updated <-
  dplyr::bind_rows(
    data_corrections_current,
    data_new_correction
  )

readr::write_csv(
  data_corrections_updated,
  path_trait_corrections
)

# Reload current state so Section 2 / Section 5 stay in sync.
data_corrections_current <-
  readr::read_csv(
    path_trait_corrections,
    show_col_types = FALSE
  )

base::message(
  "Correction written for '", focal_taxon, "' x '", trait_domain, "'.",
  "\n  action = ", correction_action,
  if (
    correction_action == "scale"
  ) {
    stringr::str_glue("  scale_factor = {correction_scale_factor}")
  },
  "\n  Total corrections: ", base::nrow(data_corrections_current)
)


#----------------------------------------------------------#
# 5. Validate corrections -----
#----------------------------------------------------------#
# Source this section at any time to run the pipeline guard.
# validate_trait_corrections() aborts if any CHECKED != TRUE.

data_corrections_validated <-
  validate_trait_corrections(
    data_trait_corrections = load_trait_corrections(
      path_trait_corrections = path_trait_corrections
    )
  )

base::message(
  "\nCorrections file is valid. ",
  base::nrow(data_corrections_validated), " row(s) ready for the pipeline."
)

base::message("\n--- All current corrections ---")
data_corrections_validated |>
  dplyr::select(
    "trait_domain_name",
    "taxon_name",
    "action",
    "scale_factor",
    "notes",
    "CHECKED"
  ) |>
  base::print(n = Inf)
