testthat::test_that(
  "fit_sjsdm_regularization_candidate() forwards selected settings",
  {
    environment_capture <-
      base::new.env(parent = base::emptyenv())

    fit_function <- function(...) {
      environment_capture[["args"]] <-
        base::list(...)

      return("fit")
    }

    data_train_input <-
      base::list(
        data_community_to_fit = base::matrix(
          data = base::c(1, 0, 0, 1),
          nrow = 2,
          dimnames = base::list(
            base::c("a__0", "b__0"),
            base::c("taxon_a", "taxon_b")
          )
        ),
        data_abiotic_to_fit = base::data.frame(bio = base::c(-1, 1))
      )

    data_candidate <-
      tibble::tibble(
        candidate_id = "candidate_001",
        alpha_cov = 0.1,
        alpha_coef = 0.2,
        alpha_spatial = 0.3,
        lambda_cov = 0.4,
        lambda_coef = 0.5,
        lambda_spatial = 0.6
      )

    res <-
      fit_sjsdm_regularization_candidate(
        data_train_input = data_train_input,
        candidate = data_candidate,
        sel_abiotic_formula = stats::as.formula("~ bio"),
        config_model_fitting = base::list(
          error_family = "binomial",
          use_spatial = FALSE,
          n_cores = 4L,
          n_sampling = 20L,
          n_iter = 30L,
          n_step_size = 5L,
          n_early_stopping = 3L
        ),
        seed = 123L,
        device = "cpu",
        fit_function = fit_function
      )

    list_args <-
      environment_capture[["args"]]

    testthat::expect_equal(res, "fit")
    testthat::expect_equal(list_args[["alpha_cov"]], 0.1)
    testthat::expect_equal(list_args[["alpha_coef"]], 0.2)
    testthat::expect_equal(list_args[["alpha_spatial"]], 0.3)
    testthat::expect_equal(list_args[["lambda_cov"]], 0.4)
    testthat::expect_equal(list_args[["lambda_coef"]], 0.5)
    testthat::expect_equal(list_args[["lambda_spatial"]], 0.6)
    testthat::expect_equal(list_args[["seed"]], 123L)
    testthat::expect_equal(list_args[["device"]], "cpu")
    testthat::expect_equal(list_args[["parallel"]], 4L)
  }
)

testthat::test_that(
  "fit_sjsdm_regularization_candidate() rejects incomplete candidates",
  {
    data_train_input <-
      base::list(
        data_community_to_fit = base::matrix(1, nrow = 1, ncol = 1),
        data_abiotic_to_fit = base::data.frame(bio = 1)
      )

    testthat::expect_error(
      fit_sjsdm_regularization_candidate(
        data_train_input = data_train_input,
        candidate = tibble::tibble(candidate_id = "candidate_001"),
        sel_abiotic_formula = stats::as.formula("~ bio"),
        config_model_fitting = base::list(error_family = "binomial"),
        fit_function = function(...) "fit"
      ),
      "candidate"
    )
  }
)
