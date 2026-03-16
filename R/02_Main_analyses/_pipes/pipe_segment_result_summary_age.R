#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          {target} pipe: Result summary type - age
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to extract summary
#   statistics for species associations for each age slice


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

pipe_segment_result_summary_age <-
  list(
    tarchetypes::tar_combine(
      description = "Combine per-slice anova objects into a list",
      name = "list_model_anova_by_age",
      pipe_models_by_age[["model_anova"]],
      command = list(!!!.x)
    ),
    targets::tar_target(
      description = paste0(
        "Long-format table of anova variance components",
        " by age slice"
      ),
      name = "data_anova_components_by_age",
      command = aggregate_anova_components(
        list_model_anova = list_model_anova_by_age
      )
    ),
    targets::tar_target(
      description = "Tranform anova components into percentages",
      name = "data_anova_components_by_age_percentage",
      command = recalculate_anova_components(
        data_source = data_anova_components_by_age
      )
    )
  )
