testthat::test_that(
  "prepare_binary_prediction_metric_input() returns aligned counts",
  {
    list_input <-
      prepare_binary_prediction_metric_input(
        observed = base::c(0, 1, 1, 0),
        predicted_probability = base::c(0.1, 0.8, 0.7, 0.2)
      )

    testthat::expect_named(
      list_input,
      base::c(
        "observed",
        "predicted_probability",
        "n_observations",
        "n_presences",
        "n_absences",
        "prevalence",
        "class_status"
      )
    )
    testthat::expect_equal(list_input[["n_observations"]], 4L)
    testthat::expect_equal(list_input[["n_presences"]], 2L)
    testthat::expect_equal(list_input[["n_absences"]], 2L)
    testthat::expect_equal(list_input[["prevalence"]], 0.5)
    testthat::expect_equal(list_input[["class_status"]], "ok")
  }
)

testthat::test_that(
  "prepare_binary_prediction_metric_input() identifies one class",
  {
    list_absences <-
      prepare_binary_prediction_metric_input(
        observed = base::c(0, 0),
        predicted_probability = base::c(0.1, 0.2)
      )

    list_presences <-
      prepare_binary_prediction_metric_input(
        observed = base::c(1, 1),
        predicted_probability = base::c(0.8, 0.9)
      )

    testthat::expect_equal(
      list_absences[["class_status"]],
      "undefined_no_presences"
    )
    testthat::expect_equal(
      list_presences[["class_status"]],
      "undefined_no_absences"
    )
  }
)

testthat::test_that(
  "prepare_binary_prediction_metric_input() validates inputs",
  {
    testthat::expect_error(
      prepare_binary_prediction_metric_input(
        observed = base::c(0, 1),
        predicted_probability = 0.5
      ),
      "same positive length"
    )

    testthat::expect_error(
      prepare_binary_prediction_metric_input(
        observed = base::c(0, 2),
        predicted_probability = base::c(0.1, 0.9)
      ),
      "only zero and one"
    )

    testthat::expect_error(
      prepare_binary_prediction_metric_input(
        observed = base::c(0, 1),
        predicted_probability = base::c(-0.1, 1.1)
      ),
      "closed interval"
    )
  }
)
