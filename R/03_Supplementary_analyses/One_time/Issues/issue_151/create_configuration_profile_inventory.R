#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#          Create configuration profile inventory
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#

base::Sys.setenv(
  BIODYNAMICS_PREPROCESSING_WORKER = "true"
)

base::source(
  file = "R/___setup_project___.R"
)

path_inventory_root <-
  withr::local_tempdir()

data_profile_inventory <-
  run_configuration_generation(
    path_destination_root = path_inventory_root
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

path_repository_root <-
  here::here() |>
  base::normalizePath(
    winslash = "/",
    mustWork = TRUE
  )

vec_r_relative_paths <-
  base::substring(
    text = vec_r_paths,
    first = base::nchar(path_repository_root) + 2L
  )

list_r_lines <-
  base::lapply(
    X = vec_r_paths,
    FUN = base::readLines,
    warn = FALSE,
    encoding = "UTF-8"
  )

vec_active_consumers <-
  base::character(base::nrow(data_profile_inventory))

vec_test_consumers <-
  base::character(base::nrow(data_profile_inventory))

for (
  index_profile in base::seq_len(
    base::nrow(data_profile_inventory)
  )
) {
  profile_id <-
    data_profile_inventory[["profile_id"]][[index_profile]]

  vec_double_quote_pattern <-
    paste0(
      "\"",
      profile_id,
      "\""
    )

  vec_single_quote_pattern <-
    paste0(
      "'",
      profile_id,
      "'"
    )

  vec_is_consumer <-
    base::vapply(
      X = list_r_lines,
      FUN = function(vec_lines) {
        base::any(
          base::grepl(
            pattern = vec_double_quote_pattern,
            x = vec_lines,
            fixed = TRUE
          )
        ) ||
          base::any(
            base::grepl(
              pattern = vec_single_quote_pattern,
              x = vec_lines,
              fixed = TRUE
            )
          )
      },
      FUN.VALUE = base::logical(1L)
    )

  vec_consumer_paths <-
    vec_r_relative_paths[vec_is_consumer]

  vec_consumer_paths <-
    vec_consumer_paths[
      !stringr::str_detect(
        string = vec_consumer_paths,
        pattern = paste0(
          "One_time/Issues/issue_151/",
          "(bootstrap|create)_configuration"
        )
      )
    ]

  vec_profile_test_consumers <-
    vec_consumer_paths[
      stringr::str_detect(
        string = vec_consumer_paths,
        pattern = "/Testing/"
      )
    ]

  vec_profile_active_consumers <-
    base::setdiff(
      x = vec_consumer_paths,
      y = vec_profile_test_consumers
    )

  vec_active_consumers[[index_profile]] <-
    stringr::str_c(
      vec_profile_active_consumers,
      collapse = ";"
    )

  vec_test_consumers[[index_profile]] <-
    stringr::str_c(
      vec_profile_test_consumers,
      collapse = ";"
    )
}

data_profile_inventory <-
  data_profile_inventory |>
  dplyr::transmute(
    profile_id = .data[["profile_id"]],
    current_source = "config.yml",
    target_fragment = .data[["source_fragment"]],
    role = .data[["role"]],
    status = .data[["status"]],
    selectable = .data[["selectable"]],
    pipeline = .data[["pipeline"]],
    inheritance_parent = .data[["inherits"]],
    inheritance_depth = .data[["inheritance_depth"]],
    target_store = .data[["target_store"]],
    active_consumers = vec_active_consumers,
    test_consumers = vec_test_consumers,
    supported_runners = .data[["supported_runners"]],
    related_issue = .data[["related_issue"]],
    retirement = .data[["retirement"]],
    contract_status = dplyr::if_else(
      .data[["profile_id"]] == "project_traits_reference",
      "internal_reference",
      "frozen_issue_141"
    ),
    semantic_hash = .data[["semantic_hash"]],
    owning_issue = "#151",
    migration_status = "modular_source_created"
  )

path_inventory <-
  here::here(
    "Documentation/Implementation_inventories/Configuration",
    "configuration_profile_inventory_v1.csv"
  )

readr::write_csv(
  x = data_profile_inventory,
  file = path_inventory
)

cli::cli_inform(
  base::c(
    "v" = "Configuration profile inventory created.",
    "i" = stringr::str_glue(
      "{base::nrow(data_profile_inventory)} profiles recorded."
    )
  )
)
