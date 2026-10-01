testthat::test_that(
  "unit fitting plans skip only wholly infeasible units",
  {
    data_inventory <-
      tidyr::expand_grid(
        analysis_id = "paleo_spatial",
        tier_id = "local",
        scale_id = base::c("unit_a", "unit_b", "unit_c"),
        resolution_id = base::c("genus", "family", "functional_type")
      ) |>
      dplyr::mutate(
        preparation_status = dplyr::case_when(
          .data[["scale_id"]] == "unit_b" ~ "expected_infeasible",
          .data[["scale_id"]] == "unit_c" &
            .data[["resolution_id"]] == "genus" ~
            "expected_infeasible",
          .default = "prepared"
        ),
        preparation_reason_code = dplyr::if_else(
          .data[["preparation_status"]] == "expected_infeasible",
          "insufficient_cores",
          NA_character_
        )
      )
    data_inventory <-
      dplyr::bind_rows(
        data_inventory,
        data_inventory |>
          dplyr::mutate(
            analysis_id = "modern_spatial",
            preparation_status = "unexpected_error"
          )
      )

    result <-
      build_sjsdm_unit_fitting_plan(
        data_preparation_inventory = data_inventory,
        analysis_id = "paleo_spatial",
        tier_id = "local",
        scale_ids = base::c("unit_c", "unit_a", "unit_b"),
        resolution_ids = base::c(
          "genus",
          "family",
          "functional_type"
        )
      )

    testthat::expect_identical(
      result[["scale_id"]],
      base::c("unit_c", "unit_a", "unit_b")
    )
    testthat::expect_identical(
      result[["fitting_status"]],
      base::c("eligible", "eligible", "expected_infeasible")
    )
    testthat::expect_true(
      base::is.na(result[["preparation_reason_code"]][[1L]])
    )
    testthat::expect_identical(
      result[["preparation_reason_code"]][[3L]],
      "insufficient_cores"
    )
  }
)

testthat::test_that(
  "unit fitting plans reject incomplete or contradictory evidence",
  {
    data_inventory <-
      tibble::tibble(
        analysis_id = "paleo_spatial",
        tier_id = "local",
        scale_id = "unit_a",
        resolution_id = "genus",
        preparation_status = "prepared",
        preparation_reason_code = NA_character_
      )

    testthat::expect_error(
      build_sjsdm_unit_fitting_plan(
        data_preparation_inventory = data_inventory,
        analysis_id = "paleo_spatial",
        tier_id = "local",
        scale_ids = "unit_a",
        resolution_ids = base::c("genus", "family")
      ),
      "missing or unresolved"
    )

    data_inventory_duplicate <-
      dplyr::bind_rows(data_inventory, data_inventory)

    testthat::expect_error(
      build_sjsdm_unit_fitting_plan(
        data_preparation_inventory = data_inventory_duplicate,
        analysis_id = "paleo_spatial",
        tier_id = "local",
        scale_ids = "unit_a",
        resolution_ids = "genus"
      ),
      "duplicate"
    )
  }
)
