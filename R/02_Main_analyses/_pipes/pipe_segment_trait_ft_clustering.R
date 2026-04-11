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
# Pipe segment that clusters all taxa present in each continental
#   unit into functional types (FTs) using Gower distance and
#   Ward D2 hierarchical clustering. The number of FTs is chosen
#   by maximising the average silhouette width (select_k_by_silhouette);
#   the assignment step (cluster_functional_types) then receives k
#   directly. One .qs file per continent is saved to
#   Data/Processed/Traits/ and its path is tracked as a file target.
#
# Targets in execution order:
#   1. k_max_ft_clustering       – scalar integer k_max from config
#                                   (traits > data_processing$ft_k_max,
#                                   default 10L)
#   2. metric_ft_clustering      – scalar character metric from config
#                                   (traits > data_processing$ft_metric,
#                                   default "gower")
#   3. method_ft_clustering      – scalar character method from config
#                                   (traits > data_processing$ft_method,
#                                   default "ward.D2")
#   4. data_continent_traits     – dynamic branch over
#                                   data_continental_rows; one branch
#                                   per continent filters the trait
#                                   table to continent taxa
#   5. dist_gower_continent      – dynamic branch over
#                                   data_continent_traits; one branch
#                                   per continent computes the Gower
#                                   dissimilarity matrix
#   6. hclust_continent          – dynamic branch over
#                                   dist_gower_continent; one branch
#                                   per continent fits the
#                                   hierarchical clustering object
#   7. k_chosen_continent        – dynamic branch over
#                                   dist_gower_continent and
#                                   hclust_continent; one branch per
#                                   continent calls
#                                   select_k_by_silhouette() and
#                                   returns the optimal k as a plain
#                                   integer — directly inspectable;
#                                   k_max is clamped inside the
#                                   function when needed
#   8. ft_result_continent       – dynamic branch over
#                                   data_continent_traits,
#                                   dist_gower_continent,
#                                   hclust_continent, and
#                                   k_chosen_continent; one branch per
#                                   continent calls
#                                   cluster_functional_types() with
#                                   a specific k and returns the
#                                   classification tibble directly
#   9. path_ft_classification    – dynamic branch over
#                                   data_continental_rows and
#                                   ft_result_continent; one branch
#                                   per continent calls
#                                   save_ft_classification_for_continent()
#                                   and returns the path to the
#                                   dated .qs file (format = "file")
#
# All three tunable parameters (k_max, metric, method) are read
# from config.yml under traits > data_processing (ft_k_max /
# ft_metric / ft_method). For non-traits configs the pipe falls back
# to the hardcoded defaults (k_max=10, metric="gower",
# method="ward.D2").


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
  list(

    # ── 1. Read k_max from config ───────────────────────
    targets::tar_target(
      description = "Read k_max for FT clustering from config",
      name = k_max_ft_clustering,
      command = {
        k_max_config <-
          purrr::pluck(
            get_active_config("data_processing"),
            "ft_k_max"
          )

        if (base::is.null(k_max_config)) 10L else base::as.integer(k_max_config)
      }
    ),

    # ── 2. Read metric from config ──────────────────────
    targets::tar_target(
      description = "Read Gower metric for FT clustering from config",
      name = metric_ft_clustering,
      command = {
        metric_config <-
          purrr::pluck(
            get_active_config("data_processing"),
            "ft_metric"
          )

        if (base::is.null(metric_config)) "gower" else metric_config
      }
    ),

    # ── 3. Read linkage method from config ──────────────
    targets::tar_target(
      description = "Read hclust method for FT clustering from config",
      name = method_ft_clustering,
      command = {
        method_config <-
          purrr::pluck(
            get_active_config("data_processing"),
            "ft_method"
          )

        if (base::is.null(method_config)) "ward.D2" else method_config
      }
    ),

    # ── 4. Filter trait table to continent taxa ─────────
    # Dynamic branch: one branch per row of data_continental_rows.
    # Each branch produces a wide tibble of trait data for its
    # specific continent, with all-NA rows already removed.
    targets::tar_target(
      description = stringr::str_glue(
        "Filter trait table to taxa for one continent"
      ),
      name = data_continent_traits,
      command = {
        continent_id_i <-
          dplyr::pull(data_continental_rows, "scale_id")

        prepare_continent_trait_data(
          continent_id = continent_id_i,
          data_trait_table = data_trait_table,
          data_traits_classified_corrected =
            data_traits_classified_corrected
        )
      },
      pattern = map(data_continental_rows)
    ),

    # ── 5. Compute Gower dissimilarity matrix ───────────
    # Dynamic branch: one branch per element of data_continent_traits.
    # Inf values are replaced with NA before daisy(); NaN/non-finite
    # results are replaced with 1.0 (fully dissimilar).
    targets::tar_target(
      description = stringr::str_glue(
        "Compute Gower distance matrix for one continent"
      ),
      name = dist_gower_continent,
      command = {
        compute_gower_distance(
          data = data_continent_traits,
          metric = metric_ft_clustering
        )
      },
      pattern = map(data_continent_traits)
    ),

    # ── 6. Fit hierarchical clustering ──────────────────
    # Dynamic branch: one branch per dist_gower_continent element.
    # Thin wrapper over stats::hclust().
    targets::tar_target(
      description = stringr::str_glue(
        "Fit hierarchical clustering for one continent"
      ),
      name = hclust_continent,
      command = {
        fit_hclust(
          dist_gower = dist_gower_continent,
          method = method_ft_clustering
        )
      },
      pattern = map(dist_gower_continent)
    ),

    # ── 7. Select optimal k per continent ───────────────
    # Dynamic branch: one branch per set of per-continent objects.
    # k_max is clamped inside select_k_by_silhouette() to
    # n_observations - 1 when necessary.
    targets::tar_target(
      description = stringr::str_glue(
        "Select optimal k via silhouette for one continent"
      ),
      name = k_chosen_continent,
      command = {
        select_k_by_silhouette(
          dist_gower = dist_gower_continent,
          hclust_obj = hclust_continent,
          k_max = k_max_ft_clustering
        )
      },
      pattern = map(
        dist_gower_continent,
        hclust_continent
      )
    ),

    # ── 8. Cluster FTs per continent ────────────────────
    # Dynamic branch: one branch per set of per-continent objects.
    # Receives the predetermined k from k_chosen_continent and
    # returns the classification tibble directly.
    targets::tar_target(
      description = stringr::str_glue(
        "Cluster taxa into FTs for one continent"
      ),
      name = ft_result_continent,
      command = {
        cluster_functional_types(
          data = data_continent_traits,
          dist_gower = dist_gower_continent,
          hclust_obj = hclust_continent,
          k = k_chosen_continent,
          verbose = TRUE
        )
      },
      pattern = map(
        data_continent_traits,
        dist_gower_continent,
        hclust_continent,
        k_chosen_continent
      )
    ),

    # ── 9. Save classification per continent ────────────
    # Dynamic branch: one branch per continent. Passes the
    # pre-computed classification tibble to
    # save_ft_classification_for_continent(); returns the path.
    # format = "file" makes {targets} track the hash of the saved
    # file; only the affected branch reruns when inputs change.
    targets::tar_target(
      description = stringr::str_glue(
        "Save FT classification for one continent to .qs file"
      ),
      name = path_ft_classification,
      command = {
        continent_id_i <-
          dplyr::pull(data_continental_rows, "scale_id")

        save_ft_classification_for_continent(
          continent_id = continent_id_i,
          data_classification = ft_result_continent,
          verbose = TRUE
        )
      },
      pattern = map(
        data_continental_rows,
        ft_result_continent
      ),
      format = "file"
    )
  )
