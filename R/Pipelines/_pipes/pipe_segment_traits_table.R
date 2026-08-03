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
#   1. data_traits_aggregated – median per taxon_resolved × trait domain
#   2. data_trait_table – wide resolved-taxon × traits matrix


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

    # ── 1. Aggregate to median per taxon × trait domain ─
    # Median is used as the central tendency measure — it is more
    # robust than mean for skewed trait value distributions (common
    # in plant functional traits).
    targets::tar_target(
      description = "Aggregate trait values to median per taxon × domain",
      name = data_traits_aggregated,
      command = {
        aggregate_trait_values(
          data_trait_values = data_traits_classified_corrected,
          trait_value_column = "trait_value",
          group_columns = base::c(
            "taxon_resolved",
            "trait_domain_name"
          ),
          aggregation_method = "median"
        )
      }
    ),

    # ── 2. Pivot to wide resolved-taxon × traits matrix ─
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
