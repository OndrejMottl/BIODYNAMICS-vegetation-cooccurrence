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
      name = "model_anova",
      command = get_anova(
        mod = mod_to_use,
        n_samples = config.model_fitting$n_samples_anova,
        verbose = TRUE
      )
    )
  )
