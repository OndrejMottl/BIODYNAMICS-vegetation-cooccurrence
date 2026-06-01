#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                 Lean project setup
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# Shared bootstrap entry point. Parallel preprocessing workers execute the
#   lean setup here. Regular sessions delegate to
#   `___setup_project_full___.R` before project packages are attached.

# Set the current environment
current_env <- environment()

flag_preprocessing_worker <-
  base::identical(
    base::Sys.getenv("BIODYNAMICS_PREPROCESSING_WORKER"),
    "true"
  )


#----------------------------------------------------------#
# 1. Define lean dependencies -----
#----------------------------------------------------------#

library(
  "here",
  quietly = TRUE,
  warn.conflicts = FALSE,
  character.only = TRUE,
  verbose = FALSE
)

# Define packages required for preprocessing targets.
vec_package_names <-
  c(
    "assertthat",
    "here",
    "qs2",
    "renv",
    "rlang",
    "tidyverse",
    "targets",
    "utils",
    "vaultkeepr"
  )

#----------------------------------------------------------#
# 2. Initialize selected setup path -----
#----------------------------------------------------------#

if (
  isTRUE(flag_preprocessing_worker)
) {
  base::sapply(
    vec_package_names,
    function(x) {
      base::library(
        x,
        quietly = TRUE,
        warn.conflicts = FALSE,
        character.only = TRUE,
        verbose = FALSE
      )
    }
  )

  vec_function_paths <-
    base::list.files(
      path = here::here("R/Functions/"),
      pattern = "*.R",
      recursive = TRUE,
      full.names = TRUE
    ) |>
    purrr::discard(
      ~ stringr::str_detect(.x, "_outdated")
    )

  if (
    base::length(vec_function_paths) > 0
  ) {
    base::sapply(
      vec_function_paths,
      base::source
    )
  }

  check_presence_of_vegvault()

  n_preprocessing_workers <-
    base::Sys.getenv("BIODYNAMICS_PREPROCESSING_WORKERS")

  flag_crew_mori_backend <-
    base::identical(
      base::Sys.getenv("BIODYNAMICS_PREPROCESSING_BACKEND"),
      "crew_mori"
    )

  if (
    base::nzchar(n_preprocessing_workers) &&
      !isTRUE(flag_crew_mori_backend)
  ) {
    n_preprocessing_workers <-
      base::as.integer(n_preprocessing_workers)

    assertthat::assert_that(
      base::is.finite(n_preprocessing_workers) &&
        n_preprocessing_workers >= 1L,
      msg = paste(
        "BIODYNAMICS_PREPROCESSING_WORKERS must be a",
        "positive integer."
      )
    )

    future::plan(
      future::multisession,
      workers = n_preprocessing_workers
    )
  }
} else {
  base::source(
    file = here::here("R/___setup_project_extended___.R"),
    local = current_env
  )
}


#----------------------------------------------------------#
# 3. Graphical options -----
#----------------------------------------------------------#

# Set ggplot output.
ggplot2::theme_set(
  ggplot2::theme_classic()
)
