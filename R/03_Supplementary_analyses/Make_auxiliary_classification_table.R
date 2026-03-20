#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#    Collate missing-taxa templates across pipeline stores
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Reads the `data_missing_taxa_template` targets object from every
#   `pipeline_basic` store under Data/targets/ and combines them
#   into a single CSV for manual review.
# After filling in the missing classifications, copy or append
#   rows to Data/Input/aux_classification_table.csv and re-run
#   the relevant pipelines.


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

library(here)

source(
  here::here("R/___setup_project___.R")
)


#----------------------------------------------------------#
# 1. Discover pipeline stores -----
#----------------------------------------------------------#

vec_store_paths <-
  list.dirs(
    path = here::here("Data/targets"),
    full.names = TRUE,
    recursive = TRUE
  ) |>
  purrr::keep(
    .p = ~ base::basename(.x) == "pipeline_basic"
  )

if (
  base::length(vec_store_paths) == 0
) {
  cli::cli_inform(
    c(
      "i" = "No pipeline stores found under {.path Data/targets/}.",
      "i" = "Run at least one pipeline before collating missing taxa."
    )
  )
} else {

  #----------------------------------------------------------#
  # 2. Read missing-taxa template from each store -----
  #----------------------------------------------------------#

  data_missing_taxa_all <-
    purrr::map(
      .x = vec_store_paths,
      .f = ~ {
        tryCatch(
          expr = {
            data_read <-
              targets::tar_read(
                name = "data_missing_taxa_template",
                store = .x
              )

            if (
              base::nrow(data_read) == 0
            ) {
              return(NULL)
            }

            dplyr::mutate(
              data_read,
              source_pipeline = stringr::str_remove(
                string = .x,
                pattern = base::paste0(
                  here::here("Data/targets"),
                  "/"
                )
              )
            )
          },
          error = function(e) NULL
        )
      }
    ) |>
    purrr::compact() |>
    purrr::list_rbind()


  #----------------------------------------------------------#
  # 3. Deduplicate and save -----
  #----------------------------------------------------------#

  if (
    base::nrow(data_missing_taxa_all) == 0
  ) {
    cli::cli_inform(
      c(
        "v" = "No missing taxa found across any pipeline store.",
        "i" = "All taxa have been successfully classified."
      )
    )
  } else {
    data_missing_taxa_collated <-
      dplyr::distinct(
        data_missing_taxa_all,
        sel_name,
        .keep_all = TRUE
      )

    vec_output_path <-
      here::here("Outputs/Data/missing_taxa/missing_taxa_collated.csv")

    base::dir.create(
      path = base::dirname(vec_output_path),
      showWarnings = FALSE,
      recursive = TRUE
    )

    readr::write_csv(
      x = data_missing_taxa_collated,
      file = vec_output_path
    )

    cli::cli_inform(
      c(
        "v" = paste(
          "Collated",
          base::nrow(data_missing_taxa_collated),
          "unique missing taxon/taxa to {.path {vec_output_path}}."
        ),
        "i" = paste(
          "Fill in the missing classifications and copy/append",
          "rows to {.path Data/Input/aux_classification_table.csv}."
        )
      )
    )
  }
}
