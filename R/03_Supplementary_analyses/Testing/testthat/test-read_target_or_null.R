testthat::test_that(
  "read_target_or_null() returns target value when read succeeds",
  {
    fake_read <-
      function(name, store) {
        base::list(name = name, store = store)
      }

    res <-
      read_target_or_null(
        target_name = "data_target",
        store_path = "store_path",
        read_fn = fake_read
      )

    testthat::expect_identical(
      purrr::pluck(res, "name"),
      "data_target"
    )
    testthat::expect_identical(
      purrr::pluck(res, "store"),
      "store_path"
    )
  }
)

testthat::test_that(
  "read_target_or_null() returns NULL when read fails",
  {
    fake_read <-
      function(name, store) {
        base::stop("read failed")
      }

    res <-
      read_target_or_null(
        target_name = "data_target",
        store_path = "store_path",
        read_fn = fake_read
      )

    testthat::expect_null(res)
  }
)

testthat::test_that(
  "read_target_or_null() validates arguments",
  {
    fake_read <-
      function(name, store) {
        base::list()
      }

    testthat::expect_error(
      read_target_or_null(
        target_name = "",
        store_path = "store",
        read_fn = fake_read
      ),
      regexp = "target_name"
    )

    testthat::expect_error(
      read_target_or_null(
        target_name = "x",
        store_path = "",
        read_fn = fake_read
      ),
      regexp = "store_path"
    )
  }
)
