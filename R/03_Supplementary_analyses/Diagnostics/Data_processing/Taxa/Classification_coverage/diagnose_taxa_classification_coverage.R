#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#     Diagnose the classification coverage of VegVault taxa
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Read-only diagnostic of the VegVault 2.0.0 migration (Stage V, step V4).
# For each continental window of spatial_grid.csv and each data type
#   (fossil pollen, vegetation plots, traits), it lists the taxon names of
#   the database and reports how the project would classify them: from
#   the auxiliary table, from the taxospace cache, or not at all. Names
#   that neither covers would stop the classification checks of the
#   community and trait pipelines.
# It also lists the combined pollen types of VegVault 2.0.0 (for example
#   "Larix Pseudotsuga") found in the windows, with their placement in
#   VegVault 1.0.0 and 2.0.0 next to the project's current classification,
#   and proposes auxiliary-table rows: the family VegVault 2.0.0 assigns,
#   with no genus, or, when VegVault leaves the type unclassified because
#   its genera belong to different families, the lowest rank its parts
#   share (as the auxiliary table already does for such types).
# Inputs:
#   - Data/Input/VegVault.sqlite and Data/Input/VegVault_1.0.0.sqlite,
#     opened read-only;
#   - Data/Input/aux_classification_table.csv;
#   - Data/Input/vegvault_2_0_0_combined_pollen_types.csv;
#   - the taxospace cache in Data/Temp/taxospace, read only.
# Names the cache does not hold are looked up online with
#   load_taxa_classification(), cached in a separate folder under
#   Data/Temp/vegvault_2_migration/, so the pipeline cache stays as it is.
#   Run with the argument "no_lookup" to skip the lookup.
# Outputs (Documentation/Reports/Model_evaluation/
#   vegvault_2_migration_2026-11/):
#   - taxa_classification_coverage_summary.csv
#   - taxa_classification_names_to_resolve.csv
#   - taxa_combined_pollen_types.csv
#   - taxa_combined_pollen_types_auxiliary_rows_proposed.csv


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

suppressMessages(
  suppressWarnings(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)

vec_arguments <-
  base::commandArgs(trailingOnly = TRUE)

flag_lookup_uncached_names <-
  !"no_lookup" %in% vec_arguments

path_vegvault <-
  here::here("Data/Input/VegVault.sqlite")

path_vegvault_previous <-
  here::here("Data/Input/VegVault_1.0.0.sqlite")

file_spatial_grid <-
  here::here("Data/Input/spatial_grid.csv")

file_auxiliary_classification_table <-
  here::here("Data/Input/aux_classification_table.csv")

file_combined_pollen_types <-
  here::here("Data/Input/vegvault_2_0_0_combined_pollen_types.csv")

dir_taxa_classification_cache <-
  here::here("Data/Temp/taxospace")

dir_taxa_classification_lookup <-
  here::here("Data/Temp/vegvault_2_migration/taxospace_lookup")

dir_output <-
  here::here(
    "Documentation/Reports/Model_evaluation/vegvault_2_migration_2026-11"
  )

# Community data types and the main continental profiles whose
#   extraction settings they use. The regional and local units lie
#   inside the continental windows, so these windows cover all units.
vec_community_profiles <-
  base::c(
    fossil_pollen_archive = "project_paleo_spatial_continental",
    vegetation_plot = "project_modern_spatial_continental"
  )

vec_classification_ranks <-
  base::c(
    "kingdom", "phylum", "class", "order",
    "family", "genus", "species"
  )

assertthat::assert_that(
  base::file.exists(path_vegvault),
  base::file.exists(path_vegvault_previous),
  base::dir.exists(dir_taxa_classification_cache),
  base::dir.exists(dir_output),
  msg = stringr::str_c(
    "The VegVault files, the taxospace cache and the evidence folder ",
    "must exist."
  )
)


#----------------------------------------------------------#
# 1. Inputs -----
#----------------------------------------------------------#

data_vegvault_release <-
  load_vegvault_database_version(
    path_to_vegvault = path_vegvault,
    vegvault_version = load_config_value(
      config_id = "default",
      value = base::c("vegvault_data", "vegvault_version")
    )
  )

data_continental_windows <-
  readr::read_csv(
    file = file_spatial_grid,
    show_col_types = FALSE
  ) |>
  dplyr::filter(.data[["scale"]] == "continental") |>
  dplyr::select(
    "continent_id", "x_min", "x_max", "y_min", "y_max"
  )

data_community_queries <-
  tibble::tibble(
    data_type = base::names(vec_community_profiles),
    config_id = base::unname(vec_community_profiles)
  ) |>
  dplyr::mutate(
    age_lim = purrr::map(
      .x = config_id,
      .f = ~ load_config_value(
        config_id = .x,
        value = base::c("vegvault_data", "age_lim")
      )
    ),
    sel_dataset_type = purrr::map(
      .x = config_id,
      .f = ~ load_config_value(
        config_id = .x,
        value = base::c("vegvault_data", "sel_dataset_type")
      )
    )
  )

# Each profile must extract exactly the data type it stands for here.
assertthat::assert_that(
  base::identical(
    purrr::map_chr(
      .x = data_community_queries |>
        dplyr::pull("sel_dataset_type"),
      .f = ~ base::setdiff(.x, "gridpoints")
    ),
    data_community_queries |>
      dplyr::pull("data_type")
  ),
  msg = "A community profile extracts an unexpected dataset type."
)

vec_trait_domain_names <-
  load_trait_domain_names_from_vegvault(
    path_vegvault = path_vegvault,
    data_vegvault_release = data_vegvault_release
  )

data_auxiliary_classification_table <-
  load_auxiliary_classification_table(
    file_auxiliary_classification_table = file_auxiliary_classification_table
  )

data_combined_pollen_types <-
  readr::read_csv(
    file = file_combined_pollen_types,
    col_types = readr::cols(.default = readr::col_character())
  )

assertthat::assert_that(
  !base::anyDuplicated(
    dplyr::pull(data_combined_pollen_types, "taxon_name")
  ),
  msg = "The combined pollen type list holds duplicated names."
)


#----------------------------------------------------------#
# 2. Taxon names per window and data type -----
#----------------------------------------------------------#
# The queries use the project's own plan builder and the vaultkeepr calls
#   of the pipelines, but count the names lazily instead of collecting
#   every record. The community queries leave out the abiotic data:
#   vaultkeepr::get_abiotic_data() keeps every vegetation sample and only
#   adds the climate of its linked gridpoints, so it cannot change the
#   names, and over the continental fossil-pollen windows it makes the
#   query run for hours.


#--------------------------------------------------#
## 2.1. Community data -----
#--------------------------------------------------#

data_community_windows <-
  tidyr::expand_grid(
    data_continental_windows,
    data_community_queries |>
      dplyr::select("data_type", "age_lim")
  )

data_window_taxa_community <-
  base::seq_len(base::nrow(data_community_windows)) |>
  purrr::map(
    .f = ~ {
      data_window <-
        data_community_windows |>
        dplyr::slice(.x)

      sel_continent_id <-
        dplyr::pull(data_window, "continent_id")

      sel_data_type <-
        dplyr::pull(data_window, "data_type")

      cli::cli_inform(
        "Listing {sel_data_type} taxa of {sel_continent_id}."
      )

      plan_window <-
        build_vegvault_plan(
          path_to_vegvault = path_vegvault,
          data_vegvault_release = data_vegvault_release,
          x_lim = base::c(
            dplyr::pull(data_window, "x_min"),
            dplyr::pull(data_window, "x_max")
          ),
          y_lim = base::c(
            dplyr::pull(data_window, "y_min"),
            dplyr::pull(data_window, "y_max")
          ),
          age_lim = purrr::chuck(
            dplyr::pull(data_window, "age_lim"),
            1L
          ),
          sel_dataset_type = sel_data_type
        )

      # Same call as extract_data_from_vegvault(): original names.
      plan_window_taxa <-
        plan_window |>
        vaultkeepr::get_taxa(verbose = FALSE)

      connection_window <-
        purrr::chuck(plan_window_taxa, "db_con")

      # vaultkeepr::extract_data() drops records without a value (for
      #   example presence-only plot records), so their names never
      #   reach the classification.
      data_window_taxa <-
        purrr::chuck(plan_window_taxa, "data") |>
        dplyr::filter(!base::is.na(.data[["value"]])) |>
        dplyr::group_by(.data[["taxon_id"]]) |>
        dplyr::summarise(
          n_datasets = dplyr::n_distinct(.data[["dataset_id"]]),
          n_samples = dplyr::n_distinct(.data[["sample_id"]]),
          .groups = "drop"
        ) |>
        dplyr::left_join(
          dplyr::tbl(connection_window, "Taxa"),
          by = dplyr::join_by("taxon_id")
        ) |>
        dplyr::collect() |>
        dplyr::mutate(
          continent_id = sel_continent_id,
          data_type = sel_data_type
        )

      DBI::dbDisconnect(connection_window)

      data_window_taxa
    }
  ) |>
  purrr::list_rbind()


#--------------------------------------------------#
## 2.2. Trait data -----
#--------------------------------------------------#

data_window_taxa_traits <-
  base::seq_len(base::nrow(data_continental_windows)) |>
  purrr::map(
    .f = ~ {
      data_window <-
        data_continental_windows |>
        dplyr::slice(.x)

      sel_continent_id <-
        dplyr::pull(data_window, "continent_id")

      cli::cli_inform("Listing trait taxa of {sel_continent_id}.")

      # Same chain as load_trait_records_from_vegvault().
      plan_window_traits <-
        vaultkeepr::open_vault(path = path_vegvault) |>
        vaultkeepr::get_datasets() |>
        vaultkeepr::select_dataset_by_type(
          sel_dataset_type = "traits"
        ) |>
        vaultkeepr::select_dataset_by_geo(
          lat_lim = base::c(
            dplyr::pull(data_window, "y_min"),
            dplyr::pull(data_window, "y_max")
          ),
          long_lim = base::c(
            dplyr::pull(data_window, "x_min"),
            dplyr::pull(data_window, "x_max")
          ),
          verbose = FALSE,
          sel_dataset_type = "traits"
        ) |>
        vaultkeepr::get_samples() |>
        vaultkeepr::get_traits(
          classify_to = "original",
          verbose = FALSE
        ) |>
        vaultkeepr::select_traits_by_domain_name(
          sel_domain = vec_trait_domain_names
        )

      connection_window <-
        purrr::chuck(plan_window_traits, "db_con")

      # filter_complete_trait_records() keeps only values that exist
      data_window_taxa <-
        purrr::chuck(plan_window_traits, "data") |>
        dplyr::filter(!base::is.na(.data[["trait_value"]])) |>
        dplyr::group_by(.data[["taxon_id"]]) |>
        dplyr::summarise(
          n_datasets = dplyr::n_distinct(.data[["dataset_id"]]),
          n_samples = dplyr::n_distinct(.data[["sample_id"]]),
          .groups = "drop"
        ) |>
        dplyr::left_join(
          dplyr::tbl(connection_window, "Taxa"),
          by = dplyr::join_by("taxon_id")
        ) |>
        dplyr::collect() |>
        dplyr::mutate(
          continent_id = sel_continent_id,
          data_type = "traits"
        )

      DBI::dbDisconnect(connection_window)

      data_window_taxa
    }
  ) |>
  purrr::list_rbind()

data_window_taxa <-
  dplyr::bind_rows(
    data_window_taxa_community,
    data_window_taxa_traits
  ) |>
  dplyr::select(
    "continent_id", "data_type", "taxon_name",
    "n_datasets", "n_samples"
  )

assertthat::assert_that(
  !base::anyNA(dplyr::pull(data_window_taxa, "taxon_name")),
  msg = "A taxon id of the windows has no name in Taxa."
)


#----------------------------------------------------------#
# 3. Placements in VegVault 1.0.0 and 2.0.0 -----
#----------------------------------------------------------#

query_taxon_placement <-
  stringr::str_c(
    "SELECT t.taxon_name, s.taxon_name AS species, ",
    "g.taxon_name AS genus, f.taxon_name AS family ",
    "FROM Taxa t ",
    "LEFT JOIN TaxonClassification c ON t.taxon_id = c.taxon_id ",
    "LEFT JOIN Taxa s ON c.taxon_species = s.taxon_id ",
    "LEFT JOIN Taxa g ON c.taxon_genus = g.taxon_id ",
    "LEFT JOIN Taxa f ON c.taxon_family = f.taxon_id"
  )

list_vegvault_placements <-
  base::list(
    vegvault_1_0_0 = path_vegvault_previous,
    vegvault_2_0_0 = path_vegvault
  ) |>
  purrr::map(
    .f = ~ {
      connection_vegvault <-
        DBI::dbConnect(
          drv = RSQLite::SQLite(),
          dbname = .x,
          flags = RSQLite::SQLITE_RO
        )

      data_placement <-
        DBI::dbGetQuery(
          conn = connection_vegvault,
          statement = query_taxon_placement
        ) |>
        tibble::as_tibble()

      DBI::dbDisconnect(connection_vegvault)

      data_placement
    }
  )

vec_taxa_previous <-
  purrr::chuck(list_vegvault_placements, "vegvault_1_0_0") |>
  dplyr::pull("taxon_name")

data_combined_pollen_types_placed <-
  data_combined_pollen_types |>
  dplyr::left_join(
    purrr::chuck(list_vegvault_placements, "vegvault_1_0_0") |>
      dplyr::rename_with(
        .fn = ~ stringr::str_c("vegvault_1_0_0_", .x),
        .cols = -"taxon_name"
      ),
    by = dplyr::join_by("taxon_name"),
    multiple = "error"
  ) |>
  dplyr::inner_join(
    purrr::chuck(list_vegvault_placements, "vegvault_2_0_0") |>
      dplyr::rename_with(
        .fn = ~ stringr::str_c("vegvault_2_0_0_", .x),
        .cols = -"taxon_name"
      ),
    by = dplyr::join_by("taxon_name"),
    multiple = "error",
    # Every combined type must be a 2.0.0 name; other names are dropped.
    unmatched = base::c("error", "drop")
  )

# VegVault 2.0.0 places every combined type at a family or nowhere.
assertthat::assert_that(
  base::all(
    base::is.na(
      dplyr::pull(data_combined_pollen_types_placed, "vegvault_2_0_0_genus")
    )
  ),
  msg = "A combined pollen type has a genus in VegVault 2.0.0."
)


#----------------------------------------------------------#
# 4. Classification coverage -----
#----------------------------------------------------------#
# The checks mirror the pipelines: load_taxa_classification() per name,
#   build_classification_table(), the auxiliary table first in
#   build_combined_classification_table(), then select_unclassified_taxa().
# The families of the combined types are classified too, because the
#   proposed auxiliary rows take their higher ranks from them.

data_combined_pollen_types_found <-
  data_combined_pollen_types_placed |>
  dplyr::filter(
    .data[["taxon_name"]] %in% dplyr::pull(data_window_taxa, "taxon_name")
  )

vec_combined_pollen_type_families <-
  data_combined_pollen_types_found |>
  dplyr::pull("vegvault_2_0_0_family") |>
  stats::na.omit() |>
  base::as.character()

# The genera (or families) each combined type joins. A type without a
#   2.0.0 family is placed at the lowest rank all its parts share, as the
#   auxiliary table already does for such types.
data_combined_pollen_type_parts <-
  data_combined_pollen_types_found |>
  dplyr::select("taxon_name", "part_name" = "genera") |>
  tidyr::separate_longer_delim(
    cols = "part_name",
    delim = "/"
  )

vec_taxa_to_classify <-
  base::c(
    dplyr::pull(data_window_taxa, "taxon_name"),
    vec_combined_pollen_type_families,
    dplyr::pull(data_combined_pollen_type_parts, "part_name")
  ) |>
  base::unique() |>
  base::sort()

# Same cache file name as load_taxa_classification() builds for one taxon.
#   A cached file makes the pipeline skip the lookup. A file written for
#   another spelling with the same file name (for example "Quercus
#   petraea" for "Quercus Petraea" on Windows) is returned under the
#   requested name, so it covers that name too.
data_taxa_cache_status <-
  tibble::tibble(taxon_name = vec_taxa_to_classify) |>
  dplyr::mutate(
    file_cache = base::file.path(
      dir_taxa_classification_cache,
      stringr::str_c(
        stringr::str_replace_all(
          .data[["taxon_name"]],
          "[^[:alnum:]_]",
          "_"
        ),
        ".qs"
      )
    ),
    is_cached = base::file.exists(.data[["file_cache"]])
  )

vec_taxa_cached <-
  data_taxa_cache_status |>
  dplyr::filter(.data[["is_cached"]]) |>
  dplyr::pull("taxon_name")

list_taxa_classification_cached <-
  vec_taxa_cached |>
  purrr::map(
    .f = ~ load_taxa_classification(
      vec_taxa = .x,
      dir_taxa_classification_cache = dir_taxa_classification_cache
    )
  )

data_classification_cached <-
  build_classification_table(
    list_taxa_classifications = list_taxa_classification_cached
  )

data_combined_classification_cached <-
  build_combined_classification_table(
    data_classification_table = data_classification_cached,
    data_auxiliary_classification_table =
      data_auxiliary_classification_table
  )

vec_taxa_unclassified_cached <-
  select_unclassified_taxa(
    vec_community_taxa = vec_taxa_to_classify,
    data_classification_table = data_combined_classification_cached
  )

vec_taxa_to_look_up <-
  data_taxa_cache_status |>
  dplyr::filter(
    !.data[["is_cached"]],
    .data[["taxon_name"]] %in% vec_taxa_unclassified_cached
  ) |>
  dplyr::pull("taxon_name")

cli::cli_inform(
  base::c(
    "{base::length(vec_taxa_to_classify)} names to classify.",
    "i" = "{base::length(vec_taxa_unclassified_cached)} not covered by the
      auxiliary table or the cache.",
    "i" = "{base::length(vec_taxa_to_look_up)} of them have no cache file."
  )
)

list_taxa_classification_lookup <-
  if (
    flag_lookup_uncached_names &&
      base::length(vec_taxa_to_look_up) > 0L
  ) {
    vec_taxa_to_look_up |>
      purrr::map(
        .f = ~ load_taxa_classification(
          vec_taxa = .x,
          dir_taxa_classification_cache = dir_taxa_classification_lookup
        ),
        .progress = TRUE
      )
  } else {
    base::list()
  }

data_classification_all <-
  build_classification_table(
    list_taxa_classifications = base::c(
      list_taxa_classification_cached,
      list_taxa_classification_lookup
    )
  )

data_combined_classification <-
  build_combined_classification_table(
    data_classification_table = data_classification_all,
    data_auxiliary_classification_table =
      data_auxiliary_classification_table
  )

vec_taxa_in_cache_table <-
  dplyr::pull(data_classification_cached, "sel_name")

vec_taxa_in_lookup_table <-
  base::setdiff(
    dplyr::pull(data_classification_all, "sel_name"),
    vec_taxa_in_cache_table
  )

data_taxa_classification_status <-
  data_taxa_cache_status |>
  dplyr::mutate(
    classification_source = dplyr::case_when(
      .data[["taxon_name"]] %in%
        dplyr::pull(data_auxiliary_classification_table, "sel_name") ~
        "auxiliary_table",
      .data[["taxon_name"]] %in% vec_taxa_in_cache_table ~
        "taxospace_cache",
      .data[["is_cached"]] ~ "cached_without_ranks",
      .data[["taxon_name"]] %in% vec_taxa_in_lookup_table ~
        "taxospace_lookup",
      !flag_lookup_uncached_names ~ "not_looked_up",
      .default = "unclassified"
    ),
    in_vegvault_1_0_0 = .data[["taxon_name"]] %in% vec_taxa_previous
  ) |>
  dplyr::select(
    "taxon_name", "classification_source", "in_vegvault_1_0_0"
  ) |>
  dplyr::left_join(
    data_combined_classification |>
      dplyr::select(
        "sel_name",
        dplyr::any_of(vec_classification_ranks)
      ),
    by = dplyr::join_by("taxon_name" == "sel_name"),
    multiple = "error"
  )


#----------------------------------------------------------#
# 5. Combined pollen types -----
#----------------------------------------------------------#

data_window_taxa_by_name <-
  data_window_taxa |>
  dplyr::group_by(.data[["taxon_name"]]) |>
  dplyr::summarise(
    continent_ids = stringr::str_c(
      base::sort(base::unique(.data[["continent_id"]])),
      collapse = "|"
    ),
    data_types = stringr::str_c(
      base::sort(base::unique(.data[["data_type"]])),
      collapse = "|"
    ),
    n_datasets = base::sum(.data[["n_datasets"]]),
    n_samples = base::sum(.data[["n_samples"]]),
    .groups = "drop"
  )

data_family_ranks <-
  data_taxa_classification_status |>
  dplyr::filter(
    .data[["taxon_name"]] %in% vec_combined_pollen_type_families
  ) |>
  dplyr::select(
    "vegvault_2_0_0_family" = "taxon_name",
    "family_source" = "classification_source",
    "kingdom", "phylum", "class", "order",
    "family_classified" = "family"
  )

# A rank is shared when every part has the same name there and all
#   coarser ranks are shared too. An unclassified part shares nothing.
vec_shared_ranks <-
  vec_classification_ranks[
    base::seq_len(base::which(vec_classification_ranks == "family"))
  ]

data_combined_pollen_type_shared_ranks <-
  data_combined_pollen_type_parts |>
  dplyr::left_join(
    data_taxa_classification_status |>
      dplyr::select(
        "part_name" = "taxon_name",
        dplyr::all_of(vec_shared_ranks)
      ),
    by = dplyr::join_by("part_name"),
    multiple = "error"
  ) |>
  tidyr::pivot_longer(
    cols = dplyr::all_of(vec_shared_ranks),
    names_to = "rank",
    values_to = "name"
  ) |>
  dplyr::group_by(.data[["taxon_name"]], .data[["rank"]]) |>
  dplyr::summarise(
    shared_name = dplyr::if_else(
      !base::anyNA(.data[["name"]]) &&
        dplyr::n_distinct(.data[["name"]]) == 1L,
      dplyr::first(.data[["name"]]),
      NA_character_
    ),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    rank_order = base::match(.data[["rank"]], vec_shared_ranks)
  ) |>
  dplyr::arrange(.data[["taxon_name"]], .data[["rank_order"]]) |>
  dplyr::group_by(.data[["taxon_name"]]) |>
  dplyr::mutate(
    shared_name = dplyr::if_else(
      dplyr::cumall(!base::is.na(.data[["shared_name"]])),
      .data[["shared_name"]],
      NA_character_
    )
  ) |>
  dplyr::ungroup() |>
  dplyr::select("taxon_name", "rank", "shared_name") |>
  tidyr::pivot_wider(
    names_from = "rank",
    values_from = "shared_name",
    names_prefix = "shared_"
  )

# Only the types without a 2.0.0 family use the shared ranks.
vec_unclassified_parts <-
  data_combined_pollen_type_parts |>
  dplyr::filter(
    .data[["taxon_name"]] %in%
      (
        data_combined_pollen_types_found |>
          dplyr::filter(base::is.na(.data[["vegvault_2_0_0_family"]])) |>
          dplyr::pull("taxon_name")
      ),
    !.data[["part_name"]] %in%
      dplyr::pull(data_combined_classification, "sel_name")
  ) |>
  dplyr::pull("part_name") |>
  base::unique()

data_combined_pollen_types_in_windows_raw <-
  data_combined_pollen_types_placed |>
  dplyr::inner_join(
    data_window_taxa_by_name,
    by = dplyr::join_by("taxon_name"),
    multiple = "error"
  ) |>
  dplyr::left_join(
    data_taxa_classification_status |>
      dplyr::select(
        "taxon_name",
        "project_source" = "classification_source",
        dplyr::all_of(vec_classification_ranks)
      ) |>
      dplyr::rename_with(
        .fn = ~ stringr::str_c("project_", .x),
        .cols = dplyr::all_of(vec_classification_ranks)
      ),
    by = dplyr::join_by("taxon_name"),
    multiple = "error"
  ) |>
  dplyr::left_join(
    data_family_ranks,
    by = dplyr::join_by("vegvault_2_0_0_family"),
    multiple = "error"
  ) |>
  dplyr::left_join(
    data_combined_pollen_type_shared_ranks,
    by = dplyr::join_by("taxon_name"),
    multiple = "error"
  ) |>
  dplyr::mutate(
    has_auxiliary_row = .data[["taxon_name"]] %in%
      dplyr::pull(data_auxiliary_classification_table, "sel_name"),
    flag_family_placed = !base::is.na(.data[["vegvault_2_0_0_family"]]),
    # An existing auxiliary row of a type without a 2.0.0 family is a
    #   curated choice of the shared rank and stays as it is.
    proposal_rule = dplyr::case_when(
      .data[["flag_family_placed"]] ~ "vegvault_2_0_0_family",
      .data[["has_auxiliary_row"]] ~ "existing_auxiliary_row",
      .default = "lowest_shared_rank"
    ),
    proposed_kingdom = dplyr::case_when(
      .data[["proposal_rule"]] == "vegvault_2_0_0_family" ~
        .data[["kingdom"]],
      .data[["proposal_rule"]] == "existing_auxiliary_row" ~
        .data[["project_kingdom"]],
      .default = .data[["shared_kingdom"]]
    ),
    proposed_phylum = dplyr::case_when(
      .data[["proposal_rule"]] == "vegvault_2_0_0_family" ~
        .data[["phylum"]],
      .data[["proposal_rule"]] == "existing_auxiliary_row" ~
        .data[["project_phylum"]],
      .default = .data[["shared_phylum"]]
    ),
    proposed_class = dplyr::case_when(
      .data[["proposal_rule"]] == "vegvault_2_0_0_family" ~
        .data[["class"]],
      .data[["proposal_rule"]] == "existing_auxiliary_row" ~
        .data[["project_class"]],
      .default = .data[["shared_class"]]
    ),
    proposed_order = dplyr::case_when(
      .data[["proposal_rule"]] == "vegvault_2_0_0_family" ~
        .data[["order"]],
      .data[["proposal_rule"]] == "existing_auxiliary_row" ~
        .data[["project_order"]],
      .default = .data[["shared_order"]]
    ),
    proposed_family = dplyr::case_when(
      .data[["proposal_rule"]] == "vegvault_2_0_0_family" ~
        .data[["vegvault_2_0_0_family"]],
      .data[["proposal_rule"]] == "existing_auxiliary_row" ~
        .data[["project_family"]],
      .default = .data[["shared_family"]]
    ),
    proposed_genus = dplyr::if_else(
      .data[["proposal_rule"]] == "existing_auxiliary_row",
      .data[["project_genus"]],
      NA_character_
    ),
    proposed_species = dplyr::if_else(
      .data[["proposal_rule"]] == "existing_auxiliary_row",
      .data[["project_species"]],
      NA_character_
    )
  )

# A proposed row changes the classification when any rank differs from
#   the current one; two missing values count as equal.
data_combined_pollen_type_changes <-
  data_combined_pollen_types_in_windows_raw |>
  dplyr::select(
    "taxon_name",
    dplyr::all_of(stringr::str_c("project_", vec_classification_ranks)),
    dplyr::all_of(stringr::str_c("proposed_", vec_classification_ranks))
  ) |>
  tidyr::pivot_longer(
    cols = -"taxon_name",
    names_to = base::c("classification", "rank"),
    names_pattern = "^(project|proposed)_(.*)$",
    values_to = "name"
  ) |>
  tidyr::pivot_wider(
    names_from = "classification",
    values_from = "name"
  ) |>
  dplyr::mutate(
    rank_differs = dplyr::coalesce(
      .data[["project"]] != .data[["proposed"]],
      base::xor(
        base::is.na(.data[["project"]]),
        base::is.na(.data[["proposed"]])
      )
    )
  ) |>
  dplyr::group_by(.data[["taxon_name"]]) |>
  dplyr::summarise(
    changes_classification = base::any(.data[["rank_differs"]]),
    .groups = "drop"
  )

data_combined_pollen_types_in_windows <-
  data_combined_pollen_types_in_windows_raw |>
  dplyr::left_join(
    data_combined_pollen_type_changes,
    by = dplyr::join_by("taxon_name"),
    multiple = "error"
  ) |>
  dplyr::select(
    "taxon_name", "genera", "kind",
    "continent_ids", "data_types", "n_datasets", "n_samples",
    dplyr::starts_with("vegvault_1_0_0_"),
    dplyr::starts_with("vegvault_2_0_0_"),
    "project_source", "has_auxiliary_row",
    dplyr::all_of(stringr::str_c("project_", vec_classification_ranks)),
    "family_source", "family_classified",
    "changes_classification", "proposal_rule",
    dplyr::starts_with("proposed_")
  ) |>
  dplyr::arrange(.data[["taxon_name"]])

# A family placement needs the higher ranks of that family.
vec_families_without_ranks <-
  data_combined_pollen_types_in_windows |>
  dplyr::filter(!base::is.na(.data[["proposed_family"]])) |>
  dplyr::filter(
    base::is.na(.data[["proposed_kingdom"]]) |
      !dplyr::coalesce(
        .data[["family_classified"]] == .data[["proposed_family"]],
        FALSE
      )
  ) |>
  dplyr::pull("proposed_family") |>
  base::unique()

# Only rows that change the classification need to enter the table.
data_auxiliary_rows_proposed <-
  data_combined_pollen_types_in_windows |>
  dplyr::filter(.data[["changes_classification"]]) |>
  dplyr::select(
    "sel_name" = "taxon_name",
    dplyr::starts_with("proposed_")
  ) |>
  dplyr::rename_with(
    .fn = ~ stringr::str_remove(.x, "^proposed_"),
    .cols = dplyr::starts_with("proposed_")
  )


#----------------------------------------------------------#
# 6. Outputs -----
#----------------------------------------------------------#

data_coverage_summary <-
  data_window_taxa |>
  dplyr::left_join(
    data_taxa_classification_status |>
      dplyr::select(
        "taxon_name", "classification_source", "in_vegvault_1_0_0"
      ),
    by = dplyr::join_by("taxon_name"),
    multiple = "error"
  ) |>
  dplyr::group_by(
    .data[["continent_id"]],
    .data[["data_type"]],
    .data[["classification_source"]]
  ) |>
  dplyr::summarise(
    n_taxa = dplyr::n(),
    n_taxa_new_in_vegvault_2_0_0 = base::sum(!.data[["in_vegvault_1_0_0"]]),
    n_samples = base::sum(.data[["n_samples"]]),
    .groups = "drop"
  ) |>
  dplyr::arrange(
    .data[["continent_id"]],
    .data[["data_type"]],
    .data[["classification_source"]]
  )

data_names_to_resolve <-
  data_taxa_classification_status |>
  dplyr::filter(
    !.data[["classification_source"]] %in%
      base::c("auxiliary_table", "taxospace_cache")
  ) |>
  dplyr::inner_join(
    data_window_taxa_by_name,
    by = dplyr::join_by("taxon_name"),
    multiple = "error"
  ) |>
  dplyr::select(
    "taxon_name", "classification_source", "in_vegvault_1_0_0",
    "continent_ids", "data_types", "n_datasets", "n_samples",
    dplyr::any_of(vec_classification_ranks)
  ) |>
  dplyr::arrange(
    .data[["classification_source"]],
    dplyr::desc(.data[["n_samples"]]),
    .data[["taxon_name"]]
  )

readr::write_csv(
  x = data_coverage_summary,
  file = base::file.path(
    dir_output,
    "taxa_classification_coverage_summary.csv"
  ),
  na = ""
)

readr::write_csv(
  x = data_names_to_resolve,
  file = base::file.path(
    dir_output,
    "taxa_classification_names_to_resolve.csv"
  ),
  na = ""
)

readr::write_csv(
  x = data_combined_pollen_types_in_windows,
  file = base::file.path(dir_output, "taxa_combined_pollen_types.csv"),
  na = ""
)

readr::write_csv(
  x = data_auxiliary_rows_proposed,
  file = base::file.path(
    dir_output,
    "taxa_combined_pollen_types_auxiliary_rows_proposed.csv"
  ),
  na = "NA"
)


#----------------------------------------------------------#
# 7. Report -----
#----------------------------------------------------------#

data_coverage_summary |>
  base::print(n = Inf)

data_names_to_resolve |>
  dplyr::count(.data[["classification_source"]]) |>
  base::print()

data_combined_pollen_types_in_windows |>
  dplyr::count(
    .data[["kind"]],
    .data[["project_source"]],
    flag_family = !base::is.na(.data[["proposed_family"]])
  ) |>
  base::print()

cli::cli_inform(
  "Outputs written to {.path {dir_output}}."
)


#----------------------------------------------------------#
# 8. Checks -----
#----------------------------------------------------------#

if (
  base::length(vec_unclassified_parts) > 0L
) {
  cli::cli_abort(
    base::c(
      "Parts of combined pollen types without classification:
        {.val {vec_unclassified_parts}}.",
      "i" = "Their lowest shared ranks are incomplete.",
      "i" = "Run with the lookup, or classify the parts first."
    )
  )
}

if (
  base::length(vec_families_without_ranks) > 0L
) {
  cli::cli_abort(
    base::c(
      "Families of combined pollen types without higher ranks:
        {.val {vec_families_without_ranks}}.",
      "i" = "Their proposed auxiliary rows are incomplete.",
      "i" = "Run with the lookup, or classify the families first."
    )
  )
}
