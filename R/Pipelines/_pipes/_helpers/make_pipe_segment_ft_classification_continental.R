#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     {targets} helper: FT classification pipe factory
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Factory for a pipe segment that computes functional-type (FT)
#   classification for the community taxa of the current run.


make_pipe_segment_ft_classification_continental <- function(
    output_target_name = "file_functional_type_classification_paleo",
    ft_classification_id_expr = quote(resolve_scale_id_from_store()),
    data_source_prefix = NULL,
    traits_store_expr = quote(
      here::here(
        load_config_value(
          config_id = "project_traits_reference",
          value = "target_store",
          file = here::here("config.yml")
        ),
        "pipeline_traits_reference"
      )
    ),
    include_reference_check = FALSE) {
  assertthat::assert_that(
    base::is.character(output_target_name),
    base::length(output_target_name) == 1L,
    base::nchar(output_target_name) > 0L,
    msg = "'output_target_name' must be a single non-empty character string."
  )

  assertthat::assert_that(
    base::is.language(ft_classification_id_expr),
    msg = "'ft_classification_id_expr' must be an unevaluated expression."
  )

  assertthat::assert_that(
    base::is.language(traits_store_expr),
    msg = "'traits_store_expr' must be an unevaluated expression."
  )

  if (
    !base::is.null(data_source_prefix)
  ) {
    assertthat::assert_that(
      base::is.character(data_source_prefix),
      base::length(data_source_prefix) == 1L,
      base::nchar(data_source_prefix) > 0L,
      msg = stringr::str_c(
        "'data_source_prefix' must be NULL or a single ",
        "non-empty character string."
      )
    )
  }

  assertthat::assert_that(
    base::is.logical(include_reference_check),
    base::length(include_reference_check) == 1L,
    msg = "'include_reference_check' must be a single logical value."
  )

  targets_reference_check <-
    if (
      base::isTRUE(include_reference_check)
    ) {
      base::list(
        targets::tar_target(
          description = stringr::str_glue(
            "Check whether the existing whole-continent FT file ",
            "is viable for this project testbed"
          ),
          name = data_functional_type_reference_validation_paleo,
          command = {
            path_processed <-
              here::here("Data/Processed/Traits")

            continent_id <-
              load_active_config_value("continent_id")

            file_name_base <-
              stringr::str_glue(
                "data_functional_type_classification_{continent_id}"
              )

            latest_file_name <-
              RUtilpol::get_latest_file_name(
                file_name = file_name_base,
                dir = path_processed,
                verbose = FALSE
              )

            if (
              base::is.na(latest_file_name)
            ) {
              return(
                tibble::tibble(
                  reference_available = FALSE,
                  reference_path = NA_character_,
                  taxon_count_after_filters = NA_integer_,
                  minimum_taxon_count = config_min_n_taxa,
                  viable = FALSE,
                  error_message = NA_character_
                )
              )
            }

            reference_path <-
              base::file.path(path_processed, latest_file_name)

            data_ft_reference <-
              qs2::qs_read(reference_path)

            build_reference_filter_failure <- function(condition) {
              tibble::tibble(
                reference_available = TRUE,
                reference_path = reference_path,
                taxon_count_after_filters = 0L,
                minimum_taxon_count = config_min_n_taxa,
                viable = FALSE,
                error_message = base::conditionMessage(condition)
              )
            }

            base::tryCatch(
              {
                data_reference_filtered <-
                  classify_to_functional_type(
                    data_source = data_community_classified,
                    data_functional_type_classification =
                      data_ft_reference
                  ) |>
                  filter_community_by_minimum_proportion(
                    minimum_proportion =
                      config_minimal_proportion_of_pollen
                  ) |>
                  filter_community_by_minimum_core_count(
                    minimum_core_count = config_min_n_cores
                  ) |>
                  filter_community_by_minimum_sample_count(
                    minimum_sample_count = config_min_n_samples
                  ) |>
                  select_top_taxa_by_group_occurrence(
                    maximum_taxon_count = config_number_of_taxa
                  )

                taxon_count_after_filters <-
                  data_reference_filtered |>
                  dplyr::pull("taxon") |>
                  base::unique() |>
                  base::length()

                tibble::tibble(
                  reference_available = TRUE,
                  reference_path = reference_path,
                  taxon_count_after_filters = taxon_count_after_filters,
                  minimum_taxon_count = config_min_n_taxa,
                  viable = taxon_count_after_filters >=
                    config_min_n_taxa,
                  error_message = NA_character_
                )
              },
              error = build_reference_filter_failure
            )
          }
        )
      )
    } else {
      base::list()
    }

  command_save_ft_classification <-
    if (
      base::isTRUE(include_reference_check)
    ) {
      bquote(
        {
          base::force(data_functional_type_reference_validation_paleo)

          save_continental_functional_type_classification(
            continent_id = .(ft_classification_id_expr),
            data_functional_type_classification =
              data_functional_type_classification_continental,
            classification_source_prefix = .(data_source_prefix),
            verbose = TRUE
          )
        }
      )
    } else {
      bquote(
        save_continental_functional_type_classification(
          continent_id = .(ft_classification_id_expr),
          data_functional_type_classification =
            data_functional_type_classification_continental,
          classification_source_prefix = .(data_source_prefix),
          verbose = TRUE
        )
      )
    }

  targets_ft_shared <-
    base::list(

      # ── 1. Read FT hyperparameters from config ────────────
      # Kept as separate always-cued targets so any config change is
      # immediately visible in tar_visnetwork() and the pipeline
      # re-runs only the targets that actually depend on the changed
      # value.
      targets::tar_target(
        description = "Read ft_groups_max for FT clustering from config",
        name = config_functional_type_group_count_max_continental,
        command = base::as.integer(
          load_config_value_with_fallback(
            config_section = "data_processing",
            config_key = "ft_groups_max",
            fallback_config = "project_traits_reference"
          )
        ),
        cue = targets::tar_cue("always")
      ),
      targets::tar_target(
        description = "Read ft_groups_min for FT clustering from config",
        name = config_functional_type_group_count_min_continental,
        command = base::as.integer(
          load_config_value_with_fallback(
            config_section = "data_processing",
            config_key = "ft_groups_min",
            fallback_config = "project_traits_reference"
          )
        ),
        cue = targets::tar_cue("always")
      ),
      targets::tar_target(
        description = "Read dissimilarity metric for FT clustering from config",
        name = config_functional_type_distance_metric_continental,
        command = load_config_value_with_fallback(
          config_section = "data_processing",
          config_key = "ft_metric",
          fallback_config = "project_traits_reference"
        ),
        cue = targets::tar_cue("always")
      ),
      targets::tar_target(
        description = paste(
          "Read hclust linkage method for FT clustering from config"
        ),
        name = config_functional_type_clustering_method_continental,
        command = load_config_value_with_fallback(
          config_section = "data_processing",
          config_key = "ft_method",
          fallback_config = "project_traits_reference"
        ),
        cue = targets::tar_cue("always")
      ),

      # ── 2. Load traits data from the shared traits store ──
      # The traits pipeline writes its outputs to the store resolved
      #   by path_traits_reference_store below.
      # We tar_read() directly from that store so the spatial pipeline
      # stays independent of the traits pipeline's data store path
      # and both pipelines can run in separate processes.
      targets::tar_target_raw(
        description = paste(
          "Resolve the traits reference target store for FT clustering"
        ),
        name = "path_traits_reference_store",
        command = traits_store_expr,
        cue = targets::tar_cue(mode = "always")
      ),

      targets::tar_target(
        description = stringr::str_glue(
          "Fingerprint classified corrected traits in the shared store"
        ),
        name = data_traits_classified_corrected_fingerprint,
        command = load_targets_target_fingerprints(
          store_path = path_traits_reference_store,
          target_names = "data_traits_classified_corrected"
        ),
        cue = targets::tar_cue(mode = "always")
      ),

      targets::tar_target(
        description = stringr::str_glue(
          "Fingerprint trait taxonomy in the shared store"
        ),
        name = data_trait_taxonomy_fingerprint,
        command = load_targets_target_fingerprints(
          store_path = path_traits_reference_store,
          target_names = "data_combined_classification_table_traits"
        ),
        cue = targets::tar_cue(mode = "always")
      ),

      targets::tar_target(
        description = stringr::str_glue(
          "Load classified corrected traits from ",
          "shared traits pipeline store"
        ),
        name = data_traits_for_functional_type_classification,
        command = load_targets_target_by_fingerprint(
          store_path = path_traits_reference_store,
          target_name = "data_traits_classified_corrected",
          data_fingerprint = data_traits_classified_corrected_fingerprint
        )
      ),
      targets::tar_target(
        description = stringr::str_glue(
          "Load trait classification table from ",
          "shared traits pipeline store"
        ),
        name = data_classification_table_for_functional_types,
        command = load_targets_target_by_fingerprint(
          store_path = path_traits_reference_store,
          target_name = "data_combined_classification_table_traits",
          data_fingerprint = data_trait_taxonomy_fingerprint
        )
      ),

      # ── 2b. Remap community classification table to classified names ─
      # data_combined_classification_table uses raw pollen names as
      #   sel_name (e.g., "Abies Alba", "Betulaceae Undiff",
      #   "ADIANTUM CAPILLUS-VENERIS"). After classify_taxonomic_
      #   resolution() those raw names become genus/family names
#   in the taxon column of data_community_classified ("Abies", "Betulaceae",
      #   "Adiantum"). The FT classification output taxon_name must
      #   match those classified names so classify_to_functional_type()
      #   can join correctly.
      targets::tar_target(
        description = stringr::str_glue(
          "Build classification table keyed by classified taxon names ",
          "for FT trait matching"
        ),
        name = data_community_classified_taxa_classification,
        command = prepare_classification_table_for_community_taxa(
          data_classification_table = data_combined_classification_table,
          data_community_classified = data_community_classified,
          vec_taxonomic_resolution = config_data_processing |>
            purrr::chuck("taxonomic_resolution")
        )
      ),

      # ── 3. Build community-taxon trait table ──────────────
      # Maps species-level trait observations to the CLASSIFIED
      # community taxon names (e.g., "Abies", "Betulaceae") using
      # resolve_classification_to_finest_rank(). Because
      # data_community_classified_taxa_classification uses classified
      # names as sel_name, the output taxon_name column matches
# the taxon column of data_community_classified exactly, so the join
      # in classify_to_functional_type() succeeds for all groups.
      targets::tar_target(
        description = stringr::str_glue(
          "Build wide trait table keyed by community taxon names ",
          "via taxonomic hierarchy"
        ),
        name = data_community_taxon_traits,
        command = build_community_taxon_trait_table(
          data_trait_records = data_traits_for_functional_type_classification |>
            dplyr::rename(taxon_name = "taxon_resolved"),
          data_trait_taxonomy = data_classification_table_for_functional_types,
          data_community_taxonomy =
            data_community_classified_taxa_classification,
          verbose = TRUE
        )
      ),

      # ── 4. Compute pairwise dissimilarity matrix ──────────
      targets::tar_target(
        description = "Compute dissimilarity matrix for FT clustering",
        name = data_functional_type_dissimilarity_continental,
        command = compute_trait_dissimilarity(
          data_trait_table = data_community_taxon_traits,
          distance_metric = config_functional_type_distance_metric_continental
        )
      ),

      # ── 5. Fit hierarchical clustering ───────────────────
      targets::tar_target(
        description = "Fit hierarchical clustering dendrogram for FTs",
        name = mod_functional_type_hierarchical_clustering_continental,
        command = fit_hierarchical_clustering(
          trait_dissimilarity = data_functional_type_dissimilarity_continental,
          clustering_method = config_functional_type_clustering_method_continental
        )
      ),

      # ── 6. Choose optimal group count via silhouette ─────
      targets::tar_target(
        description = stringr::str_glue(
          "Select optimal FT group count ",
          "by maximising average silhouette width"
        ),
        name = n_functional_type_groups_selected_continental,
        command = select_functional_type_group_count(
          trait_dissimilarity = data_functional_type_dissimilarity_continental,
          hierarchical_clustering = mod_functional_type_hierarchical_clustering_continental,
          functional_type_group_count_min =
            config_functional_type_group_count_min_continental,
          functional_type_group_count_max =
            config_functional_type_group_count_max_continental,
          data_community = data_community_classified,
          minimum_proportion = config_minimal_proportion_of_pollen,
          minimum_taxon_count = config_min_n_taxa,
          minimum_core_count = config_min_n_cores,
          minimum_sample_count = config_min_n_samples,
          error_family = config_error_family
        )
      ),

      # ── 7. Assign taxa to functional-type groups ─────────
      targets::tar_target(
        description = "Cluster community taxa into functional types",
        name = data_functional_type_classification_continental,
        command = assign_functional_type_clusters(
          data_trait_table = data_community_taxon_traits,
          trait_dissimilarity = data_functional_type_dissimilarity_continental,
          hierarchical_clustering = mod_functional_type_hierarchical_clustering_continental,
          functional_type_group_count =
            n_functional_type_groups_selected_continental,
          verbose = TRUE
        )
      )
    )

  targets_ft_save <-
    base::list(
      # ── 8. Save classification and track file path ────────
      # Returns the path with format = "file" so {targets} hashes the
      # saved .qs file. Regional and local pipelines for the same
      # continent inherit this file via
      # resolve_functional_type_classification_path_from_store().
      # The target NAME file_functional_type_classification_paleo is the interface
      # consumed by pipe_segment_community_by_resolution_paleo.
      targets::tar_target_raw(
        description = stringr::str_glue(
          "Save FT classification for this continental unit ",
          "to a dated .qs file and track its path"
        ),
        name = output_target_name,
        command = command_save_ft_classification,
        format = "file"
      )
    )

  base::c(
    targets_ft_shared,
    targets_reference_check,
    targets_ft_save
  )
}
