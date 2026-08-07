# Input Validation

testthat::test_that("load_active_config_value() errors when value is NULL", {
  testthat::expect_error(
    load_active_config_value(NULL)
  )
})

testthat::test_that("active config values require character paths", {
  testthat::expect_error(
    load_active_config_value(123)
  )
})

testthat::test_that(
  "load_active_config_value() errors when value is empty character",
  {
    testthat::expect_error(
      load_active_config_value(base::character())
    )
  }
)

testthat::test_that(
  "load_active_config_value() errors when file does not exist",
  {
    testthat::expect_error(
      load_active_config_value("key1", "non_existent.yml")
    )
  }
)

testthat::test_that(
  "load_active_config_value() errors when file has wrong extension",
  {
    path_temp <-
      base::tempfile(fileext = ".txt")

    base::writeLines("key1: value1", path_temp)

    testthat::expect_error(
      load_active_config_value("key1", path_temp)
    )

    base::unlink(path_temp)
  }
)

# Output Structure

testthat::test_that(
  "load_active_config_value() returns value from a valid YAML file",
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
      load_active_config_value("key1", path_temp)

    testthat::expect_false(base::is.null(result))
    testthat::expect_type(result, "character")

    base::unlink(path_temp)
  }
)

# Functional Correctness

testthat::test_that(
  "load_active_config_value() retrieves the correct value",
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
      load_active_config_value("key1", path_temp)

    testthat::expect_equal(result, "value1")

    base::unlink(path_temp)
  }
)

testthat::test_that(
  "load_active_config_value() retrieves a different key correctly",
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
      load_active_config_value("key2", path_temp)

    testthat::expect_equal(result, "value2")

    base::unlink(path_temp)
  }
)
