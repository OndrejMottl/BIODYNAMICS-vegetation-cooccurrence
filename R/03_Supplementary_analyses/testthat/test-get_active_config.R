testthat::test_that("get_active_config retrieves a value from a valid YAML file", {
  # Create a temporary YAML file
  temp_file <-
    tempfile(fileext = ".yml")

  yaml::write_yaml(
    list(
      default = list(
        key1 = "value1",
        key2 = "value2"
      )
    ),
    temp_file
  )

  result <-
    get_active_config("key1", temp_file)

  testthat::expect_equal(result, "value1")

  # Clean up temporary file
  unlink(temp_file)
})

testthat::test_that("get_active_config throws error for invalid input", {
  testthat::expect_error(get_active_config(NULL))
  testthat::expect_error(get_active_config("key1", "non_existent.yml"))
})
