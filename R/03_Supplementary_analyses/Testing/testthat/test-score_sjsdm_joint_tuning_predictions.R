testthat::test_that(
  "score_sjsdm_joint_tuning_predictions() uses joint likelihood",
  {
    environment_calls <-
      base::new.env(parent = base::emptyenv())

    environment_calls[["count"]] <- 0L

    likelihood_function <- function(
        data_abiotic,
        data_observed,
        SP,
        batch_size,
        sampling) {
      environment_calls[["count"]] <-
        environment_calls[["count"]] + 1L

      environment_calls[["data_abiotic"]] <-
        data_abiotic

      environment_calls[["data_observed"]] <-
        data_observed

      environment_calls[["data_spatial"]] <-
        SP

      environment_calls[["batch_size"]] <-
        batch_size

      environment_calls[["sampling"]] <-
        sampling

      return(base::list(8))
    }

    mod_fit <-
      base::structure(
        base::list(
          formula = stats::as.formula(~ 0 + temperature),
          spatial = base::list(
            formula = stats::as.formula(~ 0 + coordinate)
          ),
          settings = base::list(
            step_size = 10,
            sampling = 25L
          ),
          model = base::list(logLik = likelihood_function)
        ),
        class = base::c("spatial", "sjSDM")
      )

    data_observed <-
      base::matrix(
        data = base::c(0, 1, 1, 0),
        nrow = 2L,
        dimnames = base::list(
          base::c("sample_a", "sample_b"),
          base::c("taxon_a", "taxon_b")
        )
      )

    data_predicted <-
      base::matrix(
        data = base::c(0.2, 0.8, 0.7, 0.3),
        nrow = 2L,
        dimnames = base::dimnames(data_observed)
      )

    data_test_input <-
      base::list(
        data_abiotic_to_fit = base::data.frame(
          temperature = base::c(2, 4)
        ),
        data_spatial_to_fit = base::data.frame(
          coordinate = base::c(5, 7)
        )
      )

    res <-
      score_sjsdm_joint_tuning_predictions(
        object = mod_fit,
        data_test_input = data_test_input,
        data_observed = data_observed,
        data_predicted = data_predicted,
        n_likelihood_draws = 3L
      )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(
      res[["negative_log_likelihood_test"]],
      8
    )
    testthat::expect_equal(
      res[["negative_log_likelihood_per_response"]],
      2
    )
    testthat::expect_equal(res[["auc_macro_test"]], 1)
    testthat::expect_equal(environment_calls[["count"]], 3L)
    testthat::expect_equal(
      environment_calls[["data_abiotic"]],
      stats::model.matrix(
        object = stats::as.formula(~ 0 + temperature),
        data = data_test_input[["data_abiotic_to_fit"]]
      )
    )
    testthat::expect_equal(
      environment_calls[["data_spatial"]],
      stats::model.matrix(
        object = stats::as.formula(~ 0 + coordinate),
        data = data_test_input[["data_spatial_to_fit"]]
      )
    )
    testthat::expect_equal(
      environment_calls[["data_observed"]],
      data_observed
    )
    testthat::expect_equal(environment_calls[["batch_size"]], 1L)
    testthat::expect_equal(environment_calls[["sampling"]], 25L)
  }
)

testthat::test_that(
  "score_sjsdm_joint_tuning_predictions() validates likelihood settings",
  {
    mod_fit <-
      base::structure(
        base::list(
          formula = stats::as.formula(~ 0 + temperature),
          settings = base::list(step_size = 2L, sampling = 25L),
          model = base::list(logLik = function(...) base::list(1))
        ),
        class = "sjSDM"
      )

    data_observed <-
      base::matrix(
        data = base::c(0, 1),
        ncol = 1L,
        dimnames = base::list(
          base::c("sample_a", "sample_b"),
          "taxon_a"
        )
      )

    data_predicted <-
      base::matrix(
        data = base::c(0.2, 0.8),
        ncol = 1L,
        dimnames = base::dimnames(data_observed)
      )

    data_test_input <-
      base::list(
        data_abiotic_to_fit = base::data.frame(
          temperature = base::c(2, 4)
        )
      )

    testthat::expect_error(
      score_sjsdm_joint_tuning_predictions(
        object = mod_fit,
        data_test_input = data_test_input,
        data_observed = data_observed,
        data_predicted = data_predicted,
        n_likelihood_draws = 0L
      ),
      "positive integer"
    )
  }
)
