#' @title Build R Architecture Dependency Map
#' @description
#' Builds deterministic Markdown describing repository R ownership,
#' pipeline/profile/store relationships, persisted contracts, and exceptions.
#' @param data_scripts
#' Script-path inventory data frame.
#' @param data_functions
#' Function inventory data frame.
#' @param data_contracts
#' Persisted-contract inventory data frame.
#' @param data_manifests
#' Manifest-derived profile and target inventory data frame.
#' @param data_exceptions
#' Maintained architecture-exception ledger.
#' @return
#' Character vector containing the architecture map Markdown.
#' @examples
#' build_r_architecture_dependency_map(
#'   data_scripts = tibble::tibble(
#'     classification = "main_analysis",
#'     migration_status = "migrated"
#'   ),
#'   data_functions = tibble::tibble(
#'     current_path = "R/Functions/example.R",
#'     intended_path = "R/Functions/example.R",
#'     migration_status = "baseline_recorded",
#'     callers = "R/Pipelines/_pipes/pipe_segment_example.R"
#'   ),
#'   data_contracts = tibble::tibble(
#'     contract_type = "literal_target",
#'     contract_scope = "persisted_internal"
#'   ),
#'   data_manifests = tibble::tibble(
#'     profile_id = "example",
#'     profile_role = "smoke",
#'     pipeline_id = "example",
#'     pipeline_script = "R/Pipelines/example.R",
#'     target_store = "Data/targets/example",
#'     manifest_target_count = 1L
#'   ),
#'   data_exceptions = tibble::tibble(
#'     exception_id = character(),
#'     owner_issue = character(),
#'     expiry_issue = character()
#'   )
#' )
#' @export
build_r_architecture_dependency_map <- function(
    data_scripts,
    data_functions,
    data_contracts,
    data_manifests,
    data_exceptions) {
  assertthat::assert_that(
    base::is.data.frame(data_scripts),
    base::is.data.frame(data_functions),
    base::is.data.frame(data_contracts),
    base::is.data.frame(data_manifests),
    base::is.data.frame(data_exceptions),
    msg = "Architecture map inputs must be data frames."
  )

  data_script_summary <-
    data_scripts |>
    dplyr::filter(.data[["migration_status"]] != "retired") |>
    dplyr::count(
      .data[["classification"]],
      name = "script_count",
      sort = TRUE
    ) |>
    dplyr::arrange(.data[["classification"]])

  vec_script_rows <-
    data_script_summary |>
    purrr::pmap_chr(
      .f = ~ stringr::str_glue("| {..1} | {..2} |")
    )

  data_active_functions <-
    data_functions |>
    dplyr::mutate(
      active_path = dplyr::case_when(
        .data[["migration_status"]] == "migrated" ~
          .data[["intended_path"]],
        .data[["migration_status"]] %in%
          base::c(
            "retired",
            "retired_to_legacy",
            "localized_to_presentation"
          ) ~ NA_character_,
        TRUE ~ .data[["current_path"]]
      )
    ) |>
    dplyr::filter(!base::is.na(.data[["active_path"]])) |>
    dplyr::mutate(
      capability = .data[["active_path"]] |>
        stringr::str_remove("^R/Functions/") |>
        stringr::str_extract("^[^/]+(?:/[^/]+)?")
    )

  data_function_summary <-
    data_active_functions |>
    dplyr::count(
      .data[["capability"]],
      name = "function_count"
    ) |>
    dplyr::arrange(.data[["capability"]])

  vec_function_rows <-
    data_function_summary |>
    purrr::pmap_chr(
      .f = ~ stringr::str_glue("| {..1} | {..2} |")
    )

  data_pipe_dependencies <-
    data_active_functions |>
    dplyr::filter(
      !base::is.na(.data[["callers"]]),
      .data[["callers"]] != ""
    ) |>
    tidyr::separate_longer_delim(
      cols = "callers",
      delim = ";"
    ) |>
    dplyr::filter(
      stringr::str_starts(
        .data[["callers"]],
        "R/Pipelines/_pipes/"
      )
    ) |>
    dplyr::group_by(
      .data[["callers"]],
      .data[["capability"]]
    ) |>
    dplyr::summarise(
      function_count = dplyr::n_distinct(.data[["active_path"]]),
      .groups = "drop"
    ) |>
    dplyr::arrange(
      .data[["callers"]],
      .data[["capability"]]
    )

  vec_pipe_dependency_rows <-
    data_pipe_dependencies |>
    purrr::pmap_chr(
      .f = ~ stringr::str_glue("| `{..1}` | {..2} | {..3} |")
    )

  data_profile_summary <-
    data_manifests |>
    dplyr::select(
      "profile_id",
      "profile_role",
      "pipeline_id",
      "pipeline_script",
      "target_store",
      "manifest_target_count"
    ) |>
    dplyr::distinct() |>
    dplyr::arrange(.data[["profile_id"]]) |>
    dplyr::mutate(
      pipeline_script = dplyr::coalesce(
        .data[["pipeline_script"]],
        "Profile-only"
      ),
      target_store = dplyr::coalesce(
        .data[["target_store"]],
        "Not applicable"
      )
    )

  vec_profile_rows <-
    data_profile_summary |>
    purrr::pmap_chr(
      .f = ~ stringr::str_glue(
        "| {..1} | {..2} | {..3} | `{..4}` | `{..5}` | {..6} |"
      )
    )

  data_contract_summary <-
    data_contracts |>
    dplyr::count(
      .data[["contract_type"]],
      .data[["contract_scope"]],
      name = "contract_count"
    ) |>
    dplyr::arrange(
      .data[["contract_type"]],
      .data[["contract_scope"]]
    )

  vec_contract_rows <-
    data_contract_summary |>
    purrr::pmap_chr(
      .f = ~ stringr::str_glue("| {..1} | {..2} | {..3} |")
    )

  data_exception_summary <-
    data_exceptions |>
    dplyr::count(
      .data[["owner_issue"]],
      .data[["expiry_issue"]],
      name = "exception_count"
    ) |>
    dplyr::arrange(
      .data[["owner_issue"]],
      .data[["expiry_issue"]]
    )

  vec_exception_rows <-
    data_exception_summary |>
    purrr::pmap_chr(
      .f = ~ stringr::str_glue("| {..1} | {..2} | {..3} |")
    )

  res_markdown <-
    base::c(
      "# R architecture and dependency map",
      "",
      stringr::str_c(
        "This maintained map is generated from the versioned script, ",
        "function, persisted-contract, manifest, and ",
        "architecture-exception inventories. Do not edit generated ",
        "tables manually."
      ),
      "",
      "## Repository architecture",
      "",
      "```mermaid",
      "flowchart TD",
      "  Analyses[R/02_Main_analyses] --> Runners[Production runners]",
      "  Runners --> Profiles[Configuration profiles]",
      "  Profiles --> Pipelines[R/Pipelines]",
      "  Pipelines --> Pipes[R/Pipelines/_pipes]",
      "  Pipes --> Functions[R/Functions capabilities]",
      "  Pipelines --> Stores[Isolated target stores]",
      "  Supplementary[R/03_Supplementary_analyses] --> Validation",
      "  Validation --> Pipelines",
      "```",
      "",
      stringr::str_c(
        "- `R/02_Main_analyses/` owns stable production-facing ",
        "orchestration, scientific synthesis, and final visualisation."
      ),
      stringr::str_c(
        "- `R/03_Supplementary_analyses/` owns diagnostics, validation, ",
        "tests, sensitivity work, and one-time provenance."
      ),
      "- `R/Functions/` owns reusable one-function-per-file capabilities.",
      "- `R/Pipelines/` owns target graphs and reusable pipe segments.",
      "",
      "## Script lifecycle",
      "",
      "| Classification | Active inventory rows |",
      "|---|---:|",
      vec_script_rows,
      "",
      "## Function capabilities",
      "",
      "| Capability | Active functions |",
      "|---|---:|",
      vec_function_rows,
      "",
      "## Pipe-segment capability dependencies",
      "",
      "| Pipe segment | Function capability | Active functions |",
      "|---|---|---:|",
      vec_pipe_dependency_rows,
      "",
      "## Profile, pipeline, and store map",
      "",
      stringr::str_c(
        "| Profile | Role | Pipeline ID | Pipeline script | Target store | ",
        "Manifest targets |"
      ),
      "|---|---|---|---|---|---:|",
      vec_profile_rows,
      "",
      "## Persisted contracts",
      "",
      "| Contract type | Scope | Contracts |",
      "|---|---|---:|",
      vec_contract_rows,
      "",
      "## Architecture exceptions",
      "",
      "| Owner | Expiry issue | Exact exceptions |",
      "|---|---|---:|",
      vec_exception_rows,
      "",
      stringr::str_c(
        "Exceptions match one exact current finding. They become invalid ",
        "when their expiry issue closes and must then be removed or ",
        "replaced by an approved canonical decision."
      ),
      "",
      "## Validation and generated artifacts",
      "",
      "```mermaid",
      "flowchart LR",
      "  Sources[Active source tree] --> Inventory[Versioned inventories]",
      "  Inventory --> Checker[Blocking architecture checker]",
      "  Exceptions[Exact exception ledger] --> Checker",
      "  Checker --> Findings[Current findings report]",
      "  Inventory --> Map[This dependency map]",
      "  Functions[Function sources] --> Docs[Function documentation]",
      "  Tests[Test suite] --> Coverage[Coverage report]",
      "```",
      "",
      "Run the maintained entry points from the repository root:",
      "",
      "```powershell",
      stringr::str_c(
        "Rscript R/03_Supplementary_analyses/Validation/Architecture/",
        "generate_r_architecture_inventories.R"
      ),
      stringr::str_c(
        "Rscript R/03_Supplementary_analyses/Validation/Architecture/",
        "generate_persisted_contract_manifest_inventory.R"
      ),
      stringr::str_c(
        "Rscript R/03_Supplementary_analyses/Validation/Architecture/",
        "check_r_architecture.R"
      ),
      "Rscript R/03_Supplementary_analyses/Testing/Run_tests.R",
      "Rscript R/03_Supplementary_analyses/Testing/Smoke/run_cz_pipelines.R",
      "```"
    )

  return(res_markdown)
}
