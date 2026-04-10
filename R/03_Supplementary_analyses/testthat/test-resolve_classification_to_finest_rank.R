#----------------------------------------------------------#
# Tests for resolve_classification_to_finest_rank() -----
#----------------------------------------------------------#

testthat::test_that(
  "resolve_classification_to_finest_rank() rejects non-data-frame input",
  {
    testthat::expect_error(
      resolve_classification_to_finest_rank(
        data_classification_table = "not a data frame"
      )
    )

    testthat::expect_error(
      resolve_classification_to_finest_rank(
        data_classification_table = base::list(
          sel_name = "Taxon"
        )
      )
    )

    testthat::expect_error(
      resolve_classification_to_finest_rank(
        data_classification_table = NULL
      )
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() rejects missing required columns",
  {
    data_missing_sel_name <-
      tibble::tibble(
        kingdom = "Plantae",
        phylum = NA_character_,
        class = NA_character_,
        order = NA_character_,
        family = NA_character_,
        genus = NA_character_,
        species = NA_character_
      )

    testthat::expect_error(
      resolve_classification_to_finest_rank(
        data_classification_table = data_missing_sel_name
      )
    )

    data_missing_rank_columns <-
      tibble::tibble(
        sel_name = "Taxon A",
        kingdom = "Plantae"
      )

    testthat::expect_error(
      resolve_classification_to_finest_rank(
        data_classification_table = data_missing_rank_columns
      )
    )

    data_missing_species <-
      tibble::tibble(
        sel_name = "Taxon A",
        kingdom = "Plantae",
        phylum = "Tracheophyta",
        class = "Liliopsida",
        order = "Poales",
        family = "Poaceae",
        genus = "Poa"
      )

    testthat::expect_error(
      resolve_classification_to_finest_rank(
        data_classification_table = data_missing_species
      )
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() returns correct output structure",
  {
    data_input <-
      tibble::tibble(
        sel_name = base::c("Taxon A", "Taxon B"),
        kingdom = base::c("Plantae", "Plantae"),
        phylum = base::c(NA_character_, "Tracheophyta"),
        class = base::c(NA_character_, NA_character_),
        order = base::c(NA_character_, NA_character_),
        family = base::c("Poaceae", "Asteraceae"),
        genus = base::c("Poa", NA_character_),
        species = base::c(NA_character_, NA_character_)
      )

    data_result <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_input
      )

    testthat::expect_s3_class(data_result, "data.frame")
    testthat::expect_true(
      base::all(
        base::c("sel_name", "taxon_resolved") %in%
          base::colnames(data_result)
      )
    )
    testthat::expect_equal(base::ncol(data_result), 2L)
    testthat::expect_equal(base::nrow(data_result), 2L)
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() prefers genus over all others",
  {
    data_input <-
      tibble::tibble(
        sel_name = "Taxon A",
        kingdom = "Plantae",
        phylum = "Tracheophyta",
        class = "Liliopsida",
        order = "Poales",
        family = "Poaceae",
        genus = "Poa",
        species = NA_character_
      )

    data_result <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_input
      )

    testthat::expect_equal(
      dplyr::pull(data_result, taxon_resolved),
      "Poa"
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() falls back to family when no genus",
  {
    data_input <-
      tibble::tibble(
        sel_name = "Taxon B",
        kingdom = "Plantae",
        phylum = "Tracheophyta",
        class = "Magnoliopsida",
        order = "Asterales",
        family = "Asteraceae",
        genus = NA_character_,
        species = NA_character_
      )

    data_result <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_input
      )

    testthat::expect_equal(
      dplyr::pull(data_result, taxon_resolved),
      "Asteraceae"
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() falls back through rank hierarchy",
  {
    data_kingdom_only <-
      tibble::tibble(
        sel_name = "Taxon C",
        kingdom = "Plantae",
        phylum = NA_character_,
        class = NA_character_,
        order = NA_character_,
        family = NA_character_,
        genus = NA_character_,
        species = NA_character_
      )

    data_result_kingdom <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_kingdom_only
      )

    testthat::expect_equal(
      dplyr::pull(data_result_kingdom, taxon_resolved),
      "Plantae"
    )

    data_order_finest <-
      tibble::tibble(
        sel_name = "Taxon D",
        kingdom = "Plantae",
        phylum = "Tracheophyta",
        class = "Magnoliopsida",
        order = "Lamiales",
        family = NA_character_,
        genus = NA_character_,
        species = NA_character_
      )

    data_result_order <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_order_finest
      )

    testthat::expect_equal(
      dplyr::pull(data_result_order, taxon_resolved),
      "Lamiales"
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() resolves multiple taxa",
  {
    data_input <-
      tibble::tibble(
        sel_name = base::c("Taxon A", "Taxon B", "Taxon C"),
        kingdom = base::c("Plantae", "Plantae", "Plantae"),
        phylum = base::c(
          "Tracheophyta", "Tracheophyta", NA_character_
        ),
        class = base::c(
          NA_character_, "Magnoliopsida", NA_character_
        ),
        order = base::c(
          NA_character_, NA_character_, NA_character_
        ),
        family = base::c(
          "Poaceae", NA_character_, NA_character_
        ),
        genus = base::c("Poa", NA_character_, NA_character_),
        species = base::rep(NA_character_, 3L)
      )

    data_result <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_input
      )

    testthat::expect_equal(base::nrow(data_result), 3L)

    data_result_a <-
      dplyr::filter(data_result, .data[["sel_name"]] == "Taxon A")

    testthat::expect_equal(
      dplyr::pull(data_result_a, taxon_resolved),
      "Poa"
    )

    data_result_b <-
      dplyr::filter(data_result, .data[["sel_name"]] == "Taxon B")

    testthat::expect_equal(
      dplyr::pull(data_result_b, taxon_resolved),
      "Magnoliopsida"
    )

    data_result_c <-
      dplyr::filter(data_result, .data[["sel_name"]] == "Taxon C")

    testthat::expect_equal(
      dplyr::pull(data_result_c, taxon_resolved),
      "Plantae"
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() returns one row per sel_name",
  {
    data_input <-
      tibble::tibble(
        sel_name = base::c("Taxon A", "Taxon B", "Taxon C"),
        kingdom = "Plantae",
        phylum = "Tracheophyta",
        class = "Liliopsida",
        order = "Poales",
        family = "Poaceae",
        genus = base::c("Poa", "Festuca", "Agrostis"),
        species = base::rep(NA_character_, 3L)
      )

    data_result <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_input
      )

    testthat::expect_equal(base::nrow(data_result), 3L)
    testthat::expect_equal(
      base::length(
        base::unique(dplyr::pull(data_result, sel_name))
      ),
      3L
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() handles empty input gracefully",
  {
    data_empty <-
      tibble::tibble(
        sel_name = base::character(0),
        kingdom = base::character(0),
        phylum = base::character(0),
        class = base::character(0),
        order = base::character(0),
        family = base::character(0),
        genus = base::character(0),
        species = base::character(0)
      )

    data_result <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_empty
      )

    testthat::expect_s3_class(data_result, "data.frame")
    testthat::expect_equal(base::nrow(data_result), 0L)
    testthat::expect_true(
      "sel_name" %in% base::colnames(data_result)
    )
    testthat::expect_true(
      "taxon_resolved" %in% base::colnames(data_result)
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() prefers species over genus",
  {
    data_input <-
      tibble::tibble(
        sel_name = "Poa annua",
        kingdom = "Plantae",
        phylum = "Tracheophyta",
        class = "Liliopsida",
        order = "Poales",
        family = "Poaceae",
        genus = "Poa",
        species = "Poa annua"
      )

    data_result <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_input
      )

    testthat::expect_equal(
      dplyr::pull(data_result, taxon_resolved),
      "Poa annua"
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() respects column_name_taxon argument",
  {
    data_input <-
      tibble::tibble(
        sel_name = "Taxon A",
        kingdom = "Plantae",
        phylum = NA_character_,
        class = NA_character_,
        order = NA_character_,
        family = "Poaceae",
        genus = "Poa",
        species = NA_character_
      )

    data_result_default <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_input
      )

    testthat::expect_true(
      "taxon_resolved" %in% base::colnames(data_result_default)
    )

    data_result_custom <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_input,
        column_name_taxon = "resolved_rank"
      )

    testthat::expect_true(
      "resolved_rank" %in% base::colnames(data_result_custom)
    )

    testthat::expect_false(
      "taxon_resolved" %in% base::colnames(data_result_custom)
    )

    testthat::expect_equal(
      dplyr::pull(data_result_custom, resolved_rank),
      "Poa"
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() rejects invalid column_name_taxon",
  {
    data_input <-
      tibble::tibble(
        sel_name = "Taxon A",
        kingdom = "Plantae",
        phylum = NA_character_,
        class = NA_character_,
        order = NA_character_,
        family = NA_character_,
        genus = "Poa",
        species = NA_character_
      )

    testthat::expect_error(
      resolve_classification_to_finest_rank(
        data_classification_table = data_input,
        column_name_taxon = 123L
      )
    )

    testthat::expect_error(
      resolve_classification_to_finest_rank(
        data_classification_table = data_input,
        column_name_taxon = ""
      )
    )

    testthat::expect_error(
      resolve_classification_to_finest_rank(
        data_classification_table = data_input,
        column_name_taxon = base::c("a", "b")
      )
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() species beats all coarser ranks",
  {
    data_input <-
      tibble::tibble(
        sel_name = "Poa annua",
        kingdom = "Plantae",
        phylum = "Tracheophyta",
        class = "Liliopsida",
        order = "Poales",
        family = "Poaceae",
        genus = "Poa",
        species = "Poa annua"
      )

    data_result <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_input
      )

    testthat::expect_equal(
      dplyr::pull(data_result, taxon_resolved),
      "Poa annua"
    )
  }
)
