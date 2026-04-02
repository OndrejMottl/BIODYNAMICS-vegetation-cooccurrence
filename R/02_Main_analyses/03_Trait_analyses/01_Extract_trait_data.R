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
#   for ALL available trait domains (discovered dynamically via a
#   direct query to the TraitsDomain metadata table).
#
# Geographic filtering is applied at the continental level: all
#   three continental rows from spatial_grid.csv (europe, america,
#   asia) are processed in sequence via purrr::walk(). Each continent
#   is extracted, cleaned, translated, and saved to its own .qs file
#   before the next one begins — only one continent is held in memory
#   at a time.
#
# Output (one file per continent):
#   Data/Processed/data_traits_{scale_id}_{YYYY-MM-DD}.qs
#
# Note: extraction is slow (15–60 min per continent) due to the
#   large VegVault file. The .qs outputs are the persistent cache;
#   subsequent scripts (02, 03) load them directly and do NOT
#   re-run extraction.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)

path_output <-
  here::here("Data/Processed")

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)

path_to_vegvault <-
  here::here("Data/Input/VegVault.sqlite")


#----------------------------------------------------------#
# 1. Load all continental rows -----
#----------------------------------------------------------#

# Load the full spatial grid and keep only the three continental-
#   scale rows (europe, america, asia). Each row supplies the
#   bounding box for one call to extract_traits_from_vegvault().
data_spatial_grid <-
  readr::read_csv(
    file = here::here("Data/Input/spatial_grid.csv"),
    show_col_types = FALSE
  )

data_continental_rows <-
  data_spatial_grid |>
  dplyr::filter(
    .data[["scale"]] == "continental"
  )

assertthat::assert_that(
  base::nrow(data_continental_rows) >= 1L,
  msg = base::paste0(
    "Expected at least one continental row in ",
    "spatial_grid.csv, but found none. ",
    "Check the 'scale' column."
  )
)

cli::cli_inform(
  c(
    "v" = base::paste0(
      base::nrow(data_continental_rows),
      " continental unit(s) found: ",
      base::paste(
        data_continental_rows |>
          dplyr::pull("scale_id"),
        collapse = ", "
      ),
      "."
    )
  )
)


#----------------------------------------------------------#
# 2. Discover all available trait domains -----
#----------------------------------------------------------#

# Query the TraitsDomain metadata table directly to discover all
#   domain names currently present in VegVault. This avoids
#   hardcoding specific trait domain strings in the script.
vegvault_conn_discovery <-
  DBI::dbConnect(
    RSQLite::SQLite(),
    path_to_vegvault
  )

vec_trait_domain_names <-
  dplyr::tbl(vegvault_conn_discovery, "TraitsDomain") |>
  dplyr::distinct(.data[["trait_domain_name"]]) |>
  dplyr::collect() |>
  dplyr::pull("trait_domain_name")

DBI::dbDisconnect(vegvault_conn_discovery)

vec_trait_domain_names <-
  vec_trait_domain_names[
    !base::is.na(vec_trait_domain_names)
  ]

assertthat::assert_that(
  base::length(vec_trait_domain_names) >= 1L,
  msg = "No trait domain names found in TraitsDomain table."
)

cli::cli_inform(
  c(
    "v" = base::paste0(
      base::length(vec_trait_domain_names),
      " trait domain(s) discovered: ",
      base::paste(vec_trait_domain_names, collapse = " | "),
      "."
    )
  )
)


#----------------------------------------------------------#
# 3. Extract, clean, translate, and save per continent -----
#----------------------------------------------------------#

# Process each continental unit in sequence. Only one continent's
#   data is held in memory at a time: the object leaves scope after
#   each qs_save() call, freeing memory before the next iteration.
purrr::walk(
  .x = base::seq_len(base::nrow(data_continental_rows)),
  .f = ~ {
    data_row <-
      data_continental_rows[.x, ]

    vec_scale_id <-
      data_row |>
      dplyr::pull("scale_id")

    vec_x_lim <-
      base::c(
        data_row |> dplyr::pull("x_min"),
        data_row |> dplyr::pull("x_max")
      )

    vec_y_lim <-
      base::c(
        data_row |> dplyr::pull("y_min"),
        data_row |> dplyr::pull("y_max")
      )

    cli::cli_inform(
      c(
        "i" = base::paste0(
          "[", .x, "/",
          base::nrow(data_continental_rows), "] ",
          "Starting extraction for '", vec_scale_id, "'."
        ),
        " " = base::paste0(
          "Bounds: lon [",
          vec_x_lim[1], ", ", vec_x_lim[2],
          "], lat [",
          vec_y_lim[1], ", ", vec_y_lim[2], "]."
        ),
        " " = base::paste0(
          "Domains (", base::length(vec_trait_domain_names),
          "): ",
          base::paste(
            vec_trait_domain_names,
            collapse = " | "
          )
        ),
        " " = "This may take 15-60 min per continent."
      )
    )

    #--------------------------------------------------#
    ## 3.1. Extract from VegVault -----
    #--------------------------------------------------#

    data_traits_raw <-
      extract_traits_from_vegvault(
        path_to_vegvault = path_to_vegvault,
        sel_trait_domain_names = vec_trait_domain_names,
        x_lim = vec_x_lim,
        y_lim = vec_y_lim
      )

    cli::cli_inform(
      c(
        "v" = base::paste0(
          "'", vec_scale_id, "': raw extraction complete (",
          base::nrow(data_traits_raw), " records)."
        )
      )
    )


    #--------------------------------------------------#
    ## 3.2. Clean -----
    #--------------------------------------------------#

    # Keep only the four required columns and drop rows with
    #   missing taxon identifier or trait value.
    data_traits_clean <-
      data_traits_raw |>
      dplyr::select(
        dplyr::any_of(
          c(
            "taxon_id",
            "trait_domain_name",
            "trait_name",
            "trait_value"
          )
        )
      ) |>
      dplyr::filter(
        !base::is.na(.data[["taxon_id"]]),
        !base::is.na(.data[["trait_value"]])
      )

    cli::cli_inform(
      c(
        "v" = base::paste0(
          "'", vec_scale_id, "': cleaned to ",
          base::nrow(data_traits_clean), " records."
        )
      )
    )


    #--------------------------------------------------#
    ## 3.3. Translate taxon IDs to names -----
    #--------------------------------------------------#

    vegvault_conn <-
      DBI::dbConnect(
        RSQLite::SQLite(),
        path_to_vegvault
      )

    data_taxon_lookup <-
      dplyr::tbl(vegvault_conn, "Taxa") |>
      dplyr::collect() |>
      dplyr::filter(
        .data[["taxon_id"]] %in%
          data_traits_clean[["taxon_id"]]
      )

    DBI::dbDisconnect(vegvault_conn)

    data_traits_with_names <-
      data_traits_clean |>
      dplyr::left_join(
        data_taxon_lookup |>
          dplyr::select("taxon_id", "taxon_name"),
        by = dplyr::join_by("taxon_id")
      ) |>
      dplyr::select(
        "taxon_name",
        "trait_domain_name",
        "trait_name",
        "trait_value"
      )


    #--------------------------------------------------#
    ## 3.4. Save -----
    #--------------------------------------------------#

    path_traits_continent <-
      base::file.path(
        path_output,
        base::paste0(
          "data_traits_",
          vec_scale_id,
          "_",
          base::format(base::Sys.Date(), "%Y-%m-%d"),
          ".qs"
        )
      )

    qs2::qs_save(
      object = data_traits_with_names,
      file = path_traits_continent
    )

    cli::cli_inform(
      c(
        "v" = base::paste0(
          "'", vec_scale_id, "': saved ",
          base::nrow(data_traits_with_names),
          " records -> ", path_traits_continent
        )
      )
    )

    base::invisible(NULL)
  }
)

cli::cli_inform(
  c(
    "v" = base::paste0(
      "All ",
      base::nrow(data_continental_rows),
      " continent(s) extracted and saved to: ",
      path_output
    )
  )
)
