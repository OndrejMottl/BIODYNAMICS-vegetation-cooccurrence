#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#   Trait analyses 02 â€” Classify and align trait taxa to community
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Classifies the genus extracted from each trait record through
#   the same taxospace + auxiliary-table pipeline used for the
#   community data. This correctly handles pollen morphotaxa that
#   are resolved only to family or higher rank (not to genus), in
#   addition to standard genus-level taxa.
#
# For each unique trait genus the taxospace API returns a full
#   taxonomic lineage (kingdom â†’ genus). The lineage is pivoted to
#   long format and matched against the community taxa. The finest
#   matching rank is selected so genus-level traits are preferentially
#   linked to genus-level community taxa, while higher-rank traits
#   fall back to family / order / class matches where available.
#
# Output column 'taxon_community' holds the community taxon name
#   that was matched, ready for joining with the wide trait table.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

Sys.setenv(R_CONFIG_ACTIVE = "project_cz")

path_output <-
  here::here("Data/Processed")


#----------------------------------------------------------#
# 1. Load raw trait data -----
#----------------------------------------------------------#

# Find the most recent traits_raw file
vec_traits_files <-
  base::list.files(
    path = path_output,
    pattern = "^data_traits_.*\\.qs$",
    full.names = TRUE
  )

assertthat::assert_that(
  base::length(vec_traits_files) > 0,
  msg = base::paste0(
    "No 'data_traits_*.qs' file found in '",
    path_output,
    "'. Run 01_Extract_trait_data.R first."
  )
)

path_traits <-
  base::sort(vec_traits_files) |>
  utils::tail(n = 1)

cli::cli_inform(
  c("i" = base::paste0("Loading: ", path_traits))
)

data_traits <-
  qs2::qs_read(
    file = path_traits
  )

cli::cli_inform(
  c(
    "v" = base::paste0(
      "Loaded ",
      base::nrow(data_traits),
      " trait records, ",
      base::length(base::unique(data_traits[["taxon_name"]])),
      " unique taxon names"
    )
  )
)


#----------------------------------------------------------#
# 2. Load community taxa from targets store -----
#----------------------------------------------------------#

# Community classified taxa (project_cz targets pipeline output).
# The 'taxon' column in the classified community data holds the
#   resolved taxon names (genus, family, or higher) used throughout
#   the project analyses.
set_store <-
  base::paste0(
    get_active_config("target_store"),
    "/pipeline_basic/"
  ) |>
  here::here()

assertthat::assert_that(
  base::dir.exists(set_store),
  msg = base::paste0(
    "Targets store not found: '", set_store,
    "'. Run the project_cz pipeline first."
  )
)

data_community_classified <-
  targets::tar_read(
    name = "data_community_classified",
    store = set_store
  )

vec_community_taxa <-
  data_community_classified |>
  dplyr::pull(taxon) |>
  base::unique() |>
  base::sort()

cli::cli_inform(
  c(
    "v" = base::paste0(
      "Community taxa loaded: ",
      base::length(vec_community_taxa),
      " unique taxa."
    )
  )
)


#----------------------------------------------------------#
# 3. Extract trait taxon names -----
#----------------------------------------------------------#

vec_unique_taxa <-
  data_traits |>
  dplyr::distinct(taxon_name) |>
  dplyr::pull(taxon_name) |>
  base::sort()

cli::cli_inform(
  c(
    "i" = base::paste0(
      "Classifying ",
      base::length(vec_unique_taxa),
      " unique trait taxa via taxospace."
    )
  )
)


#----------------------------------------------------------#
# 4. Classify trait taxa with taxospace -----
#----------------------------------------------------------#

# Use the same four-step classification pipeline as the community
#   data: taxospace API classification table -> auxiliary table ->
#   combined table. This returns a lineage (kingdom through species)
#   for each trait taxon.

list_classifications <-
  vec_unique_taxa |>
  purrr::map(
    .progress = TRUE,
    .f = ~ get_taxa_classification(.x)
  )

data_classification_table <-
  list_classifications |>
  purrr::compact() |>
  make_classification_table()

cli::cli_inform(
  c(
    "v" = base::paste0(
      "Classification complete: ",
      base::nrow(data_classification_table),
      " taxa classified."
    )
  )
)


#----------------------------------------------------------#
# 5. Match trait genera to community taxa -----
#----------------------------------------------------------#

# For each trait genus, identify which community taxon matches at
#   the finest available rank. Rank order goes from coarsest
#   (kingdom = 1) to finest (genus = 6). Species excluded because
#   trait taxa are species-level but community taxa are not.
#
# Steps:
#   1. Pivot classification columns to long format.
#   2. Keep only rows where the classification value is a known
#      community taxon.
#   3. For each trait genus select the single finest-rank match.

vec_ranks <-
  base::c("kingdom", "phylum", "class", "order", "family", "genus", "species")

data_classification_to_community <-
  data_classification_table |>
  tidyr::pivot_longer(
    cols = dplyr::all_of(vec_ranks),
    names_to = "rank",
    values_to = "taxon_community"
  ) |>
  dplyr::filter(
    !base::is.na(.data[["taxon_community"]])
  ) |>
  dplyr::filter(
    .data[["taxon_community"]] %in% vec_community_taxa
  ) |>
  dplyr::select(
    dplyr::all_of(c("sel_name", "taxon_community"))
  ) |>
  dplyr::arrange(taxon_community) |>
  dplyr::relocate(taxon_community) |>
  dplyr::rename(
    taxon_trait = sel_name
  )

n_taxa_matched <-
  data_classification_to_community |>
  dplyr::distinct(taxon_community) |>
  base::nrow()

cli::cli_inform(
  c(
    "v" = base::paste0(
      "Matched ",
      n_taxa_matched,
      " / ",
      base::length(vec_community_taxa),
      " trait taxa to a community taxon."
    )
  )
)


#----------------------------------------------------------#
# 6. Join community taxon back to trait records -----
#----------------------------------------------------------#

data_traits_classified <-
  data_traits |>
  dplyr::inner_join(
    y = data_classification_to_community,
    by = dplyr::join_by(taxon_name == taxon_trait),
    multiple = "all",
    relationship = "many-to-many"
  )

n_taxa_with_traits <-
  data_traits_classified |>
  dplyr::pull(taxon_community) |>
  base::unique() |>
  base::length()

n_taxa_missing_traits <-
  base::length(vec_community_taxa) - n_taxa_with_traits

cli::cli_inform(
  c(
    "v" = base::paste0(
      "Filtered to community-relevant taxa: ",
      base::nrow(data_traits_classified),
      " records across ",
      n_taxa_with_traits,
      " taxa."
    ),
    "!" = base::paste0(
      n_taxa_missing_traits,
      " community taxa have no trait records in VegVault."
    )
  )
)


#----------------------------------------------------------#
# 7. Report coverage summary -----
#----------------------------------------------------------#

base::cat("\n--- Taxa coverage summary ---\n")
base::cat(
  "Community taxa with trait data:", n_taxa_with_traits,
  "/", base::length(vec_community_taxa),
  base::paste0(
    "(", base::round(
      n_taxa_with_traits / base::length(vec_community_taxa) * 100,
      1
    ), "%)\n"
  )
)

base::cat("\n--- Trait record counts by domain (classified) ---\n")
data_traits_classified |>
  dplyr::count(.data[["trait_domain_name"]]) |>
  print()


#----------------------------------------------------------#
# 8. Save -----
#----------------------------------------------------------#

path_traits_classified <-
  base::file.path(
    path_output,
    base::paste0(
      "data_traits_classified_",
      base::format(base::Sys.Date(), "%Y-%m-%d"),
      ".qs"
    )
  )

qs2::qs_save(
  object = data_traits_classified,
  file = path_traits_classified
)

cli::cli_inform(
  c("v" = base::paste0("Saved: ", path_traits_classified))
)
