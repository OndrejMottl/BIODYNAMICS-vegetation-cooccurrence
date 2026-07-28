testthat::test_that(
  "build_combined_classification_table() validates auto table is a data frame",
  {
    data_classification_auxiliary <-
      tibble::tibble(
        sel_name = "Taxon A",
        family = "FamilyA",
        genus = "GenusA",
        species = "SpeciesA"
      )

    testthat::expect_error(
      build_combined_classification_table(
        data_classification_table = "not_a_df",
        data_auxiliary_classification_table = data_classification_auxiliary
      )
    )
  }
)

testthat::test_that(
  "build_combined_classification_table() validates sel_name in auto table",
  {
    data_classification_automatic <-
      tibble::tibble(
        family = "FamilyA",
        genus = "GenusA",
        species = "SpeciesA"
      )
    data_classification_auxiliary <-
      tibble::tibble(
        sel_name = "Taxon A",
        family = "FamilyA",
        genus = "GenusA",
        species = "SpeciesA"
      )

    testthat::expect_error(
      build_combined_classification_table(
        data_classification_table = data_classification_automatic,
        data_auxiliary_classification_table = data_classification_auxiliary
      ),
      regexp = "sel_name"
    )
  }
)

testthat::test_that(
  "build_combined_classification_table() validates aux table is a data frame",
  {
    data_classification_automatic <-
      tibble::tibble(
        sel_name = "Taxon A",
        family = "FamilyA",
        genus = "GenusA",
        species = "SpeciesA"
      )

    testthat::expect_error(
      build_combined_classification_table(
        data_classification_table = data_classification_automatic,
        data_auxiliary_classification_table = "not_a_df"
      )
    )
  }
)

testthat::test_that(
  "build_combined_classification_table() validates sel_name in aux table",
  {
    data_classification_automatic <-
      tibble::tibble(
        sel_name = "Taxon A",
        family = "FamilyA",
        genus = "GenusA",
        species = "SpeciesA"
      )
    data_classification_auxiliary <-
      tibble::tibble(
        family = "FamilyX",
        genus = "GenusX",
        species = "SpeciesX"
      )

    testthat::expect_error(
      build_combined_classification_table(
        data_classification_table = data_classification_automatic,
        data_auxiliary_classification_table = data_classification_auxiliary
      ),
      regexp = "sel_name"
    )
  }
)

testthat::test_that(
  "build_combined_classification_table() returns a data frame",
  {
    data_classification_automatic <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B"),
        family = c("FamilyA", "FamilyB"),
        genus = c("GenusA", "GenusB"),
        species = c("SpeciesA", "SpeciesB")
      )
    data_classification_auxiliary <-
      tibble::tibble(
        sel_name = base::character(0),
        family = base::character(0),
        genus = base::character(0),
        species = base::character(0)
      )

    res_combined_classification_table <-
      build_combined_classification_table(
        data_classification_table = data_classification_automatic,
        data_auxiliary_classification_table = data_classification_auxiliary
      )

    testthat::expect_true(
      base::is.data.frame(res_combined_classification_table)
    )
  }
)

testthat::test_that(
  "build_combined_classification_table() empty aux returns auto table rows",
  {
    data_classification_automatic <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B"),
        family = c("FamilyA", "FamilyB"),
        genus = c("GenusA", "GenusB"),
        species = c("SpeciesA", "SpeciesB")
      )
    data_classification_auxiliary <-
      tibble::tibble(
        sel_name = base::character(0),
        family = base::character(0),
        genus = base::character(0),
        species = base::character(0)
      )

    res_combined_classification_table <-
      build_combined_classification_table(
        data_classification_table = data_classification_automatic,
        data_auxiliary_classification_table = data_classification_auxiliary
      )

    testthat::expect_equal(
      base::nrow(res_combined_classification_table),
      base::nrow(data_classification_automatic)
    )

    testthat::expect_equal(
      base::sort(dplyr::pull(res_combined_classification_table, sel_name)),
      base::sort(dplyr::pull(data_classification_automatic, sel_name))
    )
  }
)

testthat::test_that(
  "build_combined_classification_table() non-overlapping tables: all rows kept",
  {
    data_classification_automatic <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B"),
        family = c("FamilyA", "FamilyB"),
        genus = c("GenusA", "GenusB"),
        species = c("SpeciesA", "SpeciesB")
      )
    data_classification_auxiliary <-
      tibble::tibble(
        sel_name = c("Taxon C", "Taxon D"),
        family = c("FamilyC", "FamilyD"),
        genus = c("GenusC", "GenusD"),
        species = c("SpeciesC", "SpeciesD")
      )

    res_combined_classification_table <-
      build_combined_classification_table(
        data_classification_table = data_classification_automatic,
        data_auxiliary_classification_table = data_classification_auxiliary
      )

    testthat::expect_equal(
      base::nrow(res_combined_classification_table),
      base::nrow(data_classification_automatic) + base::nrow(data_classification_auxiliary)
    )
  }
)

testthat::test_that(
  "build_combined_classification_table() aux row wins on sel_name collision",
  {
    data_classification_automatic <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B"),
        family = c("FamilyA_auto", "FamilyB_auto"),
        genus = c("GenusA_auto", "GenusB_auto"),
        species = c("SpeciesA_auto", "SpeciesB_auto")
      )
    data_classification_auxiliary <-
      tibble::tibble(
        sel_name = c("Taxon A"),
        family = c("FamilyA_manual"),
        genus = c("GenusA_manual"),
        species = c("SpeciesA_manual")
      )

    res_combined_classification_table <-
      build_combined_classification_table(
        data_classification_table = data_classification_automatic,
        data_auxiliary_classification_table = data_classification_auxiliary
      )

    vec_family <-
      res_combined_classification_table %>%
      dplyr::filter(sel_name == "Taxon A") %>%
      dplyr::pull(family)

    testthat::expect_equal(
      vec_family,
      "FamilyA_manual"
    )
  }
)

testthat::test_that(
  "build_combined_classification_table() auto rows unaffected outside collision",
  {
    data_classification_automatic <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B"),
        family = c("FamilyA_auto", "FamilyB_auto"),
        genus = c("GenusA_auto", "GenusB_auto"),
        species = c("SpeciesA_auto", "SpeciesB_auto")
      )
    data_classification_auxiliary <-
      tibble::tibble(
        sel_name = c("Taxon A"),
        family = c("FamilyA_manual"),
        genus = c("GenusA_manual"),
        species = c("SpeciesA_manual")
      )

    res_combined_classification_table <-
      build_combined_classification_table(
        data_classification_table = data_classification_automatic,
        data_auxiliary_classification_table = data_classification_auxiliary
      )

    vec_family_b_values <-
      res_combined_classification_table %>%
      dplyr::filter(sel_name == "Taxon B") %>%
      dplyr::pull(family)

    testthat::expect_equal(
      vec_family_b_values,
      "FamilyB_auto"
    )
  }
)

testthat::test_that(
  "build_combined_classification_table() aux-only taxa appear in result",
  {
    data_classification_automatic <-
      tibble::tibble(
        sel_name = c("Taxon A"),
        family = c("FamilyA"),
        genus = c("GenusA"),
        species = c("SpeciesA")
      )
    data_classification_auxiliary <-
      tibble::tibble(
        sel_name = c("Taxon Z"),
        family = c("FamilyZ"),
        genus = c("GenusZ"),
        species = c("SpeciesZ")
      )

    res_combined_classification_table <-
      build_combined_classification_table(
        data_classification_table = data_classification_automatic,
        data_auxiliary_classification_table = data_classification_auxiliary
      )

    testthat::expect_true(
      "Taxon Z" %in% dplyr::pull(res_combined_classification_table, sel_name)
    )
  }
)

testthat::test_that(
  "build_combined_classification_table() output has no duplicate sel_name values",
  {
    data_classification_automatic <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B", "Taxon C"),
        family = c("FamilyA", "FamilyB", "FamilyC"),
        genus = c("GenusA", "GenusB", "GenusC"),
        species = c("SpeciesA", "SpeciesB", "SpeciesC")
      )
    data_classification_auxiliary <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon D"),
        family = c("FamilyA_m", "FamilyD"),
        genus = c("GenusA_m", "GenusD"),
        species = c("SpeciesA_m", "SpeciesD")
      )

    res_combined_classification_table <-
      build_combined_classification_table(
        data_classification_table = data_classification_automatic,
        data_auxiliary_classification_table = data_classification_auxiliary
      )

    vec_selected_names <-
      dplyr::pull(res_combined_classification_table, sel_name)

    testthat::expect_equal(
      base::length(vec_selected_names),
      base::length(base::unique(vec_selected_names))
    )
  }
)

testthat::test_that(
  "build_combined_classification_table() output contains only shared columns",
  {
    data_classification_automatic <-
      tibble::tibble(
        sel_name = c("Taxon A"),
        family = c("FamilyA"),
        genus = c("GenusA"),
        species = c("SpeciesA"),
        extra_col = c("extra")
      )
    data_classification_auxiliary <-
      tibble::tibble(
        sel_name = c("Taxon B"),
        family = c("FamilyB"),
        genus = c("GenusB"),
        species = c("SpeciesB")
      )

    res_combined_classification_table <-
      build_combined_classification_table(
        data_classification_table = data_classification_automatic,
        data_auxiliary_classification_table = data_classification_auxiliary
      )

    vec_columns <-
      base::colnames(res_combined_classification_table)

    testthat::expect_true("sel_name" %in% vec_columns)
    testthat::expect_true("family" %in% vec_columns)
    testthat::expect_true("genus" %in% vec_columns)
    testthat::expect_true("species" %in% vec_columns)
    testthat::expect_false("extra_col" %in% vec_columns)
  }
)

testthat::test_that(
  "build_combined_classification_table() correct row count with overlapping names",
  {
    data_classification_automatic <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B", "Taxon C"),
        family = c("FA", "FB", "FC"),
        genus = c("GA", "GB", "GC"),
        species = c("SA", "SB", "SC")
      )
    data_classification_auxiliary <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon D"),
        family = c("FA_m", "FD"),
        genus = c("GA_m", "GD"),
        species = c("SA_m", "SD")
      )

    res_combined_classification_table <-
      build_combined_classification_table(
        data_classification_table = data_classification_automatic,
        data_auxiliary_classification_table = data_classification_auxiliary
      )

    # 3 auto + 1 new aux (Taxon D); Taxon A overlap -> 4 unique rows
    testthat::expect_equal(
      base::nrow(res_combined_classification_table),
      4L
    )
  }
)
