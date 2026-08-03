source(
  here::here(
    "R/Pipelines/_pipes/_helpers/make_community_filter_targets.R"
  )
)


testthat::test_that(
  "make_community_filter_targets() returns the expected targets",
  {
    list_targets <-
      make_community_filter_targets("data_community_classified")

    testthat::expect_length(list_targets, 4L)

    vec_is_target <-
      base::vapply(
        list_targets,
        function(x) {
          base::inherits(x, "tar_target")
        },
        logical(1)
      )

    testthat::expect_true(base::all(vec_is_target))

    vec_target_names <-
      base::vapply(
        list_targets,
        function(x) {
          x[["name"]]
        },
        character(1)
      )

    testthat::expect_identical(
      vec_target_names,
      c(
        "data_community_rare_filtered",
        "data_community_filtered_cores",
        "data_community_filtered_samples",
        "data_community_analysis_subset"
      )
    )
  }
)

testthat::test_that(
  "make_community_filter_targets() injects the supplied input symbol",
  {
    list_targets <-
      make_community_filter_targets("data_community_classified")

    command_string <-
      list_targets[[1]][["command"]][["string"]]

    testthat::expect_match(
      command_string,
      "data_community_classified",
      fixed = TRUE
    )

    testthat::expect_false(
      base::grepl(
        pattern = "input_name",
        x = command_string,
        fixed = TRUE
      )
    )
  }
)
