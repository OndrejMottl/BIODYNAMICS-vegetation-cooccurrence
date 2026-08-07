testthat::test_that(
  "profile selection allows active production profiles",
  {
    withr::local_envvar(R_CONFIG_ACTIVE = "project_cz_paleo")

    profile_metadata <-
      validate_config_profile_selection()

    testthat::expect_identical(
      profile_metadata[["role"]],
      "smoke"
    )
    testthat::expect_identical(
      profile_metadata[["status"]],
      "active"
    )
  }
)

testthat::test_that(
  "profile selection rejects base and special profiles by default",
  {
    withr::local_envvar(R_CONFIG_ACTIVE = "")

    testthat::expect_error(
      validate_config_profile_selection(
        vec_allowed_roles = "base"
      ),
      "base profile"
    )

    withr::local_envvar(
      R_CONFIG_ACTIVE = "project_cz_paleo_cv_reference"
    )

    testthat::expect_error(
      validate_config_profile_selection(),
      "not authorized"
    )

    withr::local_envvar(
      R_CONFIG_ACTIVE =
        "project_issue138_paleo_spatial_continental_europe_staged"
    )

    testthat::expect_error(
      validate_config_profile_selection(),
      "not authorized"
    )
  }
)

testthat::test_that(
  "dedicated runners can authorize frozen special profiles",
  {
    withr::local_envvar(
      R_CONFIG_ACTIVE = "project_cz_paleo_cv_reference"
    )

    testthat::expect_no_error(
      validate_config_profile_selection(
        vec_allowed_roles = "reference",
        vec_allowed_statuses = "frozen"
      )
    )

    withr::local_envvar(
      R_CONFIG_ACTIVE =
        "project_issue138_paleo_spatial_continental_europe_staged"
    )

    testthat::expect_no_error(
      validate_config_profile_selection(
        vec_allowed_roles = "one_time",
        vec_allowed_statuses = "frozen"
      )
    )
  }
)

testthat::test_that(
  "profile selection always rejects archived profiles",
  {
    file_config <-
      withr::local_tempfile(fileext = ".yml")

    base::writeLines(
      base::c(
        "default:",
        "  value: base",
        "  _profile:",
        "    role: base",
        "    status: active",
        "    selectable: false",
        "archived_profile:",
        "  value: archived",
        "  _profile:",
        "    role: reference",
        "    status: archived",
        "    selectable: false"
      ),
      con = file_config
    )

    withr::local_envvar(R_CONFIG_ACTIVE = "archived_profile")

    testthat::expect_error(
      validate_config_profile_selection(
        vec_allowed_roles = "reference",
        vec_allowed_statuses = "archived",
        file = file_config
      ),
      "archived"
    )
  }
)

testthat::test_that(
  "production profiles must be selectable",
  {
    file_config <-
      withr::local_tempfile(fileext = ".yml")

    base::writeLines(
      base::c(
        "default:",
        "  value: base",
        "  _profile:",
        "    role: base",
        "    status: active",
        "    selectable: false",
        "hidden_main:",
        "  value: hidden",
        "  _profile:",
        "    role: main",
        "    status: active",
        "    selectable: false"
      ),
      con = file_config
    )

    withr::local_envvar(R_CONFIG_ACTIVE = "hidden_main")

    testthat::expect_error(
      validate_config_profile_selection(file = file_config),
      "not selectable"
    )
  }
)

testthat::test_that(
  "special profiles name dedicated authorizing runners",
  {
    list_profiles <-
      yaml::read_yaml(
        here::here("config.yml"),
        handlers = base::list(
          expr = function(value) value
        )
      )

    data_special_profiles <-
      purrr::imap_dfr(
        list_profiles,
        function(profile, profile_id) {
          metadata <- profile[["_profile"]]

          if (
            !metadata[["role"]] %in%
              base::c("reference", "one_time")
          ) {
            return(NULL)
          }

          tibble::tibble(
            profile_id = profile_id,
            role = metadata[["role"]],
            runner = base::unlist(
              metadata[["supported_runners"]],
              use.names = FALSE
            )
          )
        }
      )

    purrr::pwalk(
      data_special_profiles,
      function(profile_id, role, runner) {
        testthat::expect_true(
          base::file.exists(here::here(runner)),
          info = profile_id
        )

        text_runner <-
          readr::read_file(here::here(runner))

        if (
          role == "reference"
        ) {
          testthat::expect_match(
            text_runner,
            'vec_allowed_profile_roles = "reference"',
            fixed = TRUE,
            info = profile_id
          )
          testthat::expect_match(
            text_runner,
            'vec_allowed_profile_statuses = "frozen"',
            fixed = TRUE,
            info = profile_id
          )
        } else {
          testthat::expect_match(
            text_runner,
            "run_issue138_representative_validation(",
            fixed = TRUE,
            info = profile_id
          )
        }
      }
    )
  }
)
