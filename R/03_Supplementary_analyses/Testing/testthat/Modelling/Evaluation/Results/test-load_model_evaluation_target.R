testthat::test_that(
  "load_model_evaluation_target() loads explicit evaluation targets",
  {
    fake_reader <- function(name, store) {
      if (
        stringr::str_starts(
          name,
          "list_sjsdm_cv_evaluation_artifact"
        )
      ) {
        return(
          build_sjsdm_artifact_envelope(
            artifact_type = "sjsdm_cv_evaluation",
            payload = make_sjsdm_evaluation_payload_fixture(),
            provenance = build_sjsdm_artifact_provenance(
              pipeline_id = "pipeline_test",
              configuration_profile = "project_test"
            )
          )
        )
      }
      base::list(
        name = name,
        store = store
      )
    }

    res_fitted <-
      load_model_evaluation_target(
        store_path = "store",
        resolution_id = "genus",
        evaluation_type = "fitted",
        read_target_fn = fake_reader
      )

    testthat::expect_identical(
      purrr::chuck(res_fitted, "name"),
      "list_jsdm_evaluation_fitted_genus"
    )

    res_cross_validated <-
      load_model_evaluation_target(
        store_path = "store",
        resolution_id = "genus",
        evaluation_type = "cross_validated",
        read_target_fn = fake_reader
      )

    testthat::expect_identical(
      base::names(res_cross_validated),
      base::names(
        make_sjsdm_evaluation_payload_fixture()[[
          "list_pooled_evaluation"
        ]]
      )
    )
  }
)

testthat::test_that(
  "load_model_evaluation_target() returns NULL when loading fails",
  {
    fake_reader <- function(name, store) {
      base::stop("cannot read")
    }

    res <-
      load_model_evaluation_target(
        store_path = "store",
        resolution_id = "genus",
        evaluation_type = "fitted",
        read_target_fn = fake_reader
      )

    testthat::expect_null(res)
  }
)

testthat::test_that(
  "load_model_evaluation_target() validates arguments",
  {
    fake_reader <- function(name, store) {
      base::list()
    }

    testthat::expect_error(
      load_model_evaluation_target(
        store_path = base::character(),
        resolution_id = "genus",
        evaluation_type = "fitted",
        read_target_fn = fake_reader
      ),
      regexp = "store_path"
    )

    testthat::expect_error(
      load_model_evaluation_target(
        store_path = "store",
        resolution_id = "genus",
        evaluation_type = "combined",
        read_target_fn = fake_reader
      ),
      regexp = "evaluation_type"
    )
  }
)
