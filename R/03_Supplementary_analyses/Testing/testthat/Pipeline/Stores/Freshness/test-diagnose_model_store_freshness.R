build_test_manifest <- function() {
  tibble::tibble(
    name = base::c(
      "config_input",
      "data_raw",
      "mod_fit",
      "list_partition",
      "data_progress"
    ),
    command = base::c(
      "1L",
      "stop('do not execute')",
      "data_raw",
      "mod_fit",
      "Sys.time()"
    ),
    cue_mode = base::c("always", "thorough", "thorough", "thorough", "always")
  )
}

build_test_edges <- function() {
  tibble::tibble(
    from = base::c("config_input", "data_raw", "mod_fit"),
    to = base::c("data_raw", "mod_fit", "list_partition")
  )
}

capture_selected_names <- function(names, vec_all) {
  base::names(
    tidyselect::eval_select(
      expr = names,
      data = stats::setNames(base::seq_along(vec_all), vec_all)
    )
  )
}

testthat::test_that(
  "diagnose_model_store_freshness() reports a missing store",
  {
    res <-
      diagnose_model_store_freshness(
        pipeline_script = "pipeline.R",
        store_path = base::file.path(base::tempdir(), "no_such_store"),
        profile_id = "profile"
      )

    testthat::expect_equal(res[["finding_type"]], "store_missing")
    testthat::expect_false(res[["flag_blocking"]])
  }
)

testthat::test_that(
  "diagnose_model_store_freshness() validates its inputs",
  {
    testthat::expect_error(
      diagnose_model_store_freshness(
        pipeline_script = 1,
        store_path = "store",
        profile_id = "profile"
      ),
      "pipeline script"
    )
    testthat::expect_error(
      diagnose_model_store_freshness(
        pipeline_script = "pipeline.R",
        store_path = base::tempdir(),
        profile_id = "profile",
        data_manifest = tibble::tibble(name = "a"),
        data_edges = build_test_edges()
      ),
      "required columns"
    )
  }
)

testthat::test_that(
  "diagnose_model_store_freshness() returns no blocking finding when current",
  {
    data_manifest <-
      build_test_manifest()
    vec_inspected <- NULL

    res <-
      diagnose_model_store_freshness(
        pipeline_script = "pipeline.R",
        store_path = base::tempdir(),
        profile_id = "profile",
        data_manifest = data_manifest,
        data_edges = build_test_edges(),
        outdated_function = function(names, ...) {
          vec_inspected <<-
            capture_selected_names(
              names = rlang::enquo(names),
              vec_all = data_manifest[["name"]]
            )
          base::character()
        },
        read_target_function = function(name, ...) 1L,
        load_metadata_function = function(...) {
          tibble::tibble(
            name = data_manifest[["name"]],
            error = NA_character_
          )
        }
      )

    testthat::expect_setequal(
      vec_inspected,
      base::c("data_raw", "mod_fit", "list_partition")
    )
    testthat::expect_false(base::any(res[["flag_blocking"]]))
    testthat::expect_equal(
      res[["target_name"]],
      "data_progress"
    )
    testthat::expect_equal(
      res[["finding_type"]],
      "always_cued_not_evaluated"
    )
  }
)

testthat::test_that(
  "diagnose_model_store_freshness() reports outdated and unbuilt targets",
  {
    data_manifest <-
      build_test_manifest()

    res <-
      diagnose_model_store_freshness(
        pipeline_script = "pipeline.R",
        store_path = base::tempdir(),
        profile_id = "profile",
        data_manifest = data_manifest,
        data_edges = build_test_edges(),
        outdated_function = function(...) "mod_fit",
        read_target_function = function(name, ...) 1L,
        load_metadata_function = function(...) {
          tibble::tibble(
            name = base::setdiff(data_manifest[["name"]], "list_partition"),
            error = NA_character_
          )
        }
      )

    testthat::expect_equal(
      res[["target_name"]][res[["finding_type"]] == "outdated"],
      "mod_fit"
    )
    testthat::expect_equal(
      res[["target_name"]][res[["finding_type"]] == "missing_metadata"],
      "list_partition"
    )
  }
)

testthat::test_that(
  "diagnose_model_store_freshness() propagates a changed configuration",
  {
    data_manifest <-
      build_test_manifest()

    res <-
      diagnose_model_store_freshness(
        pipeline_script = "pipeline.R",
        store_path = base::tempdir(),
        profile_id = "profile",
        data_manifest = data_manifest,
        data_edges = build_test_edges(),
        outdated_function = function(...) base::character(),
        read_target_function = function(name, ...) 2L,
        load_metadata_function = function(...) {
          tibble::tibble(
            name = data_manifest[["name"]],
            error = NA_character_
          )
        }
      )

    testthat::expect_equal(
      res[["target_name"]][res[["finding_type"]] == "config_changed"],
      "config_input"
    )
    testthat::expect_setequal(
      res[["target_name"]][res[["finding_type"]] == "outdated"],
      base::c("data_raw", "mod_fit", "list_partition")
    )
  }
)

testthat::test_that(
  "diagnose_model_store_freshness() reports a swapped VegVault release",
  {
    path_vault <-
      withr::local_tempfile(fileext = ".sqlite")
    path_vault_rebuilt <-
      withr::local_tempfile(fileext = ".sqlite")
    path_vault_previous <-
      withr::local_tempfile(fileext = ".sqlite")

    list_version_tables <-
      base::list(
        tibble::tibble(
          id = 5L,
          version = "2.0.0",
          git_commit = "f19d588",
          manifest_sha256 = "hash_accepted"
        ),
        tibble::tibble(
          id = 5L,
          version = "2.0.0",
          git_commit = "f19d588",
          manifest_sha256 = "hash_rebuilt"
        ),
        tibble::tibble(
          id = 4L,
          version = "1.0.0"
        )
      )

    purrr::walk2(
      .x = base::c(path_vault, path_vault_rebuilt, path_vault_previous),
      .y = list_version_tables,
      .f = ~ {
        connection_vault <-
          DBI::dbConnect(
            drv = RSQLite::SQLite(),
            dbname = .x
          )
        DBI::dbWriteTable(
          conn = connection_vault,
          name = "version_control",
          value = .y
        )
        DBI::dbDisconnect(connection_vault)
      }
    )

    command_release <-
      stringr::str_glue(
        "load_vegvault_database_version(",
        "path_to_vegvault = {base::deparse(path_vault)}, ",
        "vegvault_version = \"2.0.0\")"
      ) |>
      base::as.character()

    data_manifest <-
      tibble::tibble(
        name = base::c("config_vegvault_release", "data_vegvault_extracted"),
        command = base::c(command_release, "config_vegvault_release"),
        cue_mode = base::c("always", "thorough")
      )

    data_edges <-
      tibble::tibble(
        from = "config_vegvault_release",
        to = "data_vegvault_extracted"
      )

    data_release_cached <-
      load_vegvault_database_version(
        path_to_vegvault = path_vault,
        vegvault_version = "2.0.0"
      )

    list_arguments <-
      base::list(
        pipeline_script = "pipeline.R",
        store_path = base::tempdir(),
        profile_id = "profile",
        data_manifest = data_manifest,
        data_edges = data_edges,
        outdated_function = function(...) base::character(),
        read_target_function = function(name, ...) data_release_cached,
        load_metadata_function = function(...) {
          tibble::tibble(
            name = data_manifest[["name"]],
            error = NA_character_
          )
        }
      )

    res_current <-
      rlang::exec(.fn = diagnose_model_store_freshness, !!!list_arguments)

    base::file.copy(
      from = path_vault_rebuilt,
      to = path_vault,
      overwrite = TRUE
    )

    res_rebuilt <-
      rlang::exec(.fn = diagnose_model_store_freshness, !!!list_arguments)

    base::file.copy(
      from = path_vault_previous,
      to = path_vault,
      overwrite = TRUE
    )

    res_previous <-
      rlang::exec(.fn = diagnose_model_store_freshness, !!!list_arguments)

    testthat::expect_s3_class(data_release_cached, "tbl_df")
    testthat::expect_false(
      "config_changed" %in% res_current[["finding_type"]]
    )
    testthat::expect_equal(
      res_rebuilt[["target_name"]][
        res_rebuilt[["finding_type"]] == "config_changed"
      ],
      "config_vegvault_release"
    )
    testthat::expect_equal(
      res_rebuilt[["target_name"]][
        res_rebuilt[["finding_type"]] == "outdated"
      ],
      "data_vegvault_extracted"
    )
    testthat::expect_equal(
      res_previous[["target_name"]][
        res_previous[["finding_type"]] == "config_changed"
      ],
      "config_vegvault_release"
    )
  }
)

testthat::test_that(
  "diagnose_model_store_freshness() classifies cached errors",
  {
    data_manifest <-
      build_test_manifest()

    res <-
      diagnose_model_store_freshness(
        pipeline_script = "pipeline.R",
        store_path = base::tempdir(),
        profile_id = "profile",
        data_manifest = data_manifest,
        data_edges = build_test_edges(),
        outdated_function = function(...) base::character(),
        read_target_function = function(name, ...) 1L,
        load_metadata_function = function(...) {
          tibble::tibble(
            name = base::c("config_input", "data_raw", "mod_fit"),
            error = base::c(NA_character_, NA_character_, "boom")
          )
        }
      )

    testthat::expect_equal(
      res[["target_name"]][res[["finding_type"]] == "errored_unexpected"],
      "mod_fit"
    )
    # The skipped downstream target is attributed to the error.
    testthat::expect_false(
      "list_partition" %in%
        res[["target_name"]][res[["finding_type"]] == "missing_metadata"]
    )
  }
)
