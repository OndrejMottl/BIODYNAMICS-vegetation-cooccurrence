#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                     Config file
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# Configuration script with the variables that should be consistent throughout
#   the whole repo. It loads packages, defines important variables,
#   authorises the user, and saves config file.

# Set the current environment
current_env <- environment()


#----------------------------------------------------------#
# 1. Load packages -----
#----------------------------------------------------------#

library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  character.only = TRUE,
  verbose = FALSE
)

if (
  isFALSE(
    exists("already_synch", envir = current_env)
  )
) {
  already_synch <- FALSE
}

if (
  isFALSE(already_synch)
) {
  library(here)
  # Synchronise the package versions
  renv::restore(
    lockfile = here::here("renv.lock")
  )
  already_synch <- TRUE

  # Save snapshot of package versions
  # renv::snapshot(lockfile =  here::here("renv.lock"))  # do only for update
}

# Define packages
package_list <-
  c(
    "assertthat",
    "collinear",
    "here",
    "janitor",
    "jsonlite",
    "knitr",
    "languageserver",
    "lifecycle",
    "qs2",
    "renv",
    "remotes",
    "rlang",
    "roxygen2",
    "sjSDM",
    "tidyverse",
    "targets",
    "usethis",
    "utils",
    "vaultkeepr"
  )

# Attach all packages
sapply(
  package_list,
  function(x) {
    library(x,
      quietly = TRUE,
      warn.conflicts = FALSE,
      character.only = TRUE,
      verbose = FALSE
    )
  }
)


#----------------------------------------------------------#
# 2. Load functions -----
#----------------------------------------------------------#

# get vector of general functions
fun_list <-
  list.files(
    path = here::here("R/Functions/"),
    pattern = "*.R",
    recursive = TRUE,
    full.names = TRUE
  ) %>%
  purrr::discard(
    # Exclude outdated functions (e.g. HMSC-based)
    ~ stringr::str_detect(.x, "_outdated")
  )

# source them
if (
  length(fun_list) > 0
) {
  sapply(
    fun_list,
    source
  )
}


#----------------------------------------------------------#
# 3. Check the presence of VegVault
#----------------------------------------------------------#

check_presence_of_vegvault()


#----------------------------------------------------------#
# 4. verify sjSDM setup -----
#----------------------------------------------------------#

if (
  isTRUE(interactive())
) {
  verify_sjsdm_setup()
}



#----------------------------------------------------------#
# 5. Graphical options -----
#----------------------------------------------------------#

# set ggplot output
ggplot2::theme_set(
  ggplot2::theme_classic()
)
