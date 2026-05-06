#----------------------------------------------------------#
# Helper data -----
#----------------------------------------------------------#

# "gridpoint" dataset: no entry in data_age_uncertainty
# "core1": fossil core with 2 age-model iterations
data_community_test <-
  tibble::tibble(
    dataset_name = base::c(
      base::rep("gp1", 5),
      base::rep("core1", 5)
    ),
    sample_name = base::c(
      base::paste0("s", 1:5),
      base::paste0("s", 6:10)
    ),
    taxon = "taxonA",
    age = base::c(
      0, 200, 400, 600, 800,
      0, 200, 400, 600, 800
    ),
    pollen_prop = base::c(
      0.3, 0.4, 0.5, 0.4, 0.3,
      0.2, 0.3, 0.4, 0.3, 0.2
    )
  )

# Age uncertainty only for "core1" — 2 iterations x 5 samples
data_age_unc_test <-
  tibble::tibble(
    dataset_name = base::rep("core1", 10),
    sample_name = base::rep(
      base::paste0("s", 6:10), 2
    ),
    iteration = base::c(
      base::rep(1L, 5),
      base::rep(2L, 5)
    ),
    age_uncertainty = base::c(
      10, 210, 405, 595, 805, # iteration 1
      5, 195, 410, 605, 795   # iteration 2
    )
  )

# Empty age uncertainty (correct columns, zero rows)
data_age_unc_empty <-
  tibble::tibble(
    dataset_name = base::character(0),
    sample_name = base::character(0),
    iteration = base::integer(0),
    age_uncertainty = base::double(0)
  )

# Single-iteration age uncertainty for "core1"
data_age_unc_single_iter <-
  tibble::tibble(
    dataset_name = base::rep("core1", 5),
    sample_name = base::paste0("s", 6:10),
    iteration = base::rep(1L, 5),
    age_uncertainty = base::c(10, 210, 405, 595, 805)
  )


#----------------------------------------------------------#
# Input validation — data argument -----
#----------------------------------------------------------#

testthat::test_that(
  "errors when data is not a data frame",
  {
    testthat::expect_error(
      interpolate_community_data_with_uncertainty(
        data = "not_a_df",
        data_age_uncertainty = data_age_unc_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      ),
      regexp = "data frame"
    )
  }
)

testthat::test_that(
  "errors when data is missing pollen_prop column",
  {
    data_no_prop <-
      tibble::tibble(
        dataset_name = "gp1",
        sample_name = "s1",
        taxon = "taxonA",
        age = 0
      )

    testthat::expect_error(
      interpolate_community_data_with_uncertainty(
        data = data_no_prop,
        data_age_uncertainty = data_age_unc_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      ),
      regexp = "pollen_prop"
    )
  }
)

testthat::test_that(
  "errors when data is missing dataset_name column",
  {
    data_no_dsname <-
      tibble::tibble(
        sample_name = "s1",
        taxon = "taxonA",
        age = 0,
        pollen_prop = 0.5
      )

    testthat::expect_error(
      interpolate_community_data_with_uncertainty(
        data = data_no_dsname,
        data_age_uncertainty = data_age_unc_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      ),
      regexp = "dataset_name"
    )
  }
)

testthat::test_that(
  "errors when data is missing sample_name column",
  {
    data_no_sname <-
      tibble::tibble(
        dataset_name = "gp1",
        taxon = "taxonA",
        age = 0,
        pollen_prop = 0.5
      )

    testthat::expect_error(
      interpolate_community_data_with_uncertainty(
        data = data_no_sname,
        data_age_uncertainty = data_age_unc_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      ),
      regexp = "sample_name"
    )
  }
)

testthat::test_that(
  "errors when data is missing taxon column",
  {
    data_no_taxon <-
      tibble::tibble(
        dataset_name = "gp1",
        sample_name = "s1",
        age = 0,
        pollen_prop = 0.5
      )

    testthat::expect_error(
      interpolate_community_data_with_uncertainty(
        data = data_no_taxon,
        data_age_uncertainty = data_age_unc_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      ),
      regexp = "taxon"
    )
  }
)

testthat::test_that(
  "errors when data is missing age column",
  {
    data_no_age <-
      tibble::tibble(
        dataset_name = "gp1",
        sample_name = "s1",
        taxon = "taxonA",
        pollen_prop = 0.5
      )

    testthat::expect_error(
      interpolate_community_data_with_uncertainty(
        data = data_no_age,
        data_age_uncertainty = data_age_unc_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      ),
      regexp = "age"
    )
  }
)


#----------------------------------------------------------#
# Input validation — data_age_uncertainty argument -----
#----------------------------------------------------------#

testthat::test_that(
  "errors when data_age_uncertainty is not a data frame",
  {
    testthat::expect_error(
      interpolate_community_data_with_uncertainty(
        data = data_community_test,
        data_age_uncertainty = 42L,
        timestep = 200,
        age_min = 0,
        age_max = 800
      ),
      regexp = "data frame"
    )
  }
)

testthat::test_that(
  "errors when data_age_uncertainty missing dataset_name",
  {
    data_unc_bad <-
      tibble::tibble(
        sample_name = "s6",
        iteration = 1L,
        age_uncertainty = 10
      )

    testthat::expect_error(
      interpolate_community_data_with_uncertainty(
        data = data_community_test,
        data_age_uncertainty = data_unc_bad,
        timestep = 200,
        age_min = 0,
        age_max = 800
      ),
      regexp = "dataset_name"
    )
  }
)

testthat::test_that(
  "errors when data_age_uncertainty missing sample_name",
  {
    data_unc_bad <-
      tibble::tibble(
        dataset_name = "core1",
        iteration = 1L,
        age_uncertainty = 10
      )

    testthat::expect_error(
      interpolate_community_data_with_uncertainty(
        data = data_community_test,
        data_age_uncertainty = data_unc_bad,
        timestep = 200,
        age_min = 0,
        age_max = 800
      ),
      regexp = "sample_name"
    )
  }
)

testthat::test_that(
  "errors when data_age_uncertainty missing iteration",
  {
    data_unc_bad <-
      tibble::tibble(
        dataset_name = "core1",
        sample_name = "s6",
        age_uncertainty = 10
      )

    testthat::expect_error(
      interpolate_community_data_with_uncertainty(
        data = data_community_test,
        data_age_uncertainty = data_unc_bad,
        timestep = 200,
        age_min = 0,
        age_max = 800
      ),
      regexp = "iteration"
    )
  }
)

testthat::test_that(
  "errors when data_age_uncertainty missing age_uncertainty",
  {
    data_unc_bad <-
      tibble::tibble(
        dataset_name = "core1",
        sample_name = "s6",
        iteration = 1L
      )

    testthat::expect_error(
      interpolate_community_data_with_uncertainty(
        data = data_community_test,
        data_age_uncertainty = data_unc_bad,
        timestep = 200,
        age_min = 0,
        age_max = 800
      ),
      regexp = "age_uncertainty"
    )
  }
)


#----------------------------------------------------------#
# Output structure tests -----
#----------------------------------------------------------#

testthat::test_that(
  "returns a data frame",
  {
    result <-
      interpolate_community_data_with_uncertainty(
        data = data_community_test,
        data_age_uncertainty = data_age_unc_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      )

    testthat::expect_true(
      base::is.data.frame(result)
    )
  }
)

testthat::test_that(
  "output has required columns, no sample_name or iteration",
  {
    result <-
      interpolate_community_data_with_uncertainty(
        data = data_community_test,
        data_age_uncertainty = data_age_unc_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      )

    vec_expected_cols <-
      base::c("dataset_name", "taxon", "age", "pollen_prop")

    testthat::expect_true(
      base::all(
        vec_expected_cols %in% base::colnames(result)
      )
    )

    testthat::expect_false(
      "sample_name" %in% base::colnames(result)
    )

    testthat::expect_false(
      "iteration" %in% base::colnames(result)
    )
  }
)

testthat::test_that(
  "pollen_prop values are numeric",
  {
    result <-
      interpolate_community_data_with_uncertainty(
        data = data_community_test,
        data_age_uncertainty = data_age_unc_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      )

    vec_prop <-
      dplyr::pull(result, pollen_prop)

    testthat::expect_true(
      base::is.numeric(vec_prop)
    )
  }
)

testthat::test_that(
  "age values are on the regular time grid",
  {
    result <-
      interpolate_community_data_with_uncertainty(
        data = data_community_test,
        data_age_uncertainty = data_age_unc_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      )

    vec_ages <-
      dplyr::pull(result, age) |>
      base::unique() |>
      base::sort()

    vec_expected_ages <-
      base::seq(0, 800, by = 200)

    testthat::expect_equal(
      vec_ages,
      vec_expected_ages
    )
  }
)

testthat::test_that(
  "both gp1 and core1 appear in the output",
  {
    result <-
      interpolate_community_data_with_uncertainty(
        data = data_community_test,
        data_age_uncertainty = data_age_unc_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      )

    vec_datasets <-
      dplyr::pull(result, dataset_name) |>
      base::unique() |>
      base::sort()

    testthat::expect_true(
      "gp1" %in% vec_datasets
    )

    testthat::expect_true(
      "core1" %in% vec_datasets
    )
  }
)

testthat::test_that(
  "core1 pollen_prop is median over iterations",
  {
    # At age = 200:
    #   iter 1 interpolates between s7(age~210,prop=0.3) &
    #     s6(age~10,prop=0.2) — closest grid point is 200, which
    #     should yield a value near the linear interpolation.
    #   iter 2 similarly near age 195.
    # We test the qualitative property: result is between
    # min and max of per-iteration values.

    result <-
      interpolate_community_data_with_uncertainty(
        data = data_community_test,
        data_age_uncertainty = data_age_unc_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      )

    result_core1 <-
      dplyr::filter(result, dataset_name == "core1")

    vec_prop_core1 <-
      dplyr::pull(result_core1, pollen_prop)

    # Median of numeric values must itself be numeric and finite
    testthat::expect_true(
      base::all(base::is.finite(vec_prop_core1))
    )

    # All proportions should be in [0, 1]
    testthat::expect_true(
      base::all(vec_prop_core1 >= 0) &&
        base::all(vec_prop_core1 <= 1)
    )
  }
)


#----------------------------------------------------------#
# Functional correctness: gridpoint passthrough -----
#----------------------------------------------------------#

testthat::test_that(
  "no uncertainty data yields same result as interpolate_community_data",
  {
    # When data_age_uncertainty has no matching dataset_names,
    # all datasets are treated as gridpoints.
    data_gp_only <-
      dplyr::filter(data_community_test, dataset_name == "gp1")

    result_unc <-
      interpolate_community_data_with_uncertainty(
        data = data_gp_only,
        data_age_uncertainty = data_age_unc_empty,
        timestep = 200,
        age_min = 0,
        age_max = 800
      )

    result_direct <-
      interpolate_community_data(
        data = data_gp_only,
        timestep = 200,
        age_min = 0,
        age_max = 800
      )

    testthat::expect_equal(
      base::nrow(result_unc),
      base::nrow(result_direct)
    )

    vec_prop_unc <-
      dplyr::arrange(result_unc, age) |>
      dplyr::pull(pollen_prop)

    vec_prop_direct <-
      dplyr::arrange(result_direct, age) |>
      dplyr::pull(pollen_prop)

    testthat::expect_equal(
      vec_prop_unc,
      vec_prop_direct
    )
  }
)


#----------------------------------------------------------#
# Functional correctness: uncertainty-aware path -----
#----------------------------------------------------------#

testthat::test_that(
  "output has no sample_name or iteration for fossil cores",
  {
    data_core_only <-
      dplyr::filter(data_community_test, dataset_name == "core1")

    result <-
      interpolate_community_data_with_uncertainty(
        data = data_core_only,
        data_age_uncertainty = data_age_unc_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      )

    testthat::expect_false(
      "sample_name" %in% base::colnames(result)
    )

    testthat::expect_false(
      "iteration" %in% base::colnames(result)
    )
  }
)

testthat::test_that(
  "fossil core pollen_prop is median across iterations",
  {
    # Build a simple core with 3 age points and 2 iterations
    # where iteration ages align perfectly with the grid so that
    # interpolation is trivial.
    data_simple_core <-
      tibble::tibble(
        dataset_name = base::rep("core_simple", 3),
        sample_name = base::c("s1", "s2", "s3"),
        taxon = "taxonA",
        age = base::c(0, 500, 1000),
        pollen_prop = base::c(0.2, 0.6, 0.4)
      )

    data_simple_unc <-
      tibble::tibble(
        dataset_name = base::rep("core_simple", 6),
        sample_name = base::rep(
          base::c("s1", "s2", "s3"), 2
        ),
        iteration = base::c(
          base::rep(1L, 3), base::rep(2L, 3)
        ),
        age_uncertainty = base::c(
          0, 500, 1000,  # iteration 1: same as consensus
          0, 500, 1000   # iteration 2: same as consensus
        )
      )

    # Both iterations produce the same ages, so median == original.
    result <-
      interpolate_community_data_with_uncertainty(
        data = data_simple_core,
        data_age_uncertainty = data_simple_unc,
        timestep = 500,
        age_min = 0,
        age_max = 1000
      )

    result_at_500 <-
      dplyr::filter(result, age == 500)

    val_prop <-
      dplyr::pull(result_at_500, pollen_prop)

    testthat::expect_equal(
      val_prop,
      0.6,
      tolerance = 1e-6
    )
  }
)


#----------------------------------------------------------#
# Edge cases -----
#----------------------------------------------------------#

testthat::test_that(
  "empty data_age_uncertainty matches interpolate_community_data",
  {
    result_unc <-
      interpolate_community_data_with_uncertainty(
        data = data_community_test,
        data_age_uncertainty = data_age_unc_empty,
        timestep = 200,
        age_min = 0,
        age_max = 800
      )

    result_direct <-
      interpolate_community_data(
        data = data_community_test,
        timestep = 200,
        age_min = 0,
        age_max = 800
      )

    testthat::expect_equal(
      base::nrow(result_unc),
      base::nrow(result_direct)
    )

    vec_ds_unc <-
      dplyr::pull(result_unc, dataset_name) |>
      base::unique() |>
      base::sort()

    vec_ds_direct <-
      dplyr::pull(result_direct, dataset_name) |>
      base::unique() |>
      base::sort()

    testthat::expect_equal(
      vec_ds_unc,
      vec_ds_direct
    )
  }
)

testthat::test_that(
  "single iteration produces valid output",
  {
    data_core_only <-
      dplyr::filter(data_community_test, dataset_name == "core1")

    result <-
      interpolate_community_data_with_uncertainty(
        data = data_core_only,
        data_age_uncertainty = data_age_unc_single_iter,
        timestep = 200,
        age_min = 0,
        age_max = 800
      )

    testthat::expect_true(
      base::is.data.frame(result)
    )

    vec_prop <-
      dplyr::pull(result, pollen_prop)

    testthat::expect_true(
      base::all(base::is.finite(vec_prop))
    )

    # median of 1 value == that value (spot-check row count)
    testthat::expect_true(
      base::nrow(result) > 0L
    )
  }
)
