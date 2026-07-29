#' @title Make Community Interpolation Jobs
#' @description
#' Splits paleo community and age-uncertainty data into independent
#' per-dataset interpolation jobs for dynamic targets branching.
#' @param data
#' A data frame containing a `dataset_name` column and community data.
#' @param data_age_uncertainty
#' A data frame containing a `dataset_name` column and age-model data.
#' Datasets without matching uncertainty rows receive an empty tibble.
#' @return
#' A list of jobs. Each job contains `data` and
#' `data_age_uncertainty` elements for one dataset.
#' @details
#' Each job is self-contained so a dynamic target branch only retrieves
#' one dataset instead of loading the complete continental inputs.
#' @seealso [interpolate_community_data_with_uncertainty()]
#' @export
make_community_interpolation_jobs <- function(
    data,
    data_age_uncertainty) {
  assertthat::assert_that(
    base::is.data.frame(data),
    msg = "data must be a data frame"
  )

  assertthat::assert_that(
    "dataset_name" %in% base::colnames(data),
    msg = "data must contain a 'dataset_name' column"
  )

  assertthat::assert_that(
    base::is.data.frame(data_age_uncertainty),
    msg = "data_age_uncertainty must be a data frame"
  )

  assertthat::assert_that(
    "dataset_name" %in% base::colnames(data_age_uncertainty),
    msg = "data_age_uncertainty must contain a 'dataset_name' column"
  )

  data_uncertainty_empty <-
    data_age_uncertainty |>
    dplyr::slice(0L)

  if (
    base::nrow(data) == 0L
  ) {
    # targets::tar_make_future() cannot branch over an empty upstream
    # list; return one empty job so downstream interpolation resolves to
    # an empty tibble instead of a branching error.
    return(
      base::list(
        base::list(
          data = data,
          data_age_uncertainty = data_uncertainty_empty
        )
      )
    )
  }

  data_jobs <-
    data |>
    tidyr::nest(data = -dataset_name) |>
    dplyr::left_join(
      data_age_uncertainty |>
        tidyr::nest(data_age_uncertainty = -dataset_name),
      by = dplyr::join_by(dataset_name)
    ) |>
    dplyr::mutate(
      data = purrr::map2(
        dataset_name,
        data,
        ~ dplyr::mutate(
          .y,
          dataset_name = base::rep(.x, base::nrow(.y)),
          .before = 1L
        )
      ),
      data_age_uncertainty = purrr::map2(
        dataset_name,
        data_age_uncertainty,
        ~ {
          if (
            base::is.null(.y)
          ) {
            return(data_uncertainty_empty)
          }

          dplyr::mutate(
            .y,
            dataset_name = base::rep(.x, base::nrow(.y)),
            .before = 1L
          )
        }
      )
    )

  res_jobs <-
    purrr::map2(
      dplyr::pull(data_jobs, data),
      dplyr::pull(data_jobs, data_age_uncertainty),
      ~ base::list(
        data = .x,
        data_age_uncertainty = .y
      )
    )

  base::return(res_jobs)
}
