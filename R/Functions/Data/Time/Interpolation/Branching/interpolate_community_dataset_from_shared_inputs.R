#' @title Interpolate Community Dataset from Shared Inputs
#' @description
#' Slices shared paleo preprocessing inputs to one dataset and interpolates it.
#' @param list_interpolation_index
#' A metadata object produced by [build_community_interpolation_index()].
#' @param data_community
#' Community data or a descriptor from
#' [build_shared_interpolation_data()].
#' @param data_age_uncertainty
#' Age-uncertainty data or a shared descriptor.
#' @param n_cores
#' Number of cores passed to
#' [interpolate_paleo_community_with_age_uncertainty()]. Dynamic target
#' branches should use `1L`.
#' @param ...
#' Additional arguments passed to
#' [interpolate_paleo_community_with_age_uncertainty()].
#' @return
#' A data frame with columns `dataset_name`, `taxon`, `age`, and `value`.
#' @details
#' Inclusive row ranges keep branch payloads constant in size and avoid
#' full-table logical masks inside concurrent workers. During the one-time
#' migration from persisted live `{mori}` handles, a prebuild may reuse an
#' existing branch object after separately confirming durable inputs are
#' current.
#' @seealso
#'   [build_community_interpolation_index()],
#'   [interpolate_paleo_community_with_age_uncertainty()]
#' @export
interpolate_community_dataset_from_shared_inputs <- function(
    list_interpolation_index = NULL,
    data_community = NULL,
    data_age_uncertainty = NULL,
    n_cores = 1L,
    ...) {
  flag_reuse_cached_branch <-
    base::identical(
      base::Sys.getenv(
        "BIODYNAMICS_REUSE_CACHED_INTERPOLATION_BRANCHES"
      ),
      "true"
    )
  if (
    flag_reuse_cached_branch
  ) {
    branch_index_hash <-
      digest::digest(
        object = purrr::chuck(
          list_interpolation_index,
          "dataset_name"
        ),
        algo = "xxhash64",
        serialize = TRUE
      )
    path_cached_branch <-
      base::file.path(
        base::Sys.getenv(
          "BIODYNAMICS_CACHED_INTERPOLATION_BRANCH_DIR"
        ),
        stringr::str_glue("{branch_index_hash}.qs")
      )
    if (
      !base::file.exists(path_cached_branch)
    ) {
      cli::cli_abort(
        base::c(
          "The protected interpolation branch is unavailable.",
          "x" = path_cached_branch,
          "i" = "No interpolation was restarted automatically."
        )
      )
    }
    res_cached_branch <-
      base::tryCatch(
        qs2::qs_read(
          file = path_cached_branch,
          validate_checksum = FALSE
        ),
        error = function(err) err
      )
    if (
      base::inherits(res_cached_branch, "error")
    ) {
      cli::cli_abort(
        base::c(
          "The protected interpolation branch could not be read.",
          "x" = base::conditionMessage(res_cached_branch),
          "i" = "No interpolation was restarted automatically."
        )
      )
    }
    return(res_cached_branch)
  }

  list_interpolation_inputs <-
    base::list(data_community, data_age_uncertainty) |>
    purrr::map(
      .f = ~ {
        if (
          base::is.data.frame(.x)
        ) {
          return(.x)
        }
        assertthat::assert_that(
          base::is.list(.x) &&
            base::all(
              base::c("registry_key", "source_hash") %in%
                base::names(.x)
            ),
          msg = "shared inputs must be data frames or descriptors"
        )
        registry_key <-
          purrr::chuck(.x, "registry_key")
        path_shared_registry <-
          base::Sys.getenv(
            "BIODYNAMICS_INTERPOLATION_SHARED_REGISTRY",
            unset = ""
          )
        path_shared_name <-
          base::file.path(
            path_shared_registry,
            stringr::str_glue("{registry_key}.txt")
          )
        if (
          !base::nzchar(path_shared_registry) ||
            !base::file.exists(path_shared_name)
        ) {
          cli::cli_abort(
            base::c(
              "The live shared-memory input is unavailable.",
              "i" = base::paste(
                "Rerun the numbered preparation component to",
                "recreate its process-local shared inputs."
              )
            )
          )
        }
        shared_name <-
          base::readLines(
            con = path_shared_name,
            n = 1L,
            warn = FALSE
          )
        base::tryCatch(
          mori::map_shared(shared_name),
          error = function(err) {
            cli::cli_abort(
              base::c(
                "The live shared-memory input could not be mapped.",
                "x" = base::conditionMessage(err)
              )
            )
          }
        )
      }
    )
  data_community_resolved <-
    list_interpolation_inputs[[1L]]
  data_age_uncertainty_resolved <-
    list_interpolation_inputs[[2L]]

  vec_required_index_names <-
    base::c(
      "dataset_name",
      "flag_empty",
      "index_community_row_start",
      "index_community_row_end",
      "index_age_uncertainty_row_start",
      "index_age_uncertainty_row_end"
    )

  assertthat::assert_that(
    base::is.list(list_interpolation_index),
    msg = "list_interpolation_index must be a list"
  )
  assertthat::assert_that(
    base::all(
      vec_required_index_names %in%
        base::names(list_interpolation_index)
    ),
    msg = base::paste(
      "list_interpolation_index must contain dataset and row-range",
      "metadata"
    )
  )
  assertthat::assert_that(
    base::is.data.frame(data_community_resolved),
    msg = "data_community must be a data frame"
  )
  assertthat::assert_that(
    "dataset_name" %in% base::colnames(data_community_resolved),
    msg = "data_community must contain a `dataset_name` column"
  )
  assertthat::assert_that(
    base::is.data.frame(data_age_uncertainty_resolved),
    msg = "data_age_uncertainty must be a data frame"
  )
  assertthat::assert_that(
    "dataset_name" %in% base::colnames(data_age_uncertainty_resolved),
    msg = stringr::str_c(
      "data_age_uncertainty must contain a `dataset_name`",
      "column",
      sep = " "
    )
  )
  assertthat::assert_that(
    base::is.numeric(n_cores) &&
      base::length(n_cores) == 1L &&
      base::is.finite(n_cores) &&
      n_cores >= 1L &&
      n_cores == base::as.integer(n_cores),
    msg = "n_cores must be a single positive integer"
  )

  flag_empty <-
    purrr::chuck(list_interpolation_index, "flag_empty")
  assertthat::assert_that(
    assertthat::is.flag(flag_empty),
    msg = "flag_empty must be a single logical value"
  )

  vec_range_names <-
    vec_required_index_names[3:6]
  vec_range_values <-
    purrr::map(
      vec_range_names,
      ~ purrr::chuck(list_interpolation_index, .x)
    )
  flag_valid_range_values <-
    purrr::map_lgl(
      vec_range_values,
      ~ base::length(.x) == 1L &&
        (base::is.na(.x) ||
          (base::is.numeric(.x) &&
            base::is.finite(.x) &&
            .x == base::as.integer(.x)))
    )
  assertthat::assert_that(
    base::all(flag_valid_range_values),
    msg = "row-range values must be single integers or missing"
  )

  index_community_row_start <-
    purrr::chuck(
      list_interpolation_index,
      "index_community_row_start"
    )
  index_community_row_end <-
    purrr::chuck(
      list_interpolation_index,
      "index_community_row_end"
    )
  index_age_uncertainty_row_start <-
    purrr::chuck(
      list_interpolation_index,
      "index_age_uncertainty_row_start"
    )
  index_age_uncertainty_row_end <-
    purrr::chuck(
      list_interpolation_index,
      "index_age_uncertainty_row_end"
    )

  flag_community_range_missing <-
    base::is.na(index_community_row_start) ||
    base::is.na(index_community_row_end)
  flag_uncertainty_range_missing <-
    base::is.na(index_age_uncertainty_row_start) ||
    base::is.na(index_age_uncertainty_row_end)

  assertthat::assert_that(
    base::is.na(index_community_row_start) ==
      base::is.na(index_community_row_end),
    msg = "community row-range boundaries must both be present or missing"
  )
  assertthat::assert_that(
    base::is.na(index_age_uncertainty_row_start) ==
      base::is.na(index_age_uncertainty_row_end),
    msg = "uncertainty row-range boundaries must both be present or missing"
  )

  data_community_selected <-
    data_community_resolved |>
    dplyr::slice(0L)
  data_age_uncertainty_selected <-
    data_age_uncertainty_resolved |>
    dplyr::slice(0L)

  if (
    base::isTRUE(flag_empty)
  ) {
    assertthat::assert_that(
      flag_community_range_missing && flag_uncertainty_range_missing,
      msg = "empty index row ranges must be missing"
    )
  } else {
    dataset_name <-
      purrr::chuck(list_interpolation_index, "dataset_name")
    assertthat::assert_that(
      base::is.character(dataset_name) &&
        base::length(dataset_name) == 1L &&
        !base::is.na(dataset_name),
      msg = "dataset_name must be a single non-missing string"
    )
    assertthat::assert_that(
      !flag_community_range_missing &&
        index_community_row_start >= 1L &&
        index_community_row_end >= index_community_row_start &&
        index_community_row_end <=
          base::nrow(data_community_resolved),
      msg = "community row range is outside data_community"
    )

    data_community_selected <-
      data_community_resolved |>
      dplyr::slice(
        base::seq.int(
          index_community_row_start,
          index_community_row_end
        )
      )

    if (
      !flag_uncertainty_range_missing
    ) {
      assertthat::assert_that(
        index_age_uncertainty_row_start >= 1L &&
          index_age_uncertainty_row_end >=
            index_age_uncertainty_row_start &&
          index_age_uncertainty_row_end <=
            base::nrow(data_age_uncertainty_resolved),
        msg = base::paste(
          "uncertainty row range is outside",
          "data_age_uncertainty"
        )
      )
      data_age_uncertainty_selected <-
        data_age_uncertainty_resolved |>
        dplyr::slice(
          base::seq.int(
            index_age_uncertainty_row_start,
            index_age_uncertainty_row_end
          )
        )
    }

    assertthat::assert_that(
      base::all(
        data_community_selected[["dataset_name"]] == dataset_name
      ),
      msg = "community row range does not match dataset_name"
    )
    assertthat::assert_that(
      base::all(
        data_age_uncertainty_selected[["dataset_name"]] ==
          dataset_name
      ),
      msg = "uncertainty row range does not match dataset_name"
    )
  }

  res_community_interpolated <-
    interpolate_paleo_community_with_age_uncertainty(
      data_community = data_community_selected,
      data_age_uncertainty = data_age_uncertainty_selected,
      n_cores = n_cores,
      ...
    )

  return(res_community_interpolated)
}
