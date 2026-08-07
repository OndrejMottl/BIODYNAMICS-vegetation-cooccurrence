testthat::test_that(
  "load_project_functions() loads functions in deterministic order",
  {
    path_root <-
      withr::local_tempdir()

    path_nested <-
      base::file.path(path_root, "Nested")

    base::dir.create(path_nested)

    base::writeLines(
      text = "zeta <- function() { return('zeta') }",
      con = base::file.path(path_nested, "zeta.R")
    )
    base::writeLines(
      text = "alpha <- function() { return('alpha') }",
      con = base::file.path(path_root, "alpha.R")
    )

    environment_target <-
      base::new.env(parent = base::baseenv())

    data_inventory <-
      load_project_functions(
        path_function_root = path_root,
        environment_target = environment_target
      )

    testthat::expect_s3_class(data_inventory, "data.frame")
    testthat::expect_equal(
      data_inventory[["path_relative"]],
      base::c("alpha.R", "Nested/zeta.R")
    )
    testthat::expect_equal(
      data_inventory[["source_order"]],
      base::c(1L, 2L)
    )
    testthat::expect_true(
      base::exists(
        "alpha",
        envir = environment_target,
        inherits = FALSE
      )
    )
    testthat::expect_true(
      base::exists(
        "zeta",
        envir = environment_target,
        inherits = FALSE
      )
    )
  }
)

testthat::test_that(
  "load_project_functions() applies exact directory exclusions",
  {
    path_root <-
      withr::local_tempdir()

    path_legacy <-
      base::file.path(path_root, "_legacy")

    path_not_legacy <-
      base::file.path(path_root, "not_legacy")

    path_nested_legacy <-
      base::file.path(path_root, "nested", "_legacy")

    base::dir.create(path_legacy)
    base::dir.create(path_not_legacy)
    base::dir.create(
      path_nested_legacy,
      recursive = TRUE
    )

    base::writeLines(
      text = "active <- function() { return(TRUE) }",
      con = base::file.path(path_root, "active.R")
    )
    base::writeLines(
      text = "old <- function() { return(TRUE) }",
      con = base::file.path(path_legacy, "old.R")
    )
    base::writeLines(
      text = "current <- function() { return(TRUE) }",
      con = base::file.path(path_not_legacy, "current.R")
    )
    base::writeLines(
      text = "deep_old <- function() { return(TRUE) }",
      con = base::file.path(path_nested_legacy, "deep_old.R")
    )

    environment_target <-
      base::new.env(parent = base::baseenv())

    data_inventory <-
      load_project_functions(
        path_function_root = path_root,
        environment_target = environment_target,
        vec_excluded_directory_names = "_legacy"
      )

    testthat::expect_equal(
      data_inventory[["function_name"]],
      base::c("active", "current")
    )
    testthat::expect_false(
      base::exists(
        "old",
        envir = environment_target,
        inherits = FALSE
      )
    )
    testthat::expect_false(
      base::exists(
        "deep_old",
        envir = environment_target,
        inherits = FALSE
      )
    )
    testthat::expect_true(
      base::exists(
        "current",
        envir = environment_target,
        inherits = FALSE
      )
    )
    testthat::expect_error(
      load_project_functions(
        path_function_root = path_root,
        environment_target = base::new.env(),
        vec_excluded_directory_names = "missing_legacy"
      ),
      regexp = "not present"
    )
  }
)

testthat::test_that(
  "load_project_functions() rejects duplicate symbols atomically",
  {
    path_root <-
      withr::local_tempdir()

    base::writeLines(
      text = "shared <- function() { return('first') }",
      con = base::file.path(path_root, "first.R")
    )
    base::writeLines(
      text = "shared <- function() { return('second') }",
      con = base::file.path(path_root, "second.R")
    )

    environment_target <-
      base::new.env(parent = base::baseenv())

    testthat::expect_error(
      load_project_functions(
        path_function_root = path_root,
        environment_target = environment_target
      ),
      regexp = "Duplicate function symbol"
    )
    testthat::expect_false(
      base::exists(
        "shared",
        envir = environment_target,
        inherits = FALSE
      )
    )
  }
)

testthat::test_that(
  "load_project_functions() rejects duplicate basenames",
  {
    path_root <-
      withr::local_tempdir()

    path_first <-
      base::file.path(path_root, "First")
    path_second <-
      base::file.path(path_root, "Second")

    base::dir.create(path_first)
    base::dir.create(path_second)

    base::writeLines(
      text = "same <- function() { return(1) }",
      con = base::file.path(path_first, "same.R")
    )
    base::writeLines(
      text = "Same <- function() { return(2) }",
      con = base::file.path(path_second, "Same.R")
    )

    testthat::expect_error(
      load_project_functions(
        path_function_root = path_root,
        environment_target = base::new.env()
      ),
      regexp = "Duplicate function-file basename"
    )
  }
)

testthat::test_that(
  "load_project_functions() enforces file and function names",
  {
    path_root <-
      withr::local_tempdir()

    base::writeLines(
      text = "wrong <- function() { return(TRUE) }",
      con = base::file.path(path_root, "expected.R")
    )

    testthat::expect_error(
      load_project_functions(
        path_function_root = path_root,
        environment_target = base::new.env()
      ),
      regexp = "must match its file basename"
    )

    base::unlink(base::file.path(path_root, "expected.R"))
    base::writeLines(
      text = ".internal <- function() { return(TRUE) }",
      con = base::file.path(path_root, "internal.R")
    )

    environment_target <-
      base::new.env(parent = base::baseenv())

    data_inventory <-
      load_project_functions(
        path_function_root = path_root,
        environment_target = environment_target
      )

    testthat::expect_equal(
      data_inventory[["function_name"]],
      ".internal"
    )
    testthat::expect_true(data_inventory[["is_internal"]])
  }
)

testthat::test_that(
  "load_project_functions() rejects ambiguous file contents",
  {
    path_root <-
      withr::local_tempdir()

    base::writeLines(
      text = base::c(
        "multiple <- function() { return(TRUE) }",
        "another <- function() { return(FALSE) }"
      ),
      con = base::file.path(path_root, "multiple.R")
    )

    testthat::expect_error(
      load_project_functions(
        path_function_root = path_root,
        environment_target = base::new.env()
      ),
      regexp = "exactly one top-level function"
    )

    base::unlink(base::file.path(path_root, "multiple.R"))
    base::writeLines(
      text = base::c(
        "executable <- function() { return(TRUE) }",
        "value <- 1"
      ),
      con = base::file.path(path_root, "executable.R")
    )

    testthat::expect_error(
      load_project_functions(
        path_function_root = path_root,
        environment_target = base::new.env()
      ),
      regexp = "unapproved top-level"
    )
  }
)

testthat::test_that(
  "load_project_functions() validates arguments and exclusions",
  {
    path_root <-
      withr::local_tempdir()

    base::writeLines(
      text = "valid <- function() { return(TRUE) }",
      con = base::file.path(path_root, "valid.R")
    )

    testthat::expect_error(
      load_project_functions(
        path_function_root = base::file.path(path_root, "missing"),
        environment_target = base::new.env()
      ),
      regexp = "existing directory"
    )
    testthat::expect_error(
      load_project_functions(
        path_function_root = path_root,
        environment_target = "global"
      ),
      regexp = "environment"
    )
    testthat::expect_error(
      load_project_functions(
        path_function_root = path_root,
        environment_target = base::new.env(),
        vec_excluded_directory_names = base::c(
          "_legacy",
          "_legacy"
        )
      ),
      regexp = "unique"
    )
    testthat::expect_error(
      load_project_functions(
        path_function_root = path_root,
        environment_target = base::new.env(),
        vec_excluded_directory_names = "_legacy/old"
      ),
      regexp = "single directory"
    )
  }
)
