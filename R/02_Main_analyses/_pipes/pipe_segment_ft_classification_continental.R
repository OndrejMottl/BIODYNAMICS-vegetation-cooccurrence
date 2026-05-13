#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#  {targets} pipe: FT clustering for one continental unit
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Pipe segment that computes functional-type (FT) classification
#   for the single continental spatial unit of the current run.
#
# Unlike pipe_segment_traits_ft_clustering.R (which clustered
#   species-level taxa from the shared traits pipeline), this
#   segment first maps trait observations to community-taxon names
#   via build_community_taxon_trait_table(), ensuring genus- and
#   family-level pollen taxa are correctly covered.
#
# Upstream dependencies:
#   - data_community_classified (genus/family-classified community
#       data, from pipe_segment_community_prepare_paleo)
#   - data_combined_classification_table (raw community
#       classification, from pipe_segment_taxa_classification)
#   - config_data_processing
#       (taxonomic_resolution, minimal_proportion_of_pollen)
#   - config_min_n_taxa (minimum viable non-constant FT groups)
#   - data_traits_classified_corrected  \  read from
#   - data_combined_classification_table_traits ) traits store
#
# Output:
#   file_ft_classification_paleo — a format = "file" target pointing to
#     the saved .qs file in Data/Processed/Traits/. This target
#     name is the interface consumed by
#     pipe_segment_community_by_resolution_paleo (functional_type branch).
#
# The reusable factory is declared in:
#   _helpers/make_pipe_segment_ft_classification_continental.R


#----------------------------------------------------------#
# 1. Setup -----
#----------------------------------------------------------#

base::source(
  here::here(
    "R/02_Main_analyses/_pipes/_helpers/",
    "make_pipe_segment_ft_classification_continental.R"
  )
)


#----------------------------------------------------------#
# 2. Default pipe definition -----
#----------------------------------------------------------#

pipe_segment_ft_classification_continental <-
  make_pipe_segment_ft_classification_continental()
