testthat::test_that(
  "Issue 156 migration ledger is unique and explicit",
  {
    path_inventory <-
      here::here(
        "Documentation/Implementation_inventories/R_architecture",
        "r_persisted_contract_migration_v1.csv"
      )

    data_inventory <-
      readr::read_csv(path_inventory, show_col_types = FALSE)

    testthat::expect_identical(base::anyDuplicated(data_inventory), 0L)
    testthat::expect_true(
      base::all(
        data_inventory[["migration_status"]] %in%
          base::c("approved_breaking_migration", "preserved")
      )
    )

    data_changed_targets <-
      data_inventory |>
      dplyr::filter(
        .data[["surface_type"]] == "target",
        .data[["current_name"]] != .data[["intended_name"]]
      )

    testthat::expect_equal(base::nrow(data_changed_targets), 35L)
    testthat::expect_false(
      base::any(
        data_changed_targets[["current_name"]] %in%
          base::c(
            "model_regularization_for_fit",
            "model_evaluation_cross_validated"
          )
      )
    )
  }
)

testthat::test_that(
  "Issue 156 manifests use intended target bases",
  {
    data_inventory <-
      readr::read_csv(
        here::here(
          "Documentation/Implementation_inventories/R_architecture",
          "r_persisted_contract_migration_v1.csv"
        ),
        show_col_types = FALSE
      ) |>
      dplyr::filter(
        .data[["surface_type"]] == "target",
        .data[["contract_scope"]] != "inactive_definition",
        .data[["current_name"]] != .data[["intended_name"]]
      )

    data_manifest_inventory <-
      readr::read_csv(
        here::here(
          "Documentation/Implementation_inventories/R_architecture",
          "r_manifest_contract_inventory_v1.csv"
        ),
        show_col_types = FALSE
      ) |>
      dplyr::filter(!base::is.na(.data[["target_name"]]))

    vec_manifest_targets <- data_manifest_inventory[["target_name"]]

    for (
      current_name in data_inventory[["current_name"]]
    ) {
      testthat::expect_false(
        base::any(
          vec_manifest_targets == current_name |
            base::startsWith(
              vec_manifest_targets,
              base::paste0(current_name, "_")
            )
        ),
        info = stringr::str_glue(
          "Legacy target name remains in active pipeline code: {current_name}"
        )
      )
    }

    for (
      intended_name in data_inventory[["intended_name"]]
    ) {
      testthat::expect_true(
        base::any(
          vec_manifest_targets == intended_name |
            base::startsWith(
              vec_manifest_targets,
              base::paste0(intended_name, "_")
            )
        ),
        info = stringr::str_glue(
          "Intended target name is missing: {intended_name}"
        )
      )
    }
  }
)

testthat::test_that(
  "Issue 156 inactive target definitions use intended names",
  {
    text_inactive_pipe <-
      base::readLines(
        here::here(
          "R/Pipelines/_pipes/pipe_segment_traits_ft_clustering.R"
        ),
        warn = FALSE,
        encoding = "UTF-8"
      ) |>
      stringr::str_c(collapse = "\n")

    data_inactive_targets <-
      readr::read_csv(
        here::here(
          "Documentation/Implementation_inventories/R_architecture",
          "r_persisted_contract_migration_v1.csv"
        ),
        show_col_types = FALSE
      ) |>
      dplyr::filter(.data[["contract_scope"]] == "inactive_definition")

    for (current_name in data_inactive_targets[["current_name"]]) {
      testthat::expect_false(
        stringr::str_detect(
          text_inactive_pipe,
          stringr::regex(stringr::str_c("\\b", current_name, "\\b"))
        ),
        info = stringr::str_glue(
          "Legacy inactive target remains: {current_name}"
        )
      )
    }

    for (intended_name in data_inactive_targets[["intended_name"]]) {
      testthat::expect_true(
        stringr::str_detect(
          text_inactive_pipe,
          stringr::regex(stringr::str_c("\\b", intended_name, "\\b"))
        ),
        info = stringr::str_glue(
          "Intended inactive target is missing: {intended_name}"
        )
      )
    }
  }
)
