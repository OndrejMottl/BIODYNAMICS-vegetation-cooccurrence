#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
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

#----------------------------------------------------------#
# 1. Pipe definition -----
#----------------------------------------------------------#

list(
  targets::tar_target(
    name = "data_mtgcars",
    command = mtcars,
    format = "qs",
  ),
  targets::tar_target(
    name = "data_summary",
    command = test_function(data_mtgcars),
    format = "qs",
  )
)
