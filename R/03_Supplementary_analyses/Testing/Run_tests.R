#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                       Run tests
#
#
#                       O. Mottl
#                         2025
#
#----------------------------------------------------------#
# Run all tests in the project

library(here)

source(
  here::here("R/___setup_project___.R")
)

library(testthat)

path_test_root <-
  here::here(
    "R/03_Supplementary_analyses/Testing/testthat"
  )

vec_test_files <-
  fs::dir_ls(
    path = path_test_root,
    recurse = TRUE,
    type = "file",
    regexp = "test-.*[.]R$"
  ) |>
  purrr::discard(
    ~ stringr::str_detect(
      .x,
      "(^|[/\\\\])_outdated([/\\\\]|$)"
    )
  )

vec_test_directories <-
  vec_test_files |>
  base::dirname() |>
  base::unique() |>
  base::sort(method = "radix")

vec_test_directories |>
  purrr::walk(
    .f = ~ testthat::test_dir(.x)
  )
