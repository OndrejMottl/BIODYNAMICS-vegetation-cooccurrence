#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Trait analyses 03 — Build community taxa × traits table
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Filters outlier trait values, aggregates to one value per
#   taxon × trait domain, pivots to a wide community taxon ×
#   traits matrix, and reports coverage against the project_cz
#   community taxa.


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
# 1. Load classified trait data -----
#----------------------------------------------------------#

vec_classified_files <-
  base::list.files(
    path = path_output,
    pattern = "^data_traits_classified_.*\\.qs$",
    full.names = TRUE
  )

assertthat::assert_that(
  base::length(vec_classified_files) > 0,
  msg = paste0(
    "No 'data_traits_classified_*.qs' file found in '",
    path_output,
    "'. Run 02_Classify_and_align_taxa.R first."
  )
)

path_traits_classified <-
  base::sort(vec_classified_files) |>
  utils::tail(n = 1)

cli::cli_inform(
  c("i" = paste0("Loading: ", path_traits_classified))
)

data_traits_classified <-
  qs2::qs_read(
    file = path_traits_classified
  )

cli::cli_inform(
  c(
    "v" = paste0(
      "Loaded ",
      base::nrow(data_traits_classified),
      " classified trait records."
    )
  )
)


#----------------------------------------------------------#
# 2. Load community taxa -----
#----------------------------------------------------------#

set_store <-
  base::paste0(
    get_active_config("target_store"),
    "/pipeline_basic/"
  ) |>
  here::here()

assertthat::assert_that(
  base::dir.exists(set_store),
  msg = paste0(
    "Targets store not found: '", set_store,
    "'. Run the project_cz pipeline first."
  )
)

vec_community_taxa <-
  targets::tar_read(
    name = "data_community_classified",
    store = set_store
  ) |>
  dplyr::pull(taxon) |>
  base::unique() |>
  base::sort()

cli::cli_inform(
  c(
    "v" = paste0(
      "Community taxa: ",
      base::length(vec_community_taxa)
    )
  )
)


#----------------------------------------------------------#
# 3. Filter outliers -----
#----------------------------------------------------------#

# IQR-based outlier removal per taxon × trait_domain_name group.
# Groups where IQR == 0 (all values identical) are kept intact to
#   avoid discarding valid constant traits (see filter_trait_outliers).
cli::cli_inform(
  c("i" = "Filtering outliers (IQR method).")
)

data_traits_no_outliers <-
  filter_trait_outliers(
    data = data_traits_classified,
    trait_col = "trait_value",
    group_cols = "trait_domain_name",
    iqr_multiplier = 1.5
  ) |>
  filter_trait_outliers(
    trait_col = "trait_value",
    group_cols = base::c("trait_domain_name", "taxon_community"),
    iqr_multiplier = 1.5
  )


#----------------------------------------------------------#
# 4. Aggregate to one value per genus × trait domain -----
#----------------------------------------------------------#

# Median is used as the central tendency measure — it is more
#   robust than the mean for trait values that follow skewed
#   distributions (common in plant traits).
cli::cli_inform(
  c("i" = "Aggregating to median per taxon × trait domain.")
)

data_traits_aggregated <-
  aggregate_trait_values(
    data = data_traits_no_outliers,
    trait_col = "trait_value",
    group_cols = base::c("taxon_community", "trait_domain_name"),
    fn = "median"
  )

cli::cli_inform(
  c(
    "v" = paste0(
      "Aggregated: ",
      base::nrow(data_traits_aggregated),
      " taxon × trait domain combinations."
    )
  )
)


#----------------------------------------------------------#
# 5. Pivot to wide community taxa × traits table -----
#----------------------------------------------------------#

data_trait_table <-
  make_trait_table(
    data = data_traits_aggregated,
    taxon_col = "taxon_community",
    trait_col = "trait_domain_name",
    value_col = "trait_value_aggregated"
  ) |>
  dplyr::rename(
    taxon_name = taxon_community
  )

cli::cli_inform(
  c(
    "v" = paste0(
      "Trait table dimensions: ",
      base::nrow(data_trait_table),
      " community taxa × ",
      # -1 for the taxon_name column
      base::ncol(data_trait_table) - 1L,
      " trait domains."
    )
  )
)


#----------------------------------------------------------#
# 6. Check coverage -----
#----------------------------------------------------------#

cli::cli_inform(
  c("i" = "Checking trait coverage against community taxa.")
)

list_coverage <-
  check_trait_coverage(
    vec_community_taxa = vec_community_taxa,
    data_trait_table = data_trait_table
  )

base::cat("\n--- Coverage report ---\n")
base::cat(
  "Covered:", list_coverage[["n_covered"]],
  "/", list_coverage[["n_community_taxa"]],
  base::paste0("(", list_coverage[["pct_covered"]], "%)\n")
)

if (
  base::length(list_coverage[["vec_missing_taxa"]]) > 0
) {
  base::cat("Missing taxa (first 20):\n")
  print(
    utils::head(
      base::sort(list_coverage[["vec_missing_taxa"]]),
      20
    )
  )
}


#----------------------------------------------------------#
# 7. Save -----
#----------------------------------------------------------#

path_trait_table <-
  base::file.path(
    path_output,
    base::paste0(
      "data_trait_table_",
      base::format(base::Sys.Date(), "%Y-%m-%d"),
      ".qs"
    )
  )


qs2::qs_save(
  object = data_trait_table,
  file = path_trait_table
)

cli::cli_inform(
  c(
    "v" = paste0("Saved trait table: ", path_trait_table)
  )
)
