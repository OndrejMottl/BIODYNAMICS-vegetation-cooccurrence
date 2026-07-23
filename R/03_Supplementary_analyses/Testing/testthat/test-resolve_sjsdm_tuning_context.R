testthat::test_that(
  "resolve_sjsdm_tuning_context() preserves the production context",
  {
    list_context <-
      base::list(
        pipeline_name = "pipeline_paleo_spatial_resolution",
        resolution_ids = base::c(
          "genus",
          "family",
          "functional_type"
        ),
        nested_unit_stores = TRUE
      )

    testthat::expect_identical(
      resolve_sjsdm_tuning_context(list_context),
      list_context
    )
  }
)

testthat::test_that(
  "resolve_sjsdm_tuning_context() applies a configured subset",
  {
    list_context <-
      base::list(
        pipeline_name = "pipeline_paleo_spatial_resolution",
        resolution_ids = base::c(
          "genus",
          "family",
          "functional_type"
        ),
        nested_unit_stores = TRUE
      )

    res <-
      resolve_sjsdm_tuning_context(
        list_default_context = list_context,
        resolution_ids = "genus"
      )

    testthat::expect_identical(
      res[["resolution_ids"]],
      "genus"
    )
    testthat::expect_identical(
      res[["pipeline_name"]],
      list_context[["pipeline_name"]]
    )
    testthat::expect_identical(
      res[["nested_unit_stores"]],
      list_context[["nested_unit_stores"]]
    )
  }
)

testthat::test_that(
  "resolve_sjsdm_tuning_context() rejects malformed subsets",
  {
    list_context <-
      base::list(
        pipeline_name = "pipeline_paleo_spatial_resolution",
        resolution_ids = base::c("genus", "family"),
        nested_unit_stores = TRUE
      )

    testthat::expect_error(
      resolve_sjsdm_tuning_context(
        list_default_context = list_context,
        resolution_ids = "functional_type"
      ),
      "subset"
    )
    testthat::expect_error(
      resolve_sjsdm_tuning_context(
        list_default_context = list_context,
        resolution_ids = base::c("genus", "genus")
      ),
      "unique"
    )
    testthat::expect_error(
      resolve_sjsdm_tuning_context(
        list_default_context = list_context,
        resolution_ids = base::character()
      ),
      "non-empty"
    )
  }
)
