testthat::test_that(
  "combine_classification_tables() validates auto table is a data frame",
  {
    data_aux <-
      tibble::tibble(
        sel_name = "Taxon A",
        family = "FamilyA",
        genus = "GenusA",
        species = "SpeciesA"
      )

    testthat::expect_error(
      combine_classification_tables(
        data_classification_table = "not_a_df",
        data_aux_classification_table = data_aux
      )
    )
  }
)

testthat::test_that(
  "combine_classification_tables() validates sel_name in auto table",
  {
    data_auto <-
      tibble::tibble(
        family = "FamilyA",
        genus = "GenusA",
        species = "SpeciesA"
      )
    data_aux <-
      tibble::tibble(
        sel_name = "Taxon A",
        family = "FamilyA",
        genus = "GenusA",
        species = "SpeciesA"
      )

    testthat::expect_error(
      combine_classification_tables(
        data_classification_table = data_auto,
        data_aux_classification_table = data_aux
      ),
      regexp = "sel_name"
    )
  }
)

testthat::test_that(
  "combine_classification_tables() validates aux table is a data frame",
  {
    data_auto <-
      tibble::tibble(
        sel_name = "Taxon A",
        family = "FamilyA",
        genus = "GenusA",
        species = "SpeciesA"
      )

    testthat::expect_error(
      combine_classification_tables(
        data_classification_table = data_auto,
        data_aux_classification_table = "not_a_df"
      )
    )
  }
)

testthat::test_that(
  "combine_classification_tables() validates sel_name in aux table",
  {
    data_auto <-
      tibble::tibble(
        sel_name = "Taxon A",
        family = "FamilyA",
        genus = "GenusA",
        species = "SpeciesA"
      )
    data_aux <-
      tibble::tibble(
        family = "FamilyX",
        genus = "GenusX",
        species = "SpeciesX"
      )

    testthat::expect_error(
      combine_classification_tables(
        data_classification_table = data_auto,
        data_aux_classification_table = data_aux
      ),
      regexp = "sel_name"
    )
  }
)

testthat::test_that(
  "combine_classification_tables() returns a data frame",
  {
    data_auto <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B"),
        family = c("FamilyA", "FamilyB"),
        genus = c("GenusA", "GenusB"),
        species = c("SpeciesA", "SpeciesB")
      )
    data_aux <-
      tibble::tibble(
        sel_name = base::character(0),
        family = base::character(0),
        genus = base::character(0),
        species = base::character(0)
      )

    data_result <-
      combine_classification_tables(
        data_classification_table = data_auto,
        data_aux_classification_table = data_aux
      )

    testthat::expect_true(
      base::is.data.frame(data_result)
    )
  }
)

testthat::test_that(
  "combine_classification_tables() empty aux returns auto table rows",
  {
    data_auto <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B"),
        family = c("FamilyA", "FamilyB"),
        genus = c("GenusA", "GenusB"),
        species = c("SpeciesA", "SpeciesB")
      )
    data_aux <-
      tibble::tibble(
        sel_name = base::character(0),
        family = base::character(0),
        genus = base::character(0),
        species = base::character(0)
      )

    data_result <-
      combine_classification_tables(
        data_classification_table = data_auto,
        data_aux_classification_table = data_aux
      )

    testthat::expect_equal(
      base::nrow(data_result),
      base::nrow(data_auto)
    )

    testthat::expect_equal(
      base::sort(dplyr::pull(data_result, sel_name)),
      base::sort(dplyr::pull(data_auto, sel_name))
    )
  }
)

testthat::test_that(
  "combine_classification_tables() non-overlapping tables: all rows kept",
  {
    data_auto <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B"),
        family = c("FamilyA", "FamilyB"),
        genus = c("GenusA", "GenusB"),
        species = c("SpeciesA", "SpeciesB")
      )
    data_aux <-
      tibble::tibble(
        sel_name = c("Taxon C", "Taxon D"),
        family = c("FamilyC", "FamilyD"),
        genus = c("GenusC", "GenusD"),
        species = c("SpeciesC", "SpeciesD")
      )

    data_result <-
      combine_classification_tables(
        data_classification_table = data_auto,
        data_aux_classification_table = data_aux
      )

    testthat::expect_equal(
      base::nrow(data_result),
      base::nrow(data_auto) + base::nrow(data_aux)
    )
  }
)

testthat::test_that(
  "combine_classification_tables() aux row wins on sel_name collision",
  {
    data_auto <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B"),
        family = c("FamilyA_auto", "FamilyB_auto"),
        genus = c("GenusA_auto", "GenusB_auto"),
        species = c("SpeciesA_auto", "SpeciesB_auto")
      )
    data_aux <-
      tibble::tibble(
        sel_name = c("Taxon A"),
        family = c("FamilyA_manual"),
        genus = c("GenusA_manual"),
        species = c("SpeciesA_manual")
      )

    data_result <-
      combine_classification_tables(
        data_classification_table = data_auto,
        data_aux_classification_table = data_aux
      )

    vec_family <-
      data_result %>%
      dplyr::filter(sel_name == "Taxon A") %>%
      dplyr::pull(family)

    testthat::expect_equal(
      vec_family,
      "FamilyA_manual"
    )
  }
)

testthat::test_that(
  "combine_classification_tables() auto rows unaffected outside collision",
  {
    data_auto <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B"),
        family = c("FamilyA_auto", "FamilyB_auto"),
        genus = c("GenusA_auto", "GenusB_auto"),
        species = c("SpeciesA_auto", "SpeciesB_auto")
      )
    data_aux <-
      tibble::tibble(
        sel_name = c("Taxon A"),
        family = c("FamilyA_manual"),
        genus = c("GenusA_manual"),
        species = c("SpeciesA_manual")
      )

    data_result <-
      combine_classification_tables(
        data_classification_table = data_auto,
        data_aux_classification_table = data_aux
      )

    vec_family_b <-
      data_result %>%
      dplyr::filter(sel_name == "Taxon B") %>%
      dplyr::pull(family)

    testthat::expect_equal(
      vec_family_b,
      "FamilyB_auto"
    )
  }
)

testthat::test_that(
  "combine_classification_tables() aux-only taxa appear in result",
  {
    data_auto <-
      tibble::tibble(
        sel_name = c("Taxon A"),
        family = c("FamilyA"),
        genus = c("GenusA"),
        species = c("SpeciesA")
      )
    data_aux <-
      tibble::tibble(
        sel_name = c("Taxon Z"),
        family = c("FamilyZ"),
        genus = c("GenusZ"),
        species = c("SpeciesZ")
      )

    data_result <-
      combine_classification_tables(
        data_classification_table = data_auto,
        data_aux_classification_table = data_aux
      )

    testthat::expect_true(
      "Taxon Z" %in% dplyr::pull(data_result, sel_name)
    )
  }
)

testthat::test_that(
  "combine_classification_tables() output has no duplicate sel_name values",
  {
    data_auto <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B", "Taxon C"),
        family = c("FamilyA", "FamilyB", "FamilyC"),
        genus = c("GenusA", "GenusB", "GenusC"),
        species = c("SpeciesA", "SpeciesB", "SpeciesC")
      )
    data_aux <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon D"),
        family = c("FamilyA_m", "FamilyD"),
        genus = c("GenusA_m", "GenusD"),
        species = c("SpeciesA_m", "SpeciesD")
      )

    data_result <-
      combine_classification_tables(
        data_classification_table = data_auto,
        data_aux_classification_table = data_aux
      )

    vec_sel_names <-
      dplyr::pull(data_result, sel_name)

    testthat::expect_equal(
      base::length(vec_sel_names),
      base::length(base::unique(vec_sel_names))
    )
  }
)

testthat::test_that(
  "combine_classification_tables() output contains only shared columns",
  {
    data_auto <-
      tibble::tibble(
        sel_name = c("Taxon A"),
        family = c("FamilyA"),
        genus = c("GenusA"),
        species = c("SpeciesA"),
        extra_col = c("extra")
      )
    data_aux <-
      tibble::tibble(
        sel_name = c("Taxon B"),
        family = c("FamilyB"),
        genus = c("GenusB"),
        species = c("SpeciesB")
      )

    data_result <-
      combine_classification_tables(
        data_classification_table = data_auto,
        data_aux_classification_table = data_aux
      )

    vec_cols <-
      base::colnames(data_result)

    testthat::expect_true("sel_name" %in% vec_cols)
    testthat::expect_true("family" %in% vec_cols)
    testthat::expect_true("genus" %in% vec_cols)
    testthat::expect_true("species" %in% vec_cols)
    testthat::expect_false("extra_col" %in% vec_cols)
  }
)

testthat::test_that(
  "combine_classification_tables() correct row count with overlapping names",
  {
    data_auto <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon B", "Taxon C"),
        family = c("FA", "FB", "FC"),
        genus = c("GA", "GB", "GC"),
        species = c("SA", "SB", "SC")
      )
    data_aux <-
      tibble::tibble(
        sel_name = c("Taxon A", "Taxon D"),
        family = c("FA_m", "FD"),
        genus = c("GA_m", "GD"),
        species = c("SA_m", "SD")
      )

    data_result <-
      combine_classification_tables(
        data_classification_table = data_auto,
        data_aux_classification_table = data_aux
      )

    # 3 auto + 1 new aux (Taxon D); Taxon A overlap → 4 unique rows
    testthat::expect_equal(
      base::nrow(data_result),
      4L
    )
  }
)
