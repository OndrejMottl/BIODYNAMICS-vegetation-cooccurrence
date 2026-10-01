testthat::test_that(
  "build_manuscript_palette() returns stable semantic mappings",
  {
    vec_components <-
      build_manuscript_palette("variance_component")
    vec_sources <-
      build_manuscript_palette("data_source")

    testthat::expect_named(
      vec_components,
      base::c(
        "Biotic co-occurrence",
        "Climate",
        "Spatial",
        "Unexplained"
      )
    )
    testthat::expect_named(
      vec_sources,
      base::c("Paleo", "Modern")
    )
    testthat::expect_length(
      base::unique(vec_components),
      base::length(vec_components)
    )
  }
)

testthat::test_that(
  "build_manuscript_palette() rejects unsupported domains",
  {
    testthat::expect_error(
      build_manuscript_palette("decorative"),
      "arg"
    )
  }
)
