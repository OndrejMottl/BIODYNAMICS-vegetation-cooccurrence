#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#            {targets} pipe: Trait table assembly
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Pipe segment that aggregates trait values to one median per
#   taxon × trait domain and pivots to a wide taxa × traits matrix.
#
# The resulting data_trait_table is project-agnostic: it covers
#   all taxa present in VegVault. Individual projects join
#   against it downstream to check coverage for their own
#   community taxa.
#
# Targets in execution order:
#   1. list_trait_analysis_release - frozen records and evidence status
#   2. data_traits_analysis_release - records exposed for consumers
#   3. data_trait_analysis_release_status - six-domain release contract
#   4. list_trait_source_anomaly_diagnostics - source diagnostics
#   5. data_traits_aggregated - median per taxon and trait domain
#   6. data_trait_table - wide resolved-taxon by traits matrix


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

pipe_segment_traits_table <-
  list(

    # ── 1. Freeze the interim VegVault 1.0.0 analysis release ─
    targets::tar_target(
      description = paste(
        "Freeze corrected records behind the interim release contract"
      ),
      name = list_trait_analysis_release,
      command = build_trait_analysis_release(
        data_trait_records = data_traits_classified_corrected,
        vegvault_version = data_trait_source_scale_rules_validated |>
          dplyr::pull("vegvault_version") |>
          base::unique(),
        release_id = "vegvault_1_0_0_interim_2026_08_31",
        release_date = "2026-08-31"
      )
    ),

    # ── 2. Expose frozen records for downstream analysis ─
    targets::tar_target(
      description = "Expose frozen interim trait records",
      name = data_traits_analysis_release,
      command = purrr::chuck(
        list_trait_analysis_release,
        "data_trait_records"
      )
    ),

    # ── 3. Expose machine-readable domain evidence status ─
    targets::tar_target(
      description = "Expose interim trait-domain evidence status",
      name = data_trait_analysis_release_status,
      command = purrr::chuck(
        list_trait_analysis_release,
        "data_trait_domain_status"
      )
    ),

    # ── 4. Diagnose isolated source-taxon anomalies ─
    targets::tar_target(
      description = paste(
        "Diagnose residual source-taxon trait anomalies"
      ),
      name = list_trait_source_anomaly_diagnostics,
      command = diagnose_trait_source_anomalies(
        data_trait_records = data_traits_analysis_release |>
          dplyr::rename(taxon_name = "taxon_resolved")
      )
    ),

    # ── 5. Aggregate to median per taxon × trait domain ─
    # Median is used as the central tendency measure — it is more
    # robust than mean for skewed trait value distributions (common
    # in plant functional traits).
    targets::tar_target(
      description = "Aggregate trait values to median per taxon × domain",
      name = data_traits_aggregated,
      command = {
        aggregate_trait_values(
          data_trait_values = data_traits_analysis_release,
          trait_value_column = "trait_value",
          group_columns = base::c(
            "taxon_resolved",
            "trait_domain_name"
          ),
          aggregation_method = "median"
        )
      }
    ),

    # ── 6. Pivot to wide resolved-taxon × traits matrix ─
    # Each row = one taxon at the finest resolved rank (species
    # preferred, genus or coarser as fallback). Each column = one
    # trait domain. The taxon_name column is ready for direct
    # joining with community classified taxa from any project pipeline.
    targets::tar_target(
      description = "Build wide resolved-taxon × traits matrix",
      name = data_trait_table,
      command = {
        build_trait_table(
          data_aggregated_trait_values = data_traits_aggregated,
          taxon_column = "taxon_resolved",
          trait_domain_column = "trait_domain_name",
          trait_value_column = "trait_value_aggregated"
        ) |>
          dplyr::rename(
            taxon_name = "taxon_resolved"
          )
      }
    )

  )
