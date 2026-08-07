#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurence
#
#                   Check R architecture
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Enforce migrated placement rules and report remaining architecture findings.


#----------------------------------------------------------#
# 1. Load inventories and current paths -----
#----------------------------------------------------------#

path_inventory_root <-
  here::here(
    "Documentation/Implementation_inventories/R_architecture"
  )

data_scripts <-
  readr::read_csv(
    file = base::file.path(
      path_inventory_root,
      "r_script_path_inventory_v1.csv"
    ),
    show_col_types = FALSE
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

data_functions <-
  readr::read_csv(
    file = base::file.path(
      path_inventory_root,
      "r_function_inventory_v1.csv"
    ),
    show_col_types = FALSE
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
        ) ~
        NA_character_,
      TRUE ~ .data[["current_path"]]
    ),
    active_symbol = dplyr::case_when(
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

path_repository_root <-
  base::normalizePath(
    path = here::here(),
    winslash = "/"
  )

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
  )

vec_r_relative_paths <-
  base::substring(
    text = vec_r_paths,
    first = base::nchar(path_repository_root) + 2L
  )

vec_script_paths_current <-
  vec_r_relative_paths[
    !stringr::str_starts(
      vec_r_relative_paths,
      "R/Functions/"
    )
  ]

base::source(
  file = here::here(
    "R/Functions/Pipeline/Definitions/load_project_functions.R"
  ),
  local = base::environment()
)

data_functions_current <-
  load_project_functions(
    path_function_root = here::here("R/Functions"),
    environment_target = base::new.env(parent = base::globalenv()),
    vec_excluded_directory_names = "_legacy"
  )

vec_function_paths_current <-
  stringr::str_c(
    "R/Functions/",
    data_functions_current[["path_relative"]]
  )

vec_function_paths_inventoried <-
  data_functions[["active_path"]] |>
  purrr::discard(base::is.na)


#----------------------------------------------------------#
# 2. Build report-only findings -----
#----------------------------------------------------------#

data_findings <-
  tibble::tibble(
    finding_type = base::character(),
    severity = base::character(),
    current_path = base::character(),
    symbol = base::character(),
    owning_issue = base::character(),
    message = base::character()
  )

vec_uninventoried_scripts <-
  base::setdiff(
    vec_script_paths_current,
    data_scripts[["active_path"]]
  )

vec_missing_scripts <-
  base::setdiff(
    data_scripts[["active_path"]] |>
      purrr::discard(base::is.na),
    vec_script_paths_current
  )

vec_uninventoried_functions <-
  base::setdiff(
    vec_function_paths_current,
    vec_function_paths_inventoried
  )

vec_missing_functions <-
  base::setdiff(
    vec_function_paths_inventoried,
    vec_function_paths_current
  )

data_findings <-
  dplyr::bind_rows(
    data_findings,
    tibble::tibble(
      finding_type = "uninventoried_script",
      severity = "report_only",
      current_path = vec_uninventoried_scripts,
      symbol = NA_character_,
      owning_issue = "#150",
      message = "Add the active script to the versioned inventory."
    ),
    tibble::tibble(
      finding_type = "missing_script",
      severity = "report_only",
      current_path = vec_missing_scripts,
      symbol = NA_character_,
      owning_issue = "#150",
      message = "Record the approved script move or removal."
    ),
    tibble::tibble(
      finding_type = "uninventoried_function",
      severity = "report_only",
      current_path = vec_uninventoried_functions,
      symbol = NA_character_,
      owning_issue = "#150",
      message = "Add the active function to the versioned inventory."
    ),
    tibble::tibble(
      finding_type = "missing_function",
      severity = "report_only",
      current_path = vec_missing_functions,
      symbol = NA_character_,
      owning_issue = "#150",
      message = "Record the approved function move or removal."
    )
  )

data_placement_findings <-
  data_scripts |>
  dplyr::filter(.data[["migration_status"]] == "move_required") |>
  dplyr::mutate(
    finding_type = "script_placement",
    severity = dplyr::if_else(
      .data[["owning_issue"]] == "#152",
      "blocking",
      "report_only"
    ),
    current_path = .data[["active_path"]],
    symbol = NA_character_,
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_glue(
      "Move this `{.data[['classification']]}` workflow from main analyses."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

vec_main_analysis_paths <-
  vec_script_paths_current |>
  purrr::keep(
    ~ stringr::str_starts(.x, "R/02_Main_analyses/")
  )

vec_allowed_main_analysis_paths <-
  data_scripts |>
  dplyr::filter(
    stringr::str_starts(
      .data[["active_path"]],
      "R/02_Main_analyses/"
    ),
    .data[["classification"]] == "main_analysis"
  ) |>
  dplyr::pull(.data[["active_path"]])

vec_invalid_main_analysis_paths <-
  base::setdiff(
    vec_main_analysis_paths,
    vec_allowed_main_analysis_paths
  )

data_main_analysis_findings <-
  tibble::tibble(
    finding_type = "main_analysis_placement",
    severity = "blocking",
    current_path = vec_invalid_main_analysis_paths,
    symbol = NA_character_,
    owning_issue = "#152",
    message = "Only production analyses may remain in R/02_Main_analyses."
  )

data_migrated_data_processing_scripts <-
  data_scripts |>
  dplyr::filter(
    .data[["owning_issue"]] == "#153",
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["current_path"]],
      "R/01_Data_processing/"
    )
  )

vec_allowed_data_processing_script_paths <-
  data_migrated_data_processing_scripts |>
  dplyr::pull(.data[["active_path"]])

vec_legacy_data_processing_script_paths <-
  vec_script_paths_current[
    stringr::str_starts(
      vec_script_paths_current,
      "R/01_Data_processing/"
    )
  ]

vec_invalid_data_processing_script_paths <-
  base::union(
    vec_legacy_data_processing_script_paths,
    base::setdiff(
      vec_allowed_data_processing_script_paths,
      vec_script_paths_current
    )
  )

data_data_processing_script_findings <-
  tibble::tibble(
    finding_type = "data_processing_script_placement",
    severity = "blocking",
    current_path = vec_invalid_data_processing_script_paths,
    symbol = NA_character_,
    owning_issue = "#153",
    message = stringr::str_c(
      "Migrated R/01 data-processing scripts must remain in their ",
      "approved scientific-reference or historical locations."
    )
  )

vec_abiotic_function_paths_current <-
  vec_function_paths_current |>
  purrr::keep(
    ~ stringr::str_starts(
      .x,
      "R/Functions/Data/Abiotic/"
    )
  )

data_migrated_abiotic_functions <-
  data_functions |>
  dplyr::filter(
    stringr::str_starts(
      .data[["current_path"]],
      "R/Functions/Abiotic/"
    ),
    .data[["owning_issue"]] == "#153",
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["active_path"]],
      "R/Functions/Data/Abiotic/"
    )
  )

vec_allowed_abiotic_function_paths <-
  data_migrated_abiotic_functions |>
  dplyr::pull(.data[["active_path"]])

vec_legacy_abiotic_function_paths <-
  base::intersect(
    vec_function_paths_current,
    data_migrated_abiotic_functions[["current_path"]]
  )

vec_invalid_abiotic_function_paths <-
  base::union(
    vec_legacy_abiotic_function_paths,
    base::union(
      base::setdiff(
        vec_abiotic_function_paths_current,
        vec_allowed_abiotic_function_paths
      ),
      base::setdiff(
        vec_allowed_abiotic_function_paths,
        vec_abiotic_function_paths_current
      )
    )
  )

data_abiotic_function_findings <-
  tibble::tibble(
    finding_type = "abiotic_function_placement",
    severity = "blocking",
    current_path = vec_invalid_abiotic_function_paths,
    symbol = NA_character_,
    owning_issue = "#153",
    message = stringr::str_c(
      "Abiotic functions must match the migrated ",
      "R/Functions/Data/Abiotic inventory."
    )
  )

data_abiotic_naming_findings <-
  data_migrated_abiotic_functions |>
  dplyr::filter(
    .data[["naming_status"]] != "canonical_or_domain_verb"
  ) |>
  dplyr::mutate(
    finding_type = "abiotic_function_naming",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_c(
      "Migrated Abiotic functions must use an approved canonical ",
      "or domain verb."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

path_abiotic_test_root <-
  stringr::str_c(
    "R/03_Supplementary_analyses/Testing/testthat/",
    "Data/Abiotic/"
  )

vec_abiotic_test_paths_current <-
  vec_script_paths_current |>
  purrr::keep(
    ~ stringr::str_starts(
      .x,
      path_abiotic_test_root
    )
  )

data_migrated_abiotic_tests <-
  data_scripts |>
  dplyr::filter(
    .data[["owning_issue"]] == "#153",
    .data[["classification"]] == "test",
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["active_path"]],
      path_abiotic_test_root
    )
  )

vec_allowed_abiotic_test_paths <-
  data_migrated_abiotic_tests |>
  dplyr::pull(.data[["active_path"]])

vec_legacy_abiotic_test_paths <-
  base::intersect(
    vec_script_paths_current,
    data_migrated_abiotic_tests[["current_path"]]
  )

vec_invalid_abiotic_test_paths <-
  base::union(
    vec_legacy_abiotic_test_paths,
    base::union(
      base::setdiff(
        vec_abiotic_test_paths_current,
        vec_allowed_abiotic_test_paths
      ),
      base::setdiff(
        vec_allowed_abiotic_test_paths,
        vec_abiotic_test_paths_current
      )
    )
  )

data_abiotic_test_findings <-
  tibble::tibble(
    finding_type = "abiotic_test_placement",
    severity = "blocking",
    current_path = vec_invalid_abiotic_test_paths,
    symbol = NA_character_,
    owning_issue = "#153",
    message = stringr::str_c(
      "Abiotic tests must mirror the migrated ",
      "R/Functions/Data/Abiotic hierarchy."
    )
  )

path_trait_function_root <-
  "R/Functions/Data/Traits/"

vec_trait_function_paths_current <-
  vec_function_paths_current[
    stringr::str_starts(
      vec_function_paths_current,
      path_trait_function_root
    )
  ]

data_migrated_trait_functions <-
  data_functions |>
  dplyr::filter(
    .data[["owning_issue"]] %in% base::c("#153", "#155"),
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["active_path"]],
      path_trait_function_root
    )
  )

vec_allowed_trait_function_paths <-
  data_migrated_trait_functions |>
  dplyr::pull(.data[["active_path"]])

vec_legacy_trait_function_paths <-
  base::intersect(
    vec_function_paths_current,
    data_migrated_trait_functions[["current_path"]]
  )

vec_invalid_trait_function_paths <-
  base::union(
    vec_legacy_trait_function_paths,
    base::union(
      base::setdiff(
        vec_trait_function_paths_current,
        vec_allowed_trait_function_paths
      ),
      base::setdiff(
        vec_allowed_trait_function_paths,
        vec_trait_function_paths_current
      )
    )
  )

data_trait_function_findings <-
  tibble::tibble(
    finding_type = "trait_function_placement",
    severity = "blocking",
    current_path = vec_invalid_trait_function_paths,
    symbol = NA_character_,
    owning_issue = "#153",
    message = stringr::str_c(
      "Trait functions must match the migrated ",
      "R/Functions/Data/Traits inventory."
    )
  )

data_trait_naming_findings <-
  data_migrated_trait_functions |>
  dplyr::filter(
    .data[["naming_status"]] != "canonical_or_domain_verb"
  ) |>
  dplyr::mutate(
    finding_type = "trait_function_naming",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_c(
      "Migrated trait functions must use an approved ",
      "canonical or domain verb."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

path_trait_test_root <-
  stringr::str_c(
    "R/03_Supplementary_analyses/Testing/testthat/",
    "Data/Traits/"
  )

vec_trait_test_paths_current <-
  vec_script_paths_current[
    stringr::str_starts(
      vec_script_paths_current,
      path_trait_test_root
    )
  ]

data_migrated_trait_tests <-
  data_scripts |>
  dplyr::filter(
    .data[["owning_issue"]] %in% base::c("#153", "#155"),
    .data[["classification"]] == "test",
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["active_path"]],
      path_trait_test_root
    )
  )

vec_allowed_trait_test_paths <-
  data_migrated_trait_tests |>
  dplyr::pull(.data[["active_path"]])

vec_legacy_trait_test_paths <-
  base::intersect(
    vec_script_paths_current,
    data_migrated_trait_tests[["current_path"]]
  )

vec_invalid_trait_test_paths <-
  base::union(
    vec_legacy_trait_test_paths,
    base::union(
      base::setdiff(
        vec_trait_test_paths_current,
        vec_allowed_trait_test_paths
      ),
      base::setdiff(
        vec_allowed_trait_test_paths,
        vec_trait_test_paths_current
      )
    )
  )

data_trait_test_findings <-
  tibble::tibble(
    finding_type = "trait_test_placement",
    severity = "blocking",
    current_path = vec_invalid_trait_test_paths,
    symbol = NA_character_,
    owning_issue = "#153",
    message = stringr::str_c(
      "Trait tests must mirror the migrated ",
      "R/Functions/Data/Traits hierarchy."
    )
  )

path_spatial_function_root <-
  "R/Functions/Data/Spatial/"

vec_spatial_function_paths_current <-
  vec_function_paths_current[
    stringr::str_starts(
      vec_function_paths_current,
      path_spatial_function_root
    )
  ]

data_migrated_spatial_functions <-
  data_functions |>
  dplyr::filter(
    .data[["owning_issue"]] %in% base::c("#153", "#155"),
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["active_path"]],
      path_spatial_function_root
    )
  )

vec_allowed_spatial_function_paths <-
  data_migrated_spatial_functions |>
  dplyr::pull(.data[["active_path"]])

vec_invalid_spatial_function_paths <-
  base::union(
    base::setdiff(
      vec_spatial_function_paths_current,
      vec_allowed_spatial_function_paths
    ),
    base::setdiff(
      vec_allowed_spatial_function_paths,
      vec_spatial_function_paths_current
    )
  )

data_spatial_function_findings <-
  tibble::tibble(
    finding_type = "spatial_function_placement",
    severity = "blocking",
    current_path = vec_invalid_spatial_function_paths,
    symbol = NA_character_,
    owning_issue = "#153",
    message = stringr::str_c(
      "Spatial functions must match the migrated ",
      "R/Functions/Data/Spatial inventory."
    )
  )

data_spatial_naming_findings <-
  data_migrated_spatial_functions |>
  dplyr::filter(
    .data[["naming_status"]] != "canonical_or_domain_verb"
  ) |>
  dplyr::mutate(
    finding_type = "spatial_function_naming",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_c(
      "Migrated Spatial functions must use an approved canonical ",
      "or domain verb."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

path_spatial_test_root <-
  stringr::str_c(
    "R/03_Supplementary_analyses/Testing/testthat/",
    "Data/Spatial/"
  )

vec_spatial_test_paths_current <-
  vec_script_paths_current[
    stringr::str_starts(
      vec_script_paths_current,
      path_spatial_test_root
    )
  ]

data_migrated_spatial_tests <-
  data_scripts |>
  dplyr::filter(
    .data[["owning_issue"]] %in% base::c("#153", "#155"),
    .data[["classification"]] == "test",
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["active_path"]],
      path_spatial_test_root
    )
  )

vec_allowed_spatial_test_paths <-
  data_migrated_spatial_tests |>
  dplyr::pull(.data[["active_path"]])

vec_invalid_spatial_test_paths <-
  base::union(
    base::setdiff(
      vec_spatial_test_paths_current,
      vec_allowed_spatial_test_paths
    ),
    base::setdiff(
      vec_allowed_spatial_test_paths,
      vec_spatial_test_paths_current
    )
  )

data_spatial_test_findings <-
  tibble::tibble(
    finding_type = "spatial_test_placement",
    severity = "blocking",
    current_path = vec_invalid_spatial_test_paths,
    symbol = NA_character_,
    owning_issue = "#153",
    message = stringr::str_c(
      "Spatial tests must mirror the migrated ",
      "R/Functions/Data/Spatial hierarchy."
    )
  )

vec_community_function_paths_current <-
  vec_function_paths_current |>
  purrr::keep(
    ~ stringr::str_starts(
      .x,
      "R/Functions/Data/Community/"
    )
  )

data_migrated_community_functions <-
  data_functions |>
  dplyr::filter(
    stringr::str_starts(
      .data[["current_path"]],
      "R/Functions/Community/"
    ),
    .data[["owning_issue"]] == "#153",
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["active_path"]],
      "R/Functions/Data/Community/"
    )
  )

vec_allowed_community_function_paths <-
  data_migrated_community_functions |>
  dplyr::pull(.data[["active_path"]])

vec_legacy_community_function_paths <-
  base::intersect(
    vec_function_paths_current,
    data_migrated_community_functions[["current_path"]]
  )

vec_invalid_community_function_paths <-
  base::union(
    vec_legacy_community_function_paths,
    base::union(
      base::setdiff(
        vec_community_function_paths_current,
        vec_allowed_community_function_paths
      ),
      base::setdiff(
        vec_allowed_community_function_paths,
        vec_community_function_paths_current
      )
    )
  )

data_community_function_findings <-
  tibble::tibble(
    finding_type = "community_function_placement",
    severity = "blocking",
    current_path = vec_invalid_community_function_paths,
    symbol = NA_character_,
    owning_issue = "#153",
    message = stringr::str_c(
      "Community functions must match the migrated ",
      "R/Functions/Data/Community inventory."
    )
  )

vec_community_classification_function_roots <-
  base::c(
    "R/Functions/Data/Community/Classification/",
    "R/Functions/Data/Community/Ingest/Classification/"
  )

data_migrated_community_classification_functions <-
  data_migrated_community_functions |>
  dplyr::filter(
    purrr::map_lgl(
      .data[["active_path"]],
      ~ base::any(
        stringr::str_starts(
          .x,
          vec_community_classification_function_roots
        )
      )
    )
  )

data_community_classification_naming_findings <-
  data_migrated_community_classification_functions |>
  dplyr::filter(
    .data[["naming_status"]] != "canonical_or_domain_verb"
  ) |>
  dplyr::mutate(
    finding_type = "community_classification_function_naming",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_c(
      "Migrated Community classification functions must use an approved ",
      "canonical or domain verb."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

data_migrated_community_quality_control_functions <-
  data_migrated_community_functions |>
  dplyr::filter(
    stringr::str_starts(
      .data[["active_path"]],
      "R/Functions/Data/Community/Quality_control/"
    )
  )

data_community_quality_control_naming_findings <-
  data_migrated_community_quality_control_functions |>
  dplyr::filter(
    .data[["naming_status"]] != "canonical_or_domain_verb"
  ) |>
  dplyr::mutate(
    finding_type = "community_quality_control_function_naming",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_c(
      "Migrated Community quality-control functions must use an approved ",
      "canonical or domain verb."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

data_migrated_community_modern_record_functions <-
  data_migrated_community_functions |>
  dplyr::filter(
    stringr::str_starts(
      .data[["active_path"]],
      "R/Functions/Data/Community/Transformation/Modern_records/"
    )
  )

data_community_modern_record_naming_findings <-
  data_migrated_community_modern_record_functions |>
  dplyr::filter(
    .data[["naming_status"]] != "canonical_or_domain_verb"
  ) |>
  dplyr::mutate(
    finding_type = "community_modern_record_function_naming",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_c(
      "Migrated Community modern-record functions must use an approved ",
      "canonical or domain verb."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

data_migrated_community_proportion_functions <-
  data_migrated_community_functions |>
  dplyr::filter(
    stringr::str_starts(
      .data[["active_path"]],
      "R/Functions/Data/Community/Transformation/Proportions/"
    )
  )

data_community_proportion_naming_findings <-
  data_migrated_community_proportion_functions |>
  dplyr::filter(
    .data[["naming_status"]] != "canonical_or_domain_verb"
  ) |>
  dplyr::mutate(
    finding_type = "community_proportion_function_naming",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_c(
      "Migrated Community proportion functions must use an approved ",
      "canonical or domain verb."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

data_migrated_community_data_shape_functions <-
  data_migrated_community_functions |>
  dplyr::filter(
    stringr::str_starts(
      .data[["active_path"]],
      "R/Functions/Data/Community/Transformation/Data_shape/"
    )
  )

data_community_data_shape_naming_findings <-
  data_migrated_community_data_shape_functions |>
  dplyr::filter(
    .data[["naming_status"]] != "canonical_or_domain_verb"
  ) |>
  dplyr::mutate(
    finding_type = "community_data_shape_function_naming",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_c(
      "Migrated Community data-shape functions must use an approved ",
      "canonical or domain verb."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

data_migrated_community_taxa_selection_functions <-
  data_migrated_community_functions |>
  dplyr::filter(
    stringr::str_starts(
      .data[["active_path"]],
      "R/Functions/Data/Community/Transformation/Taxa_selection/"
    )
  )

data_community_taxa_selection_naming_findings <-
  data_migrated_community_taxa_selection_functions |>
  dplyr::filter(
    .data[["naming_status"]] != "canonical_or_domain_verb"
  ) |>
  dplyr::mutate(
    finding_type = "community_taxa_selection_function_naming",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_c(
      "Migrated Community taxa-selection functions must use an approved ",
      "canonical or domain verb."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

path_community_test_root <-
  stringr::str_c(
    "R/03_Supplementary_analyses/Testing/testthat/",
    "Data/Community/"
  )

vec_community_test_paths_current <-
  vec_script_paths_current |>
  purrr::keep(
    ~ stringr::str_starts(
      .x,
      path_community_test_root
    )
  )

data_migrated_community_tests <-
  data_scripts |>
  dplyr::filter(
    .data[["owning_issue"]] == "#153",
    .data[["classification"]] == "test",
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["active_path"]],
      path_community_test_root
    )
  )

vec_allowed_community_test_paths <-
  data_migrated_community_tests |>
  dplyr::pull(.data[["active_path"]])

vec_legacy_community_test_paths <-
  base::intersect(
    vec_script_paths_current,
    data_migrated_community_tests[["current_path"]]
  )

vec_invalid_community_test_paths <-
  base::union(
    vec_legacy_community_test_paths,
    base::union(
      base::setdiff(
        vec_community_test_paths_current,
        vec_allowed_community_test_paths
      ),
      base::setdiff(
        vec_allowed_community_test_paths,
        vec_community_test_paths_current
      )
    )
  )

data_community_test_findings <-
  tibble::tibble(
    finding_type = "community_test_placement",
    severity = "blocking",
    current_path = vec_invalid_community_test_paths,
    symbol = NA_character_,
    owning_issue = "#153",
    message = stringr::str_c(
      "Community tests must mirror the migrated ",
      "R/Functions/Data/Community hierarchy."
    )
  )

path_time_ages_function_root <-
  "R/Functions/Data/Time/Ages/"

vec_time_ages_function_paths_current <-
  vec_function_paths_current |>
  purrr::keep(
    ~ stringr::str_starts(
      .x,
      path_time_ages_function_root
    )
  )

data_migrated_time_ages_functions <-
  data_functions |>
  dplyr::filter(
    stringr::str_starts(
      .data[["current_path"]],
      "R/Functions/Time/Ages/"
    ),
    .data[["owning_issue"]] == "#153",
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["active_path"]],
      path_time_ages_function_root
    )
  )

vec_allowed_time_ages_function_paths <-
  data_migrated_time_ages_functions |>
  dplyr::pull(.data[["active_path"]])

vec_legacy_time_ages_function_paths <-
  base::intersect(
    vec_function_paths_current,
    data_migrated_time_ages_functions[["current_path"]]
  )

vec_invalid_time_ages_function_paths <-
  base::union(
    vec_legacy_time_ages_function_paths,
    base::union(
      base::setdiff(
        vec_time_ages_function_paths_current,
        vec_allowed_time_ages_function_paths
      ),
      base::setdiff(
        vec_allowed_time_ages_function_paths,
        vec_time_ages_function_paths_current
      )
    )
  )

data_time_ages_function_findings <-
  tibble::tibble(
    finding_type = "time_ages_function_placement",
    severity = "blocking",
    current_path = vec_invalid_time_ages_function_paths,
    symbol = NA_character_,
    owning_issue = "#153",
    message = stringr::str_c(
      "Time/Ages functions must match the migrated ",
      "R/Functions/Data/Time/Ages inventory."
    )
  )

data_time_ages_naming_findings <-
  data_migrated_time_ages_functions |>
  dplyr::filter(
    .data[["naming_status"]] != "canonical_or_domain_verb"
  ) |>
  dplyr::mutate(
    finding_type = "time_ages_function_naming",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_c(
      "Migrated Time/Ages functions must use an approved canonical ",
      "or domain verb."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

path_time_ages_test_root <-
  stringr::str_c(
    "R/03_Supplementary_analyses/Testing/testthat/",
    "Data/Time/Ages/"
  )

vec_time_ages_test_paths_current <-
  vec_script_paths_current |>
  purrr::keep(
    ~ stringr::str_starts(
      .x,
      path_time_ages_test_root
    )
  )

data_migrated_time_ages_tests <-
  data_scripts |>
  dplyr::filter(
    .data[["owning_issue"]] == "#153",
    .data[["classification"]] == "test",
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["active_path"]],
      path_time_ages_test_root
    )
  )

vec_allowed_time_ages_test_paths <-
  data_migrated_time_ages_tests |>
  dplyr::pull(.data[["active_path"]])

vec_legacy_time_ages_test_paths <-
  base::intersect(
    vec_script_paths_current,
    data_migrated_time_ages_tests[["current_path"]]
  )

vec_invalid_time_ages_test_paths <-
  base::union(
    vec_legacy_time_ages_test_paths,
    base::union(
      base::setdiff(
        vec_time_ages_test_paths_current,
        vec_allowed_time_ages_test_paths
      ),
      base::setdiff(
        vec_allowed_time_ages_test_paths,
        vec_time_ages_test_paths_current
      )
    )
  )

data_time_ages_test_findings <-
  tibble::tibble(
    finding_type = "time_ages_test_placement",
    severity = "blocking",
    current_path = vec_invalid_time_ages_test_paths,
    symbol = NA_character_,
    owning_issue = "#153",
    message = stringr::str_c(
      "Time/Ages tests must mirror the migrated ",
      "R/Functions/Data/Time/Ages hierarchy."
    )
  )

path_time_interpolation_function_root <-
  "R/Functions/Data/Time/Interpolation/"

vec_time_interpolation_function_paths_current <-
  vec_function_paths_current |>
  purrr::keep(
    ~ stringr::str_starts(
      .x,
      path_time_interpolation_function_root
    )
  )

data_migrated_time_interpolation_functions <-
  data_functions |>
  dplyr::filter(
    (
      stringr::str_starts(
        .data[["current_path"]],
        "R/Functions/Time/Interpolation/"
      ) |
      stringr::str_starts(
        .data[["current_path"]],
        "R/Functions/Time/Interpolation_jobs/"
      ) |
        stringr::str_starts(
          .data[["current_path"]],
          path_time_interpolation_function_root
        )
    ),
    .data[["owning_issue"]] == "#153",
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["active_path"]],
      path_time_interpolation_function_root
    )
  )

vec_allowed_time_interpolation_function_paths <-
  data_migrated_time_interpolation_functions |>
  dplyr::pull(.data[["active_path"]])

vec_legacy_time_interpolation_function_paths <-
  base::intersect(
    vec_function_paths_current,
    data_migrated_time_interpolation_functions |>
      dplyr::filter(
        .data[["current_path"]] != .data[["active_path"]]
      ) |>
      dplyr::pull(.data[["current_path"]])
  )

vec_invalid_time_interpolation_function_paths <-
  base::union(
    vec_legacy_time_interpolation_function_paths,
    base::union(
      base::setdiff(
        vec_time_interpolation_function_paths_current,
        vec_allowed_time_interpolation_function_paths
      ),
      base::setdiff(
        vec_allowed_time_interpolation_function_paths,
        vec_time_interpolation_function_paths_current
      )
    )
  )

data_time_interpolation_function_findings <-
  tibble::tibble(
    finding_type = "time_interpolation_function_placement",
    severity = "blocking",
    current_path = vec_invalid_time_interpolation_function_paths,
    symbol = NA_character_,
    owning_issue = "#153",
    message = stringr::str_c(
      "Time/Interpolation functions must match the migrated ",
      "R/Functions/Data/Time/Interpolation inventory."
    )
  )

data_time_interpolation_naming_findings <-
  data_migrated_time_interpolation_functions |>
  dplyr::filter(
    .data[["naming_status"]] != "canonical_or_domain_verb"
  ) |>
  dplyr::mutate(
    finding_type = "time_interpolation_function_naming",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_c(
      "Migrated Time/Interpolation functions must use an approved ",
      "canonical or domain verb."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

data_retired_time_interpolation_functions <-
  data_functions |>
  dplyr::filter(
    .data[["owning_issue"]] == "#153",
    .data[["migration_status"]] == "retired_to_legacy"
  )

data_time_interpolation_retirement_findings <-
  data_retired_time_interpolation_functions |>
  dplyr::filter(
    !stringr::str_detect(
      .data[["intended_path"]],
      "(^|/)_legacy(/|$)"
    ) |
      !.data[["intended_path"]] %in% vec_r_relative_paths
  ) |>
  dplyr::mutate(
    finding_type = "time_interpolation_function_retirement",
    severity = "blocking",
    current_path = .data[["intended_path"]],
    symbol = .data[["intended_function"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_c(
      "Retired Time/Interpolation functions must remain below ",
      "an exact `_legacy` directory."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

path_time_interpolation_test_root <-
  stringr::str_c(
    "R/03_Supplementary_analyses/Testing/testthat/",
    "Data/Time/Interpolation/"
  )

vec_time_interpolation_test_paths_current <-
  vec_script_paths_current |>
  purrr::keep(
    ~ stringr::str_starts(
      .x,
      path_time_interpolation_test_root
    ) &&
      !stringr::str_detect(
        .x,
        "(^|/)_outdated(/|$)"
      )
  )

data_migrated_time_interpolation_tests <-
  data_scripts |>
  dplyr::filter(
    .data[["owning_issue"]] == "#153",
    .data[["classification"]] == "test",
    .data[["lifecycle_status"]] == "active",
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["active_path"]],
      path_time_interpolation_test_root
    )
  )

vec_allowed_time_interpolation_test_paths <-
  data_migrated_time_interpolation_tests |>
  dplyr::pull(.data[["active_path"]])

vec_legacy_time_interpolation_test_paths <-
  base::intersect(
    vec_script_paths_current,
    data_migrated_time_interpolation_tests[["current_path"]]
  )

vec_invalid_time_interpolation_test_paths <-
  base::union(
    vec_legacy_time_interpolation_test_paths,
    base::union(
      base::setdiff(
        vec_time_interpolation_test_paths_current,
        vec_allowed_time_interpolation_test_paths
      ),
      base::setdiff(
        vec_allowed_time_interpolation_test_paths,
        vec_time_interpolation_test_paths_current
      )
    )
  )

data_time_interpolation_test_findings <-
  tibble::tibble(
    finding_type = "time_interpolation_test_placement",
    severity = "blocking",
    current_path = vec_invalid_time_interpolation_test_paths,
    symbol = NA_character_,
    owning_issue = "#153",
    message = stringr::str_c(
      "Active Time/Interpolation tests must mirror the migrated ",
      "R/Functions/Data/Time/Interpolation hierarchy."
    )
  )

path_retired_hmsc_function_root <-
  "R/Functions/Modelling/_legacy/"

vec_retired_hmsc_symbols <-
  base::c(
    "add_model_evaluation",
    "check_and_prepare_data_for_fit",
    "fit_hmsc_model",
    "get_better_model_based_on_fit",
    "get_random_structure_for_model",
    "get_significant_associations",
    "get_species_association",
    "make_hmsc_model"
  )

vec_retired_hmsc_test_paths <-
  stringr::str_c(
    "R/03_Supplementary_analyses/Testing/testthat/_outdated/",
    base::c(
      "test-add_model_evaluation.R",
      "test-check_and_prepare_data_for_fit.R",
      "test-fit_hmsc_model.R",
      "test-get_better_model_based_on_fit.R",
      "test-get_random_structure_for_model.R",
      "test-get_significant_associations .R",
      "test-get_species_association.R",
      "test-make_hmsc_model.R",
      "test-prepare_data_for_fit.R"
    )
  )

vec_returned_hmsc_function_paths <-
  vec_r_relative_paths[
    stringr::str_starts(
      vec_r_relative_paths,
      path_retired_hmsc_function_root
    )
  ]

vec_returned_hmsc_test_paths <-
  base::intersect(
    vec_r_relative_paths,
    vec_retired_hmsc_test_paths
  )

data_hmsc_retirement_path_findings <-
  tibble::tibble(
    finding_type = "hmsc_retirement_path",
    severity = "blocking",
    current_path = base::c(
      vec_returned_hmsc_function_paths,
      vec_returned_hmsc_test_paths
    ),
    symbol = NA_character_,
    owning_issue = "#154",
    message = "Retired HMSC functions and tests must not return."
  )

data_hmsc_retirement_symbol_findings <-
  data_functions_current |>
  dplyr::filter(
    .data[["function_name"]] %in% vec_retired_hmsc_symbols
  ) |>
  dplyr::transmute(
    finding_type = "hmsc_retirement_symbol",
    severity = "blocking",
    current_path = stringr::str_c(
      "R/Functions/",
      .data[["path_relative"]]
    ),
    symbol = .data[["function_name"]],
    owning_issue = "#154",
    message = "Retired HMSC function symbols must not return."
  )

data_migrated_issue154_functions <-
  data_functions |>
  dplyr::filter(
    .data[["owning_issue"]] == "#154",
    .data[["migration_status"]] == "migrated"
  )

vec_allowed_issue154_function_paths <-
  data_migrated_issue154_functions |>
  dplyr::pull(.data[["active_path"]])

vec_legacy_issue154_function_paths <-
  base::intersect(
    vec_function_paths_current,
    data_migrated_issue154_functions |>
      dplyr::filter(
        .data[["current_path"]] != .data[["active_path"]]
      ) |>
      dplyr::pull(.data[["current_path"]])
  )

vec_invalid_issue154_function_paths <-
  base::union(
    vec_legacy_issue154_function_paths,
    base::setdiff(
      vec_allowed_issue154_function_paths,
      vec_function_paths_current
    )
  )

data_issue154_function_placement_findings <-
  tibble::tibble(
    finding_type = "issue154_function_placement",
    severity = "blocking",
    current_path = vec_invalid_issue154_function_paths,
    symbol = NA_character_,
    owning_issue = "#154",
    message = stringr::str_c(
      "Migrated non-CV modelling functions must remain at their ",
      "approved capability paths."
    )
  )

data_issue154_naming_findings <-
  data_migrated_issue154_functions |>
  dplyr::filter(
    .data[["naming_status"]] != "canonical_or_domain_verb"
  ) |>
  dplyr::transmute(
    finding_type = "issue154_function_naming",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = "#154",
    message = "Migrated modelling functions must use approved verbs."
  )

path_issue154_test_root <-
  stringr::str_c(
    "R/03_Supplementary_analyses/Testing/testthat/",
    "Modelling/"
  )

data_migrated_issue154_tests <-
  data_scripts |>
  dplyr::filter(
    .data[["owning_issue"]] == "#154",
    .data[["classification"]] == "test",
    .data[["migration_status"]] == "migrated",
    stringr::str_starts(
      .data[["active_path"]],
      path_issue154_test_root
    )
  )

vec_allowed_issue154_test_paths <-
  data_migrated_issue154_tests |>
  dplyr::pull(.data[["active_path"]])

vec_legacy_issue154_test_paths <-
  base::intersect(
    vec_script_paths_current,
    data_migrated_issue154_tests |>
      dplyr::filter(
        .data[["current_path"]] != .data[["active_path"]]
      ) |>
      dplyr::pull(.data[["current_path"]])
  )

vec_invalid_issue154_test_paths <-
  base::union(
    vec_legacy_issue154_test_paths,
    base::setdiff(
      vec_allowed_issue154_test_paths,
      vec_script_paths_current
    )
  )

data_issue154_test_placement_findings <-
  tibble::tibble(
    finding_type = "issue154_test_placement",
    severity = "blocking",
    current_path = vec_invalid_issue154_test_paths,
    symbol = NA_character_,
    owning_issue = "#154",
    message = stringr::str_c(
      "Migrated non-CV modelling tests must remain at their ",
      "approved capability paths."
    )
  )

data_issue154_test_mirror_findings <-
  data_migrated_issue154_functions |>
  dplyr::mutate(
    expected_test_path = .data[["active_path"]] |>
      stringr::str_replace(
        "^R/Functions/Modelling/",
        path_issue154_test_root
      ) |>
      stringr::str_replace(
        "/([^/]+)[.]R$",
        "/test-\\1.R"
      ),
    has_mirrored_test = dplyr::coalesce(
      stringr::str_detect(
        .data[["matching_tests"]],
        stringr::fixed(.data[["expected_test_path"]])
      ),
      FALSE
    )
  ) |>
  dplyr::filter(!.data[["has_mirrored_test"]]) |>
  dplyr::transmute(
    finding_type = "issue154_test_mirror",
    severity = "blocking",
    current_path = .data[["expected_test_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = "#154",
    message = "Each migrated modelling function needs a mirrored test."
  )

vec_allowed_issue154_internal_paths <-
  base::c(
    "R/Functions/Modelling/Decomposition/Internal/" |>
      stringr::str_c("build_empty_decomposition_variant.R"),
    "R/Functions/Modelling/Decomposition/Internal/" |>
      stringr::str_c("load_decomposition_model_fitting_config.R"),
    "R/Functions/Modelling/Decomposition/Internal/" |>
      stringr::str_c("load_decomposition_target.R"),
    "R/Functions/Modelling/Decomposition/Internal/" |>
      stringr::str_c("resolve_decomposition_fold_loss.R"),
    "R/Functions/Modelling/Evaluation/Internal/" |>
      stringr::str_c("build_empty_spatial_model_results.R"),
    "R/Functions/Modelling/Evaluation/Internal/" |>
      stringr::str_c("fit_binary_calibration_model.R"),
    "R/Functions/Modelling/Evaluation/Internal/" |>
      stringr::str_c("load_successful_model_target.R"),
    "R/Functions/Modelling/Evaluation/Internal/" |>
      stringr::str_c("summarise_fitted_auc.R"),
    "R/Functions/Modelling/Evaluation/Internal/" |>
      stringr::str_c("summarise_model_provenance.R"),
    "R/Functions/Modelling/Fitting/Internal/" |>
      stringr::str_c("build_sjsdm_predictor_structure.R"),
    "R/Functions/Modelling/Fitting/Internal/" |>
      stringr::str_c("prepare_sjsdm_response.R"),
    "R/Functions/Modelling/Fitting/Internal/" |>
      stringr::str_c("resolve_sjsdm_device.R"),
    "R/Functions/Modelling/Fitting/Internal/" |>
      stringr::str_c("resolve_sjsdm_early_stopping.R"),
    "R/Functions/Modelling/Spatial_effects/Basis/Internal/" |>
      stringr::str_c("compute_exact_spatial_mev_basis.R"),
    "R/Functions/Modelling/Variance_partitioning/Internal/" |>
      stringr::str_c("lookup_jsdm_variance_component.R")
  )

vec_issue154_internal_paths_current <-
  vec_function_paths_current[
    stringr::str_detect(
      vec_function_paths_current,
      "^R/Functions/Modelling/.*/Internal/"
    )
  ]

vec_invalid_issue154_internal_paths <-
  base::union(
    base::setdiff(
      vec_issue154_internal_paths_current,
      vec_allowed_issue154_internal_paths
    ),
    base::setdiff(
      vec_allowed_issue154_internal_paths,
      vec_issue154_internal_paths_current
    )
  )

data_issue154_internal_findings <-
  tibble::tibble(
    finding_type = "issue154_internal_contract",
    severity = "blocking",
    current_path = vec_invalid_issue154_internal_paths,
    symbol = NA_character_,
    owning_issue = "#154",
    message = stringr::str_c(
      "Internal modelling functions must match the reviewed small-helper ",
      "allowlist."
    )
  )

vec_issue154_active_paths <-
  data_functions |>
  dplyr::filter(
    .data[["owning_issue"]] == "#154",
    !base::is.na(.data[["active_path"]])
  ) |>
  dplyr::pull(.data[["active_path"]]) |>
  base::intersect(vec_function_paths_current)

data_issue154_dollar_access_findings <-
  purrr::map_dfr(
    .x = vec_issue154_active_paths,
    .f = function(path_current) {
      vec_lines <-
        base::readLines(
          con = here::here(path_current),
          warn = FALSE,
          encoding = "UTF-8"
        )

      vec_match_indices <-
        base::which(
          stringr::str_detect(
            vec_lines,
            "[A-Za-z0-9_.]+[$][A-Za-z.]"
          )
        )

      tibble::tibble(
        finding_type = "issue154_dollar_access",
        severity = "blocking",
        current_path = base::rep(
          path_current,
          base::length(vec_match_indices)
        ),
        symbol = stringr::str_c("line_", vec_match_indices),
        owning_issue = "#154",
        message = "Replace prohibited `$` access in modelling functions."
      )
    }
  )

data_issue155_functions <-
  data_functions |>
  dplyr::filter(.data[["owning_issue"]] == "#155")

data_migrated_issue155_functions <-
  data_issue155_functions |>
  dplyr::filter(.data[["migration_status"]] == "migrated")

data_localized_issue155_functions <-
  data_issue155_functions |>
  dplyr::filter(
    .data[["migration_status"]] == "localized_to_presentation"
  )

data_retired_issue155_functions <-
  data_issue155_functions |>
  dplyr::filter(.data[["migration_status"]] == "retired")

data_issue155_function_placement_findings <-
  data_migrated_issue155_functions |>
  dplyr::filter(
    !base::file.exists(here::here(.data[["active_path"]])) |
      (
        .data[["current_path"]] != .data[["active_path"]] &
          base::file.exists(here::here(.data[["current_path"]]))
      )
  ) |>
  dplyr::transmute(
    finding_type = "issue155_function_placement",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = "#155",
    message = stringr::str_c(
      "Issue #155 functions must remain at their approved capability paths."
    )
  )

data_issue155_localization_findings <-
  data_localized_issue155_functions |>
  dplyr::filter(
    !base::file.exists(here::here(.data[["intended_path"]])) |
      base::file.exists(here::here(.data[["current_path"]]))
  ) |>
  dplyr::transmute(
    finding_type = "issue155_presentation_localization",
    severity = "blocking",
    current_path = .data[["intended_path"]],
    symbol = .data[["intended_function"]],
    owning_issue = "#155",
    message = "IAVS-only helpers must remain presentation-local."
  )

data_issue155_retirement_path_findings <-
  data_retired_issue155_functions |>
  dplyr::filter(base::file.exists(here::here(.data[["current_path"]]))) |>
  dplyr::transmute(
    finding_type = "issue155_retirement_path",
    severity = "blocking",
    current_path = .data[["current_path"]],
    symbol = .data[["function_name"]],
    owning_issue = "#155",
    message = "Retired Issue #155 function paths must not return."
  )

vec_issue155_inactive_symbols <-
  base::unique(
    base::c(
      data_localized_issue155_functions[["function_name"]],
      data_localized_issue155_functions[["intended_function"]],
      data_retired_issue155_functions[["function_name"]]
    )
  )

data_issue155_inactive_symbol_findings <-
  data_functions_current |>
  dplyr::filter(
    .data[["function_name"]] %in% vec_issue155_inactive_symbols
  ) |>
  dplyr::transmute(
    finding_type = "issue155_inactive_symbol",
    severity = "blocking",
    current_path = stringr::str_c(
      "R/Functions/",
      .data[["path_relative"]]
    ),
    symbol = .data[["function_name"]],
    owning_issue = "#155",
    message = "Retired and presentation-local symbols must not load globally."
  )

data_issue155_naming_findings <-
  data_migrated_issue155_functions |>
  dplyr::filter(
    .data[["naming_status"]] != "canonical_or_domain_verb"
  ) |>
  dplyr::transmute(
    finding_type = "issue155_function_naming",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = "#155",
    message = "Migrated Issue #155 functions must use approved verbs."
  )

data_issue155_test_mirror_findings <-
  data_migrated_issue155_functions |>
  dplyr::mutate(
    expected_test_path = .data[["active_path"]] |>
      stringr::str_replace(
        "^R/Functions/",
        "R/03_Supplementary_analyses/Testing/testthat/"
      ) |>
      stringr::str_replace(
        "/([^/]+)[.]R$",
        "/test-\\1.R"
      ),
    has_mirrored_test = base::file.exists(
      here::here(.data[["expected_test_path"]])
    )
  ) |>
  dplyr::filter(!.data[["has_mirrored_test"]]) |>
  dplyr::transmute(
    finding_type = "issue155_test_mirror",
    severity = "blocking",
    current_path = .data[["expected_test_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = "#155",
    message = "Each migrated Issue #155 function needs a mirrored test."
  )

data_issue155_nested_findings <-
  data_migrated_issue155_functions |>
  dplyr::filter(
    !base::is.na(.data[["nested_helpers"]]) &
      .data[["nested_helpers"]] != ""
  ) |>
  dplyr::transmute(
    finding_type = "issue155_nested_helper",
    severity = "blocking",
    current_path = .data[["active_path"]],
    symbol = .data[["nested_helpers"]],
    owning_issue = "#155",
    message = "Issue #155 functions must not retain named nested helpers."
  )

data_issue155_scripts <-
  data_scripts |>
  dplyr::filter(
    .data[["owning_issue"]] == "#155",
    .data[["migration_status"]] %in%
      base::c("migrated", "localized_to_presentation")
  )

data_issue155_script_placement_findings <-
  data_issue155_scripts |>
  dplyr::filter(
    !base::file.exists(here::here(.data[["intended_path"]])) |
      (
        .data[["current_path"]] != .data[["intended_path"]] &
          base::file.exists(here::here(.data[["current_path"]]))
      )
  ) |>
  dplyr::transmute(
    finding_type = "issue155_script_placement",
    severity = "blocking",
    current_path = .data[["intended_path"]],
    symbol = NA_character_,
    owning_issue = "#155",
    message = "Issue #155 scripts and tests must remain at approved paths."
  )

data_issue155_retired_script_findings <-
  data_scripts |>
  dplyr::filter(
    .data[["owning_issue"]] == "#155",
    .data[["migration_status"]] == "retired",
    base::file.exists(here::here(.data[["current_path"]]))
  ) |>
  dplyr::transmute(
    finding_type = "issue155_retired_script",
    severity = "blocking",
    current_path = .data[["current_path"]],
    symbol = NA_character_,
    owning_issue = "#155",
    message = "Retired Issue #155 scripts must not return."
  )

vec_issue155_scope_paths_current <-
  vec_function_paths_current[
    stringr::str_detect(
      vec_function_paths_current,
      stringr::str_c(
        "^R/Functions/(Pipeline/|Prediction/|Visualisation/|",
        "Data/Samples/|Data/Spatial/(Coordinates|Grid_catalogue)/|",
        "Data_access/(Files|Vegvault/Validation)/)"
      )
    ) |
      vec_function_paths_current %in%
        data_migrated_issue155_functions[["active_path"]]
  ]

data_issue155_inventory_findings <-
  tibble::tibble(
    finding_type = "issue155_missing_inventory_row",
    severity = "blocking",
    current_path = base::setdiff(
      vec_issue155_scope_paths_current,
      data_functions[["active_path"]] |>
        purrr::discard(base::is.na)
    ),
    symbol = NA_character_,
    owning_issue = "#155",
    message = "Every Issue #155-owned function needs a current inventory row."
  )

vec_issue155_forbidden_directories <-
  base::c(
    "R/Functions/Utility",
    "R/Functions/Presentation/IAVS"
  )

data_issue155_directory_findings <-
  tibble::tibble(
    finding_type = "issue155_forbidden_directory",
    severity = "blocking",
    current_path = vec_issue155_forbidden_directories[
      base::dir.exists(here::here(vec_issue155_forbidden_directories))
    ],
    symbol = NA_character_,
    owning_issue = "#155",
    message = stringr::str_c(
      "Utility and globally loaded IAVS directories must not return."
    )
  )

vec_issue155_active_documentation_names <-
  data_migrated_issue155_functions[["active_symbol"]] |>
  base::unique()

vec_issue155_required_documentation_paths <-
  base::c(
    base::file.path(
      "Documentation/Functions",
      base::as.vector(
        base::outer(
          vec_issue155_active_documentation_names,
          base::c(".html", ".txt"),
          base::paste0
        )
      )
    ),
    base::file.path(
      "Documentation/Website/Documentation/Functions",
      base::paste0(
        vec_issue155_active_documentation_names,
        ".qmd"
      )
    ),
    base::file.path(
      "docs/Documentation/Website/Documentation/Functions",
      base::paste0(
        vec_issue155_active_documentation_names,
        ".html"
      )
    )
  )

data_issue155_missing_documentation_findings <-
  tibble::tibble(
    finding_type = "issue155_missing_documentation",
    severity = "blocking",
    current_path = vec_issue155_required_documentation_paths[
      !base::file.exists(
        here::here(vec_issue155_required_documentation_paths)
      )
    ],
    symbol = NA_character_,
    owning_issue = "#155",
    message = "Active Issue #155 functions need current generated pages."
  )

vec_issue155_renamed_symbols <-
  data_migrated_issue155_functions |>
  dplyr::filter(
    .data[["function_name"]] != .data[["intended_function"]]
  ) |>
  dplyr::pull(.data[["function_name"]])

vec_issue155_stale_documentation_names <-
  base::unique(
    base::c(
      vec_issue155_inactive_symbols,
      vec_issue155_renamed_symbols
    )
  )

vec_issue155_stale_documentation_paths <-
  base::c(
    base::file.path(
      "Documentation/Functions",
      base::as.vector(
        base::outer(
          vec_issue155_stale_documentation_names,
          base::c(".html", ".pdf", ".txt"),
          base::paste0
        )
      )
    ),
    base::file.path(
      "Documentation/Website/Documentation/Functions",
      base::paste0(
        vec_issue155_stale_documentation_names,
        ".qmd"
      )
    ),
    base::file.path(
      "docs/Documentation/Website/Documentation/Functions",
      base::paste0(
        vec_issue155_stale_documentation_names,
        ".html"
      )
    )
  )

data_issue155_stale_documentation_findings <-
  tibble::tibble(
    finding_type = "issue155_stale_documentation",
    severity = "blocking",
    current_path = vec_issue155_stale_documentation_paths[
      base::file.exists(
        here::here(vec_issue155_stale_documentation_paths)
      )
    ],
    symbol = NA_character_,
    owning_issue = "#155",
    message = "Retired, renamed, and IAVS-local pages must not return."
  )

data_naming_findings <-
  data_functions |>
  dplyr::filter(.data[["naming_status"]] == "review_in_owning_issue") |>
  dplyr::mutate(
    finding_type = "function_naming",
    severity = "report_only",
    current_path = .data[["active_path"]],
    symbol = .data[["active_symbol"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_glue(
      "Review leading verb `{.data[['leading_verb']]}` against version 1."
    )
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

data_nested_findings <-
  data_functions |>
  dplyr::filter(
    .data[["nested_helper_disposition"]] == "review_in_owning_issue"
  ) |>
  dplyr::mutate(
    finding_type = "nested_named_helper",
    severity = "report_only",
    current_path = .data[["active_path"]],
    symbol = .data[["nested_helpers"]],
    owning_issue = .data[["owning_issue"]],
    message = "Extract or explicitly retain the named nested helper."
  ) |>
  dplyr::select(
    "finding_type",
    "severity",
    "current_path",
    "symbol",
    "owning_issue",
    "message"
  )

data_findings <-
  dplyr::bind_rows(
    data_findings,
    data_placement_findings,
    data_main_analysis_findings,
    data_data_processing_script_findings,
    data_abiotic_function_findings,
    data_abiotic_naming_findings,
    data_abiotic_test_findings,
    data_trait_function_findings,
    data_trait_naming_findings,
    data_trait_test_findings,
    data_spatial_function_findings,
    data_spatial_naming_findings,
    data_spatial_test_findings,
    data_community_function_findings,
    data_community_classification_naming_findings,
    data_community_quality_control_naming_findings,
    data_community_modern_record_naming_findings,
    data_community_proportion_naming_findings,
    data_community_data_shape_naming_findings,
    data_community_taxa_selection_naming_findings,
    data_community_test_findings,
    data_time_ages_function_findings,
    data_time_ages_naming_findings,
    data_time_ages_test_findings,
    data_time_interpolation_function_findings,
    data_time_interpolation_naming_findings,
    data_time_interpolation_retirement_findings,
    data_time_interpolation_test_findings,
    data_hmsc_retirement_path_findings,
    data_hmsc_retirement_symbol_findings,
    data_issue154_function_placement_findings,
    data_issue154_naming_findings,
    data_issue154_test_placement_findings,
    data_issue154_test_mirror_findings,
    data_issue154_internal_findings,
    data_issue154_dollar_access_findings,
    data_issue155_function_placement_findings,
    data_issue155_localization_findings,
    data_issue155_retirement_path_findings,
    data_issue155_inactive_symbol_findings,
    data_issue155_naming_findings,
    data_issue155_test_mirror_findings,
    data_issue155_nested_findings,
    data_issue155_script_placement_findings,
    data_issue155_retired_script_findings,
    data_issue155_inventory_findings,
    data_issue155_directory_findings,
    data_issue155_missing_documentation_findings,
    data_issue155_stale_documentation_findings,
    data_naming_findings,
    data_nested_findings
  ) |>
  dplyr::arrange(
    .data[["finding_type"]],
    .data[["current_path"]],
    .data[["symbol"]]
  )


#----------------------------------------------------------#
# 3. Write and report findings -----
#----------------------------------------------------------#

path_report_root <-
  here::here("Documentation/Reports/R_architecture")

base::dir.create(
  path = path_report_root,
  recursive = TRUE,
  showWarnings = FALSE
)

readr::write_csv(
  x = data_findings,
  file = base::file.path(
    path_report_root,
    "architecture_findings_v1.csv"
  )
)

data_finding_summary <-
  data_findings |>
  dplyr::count(.data[["finding_type"]], name = "n_findings")

data_blocking_findings <-
  data_findings |>
  dplyr::filter(.data[["severity"]] == "blocking")

if (
  base::nrow(data_blocking_findings) > 0L
) {
  cli::cli_abort(
    base::c(
      "x" = "R architecture validation found blocking placement errors.",
      "i" = stringr::str_c(
        data_blocking_findings[["current_path"]],
        collapse = ", "
      )
    )
  )
}

cli::cli_inform(
  base::c(
    "v" = "R architecture validation completed.",
    "i" = stringr::str_glue(
      "{base::nrow(data_findings)} findings across ",
      "{base::nrow(data_finding_summary)} types."
    ),
    "i" = stringr::str_c(
      "Main-analysis placement, migrated Abiotic placement/naming,",
      "migrated Community placement, and migrated Community",
      "classification, quality-control, modern-record, proportion,",
      "data-shape, and taxa-selection naming, plus migrated Time/Ages",
      "and Time/Interpolation placement, naming, and retirement are",
      "blocking; retired HMSC paths and symbols are blocking; Issue #154",
      "placement, naming, mirrored tests, internal classification, and",
      "dollar-access rules are blocking; Issue #155 ownership, naming,",
      "mirrored tests, retirement, localisation, and nested-helper rules",
      "plus generated-documentation freshness are blocking;",
      "migrated trait placement and naming are also",
      "blocking; migrated R/01 scripts and Spatial functions/tests are",
      "also blocking;",
      "unmigrated architecture contracts remain report-only.",
      sep = " "
    ),
    "i" = stringr::str_c(
      data_finding_summary[["finding_type"]],
      ": ",
      data_finding_summary[["n_findings"]],
      collapse = "; "
    )
  )
)
