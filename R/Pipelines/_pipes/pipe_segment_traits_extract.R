#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          {targets} pipe: Trait data extraction
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Pipe segment that discovers all continental rows from
#   spatial_grid.csv and extracts trait data from VegVault
#   for each continent as a separate, individually-cached
#   branch target.
#
# Targets in execution order:
#   0. config_vegvault_release  - VegVault release record (always cued)
#   1. file_spatial_grid        - tracks spatial_grid.csv (format="file")
#   2. data_continental_rows    - filtered to scale == "continental"
#   3. vec_trait_domain_names   - all trait domains in VegVault
#   4. data_traits_continent    - per-continent extraction (dynamic branch)
#   5. data_traits_raw          - untouched continents combined
#
# NOTE: VegVault.sqlite is NOT tracked as format="file" to avoid
#   hashing a multi-GB file on every tar_make() call. Instead, the
#   always-cued config_vegvault_release reads the release record from
#   the file, so replacing the database reruns the extraction targets.


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

pipe_segment_traits_extract <-
  list(

    # -- 0. VegVault release record ----------------------
    # Read on every build. The database is not a file target, so this
    # always-cued record is what makes a database swap visible: the
    # extraction targets below depend on it, and the store validator
    # reports a changed record as config_changed.
    targets::tar_target(
      description = "VegVault release record of the input database",
      name = "config_vegvault_release",
      command = load_vegvault_database_version(
        path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
        vegvault_version = load_active_config_value(
          value = c("vegvault_data", "vegvault_version")
        )
      ),
      cue = targets::tar_cue(mode = "always")
    ),

    # ── 1. Track spatial grid CSV ───────────────────────
    # format = "file" means the downstream target rebuilds whenever
    # the CSV is edited (e.g. a new continental row is added).
    targets::tar_target(
      description = "Track spatial_grid.csv for changes",
      name = file_spatial_grid,
      command = {
        here::here("Data/Input/spatial_grid.csv")
      },
      format = "file"
    ),

    # ── 2. Load continental rows ────────────────────────
    # Returns a data frame with one row per continent. This data frame
    # is used as the iteration variable for dynamic branching in
    # data_traits_continent below.
    targets::tar_target(
      description = "Load continental rows from spatial grid",
      name = data_continental_rows,
      command = load_continental_spatial_grid_rows(
        path_spatial_grid = file_spatial_grid
      )
    ),

    # ── 3. Discover trait domain names ─────────────────
    # Queries the TraitsDomain metadata table to get all domain
    # names currently in VegVault. This avoids hardcoding domain
    # strings in the pipeline.
    # Reruns when config_vegvault_release changes, that is when the
    # database is replaced.
    targets::tar_target(
      description = "Discover all trait domain names from VegVault",
      name = vec_trait_domain_names,
      command = load_trait_domain_names_from_vegvault(
        path_vegvault = here::here(
          "Data/Input/VegVault.sqlite"
        ),
        data_vegvault_release = config_vegvault_release,
        verbose = TRUE
      )
    ),

    # ── 4. Extract traits per continent (dynamic branch) ─
    # One branch per row of data_continental_rows. Each branch
    # extracts, cleans, and joins taxon names for a single continent,
    # returning a clean tibble. Only one continent is in memory at a
    # time — the branch result is written to disk by {targets} before
    # the next branch begins. scale_id is added so that downstream
    # targets can identify which continent each record belongs to
    # (required for per-continent FT clustering in Segment 6).
    targets::tar_target(
      description = "Extract trait data for one continental unit",
      name = data_traits_continent,
      command = {
        vec_scale_id <-
          dplyr::pull(data_continental_rows, "scale_id")

        load_continental_trait_records_from_vegvault(
          data_continental_unit = data_continental_rows,
          vec_trait_domain_names = vec_trait_domain_names,
          path_vegvault = here::here(
            "Data/Input/VegVault.sqlite"
          ),
          data_vegvault_release = config_vegvault_release,
          verbose = TRUE
        ) |>
          dplyr::mutate(
            scale_id = vec_scale_id
          )
      },
      pattern = map(data_continental_rows)
    ),

    # ── 5. Combine all continent branches ───────────────
    targets::tar_target(
      description = "Combine all per-continent trait extractions",
      name = data_traits_raw,
      command = dplyr::bind_rows(data_traits_continent)
    )
  )
