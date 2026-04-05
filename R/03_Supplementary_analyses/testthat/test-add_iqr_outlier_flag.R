testthat::test_that(
  "add_iqr_outlier_flag() errors on non-data-frame data",
  {
    testthat::expect_error(
      add_iqr_outlier_flag(
        data = "not_a_df",
        col_value = "trait_value",
        multiplier = 1.5
      )
    )

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = NULL,
        col_value = "trait_value",
        multiplier = 1.5
      )
    )

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = base::c(1, 2, 3),
        col_value = "trait_value",
        multiplier = 1.5
      )
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() errors on ungrouped data frame",
  {
    data_ungrouped <-
      tibble::tibble(
        group = base::c("a", "a", "b"),
        trait_value = base::c(1, 2, 3)
      )

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_ungrouped,
        col_value = "trait_value",
        multiplier = 1.5
      )
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() errors when col_value missing",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "b", "b"),
        trait_value = base::c(1, 2, 3, 4)
      ) |>
      dplyr::group_by(group)

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "no_such_col",
        multiplier = 1.5
      )
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() errors on invalid col_value arg",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a"),
        trait_value = base::c(1, 2)
      ) |>
      dplyr::group_by(group)

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = 123,
        multiplier = 1.5
      )
    )

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = base::c("trait_value", "group"),
        multiplier = 1.5
      )
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() errors when multiplier is missing",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a"),
        trait_value = base::c(1, 2)
      ) |>
      dplyr::group_by(group)

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value"
      )
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() errors on invalid multiplier",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "b", "b"),
        trait_value = base::c(1, 2, 3, 4)
      ) |>
      dplyr::group_by(group)

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = "large"
      )
    )

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = -1
      )
    )

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 0
      )
    )

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = base::c(1.5, 2.5)
      )
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() errors on invalid min_n",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "b", "b"),
        trait_value = base::c(1, 2, 3, 4)
      ) |>
      dplyr::group_by(group)

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5,
        min_n = "five"
      )
    )

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5,
        min_n = -1L
      )
    )

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5,
        min_n = 0L
      )
    )

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5,
        min_n = base::c(3L, 5L)
      )
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() errors on non-numeric col_value column",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "b", "b"),
        trait_value = base::c("x", "y", "z", "w")
      ) |>
      dplyr::group_by(group)

    testthat::expect_error(
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5
      )
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() returns a data frame",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "a", "a", "a"),
        trait_value = base::c(1, 2, 3, 4, 5)
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5
      )

    testthat::expect_true(
      base::is.data.frame(res)
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() returns an ungrouped data frame",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "a", "b", "b", "b"),
        trait_value = base::c(1, 2, 3, 4, 5, 6)
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5
      )

    testthat::expect_equal(
      base::length(dplyr::group_vars(res)),
      0L
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() adds n_group and is_outlier columns",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "a"),
        trait_value = base::c(1, 2, 3)
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5
      )

    col_names <-
      base::colnames(res)

    testthat::expect_true(
      "n_group" %in% col_names
    )

    testthat::expect_true(
      "is_outlier" %in% col_names
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() n_group is integer type",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "a"),
        trait_value = base::c(1, 2, 3)
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5
      )

    testthat::expect_type(
      dplyr::pull(res, n_group),
      "integer"
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() is_outlier is logical type",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "a"),
        trait_value = base::c(1, 2, 3)
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5
      )

    testthat::expect_type(
      dplyr::pull(res, is_outlier),
      "logical"
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() preserves row count",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("a", "a", "a", "b", "b"),
        trait_value = base::c(1, 2, 3, 4, 5)
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5
      )

    testthat::expect_equal(
      base::nrow(res),
      5L
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() flags clear outlier in one group",
  {
    # One group, 9 normal values + 1 extreme outlier
    trait_vals <-
      base::c(10, 11, 10, 9, 11, 10, 10, 11, 9, 1000)

    data_grouped <-
      tibble::tibble(
        group = base::rep("a", 10L),
        trait_value = trait_vals
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5
      )

    # Only the extreme value (1000) should be flagged
    vec_is_outlier <-
      dplyr::pull(res, is_outlier)

    vec_values <-
      dplyr::pull(res, trait_value)

    testthat::expect_true(
      vec_is_outlier[base::which(vec_values == 1000)]
    )

    testthat::expect_equal(
      base::sum(vec_is_outlier),
      1L
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() does not confuse outliers across groups",
  {
    # Group A: normal values; Group B: outlier only in B
    data_grouped <-
      tibble::tibble(
        group = base::c(
          base::rep("A", 6L),
          base::rep("B", 6L)
        ),
        trait_value = base::c(
          5, 6, 5, 6, 5, 6,       # group A: no outlier
          5, 6, 5, 6, 5, 9999     # group B: one outlier
        )
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5
      )

    res_a <-
      dplyr::filter(res, group == "A")

    res_b <-
      dplyr::filter(res, group == "B")

    # No outliers in group A
    testthat::expect_true(
      base::all(
        dplyr::pull(res_a, is_outlier) == FALSE
      )
    )

    # Exactly one outlier in group B
    testthat::expect_equal(
      base::sum(dplyr::pull(res_b, is_outlier)),
      1L
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() flags no outlier when IQR is zero",
  {
    data_grouped <-
      tibble::tibble(
        group = base::rep("a", 5L),
        trait_value = base::rep(5.0, 5L)
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5
      )

    testthat::expect_true(
      base::all(
        dplyr::pull(res, is_outlier) == FALSE
      )
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() computes correct n_group per group",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c(
          base::rep("A", 4L),
          base::rep("B", 7L)
        ),
        trait_value = base::c(
          1, 2, 3, 4,
          10, 11, 12, 13, 14, 15, 16
        )
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5
      )

    res_a <-
      dplyr::filter(res, group == "A")

    res_b <-
      dplyr::filter(res, group == "B")

    testthat::expect_true(
      base::all(dplyr::pull(res_a, n_group) == 4L)
    )

    testthat::expect_true(
      base::all(dplyr::pull(res_b, n_group) == 7L)
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() symmetric fence flags both tails",
  {
    # Median 50, IQR 20 (Q1=40, Q3=60)
    # Fence: [50 - 1.5*20, 50 + 1.5*20] = [20, 80]
    # 10 should be flagged (below), 90 should be flagged (above)
    data_grouped <-
      tibble::tibble(
        group = base::rep("a", 8L),
        trait_value = base::c(
          40, 45, 50, 55, 60, 50,
          10,   # below fence
          90    # above fence
        )
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5
      )

    vec_values <-
      dplyr::pull(res, trait_value)

    vec_is_outlier <-
      dplyr::pull(res, is_outlier)

    testthat::expect_true(
      vec_is_outlier[base::which(vec_values == 10)]
    )

    testthat::expect_true(
      vec_is_outlier[base::which(vec_values == 90)]
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() with min_n: small group not flagged",
  {
    # Group A: only 2 rows, min_n = 3, extreme value present
    data_grouped <-
      tibble::tibble(
        group = base::c("A", "A", "B", "B", "B", "B", "B"),
        trait_value = base::c(
          1, 99999,               # group A: extreme but n < min_n
          10, 11, 10, 11, 99999  # group B: extreme and n >= min_n
        )
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5,
        min_n = 3L
      )

    res_a <-
      dplyr::filter(res, group == "A")

    testthat::expect_true(
      base::all(
        dplyr::pull(res_a, is_outlier) == FALSE
      )
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() with min_n: zero IQR not flagged",
  {
    # Group with all identical values: IQR = 0, min_n supplied
    data_grouped <-
      tibble::tibble(
        group = base::rep("a", 5L),
        trait_value = base::rep(7.0, 5L)
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5,
        min_n = 3L
      )

    testthat::expect_true(
      base::all(
        dplyr::pull(res, is_outlier) == FALSE
      )
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() with min_n: large group still flagged",
  {
    # Group with >= min_n and clear outlier
    trait_vals <-
      base::c(10, 11, 10, 9, 11, 10, 10, 11, 9, 1000)

    data_grouped <-
      tibble::tibble(
        group = base::rep("a", 10L),
        trait_value = trait_vals
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5,
        min_n = 5L
      )

    vec_values <-
      dplyr::pull(res, trait_value)

    vec_is_outlier <-
      dplyr::pull(res, is_outlier)

    testthat::expect_true(
      vec_is_outlier[base::which(vec_values == 1000)]
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() n_group computed regardless of min_n",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c(
          base::rep("small", 2L),
          base::rep("large", 8L)
        ),
        trait_value = base::c(
          1, 99,
          10, 11, 10, 11, 10, 11, 10, 9999
        )
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5,
        min_n = 5L
      )

    res_small <-
      dplyr::filter(res, group == "small")

    res_large <-
      dplyr::filter(res, group == "large")

    testthat::expect_true(
      base::all(dplyr::pull(res_small, n_group) == 2L)
    )

    testthat::expect_true(
      base::all(dplyr::pull(res_large, n_group) == 8L)
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() single-row group: is_outlier FALSE",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("solo", "multi", "multi", "multi"),
        trait_value = base::c(99999, 1, 2, 3)
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5
      )

    res_solo <-
      dplyr::filter(res, group == "solo")

    testthat::expect_false(
      dplyr::pull(res_solo, is_outlier)
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() single-row group: FALSE with min_n",
  {
    data_grouped <-
      tibble::tibble(
        group = base::c("solo", "multi", "multi", "multi"),
        trait_value = base::c(99999, 1, 2, 3)
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 1.5,
        min_n = 3L
      )

    res_solo <-
      dplyr::filter(res, group == "solo")

    testthat::expect_false(
      dplyr::pull(res_solo, is_outlier)
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() works with non-default col_value",
  {
    data_grouped <-
      tibble::tibble(
        group = base::rep("a", 10L),
        my_value = base::c(
          10, 11, 10, 9, 11, 10, 10, 11, 9, 1000
        )
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "my_value",
        multiplier = 1.5
      )

    vec_values <-
      dplyr::pull(res, my_value)

    vec_is_outlier <-
      dplyr::pull(res, is_outlier)

    testthat::expect_true(
      vec_is_outlier[base::which(vec_values == 1000)]
    )

    testthat::expect_equal(
      base::sum(vec_is_outlier),
      1L
    )
  }
)

testthat::test_that(
  "add_iqr_outlier_flag() works on large synthetic dataset",
  {
    base::set.seed(900723)

    n_rows <- 120L
    groups <-
      base::sample(
        x = base::c("grp1", "grp2", "grp3", "grp4"),
        size = n_rows,
        replace = TRUE
      )

    values <-
      stats::rnorm(n = n_rows, mean = 50, sd = 5)

    data_grouped <-
      tibble::tibble(
        group = groups,
        trait_value = values
      ) |>
      dplyr::group_by(group)

    res <-
      add_iqr_outlier_flag(
        data = data_grouped,
        col_value = "trait_value",
        multiplier = 3
      )

    testthat::expect_true(
      base::is.data.frame(res)
    )

    testthat::expect_equal(
      base::nrow(res),
      n_rows
    )

    col_names <-
      base::colnames(res)

    testthat::expect_true("n_group" %in% col_names)
    testthat::expect_true("is_outlier" %in% col_names)

    testthat::expect_type(
      dplyr::pull(res, n_group),
      "integer"
    )

    testthat::expect_type(
      dplyr::pull(res, is_outlier),
      "logical"
    )
  }
)
