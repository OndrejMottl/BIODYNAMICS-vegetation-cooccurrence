# Input Validation (no external database required)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault errors for NULL plan",
  {
    data_mapping <-
      tibble::tibble(
        dataset_name = "core1",
        sample_name = "s1"
      )

    testthat::expect_error(
      extract_age_uncertainty_from_vegvault(
        plan = NULL,
        data_sample_mapping = data_mapping
      ),
      regexp = "plan"
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault errors for invalid mapping",
  {
    fake_plan <-
      base::list()

    testthat::expect_error(
      extract_age_uncertainty_from_vegvault(
        plan = fake_plan,
        data_sample_mapping = "not_a_df"
      ),
      regexp = "data_sample_mapping"
    )

    testthat::expect_error(
      extract_age_uncertainty_from_vegvault(
        plan = fake_plan,
        data_sample_mapping = tibble::tibble(x = 1)
      ),
      regexp = "dataset_name"
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault errors for invalid verbose",
  {
    fake_plan <-
      base::list()

    data_mapping <-
      tibble::tibble(
        dataset_name = "core1",
        sample_name = "s1"
      )

    testthat::expect_error(
      extract_age_uncertainty_from_vegvault(
        plan = fake_plan,
        data_sample_mapping = data_mapping,
        verbose = "yes"
      ),
      regexp = "verbose"
    )
  }
)

# Behaviour tests with mocked vaultkeepr (no real DB required)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault returns empty tibble on no data",
  {
    fake_plan <-
      base::list()

    data_mapping <-
      tibble::tibble(
        dataset_name = "core1",
        sample_name = "s1"
      )

    testthat::local_mocked_bindings(
      get_age_uncertainty = function(...) {
        tibble::tibble(sample_name = character())
      },
      .package = "vaultkeepr"
    )

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = fake_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_equal(base::nrow(res), 0L)

    expected_cols <-
      base::c(
        "dataset_name",
        "sample_name",
        "iteration",
        "age_uncertainty"
      )

    testthat::expect_true(
      base::all(expected_cols %in% base::colnames(res))
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault returns long tibble",
  {
    fake_plan <-
      base::list()

    data_mapping <-
      tibble::tibble(
        dataset_name = base::c("core1", "core1"),
        sample_name = base::c("s1", "s2")
      )

    testthat::local_mocked_bindings(
      get_age_uncertainty = function(...) {
        tibble::tibble(
          sample_name = base::c("s1", "s2"),
          iteration_1 = base::c(100.0, 200.0),
          iteration_2 = base::c(110.0, 210.0)
        )
      },
      .package = "vaultkeepr"
    )

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = fake_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_equal(base::nrow(res), 4L)

    expected_cols <-
      base::c(
        "dataset_name",
        "sample_name",
        "iteration",
        "age_uncertainty"
      )

    testthat::expect_named(
      res,
      expected = expected_cols,
      ignore.order = TRUE
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault drops NA age estimates",
  {
    fake_plan <-
      base::list()

    data_mapping <-
      tibble::tibble(
        dataset_name = "core1",
        sample_name = "s1"
      )

    testthat::local_mocked_bindings(
      get_age_uncertainty = function(...) {
        tibble::tibble(
          sample_name = "s1",
          iteration_1 = NA_real_,
          iteration_2 = 200.0
        )
      },
      .package = "vaultkeepr"
    )

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = fake_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::expect_equal(base::nrow(res), 1L)

    testthat::expect_false(
      base::any(base::is.na(dplyr::pull(res, age_uncertainty)))
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault integer iteration col",
  {
    fake_plan <-
      base::list()

    data_mapping <-
      tibble::tibble(
        dataset_name = "core1",
        sample_name = "s1"
      )

    testthat::local_mocked_bindings(
      get_age_uncertainty = function(...) {
        tibble::tibble(
          sample_name = "s1",
          iteration_1 = 100.0,
          iteration_2 = 200.0
        )
      },
      .package = "vaultkeepr"
    )

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = fake_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::expect_type(
      dplyr::pull(res, iteration),
      "integer"
    )

    testthat::expect_true(
      base::all(dplyr::pull(res, iteration) >= 1L)
    )
  }
)

# Output Structure (VegVault database required)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault returns tibble with cols",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(12, 18.9),
        y_lim = c(48.5, 51.5),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    data_mapping <-
      res_plan |>
      vaultkeepr::get_taxa() |>
      vaultkeepr::extract_data(
        return_raw_data = FALSE,
        verbose = FALSE
      ) |>
      dplyr::select("dataset_name", "data_samples") |>
      tidyr::unnest(data_samples) |>
      dplyr::select("dataset_name", "sample_name") |>
      dplyr::distinct()

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "data.frame")

    expected_cols <-
      base::c(
        "dataset_name",
        "sample_name",
        "iteration",
        "age_uncertainty"
      )

    testthat::expect_true(
      base::all(expected_cols %in% base::colnames(res))
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault col types are correct",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(12, 18.9),
        y_lim = c(48.5, 51.5),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    data_mapping <-
      res_plan |>
      vaultkeepr::get_taxa() |>
      vaultkeepr::extract_data(
        return_raw_data = FALSE,
        verbose = FALSE
      ) |>
      dplyr::select("dataset_name", "data_samples") |>
      tidyr::unnest(data_samples) |>
      dplyr::select("dataset_name", "sample_name") |>
      dplyr::distinct()

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::skip_if(
      base::nrow(res) == 0L,
      "No data returned for Czech bounds"
    )

    testthat::expect_type(
      dplyr::pull(res, dataset_name),
      "character"
    )

    testthat::expect_type(
      dplyr::pull(res, sample_name),
      "character"
    )

    testthat::expect_type(
      dplyr::pull(res, iteration),
      "integer"
    )

    testthat::expect_type(
      dplyr::pull(res, age_uncertainty),
      "double"
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault has no NA age_uncertainty",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(12, 18.9),
        y_lim = c(48.5, 51.5),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    data_mapping <-
      res_plan |>
      vaultkeepr::get_taxa() |>
      vaultkeepr::extract_data(
        return_raw_data = FALSE,
        verbose = FALSE
      ) |>
      dplyr::select("dataset_name", "data_samples") |>
      tidyr::unnest(data_samples) |>
      dplyr::select("dataset_name", "sample_name") |>
      dplyr::distinct()

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::skip_if(
      base::nrow(res) == 0L,
      "No data returned for Czech bounds"
    )

    testthat::expect_false(
      base::any(base::is.na(dplyr::pull(res, age_uncertainty)))
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault has positive iteration values",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(12, 18.9),
        y_lim = c(48.5, 51.5),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    data_mapping <-
      res_plan |>
      vaultkeepr::get_taxa() |>
      vaultkeepr::extract_data(
        return_raw_data = FALSE,
        verbose = FALSE
      ) |>
      dplyr::select("dataset_name", "data_samples") |>
      tidyr::unnest(data_samples) |>
      dplyr::select("dataset_name", "sample_name") |>
      dplyr::distinct()

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::skip_if(
      base::nrow(res) == 0L,
      "No data returned for Czech bounds"
    )

    testthat::expect_true(
      base::all(dplyr::pull(res, iteration) >= 1L)
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault returns data for >1 dataset",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(12, 18.9),
        y_lim = c(48.5, 51.5),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    data_mapping <-
      res_plan |>
      vaultkeepr::get_taxa() |>
      vaultkeepr::extract_data(
        return_raw_data = FALSE,
        verbose = FALSE
      ) |>
      dplyr::select("dataset_name", "data_samples") |>
      tidyr::unnest(data_samples) |>
      dplyr::select("dataset_name", "sample_name") |>
      dplyr::distinct()

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    n_datasets <-
      dplyr::n_distinct(dplyr::pull(res, dataset_name))

    testthat::expect_gt(n_datasets, 1L)
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault empty tibble when no data",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(150, 160),
        y_lim = c(-10, 0),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    data_mapping <-
      tibble::tibble(
        dataset_name = character(),
        sample_name = character()
      )

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_equal(base::nrow(res), 0L)

    expected_cols <-
      base::c(
        "dataset_name",
        "sample_name",
        "iteration",
        "age_uncertainty"
      )

    testthat::expect_true(
      base::all(expected_cols %in% base::colnames(res))
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault verbose=FALSE is silent",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(12, 18.9),
        y_lim = c(48.5, 51.5),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    data_mapping <-
      res_plan |>
      vaultkeepr::get_taxa() |>
      vaultkeepr::extract_data(
        return_raw_data = FALSE,
        verbose = FALSE
      ) |>
      dplyr::select("dataset_name", "data_samples") |>
      tidyr::unnest(data_samples) |>
      dplyr::select("dataset_name", "sample_name") |>
      dplyr::distinct()

    testthat::expect_no_message(
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )
    )
  }
)

# Integration tests (requires VegVault database)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault returns expected columns (DB)",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(12, 18.9),
        y_lim = c(48.5, 51.5),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    data_mapping <-
      res_plan |>
      vaultkeepr::get_taxa() |>
      vaultkeepr::extract_data(
        return_raw_data = FALSE,
        verbose = FALSE
      ) |>
      dplyr::select("dataset_name", "data_samples") |>
      tidyr::unnest(data_samples) |>
      dplyr::select("dataset_name", "sample_name") |>
      dplyr::distinct()

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "data.frame")

    expected_cols <-
      base::c(
        "dataset_name",
        "sample_name",
        "iteration",
        "age_uncertainty"
      )

    testthat::expect_true(
      base::all(expected_cols %in% base::colnames(res))
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault col types are correct",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(12, 18.9),
        y_lim = c(48.5, 51.5),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    data_mapping <-
      res_plan |>
      vaultkeepr::get_taxa() |>
      vaultkeepr::extract_data(
        return_raw_data = FALSE,
        verbose = FALSE
      ) |>
      dplyr::select("dataset_name", "data_samples") |>
      tidyr::unnest(data_samples) |>
      dplyr::select("dataset_name", "sample_name") |>
      dplyr::distinct()

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::skip_if(
      base::nrow(res) == 0L,
      "No data returned for Czech bounds"
    )

    testthat::expect_type(
      dplyr::pull(res, dataset_name),
      "character"
    )

    testthat::expect_type(
      dplyr::pull(res, sample_name),
      "character"
    )

    testthat::expect_type(
      dplyr::pull(res, iteration),
      "integer"
    )

    testthat::expect_type(
      dplyr::pull(res, age_uncertainty),
      "double"
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault has no NA age_uncertainty",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(12, 18.9),
        y_lim = c(48.5, 51.5),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    data_mapping <-
      res_plan |>
      vaultkeepr::get_taxa() |>
      vaultkeepr::extract_data(
        return_raw_data = FALSE,
        verbose = FALSE
      ) |>
      dplyr::select("dataset_name", "data_samples") |>
      tidyr::unnest(data_samples) |>
      dplyr::select("dataset_name", "sample_name") |>
      dplyr::distinct()

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::skip_if(
      base::nrow(res) == 0L,
      "No data returned for Czech bounds"
    )

    testthat::expect_false(
      base::any(base::is.na(dplyr::pull(res, age_uncertainty)))
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault has positive iteration values",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(12, 18.9),
        y_lim = c(48.5, 51.5),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    data_mapping <-
      res_plan |>
      vaultkeepr::get_taxa() |>
      vaultkeepr::extract_data(
        return_raw_data = FALSE,
        verbose = FALSE
      ) |>
      dplyr::select("dataset_name", "data_samples") |>
      tidyr::unnest(data_samples) |>
      dplyr::select("dataset_name", "sample_name") |>
      dplyr::distinct()

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::skip_if(
      base::nrow(res) == 0L,
      "No data returned for Czech bounds"
    )

    testthat::expect_true(
      base::all(dplyr::pull(res, iteration) >= 1L)
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault returns data for >1 dataset",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(12, 18.9),
        y_lim = c(48.5, 51.5),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    data_mapping <-
      res_plan |>
      vaultkeepr::get_taxa() |>
      vaultkeepr::extract_data(
        return_raw_data = FALSE,
        verbose = FALSE
      ) |>
      dplyr::select("dataset_name", "data_samples") |>
      tidyr::unnest(data_samples) |>
      dplyr::select("dataset_name", "sample_name") |>
      dplyr::distinct()

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    n_datasets <-
      dplyr::n_distinct(dplyr::pull(res, dataset_name))

    testthat::expect_gt(n_datasets, 1L)
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault returns empty tibble when no data",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    # Bounds in the open ocean — no fossil pollen archives expected.
    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(150, 160),
        y_lim = c(-10, 0),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    # No data in ocean bounds so supply an empty mapping directly
    data_mapping <-
      tibble::tibble(
        dataset_name = character(),
        sample_name = character()
      )

    res <-
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "data.frame")
    testthat::expect_equal(base::nrow(res), 0L)

    expected_cols <-
      base::c(
        "dataset_name",
        "sample_name",
        "iteration",
        "age_uncertainty"
      )

    testthat::expect_true(
      base::all(expected_cols %in% base::colnames(res))
    )
  }
)

testthat::test_that(
  "extract_age_uncertainty_from_vegvault verbose = FALSE is silent",
  {
    test_db <-
      here::here("Data/Input/VegVault.sqlite")

    testthat::skip_if_not(
      base::file.exists(test_db),
      "VegVault database not available"
    )

    res_plan <-
      build_vegvault_plan(
        path_to_vegvault = test_db,
        x_lim = c(12, 18.9),
        y_lim = c(48.5, 51.5),
        age_lim = c(0, 5000),
        sel_dataset_type = "fossil_pollen_archive"
      )

    data_mapping <-
      res_plan |>
      vaultkeepr::get_taxa() |>
      vaultkeepr::extract_data(
        return_raw_data = FALSE,
        verbose = FALSE
      ) |>
      dplyr::select("dataset_name", "data_samples") |>
      tidyr::unnest(data_samples) |>
      dplyr::select("dataset_name", "sample_name") |>
      dplyr::distinct()

    testthat::expect_no_message(
      extract_age_uncertainty_from_vegvault(
        plan = res_plan,
        data_sample_mapping = data_mapping,
        verbose = FALSE
      )
    )
  }
)
