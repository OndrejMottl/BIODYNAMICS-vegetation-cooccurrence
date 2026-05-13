#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#         {targets} pipe: Trait QC and corrections
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Pipe segment that generates the QC report, tracks the human
#   corrections CSV, enforces human sign-off, and applies
#   corrections to the raw trait data.
#
# Targets in execution order:
#   1. trait_qc_report              – per-domain and per-domain×taxon stats
#                                     + outlier summary;
#                                     writes Data/Temp/trait_qc_report_*.csv
#                                     (per-domain×taxon summary);
#                                     creates Data/Input/trait_manual_corrections.csv
#                                     if it does not yet exist
#   2. file_trait_corrections        - tracks the corrections CSV (format="file")
#   3. trait_corrections_validated   – GUARD: aborts when any row has
#                                      CHECKED != TRUE; requires human sign-off
#   4. data_traits_corrected         – corrections applied to raw trait data
#
# HUMAN REVIEW REQUIRED BETWEEN TARGETS 2 AND 3:
#   After running targets 1-2, open Data/Input/trait_manual_corrections.csv,
#   review the suspected outliers listed in the QC report, add correction
#   rows as needed (action = "exclude" or "scale"), and set CHECKED = TRUE
#   for every row you have reviewed.  Only then will target 3 pass and
#   the pipeline continue.


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


#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_traits_qc <-
  list(

    # ── 1. Generate QC report ───────────────────────────
    # Side effects:
    #   • writes Data/Temp/trait_qc_report_{date}.csv (per-domain×taxon summary)
    #   • creates Data/Input/trait_manual_corrections.csv (header only)
    #     if the file does not already exist
    targets::tar_target(
      description = "Generate trait QC report and create corrections template",
      name = trait_qc_report,
      command = generate_trait_qc_report(
        data_traits = data_traits_raw,
        path_corrections = here::here(
          "Data/Input/trait_manual_corrections.csv"
        )
      )
    ),

    # ── 2. Track corrections CSV ────────────────────────
    # format = "file" causes {targets} to detect file changes (e.g.
    # when a human opens the CSV and adds/modifies rows). Downstream
    # targets automatically become outdated when the file is edited.
    # trait_qc_report is referenced to ensure the file is created
    # before this target attempts to track it.
    targets::tar_target(
      description = "Track trait manual corrections CSV for changes",
      name = file_trait_corrections,
      command = {
        trait_qc_report
        here::here("Data/Input/trait_manual_corrections.csv")
      },
      format = "file"
    ),

    # ── 3. HUMAN REVIEW GUARD ───────────────────────────
    # Calls validate_trait_corrections(), which aborts with an
    # informative error when any row has CHECKED != TRUE.
    # The pipeline CANNOT proceed past this point until a human has:
    #   1. Reviewed Data/Temp/trait_qc_report_{date}.csv
    #   2. Filled in Data/Input/trait_manual_corrections.csv
    #   3. Set CHECKED = TRUE for every row
    targets::tar_target(
      description = "GUARD: validate all correction rows are signed off",
      name = trait_corrections_validated,
      command = validate_trait_corrections(
        path_corrections = file_trait_corrections
      )
    ),

    # ── 4. Apply corrections ────────────────────────────
    # Removes "exclude" rows and scales "scale" rows in the raw data
    # according to the validated corrections tibble.
    targets::tar_target(
      description = "Apply human-reviewed corrections to raw trait data",
      name = data_traits_corrected,
      command = apply_trait_corrections(
        data_traits = data_traits_raw,
        data_corrections = trait_corrections_validated
      )
    )
  )
