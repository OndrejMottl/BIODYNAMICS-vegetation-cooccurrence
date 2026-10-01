testthat::test_that(
  "interpolate shared inputs requires complete row-range metadata",
  {
    data_input <- tibble::tibble(dataset_name = "core_a")

    testthat::expect_error(
      interpolate_community_dataset_from_shared_inputs(
        list_interpolation_index = base::list(
          dataset_name = "core_a",
          flag_empty = FALSE
        ),
        data_community = data_input,
        data_age_uncertainty = data_input
      ),
      regexp = "row-range"
    )
  }
)

testthat::test_that(
  "interpolate shared inputs matches a directly filtered call",
  {
    path_registry <- withr::local_tempdir()
    withr::local_envvar(
      BIODYNAMICS_INTERPOLATION_SHARED_REGISTRY = path_registry
    )
    data_community <-
      tibble::tibble(
        dataset_name = base::c("core_a", "core_a", "core_b"),
        sample_name = base::c("sample_a", "sample_b", "sample_c"),
        taxon = "Taxon",
        age = base::c(0, 500, 0),
        value = base::c(0, 1, 0.5)
      )
    data_uncertainty <-
      tibble::tibble(
        dataset_name = base::character(),
        sample_name = base::character(),
        iteration = base::integer(),
        age_uncertainty = base::numeric()
      )
    list_index <-
      build_community_interpolation_index(
        data_community = data_community,
        data_age_uncertainty = data_uncertainty
      )
    data_expected <-
      interpolate_paleo_community_with_age_uncertainty(
        data_community = dplyr::slice(data_community, 1:2),
        data_age_uncertainty = data_uncertainty,
        age_min = 0,
        age_max = 500,
        time_step = 500,
        n_cores = 1L
      )

    data_actual <-
      interpolate_community_dataset_from_shared_inputs(
        list_interpolation_index = list_index[[1L]],
        data_community = build_shared_interpolation_data(
          data_interpolation = data_community
        ),
        data_age_uncertainty = build_shared_interpolation_data(
          data_interpolation = data_uncertainty
        ),
        age_min = 0,
        age_max = 500,
        time_step = 500,
        n_cores = 1L
      )

    testthat::expect_equal(data_actual, data_expected)
  }
)

testthat::test_that(
  "interpolate shared inputs validates range boundaries",
  {
    data_input <- tibble::tibble(dataset_name = "core_a")
    list_index <-
      base::list(
        dataset_name = "core_a",
        flag_empty = FALSE,
        index_community_row_start = 1L,
        index_community_row_end = 2L,
        index_age_uncertainty_row_start = NA_integer_,
        index_age_uncertainty_row_end = NA_integer_
      )

    testthat::expect_error(
      interpolate_community_dataset_from_shared_inputs(
        list_interpolation_index = list_index,
        data_community = data_input,
        data_age_uncertainty = data_input
      ),
      regexp = "outside data_community"
    )

    list_index[["index_community_row_end"]] <- 1L
    list_index[["index_age_uncertainty_row_start"]] <- 1L
    testthat::expect_error(
      interpolate_community_dataset_from_shared_inputs(
        list_interpolation_index = list_index,
        data_community = data_input,
        data_age_uncertainty = data_input
      ),
      regexp = "both be present or missing"
    )
  }
)

testthat::test_that(
  "interpolate shared inputs handles an empty index",
  {
    data_community <-
      tibble::tibble(
        dataset_name = base::character(),
        sample_name = base::character(),
        taxon = base::character(),
        age = base::numeric(),
        value = base::numeric()
      )
    data_uncertainty <-
      tibble::tibble(
        dataset_name = base::character(),
        sample_name = base::character(),
        iteration = base::integer(),
        age_uncertainty = base::numeric()
      )
    list_index <-
      build_community_interpolation_index(
        data_community = data_community,
        data_age_uncertainty = data_uncertainty
      )

    data_actual <-
      interpolate_community_dataset_from_shared_inputs(
        list_interpolation_index = list_index[[1L]],
        data_community = data_community,
        data_age_uncertainty = data_uncertainty,
        age_min = 0,
        age_max = 500,
        time_step = 500,
        n_cores = 1L
      )

    testthat::expect_s3_class(data_actual, "data.frame")
    testthat::expect_equal(base::nrow(data_actual), 0L)
    testthat::expect_equal(
      base::colnames(data_actual),
      base::c("dataset_name", "taxon", "age", "value")
    )
  }
)

testthat::test_that(
  "interpolate shared inputs replays a protected legacy branch",
  {
    path_recovery <- withr::local_tempdir()
    dataset_name <- "core_a"
    branch_index_hash <-
      digest::digest(
        object = dataset_name,
        algo = "xxhash64",
        serialize = TRUE
      )
    data_cached <-
      tibble::tibble(
        dataset_name = dataset_name,
        taxon = "Taxon",
        age = 0,
        value = 0.5
      )
    qs2::qs_save(
      object = data_cached,
      file = base::file.path(
        path_recovery,
        stringr::str_glue("{branch_index_hash}.qs")
      )
    )
    withr::local_envvar(
      BIODYNAMICS_REUSE_CACHED_INTERPOLATION_BRANCHES = "true",
      BIODYNAMICS_CACHED_INTERPOLATION_BRANCH_DIR = path_recovery
    )

    data_actual <-
      interpolate_community_dataset_from_shared_inputs(
        list_interpolation_index = base::list(
          dataset_name = dataset_name
        )
      )

    testthat::expect_equal(data_actual, data_cached)
  }
)

testthat::test_that(
  "interpolate shared inputs never replaces a missing protected branch",
  {
    path_recovery <- withr::local_tempdir()
    withr::local_envvar(
      BIODYNAMICS_REUSE_CACHED_INTERPOLATION_BRANCHES = "true",
      BIODYNAMICS_CACHED_INTERPOLATION_BRANCH_DIR = path_recovery
    )

    testthat::expect_error(
      interpolate_community_dataset_from_shared_inputs(
        list_interpolation_index = base::list(
          dataset_name = "core_a"
        )
      ),
      "No interpolation was restarted automatically",
      fixed = TRUE
    )
  }
)
