testthat::test_that(
  "read_vegvault_scalar() returns first scalar value",
  {
    con <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = ":memory:"
      )

    base::on.exit(
      DBI::dbDisconnect(con),
      add = TRUE
    )

    DBI::dbExecute(
      conn = con,
      statement = "create table test_table (value integer)"
    )
    DBI::dbExecute(
      conn = con,
      statement = "insert into test_table values (7), (9)"
    )

    res <-
      read_vegvault_scalar(
        conn = con,
        sql = "select value from test_table order by value"
      )

    testthat::expect_identical(res, 7L)
  }
)

testthat::test_that(
  "read_vegvault_scalar() validates SQL input",
  {
    con <-
      DBI::dbConnect(
        drv = RSQLite::SQLite(),
        dbname = ":memory:"
      )

    base::on.exit(
      DBI::dbDisconnect(con),
      add = TRUE
    )

    testthat::expect_error(
      read_vegvault_scalar(
        conn = con,
        sql = ""
      ),
      regexp = "sql"
    )
  }
)
