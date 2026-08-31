testthat::test_that(
  "matrix readiness reports coverage ranges and taxon anomalies",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D", "E", "F"),
        `Plant heigh` = base::c(2, 2, 2, 3, 3, 100000),
        `Stem specific density` =
          base::c(0.4, 0.5, 0.5, 0.6, NA_real_, 0.55)
      )
    vec_transformations <-
      base::c(
        `Plant heigh` = "log10",
        `Stem specific density` = "identity"
      )

    list_diagnosis <-
      diagnose_trait_matrix_readiness(
        data_trait_table = data_traits,
        vec_trait_transformations = vec_transformations,
        maximum_transformed_range = 3,
        outlier_fence_multiplier = 1.5
      )

    data_summary <- list_diagnosis[["data_domain_summary"]]
    data_anomalies <- list_diagnosis[["data_taxon_anomalies"]]
    data_height_anomalies <-
      data_anomalies |>
      dplyr::filter(
        .data[["trait_domain_name"]] == "Plant heigh"
      )

    testthat::expect_equal(base::nrow(data_summary), 2L)
    testthat::expect_equal(
      data_summary[["n_missing"]],
      base::c(0L, 1L)
    )
    testthat::expect_true(
      data_summary[["flag_excessive_transformed_range"]][[1L]]
    )
    testthat::expect_identical(
      data_height_anomalies[["taxon_name"]],
      "F"
    )
    testthat::expect_false(list_diagnosis[["flag_ready"]])
  }
)

testthat::test_that(
  "matrix readiness is true for a complete coherent matrix",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        `Leaf Area` = base::c(10, 20, 30)
      )

    list_diagnosis <-
      diagnose_trait_matrix_readiness(
        data_trait_table = data_traits,
        vec_trait_transformations =
          base::c(`Leaf Area` = "log10")
      )

    testthat::expect_true(list_diagnosis[["flag_ready"]])
    testthat::expect_equal(
      base::nrow(list_diagnosis[["data_taxon_anomalies"]]),
      0L
    )
  }
)

testthat::test_that(
  "matrix readiness diagnoses only sensitivity-selected traits",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        `Leaf Area` = base::c(10, 20, 30),
        `Leaf mass per area` = base::c(1, 2, 3)
      )

    list_diagnosis <-
      diagnose_trait_matrix_readiness(
        data_trait_table = data_traits,
        vec_trait_transformations =
          base::c(`Leaf Area` = "log10")
      )

    testthat::expect_identical(
      list_diagnosis[["data_domain_summary"]][["trait_domain_name"]],
      "Leaf Area"
    )
  }
)
