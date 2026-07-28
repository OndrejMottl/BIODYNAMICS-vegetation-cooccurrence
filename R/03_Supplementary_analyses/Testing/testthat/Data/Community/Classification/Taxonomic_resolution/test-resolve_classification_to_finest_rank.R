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
    data_classification_missing_selected_name <-
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
        data_classification_table = data_classification_missing_selected_name
      )
    )

    data_classification_missing_rank_columns <-
      tibble::tibble(
        sel_name = "Taxon A",
        kingdom = "Plantae"
      )

    testthat::expect_error(
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_missing_rank_columns
      )
    )

    data_classification_missing_species <-
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
        data_classification_table = data_classification_missing_species
      )
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() returns correct output structure",
  {
    data_classification_input <-
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

    res_classification_resolved <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_input
      )

    testthat::expect_s3_class(res_classification_resolved, "data.frame")
    testthat::expect_true(
      base::all(
        base::c("sel_name", "taxon_resolved") %in%
          base::colnames(res_classification_resolved)
      )
    )
    testthat::expect_equal(base::ncol(res_classification_resolved), 2L)
    testthat::expect_equal(base::nrow(res_classification_resolved), 2L)
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() prefers genus over all others",
  {
    data_classification_input <-
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

    res_classification_resolved <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_input
      )

    testthat::expect_equal(
      dplyr::pull(res_classification_resolved, taxon_resolved),
      "Poa"
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() falls back to family when no genus",
  {
    data_classification_input <-
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

    res_classification_resolved <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_input
      )

    testthat::expect_equal(
      dplyr::pull(res_classification_resolved, taxon_resolved),
      "Asteraceae"
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() falls back through rank hierarchy",
  {
    data_classification_kingdom_only <-
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

    res_classification_kingdom <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_kingdom_only
      )

    testthat::expect_equal(
      dplyr::pull(res_classification_kingdom, taxon_resolved),
      "Plantae"
    )

    data_classification_order_finest <-
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

    res_classification_order <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_order_finest
      )

    testthat::expect_equal(
      dplyr::pull(res_classification_order, taxon_resolved),
      "Lamiales"
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() resolves multiple taxa",
  {
    data_classification_input <-
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

    res_classification_resolved <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_input
      )

    testthat::expect_equal(base::nrow(res_classification_resolved), 3L)

    res_classification_a <-
      dplyr::filter(res_classification_resolved, .data[["sel_name"]] == "Taxon A")

    testthat::expect_equal(
      dplyr::pull(res_classification_a, taxon_resolved),
      "Poa"
    )

    res_classification_b <-
      dplyr::filter(res_classification_resolved, .data[["sel_name"]] == "Taxon B")

    testthat::expect_equal(
      dplyr::pull(res_classification_b, taxon_resolved),
      "Magnoliopsida"
    )

    res_classification_c <-
      dplyr::filter(res_classification_resolved, .data[["sel_name"]] == "Taxon C")

    testthat::expect_equal(
      dplyr::pull(res_classification_c, taxon_resolved),
      "Plantae"
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() returns one row per sel_name",
  {
    data_classification_input <-
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

    res_classification_resolved <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_input
      )

    testthat::expect_equal(base::nrow(res_classification_resolved), 3L)
    testthat::expect_equal(
      base::length(
        base::unique(dplyr::pull(res_classification_resolved, sel_name))
      ),
      3L
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() handles empty input gracefully",
  {
    data_classification_empty <-
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

    res_classification_resolved <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_empty
      )

    testthat::expect_s3_class(res_classification_resolved, "data.frame")
    testthat::expect_equal(base::nrow(res_classification_resolved), 0L)
    testthat::expect_true(
      "sel_name" %in% base::colnames(res_classification_resolved)
    )
    testthat::expect_true(
      "taxon_resolved" %in% base::colnames(res_classification_resolved)
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() prefers species over genus",
  {
    data_classification_input <-
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

    res_classification_resolved <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_input
      )

    testthat::expect_equal(
      dplyr::pull(res_classification_resolved, taxon_resolved),
      "Poa annua"
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() respects vec_taxon_column_name argument",
  {
    data_classification_input <-
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

    res_classification_default <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_input
      )

    testthat::expect_true(
      "taxon_resolved" %in% base::colnames(res_classification_default)
    )

    res_classification_custom <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_input,
        vec_taxon_column_name = "resolved_rank"
      )

    testthat::expect_true(
      "resolved_rank" %in% base::colnames(res_classification_custom)
    )

    testthat::expect_false(
      "taxon_resolved" %in% base::colnames(res_classification_custom)
    )

    testthat::expect_equal(
      dplyr::pull(res_classification_custom, resolved_rank),
      "Poa"
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() rejects invalid vec_taxon_column_name",
  {
    data_classification_input <-
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
        data_classification_table = data_classification_input,
        vec_taxon_column_name = 123L
      )
    )

    testthat::expect_error(
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_input,
        vec_taxon_column_name = ""
      )
    )

    testthat::expect_error(
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_input,
        vec_taxon_column_name = base::c("a", "b")
      )
    )
  }
)

testthat::test_that(
  "resolve_classification_to_finest_rank() species beats all coarser ranks",
  {
    data_classification_input <-
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

    res_classification_resolved <-
      resolve_classification_to_finest_rank(
        data_classification_table = data_classification_input
      )

    testthat::expect_equal(
      dplyr::pull(res_classification_resolved, taxon_resolved),
      "Poa annua"
    )
  }
)
