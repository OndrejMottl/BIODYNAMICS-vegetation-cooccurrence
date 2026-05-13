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
    output_target_name = "file_ft_classification_paleo",
    ft_classification_id_expr = quote(get_scale_id_from_store()),
    data_source_prefix = NULL,
    traits_store_expr = quote(
      here::here(
        config::get(
          value = "target_store",
          config = "project_traits_reference",
          use_parent = FALSE,
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
          name = check_ft_reference_classification_paleo,
          command = {
            path_processed <-
              here::here("Data/Processed/Traits")

            continent_id <-
              get_active_config("continent_id")

            file_name_base <-
              stringr::str_glue(
                "data_ft_classification_{continent_id}"
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
                  n_taxa_after_filters = NA_integer_,
                  min_n_taxa = config_min_n_taxa,
                  viable = FALSE,
                  error_message = NA_character_
                )
              )
            }

            reference_path <-
              base::file.path(path_processed, latest_file_name)

            data_ft_reference <-
              qs2::qs_read(reference_path)

            base::tryCatch(
              {
                data_reference_filtered <-
                  classify_to_functional_type(
                    data = data_community_classified,
                    data_ft_classification = data_ft_reference
                  ) |>
                  filter_rare_taxa(
                    minimal_proportion = config_minimal_proportion_of_pollen
                  ) |>
                  filter_community_by_n_cores(
                    min_n_cores = config_min_n_cores
                  ) |>
                  filter_by_n_samples(
                    min_n_samples = config_min_n_samples
                  ) |>
                  select_n_taxa(
                    n_taxa = config_number_of_taxa
                  )

                n_taxa_after_filters <-
                  data_reference_filtered |>
                  dplyr::pull("taxon") |>
                  unique() |>
                  length()

                tibble::tibble(
                  reference_available = TRUE,
                  reference_path = reference_path,
                  n_taxa_after_filters = n_taxa_after_filters,
                  min_n_taxa = config_min_n_taxa,
                  viable = n_taxa_after_filters >= config_min_n_taxa,
                  error_message = NA_character_
                )
              },
              error = function(e) {
                tibble::tibble(
                  reference_available = TRUE,
                  reference_path = reference_path,
                  n_taxa_after_filters = 0L,
                  min_n_taxa = config_min_n_taxa,
                  viable = FALSE,
                  error_message = conditionMessage(e)
                )
              }
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
          base::force(check_ft_reference_classification_paleo)

          save_ft_classification_for_continent(
            continent_id = .(ft_classification_id_expr),
            data_classification = ft_result_continental_unit,
            data_source_prefix = .(data_source_prefix),
            verbose = TRUE
          )
        }
      )
    } else {
      bquote(
        save_ft_classification_for_continent(
          continent_id = .(ft_classification_id_expr),
          data_classification = ft_result_continental_unit,
          data_source_prefix = .(data_source_prefix),
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
        name = ft_groups_max_continental,
        command = base::as.integer(
          get_config_value_with_fallback(
            config_section = "data_processing",
            config_key = "ft_groups_max",
            fallback_config = "project_traits_reference"
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
            fallback_config = "project_traits_reference"
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
          fallback_config = "project_traits_reference"
        ),
        cue = targets::tar_cue("always")
      ),
      targets::tar_target(
        description = "Read hclust linkage method for FT clustering from config",
        name = method_ft_continental,
        command = get_config_value_with_fallback(
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
        description = "Resolve the traits reference target store for FT clustering",
        name = "path_traits_reference_store",
        command = traits_store_expr,
        cue = targets::tar_cue(mode = "always")
      ),

      targets::tar_target(
        description = stringr::str_glue(
          "Load classified corrected traits from ",
          "shared traits pipeline store"
        ),
        name = data_traits_for_ft,
        command = targets::tar_read(
          data_traits_classified_corrected,
          store = path_traits_reference_store
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
          store = path_traits_reference_store
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
          taxonomic_resolution = config_data_processing |>
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
          minimal_proportion = config_minimal_proportion_of_pollen,
          min_n_taxa = config_min_n_taxa,
          min_n_cores = config_min_n_cores,
          min_n_samples = config_min_n_samples,
          error_family = config_error_family
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
      )
    )

  targets_ft_save <-
    base::list(
      # ── 8. Save classification and track file path ────────
      # Returns the path with format = "file" so {targets} hashes the
      # saved .qs file. Regional and local pipelines for the same
      # continent inherit this file via
      # get_functional_type_classification_path_from_store().
      # The target NAME file_ft_classification_paleo is the interface
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
