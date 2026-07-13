predict.mock_sjsdm_adapter <- function(
    object,
    newdata = NULL,
    SP = NULL,
    type = "link",
    ...) {
  object[["capture"]][["newdata"]] <-
    newdata

  object[["capture"]][["spatial"]] <-
    SP

  object[["capture"]][["type"]] <-
    type

  res <-
    base::matrix(
      data = base::c(0.2, 0.8, 0.6, 0.4),
      nrow = 2,
      dimnames = base::list(
        base::c("a__0", "b__0"),
        base::c("taxon_a", "taxon_b")
      )
    )

  return(res)
}

testthat::test_that(
  "predict_sjsdm_probability_matrix() passes abiotic and spatial inputs",
  {
    environment_capture <-
      base::new.env(parent = base::emptyenv())

    object <-
      base::list(capture = environment_capture)

    base::class(object) <- "mock_sjsdm_adapter"

    data_test_input <-
      base::list(
        data_abiotic_to_fit = base::data.frame(bio = base::c(1, 2)),
        data_spatial_to_fit = base::data.frame(mev_1 = base::c(3, 4))
      )

    res <-
      predict_sjsdm_probability_matrix(
        object = object,
        data_test_input = data_test_input,
        predict_function = predict.mock_sjsdm_adapter
      )

    testthat::expect_equal(
      environment_capture[["newdata"]],
      data_test_input[["data_abiotic_to_fit"]]
    )
    testthat::expect_equal(
      environment_capture[["spatial"]],
      data_test_input[["data_spatial_to_fit"]]
    )
    testthat::expect_equal(environment_capture[["type"]], "link")
    testthat::expect_equal(base::dim(res), base::c(2L, 2L))
  }
)

testthat::test_that(
  "predict_sjsdm_probability_matrix() rejects invalid probabilities",
  {
    predict_bad <- function(object, newdata = NULL, SP = NULL, type = "link") {
      base::matrix(base::c(-0.1, 1.1), nrow = 1)
    }

    data_test_input <-
      base::list(
        data_abiotic_to_fit = base::data.frame(bio = 1)
      )

    testthat::expect_error(
      predict_sjsdm_probability_matrix(
        object = base::list(),
        data_test_input = data_test_input,
        predict_function = predict_bad
      ),
      "probabilities"
    )
  }
)
