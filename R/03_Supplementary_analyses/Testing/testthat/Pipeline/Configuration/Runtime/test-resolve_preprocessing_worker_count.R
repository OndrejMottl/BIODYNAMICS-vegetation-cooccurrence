testthat::test_that(
  "worker resolution applies shared and dedicated profile caps",
  {
    res_shared <-
      resolve_preprocessing_worker_count(
        configured_workers = 16L,
        resource_profile = "shared",
        available_memory_bytes = 64 * 1024^3
      )
    res_dedicated <-
      resolve_preprocessing_worker_count(
        configured_workers = 16L,
        resource_profile = "dedicated",
        available_memory_bytes = 64 * 1024^3
      )
    res_configured <-
      resolve_preprocessing_worker_count(
        configured_workers = 16L,
        resource_profile = "configured",
        available_memory_bytes = 128 * 1024^3
      )

    testthat::expect_identical(res_shared, 4L)
    testthat::expect_identical(res_dedicated, 8L)
    testthat::expect_identical(res_configured, 16L)
  }
)

testthat::test_that(
  "worker resolution gives explicit override precedence",
  {
    res <-
      resolve_preprocessing_worker_count(
        configured_workers = 4L,
        resource_profile = "shared",
        workers_override = "12",
        available_memory_bytes = 128 * 1024^3
      )

    testthat::expect_identical(res, 12L)
  }
)

testthat::test_that(
  "worker resolution lowers concurrency under memory pressure",
  {
    res <-
      resolve_preprocessing_worker_count(
        configured_workers = 16L,
        resource_profile = "dedicated",
        available_memory_bytes = 20 * 1024^3
      )

    testthat::expect_identical(res, 3L)
  }
)

testthat::test_that(
  "worker resolution validates profiles and worker values",
  {
    testthat::expect_error(
      resolve_preprocessing_worker_count(
        configured_workers = 0L,
        available_memory_bytes = 64 * 1024^3
      ),
      "configured_workers"
    )
    testthat::expect_error(
      resolve_preprocessing_worker_count(
        configured_workers = 4L,
        resource_profile = "turbo",
        available_memory_bytes = 64 * 1024^3
      ),
      "resource_profile"
    )
  }
)
