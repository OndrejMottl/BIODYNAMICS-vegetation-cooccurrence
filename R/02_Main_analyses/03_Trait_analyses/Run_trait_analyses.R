#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Run trait analyses: master runner
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Master runner for the full trait analysis {targets} pipeline.
# A single tar_make() call runs all four segments in sequence:
#
#   Segment 1 — Extract raw trait data from VegVault per continent
#               (slow, 15–60 min per continent; cached individually
#                so adding a continent only re-extracts that continent)
#   Segment 2 — QC + corrections pipeline with human-in-loop guard
#   Segment 3 — Classify all trait taxa via taxospace
#   Segment 4 — Build project-agnostic genus × traits table
#
# HUMAN REVIEW STEP (inside segment 2 — pipeline stops automatically):
#   Running tar_make() for the first time will complete segment 1 and
#   the QC report target (segment 2, target 1), then STOP at the
#   human-review guard.  At that point:
#     1. Review  Data/Temp/trait_qc_report_{date}.csv
#     2. Fill in Data/Input/trait_manual_corrections.csv
#        (set CHECKED = TRUE for every row you have reviewed)
#     3. Re-run tar_make() — the guard will now pass and the rest
#        of the pipeline will complete.
#
# RE-EXTRACTION:
#   VegVault.sqlite is NOT tracked automatically (it is too large to
#   hash on every tar_make call). To force re-extraction after the
#   database is updated, invalidate the continent branches first:
#
#     targets::tar_invalidate("data_traits_continent")
#
#   Then re-run tar_make() below.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 1. Run the full trait pipeline -----
#----------------------------------------------------------#

targets::tar_make(
  script = here::here("R/02_Main_analyses/pipeline_traits.R"),
  store = here::here("Data/targets/traits/pipeline_traits")
)
