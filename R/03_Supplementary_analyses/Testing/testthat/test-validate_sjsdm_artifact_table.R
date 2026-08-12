testthat::test_that(
  "validate_sjsdm_artifact_table() enforces keys and statuses",
  {
    data_value <-
      tibble::tibble(
        id = 1:2,
        status = base::c("ok", "error")
      )

    testthat::expect_true(
      validate_sjsdm_artifact_table(
        data_value = data_value,
        table_name = "data_test",
        columns = base::c("id", "status"),
        types = base::c(id = "integer", status = "character"),
        keys = "id",
        statuses = base::list(status = base::c("ok", "error"))
      )
    )

    testthat::expect_error(
      validate_sjsdm_artifact_table(
        data_value = dplyr::mutate(data_value, id = 1L),
        table_name = "data_test",
        columns = base::c("id", "status"),
        types = base::c(id = "integer", status = "character"),
        keys = "id",
        statuses = base::list(status = base::c("ok", "error"))
      ),
      "duplicate keys"
    )
  }
)
