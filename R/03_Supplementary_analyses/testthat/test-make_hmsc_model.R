testthat::test_that(
  desc = "return correct class",
  code = {
    data_community_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000", "dataset3__1500"),
        species1 = c(1, 0, 1),
        species2 = c(0, 1, 0)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_abiotic_example <-
      data.frame(
        row_name = c("dataset0__0", "dataset1__500", "dataset2__1000"),
        abiotic1 = c(5, 6, 7),
        abiotic2 = c(8, 9, 10)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_coords_example <-
      data.frame(
        row_name = c("dataset0", "dataset1", "dataset2", "dataset3"),
        coord_long = c(9, 10, 11, 12),
        coord_lat = c(12, 13, 14, 15)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_dummy <-
      check_and_prepare_data_for_fit(
        data_community = data_community_example,
        data_abiotic = data_abiotic_example,
        data_coords = data_coords_example
      )

    result <-
      make_hmsc_model(
        data = data_dummy,
        sel_formula = "~ abiotic1 + abiotic2",
        random_structure = get_random_structure_for_model(
          data = data_dummy,
          type = c("age", "space")
        )
      )

    testthat::expect_s3_class(result, "Hmsc")
  }
)

testthat::test_that(
  desc = "return correct data structure",
  code = {
    data_community_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000", "dataset3__1500"),
        species1 = c(1, 0, 1),
        species2 = c(0, 1, 0)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_abiotic_example <-
      data.frame(
        row_name = c("dataset0__0", "dataset1__500", "dataset2__1000"),
        abiotic1 = c(5, 6, 7),
        abiotic2 = c(8, 9, 10)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_coords_example <-
      data.frame(
        row_name = c("dataset0", "dataset1", "dataset2", "dataset3"),
        coord_long = c(9, 10, 11, 12),
        coord_lat = c(12, 13, 14, 15)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_dummy <-
      check_and_prepare_data_for_fit(
        data_community = data_community_example,
        data_abiotic = data_abiotic_example,
        data_coords = data_coords_example
      )

    result <-
      make_hmsc_model(
        data = data_dummy,
        sel_formula = "~ abiotic1 + abiotic2",
        random_structure = get_random_structure_for_model(
          data = data_dummy,
          type = c("age", "space")
        )
      )

    result_names <- names(result)

    expected_names <-
      c(
        "Y", "XData", "XFormula", "X", "XScaled",
        "XRRRData", "XRRRFormula", "XRRRScaled", "YScaled", "XInterceptInd",
        "studyDesign", "ranLevels", "ranLevelsUsed", "dfPi", "rL",
        "Pi", "TrData", "TrFormula", "Tr", "TrScaled",
        "C", "phyloTree", "distr", "ny", "ns",
        "nc", "ncNRRR", "ncRRR", "ncORRR", "ncsel",
        "nr", "nt", "nf", "ncr", "ncs",
        "np",
        "spNames", "covNames", "trNames", "rLNames",
        "XScalePar", "XRRRScalePar", "YScalePar", "TrScalePar", "V0",
        "f0", "mGamma", "UGamma", "aSigma", "bSigma",
        "rhopw", "nuRRR", "a1RRR", "b1RRR", "a2RRR",
        "b2RRR", "samples", "transient", "thin", "verbose",
        "adaptNf", "initPar", "repN", "randSeed", "postList",
        "call", "HmscVersion"
      )

    testthat::expect_equal(
      result_names,
      expected_names
    )
  }
)

testthat::test_that(
  desc = "handles input errors",
  code = {
    data_community_example <-
      data.frame(
        row_name = c("dataset1__500", "dataset2__1000", "dataset3__1500"),
        species1 = c(1, 0, 1),
        species2 = c(0, 1, 0)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_abiotic_example <-
      data.frame(
        row_name = c("dataset0__0", "dataset1__500", "dataset2__1000"),
        abiotic1 = c(5, 6, 7),
        abiotic2 = c(8, 9, 10)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_coords_example <-
      data.frame(
        row_name = c("dataset0", "dataset1", "dataset2", "dataset3"),
        coord_long = c(9, 10, 11, 12),
        coord_lat = c(12, 13, 14, 15)
      ) %>%
      tibble::column_to_rownames("row_name")

    data_dummy <-
      check_and_prepare_data_for_fit(
        data_community = data_community_example,
        data_abiotic = data_abiotic_example,
        data_coords = data_coords_example
      )

    testthat::expect_error(
      make_hmsc_model(
        data = NULL,
        sel_formula = "~ abiotic1 + abiotic2",
        random_structure = get_random_structure_for_model(
          data = data_dummy,
          type = c("age", "space")
        )
      )
    )

    testthat::expect_error(
      make_hmsc_model(
        data = "invalid_data",
        sel_formula = "~ abiotic1 + abiotic2",
        random_structure = get_random_structure_for_model(
          data = data_dummy,
          type = c("age", "space")
        )
      )
    )

    testthat::expect_error(
      make_hmsc_model(
        data = list(),
        sel_formula = "~ abiotic1 + abiotic2",
        random_structure = get_random_structure_for_model(
          data = data_dummy,
          type = c("age", "space")
        )
      )
    )

    testthat::expect_error(
      make_hmsc_model(
        data = data_dummy,
        sel_formula = NULL,
        random_structure = get_random_structure_for_model(
          data = data_dummy,
          type = c("age", "space")
        )
      )
    )

    testthat::expect_error(
      make_hmsc_model(
        data = data_dummy,
        sel_formula = "not_a_formula",
        random_structure = get_random_structure_for_model(
          data = data_dummy,
          type = c("age", "space")
        )
      )
    )

    testthat::expect_error(
      make_hmsc_model(
        data = data_dummy,
        sel_formula = "~ abiotic1 + abiotic2",
        random_structure = NULL
      )
    )

    testthat::expect_error(
      make_hmsc_model(
        data = data_dummy,
        sel_formula = "~ abiotic1 + abiotic2",
        random_structure = "not_a_random_structure"
      )
    )

    testthat::expect_error(
      make_hmsc_model(
        data = data_dummy,
        sel_formula = "~ abiotic1 + abiotic2",
        random_structure = list()
      )
    )

    testthat::expect_error(
      make_hmsc_model(
        data = data_dummy,
        sel_formula = "~ abiotic1 + abiotic2",
        random_structure = get_random_structure_for_model(
          data = data_dummy,
          type = c("age", "space")
        ),
        error_family = NULL
      )
    )

    testthat::expect_error(
      make_hmsc_model(
        data = data_dummy,
        sel_formula = "~ abiotic1 + abiotic2",
        random_structure = get_random_structure_for_model(
          data = data_dummy,
          type = c("age", "space")
        ),
        error_family = character()
      )
    )

    testthat::expect_error(
      make_hmsc_model(
        data = data_dummy,
        sel_formula = "~ abiotic1 + abiotic2",
        random_structure = get_random_structure_for_model(
          data = data_dummy,
          type = c("age", "space")
        ),
        error_family = "invalid_error_family"
      )
    )
  }
)
