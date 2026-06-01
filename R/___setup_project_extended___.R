#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                 Full project setup
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Complete initialization for regular and modelling sessions. The
#   `___setup_project___.R` entry point sources this file only outside
#   parallel preprocessing workers and supplies `vec_package_names`.


#----------------------------------------------------------#
# 1. Synchronise package library -----
#----------------------------------------------------------#

if (
  isFALSE(
    base::exists(
      "flag_already_synch",
      envir = current_env,
      inherits = FALSE
    )
  )
) {
  flag_already_synch <- FALSE
}

if (
  isFALSE(flag_already_synch)
) {
  renv::restore(
    lockfile = here::here("renv.lock")
  )
  flag_already_synch <- TRUE

  # Save a snapshot only when package versions are intentionally updated.
  # renv::snapshot(lockfile = here::here("renv.lock"))
}


#----------------------------------------------------------#
# 2. Load full-session packages -----
#----------------------------------------------------------#

vec_package_names_full <-
  base::c(
    vec_package_names,
    "collinear",
    "janitor",
    "jsonlite",
    "knitr",
    "languageserver",
    "lifecycle",
    "remotes",
    "roxygen2",
    "sf",
    "sjSDM",
    "usethis"
  )

base::sapply(
  vec_package_names_full,
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


#----------------------------------------------------------#
# 3. Load functions and verify data access -----
#----------------------------------------------------------#

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


#----------------------------------------------------------#
# 4. Check CUDA GPU runtime availability -----
#----------------------------------------------------------#

if (
  isFALSE(
    base::exists(
      "flag_cuda_runtime_checked",
      envir = current_env,
      inherits = FALSE
    )
  )
) {
  flag_cuda_runtime_checked <- FALSE
}

if (
  isFALSE(flag_cuda_runtime_checked)
) {
  check_cuda_gpu_runtime(
    fail_on_error = FALSE,
    verbose = TRUE
  )

  flag_cuda_runtime_checked <- TRUE
}


#----------------------------------------------------------#
# 5. Verify sjSDM setup -----
#----------------------------------------------------------#

if (
  isTRUE(base::interactive())
) {
  verify_sjsdm_setup()
}
