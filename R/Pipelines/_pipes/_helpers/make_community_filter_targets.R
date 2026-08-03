#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#        {targets} helper: Community filtering targets
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Factory for the shared post-classification community
#   filtering chain.


make_community_filter_targets <- function(input_name) {
  list(
    targets::tar_target_raw(
      description = "Filter community records below minimum proportion",
      name = "data_community_rare_filtered",
      command = bquote(
        filter_community_by_minimum_proportion(
          data_community = .(as.symbol(input_name)),
          minimum_proportion = purrr::chuck(
            config_data_processing,
            "minimal_proportion_of_pollen"
          )
        )
      )
    ),

    targets::tar_target_raw(
      description = "Filter taxa below the minimum core count",
      name = "data_community_filtered_cores",
      command = quote(
        filter_community_by_minimum_core_count(
          data_community = data_community_rare_filtered,
          minimum_core_count = purrr::chuck(
            config_data_processing,
            "min_n_cores"
          )
        )
      )
    ),

    targets::tar_target_raw(
      description = "Filter taxa below the minimum sample count",
      name = "data_community_filtered_samples",
      command = quote(
        filter_community_by_minimum_sample_count(
          data_community = data_community_filtered_cores,
          minimum_sample_count = purrr::chuck(
            config_data_processing,
            "min_n_samples"
          )
        )
      )
    ),

    targets::tar_target_raw(
      description = "Select top taxa by group occurrence",
      name = "data_community_analysis_subset",
      command = quote(
        select_top_taxa_by_group_occurrence(
          data_community = data_community_filtered_samples,
          maximum_taxon_count = purrr::chuck(
            config_data_processing,
            "number_of_taxa"
          )
        )
      )
    )
  )
}
