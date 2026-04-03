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
#   1. path_spatial_grid        – tracks spatial_grid.csv (format="file")
#   2. data_continental_rows    – filtered to scale == "continental"
#   3. vec_trait_domain_names   – all trait domains in VegVault
#   4. data_traits_continent    – per-continent extraction (dynamic branch)
#   5. data_traits_raw          – all continents combined
#
# NOTE: VegVault.sqlite is NOT tracked as format="file" to avoid
#   hashing a multi-GB file on every tar_make() call. Re-extraction
#   is triggered manually:
#     targets::tar_invalidate("data_traits_continent")


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

pipe_segment_trait_extraction <-
  list(

    # ── 1. Track spatial grid CSV ───────────────────────
    # format = "file" means the downstream target rebuilds whenever
    # the CSV is edited (e.g. a new continental row is added).
    targets::tar_target(
      description = "Track spatial_grid.csv for changes",
      name = path_spatial_grid,
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
      command = load_continental_rows(
        path_spatial_grid = path_spatial_grid
      )
    ),

    # ── 3. Discover trait domain names ─────────────────
    # Queries the TraitsDomain metadata table to get all domain
    # names currently in VegVault. This avoids hardcoding domain
    # strings in the pipeline.
    # NOT format="file" — re-run manually via tar_invalidate() if
    # the VegVault database is updated with new trait domains.
    targets::tar_target(
      description = "Discover all trait domain names from VegVault",
      name = vec_trait_domain_names,
      command = get_trait_domain_names_from_vegvault(
        path_to_vegvault = here::here(
          "Data/Input/VegVault.sqlite"
        ),
        verbose = TRUE
      )
    ),

    # ── 4. Extract traits per continent (dynamic branch) ─
    # One branch per row of data_continental_rows. Each branch
    # extracts, cleans, and joins taxon names for a single continent,
    # returning a clean tibble. Only one continent is in memory at a
    # time — the branch result is written to disk by {targets} before
    # the next branch begins.
    targets::tar_target(
      description = "Extract trait data for one continental unit",
      name = data_traits_continent,
      command = extract_and_clean_continent_traits(
        data_continental_rows = data_continental_rows,
        vec_trait_domain_names = vec_trait_domain_names,
        path_to_vegvault = here::here(
          "Data/Input/VegVault.sqlite"
        ),
        verbose = TRUE
      ),
      pattern = map(data_continental_rows)
    ),

    # ── 5. Combine all continent branches ───────────────
    targets::tar_target(
      description = "Combine all per-continent trait extractions",
      name = data_traits_raw,
      command = dplyr::bind_rows(data_traits_continent)
    )
  )
