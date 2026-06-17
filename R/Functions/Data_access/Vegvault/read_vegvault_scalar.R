#' @title Read Scalar Value from VegVault
#' @description
#' Executes one SQL query against an open VegVault connection and returns
#' the first value from the first column.
#' @param conn
#' Active DBI connection.
#' @param sql
#' Character scalar SQL query.
#' @return
#' Scalar value from the first query column.
#' @examples
#' \dontrun{
#' con <- DBI::dbConnect(RSQLite::SQLite(), "Data/Input/VegVault.sqlite")
#' on.exit(DBI::dbDisconnect(con), add = TRUE)
#' read_vegvault_scalar(con, "select count(*) from Datasets")
#' }
#' @export
read_vegvault_scalar <- function(
    conn,
    sql) {
  assertthat::assert_that(
    DBI::dbIsValid(conn),
    msg = "'conn' must be a valid open DBI connection."
  )

  assertthat::assert_that(
    base::is.character(sql),
    base::length(sql) == 1L,
    base::nchar(sql) > 0L,
    msg = "'sql' must be a single non-empty character value."
  )

  res_query <-
    DBI::dbGetQuery(
      conn = conn,
      statement = sql
    )

  assertthat::assert_that(
    base::nrow(res_query) >= 1L,
    base::ncol(res_query) >= 1L,
    msg = "Query did not return at least one value."
  )

  res_value <-
    res_query |>
    dplyr::pull(1)

  assertthat::assert_that(
    base::length(res_value) >= 1L,
    msg = "Query result did not contain a scalar value."
  )

  return(res_value[[1]])
}
