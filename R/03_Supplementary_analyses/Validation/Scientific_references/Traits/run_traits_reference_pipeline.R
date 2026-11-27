#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Run traits reference pipeline
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Stable runner for the full traits reference {targets} pipeline.
# A single run_pipeline() call runs all four segments in sequence:
#
#   Segment 1 — Extract raw trait data from VegVault per continent
#               (slow, 15–60 min per continent; cached individually
#                so adding a continent only re-extracts that continent)
#   Segment 2 — QC + corrections pipeline with human-in-loop guard
#   Segment 3 — Classify all trait taxa via taxospace
#   Segment 4 — Build project-agnostic genus × traits table
#
# HUMAN REVIEW STEPS:
#   The raw and classified stages each stop at a complete-coverage check.
#   Every current candidate needs an approved correction or explicit
#   no-action row in the decision files of the VegVault release:
#     Data/Input/Trait_corrections/VegVault_<version>/
#       trait_review_decisions_raw.csv
#       trait_review_decisions_classified.csv
#   Data/Input/Trait_corrections/README.md describes the sorting and
#   approval runners that write them, and the decision schema.
#
# RE-EXTRACTION:
#   The target config_vegvault_release reads the release record of
#   Data/Input/VegVault.sqlite on every run, so replacing the database
#   reruns the extraction. A new vaultkeepr version is not tracked; to
#   force re-extraction for the same database, invalidate the continent
#   branches first:
#
#     targets::tar_invalidate("data_traits_continent")
#
#   Then re-run run_pipeline() below.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 1. Set active configuration -----
#----------------------------------------------------------#

Sys.setenv(R_CONFIG_ACTIVE = "project_traits_reference")


#----------------------------------------------------------#
# 2. Run the full trait pipeline -----
#----------------------------------------------------------#

run_pipeline(
  sel_script = "R/Pipelines/pipeline_traits_reference.R",
  vec_allowed_profile_roles = "reference",
  vec_allowed_profile_statuses = "frozen"
)
