#----------------------------------------------------------#
#
#
#                 Vegetation Co-occurrence
#
#              Validate model store freshness
#
#
#                       O. Mottl
#                         2026
#
#----------------------------------------------------------#
# Checks that every store feeding published model results is current, apart
#   from targets recorded in the model store freshness ledger. Builds nothing.
#
# Arguments (all optional, repeatable where noted):
#   --profile=<profile_id>      restrict to profiles (repeatable)
#   --store-kind=<kind>         spatial_unit, temporal, tier_tuning,
#                               sensitivity (repeatable)
#   --store=<relative path>     restrict to stores (repeatable)
#   --store-root=<path>         resolve stores below another root, e.g. copies
#   --table=<path>              published table to check for provenance
#                               (repeatable)
#   --table-availability=<col>  availability column of the checked tables
#   --ledger=<path>             alternative ledger file, e.g. a draft


#----------------------------------------------------------#
# 0. Setup -----
#----------------------------------------------------------#

# The light worker setup is enough for inspection and is inherited by every
#   pipeline definition sourced below, which keeps each store check short.
base::Sys.setenv(
  BIODYNAMICS_PREPROCESSING_WORKER = "true"
)

base::source(
  file = "R/___setup_project___.R"
)

vec_arguments <-
  base::commandArgs(trailingOnly = TRUE)

list_argument_values <-
  base::c(
    "profile",
    "store-kind",
    "store",
    "store-root",
    "table",
    "table-availability",
    "ledger"
  ) |>
  rlang::set_names() |>
  purrr::map(
    .f = ~ {
      argument_prefix <-
        stringr::str_c("--", .x, "=")
      vec_arguments[
        stringr::str_starts(vec_arguments, stringr::fixed(argument_prefix))
      ] |>
        stringr::str_remove(stringr::fixed(argument_prefix))
    }
  )

vec_profile_ids <-
  list_argument_values[["profile"]]
vec_store_kinds <-
  list_argument_values[["store-kind"]]
vec_store_paths <-
  list_argument_values[["store"]]
vec_store_roots <-
  list_argument_values[["store-root"]]
vec_table_paths <-
  list_argument_values[["table"]]
vec_table_availability <-
  list_argument_values[["table-availability"]]
vec_ledger_files <-
  list_argument_values[["ledger"]]

path_store_root <-
  if (
    base::length(vec_store_roots) == 0L
  ) {
    here::here()
  } else {
    vec_store_roots[[1L]]
  }

path_output <-
  here::here("Data/Temp/Model_store_validation")

base::dir.create(
  path = path_output,
  showWarnings = FALSE,
  recursive = TRUE
)


#----------------------------------------------------------#
# 1. Select stores -----
#----------------------------------------------------------#

data_store_index <-
  load_model_store_index(
    vec_profile_ids = if (
      base::length(vec_profile_ids) == 0L
    ) {
      NULL
    } else {
      vec_profile_ids
    },
    path_store_root = path_store_root
  )

data_store_selected <-
  data_store_index |>
  dplyr::filter(
    base::length(vec_store_kinds) == 0L |
      .data[["store_kind"]] %in% vec_store_kinds,
    base::length(vec_store_paths) == 0L |
      .data[["store_path_relative"]] %in% vec_store_paths
  )

if (
  base::nrow(data_store_selected) == 0L
) {
  cli::cli_abort("No model store matches the selection.")
}

vec_store_paths_unknown <-
  base::setdiff(vec_store_paths, data_store_index[["store_path_relative"]])

if (
  base::length(vec_store_paths_unknown) > 0L
) {
  cli::cli_abort(
    "Not an indexed model store: {.file {vec_store_paths_unknown}}."
  )
}

cli::cli_inform(
  "Inspecting {base::nrow(data_store_selected)} store(s)."
)


#----------------------------------------------------------#
# 2. Diagnose stores -----
#----------------------------------------------------------#

# Pipeline definitions do not depend on the unit store, so the manifest and
#   network are read once per pipeline and profile.
environment_cache <-
  base::new.env()

data_findings <-
  data_store_selected |>
  dplyr::mutate(index_store = dplyr::row_number()) |>
  purrr::pmap(
    .f = function(index_store, store_kind, store_path, store_path_relative,
                  pipeline_script, profile_id, store_exists, ...) {
      cli::cli_inform(
        stringr::str_c(
          "[{index_store}/{base::nrow(data_store_selected)}] ",
          "{store_path_relative}"
        )
      )
      cache_key <-
        stringr::str_c(pipeline_script, "|", profile_id)

      res_store <-
        base::tryCatch(
          expr = {
            if (
              store_exists &&
                !base::exists(cache_key, envir = environment_cache)
            ) {
              withr::with_envvar(
                new = base::c(R_CONFIG_ACTIVE = profile_id),
                code = {
                  data_manifest <-
                    targets::tar_manifest(
                      script = pipeline_script,
                      fields = tidyselect::all_of(
                        base::c("name", "command", "cue_mode")
                      ),
                      callr_function = NULL
                    )
                  list_network <-
                    targets::tar_network(
                      script = pipeline_script,
                      store = store_path,
                      targets_only = TRUE,
                      outdated = FALSE,
                      callr_function = NULL
                    )
                }
              )
              base::assign(
                x = cache_key,
                value = base::list(
                  data_manifest = data_manifest,
                  data_edges = list_network[["edges"]]
                ),
                envir = environment_cache
              )
            }
            list_cached <-
              base::get0(cache_key, envir = environment_cache)

            diagnose_model_store_freshness(
              pipeline_script = pipeline_script,
              store_path = store_path,
              profile_id = profile_id,
              data_manifest = list_cached[["data_manifest"]],
              data_edges = list_cached[["data_edges"]]
            )
          },
          error = function(error_condition) {
            tibble::tibble(
              store_path = store_path,
              target_name = NA_character_,
              finding_type = "diagnosis_failed",
              flag_blocking = TRUE,
              detail = base::conditionMessage(error_condition)
            )
          }
        )

      # Most grid units have no spatial store, so a missing spatial store is
      #   informational. A missing temporal, tier-tuning or sensitivity
      #   store, or a store named with --store, blocks.
      flag_missing_blocks <-
        store_kind != "spatial_unit" ||
          store_path_relative %in% vec_store_paths

      res_store |>
        dplyr::mutate(
          flag_blocking = .data[["flag_blocking"]] |
            (
              .data[["finding_type"]] == "store_missing" &
                flag_missing_blocks
            ),
          store_path_relative = store_path_relative,
          profile_id = profile_id,
          .before = "target_name"
        )
    }
  ) |>
  purrr::list_rbind()


#----------------------------------------------------------#
# 3. Apply the ledger and report -----
#----------------------------------------------------------#

data_findings_resolved <-
  apply_model_store_freshness_ledger(
    data_findings = data_findings,
    data_ledger = if (
      base::length(vec_ledger_files) == 0L
    ) {
      load_model_store_freshness_ledger()
    } else {
      load_model_store_freshness_ledger(file = vec_ledger_files[[1L]])
    },
    vec_inspected_store_paths = data_store_selected[["store_path_relative"]]
  )

file_findings <-
  base::file.path(
    path_output,
    stringr::str_glue(
      "model_store_freshness_",
      "{base::format(base::Sys.time(), '%Y%m%d_%H%M%S')}.csv"
    )
  )

readr::write_csv(
  x = data_findings_resolved,
  file = file_findings
)

data_findings_resolved |>
  dplyr::count(
    .data[["store_path_relative"]],
    .data[["finding_type"]],
    .data[["resolution_status"]],
    name = "n_targets"
  ) |>
  base::print(n = Inf)

cli::cli_inform("Findings written to {file_findings}.")


#----------------------------------------------------------#
# 4. Check published tables -----
#----------------------------------------------------------#

purrr::walk(
  .x = vec_table_paths,
  .f = ~ validate_model_table_provenance(
    data_table = readr::read_csv(file = .x, show_col_types = FALSE),
    availability_column = if (
      base::length(vec_table_availability) == 0L
    ) {
      NULL
    } else {
      vec_table_availability[[1L]]
    },
    table_label = base::basename(.x)
  )
)

validate_model_store_freshness(data_findings_resolved)

n_stores_missing <-
  base::sum(data_findings_resolved[["finding_type"]] == "store_missing")

cli::cli_alert_success(
  stringr::str_c(
    "All inspected model stores are current ",
    "({n_stores_missing} spatial unit store(s) not built)."
  )
)
