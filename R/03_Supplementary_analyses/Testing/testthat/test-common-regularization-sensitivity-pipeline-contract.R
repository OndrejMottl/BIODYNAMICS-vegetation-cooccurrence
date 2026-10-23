testthat::test_that(
  "common sensitivity excludes expected-infeasible unit stores",
  {
    withr::local_envvar(
      R_CONFIG_ACTIVE = "project_paleo_spatial_local"
    )
    data_fixture <-
      tidyr::crossing(
        tibble::tibble(
          tier_id = base::c("continental", "regional", "local",
            "local", "local"),
          scale_id = base::c("europe", "eu_r005", "eu_r005_l014",
            "am_r011_l002", "am_r001_l001")
        ),
        resolution_id = base::c("genus", "family", "functional_type")
      ) |>
      dplyr::mutate(
        analysis_id = "paleo_spatial",
        preparation_status = dplyr::if_else(
          .data[["scale_id"]] == "am_r001_l001",
          "expected_infeasible", "prepared"
        ),
        preparation_reason_code = dplyr::if_else(
          .data[["preparation_status"]] == "expected_infeasible",
          "insufficient_samples", NA_character_
        )
      )
    function_read_csv <-
      readr::read_csv
    testthat::local_mocked_bindings(
      read_csv = function(file, ...) {
        if (
          base::basename(file) == "calibration_unit_inventory.csv"
        ) {
          return(data_fixture)
        }
        return(function_read_csv(file = file, ...))
      },
      .package = "readr"
    )

    environment_pipeline <-
      base::new.env(parent = base::globalenv())

    base::source(
      here::here(
        "R/Pipelines/",
        "pipeline_sjsdm_common_regularization_sensitivity.R"
      ),
      local = environment_pipeline
    )

    data_context <-
      environment_pipeline[["data_spatial_profile_context"]]
    vec_local_scale_ids <-
      data_context |>
      dplyr::filter(
        .data[["profile_id"]] == "project_paleo_spatial_local"
      ) |>
      dplyr::pull("eligible_scale_ids") |>
      purrr::pluck(1L)

    testthat::expect_setequal(
      vec_local_scale_ids, base::c("eu_r005_l014", "am_r011_l002")
    )
    testthat::expect_contains(
      vec_local_scale_ids,
      "am_r011_l002"
    )
    testthat::expect_false(
      "am_r001_l001" %in% vec_local_scale_ids
    )
    data_fixture[["preparation_status"]][
      data_fixture[["scale_id"]] == "am_r011_l002"
    ] <-
      "pipeline_error"
    testthat::expect_error(
      base::source(
        file = here::here(
          "R/Pipelines/pipeline_sjsdm_common_regularization_sensitivity.R"
        ),
        local = base::new.env(parent = base::globalenv())
      ),
      "Preparation evidence is missing or unresolved"
    )
  }
)

testthat::test_that(
  "common sensitivity loads only inventory-eligible stores",
  {
    text_pipeline <-
      readr::read_file(
        here::here(
          "R/Pipelines/",
          "pipeline_sjsdm_common_regularization_sensitivity.R"
        )
      )

    testthat::expect_match(
      text_pipeline,
      '.x[["eligible_scale_ids"]][[1L]]',
      fixed = TRUE
    )
    testthat::expect_false(
      stringr::str_detect(
        text_pipeline,
        "fs::dir_ls\\("
      )
    )
  }
)

testthat::test_that(
  "common sensitivity respects partial-resolution production requests",
  {
    path_fixture <-
      withr::local_tempdir() |>
      fs::path_norm()
    vec_stores <-
      fs::path(path_fixture, base::c("full", "partial"), "unit_pipeline")
    fs::dir_create(path = vec_stores)
    data_requests <-
      tibble::tibble(
        source_store = base::c(base::rep(vec_stores[[1L]], 3L),
          vec_stores[[2L]]),
        target_name = stringr::str_c("list_sjsdm_cv_tuning_artifact_",
          base::c("genus", "family", "ft_modern", "ft_modern"))
      )
    readr::write_csv(x = data_requests,
      file = fs::path(path_fixture, "sjsdm_tier_unit_requests.csv"))
    list_calls <-
      base::parse(file = here::here(
        "R/Pipelines/pipeline_sjsdm_common_regularization_sensitivity.R"))
    list_target_calls <-
      rlang::call_args(list_calls[[base::length(list_calls)]])
    expr_target <-
      purrr::keep(list_target_calls, ~ base::identical(.x[["name"]],
        base::as.name("data_sjsdm_common_tuning_summaries")))[[1L]]
    environment_command <-
      base::new.env(parent = base::globalenv())
    environment_command[["data_sjsdm_common_profile_context"]] <-
      tibble::tibble(profile_id = "project_modern_spatial_local",
        target_store_root = path_fixture,
        eligible_scale_ids = base::list(base::c("full", "partial")))
    environment_command[["list_spatial_project"]] <-
      base::list(pipeline_name = "unit_pipeline",
        resolution_ids = base::c("genus", "family", "ft_modern"))
    flag_missing_eligible <- FALSE
    environment_command[["load_sjsdm_tuning_summaries"]] <- function(...) {
      return(load_sjsdm_tuning_summaries(...,
        read_target_function = function(name, store) {
          flag_requested <-
            base::any(data_requests[["source_store"]] == store &
              data_requests[["target_name"]] == name)
          if (
            !flag_requested || (flag_missing_eligible &&
              store == vec_stores[[2L]])
          ) {
            base::stop("target absent for this unit-resolution")
          }
          return(make_sjsdm_tuning_artifact_fixture(
            taxonomic_resolution = stringr::str_remove(name,
              "^list_sjsdm_cv_tuning_artifact_")))
        }))
    }
    data_summary <-
      testthat::expect_no_error(base::eval(expr = expr_target[["command"]],
        envir = environment_command))
    testthat::expect_equal(base::nrow(data_summary), 4L)
    testthat::expect_identical(data_summary |>
      dplyr::filter(.data[["source_store"]] == vec_stores[[2L]]) |>
      dplyr::pull("resolution_id"), "ft_modern")
    flag_missing_eligible <- TRUE
    testthat::expect_error(base::eval(expr = expr_target[["command"]],
      envir = environment_command), "Could not read every requested")
  }
)
