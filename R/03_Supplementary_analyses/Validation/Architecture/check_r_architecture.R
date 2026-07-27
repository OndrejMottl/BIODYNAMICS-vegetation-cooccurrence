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
    active_path = dplyr::if_else(
      .data[["migration_status"]] == "migrated",
      .data[["intended_path"]],
      .data[["current_path"]]
    )
  )

data_functions <-
  readr::read_csv(
    file = base::file.path(
      path_inventory_root,
      "r_function_inventory_v1.csv"
    ),
    show_col_types = FALSE
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
    "R/Functions/Utility/Project_setup/load_project_functions.R"
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
    data_scripts[["active_path"]],
    vec_script_paths_current
  )

vec_uninventoried_functions <-
  base::setdiff(
    vec_function_paths_current,
    data_functions[["current_path"]]
  )

vec_missing_functions <-
  base::setdiff(
    data_functions[["current_path"]],
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

data_naming_findings <-
  data_functions |>
  dplyr::filter(.data[["naming_status"]] == "review_in_owning_issue") |>
  dplyr::transmute(
    finding_type = "function_naming",
    severity = "report_only",
    current_path = .data[["current_path"]],
    symbol = .data[["function_name"]],
    owning_issue = .data[["owning_issue"]],
    message = stringr::str_glue(
      "Review leading verb `{.data[['leading_verb']]}` against version 1."
    )
  )

data_nested_findings <-
  data_functions |>
  dplyr::filter(
    .data[["nested_helper_disposition"]] == "review_in_owning_issue"
  ) |>
  dplyr::transmute(
    finding_type = "nested_named_helper",
    severity = "report_only",
    current_path = .data[["current_path"]],
    symbol = .data[["nested_helpers"]],
    owning_issue = .data[["owning_issue"]],
    message = "Extract or explicitly retain the named nested helper."
  )

data_findings <-
  dplyr::bind_rows(
    data_findings,
    data_placement_findings,
    data_main_analysis_findings,
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
      "Main-analysis placement is blocking;",
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
