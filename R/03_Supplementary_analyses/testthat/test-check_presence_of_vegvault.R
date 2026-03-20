# Input Validation

testthat::test_that(
  "check_presence_of_vegvault() errors for missing file",
  {
    testthat::expect_error(
      check_presence_of_vegvault("non_existent_file.sqlite")
    )
  }
)

# Output Structure

testthat::test_that(
  "check_presence_of_vegvault() returns logical(1) for existing file",
  {
    path_temp <-
      "R/03_Supplementary_analyses/testthat/Vegvault.sqlite"

    base::file.create(here::here(path_temp))

    result <-
      check_presence_of_vegvault(relative_path = path_temp)

    testthat::expect_type(result, "logical")
    testthat::expect_length(result, 1L)

    base::unlink(here::here(path_temp))
  }
)

# Functional Correctness

testthat::test_that(
  "check_presence_of_vegvault() returns TRUE for existing file",
  {
    path_temp <-
      "R/03_Supplementary_analyses/testthat/Vegvault.sqlite"

    base::file.create(here::here(path_temp))

    result <-
      check_presence_of_vegvault(relative_path = path_temp)

    testthat::expect_true(result)

    base::unlink(here::here(path_temp))
  }
)
