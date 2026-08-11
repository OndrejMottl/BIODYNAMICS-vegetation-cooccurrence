testthat::test_that(
  "build_r_architecture_dependency_map() is deterministic",
  {
    data_scripts <-
      tibble::tibble(
        classification = "main_analysis",
        migration_status = "migrated"
      )
    data_functions <-
      tibble::tibble(
        current_path = "R/Functions/Data/example.R",
        intended_path = "R/Functions/Data/example.R",
        migration_status = "baseline_recorded",
        callers = "R/Pipelines/_pipes/pipe_segment_example.R"
      )
    data_contracts <-
      tibble::tibble(
        contract_type = "literal_target",
        contract_scope = "persisted_internal"
      )
    data_manifests <-
      tibble::tibble(
        profile_id = "example",
        profile_role = "smoke",
        pipeline_id = "example",
        pipeline_script = "R/Pipelines/example.R",
        target_store = "Data/targets/example",
        manifest_target_count = 1L
      )
    data_exceptions <-
      tibble::tibble(
        owner_issue = "#141",
        expiry_issue = "#141"
      )

    vec_first <-
      build_r_architecture_dependency_map(
        data_scripts = data_scripts,
        data_functions = data_functions,
        data_contracts = data_contracts,
        data_manifests = data_manifests,
        data_exceptions = data_exceptions
      )
    vec_second <-
      build_r_architecture_dependency_map(
        data_scripts = data_scripts,
        data_functions = data_functions,
        data_contracts = data_contracts,
        data_manifests = data_manifests,
        data_exceptions = data_exceptions
      )
    text_expected_intro <-
      stringr::str_c(
        "This maintained map is generated from the versioned script, ",
        "function, persisted-contract, manifest, and ",
        "architecture-exception inventories. Do not edit generated ",
        "tables manually."
      )
    text_expected_analysis_owner <-
      stringr::str_c(
        "- `R/02_Main_analyses/` owns stable production-facing ",
        "orchestration, scientific synthesis, and final visualisation."
      )
    text_expected_exception_lifecycle <-
      stringr::str_c(
        "Exceptions match one exact current finding. They become invalid ",
        "when their expiry issue closes and must then be removed or ",
        "replaced by an approved canonical decision."
      )

    testthat::expect_identical(vec_first, vec_second)
    testthat::expect_true(text_expected_intro %in% vec_first)
    testthat::expect_true(text_expected_analysis_owner %in% vec_first)
    testthat::expect_true(
      text_expected_exception_lifecycle %in% vec_first
    )
    testthat::expect_true(
      base::any(stringr::str_detect(vec_first, "flowchart TD"))
    )
    testthat::expect_true(
      base::any(stringr::str_detect(vec_first, "Data/targets/example"))
    )
    testthat::expect_true(
      base::any(
        stringr::str_detect(
          vec_first,
          stringr::fixed("| main_analysis | 1 |")
        )
      )
    )
    testthat::expect_true(
      base::any(
        stringr::str_detect(
          vec_first,
          stringr::fixed("pipe_segment_example.R")
        )
      )
    )
  }
)
