# Input Validation

testthat::test_that("get_active_config() errors when value is NULL", {
  testthat::expect_error(
    get_active_config(NULL)
  )
})

testthat::test_that("get_active_config() errors when value is non-character", {
  testthat::expect_error(
    get_active_config(123)
  )
})

testthat::test_that(
  "get_active_config() errors when value is empty character",
  {
    testthat::expect_error(
      get_active_config(base::character())
    )
  }
)

testthat::test_that(
  "get_active_config() errors when file does not exist",
  {
    testthat::expect_error(
      get_active_config("key1", "non_existent.yml")
    )
  }
)

testthat::test_that(
  "get_active_config() errors when file has wrong extension",
  {
    path_temp <-
      base::tempfile(fileext = ".txt")

    base::writeLines("key1: value1", path_temp)

    testthat::expect_error(
      get_active_config("key1", path_temp)
    )

    base::unlink(path_temp)
  }
)

# Output Structure

testthat::test_that(
  "get_active_config() returns value from a valid YAML file",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    yaml::write_yaml(
      list(
        default = list(
          key1 = "value1",
          key2 = "value2"
        )
      ),
      path_temp
    )

    result <-
      get_active_config("key1", path_temp)

    testthat::expect_false(base::is.null(result))
    testthat::expect_type(result, "character")

    base::unlink(path_temp)
  }
)

# Functional Correctness

testthat::test_that(
  "get_active_config() retrieves the correct value",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    yaml::write_yaml(
      list(
        default = list(
          key1 = "value1",
          key2 = "value2"
        )
      ),
      path_temp
    )

    result <-
      get_active_config("key1", path_temp)

    testthat::expect_equal(result, "value1")

    base::unlink(path_temp)
  }
)

testthat::test_that(
  "get_active_config() retrieves a different key correctly",
  {
    path_temp <-
      base::tempfile(fileext = ".yml")

    yaml::write_yaml(
      list(
        default = list(
          key1 = "value1",
          key2 = "value2"
        )
      ),
      path_temp
    )

    result <-
      get_active_config("key2", path_temp)

    testthat::expect_equal(result, "value2")

    base::unlink(path_temp)
  }
)
