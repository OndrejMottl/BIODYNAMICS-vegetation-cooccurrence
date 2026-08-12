#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#              Generate R architecture inventories
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Generate the version-one baseline inventories used by issue #150.


#----------------------------------------------------------#
# 1. Load the validated function inventory -----
#----------------------------------------------------------#

path_repository_root <-
  here::here()

path_loader <-
  here::here(
    "R/Functions/Pipeline/Definitions/load_project_functions.R"
  )

base::source(
  file = path_loader,
  local = base::environment()
)

environment_functions <-
  base::new.env(parent = base::globalenv())

data_functions_loaded <-
  load_project_functions(
    path_function_root = here::here("R/Functions"),
    environment_target = environment_functions,
    vec_excluded_directory_names = "_legacy"
  )


#----------------------------------------------------------#
# 2. Read active R sources once -----
#----------------------------------------------------------#

vec_r_paths <-
  base::list.files(
    path = here::here("R"),
    pattern = "[.]R$",
    recursive = TRUE,
    full.names = TRUE
  ) |>
  base::normalizePath(
    winslash = "/",
    mustWork = TRUE
  ) |>
  base::sort(method = "radix")

vec_r_relative_paths <-
  base::substring(
    text = vec_r_paths,
    first = base::nchar(
      base::normalizePath(
        path_repository_root,
        winslash = "/"
      )
    ) + 2L
  )

list_r_lines <-
  base::vector(
    mode = "list",
    length = base::length(vec_r_paths)
  )

for (
  index_path in base::seq_along(vec_r_paths)
) {
  list_r_lines[[index_path]] <-
    base::readLines(
      con = vec_r_paths[[index_path]],
      warn = FALSE,
      encoding = "UTF-8"
    )
}


#----------------------------------------------------------#
# 3. Build the function inventory -----
#----------------------------------------------------------#

data_function_inventory <-
  data_functions_loaded |>
  dplyr::mutate(
    current_path = stringr::str_c(
      "R/Functions/",
      .data[["path_relative"]]
    ),
    intended_path = .data[["current_path"]],
    leading_verb = .data[["function_name"]] |>
      stringr::str_remove("^[.]") |>
      stringr::str_extract("^[^_]+"),
    owning_issue = dplyr::case_when(
      stringr::str_detect(
        .data[["current_path"]],
        "/Pipeline/Definitions/Architecture/"
      ) ~ "#157",
      stringr::str_detect(
        .data[["current_path"]],
        "load_project_functions[.]R$"
      ) ~ "#150",
      stringr::str_detect(
        .data[["current_path"]],
        "Cross_validation"
      ) ~ "#141",
      stringr::str_detect(
        .data[["current_path"]],
        "/(Abiotic|Community|Traits|Time)/"
      ) ~ "#153",
      stringr::str_detect(
        .data[["current_path"]],
        "/Modelling/"
      ) ~ "#154",
      TRUE ~ "#155"
    ),
    naming_status = dplyr::case_when(
      .data[["leading_verb"]] %in% base::c(
        "load", "save", "build", "prepare", "validate",
        "diagnose", "is", "has", "resolve", "compute",
        "aggregate", "combine", "convert", "summarise", "fit", "predict",
        "score", "evaluate", "select", "run", "plot",
        "render", "filter", "classify", "interpolate",
        "scale", "project", "cluster", "deduplicate",
        "normalise", "extract", "apply"
      ) ~ "canonical_or_domain_verb",
      TRUE ~ "review_in_owning_issue"
    ),
    intended_function = .data[["function_name"]],
    migration_status = "baseline_recorded"
  )

vec_test_indices <-
  base::which(
    stringr::str_detect(
      vec_r_relative_paths,
      "R/03_Supplementary_analyses/Testing/testthat/"
    )
  )

vec_callers <-
  base::character(base::nrow(data_function_inventory))
vec_matching_tests <-
  base::character(base::nrow(data_function_inventory))
vec_nested_helpers <-
  base::character(base::nrow(data_function_inventory))

for (
  index_function in base::seq_len(base::nrow(data_function_inventory))
) {
  function_name <-
    data_function_inventory[["function_name"]][[index_function]]

  pattern_call <-
    stringr::fixed(stringr::str_c(function_name, "("))

  vec_call_indices <-
    base::which(
      purrr::map_lgl(
        list_r_lines,
        ~ base::any(stringr::str_detect(.x, pattern_call))
      )
    )

  vec_callers[[index_function]] <-
    stringr::str_c(
      vec_r_relative_paths[vec_call_indices],
      collapse = ";"
    )

  vec_test_call_indices <-
    base::intersect(vec_call_indices, vec_test_indices)

  vec_matching_tests[[index_function]] <-
    stringr::str_c(
      vec_r_relative_paths[vec_test_call_indices],
      collapse = ";"
    )

  index_definition <-
    base::match(
      data_function_inventory[["current_path"]][[index_function]],
      vec_r_relative_paths
    )

  vec_nested_matches <-
    stringr::str_match(
      list_r_lines[[index_definition]],
      "^\\s+([.]?[A-Za-z][A-Za-z0-9_.]*)\\s*<-\\s*function\\s*\\("
    )[, 2]

  vec_nested_helpers[[index_function]] <-
    vec_nested_matches |>
    stats::na.omit() |>
    base::as.character() |>
    stringr::str_c(collapse = ";")
}

data_function_inventory <-
  data_function_inventory |>
  dplyr::mutate(
    callers = vec_callers,
    matching_tests = vec_matching_tests,
    nested_helpers = vec_nested_helpers,
    nested_helper_disposition = dplyr::if_else(
      .data[["nested_helpers"]] == "",
      "none",
      "review_in_owning_issue"
    )
  ) |>
  dplyr::select(
    current_path,
    function_name,
    intended_path,
    intended_function,
    leading_verb,
    naming_status,
    callers,
    matching_tests,
    nested_helpers,
    nested_helper_disposition,
    owning_issue,
    migration_status
  )


#----------------------------------------------------------#
# 4. Build script and persisted-target inventories -----
#----------------------------------------------------------#

data_script_inventory <-
  tibble::tibble(current_path = vec_r_relative_paths) |>
  dplyr::filter(
    !stringr::str_starts(.data[["current_path"]], "R/Functions/")
  ) |>
  dplyr::mutate(
    intended_path = .data[["current_path"]],
    classification = dplyr::case_when(
      stringr::str_detect(
        .data[["current_path"]],
        "/Testing/"
      ) ~ "test",
      stringr::str_detect(
        .data[["current_path"]],
        "(Diagnose|Diagnostics)"
      ) ~ "diagnostic",
      stringr::str_detect(
        .data[["current_path"]],
        "(reference|Reference)"
      ) ~ "reference",
      stringr::str_detect(
        .data[["current_path"]],
        "Run_issue"
      ) ~ "issue_reproduction",
      stringr::str_detect(
        .data[["current_path"]],
        "(Tune|Sensitivity)"
      ) ~ "sensitivity",
      stringr::str_detect(
        .data[["current_path"]],
        "R/02_Main_analyses/.*/[0-9]+_(Run|Plot|Analyse|Compare|Visualise)"
      ) ~ "main_analysis",
      stringr::str_detect(
        .data[["current_path"]],
        "R/Pipelines/"
      ) ~ "pipeline_definition",
      stringr::str_detect(
        .data[["current_path"]],
        "setup|Init_project"
      ) ~ "project_setup",
      TRUE ~ "supplementary_or_processing"
    ),
    owning_issue = dplyr::case_when(
      stringr::str_detect(
        .data[["current_path"]],
        stringr::str_c(
          "(Validation/Architecture|Testing/testthat/Pipeline/",
          "Definitions/Architecture)"
        )
      ) ~ "#157",
      stringr::str_detect(
        .data[["current_path"]],
        "(cross_validation|_cv_|issue138|issue143)"
      ) ~ "#141",
      stringr::str_detect(
        .data[["current_path"]],
        "___setup_project"
      ) ~ "#150",
      stringr::str_detect(
        .data[["current_path"]],
        "R/02_Main_analyses/"
      ) ~ "#152",
      stringr::str_detect(
        .data[["current_path"]],
        "R/01_Data_processing/"
      ) ~ "#153",
      stringr::str_detect(
        .data[["current_path"]],
        "(Modelling|model_)"
      ) ~ "#154",
      TRUE ~ "#155"
    ),
    lifecycle_status = dplyr::if_else(
      stringr::str_detect(
        .data[["current_path"]],
        "/(_outdated|_legacy)/"
      ),
      "archived",
      "active"
    ),
    migration_status = dplyr::case_when(
      .data[["lifecycle_status"]] == "archived" ~
        "archive_or_remove_review",
      stringr::str_detect(
        .data[["current_path"]],
        "R/02_Main_analyses/"
      ) &
        !.data[["classification"]] %in% "main_analysis" ~
        "move_required",
      TRUE ~ "baseline_recorded"
    ),
    caller_notes = "Refresh static references before an approved move.",
    documentation_notes = "Update generated references in the owning issue."
  )

vec_pipeline_indices <-
  base::which(
    stringr::str_detect(
      vec_r_relative_paths,
      "^R/(Pipelines|02_Main_analyses)/"
    )
  )

vec_target_names <- base::character()
vec_target_sources <- base::character()

pattern_literal_target <-
  stringr::str_c(
    "targets::tar_target(?:_raw)?\\s*\\(",
    "(?s:.*?)\\bname\\s*=\\s*['\"]?([A-Za-z][A-Za-z0-9_]*)"
  )

for (
  index_pipeline in vec_pipeline_indices
) {
  text_pipeline <-
    stringr::str_c(
      list_r_lines[[index_pipeline]],
      collapse = "\n"
    )

  data_matches <-
    stringr::str_match_all(
      text_pipeline,
      pattern_literal_target
    )[[1L]]

  if (
    base::nrow(data_matches) > 0L
  ) {
    vec_target_names <-
      base::c(vec_target_names, data_matches[, 2])
    vec_target_sources <-
      base::c(
        vec_target_sources,
        base::rep(
          vec_r_relative_paths[[index_pipeline]],
          base::nrow(data_matches)
        )
      )
  }
}

data_contract_inventory <-
  tibble::tibble(
    contract_name = vec_target_names,
    source_path = vec_target_sources
  ) |>
  dplyr::distinct() |>
  dplyr::arrange(.data[["contract_name"]], .data[["source_path"]]) |>
  dplyr::mutate(
    contract_type = "literal_target",
    contract_scope = dplyr::if_else(
      stringr::str_detect(
        .data[["contract_name"]],
        "(cross_validation|sjsdm_(out_of_fold|tuning|model_provenance))"
      ),
      "public_or_frozen_cv_review",
      "persisted_internal"
    ),
    migration_permission = dplyr::if_else(
      .data[["contract_scope"]] == "public_or_frozen_cv_review",
      "frozen_by_issue_141",
      "requires_owner_approval"
    ),
    store_consequence = "assess_before_rename",
    owning_issue = dplyr::if_else(
      .data[["contract_scope"]] == "public_or_frozen_cv_review",
      "#141",
      "#156"
    )
  )


#----------------------------------------------------------#
# 5. Preserve approved migration decisions -----
#----------------------------------------------------------#

path_output <-
  here::here(
    "Documentation/Implementation_inventories/R_architecture"
  )

data_issue141_function_migrations <-
  tibble::tribble(
    ~function_name, ~intended_function,
    "combine_sjsdm_tuning_work_items",
    "aggregate_sjsdm_tuning_work_items",
    "make_cross_validation_assignments_from_resolution",
    "build_cross_validation_assignments_from_resolution",
    "make_cross_validation_branch_assignments",
    "build_cross_validation_branch_assignments",
    "make_cross_validation_grid_candidates",
    "build_cross_validation_grid_candidates",
    "make_cross_validation_grid_candidates_from_resolution",
    "build_cross_validation_grid_candidates_from_resolution",
    "make_cross_validation_location_table",
    "build_cross_validation_location_table",
    "make_leave_one_location_out_assignments",
    "build_leave_one_location_out_assignments",
    "assemble_sjsdm_cached_selected_folds",
    "build_sjsdm_cached_selected_folds",
    "make_sjsdm_empty_selected_fold_artifacts",
    "build_sjsdm_empty_selected_fold_artifacts",
    "configure_sjsdm_predictor_structure",
    "build_sjsdm_predictor_comparison_structure",
    "make_sjsdm_regularization_candidates",
    "build_sjsdm_regularization_candidates",
    "get_sjsdm_staged_benchmark_policy",
    "build_sjsdm_staged_benchmark_policy",
    "make_sjsdm_structured_regularization_candidates",
    "build_sjsdm_structured_regularization_candidates",
    "make_sjsdm_tuning_branch_work_items",
    "build_sjsdm_tuning_branch_work_items",
    "make_sjsdm_tuning_fold_context",
    "build_sjsdm_tuning_fold_context",
    "make_spatial_cross_validation_assignments",
    "build_spatial_cross_validation_assignments",
    "calibrate_cross_validation_grid_size",
    "compute_cross_validation_grid_calibration",
    "calibrate_cross_validation_grid_from_resolution",
    "compute_cross_validation_grid_calibration_from_resolution",
    "compare_sjsdm_decomposition_fold_metrics",
    "compute_sjsdm_decomposition_fold_effects",
    "make_cross_validation_partition_diagnostics",
    "diagnose_cross_validation_partitions",
    "assess_sjsdm_candidate_guardrails",
    "evaluate_sjsdm_candidate_guardrails",
    "assess_sjsdm_scientific_performance",
    "evaluate_sjsdm_scientific_performance",
    "assess_sjsdm_staged_benchmark",
    "evaluate_sjsdm_staged_benchmark",
    "assess_sjsdm_taxon_eligibility",
    "evaluate_sjsdm_taxon_eligibility",
    "assess_spatial_mev_paired_benchmark",
    "evaluate_spatial_mev_paired_benchmark",
    "collect_sjsdm_available_tier_decisions",
    "load_sjsdm_available_tier_decisions",
    "read_sjsdm_tier_survivor_decisions",
    "load_sjsdm_tier_survivor_decisions",
    "read_sjsdm_tier_tuning_artifact",
    "load_sjsdm_tier_tuning_artifact",
    "collect_sjsdm_tuning_summaries",
    "load_sjsdm_tuning_summaries",
    "adapt_cross_validation_assignments",
    "resolve_cross_validation_assignments",
    "assess_cross_validation_feasibility",
    "resolve_cross_validation_strategy",
    "collect_sjsdm_tuning_timings",
    "summarise_sjsdm_tuning_timings"
  )

data_issue141_active_function_keys <-
  data_issue141_function_migrations |>
  dplyr::mutate(
    current_path = stringr::str_c(
      "R/Functions/Modelling/Cross_validation/",
      .data[["intended_function"]],
      ".R"
    ),
    function_name = .data[["intended_function"]]
  ) |>
  dplyr::select(
    "current_path",
    "function_name"
  )

path_function_inventory <-
  base::file.path(path_output, "r_function_inventory_v1.csv")

if (
  base::file.exists(path_function_inventory)
) {
  data_function_inventory_current <-
    data_function_inventory

  data_function_inventory_existing <-
    readr::read_csv(
      file = path_function_inventory,
      show_col_types = FALSE
    ) |>
    dplyr::anti_join(
      data_issue141_active_function_keys,
      by = dplyr::join_by(current_path, function_name)
    ) |>
    dplyr::left_join(
      data_issue141_function_migrations,
      by = dplyr::join_by(function_name)
    ) |>
    dplyr::mutate(
      intended_path = dplyr::if_else(
        !base::is.na(.data[["intended_function.y"]]),
        stringr::str_c(
          "R/Functions/Modelling/Cross_validation/",
          .data[["intended_function.y"]],
          ".R"
        ),
        .data[["intended_path"]]
      ),
      intended_function = dplyr::coalesce(
        .data[["intended_function.y"]],
        .data[["intended_function.x"]]
      ),
      leading_verb = dplyr::if_else(
        !base::is.na(.data[["intended_function.y"]]),
        .data[["intended_function.y"]] |>
          stringr::str_remove("^[.]") |>
          stringr::str_extract("^[^_]+"),
        .data[["leading_verb"]]
      ),
      naming_status = dplyr::if_else(
        !base::is.na(.data[["intended_function.y"]]) |
          .data[["leading_verb"]] %in% base::c("combine", "convert"),
        "canonical_or_domain_verb",
        .data[["naming_status"]]
      ),
      migration_status = dplyr::if_else(
        !base::is.na(.data[["intended_function.y"]]),
        "migrated",
        .data[["migration_status"]]
      )
    ) |>
    dplyr::select(
      -"intended_function.x",
      -"intended_function.y"
    ) |>
    dplyr::relocate("intended_function", .after = "intended_path")

  vec_function_inventory_columns <-
    base::colnames(data_function_inventory_existing)

  data_function_active_contracts <-
    data_function_inventory_existing |>
    dplyr::mutate(
      active_path = dplyr::case_when(
        .data[["migration_status"]] == "migrated" ~
          .data[["intended_path"]],
        .data[["migration_status"]] %in%
          base::c(
            "retired_to_legacy",
            "retired",
            "localized_to_presentation"
          ) ~
          NA_character_,
        TRUE ~ .data[["current_path"]]
      ),
      active_function = dplyr::case_when(
        .data[["migration_status"]] == "migrated" ~
          .data[["intended_function"]],
        .data[["migration_status"]] %in%
          base::c(
            "retired_to_legacy",
            "retired",
            "localized_to_presentation"
          ) ~
          NA_character_,
        TRUE ~ .data[["function_name"]]
      )
    )

  data_function_dynamic_fields <-
    data_function_inventory_current |>
    dplyr::select(
      current_path_current = "current_path",
      function_name_current = "function_name",
      callers_current = "callers",
      matching_tests_current = "matching_tests",
      nested_helpers_current = "nested_helpers",
      nested_helper_disposition_current =
        "nested_helper_disposition"
    )

  data_function_inventory_existing <-
    data_function_active_contracts |>
    dplyr::left_join(
      data_function_dynamic_fields,
      by = dplyr::join_by(
        active_path == current_path_current,
        active_function == function_name_current
      ),
      multiple = "error"
    ) |>
    dplyr::mutate(
      callers = dplyr::coalesce(
        .data[["callers_current"]],
        .data[["callers"]]
      ),
      matching_tests = dplyr::coalesce(
        .data[["matching_tests_current"]],
        .data[["matching_tests"]]
      ),
      nested_helpers = dplyr::coalesce(
        .data[["nested_helpers_current"]],
        .data[["nested_helpers"]]
      ),
      nested_helper_disposition = dplyr::coalesce(
        .data[["nested_helper_disposition_current"]],
        .data[["nested_helper_disposition"]]
      )
    ) |>
    dplyr::select(dplyr::all_of(vec_function_inventory_columns))

  data_function_inventory_new <-
    data_function_inventory_current |>
    dplyr::anti_join(
      data_function_active_contracts |>
        dplyr::filter(!base::is.na(.data[["active_path"]])),
      by = dplyr::join_by(
        current_path == active_path,
        function_name == active_function
      )
    )

  data_function_inventory <-
    dplyr::bind_rows(
      data_function_inventory_existing,
      data_function_inventory_new
    )
}

path_script_inventory <-
  base::file.path(path_output, "r_script_path_inventory_v1.csv")

if (
  base::file.exists(path_script_inventory)
) {
  data_script_inventory_current <-
    data_script_inventory

  data_script_inventory_existing <-
    readr::read_csv(
      file = path_script_inventory,
      show_col_types = FALSE
    ) |>
    dplyr::mutate(
      script_name = fs::path_ext_remove(fs::path_file(.data[["current_path"]])),
      function_name = stringr::str_remove(script_name, "^test-")
    ) |>
    dplyr::left_join(
      data_issue141_function_migrations,
      by = dplyr::join_by(function_name)
    ) |>
    dplyr::mutate(
      intended_path = dplyr::if_else(
        !base::is.na(.data[["intended_function"]]) &
          stringr::str_starts(.data[["script_name"]], "test-"),
        stringr::str_c(
          fs::path_dir(.data[["current_path"]]),
          "/test-",
          .data[["intended_function"]],
          ".R"
        ),
        .data[["intended_path"]]
      ),
      migration_status = dplyr::if_else(
        !base::is.na(.data[["intended_function"]]) &
          stringr::str_starts(.data[["script_name"]], "test-"),
        "migrated",
        .data[["migration_status"]]
      )
    ) |>
    dplyr::select(-"script_name", -"function_name", -"intended_function") |>
    dplyr::filter(
      !(
        .data[["migration_status"]] == "baseline_recorded" &
          .data[["current_path"]] %in%
            stringr::str_c(
              "R/03_Supplementary_analyses/Testing/testthat/test-",
              data_issue141_function_migrations[["intended_function"]],
              ".R"
            )
      )
    ) |>
    dplyr::mutate(
      active_path = dplyr::case_when(
        .data[["migration_status"]] == "migrated" ~
          .data[["intended_path"]],
        .data[["migration_status"]] %in%
          base::c(
            "retired_to_legacy",
            "retired",
            "localized_to_presentation"
          ) ~ NA_character_,
        TRUE ~ .data[["current_path"]]
      )
    )

  data_script_inventory_new <-
    data_script_inventory_current |>
    dplyr::anti_join(
      data_script_inventory_existing,
      by = dplyr::join_by(current_path == active_path)
    )

  data_script_inventory <-
    dplyr::bind_rows(
      data_script_inventory_existing |>
        dplyr::select(-"active_path"),
      data_script_inventory_new
    )
}

path_contract_inventory <-
  base::file.path(path_output, "r_contract_inventory_v1.csv")

if (
  base::file.exists(path_contract_inventory)
) {
  data_contract_inventory_existing <-
    readr::read_csv(
      file = path_contract_inventory,
      show_col_types = FALSE
    )

  data_contract_inventory_new <-
    data_contract_inventory |>
    dplyr::anti_join(
      data_contract_inventory_existing,
      by = dplyr::join_by(contract_name, source_path)
    )

  data_contract_inventory <-
    dplyr::bind_rows(
      data_contract_inventory_existing,
      data_contract_inventory_new
    )
}


#----------------------------------------------------------#
# 6. Write version-one inventories -----
#----------------------------------------------------------#

base::dir.create(
  path = path_output,
  recursive = TRUE,
  showWarnings = FALSE
)

readr::write_csv(
  x = data_script_inventory,
  file = path_script_inventory,
  na = ""
)
readr::write_csv(
  x = data_function_inventory,
  file = path_function_inventory,
  na = ""
)
readr::write_csv(
  x = data_contract_inventory,
  file = path_contract_inventory,
  na = ""
)

cli::cli_inform(
  base::c(
    "v" = "R architecture inventories generated.",
    "i" = stringr::str_glue(
      "{base::nrow(data_script_inventory)} scripts, ",
      "{base::nrow(data_function_inventory)} functions, and ",
      "{base::nrow(data_contract_inventory)} literal targets."
    )
  )
)
