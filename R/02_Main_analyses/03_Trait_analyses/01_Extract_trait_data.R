#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#       Trait analyses 01 — Extract trait data from VegVault
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Extracts functional trait data from the VegVault SQLite database
#   for two trait domains:
#     - "Leaf mass per area" (LMA; inversely related to SLA)
#     - "Plant heigh" (plant height; note typo is in the database)
#
# Geographic filtering is applied at the continental level: the
#   project bounding box (from the active config) is used to
#   auto-detect the matching continental row in spatial_grid.csv,
#   and the continental bounds are passed to the extractor so that
#   VegVault only returns datasets from the relevant continent.
#
# Note: extraction is slow (15–60 min) due to the large VegVault
#   file. The .qs output is the persistent cache; subsequent scripts
#   (02, 03) load it directly and do NOT re-run extraction.


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

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)


#----------------------------------------------------------#
# 1. Detect continental bounding box -----
#----------------------------------------------------------#

# Load the spatial grid to find the continental row that contains
#   the project's bounding box. Containment (not overlap) is used
#   so that the selected continent unambiguously encloses the
#   project area.
data_spatial_grid <-
  readr::read_csv(
    file = here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  )

vegvault_config <-
  get_active_config("vegvault_data")

vec_x_lim_project <-
  vegvault_config[["x_lim"]]

vec_y_lim_project <-
  vegvault_config[["y_lim"]]

data_continental_row <-
  data_spatial_grid |>
  dplyr::filter(
    .data[["scale"]] == "continental"
  ) |>
  dplyr::filter(
    .data[["x_min"]] <= base::min(vec_x_lim_project),
    .data[["x_max"]] >= base::max(vec_x_lim_project),
    .data[["y_min"]] <= base::min(vec_y_lim_project),
    .data[["y_max"]] >= base::max(vec_y_lim_project)
  )

assertthat::assert_that(
  base::nrow(data_continental_row) == 1L,
  msg = base::paste0(
    "Expected exactly one continental row to contain ",
    "the project bounding box, but found ",
    base::nrow(data_continental_row),
    ". Check spatial_grid.csv and config x_lim/y_lim."
  )
)

vec_continental_x_lim <-
  base::c(
    data_continental_row[["x_min"]],
    data_continental_row[["x_max"]]
  )

vec_continental_y_lim <-
  base::c(
    data_continental_row[["y_min"]],
    data_continental_row[["y_max"]]
  )

cli::cli_inform(
  c(
    "v" = base::paste0(
      "Continental bounds detected: ",
      "lon [", vec_continental_x_lim[1], ", ",
      vec_continental_x_lim[2], "], ",
      "lat [", vec_continental_y_lim[1], ", ",
      vec_continental_y_lim[2], "]."
    )
  )
)


#----------------------------------------------------------#
# 2. Define trait domains -----
#----------------------------------------------------------#

# Exact domain name strings as stored in the VegVault SQLite database.
# Note on "Plant heigh": the trailing 't' is missing in the database
#   — this is a known typo in the source data.
# Note on "Leaf mass per area": this is LMA (leaf mass per area),
#   which is the inverse of SLA (specific leaf area). The two traits
#   measure the same biological property from different angles.
sel_trait_domain_names <-
  base::c("Leaf mass per area", "Plant heigh")


#----------------------------------------------------------#
# 3. Extract traits from VegVault -----
#----------------------------------------------------------#

cli::cli_inform(
  c(
    "i" = "Starting VegVault trait extraction.",
    " " = paste0(
      "Domains: ",
      base::paste(sel_trait_domain_names, collapse = " | ")
    ),
    " " = "This may take 15-60 min for the full VegVault."
  )
)

data_traits_raw <-
  extract_traits_from_vegvault(
    path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
    sel_trait_domain_names = sel_trait_domain_names,
    x_lim = vec_continental_x_lim,
    y_lim = vec_continental_y_lim
  )

cli::cli_inform(
  c("v" = "Extraction complete.")
)


#----------------------------------------------------------#
# 4. Clean raw trait data -----
#----------------------------------------------------------#

# extract_traits_from_vegvault() with return_raw_data = TRUE
#   returns a flat tibble. Each row is one trait measurement with
#   columns:
#     taxon_id          — unique identifier for each taxon
#     trait_domain_name — e.g. "Leaf mass per area"
#     trait_name        — specific trait variant within the domain
#     trait_value       — numeric measurement
data_traits <-
  data_traits_raw |>
  dplyr::select(
    dplyr::any_of(
      c("taxon_id", "trait_domain_name", "trait_name", "trait_value")
    )
  ) |>
  dplyr::filter(
    !base::is.na(.data[["taxon_id"]]),
    !base::is.na(.data[["trait_value"]])
  )

cli::cli_inform(
  c(
    "v" = paste0(
      "Cleaned: ",
      base::nrow(data_traits),
      " trait records."
    )
  )
)

# Quick check of the output structure
base::cat("\n--- data_traits glimpse ---\n")
dplyr::glimpse(data_traits)
base::cat("\n--- Trait record counts by domain ---\n")
data_traits |>
  dplyr::count(.data[["trait_domain_name"]]) |>
  print()

# Now need to do call to the database to translate the IDs to names
cli::cli_inform(
  c(
    "i" = "Translating taxon IDs to names via VegVault database.",
    " " = "This may take a few minutes."
  )
)

vegvault_conn <-
  DBI::dbConnect(
    RSQLite::SQLite(),
    here::here("Data/Input/VegVault.sqlite")
  )

data_taxon_lookup <-
  dplyr::tbl(vegvault_conn, "Taxa") |>
  dplyr::collect() |>
  dplyr::filter(
    .data[["taxon_id"]] %in% data_traits[["taxon_id"]]
  )

data_traits_with_names <-
  data_traits |>
  dplyr::left_join(
    data_taxon_lookup |> dplyr::select("taxon_id", "taxon_name"),
    by = "taxon_id"
  ) |>
  dplyr::select(
    "taxon_name", "trait_domain_name", "trait_name", "trait_value"
  )


#----------------------------------------------------------#
# 5. Save -----
#----------------------------------------------------------#

path_traits <-
  base::file.path(
    path_output,
    base::paste0(
      "data_traits_",
      base::format(base::Sys.Date(), "%Y-%m-%d"),
      ".qs"
    )
  )

qs2::qs_save(
  object = data_traits_with_names,
  file = path_traits
)

cli::cli_inform(
  c("v" = paste0("Saved: ", path_traits))
)
