testthat::test_that(
  "make_community_interpolation_jobs() splits datasets",
  {
    data_community <-
      tibble::tibble(
        dataset_name = base::c("core1", "core1", "grid1"),
        sample_name = base::c("a", "b", "c"),
        taxon = "Taxon",
        age = base::c(100, 200, 100),
        value = base::c(0.2, 0.3, 0.5)
      )

    data_uncertainty <-
      tibble::tibble(
        dataset_name = "core1",
        sample_name = base::c("a", "b"),
        iteration = 1L,
        age_uncertainty = base::c(110, 210)
      )

    list_jobs <-
      make_community_interpolation_jobs(
        data = data_community,
        data_age_uncertainty = data_uncertainty
      )

    testthat::expect_length(list_jobs, 2L)

    vec_job_names <-
      purrr::map_chr(
        list_jobs,
        ~ dplyr::pull(purrr::chuck(.x, "data"), dataset_name)[[1L]]
      )

    testthat::expect_setequal(
      vec_job_names,
      base::c("core1", "grid1")
    )

    list_core_job <-
      list_jobs[[base::match("core1", vec_job_names)]]

    testthat::expect_equal(
      base::nrow(purrr::chuck(list_core_job, "data_age_uncertainty")),
      2L
    )

    list_grid_job <-
      list_jobs[[base::match("grid1", vec_job_names)]]

    testthat::expect_equal(
      base::nrow(purrr::chuck(list_grid_job, "data_age_uncertainty")),
      0L
    )
  }
)

testthat::test_that(
  "make_community_interpolation_jobs() validates dataset columns",
  {
    data_valid <-
      tibble::tibble(dataset_name = "core1")

    testthat::expect_error(
      make_community_interpolation_jobs(
        data = tibble::tibble(value = 1),
        data_age_uncertainty = data_valid
      ),
      regexp = "dataset_name"
    )

    testthat::expect_error(
      make_community_interpolation_jobs(
        data = data_valid,
        data_age_uncertainty = tibble::tibble(value = 1)
      ),
      regexp = "dataset_name"
    )
  }
)
