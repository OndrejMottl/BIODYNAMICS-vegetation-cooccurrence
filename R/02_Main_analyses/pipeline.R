#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#                   Main {target} pipe
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the main target pipe, which is run in the `Master.R` file


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

# load all functions
targets::tar_source(
  files = here::here("R/Functions/")
)

# set seed for reproducibility
targets::tar_option_set(
  seed = get_active_config("seed"),
  format = "qs",
  error = "null"
)

#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

# This section is basically a very complicated target factory.

# This is done to reduce code duplication (several parts of pipe chain repeats).
#  And mainly to use the `tar_combine` function to combine the results.

# I am aware that this is not the most elegant solution, but it works.

#--------------------------------------------------#
## 1.1 load pipes parts -----
#--------------------------------------------------#

path_pipe_parts <-
  here::here("R/02_Main_analyses/_pipes/")

# sourcing all pipe parts needs to be done in specific order
c(
  "pipe_target_config.R",
  "pipe_target_vegvault_data.R",
  "pipe_target_community_data.R",
  "pipe_target_abiotic_data.R",
  "pipe_target_model.R",
  "pipe_target_species_associations.R",
  "pipe_target_slice_by_age.R"
) %>%
  rlang::set_names() %>%
  purrr::walk(
    .f = ~ source(
      file = file.path(path_pipe_parts, .x)
    )
  )


#--------------------------------------------------#
## 1.1 combine all targets into a single pipe -----
#--------------------------------------------------#

list(
  pipe_target_config,
  pipe_target_vegvault_data,
  pipe_target_community_data,
  pipe_target_abiotic_data,
  pipe_target_associations_full,
  pipe_models_by_age,
  tarchetypes::tar_combine(
    name = "species_associations_by_age_merged",
    pipe_models_by_age[["number_of_significant_associations"]],
    command = list(!!!.x)
  ),
  targets::tar_target(
    description = "Table of significant associations by age",
    name = "data_species_associations_by_age",
    command = species_associations_by_age_merged %>%
      purrr::map("dataset_name") %>%
      purrr::map("proportion_significant") %>%
      unlist() %>%
      purrr::set_names(
        nm = names(.) %>%
          stringr::str_extract(., "_timeslice_\\d+") %>%
          stringr::str_remove(., "_timeslice_")
      ) %>%
      as.data.frame() %>%
      purrr::set_names("prop_sign_assoc") %>%
      tibble::rownames_to_column("age") %>%
      dplyr::mutate(
        age = as.numeric(age)
      )
  ),
  targets::tar_target(
    description = "Table of species associations total",
    name = "data_species_associations_total",
    command = number_of_significant_associations %>%
      purrr::map("proportion_significant") %>%
      unlist() %>%
      purrr::set_names(
        nm = names(.)
      ) %>%
      as.data.frame() %>%
      purrr::set_names("n_sign_assoc") %>%
      tibble::rownames_to_column("type")
  ),
  targets::tar_target(
    description = "Plot of significant associations by age",
    name = "plot_species_associations_by_age",
    command = ggplot2::ggplot() +
      ggplot2::geom_line(
        data = data_species_associations_by_age,
        mapping = ggplot2::aes(
          x = age,
          y = prop_sign_assoc
        )
      ) +
      ggplot2::geom_point(
        data = data_species_associations_by_age,
        mapping = ggplot2::aes(
          x = age,
          y = prop_sign_assoc
        )
      ) +
      ggplot2::geom_hline(
        data = data_species_associations_total,
        mapping = ggplot2::aes(
          yintercept = n_sign_assoc,
          col = type
        ),
        linetype = "dashed"
      ) +
      ggplot2::coord_cartesian(
        ylim = c(0, 1),
      ) +
      ggplot2::scale_x_continuous(
        trans = "reverse"
      ) +
      ggplot2::labs(
        title = "Proportion of significant associations by age",
        subtitle = paste("project:", Sys.getenv("R_CONFIG_ACTIVE")),
        x = "Age (cal yr BP)",
        y = "Proportion of significant associations"
      )
  )
)
