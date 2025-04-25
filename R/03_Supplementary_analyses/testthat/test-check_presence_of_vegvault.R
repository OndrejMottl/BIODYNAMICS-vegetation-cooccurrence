testthat::test_that("check_presence_of_vegvault returns TRUE for existing file", {
  # Create a temporary file to simulate VegVault.sqlite

  path_relative_temp_file <-
    "R/03_Supplementary_analyses/testthat/Vegvault.sqlite"


  file.create(
    here::here(path_relative_temp_file)
  )

  result <-
    check_presence_of_vegvault(
      relative_path = path_relative_temp_file
    )

  testthat::expect_true(result)

  # Clean up temporary file
  unlink(
    here::here(path_relative_temp_file)
  )
})

testthat::test_that("check_presence_of_vegvault throws error for missing file", {
  testthat::expect_error(
    check_presence_of_vegvault("non_existent_file.sqlite")
  )
})
