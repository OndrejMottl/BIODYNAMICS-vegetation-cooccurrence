#----------------------------------------------------------#
#
#                 Vegetation Co-occurrence
#
#         {targets} pipe: Trait QC and corrections
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Builds the raw-stage review queue, enforces complete human approval,
# applies exact selectors, and exposes a per-decision application audit.


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
    targets::tar_target(
      description = "Generate the durable raw trait QC report",
      name = list_trait_quality_control_report,
      command = write_trait_quality_control_report(
        data_trait_records = data_traits_raw,
        path_trait_corrections = here::here(
          "Data/Input/Trait_corrections/",
          "trait_review_decisions_raw.csv"
        ),
        path_trait_quality_control_report = here::here(
          "Outputs/Reports/Trait_corrections/raw/",
          "trait_quality_control_report_raw.csv"
        )
      )
    ),

    targets::tar_target(
      description = "Track the immutable review submission CSV",
      name = file_review_submission,
      command = here::here(
        "Data/Input/Trait_corrections/Review_submission/",
        "trait_manual_corrections.csv"
      ),
      format = "file"
    ),

    targets::tar_target(
      description = "Recover submitted taxon-domain review keys",
      name = data_review_submission_candidates,
      command = load_review_submission_candidates(
        path_review_submission = file_review_submission
      )
    ),

    targets::tar_target(
      description = "Build raw trait review candidates",
      name = data_trait_review_candidates_raw,
      command = build_trait_review_candidates(
        data_trait_records = data_traits_raw,
        data_source_candidates =
          data_review_submission_candidates,
        review_stage = "raw"
      )
    ),

    targets::tar_target(
      description = "Write the generated raw trait review queue",
      name = file_trait_review_candidates_raw,
      command = save_trait_review_candidates(
        data_trait_review_candidates =
          data_trait_review_candidates_raw,
        path_trait_review_candidates = here::here(
          "Data/Temp/Trait_corrections/raw/",
          "trait_review_candidates.csv"
        )
      ),
      format = "file"
    ),

    targets::tar_target(
      description = "Track raw trait review decisions",
      name = file_trait_review_decisions_raw,
      command = here::here(
        "Data/Input/Trait_corrections/",
        "trait_review_decisions_raw.csv"
      ),
      format = "file"
    ),

    targets::tar_target(
      description = "Load raw trait review decisions",
      name = data_trait_review_decisions_raw,
      command = load_trait_review_decisions(
        path_trait_review_decisions =
          file_trait_review_decisions_raw
      )
    ),

    targets::tar_target(
      description = "GUARD: validate complete raw trait review",
      name = data_trait_review_decisions_raw_validated,
      command = validate_trait_review_decisions(
        data_trait_review_decisions =
          data_trait_review_decisions_raw,
        data_trait_records = data_traits_raw,
        data_trait_review_candidates =
          data_trait_review_candidates_raw
      )
    ),

    targets::tar_target(
      description = "Apply approved raw trait review decisions",
      name = list_trait_review_application_raw,
      command = apply_trait_review_decisions(
        data_trait_records = data_traits_raw,
        data_trait_review_decisions =
          data_trait_review_decisions_raw_validated
      )
    ),

    targets::tar_target(
      description = "Expose corrected raw trait records",
      name = data_traits_corrected,
      command = purrr::chuck(
        list_trait_review_application_raw,
        "data_trait_records_corrected"
      )
    ),

    targets::tar_target(
      description = "Expose the raw per-decision application audit",
      name = data_trait_review_application_audit_raw,
      command = purrr::chuck(
        list_trait_review_application_raw,
        "data_correction_audit"
      )
    )
  )
