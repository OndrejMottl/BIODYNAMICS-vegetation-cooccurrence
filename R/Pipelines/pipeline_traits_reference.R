#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Full trait {targets} pipeline
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Complete targets pipeline for the trait analysis workflow.
# Orchestrates five pipe segments in sequence:
#
#   Segment 1 — pipe_segment_traits_extract
#     Discovers continental rows from spatial_grid.csv and
#     extracts raw trait data from VegVault per continent.
#
#   Segment 2 — pipe_segment_traits_qc
#     Generates QC report, tracks corrections CSV, enforces
#     human sign-off (HUMAN-IN-LOOP guard), applies corrections.
#
#   Segment 3 — pipe_segment_traits_classification
#     Classifies all trait taxa via taxospace and resolves each
#     to its finest available taxonomic rank (genus preferred).
#     Unresolved taxa are appended to missing_taxa_template.csv
#     before the guard target stops the pipeline.
#
#   Segment 4 — pipe_segment_traits_qc_classified
#     Generates a second QC pass on the classified data grouped by
#     taxon_genus; human sign-off guard; applies genus-level
#     corrections.
#
#   Segment 5 — pipe_segment_traits_table
#     Aggregates to median, pivots to a project-agnostic wide
#     genus × traits matrix.
#
# Note: FT clustering (previously Segment 6) has been moved to
#   pipe_segment_ft_classification_continental.R, which runs as part of
#   pipeline_paleo_spatial_resolution.R for each continental spatial unit.
#   This ensures FT labels are derived from the actual community
#   taxa (genus/family pollen names) rather than species-level
#   trait taxa, and that regional/local pipelines share consistent
#   FT labels with their parent continental run.
#
# HUMAN REVIEW REQUIRED (inside segments 2 and 4):
#   Segment 3 — if trait classification stops, open:
#     Data/Input/missing_taxa_template.csv
#       <- review the unresolved trait taxa appended by the guard
#     Data/Input/aux_classification_table.csv
#       <- add manual classifications, then re-run tar_make()
#       (same file used by the community pipeline — one edit covers both)
#
#   Segment 2 — after trait_qc_report completes, open:
#     Data/Temp/trait_qc_report_{date}.csv      <- review suspected outliers
#                                                   (per-domain x taxon summary)
#     Data/Input/trait_manual_corrections.csv   <- fill in corrections
#   Set CHECKED = TRUE for every row, then re-run tar_make() so the
#   trait_corrections_validated guard target passes.
#
#   Segment 4 — after trait_qc_report_classified completes, open:
#     Data/Temp/trait_qc_report_{date}.csv
#       <- review suspected outliers (per-domain x genus summary)
#     Data/Input/trait_manual_corrections_classified.csv
#       <- fill in corrections
#   Set CHECKED = TRUE for every row, then re-run tar_make() so
#   the trait_corrections_classified_validated guard target passes.
#
# To run this pipeline:
#
#   targets::tar_make(
#     script = here::here("R/Pipelines/pipeline_traits_reference.R"),
#     store  = here::here("Data/targets/traits_reference_reference/pipeline_traits_reference")
#   )
#
# To force re-extraction from VegVault (not done automatically):
#
#   targets::tar_invalidate("data_traits_continent")


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  verbose = FALSE
)

suppressMessages(
  suppressWarnings(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)

vec_fun_files <-
  base::list.files(
    path = here::here("R/Functions/"),
    pattern = "*.R",
    recursive = TRUE,
    full.names = TRUE
  ) |>
  purrr::discard(
    ~ stringr::str_detect(.x, "_outdated|_legacy")
  )

targets::tar_source(
  files = vec_fun_files
)

targets::tar_option_set(
  seed = get_active_config("seed"),
  format = "qs"
)


#----------------------------------------------------------#
# 1. Load pipe segments -----
#----------------------------------------------------------#

path_pipe_parts <-
  here::here("R/Pipelines/_pipes/")

# Segments must be sourced in dependency order:
#   extraction -> qc -> classification -> qc_classified -> table
base::c(
  "pipe_segment_traits_extract.R",
  "pipe_segment_traits_qc.R",
  "pipe_segment_traits_classification.R",
  "pipe_segment_traits_qc_classified.R",
  "pipe_segment_traits_table.R"
) |>
  rlang::set_names() |>
  purrr::walk(
    .f = ~ base::source(
      file = base::file.path(path_pipe_parts, .x)
    )
  )


#----------------------------------------------------------#
# 2. Combine all segments into single pipeline -----
#----------------------------------------------------------#

base::list(
  pipe_segment_traits_extract,
  pipe_segment_traits_qc,
  pipe_segment_traits_classification,
  pipe_segment_traits_qc_classified,
  pipe_segment_traits_table
)
