make_configuration_test_fixture <- function() {
  path_fixture_root <-
    base::tempfile(pattern = "configuration-test-")

  base::dir.create(
    path = path_fixture_root,
    recursive = TRUE
  )

  withr::defer(
    base::unlink(
      x = path_fixture_root,
      recursive = TRUE,
      force = TRUE
    ),
    envir = base::parent.frame()
  )

  fs::dir_copy(
    path = here::here("Configuration"),
    new_path = base::file.path(
      path_fixture_root,
      "Configuration"
    )
  )

  path_reference_directory <-
    base::file.path(
      path_fixture_root,
      "Documentation",
      "Implementation_inventories",
      "Configuration"
    )

  fs::dir_create(path_reference_directory)
  fs::file_copy(
    path = here::here(
      "Documentation/Implementation_inventories/Configuration",
      "configuration_profile_reference_v1.rds"
    ),
    new_path = base::file.path(
      path_reference_directory,
      "configuration_profile_reference_v1.rds"
    )
  )

  return(path_fixture_root)
}

run_configuration_test_fixture <- function(path_fixture_root) {
  run_configuration_generation(
    path_manifest = base::file.path(
      path_fixture_root,
      "Configuration",
      "manifest.yml"
    ),
    path_source_root = path_fixture_root,
    path_destination_root = base::file.path(
      path_fixture_root,
      "output"
    )
  )
}

testthat::test_that(
  "configuration generation reproduces the tracked source contract",
  {
    path_fixture_root <-
      make_configuration_test_fixture()

    data_profiles <-
      run_configuration_test_fixture(path_fixture_root)

    testthat::expect_identical(base::nrow(data_profiles), 26L)
    testthat::expect_true(
      base::file.exists(
        base::file.path(
          path_fixture_root,
          "output",
          "config.yml"
        )
      )
    )
    testthat::expect_true(
      base::file.exists(
        base::file.path(
          path_fixture_root,
          "output",
          "Configuration",
          "Generated",
          "profile_catalog.md"
        )
      )
    )

    vec_artifact_paths <-
      base::c(
        "config.yml",
        "Configuration/Generated/profile_catalog.md"
      )

    for (
      path_artifact in vec_artifact_paths
    ) {
      path_generated <-
        base::file.path(
          path_fixture_root,
          "output",
          path_artifact
        )
      path_tracked <-
        here::here(path_artifact)

      testthat::expect_identical(
        base::readBin(
          con = path_generated,
          what = "raw",
          n = base::file.info(path_generated)[["size"]]
        ),
        base::readBin(
          con = path_tracked,
          what = "raw",
          n = base::file.info(path_tracked)[["size"]]
        ),
        info = path_artifact
      )
    }
  }
)

testthat::test_that(
  "configuration generation rejects unlisted fragments",
  {
    path_fixture_root <-
      make_configuration_test_fixture()

    base::writeLines(
      base::c(
        "unexpected_profile:",
        "  inherits: default"
      ),
      con = base::file.path(
        path_fixture_root,
        "Configuration",
        "unexpected.yml"
      )
    )

    testthat::expect_error(
      run_configuration_test_fixture(path_fixture_root),
      "absent from the manifest"
    )
  }
)

testthat::test_that(
  "configuration generation rejects duplicate nested keys",
  {
    path_fixture_root <-
      make_configuration_test_fixture()

    path_fragment <-
      base::file.path(
        path_fixture_root,
        "Configuration",
        "Defaults",
        "default.yml"
      )

    base::writeLines(
      base::c(
        base::readLines(path_fragment, warn = FALSE),
        "  target_store: duplicate"
      ),
      con = path_fragment
    )

    testthat::expect_error(
      run_configuration_test_fixture(path_fixture_root),
      "Duplicate YAML key"
    )
  }
)

testthat::test_that(
  "configuration generation rejects duplicate profile declarations",
  {
    path_fixture_root <-
      make_configuration_test_fixture()

    path_fragment <-
      base::file.path(
        path_fixture_root,
        "Configuration",
        "Profiles",
        "References",
        "traits.yml"
      )

    base::writeLines(
      base::c(
        base::readLines(path_fragment, warn = FALSE),
        "",
        "default:",
        "  inherits: project_traits_reference"
      ),
      con = path_fragment
    )

    testthat::expect_error(
      run_configuration_test_fixture(path_fixture_root),
      "declared in multiple fragments"
    )
  }
)

testthat::test_that(
  "configuration generation rejects incomplete metadata",
  {
    path_fixture_root <-
      make_configuration_test_fixture()

    path_fragment <-
      base::file.path(
        path_fixture_root,
        "Configuration",
        "Profiles",
        "References",
        "traits.yml"
      )

    vec_lines <-
      base::readLines(path_fragment, warn = FALSE)

    base::writeLines(
      vec_lines[
        !stringr::str_detect(
          vec_lines,
          "^[ ]+role: reference$"
        )
      ],
      con = path_fragment
    )

    testthat::expect_error(
      run_configuration_test_fixture(path_fixture_root),
      "incomplete metadata"
    )
  }
)

testthat::test_that(
  "configuration generation rejects unknown inheritance parents",
  {
    path_fixture_root <-
      make_configuration_test_fixture()

    path_fragment <-
      base::file.path(
        path_fixture_root,
        "Configuration",
        "Profiles",
        "References",
        "cross_validation.yml"
      )

    vec_lines <-
      base::readLines(path_fragment, warn = FALSE)

    base::writeLines(
      base::sub(
        pattern = "inherits: project_cz_paleo$",
        replacement = "inherits: missing_parent",
        x = vec_lines
      ),
      con = path_fragment
    )

    testthat::expect_error(
      run_configuration_test_fixture(path_fixture_root),
      "unknown parent"
    )
  }
)

testthat::test_that(
  "configuration generation rejects inheritance cycles",
  {
    path_fixture_root <-
      make_configuration_test_fixture()

    path_fragment <-
      base::file.path(
        path_fixture_root,
        "Configuration",
        "Profiles",
        "References",
        "cross_validation.yml"
      )

    vec_lines <-
      base::readLines(path_fragment, warn = FALSE)

    base::writeLines(
      base::sub(
        pattern = "inherits: project_cz_paleo$",
        replacement =
          "inherits: project_cz_paleo_cv_reference_gpu",
        x = vec_lines
      ),
      con = path_fragment
    )

    testthat::expect_error(
      run_configuration_test_fixture(path_fixture_root),
      "Inheritance cycle"
    )
  }
)

testthat::test_that(
  "configuration generation enforces inheritance depth",
  {
    path_fixture_root <-
      make_configuration_test_fixture()

    path_manifest <-
      base::file.path(
        path_fixture_root,
        "Configuration",
        "manifest.yml"
      )

    vec_lines <-
      base::readLines(path_manifest, warn = FALSE)

    base::writeLines(
      base::sub(
        pattern = "maximum_inheritance_depth: 4$",
        replacement = "maximum_inheritance_depth: 1",
        x = vec_lines
      ),
      con = path_manifest
    )

    testthat::expect_error(
      run_configuration_test_fixture(path_fixture_root),
      "exceeds the maximum\\s+inheritance depth"
    )
  }
)

testthat::test_that(
  "configuration generation rejects semantic drift",
  {
    path_fixture_root <-
      make_configuration_test_fixture()

    path_fragment <-
      base::file.path(
        path_fixture_root,
        "Configuration",
        "Profiles",
        "Validation",
        "cz_smoke.yml"
      )

    vec_lines <-
      base::readLines(path_fragment, warn = FALSE)

    base::writeLines(
      base::sub(
        pattern = "Data/targets/cz_paleo$",
        replacement = "Data/targets/cz_paleo_changed",
        x = vec_lines
      ),
      con = path_fragment
    )

    testthat::expect_error(
      run_configuration_test_fixture(path_fixture_root),
      "differ from the semantic reference"
    )
  }
)
