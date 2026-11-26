testthat::test_that(
  "resolve_trait_correction_directory() returns the release folder",
  {
    dir_corrections <-
      withr::local_tempdir()
    base::dir.create(
      base::file.path(dir_corrections, "VegVault_1_0_0")
    )
    base::dir.create(
      base::file.path(dir_corrections, "VegVault_2_0_0")
    )

    res <-
      resolve_trait_correction_directory(
        vegvault_version = "2.0.0",
        dir_trait_corrections = dir_corrections
      )

    testthat::expect_type(res, "character")
    testthat::expect_length(res, 1L)
    testthat::expect_identical(
      res,
      base::file.path(dir_corrections, "VegVault_2_0_0")
    )
  }
)

testthat::test_that(
  "resolve_trait_correction_directory() keeps multi-digit version parts",
  {
    dir_corrections <-
      withr::local_tempdir()
    base::dir.create(
      base::file.path(dir_corrections, "VegVault_2_10_0")
    )

    res <-
      resolve_trait_correction_directory(
        vegvault_version = "2.10.0",
        dir_trait_corrections = dir_corrections
      )

    testthat::expect_identical(
      res,
      base::file.path(dir_corrections, "VegVault_2_10_0")
    )
  }
)

testthat::test_that(
  "resolve_trait_correction_directory() stops without a release folder",
  {
    dir_corrections <-
      withr::local_tempdir()
    base::dir.create(
      base::file.path(dir_corrections, "VegVault_1_0_0")
    )
    base::file.create(
      base::file.path(dir_corrections, "VegVault_3_0_0")
    )

    testthat::expect_error(
      resolve_trait_correction_directory(
        vegvault_version = "2.0.0",
        dir_trait_corrections = dir_corrections
      ),
      class = "biodynamics_trait_correction_directory_missing"
    )
    testthat::expect_error(
      resolve_trait_correction_directory(
        vegvault_version = "2.0.0",
        dir_trait_corrections = dir_corrections
      ),
      regexp = "VegVault_2_0_0"
    )
    testthat::expect_error(
      resolve_trait_correction_directory(
        vegvault_version = "3.0.0",
        dir_trait_corrections = dir_corrections
      ),
      class = "biodynamics_trait_correction_directory_missing"
    )
  }
)

testthat::test_that(
  "resolve_trait_correction_directory() rejects an invalid version",
  {
    dir_corrections <-
      withr::local_tempdir()
    base::dir.create(
      base::file.path(dir_corrections, "VegVault_2_0_0")
    )

    purrr::walk(
      .x = base::list(
        NA_character_,
        "2.0",
        "v2.0.0",
        "2.0.0 ",
        base::c("2.0.0", "1.0.0"),
        2,
        NULL
      ),
      .f = ~ testthat::expect_error(
        resolve_trait_correction_directory(
          vegvault_version = .x,
          dir_trait_corrections = dir_corrections
        ),
        regexp = "'vegvault_version' must be"
      )
    )
  }
)

testthat::test_that(
  "resolve_trait_correction_directory() rejects an invalid parent folder",
  {
    dir_missing <-
      base::file.path(withr::local_tempdir(), "missing")

    purrr::walk(
      .x = base::list(
        dir_missing,
        base::c(dir_missing, dir_missing),
        1L,
        NA_character_
      ),
      .f = ~ testthat::expect_error(
        resolve_trait_correction_directory(
          vegvault_version = "2.0.0",
          dir_trait_corrections = .x
        ),
        regexp = "'dir_trait_corrections' must be"
      )
    )
  }
)
