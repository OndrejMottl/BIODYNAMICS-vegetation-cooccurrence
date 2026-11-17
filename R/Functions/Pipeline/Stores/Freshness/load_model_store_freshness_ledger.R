#' @title Load the Model Store Freshness Ledger
#' @description
#' Reads and validates the ledger of targets that are knowingly left outdated
#' after a selective rerun.
#' @param file
#' Path to the ledger CSV file.
#' @return
#' A tibble with character columns `store_path`, `target_pattern`, `reason`,
#' `evidence`, `owner`, and `expiry_issue`. It has zero rows when the ledger
#' only holds its header.
#' @details
#' `store_path` is relative to the repository root, as in the
#' `store_path_relative` column of [load_model_store_index()]. `target_pattern`
#' is a regular expression matched against whole target names. Every field is
#' required, the pair of store path and pattern must be unique, and each
#' pattern must be a valid regular expression. Rows are temporary: each one
#' expires with the issue named in `expiry_issue`.
#' @seealso [apply_model_store_freshness_ledger()]
#' @examples
#' \dontrun{
#' load_model_store_freshness_ledger()
#' }
#' @export
load_model_store_freshness_ledger <- function(
    file = here::here(
      "Documentation/Implementation_inventories/Model_stores",
      "model_store_freshness_ledger.csv"
    )) {
  assertthat::assert_that(
    assertthat::is.string(file),
    base::file.exists(file),
    msg = "`file` must be one existing ledger file."
  )

  vec_ledger_columns <-
    base::c(
      "store_path",
      "target_pattern",
      "reason",
      "evidence",
      "owner",
      "expiry_issue"
    )

  data_ledger_raw <-
    readr::read_csv(
      file = file,
      col_types = readr::cols(.default = readr::col_character()),
      na = base::character(),
      show_col_types = FALSE
    )

  assertthat::assert_that(
    base::identical(base::names(data_ledger_raw), vec_ledger_columns),
    msg = stringr::str_glue(
      "The ledger must have exactly these columns: ",
      "{stringr::str_c(vec_ledger_columns, collapse = ', ')}."
    )
  )

  data_ledger_trimmed <-
    data_ledger_raw |>
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::everything(),
        .fns = stringr::str_trim
      )
    )

  flag_incomplete <-
    data_ledger_trimmed |>
    dplyr::mutate(
      dplyr::across(
        .cols = dplyr::everything(),
        .fns = ~ base::is.na(.x) | !base::nzchar(.x)
      )
    ) |>
    base::as.matrix() |>
    base::any()

  if (
    flag_incomplete
  ) {
    cli::cli_abort(
      "Every ledger field is required.",
      class = "model_store_ledger_incomplete"
    )
  }

  if (
    base::anyDuplicated(
      data_ledger_trimmed[, base::c("store_path", "target_pattern")]
    ) > 0L
  ) {
    cli::cli_abort(
      "Ledger rows must have unique store paths and target patterns.",
      class = "model_store_ledger_duplicate"
    )
  }

  vec_invalid_patterns <-
    data_ledger_trimmed[["target_pattern"]] |>
    purrr::discard(
      .p = ~ {
        flag_valid <-
          base::tryCatch(
            expr = {
              stringr::str_detect("", .x)
              TRUE
            },
            error = function(error_condition) FALSE
          )
        return(flag_valid)
      }
    )

  if (
    base::length(vec_invalid_patterns) > 0L
  ) {
    cli::cli_abort(
      base::c(
        "Ledger target patterns must be valid regular expressions.",
        "x" = "{vec_invalid_patterns}"
      ),
      class = "model_store_ledger_invalid_pattern"
    )
  }

  res <-
    tibble::as_tibble(data_ledger_trimmed)

  return(res)
}
