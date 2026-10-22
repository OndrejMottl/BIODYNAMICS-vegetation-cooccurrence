testthat::test_that("production checks evidence before fitting", {
  data_representatives <-
    tibble::tibble(analysis_id = "modern_spatial", tier_id = "local",
      continent_id = "europe", scale_id = "eu_r001_l001",
      resolution_id = "genus", target_suffix = "genus",
      store_path = "store")
  list_arguments <-
    base::list(
      profile_id = "project_modern_spatial_local",
      data_representatives = data_representatives,
      validate_preparation_function = function(...) NULL,
      read_target_function = function(...) base::list(),
      load_evidence_function = function(...) base::list()
    )
  testthat::expect_invisible(validate_sjsdm_cv_production_calibration(
    profile_id = list_arguments[["profile_id"]],
    data_representatives = data_representatives,
    validate_preparation_function = function(...) NULL,
    read_target_function = function(...) base::list(),
    load_evidence_function = function(...) base::list(),
    validate_evidence_function = function(...) {
      base::list(status = "accepted")
    }
  ))
  testthat::expect_error(base::do.call(
    validate_sjsdm_cv_production_calibration,
    base::c(list_arguments, base::list(
      validate_evidence_function = function(...) {
        base::list(status = "incompatible_inputs")
      }
    ))
  ), "01_run_model_calibration[.]R")
})
