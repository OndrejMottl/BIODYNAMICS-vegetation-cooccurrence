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
#   1. list_trait_analysis_release - frozen records, units and status
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

    # ── 1. Freeze the reviewed VegVault analysis release ─
    # release_id and release_date are set on the day the classified
    #   review is approved (vegvault_<version>_reviewed_<YYYY_MM_DD>);
    #   until then the NA values stop the release on purpose
    targets::tar_target(
      description = paste(
        "Freeze corrected records behind the reviewed release contract"
      ),
      name = list_trait_analysis_release,
      command = build_trait_analysis_release(
        data_trait_records = data_traits_classified_corrected,
        data_trait_domain_units = data_trait_domain_units_validated,
        vegvault_version = purrr::chuck(
          config_vegvault_release,
          "vegvault_version"
        ),
        release_id = NA_character_,
        release_date = NA_character_
      )
    ),

    # ── 2. Expose frozen records for downstream analysis ─
    targets::tar_target(
      description = "Expose frozen reviewed trait records",
      name = data_traits_analysis_release,
      command = purrr::chuck(
        list_trait_analysis_release,
        "data_trait_records"
      )
    ),

    # ── 3. Expose machine-readable domain evidence status ─
    targets::tar_target(
      description = "Expose reviewed trait-domain units and status",
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
