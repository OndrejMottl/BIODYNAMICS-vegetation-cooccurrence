# ---- Helpers ----------------------------------------------------------------

data_class_table_genus <-
  tibble::tibble(
    sel_name = base::c(
      "Betula cf. alba", "Betula", "Quercus robur", "Quercus"
    ),
    kingdom  = base::c("Plantae", "Plantae", "Plantae", "Plantae"),
    phylum   = base::c(
      "Tracheophyta", "Tracheophyta",
      "Tracheophyta", "Tracheophyta"
    ),
    class    = base::c(
      "Magnoliopsida", "Magnoliopsida",
      "Magnoliopsida", "Magnoliopsida"
    ),
    order    = base::c("Fagales", "Fagales", "Fagales", "Fagales"),
    family   = base::c(
      "Betulaceae", "Betulaceae",
      "Fagaceae", "Fagaceae"
    ),
    genus    = base::c("Betula", "Betula", "Quercus", "Quercus"),
    species  = base::c(
      "Betula alba", NA_character_,
      "Quercus robur", NA_character_
    )
  )

data_comm_genus <-
  tibble::tibble(taxon = base::c("Betula", "Quercus"))

# ---- Input validation -------------------------------------------------------

testthat::test_that(
  "remap_classification_table_by_community_taxa() errors on non-df input",
  {
    testthat::expect_error(
      remap_classification_table_by_community_taxa(
        data_classification_table = "not_a_df",
        data_community_classified = data_comm_genus,
        taxonomic_resolution = "genus"
      )
    )

    testthat::expect_error(
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_table_genus,
        data_community_classified = "not_a_df",
        taxonomic_resolution = "genus"
      )
    )

    testthat::expect_error(
      remap_classification_table_by_community_taxa(
        data_classification_table = 42L,
        data_community_classified = data_comm_genus,
        taxonomic_resolution = "genus"
      )
    )
  }
)

testthat::test_that(
  "remap_classification_table_by_community_taxa() errors on missing columns",
  {
    data_no_sel_name <-
      tibble::tibble(
        kingdom = "Plantae", phylum = "Tracheophyta",
        class = "A", order = "B", family = "C",
        genus = "D", species = "E"
      )

    testthat::expect_error(
      remap_classification_table_by_community_taxa(
        data_classification_table = data_no_sel_name,
        data_community_classified = data_comm_genus,
        taxonomic_resolution = "genus"
      )
    )

    data_no_genus <-
      tibble::tibble(
        sel_name = "Betula", kingdom = "Plantae",
        phylum = "Tracheophyta", class = "A",
        order = "B", family = "C", species = "D"
      )

    testthat::expect_error(
      remap_classification_table_by_community_taxa(
        data_classification_table = data_no_genus,
        data_community_classified = data_comm_genus,
        taxonomic_resolution = "genus"
      )
    )

    data_no_taxon <-
      tibble::tibble(name = base::c("Betula", "Quercus"))

    testthat::expect_error(
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_table_genus,
        data_community_classified = data_no_taxon,
        taxonomic_resolution = "genus"
      )
    )
  }
)

testthat::test_that(
  "remap_classification_table_by_community_taxa() errors on bad resolution",
  {
    testthat::expect_error(
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_table_genus,
        data_community_classified = data_comm_genus,
        taxonomic_resolution = 1L
      )
    )

    testthat::expect_error(
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_table_genus,
        data_community_classified = data_comm_genus,
        taxonomic_resolution = "tribe"
      )
    )

    testthat::expect_error(
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_table_genus,
        data_community_classified = data_comm_genus,
        taxonomic_resolution = base::c("genus", "family")
      )
    )

    testthat::expect_error(
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_table_genus,
        data_community_classified = data_comm_genus,
        taxonomic_resolution = NA_character_
      )
    )
  }
)

# ---- Output structure — genus resolution ------------------------------------

testthat::test_that(
  "remap_classification_table_by_community_taxa() returns a data frame",
  {
    res <-
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_table_genus,
        data_community_classified = data_comm_genus,
        taxonomic_resolution = "genus"
      )

    testthat::expect_true(base::is.data.frame(res))
  }
)

testthat::test_that(
  "remap_classification_table_by_community_taxa() has correct columns",
  {
    res <-
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_table_genus,
        data_community_classified = data_comm_genus,
        taxonomic_resolution = "genus"
      )

    vec_expected_cols <-
      base::c(
        "sel_name", "kingdom", "phylum", "class",
        "order", "family", "genus", "species"
      )

    testthat::expect_equal(
      base::sort(base::colnames(res)),
      base::sort(vec_expected_cols)
    )
  }
)

testthat::test_that(
  "remap_classification_table_by_community_taxa() sel_name is genus name",
  {
    res <-
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_table_genus,
        data_community_classified = data_comm_genus,
        taxonomic_resolution = "genus"
      )

    vec_sel_names <-
      dplyr::pull(res, sel_name)

    testthat::expect_true(
      base::all(vec_sel_names %in% base::c("Betula", "Quercus"))
    )
  }
)

testthat::test_that(
  "remap_classification_table_by_community_taxa() species is NA at genus",
  {
    res <-
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_table_genus,
        data_community_classified = data_comm_genus,
        taxonomic_resolution = "genus"
      )

    vec_species <-
      dplyr::pull(res, species)

    testthat::expect_true(base::all(base::is.na(vec_species)))
  }
)

testthat::test_that(
  "remap_classification_table_by_community_taxa() one row per genus",
  {
    res <-
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_table_genus,
        data_community_classified = data_comm_genus,
        taxonomic_resolution = "genus"
      )

    testthat::expect_equal(base::nrow(res), 2L)

    vec_sel_names <-
      dplyr::pull(res, sel_name)

    testthat::expect_equal(
      base::length(vec_sel_names),
      base::length(base::unique(vec_sel_names))
    )
  }
)

testthat::test_that(
  "remap_classification_table_by_community_taxa() filters to community taxa",
  {
    data_comm_one <-
      tibble::tibble(taxon = "Betula")

    res <-
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_table_genus,
        data_community_classified = data_comm_one,
        taxonomic_resolution = "genus"
      )

    testthat::expect_equal(base::nrow(res), 1L)

    testthat::expect_equal(
      dplyr::pull(res, sel_name),
      "Betula"
    )
  }
)

# ---- Output structure — family resolution -----------------------------------

testthat::test_that(
  "remap_classification_table_by_community_taxa() nulls genus at family",
  {
    data_class_family <-
      tibble::tibble(
        sel_name = base::c("Betula", "Quercus", "Alnus"),
        kingdom  = base::rep("Plantae", 3L),
        phylum   = base::rep("Tracheophyta", 3L),
        class    = base::rep("Magnoliopsida", 3L),
        order    = base::rep("Fagales", 3L),
        family   = base::c("Betulaceae", "Fagaceae", "Betulaceae"),
        genus    = base::c("Betula", "Quercus", "Alnus"),
        species  = base::rep(NA_character_, 3L)
      )

    data_comm_family <-
      tibble::tibble(taxon = base::c("Betulaceae", "Fagaceae"))

    res <-
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_family,
        data_community_classified = data_comm_family,
        taxonomic_resolution = "family"
      )

    vec_genus <-
      dplyr::pull(res, genus)

    vec_species <-
      dplyr::pull(res, species)

    testthat::expect_true(base::all(base::is.na(vec_genus)))
    testthat::expect_true(base::all(base::is.na(vec_species)))
  }
)

testthat::test_that(
  "remap_classification_table_by_community_taxa() sel_name is family name",
  {
    data_class_family <-
      tibble::tibble(
        sel_name = base::c("Betula", "Quercus", "Alnus"),
        kingdom  = base::rep("Plantae", 3L),
        phylum   = base::rep("Tracheophyta", 3L),
        class    = base::rep("Magnoliopsida", 3L),
        order    = base::rep("Fagales", 3L),
        family   = base::c("Betulaceae", "Fagaceae", "Betulaceae"),
        genus    = base::c("Betula", "Quercus", "Alnus"),
        species  = base::rep(NA_character_, 3L)
      )

    data_comm_family <-
      tibble::tibble(taxon = base::c("Betulaceae", "Fagaceae"))

    res <-
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_family,
        data_community_classified = data_comm_family,
        taxonomic_resolution = "family"
      )

    vec_sel_names <-
      dplyr::pull(res, sel_name)

    testthat::expect_true(
      base::all(
        vec_sel_names %in% base::c("Betulaceae", "Fagaceae")
      )
    )
  }
)

# ---- Functional correctness — direct match preferred -----------------------

testthat::test_that(
  "remap_classification_table_by_community_taxa() prefers direct match row",
  {
    data_class_direct <-
      tibble::tibble(
        sel_name = base::c(
          "Betula pollen type", "Betula"
        ),
        kingdom  = base::c("Plantae", "Plantae"),
        phylum   = base::c("Tracheophyta", "Tracheophyta"),
        class    = base::c("Magnoliopsida", "Magnoliopsida"),
        order    = base::c("Fagales", "Fagales"),
        family   = base::c("Betulaceae", "Betulaceae"),
        genus    = base::c("Betula", "Betula"),
        species  = base::c(NA_character_, NA_character_)
      )

    data_comm_direct <-
      tibble::tibble(taxon = "Betula")

    res <-
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_direct,
        data_community_classified = data_comm_direct,
        taxonomic_resolution = "genus"
      )

    testthat::expect_equal(base::nrow(res), 1L)

    testthat::expect_equal(
      dplyr::pull(res, sel_name),
      "Betula"
    )
  }
)

# ---- Functional correctness — only community taxa retained -----------------

testthat::test_that(
  "remap_classification_table_by_community_taxa() retains only community taxa",
  {
    data_class_abc <-
      tibble::tibble(
        sel_name = base::c("GenusA", "GenusB", "GenusC"),
        kingdom  = base::rep("Plantae", 3L),
        phylum   = base::rep("Tracheophyta", 3L),
        class    = base::rep("Magnoliopsida", 3L),
        order    = base::rep("Fagales", 3L),
        family   = base::c("FamA", "FamB", "FamC"),
        genus    = base::c("GenusA", "GenusB", "GenusC"),
        species  = base::rep(NA_character_, 3L)
      )

    data_comm_ac <-
      tibble::tibble(taxon = base::c("GenusA", "GenusC"))

    res <-
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_abc,
        data_community_classified = data_comm_ac,
        taxonomic_resolution = "genus"
      )

    testthat::expect_equal(base::nrow(res), 2L)

    vec_sel_names <-
      dplyr::pull(res, sel_name)

    testthat::expect_true("GenusA" %in% vec_sel_names)
    testthat::expect_true("GenusC" %in% vec_sel_names)
    testthat::expect_false("GenusB" %in% vec_sel_names)
  }
)

# ---- Edge cases -------------------------------------------------------------

testthat::test_that(
  "remap_classification_table_by_community_taxa() zero-row community",
  {
    data_comm_empty <-
      tibble::tibble(taxon = base::character(0L))

    res <-
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_table_genus,
        data_community_classified = data_comm_empty,
        taxonomic_resolution = "genus"
      )

    testthat::expect_equal(base::nrow(res), 0L)
  }
)

testthat::test_that(
  "remap_classification_table_by_community_taxa() species res keeps species",
  {
    data_class_sp <-
      tibble::tibble(
        sel_name = "Betula alba",
        kingdom  = "Plantae",
        phylum   = "Tracheophyta",
        class    = "Magnoliopsida",
        order    = "Fagales",
        family   = "Betulaceae",
        genus    = "Betula",
        species  = "Betula alba"
      )

    data_comm_sp <-
      tibble::tibble(taxon = "Betula alba")

    res <-
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_sp,
        data_community_classified = data_comm_sp,
        taxonomic_resolution = "species"
      )

    vec_species <-
      dplyr::pull(res, species)

    testthat::expect_false(base::all(base::is.na(vec_species)))

    testthat::expect_equal(vec_species, "Betula alba")
  }
)

testthat::test_that(
  "remap_classification_table_by_community_taxa() skips all-NA rank rows",
  {
    data_class_na_genus <-
      tibble::tibble(
        sel_name = base::c(
          "UnknownPollen", "Betula"
        ),
        kingdom  = base::c("Plantae", "Plantae"),
        phylum   = base::c("Tracheophyta", "Tracheophyta"),
        class    = base::c("Magnoliopsida", "Magnoliopsida"),
        order    = base::c("Fagales", "Fagales"),
        family   = base::c("Betulaceae", "Betulaceae"),
        genus    = base::c(NA_character_, "Betula"),
        species  = base::c(NA_character_, NA_character_)
      )

    data_comm_both <-
      tibble::tibble(taxon = base::c("Betula"))

    res <-
      remap_classification_table_by_community_taxa(
        data_classification_table = data_class_na_genus,
        data_community_classified = data_comm_both,
        taxonomic_resolution = "genus"
      )

    vec_sel_names <-
      dplyr::pull(res, sel_name)

    testthat::expect_true("Betula" %in% vec_sel_names)
    testthat::expect_false(NA_character_ %in% vec_sel_names)
  }
)
