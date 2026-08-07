# Input Validation

testthat::test_that(
  "validate_vegvault_presence() errors for missing file",
  {
    testthat::expect_error(
      validate_vegvault_presence("non_existent_file.sqlite")
    )
  }
)

# Output Structure

testthat::test_that(
  "validate_vegvault_presence() returns logical(1) for existing file",
  {
    path_temp <-
      "R/03_Supplementary_analyses/Testing/testthat/Vegvault.sqlite"

    base::file.create(here::here(path_temp))

    result <-
      validate_vegvault_presence(relative_path = path_temp)

    testthat::expect_type(result, "logical")
    testthat::expect_length(result, 1L)

    base::unlink(here::here(path_temp))
  }
)

# Functional Correctness

testthat::test_that(
  "validate_vegvault_presence() returns TRUE for existing file",
  {
    path_temp <-
      "R/03_Supplementary_analyses/Testing/testthat/Vegvault.sqlite"

    base::file.create(here::here(path_temp))

    result <-
      validate_vegvault_presence(relative_path = path_temp)

    testthat::expect_true(result)

    base::unlink(here::here(path_temp))
  }
)
