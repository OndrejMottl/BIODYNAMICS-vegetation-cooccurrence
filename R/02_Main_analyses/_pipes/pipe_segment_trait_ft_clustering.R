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
#   automatically by maximising the average silhouette width over
#   k = 2 .. k_max. One .qs file per continent is saved to
#   Data/Processed/Traits/ and its path is tracked as a file target.
#
# Targets in execution order:
#   1. k_max_ft_clustering         – scalar integer k_max from config
#                                     (data_processing$ft_k_max,
#                                     default 10L); isolates config
#                                     reads from the hot branch loop
#   2. path_ft_classification      – dynamic branch over
#                                     data_continental_rows; one
#                                     branch per continent runs
#                                     save_ft_classification_for_continent()
#                                     and returns the path to the
#                                     dated .qs file (format = "file")
#
# The k_max parameter is taken from config.yml under
#   data_processing$ft_k_max (default: 10L).


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

pipe_segment_trait_ft_clustering <-
  list(

    # ── 1. Read k_max from config ───────────────────────
    # Extracting k_max as a dedicated scalar target makes the
    # config dependency explicit to {targets} and avoids repeating
    # the NULL-fallback logic inside the hot branch loop.
    targets::tar_target(
      description = "Read k_max for FT clustering from config",
      name = k_max_ft_clustering,
      command = {
        k_max_cfg <-
          purrr::pluck(
            get_active_config("data_processing"),
            "ft_k_max"
          )

        if (base::is.null(k_max_cfg)) 10L else base::as.integer(k_max_cfg)
      }
    ),

    # ── 2. Cluster FTs per continent, save .qs file ─────
    # Dynamic branch: one branch per row of data_continental_rows.
    # Each branch runs save_ft_classification_for_continent() for
    # its single continent, writes a dated .qs to
    # Data/Processed/Traits/, and returns the path string.
    # format = "file" makes {targets} track the hash of the saved
    # file; only the affected branch reruns when a continent's
    # trait data changes.
    targets::tar_target(
      description = "Cluster FTs for one continent and save dated .qs file",
      name = path_ft_classification,
      command = {
        continent_id_i <-
          dplyr::pull(data_continental_rows, "scale_id")

        save_ft_classification_for_continent(
          continent_id = continent_id_i,
          data_trait_table = data_trait_table,
          data_traits_classified_corrected =
            data_traits_classified_corrected,
          k_max = k_max_ft_clustering,
          verbose = TRUE
        )
      },
      pattern = map(data_continental_rows),
      format = "file"
    )
  )
