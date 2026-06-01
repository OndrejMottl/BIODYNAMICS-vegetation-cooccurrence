#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               {target} pipe: VegVault data
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to load VegVault data


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

# Load {here}
library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  verbose = FALSE
)

# load all project settings
suppressMessages(
  suppressWarnings(
    source(
      here::here("R/___setup_project___.R")
    )
  )
)

#----------------------------------------------------------#
# 1. pipe definition -----
#----------------------------------------------------------#

pipe_segment_vegvault_extract <-
  list(
    targets::tar_target(
      description = "Extracted data from VegVault",
      name = "data_vegvault_extracted",
      # Build fossil-pollen plan fresh inside target to avoid serialising
      # the DBI connection
      command = {
        sel_x_lim <-
          purrr::chuck(config_vegvault_data, "x_lim")
        sel_y_lim <-
          purrr::chuck(config_vegvault_data, "y_lim")
        sel_age_lim <-
          purrr::chuck(config_vegvault_data, "age_lim")
        sel_dataset_type <-
          purrr::chuck(config_vegvault_data, "sel_dataset_type")
        sel_abiotic_var_name <-
          purrr::chuck(config_vegvault_data, "sel_abiotic_var_name")

        sel_scale_id <-
          get_scale_id_from_store()

        data_extracted <-
          tryCatch(
            expr = {
              build_vegvault_plan(
                path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
                x_lim = sel_x_lim,
                y_lim = sel_y_lim,
                age_lim = sel_age_lim,
                sel_dataset_type = sel_dataset_type
              ) |>
                extract_data_from_vegvault(
                  sel_abiotic_var_name = sel_abiotic_var_name
                )
            },
            error = function(e) {
              raw_error <-
                base::conditionMessage(e)

              has_meaningful_error <-
                !base::is.null(raw_error) &&
                base::nzchar(base::trimws(raw_error)) &&
                !base::identical(raw_error, ".")

              error_detail <-
                if (
                  has_meaningful_error
                ) {
                  raw_error
                } else {
                  stringr::str_c(
                    "The upstream backend returned an empty/opaque error ",
                    "message."
                  )
                }

              cli::cli_abort(
                c(
                  "Failed to extract VegVault data for this spatial unit.",
                  "i" = stringr::str_c(
                    "scale_id: ",
                    dplyr::coalesce(sel_scale_id, "unknown")
                  ),
                  "i" = stringr::str_c(
                    "dataset_type: ",
                    base::paste(sel_dataset_type, collapse = ", ")
                  ),
                  "i" = stringr::str_c(
                    "abiotic variables: ",
                    base::paste(sel_abiotic_var_name, collapse = ", ")
                  ),
                  "i" = stringr::str_c(
                    "x_lim: [",
                    base::paste(sel_x_lim, collapse = ", "),
                    "] | y_lim: [",
                    base::paste(sel_y_lim, collapse = ", "),
                    "] | age_lim: [",
                    base::paste(sel_age_lim, collapse = ", "),
                    "]"
                  ),
                  "x" = error_detail
                )
              )
            }
          )

        assertthat::assert_that(
          base::is.data.frame(data_extracted),
          msg = "VegVault extraction must return a data frame."
        )

        if (
          base::nrow(data_extracted) == 0L
        ) {
          cli::cli_abort(
            c(
              "VegVault extraction returned zero rows.",
              "i" = stringr::str_c(
                "scale_id: ",
                dplyr::coalesce(sel_scale_id, "unknown")
              ),
              "i" = stringr::str_c(
                "No records matched the current spatial/age filters.",
                " Consider widening the spatial window or age range."
              )
            )
          )
        }

        data_extracted
      }
    ),
    targets::tar_target(
      description = "Get coordinates of the VegVault data",
      name = "data_coords",
      command = get_coords(data_vegvault_extracted)
    ),
    targets::tar_target(
      description = paste0(
        "Check that the spatial window contains enough cores",
        " before processing community data"
      ),
      name = "check_n_cores",
      command = check_min_n_cores(
        data_coords = data_coords,
        min_n_cores = config_min_n_cores
      )
    )
  )
