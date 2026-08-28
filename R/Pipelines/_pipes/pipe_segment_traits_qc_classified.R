#----------------------------------------------------------#
#
#                 Vegetation Co-occurrence
#
#      {targets} pipe: Post-classification trait QC
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Independently reviews resolved taxa after raw decisions are applied.
# The classified gate remains closed until every candidate is approved.


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
    targets::tar_target(
      description = "Generate the durable classified trait QC report",
      name = list_trait_quality_control_report_classified,
      command = write_trait_quality_control_report(
        data_trait_records = data_traits_classified |>
          dplyr::select(-"taxon_name") |>
          dplyr::rename(taxon_name = "taxon_resolved"),
        path_trait_corrections = here::here(
          "Data/Input/Trait_corrections/",
          "trait_review_decisions_classified.csv"
        ),
        path_trait_quality_control_report = here::here(
          "Outputs/Reports/Trait_corrections/classified/",
          "trait_quality_control_report_classified.csv"
        )
      )
    ),

    targets::tar_target(
      description = "Build classified trait review candidates",
      name = data_trait_review_candidates_classified,
      command = build_trait_review_candidates(
        data_trait_records = data_traits_classified |>
          dplyr::select(-"taxon_name") |>
          dplyr::rename(taxon_name = "taxon_resolved"),
        data_source_candidates =
          data_trait_review_decisions_classified |>
          dplyr::transmute(
            taxon_name = .data[["taxon_name"]],
            trait_domain_name = .data[["trait_domain_name"]],
            source_reference = stringr::str_c(
              "canonical_decision:",
              .data[["decision_id"]]
            )
          ),
        review_stage = "classified"
      )
    ),

    targets::tar_target(
      description = "Write the generated classified trait queue",
      name = file_trait_review_candidates_classified,
      command = save_trait_review_candidates(
        data_trait_review_candidates =
          data_trait_review_candidates_classified,
        path_trait_review_candidates = here::here(
          "Data/Temp/Trait_corrections/classified/",
          "trait_review_candidates.csv"
        )
      ),
      format = "file"
    ),

    targets::tar_target(
      description = "Track classified trait review decisions",
      name = file_trait_review_decisions_classified,
      command = here::here(
        "Data/Input/Trait_corrections/",
        "trait_review_decisions_classified.csv"
      ),
      format = "file"
    ),

    targets::tar_target(
      description = "Load classified trait review decisions",
      name = data_trait_review_decisions_classified,
      command = load_trait_review_decisions(
        path_trait_review_decisions =
          file_trait_review_decisions_classified
      )
    ),

    targets::tar_target(
      description = "GUARD: validate complete classified review",
      name = data_trait_review_decisions_classified_validated,
      command = validate_trait_review_decisions(
        data_trait_review_decisions =
          data_trait_review_decisions_classified,
        data_trait_records = data_traits_classified |>
          dplyr::select(-"taxon_name") |>
          dplyr::rename(taxon_name = "taxon_resolved"),
        data_trait_review_candidates =
          data_trait_review_candidates_classified,
        data_trait_source_scale_record_audit =
          data_trait_source_scale_record_audit
      )
    ),

    targets::tar_target(
      description = "Apply approved classified trait decisions",
      name = list_trait_review_application_classified,
      command = apply_trait_review_decisions(
        data_trait_records = data_traits_classified |>
          dplyr::select(-"taxon_name") |>
          dplyr::rename(taxon_name = "taxon_resolved"),
        data_trait_review_decisions =
          data_trait_review_decisions_classified_validated,
        data_trait_source_scale_record_audit =
          data_trait_source_scale_record_audit
      )
    ),

    targets::tar_target(
      description = "Expose corrected classified trait records",
      name = data_traits_classified_corrected,
      command = purrr::chuck(
        list_trait_review_application_classified,
        "data_trait_records_corrected"
      ) |>
        dplyr::rename(taxon_resolved = "taxon_name")
    ),

    targets::tar_target(
      description = "Expose classified application audit",
      name = data_trait_review_application_audit_classified,
      command = purrr::chuck(
        list_trait_review_application_classified,
        "data_correction_audit"
      )
    )
  )
