# --- Fixtures ---

data_traits_fix <-
  tibble::tibble(
    taxon_name = base::c(
      "Abies alba",
      "Abies cephalonica",
      "Asteraceae sp1"
    ),
    trait_domain_name = base::c("SLA", "SLA", "SLA"),
    trait_value = base::c(10.0, 12.0, 5.0)
  )

data_class_fix <-
  tibble::tibble(
    sel_name = base::c(
      "Abies alba",
      "Abies cephalonica",
      "Asteraceae sp1"
    ),
    kingdom = base::c(
      "Plantae", "Plantae", "Plantae"
    ),
    phylum = base::c(
      NA_character_,
      NA_character_,
      NA_character_
    ),
    class = base::c(
      NA_character_,
      NA_character_,
      NA_character_
    ),
    order = base::c(
      NA_character_,
      NA_character_,
      NA_character_
    ),
    family = base::c(
      "Pinaceae", "Pinaceae", "Asteraceae"
    ),
    genus = base::c(
      "Abies", "Abies", NA_character_
    ),
    species = base::c(
      "Abies alba",
      "Abies cephalonica",
      NA_character_
    )
  )

# --- Input validation: data_traits ---

testthat::test_that(
  "build_community_taxon_trait_table() errors if data_traits not df",
  {
    testthat::expect_error(
      build_community_taxon_trait_table(
        data_traits = "not_a_df",
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies")
      )
    )
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() errors if taxon_name missing",
  {
    data_bad <-
      dplyr::select(data_traits_fix, -taxon_name)

    testthat::expect_error(
      build_community_taxon_trait_table(
        data_traits = data_bad,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies")
      )
    )
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() errors if trait_domain_name missing",
  {
    data_bad <-
      dplyr::select(data_traits_fix, -trait_domain_name)

    testthat::expect_error(
      build_community_taxon_trait_table(
        data_traits = data_bad,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies")
      )
    )
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() errors if trait_value missing",
  {
    data_bad <-
      dplyr::select(data_traits_fix, -trait_value)

    testthat::expect_error(
      build_community_taxon_trait_table(
        data_traits = data_bad,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies")
      )
    )
  }
)

# --- Input validation: data_classification_table ---

testthat::test_that(
  "build_community_taxon_trait_table() errors if classif table not df",
  {
    testthat::expect_error(
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = base::c("a", "b"),
        vec_community_taxa = base::c("Abies")
      )
    )
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() errors if sel_name missing",
  {
    data_bad <-
      dplyr::select(data_class_fix, -sel_name)

    testthat::expect_error(
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_bad,
        vec_community_taxa = base::c("Abies")
      )
    )
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() errors if genus column missing",
  {
    data_bad <-
      dplyr::select(data_class_fix, -genus)

    testthat::expect_error(
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_bad,
        vec_community_taxa = base::c("Abies")
      )
    )
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() errors if family column missing",
  {
    data_bad <-
      dplyr::select(data_class_fix, -family)

    testthat::expect_error(
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_bad,
        vec_community_taxa = base::c("Abies")
      )
    )
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() errors if order column missing",
  {
    data_bad <-
      dplyr::select(data_class_fix, -order)

    testthat::expect_error(
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_bad,
        vec_community_taxa = base::c("Abies")
      )
    )
  }
)

# --- Input validation: vec_community_taxa ---

testthat::test_that(
  "build_community_taxon_trait_table() errors if vec_taxa not character",
  {
    testthat::expect_error(
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = 1L
      )
    )
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() errors if vec_taxa is empty",
  {
    testthat::expect_error(
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::character(0)
      )
    )
  }
)

# --- Input validation: verbose ---

testthat::test_that(
  "build_community_taxon_trait_table() errors if verbose not logical",
  {
    testthat::expect_error(
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies"),
        verbose = "yes"
      )
    )
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() errors if verbose is length > 1",
  {
    testthat::expect_error(
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies"),
        verbose = base::c(TRUE, FALSE)
      )
    )
  }
)

# --- Output structure ---

testthat::test_that(
  "build_community_taxon_trait_table() returns a tibble",
  {
    res <-
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies"),
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "tbl_df")
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() output has taxon_name column",
  {
    res <-
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies"),
        verbose = FALSE
      )

    testthat::expect_true(
      "taxon_name" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() Abies: one row named Abies",
  {
    res <-
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies"),
        verbose = FALSE
      )

    testthat::expect_equal(base::nrow(res), 1L)

    vec_names <-
      dplyr::pull(res, taxon_name)

    testthat::expect_equal(vec_names, "Abies")
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() Abies SLA = median(10, 12) = 11",
  {
    res <-
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies"),
        verbose = FALSE
      )

    vec_sla <-
      dplyr::pull(res, SLA)

    testthat::expect_equal(vec_sla, 11.0)
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() Pinaceae: one row, SLA = 11",
  {
    res <-
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Pinaceae"),
        verbose = FALSE
      )

    testthat::expect_equal(base::nrow(res), 1L)

    vec_names <-
      dplyr::pull(res, taxon_name)

    testthat::expect_equal(vec_names, "Pinaceae")

    vec_sla <-
      dplyr::pull(res, SLA)

    testthat::expect_equal(vec_sla, 11.0)
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() Abies+Pinaceae: two rows",
  {
    res <-
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies", "Pinaceae"),
        verbose = FALSE
      )

    testthat::expect_equal(base::nrow(res), 2L)

    vec_names <-
      base::sort(dplyr::pull(res, taxon_name))

    testthat::expect_equal(
      vec_names,
      base::c("Abies", "Pinaceae")
    )
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() Abies SLA == Pinaceae SLA",
  {
    res <-
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies", "Pinaceae"),
        verbose = FALSE
      )

    data_abies <-
      dplyr::filter(res, taxon_name == "Abies")

    data_pinaceae <-
      dplyr::filter(res, taxon_name == "Pinaceae")

    vec_abies_sla <-
      dplyr::pull(data_abies, SLA)

    vec_pinaceae_sla <-
      dplyr::pull(data_pinaceae, SLA)

    testthat::expect_equal(vec_abies_sla, 11.0)
    testthat::expect_equal(vec_pinaceae_sla, 11.0)
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() unmatched taxa absent (no NA row)",
  {
    res <-
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies", "NoMatch"),
        verbose = FALSE
      )

    vec_names <-
      dplyr::pull(res, taxon_name)

    testthat::expect_false("NoMatch" %in% vec_names)
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() no matches: 0-row tibble",
  {
    res <-
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("NoMatch"),
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(base::nrow(res), 0L)
    testthat::expect_true(
      "taxon_name" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() no duplicate taxon_name rows",
  {
    res <-
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies", "Pinaceae"),
        verbose = FALSE
      )

    vec_names <-
      dplyr::pull(res, taxon_name)

    testthat::expect_equal(
      base::length(vec_names),
      base::length(base::unique(vec_names))
    )
  }
)

# --- Multiple trait domains ---

testthat::test_that(
  "build_community_taxon_trait_table() multiple domains as separate cols",
  {
    data_traits_multi <-
      tibble::tibble(
        taxon_name = base::c(
          "Abies alba",
          "Abies alba",
          "Abies cephalonica",
          "Abies cephalonica"
        ),
        trait_domain_name = base::c(
          "SLA", "PlantHeight",
          "SLA", "PlantHeight"
        ),
        trait_value = base::c(10.0, 20.0, 12.0, 18.0)
      )

    res <-
      build_community_taxon_trait_table(
        data_traits = data_traits_multi,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies"),
        verbose = FALSE
      )

    vec_cols <-
      base::colnames(res)

    testthat::expect_true("SLA" %in% vec_cols)
    testthat::expect_true("PlantHeight" %in% vec_cols)
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() PlantHeight median correct",
  {
    data_traits_multi <-
      tibble::tibble(
        taxon_name = base::c(
          "Abies alba",
          "Abies alba",
          "Abies cephalonica",
          "Abies cephalonica"
        ),
        trait_domain_name = base::c(
          "SLA", "PlantHeight",
          "SLA", "PlantHeight"
        ),
        trait_value = base::c(10.0, 20.0, 12.0, 18.0)
      )

    res <-
      build_community_taxon_trait_table(
        data_traits = data_traits_multi,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies"),
        verbose = FALSE
      )

    vec_ph <-
      dplyr::pull(res, PlantHeight)

    testthat::expect_equal(vec_ph, 19.0)
  }
)

# --- verbose behaviour ---

testthat::test_that(
  "build_community_taxon_trait_table() verbose=TRUE emits a message",
  {
    testthat::expect_message(
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies"),
        verbose = TRUE
      )
    )
  }
)

testthat::test_that(
  "build_community_taxon_trait_table() verbose=FALSE no message",
  {
    testthat::expect_no_message(
      build_community_taxon_trait_table(
        data_traits = data_traits_fix,
        data_classification_table = data_class_fix,
        vec_community_taxa = base::c("Abies"),
        verbose = FALSE
      )
    )
  }
)
