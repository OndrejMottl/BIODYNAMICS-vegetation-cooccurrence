build_test_reference <- function() {
  list_profiles <-
    base::list(
      p1 = base::list(a = 1, m = base::list(flag = TRUE)),
      p2 = base::list(a = 2, m = base::list(flag = TRUE))
    )
  base::list(
    reference_version = 1L,
    profile_ids = base::c("p1", "p2"),
    semantic_hashes = list_profiles |>
      purrr::map_chr(.f = ~ digest::digest(object = .x, algo = "sha256")),
    aggregate_semantic_sha256 = digest::digest(
      object = list_profiles,
      algo = "sha256"
    ),
    resolved_profiles = list_profiles
  )
}

build_test_declared_changes <- function(profile_id, key_path) {
  tibble::tibble(
    change_id = stringr::str_c("change_", base::seq_along(profile_id)),
    profile_id = profile_id,
    key_path = key_path,
    issue = "#1",
    rationale = "test"
  )
}

testthat::test_that(
  "save_configuration_profile_reference() writes declared changes",
  {
    list_reference <-
      build_test_reference()
    list_profiles_new <-
      list_reference[["resolved_profiles"]]
    list_profiles_new[["p1"]][["m"]][["flag"]] <- FALSE
    list_profiles_new[["p1"]][["continent_id"]] <- "europe"
    list_profiles_new[["p2"]][["continent_id"]] <- "america"
    path_reference <-
      base::tempfile(fileext = ".rds")

    res <-
      save_configuration_profile_reference(
        list_reference = list_reference,
        list_profiles_new = list_profiles_new,
        data_declared_changes = build_test_declared_changes(
          profile_id = base::c("p1", "*"),
          key_path = base::c("m.flag", "continent_id")
        ),
        path_reference = path_reference
      )

    list_saved <-
      base::readRDS(path_reference)

    testthat::expect_identical(res, list_saved)
    testthat::expect_identical(
      list_saved[["resolved_profiles"]],
      list_profiles_new
    )
    testthat::expect_equal(
      list_saved[["semantic_hashes"]][["p1"]],
      digest::digest(object = list_profiles_new[["p1"]], algo = "sha256")
    )
    testthat::expect_equal(base::nrow(list_saved[["revision_changes"]]), 3L)
    testthat::expect_equal(list_saved[["reference_version"]], 1L)
  }
)

testthat::test_that(
  "save_configuration_profile_reference() rejects undeclared changes",
  {
    list_reference <-
      build_test_reference()
    list_profiles_new <-
      list_reference[["resolved_profiles"]]
    list_profiles_new[["p2"]][["a"]] <- 3
    path_reference <-
      base::tempfile(fileext = ".rds")

    testthat::expect_error(
      save_configuration_profile_reference(
        list_reference = list_reference,
        list_profiles_new = list_profiles_new,
        data_declared_changes = build_test_declared_changes(
          profile_id = "p1",
          key_path = "a"
        ),
        path_reference = path_reference
      ),
      class = "configuration_reference_undeclared_change"
    )
    testthat::expect_false(base::file.exists(path_reference))
  }
)

testthat::test_that(
  "save_configuration_profile_reference() validates its inputs",
  {
    testthat::expect_error(
      save_configuration_profile_reference(
        list_reference = base::list(),
        list_profiles_new = base::list(),
        data_declared_changes = build_test_declared_changes("p1", "a"),
        path_reference = "x.rds"
      ),
      "semantic reference"
    )
    testthat::expect_error(
      save_configuration_profile_reference(
        list_reference = build_test_reference(),
        list_profiles_new = build_test_reference()[["resolved_profiles"]],
        data_declared_changes = tibble::tibble(profile_id = "p1"),
        path_reference = "x.rds"
      ),
      "declared-changes schema"
    )
  }
)
