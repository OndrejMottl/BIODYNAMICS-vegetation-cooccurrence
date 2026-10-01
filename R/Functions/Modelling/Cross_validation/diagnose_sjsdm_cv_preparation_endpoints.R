#' @title Diagnose sjSDM CV Preparation Endpoints
#' @description
#' Diagnoses whether requested prepared-fold targets exist, have successful
#' metadata and content hashes, and can be read from a targets store.
#' @param store_path
#' Character scalar identifying the targets store.
#' @param target_names
#' Unique non-empty character vector of prepared-fold target names.
#' @param load_metadata_function
#' Injectable target-metadata loader.
#' @param read_target_function
#' Injectable raw target reader.
#' @return
#' A tibble with one row per requested target and its endpoint status, data
#' hash, and diagnostic message.
#' @details
#' Endpoint statuses are `prepared`, `missing`, `errored`, `unreadable`, or
#' `cache_format_incompatible`. The last status is reserved for legacy `qs`
#' objects that current `qs2`-based targets installations cannot read.
#' @export
diagnose_sjsdm_cv_preparation_endpoints <- function(
    store_path = NULL,
    target_names = NULL,
    load_metadata_function = load_targets_store_metadata,
    read_target_function = targets::tar_read_raw) {
  assertthat::assert_that(
    base::is.character(store_path),
    base::length(store_path) == 1L,
    !base::is.na(store_path),
    base::nzchar(store_path),
    msg = "store_path must be one non-empty path."
  )
  assertthat::assert_that(
    base::is.character(target_names),
    base::length(target_names) > 0L,
    base::all(!base::is.na(target_names)),
    base::all(base::nzchar(target_names)),
    !base::any(base::duplicated(target_names)),
    msg = "target_names must be unique non-empty names."
  )
  assertthat::assert_that(
    base::is.function(load_metadata_function),
    base::is.function(read_target_function),
    msg = "Metadata loading and target reading must use functions."
  )

  data_metadata <-
    load_metadata_function(
      store_path = store_path,
      fields = base::c("name", "error", "data")
    )
  if (
    base::is.null(data_metadata) ||
      !base::is.data.frame(data_metadata) ||
      !base::all(
        base::c("name", "error", "data") %in%
          base::colnames(data_metadata)
      )
  ) {
    data_metadata <-
      tibble::tibble(
        name = base::character(),
        error = base::character(),
        data = base::character()
      )
  }

  data_endpoints <-
    target_names |>
    purrr::map(
      .f = function(target_name) {
        data_target <-
          data_metadata |>
          dplyr::filter(.data[["name"]] == .env[["target_name"]])
        if (
          base::nrow(data_target) == 0L
        ) {
          return(
            tibble::tibble(
              target_name = target_name,
              endpoint_status = "missing",
              data_hash = NA_character_,
              error_message = "Target metadata are missing."
            )
          )
        }
        if (
          base::nrow(data_target) != 1L
        ) {
          return(
            tibble::tibble(
              target_name = target_name,
              endpoint_status = "errored",
              data_hash = NA_character_,
              error_message = "Target metadata contain duplicate rows."
            )
          )
        }

        error_message <-
          data_target[["error"]][[1L]]
        data_hash <-
          data_target[["data"]][[1L]]
        flag_has_error <-
          !base::is.na(error_message) &&
          base::nzchar(error_message)
        flag_legacy_qs <-
          flag_has_error &&
          stringr::str_detect(
            error_message,
            "(?:no package called|package) ['\"]qs['\"]"
          )
        if (
          flag_has_error
        ) {
          return(
            tibble::tibble(
              target_name = target_name,
              endpoint_status = if (
                flag_legacy_qs
              ) {
                "cache_format_incompatible"
              } else {
                "errored"
              },
              data_hash = data_hash,
              error_message = error_message
            )
          )
        }
        if (
          base::is.na(data_hash) || !base::nzchar(data_hash)
        ) {
          return(
            tibble::tibble(
              target_name = target_name,
              endpoint_status = "missing",
              data_hash = data_hash,
              error_message = "Target metadata have no content hash."
            )
          )
        }

        read_error <-
          base::tryCatch(
            expr = {
              read_target_function(
                name = target_name,
                store = store_path
              )
              NULL
            },
            error = function(error_captured) error_captured
          )
        base::gc(verbose = FALSE)
        if (
          base::is.null(read_error)
        ) {
          return(
            tibble::tibble(
              target_name = target_name,
              endpoint_status = "prepared",
              data_hash = data_hash,
              error_message = NA_character_
            )
          )
        }

        read_error_message <-
          base::conditionMessage(read_error)
        flag_legacy_qs_read <-
          stringr::str_detect(
            read_error_message,
            "(?:no package called|package) ['\"]qs['\"]"
          )
        tibble::tibble(
          target_name = target_name,
          endpoint_status = if (
            flag_legacy_qs_read
          ) {
            "cache_format_incompatible"
          } else {
            "unreadable"
          },
          data_hash = data_hash,
          error_message = read_error_message
        )
      }
    ) |>
    purrr::list_rbind()

  return(data_endpoints)
}
