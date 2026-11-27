testthat::test_that(
  "every direct database connection in R/Functions is read-only",
  {
    vec_function_files <-
      base::list.files(
        path = here::here("R/Functions"),
        pattern = "[.]R$",
        recursive = TRUE,
        full.names = TRUE
      ) |>
      purrr::discard(
        .p = ~ stringr::str_detect(.x, "_outdated|_legacy")
      )

    data_connections <-
      vec_function_files |>
      rlang::set_names() |>
      purrr::map(
        .f = ~ {
          data_parse <-
            base::parse(file = .x, keep.source = TRUE) |>
            utils::getParseData()

          vec_call_name_ids <-
            data_parse |>
            dplyr::filter(
              .data[["token"]] == "SYMBOL_FUNCTION_CALL",
              .data[["text"]] == "dbConnect"
            ) |>
            dplyr::pull(parent)

          vec_call_ids <-
            data_parse |>
            dplyr::filter(.data[["id"]] %in% vec_call_name_ids) |>
            dplyr::pull(parent)

          tibble::tibble(
            call_text = utils::getParseText(
              parseData = data_parse,
              id = vec_call_ids
            )
          )
        }
      ) |>
      purrr::list_rbind(names_to = "path_function_file")

    vec_files_not_read_only <-
      data_connections |>
      dplyr::filter(
        !stringr::str_detect(
          string = .data[["call_text"]],
          pattern = "flags\\s*=\\s*RSQLite::SQLITE_RO"
        )
      ) |>
      dplyr::pull(path_function_file) |>
      base::basename() |>
      base::sort()

    testthat::expect_gt(base::nrow(data_connections), 0L)
    testthat::expect_equal(vec_files_not_read_only, base::character())
  }
)
