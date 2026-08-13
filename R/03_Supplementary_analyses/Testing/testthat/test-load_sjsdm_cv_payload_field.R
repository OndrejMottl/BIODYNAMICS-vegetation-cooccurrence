testthat::test_that(
  "load_sjsdm_cv_payload_field() prefers valid v2 content",
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
    res <-
      load_sjsdm_cv_payload_field(
        store_path = "store",
        v2_target_name = "v2",
        artifact_type = "sjsdm_cv_predictions",
        payload_name = "data_predictions",
        read_target_function = function(name, store) {
          if (name == "v2") list_v2 else base::stop("unexpected")
        }
      )

    testthat::expect_identical(
      res,
      list_empty[["data_predictions"]]
    )
  }
)

testthat::test_that(
  "load_sjsdm_cv_payload_field() never probes a v1 target",
  {
    environment_reads <-
      base::new.env(parent = base::emptyenv())
    environment_reads[["count"]] <- 0L

    testthat::expect_error(
      load_sjsdm_cv_payload_field(
        store_path = "store",
        v2_target_name = "missing_v2",
        artifact_type = "sjsdm_cv_predictions",
        payload_name = "data_predictions",
        read_target_function = function(name, store) {
          environment_reads[["count"]] <-
            environment_reads[["count"]] + 1L
          base::stop("missing")
        }
      ),
      "missing"
    )

    testthat::expect_identical(environment_reads[["count"]], 1L)
    testthat::expect_false(
      "v1_target_name" %in%
        base::names(base::formals(load_sjsdm_cv_payload_field))
    )
  }
)
