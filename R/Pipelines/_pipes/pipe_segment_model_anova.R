#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#               {target} pipe: Model anova
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# definition of the target pipe, which is created to set up model anova


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

pipe_segment_model_anova <-
  list(
    targets::tar_target(
      description = "Get model anova",
      name = "list_jsdm_variance_partition",
      command = if (
        base::is.null(mod_jsdm_selected)
      ) {
        NULL
      } else {
        compute_jsdm_variance_partition(
          mod = mod_jsdm_selected,
          n_samples = config_model_fitting[["n_samples_anova"]],
          verbose = TRUE
        )
      }
    )
  )
