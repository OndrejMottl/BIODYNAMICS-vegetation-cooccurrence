testthat::test_that(
  "load_sjsdm_versioned_artifact() prefers canonical v2 output",
  {
    list_empty <-
      build_sjsdm_empty_selected_fold_artifacts()

    list_v2 <-
      build_sjsdm_pipeline_artifact(
        artifact_type = "sjsdm_cv_predictions",
        payload = base::list(
          data_predictions = list_empty[["data_predictions"]],
          data_fold_diagnostics = list_empty[["data_diagnostics"]]
        ),
        pipeline_id = "pipeline_test",
        configuration_profile = "project_test"
      )
    vec_reads <-
      character()
    read_target <- function(name, store) {
      vec_reads <<-
        base::c(vec_reads, name)
      if (name == "list_sjsdm_cv_prediction_artifact") {
        return(list_v2)
      }
      cli::cli_abort("v1 should not be read")
    }

    res <-
      load_sjsdm_versioned_artifact(
        store_path = "store",
        v2_target_name = "list_sjsdm_cv_prediction_artifact",
        v1_target_names = "data_sjsdm_out_of_fold_predictions",
        artifact_type = "sjsdm_cv_predictions",
        converter_function = identity,
        read_target_function = read_target
      )

    testthat::expect_identical(res, list_v2)
    testthat::expect_identical(
      vec_reads,
      "list_sjsdm_cv_prediction_artifact"
    )
  }
)
