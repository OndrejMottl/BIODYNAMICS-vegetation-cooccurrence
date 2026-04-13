#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       {targets} pipe: Functional-type (FT) clustering
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Pipe segment that clusters taxa within each continental unit into
#   functional types (FTs). The workflow reads FT clustering settings
#   from the active configuration, prepares one trait matrix per
#   continent, computes pairwise dissimilarities, fits hierarchical
#   clustering, chooses the number of FT groups by maximising average
#   silhouette width, and saves one classified output file per
#   continent.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  verbose = FALSE
)

base::suppressMessages(
  base::suppressWarnings(
    base::source(
      here::here("R/___setup_project___.R")
    )
  )
)


#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

pipe_segment_trait_ft_clustering <-
  base::list(

    # ── 1. Read upper FT-group bound from config ───────
    # This scalar target defines the largest number of candidate
    # groups evaluated during silhouette-based model selection.
    # The value is read once and then reused by every continent branch.
    # If the active config does not define ft_groups_max, the helper
    # falls back to the traits config for shared FT defaults.
    targets::tar_target(
      description = "Read ft_groups_max for FT clustering from config",
      name = ft_groups_max_clustering,
      command = base::as.integer(
        get_config_value_with_fallback(
          config_section = "data_processing",
          config_key = "ft_groups_max",
          fallback_config = "traits"
        )
      ),
      cue = tar_cue("always")
    ),

    # ── 2. Read lower FT-group bound from config ───────
    # This scalar target defines the smallest number of candidate
    # groups considered during silhouette selection. It is kept as a
    # separate target so config-driven tuning is explicit in the graph.
    # If absent from the active config, the helper falls back to the
    # traits config for shared FT defaults.
    targets::tar_target(
      description = "Read ft_groups_min for FT clustering from config",
      name = ft_groups_min_clustering,
      command = base::as.integer(
        get_config_value_with_fallback(
          config_section = "data_processing",
          config_key = "ft_groups_min",
          fallback_config = "traits"
        )
      ),
      cue = tar_cue("always")
    ),

    # ── 3. Read dissimilarity metric from config ────────
    # This scalar target supplies the distance metric passed into
    # compute_dissimilarity_matrix() for every continent branch.
    # Keeping the metric in its own target makes it easy to see when a
    # graph invalidation is caused by a change in clustering settings.
    # If absent from the active config, the helper falls back to the
    # traits config for shared FT defaults.
    targets::tar_target(
      description = "Read dissimilarity metric for FT clustering from config",
      name = metric_ft_clustering,
      command = get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "ft_metric",
        fallback_config = "traits"
      ),
      cue = tar_cue("always")
    ),

    # ── 4. Read hclust linkage method from config ───────
    # This scalar target controls how the dendrogram is built from the
    # per-continent dissimilarity matrix. It is read once upstream so
    # every branch uses the same linkage rule. If missing from config,
    # the helper falls back to the traits config for shared FT defaults.
    targets::tar_target(
      description = "Read hclust method for FT clustering from config",
      name = method_ft_clustering,
      command = get_config_value_with_fallback(
        config_section = "data_processing",
        config_key = "ft_method",
        fallback_config = "traits"
      ),
      cue = tar_cue("always")
    ),

    # ── 5. Prepare continent-specific trait matrices ────
    # Dynamic branch: one branch per row of data_continental_rows.
    # Each branch extracts the taxa present in that continent,
    # joins them to the trait table, and returns the wide trait tibble
    # that will feed all downstream clustering steps for that branch.
    # All-NA taxa rows are removed here so later targets operate on the
    # final analysable trait matrix rather than repeating that cleanup.
    targets::tar_target(
      description = stringr::str_glue(
        "Filter trait table to taxa for one continent"
      ),
      name = data_continent_traits,
      command = prepare_continent_trait_data(
        continent_id = dplyr::pull(data_continental_rows, "scale_id"),
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      ),
      pattern = map(data_continental_rows)
    ),

    # ── 6. Compute per-continent dissimilarity matrices ─
    # Dynamic branch: one branch per element of data_continent_traits.
    # Each branch converts the prepared trait tibble into the distance
    # object used by hierarchical clustering and silhouette selection.
    # Inf values are converted to NA before daisy(), while NaN or other
    # non-finite outputs are replaced with 1.0 to preserve a usable
    # distance structure for taxa that would otherwise break the metric.
    targets::tar_target(
      description = stringr::str_glue(
        "Compute dissimilarity matrix for one continent"
      ),
      name = dist_continent,
      command = compute_dissimilarity_matrix(
        data = data_continent_traits,
        metric = metric_ft_clustering
      ),
      pattern = map(data_continent_traits)
    ),

    # ── 7. Fit per-continent hierarchical clustering ────
    # Dynamic branch: one branch per dist_continent element.
    # Each branch fits the dendrogram from the previously computed
    # distance object using the shared linkage method target.
    # The output is kept separate from FT assignment so the tree can be
    # reused both for silhouette-based group selection and final cuts.
    targets::tar_target(
      description = stringr::str_glue(
        "Fit hierarchical clustering for one continent"
      ),
      name = hclust_continent,
      command = fit_hclust(
        dist_mat = dist_continent,
        method = method_ft_clustering
      ),
      pattern = map(dist_continent)
    ),

    # ── 8. Choose FT-group count for each continent ─────
    # Dynamic branch: one branch per set of per-continent objects.
    # Each branch evaluates candidate cuts of the dendrogram and returns
    # the optimal number_of_ft_groups as a plain integer so the selected
    # value is directly inspectable in the target graph and metadata.
    # select_ft_groups_by_silhouette() clamps ft_groups_max to the
    # number of valid observations minus one, and then clamps
    # ft_groups_min if necessary, so small continent subsets still run.
    targets::tar_target(
      description = stringr::str_glue(
        "Select optimal number of FT groups via silhouette for one continent"
      ),
      name = ft_groups_chosen_continent,
      command = select_ft_groups_by_silhouette(
        dist_mat = dist_continent,
        hclust_obj = hclust_continent,
        ft_groups_min = ft_groups_min_clustering,
        ft_groups_max = ft_groups_max_clustering
      ),
      pattern = map(
        dist_continent,
        hclust_continent
      )
    ),

    # ── 9. Assign taxa to FT groups for each continent ──
    # Dynamic branch: one branch per set of per-continent objects.
    # This is the first target that returns the actual FT classification
    # tibble. It receives the already selected number_of_ft_groups,
    # cuts the dendrogram accordingly, and packages the assignments in a
    # tabular form that can be saved or inspected directly.
    targets::tar_target(
      description = stringr::str_glue(
        "Cluster taxa into FTs for one continent"
      ),
      name = ft_result_continent,
      command = cluster_functional_types(
        data = data_continent_traits,
        dist_mat = dist_continent,
        hclust_obj = hclust_continent,
        number_of_ft_groups = ft_groups_chosen_continent,
        verbose = TRUE
      ),
      pattern = map(
        data_continent_traits,
        dist_continent,
        hclust_continent,
        ft_groups_chosen_continent
      )
    ),

    # ── 10. Save one FT classification file per continent ─
    # Dynamic branch: one branch per continent. This target combines
    # the continent identifier with the pre-computed classification and
    # writes the dated .qs output into Data/Processed/Traits/.
    # Returning the path with format = "file" makes {targets} track the
    # saved file hash, so only continents with changed upstream inputs
    # rerun and overwrite their corresponding saved output.
    targets::tar_target(
      description = stringr::str_glue(
        "Save FT classification for one continent to .qs file"
      ),
      name = path_ft_classification,
      command = save_ft_classification_for_continent(
        continent_id = dplyr::pull(data_continental_rows, "scale_id"),
        data_classification = ft_result_continent,
        verbose = TRUE
      ),
      pattern = map(
        data_continental_rows,
        ft_result_continent
      ),
      format = "file"
    )
  )
