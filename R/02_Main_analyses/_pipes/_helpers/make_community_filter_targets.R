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
      description = "Filter rare taxa from community data",
      name = "data_community_rare_filtered",
      command = bquote(
        filter_rare_taxa(
          data = .(as.symbol(input_name)),
          minimal_proportion = purrr::chuck(
            config_data_processing,
            "minimal_proportion_of_pollen"
          )
        )
      )
    ),

    targets::tar_target_raw(
      description = "Filter taxa not present in enough cores",
      name = "data_community_filtered_cores",
      command = quote(
        filter_community_by_n_cores(
          data = data_community_rare_filtered,
          min_n_cores = purrr::chuck(config_data_processing, "min_n_cores")
        )
      )
    ),

    targets::tar_target_raw(
      description = "Filter taxa not present in enough samples",
      name = "data_community_filtered_samples",
      command = quote(
        filter_by_n_samples(
          data = data_community_filtered_cores,
          min_n_samples = purrr::chuck(
            config_data_processing,
            "min_n_samples"
          )
        )
      )
    ),

    targets::tar_target_raw(
      description = "Select number of taxa to include",
      name = "data_community_analysis_subset",
      command = quote(
        select_n_taxa(
          data = data_community_filtered_samples,
          n_taxa = purrr::chuck(config_data_processing, "number_of_taxa")
        )
      )
    )
  )
}
