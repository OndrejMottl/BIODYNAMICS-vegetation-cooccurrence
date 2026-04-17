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
# Unlike pipe_segment_trait_ft_clustering.R (which clustered
#   species-level taxa from the shared traits pipeline), this
#   segment first maps trait observations to community-taxon names
#   via build_community_taxon_trait_table(), ensuring genus- and
#   family-level pollen taxa are correctly covered.
#
# Upstream dependencies:
#   - data_community_classified (genus/family-classified community
#       data, from pipe_segment_community_data)
#   - data_combined_classification_table (raw community
#       classification, from pipe_segment_community_data)
#   - config.data_processing
#       (taxonomic_resolution, minimal_proportion_of_pollen)
#   - config.min_n_taxa (minimum viable non-constant FT groups)
#   - data_traits_classified_corrected  \  read from
#   - data_combined_classification_table_traits ) traits store
#
# Output:
#   path_ft_classification — a format = "file" target pointing to
#     the saved .qs file in Data/Processed/Traits/. This target
#     name is the interface consumed by
#     pipe_segment_community_resolution (functional_type branch).
#
# Used only when R_CONFIG_ACTIVE contains "continental".
# Regional and local pipelines inherit the .qs file produced here
#   via get_functional_type_classification_path_from_store().


#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_ft_continental <-
  base::list(

    # ── 1. Read FT hyperparameters from config ────────────
    # Kept as separate always-cued targets so any config change is
    # immediately visible in tar_visnetwork() and the pipeline
    # re-runs only the targets that actually depend on the changed
    # value.

    targets::tar_target(
      description = "Read ft_groups_max for FT clustering from config",
      name = ft_groups_max_continental,
      command = base::as.integer(
        get_config_value_with_fallback(
          config_section = "data_processing",
          config_key = "ft_groups_max",
          fallback_config = "traits"
        )
      ),
      cue = targets::tar_cue("always")
    ),

    targets::tar_target(
      description = "Read ft_groups_min for FT clustering from config",
      name = ft_groups_min_continental,
      command = base::as.integer(
        get_config_value_with_fallback(
          config_section = "data_processing",
          config_key = "ft_groups_min",
          fallback_config = "traits"
        )
      ),
      cue = targets::tar_cue("always")
    ),

    targets::tar_target(
      description = "Read dissimilarity metric for FT clustering from config",
      name = metric_ft_continental,
      command = get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "ft_metric",
        fallback_config = "traits"
      ),
      cue = targets::tar_cue("always")
    ),

    targets::tar_target(
      description = "Read hclust linkage method for FT clustering from config",
      name = method_ft_continental,
      command = get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "ft_method",
        fallback_config = "traits"
      ),
      cue = targets::tar_cue("always")
    ),


    # ── 2. Load traits data from the shared traits store ──
    # The traits pipeline writes its outputs to
    #   Data/targets/traits/pipeline_traits/.
    # We tar_read() directly from that store so the spatial pipeline
    # stays independent of the traits pipeline's data store path
    # and both pipelines can run in separate processes.

    targets::tar_target(
      description = stringr::str_glue(
        "Load classified corrected traits from ",
        "shared traits pipeline store"
      ),
      name = data_traits_for_ft,
      command = targets::tar_read(
        data_traits_classified_corrected,
        store = here::here("Data/targets/traits/pipeline_traits")
      )
    ),

    targets::tar_target(
      description = stringr::str_glue(
        "Load trait classification table from ",
        "shared traits pipeline store"
      ),
      name = data_classification_table_for_ft,
      command = targets::tar_read(
        data_combined_classification_table_traits,
        store = here::here("Data/targets/traits/pipeline_traits")
      )
    ),


    # ── 2b. Remap community classification table to classified names ─
    # data_combined_classification_table uses raw pollen names as
    #   sel_name (e.g., "Abies Alba", "Betulaceae Undiff",
    #   "ADIANTUM CAPILLUS-VENERIS"). After classify_taxonomic_
    #   resolution() those raw names become genus/family names
    #   in data_community_classified$taxon ("Abies", "Betulaceae",
    #   "Adiantum"). The FT classification output taxon_name must
    #   match those classified names so classify_to_functional_type()
    #   can join correctly.
    targets::tar_target(
      description = stringr::str_glue(
        "Build classification table keyed by classified taxon names ",
        "for FT trait matching"
      ),
      name = data_community_classified_taxa_classification,
      command = remap_classification_table_by_community_taxa(
        data_classification_table = data_combined_classification_table,
        data_community_classified = data_community_classified,
        taxonomic_resolution = config.data_processing |>
          purrr::chuck("taxonomic_resolution")
      )
    ),


    # ── 3. Build community-taxon trait table ──────────────
    # Maps species-level trait observations to the CLASSIFIED
    # community taxon names (e.g., "Abies", "Betulaceae") using
    # resolve_classification_to_finest_rank(). Because
    # data_community_classified_taxa_classification uses classified
    # names as sel_name, the output taxon_name column matches
    # data_community_classified$taxon exactly, so the join
    # in classify_to_functional_type() succeeds for all groups.

    targets::tar_target(
      description = stringr::str_glue(
        "Build wide trait table keyed by community taxon names ",
        "via taxonomic hierarchy"
      ),
      name = data_community_taxon_traits,
      command = build_community_taxon_trait_table(
        data_traits = data_traits_for_ft |>
          dplyr::rename(taxon_name = "taxon_resolved"),
        data_classification_table = data_classification_table_for_ft,
        data_community_classification_table =
          data_community_classified_taxa_classification,
        verbose = TRUE
      )
    ),


    # ── 4. Compute pairwise dissimilarity matrix ──────────

    targets::tar_target(
      description = "Compute dissimilarity matrix for FT clustering",
      name = dist_ft_continental,
      command = compute_dissimilarity_matrix(
        data = data_community_taxon_traits,
        metric = metric_ft_continental
      )
    ),


    # ── 5. Fit hierarchical clustering ───────────────────

    targets::tar_target(
      description = "Fit hierarchical clustering dendrogram for FTs",
      name = hclust_ft_continental,
      command = fit_hclust(
        dist_mat = dist_ft_continental,
        method = method_ft_continental
      )
    ),


    # ── 6. Choose optimal group count via silhouette ─────

    targets::tar_target(
      description = stringr::str_glue(
        "Select optimal FT group count ",
        "by maximising average silhouette width"
      ),
      name = ft_groups_chosen_continental,
      command = select_ft_groups_by_silhouette(
        dist_mat = dist_ft_continental,
        hclust_obj = hclust_ft_continental,
        ft_groups_min = ft_groups_min_continental,
        ft_groups_max = ft_groups_max_continental,
        data_community = data_community_classified,
        minimal_proportion = purrr::chuck(
          config.data_processing,
          "minimal_proportion_of_pollen"
        ),
        min_n_taxa = config.min_n_taxa
      )
    ),


    # ── 7. Assign taxa to functional-type groups ─────────

    targets::tar_target(
      description = "Cluster community taxa into functional types",
      name = ft_result_continental_unit,
      command = cluster_functional_types(
        data = data_community_taxon_traits,
        dist_mat = dist_ft_continental,
        hclust_obj = hclust_ft_continental,
        number_of_ft_groups = ft_groups_chosen_continental,
        verbose = TRUE
      )
    ),


    # ── 8. Save classification and track file path ────────
    # Returns the path with format = "file" so {targets} hashes the
    # saved .qs file. Regional and local pipelines for the same
    # continent inherit this file via
    # get_functional_type_classification_path_from_store().
    # The target NAME path_ft_classification is the interface
    # consumed by pipe_segment_community_resolution.

    targets::tar_target(
      description = stringr::str_glue(
        "Save FT classification for this continental unit ",
        "to a dated .qs file and track its path"
      ),
      name = path_ft_classification,
      command = save_ft_classification_for_continent(
        continent_id = get_scale_id_from_store(),
        data_classification = ft_result_continental_unit,
        verbose = TRUE
      ),
      format = "file"
    )
  )
