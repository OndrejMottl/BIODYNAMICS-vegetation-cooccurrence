#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#      {targets} pipe: Post-classification trait QC
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Pipe segment that generates a second QC pass on the
#   classified trait data, now grouped by resolved taxon
#   genus. This catches within-genus inconsistencies that
#   pre-classification QC cannot detect (taxon_resolved only
#   exists after the classification join).
#
# The existing QC functions (generate_trait_qc_report,
#   validate_trait_corrections, apply_trait_corrections)
#   are reused: taxon_resolved is temporarily renamed to
#   taxon_name before each call and renamed back afterwards.
#
# Targets in execution order:
#   1. trait_qc_report_classified
#        per-domain and per-domain×genus stats + outlier summary;
#        writes Data/Temp/trait_qc_report_{date}.csv
#        (overwrites the pre-classification report if both targets
#        run on the same date);
#        creates
#        Data/Input/trait_manual_corrections_classified.csv
#        (header only) if it does not yet exist
#   2. file_trait_corrections_classified
#        tracks the corrections CSV (format = "file")
#   3. trait_corrections_classified_validated
#        GUARD: aborts when any row has CHECKED != TRUE;
#        requires human sign-off
#   4. data_traits_classified_corrected
#        corrections applied to classified trait data;
#        taxon_resolved column preserved

# HUMAN REVIEW REQUIRED BETWEEN TARGETS 2 AND 3:
#   After running targets 1-2, open
#     Data/Input/trait_manual_corrections_classified.csv,
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

pipe_segment_traits_qc_classified <-
  list(

    # ── 1. Generate QC report ───────────────────────────
    # Side effects:
    #   • writes Data/Temp/trait_qc_report_{date}.csv
    #     (per-domain×genus summary)
    #   • creates Data/Input/trait_manual_corrections_classified.csv
    #     (header only) if the file does not already exist
    # taxon_resolved is renamed to taxon_name before the call because
    # generate_trait_qc_report expects a taxon_name column.
    targets::tar_target(
      description = "Generate post-classification QC report by resolved taxon",
      name = trait_qc_report_classified,
      command = generate_trait_qc_report(
        data_traits = data_traits_classified |>
          dplyr::select(-"taxon_name") |>
          dplyr::rename(taxon_name = "taxon_resolved"),

        path_corrections = here::here(
          "Data/Input/trait_manual_corrections_classified.csv"
        )
      )
    ),

    # ── 2. Track corrections CSV ────────────────────────
    # format = "file" causes {targets} to detect file changes (e.g.
    # when a human opens the CSV and adds/modifies rows). Downstream
    # targets automatically become outdated when the file is edited.
    # trait_qc_report_classified is referenced to ensure the file is
    # created before this target attempts to track it.
    targets::tar_target(
      description = "Track classified trait corrections CSV for changes",
      name = file_trait_corrections_classified,
      command = {
        trait_qc_report_classified
        here::here(
          "Data/Input/trait_manual_corrections_classified.csv"
        )
      },
      format = "file"
    ),

    # ── 3. HUMAN REVIEW GUARD ───────────────────────────
    # Calls validate_trait_corrections(), which aborts with an
    # informative error when any row has CHECKED != TRUE.
    # The pipeline CANNOT proceed past this point until a human has:
    #   1. Reviewed Data/Temp/trait_qc_report_{date}.csv
    #   2. Filled in Data/Input/trait_manual_corrections_classified.csv
    #   3. Set CHECKED = TRUE for every row
    targets::tar_target(
      description = "GUARD: validate all classified corrections signed off",
      name = trait_corrections_classified_validated,
      command = validate_trait_corrections(
        path_corrections = file_trait_corrections_classified
      )
    ),

    # ── 4. Apply corrections ────────────────────────────
    # taxon_resolved is renamed to taxon_name before
    # apply_trait_corrections (which expects that column name) and
    # renamed back afterwards so downstream targets receive the
    # consistent taxon_resolved column.
    targets::tar_target(
      description = "Apply resolved-taxon corrections to classified data",
      name = data_traits_classified_corrected,
      command = {
        apply_trait_corrections(
          data_traits = data_traits_classified |>
            dplyr::select(-"taxon_name") |>
            dplyr::rename(taxon_name = "taxon_resolved"),
          data_corrections = trait_corrections_classified_validated
        ) |>
          dplyr::rename(taxon_resolved = "taxon_name")
      }
    )
  )
