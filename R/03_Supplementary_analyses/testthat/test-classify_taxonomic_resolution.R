testthat::test_that("classify_taxonomic_resolution() return correct class", {
  set.seed(900723)
  data_dummy <-
    data.frame(
      dataset_name = "dataset_1",
      age = 0,
      taxon = paste0("Taxon_", 1:6),
      pollen_prop = runif(6, 0, 1)
    )

  classification_table_dummy <-
    data.frame(
      sel_name = paste0("Taxon_", 1:6),
      family = c(
        "Family_A", "Family_A", "Family_A",
        "Family_B", "Family_B", "Family_B"
      ),
      genus = c(
        "Genus_A", "Genus_A", "Genus_B",
        "Genus_C", "Genus_D", "Genus_D"
      ),
      species = c(
        "Species_A", "Species_B", "Species_C",
        "Species_D", "Species_E", "Species_F"
      )
    )

  res <-
    classify_taxonomic_resolution(
      data = data_dummy,
      data_classification_table = classification_table_dummy,
      taxonomic_resolution = "genus"
    )

  testthat::expect_s3_class(res, "data.frame")

  testthat::expect_true(
    all(c("dataset_name", "age", "taxon", "pollen_prop") %in% colnames(res))
  )
})

testthat::test_that("classify_taxonomic_resolution() return correct data", {
  set.seed(900723)
  data_dummy <-
    data.frame(
      dataset_name = "dataset_1",
      age = 0,
      taxon = paste0("Taxon_", 1:6),
      pollen_prop = runif(6, 0, 1)
    )

  classification_table_dummy <-
    data.frame(
      sel_name = paste0("Taxon_", 1:6),
      family = c(
        "Family_A", "Family_A", "Family_A",
        "Family_B", "Family_B", "Family_B"
      ),
      genus = c(
        "Genus_A", "Genus_A", "Genus_B",
        "Genus_C", "Genus_C", "Genus_D"
      ),
      species = c(
        "Species_A", "Species_B", "Species_C",
        "Species_D", "Species_E", "Species_F"
      )
    )

  res <-
    classify_taxonomic_resolution(
      data = data_dummy,
      data_classification_table = classification_table_dummy,
      taxonomic_resolution = "genus"
    )

  expected_res <-
    tibble::tibble(
      dataset_name = "dataset_1",
      age = 0,
      taxon = c("Genus_A", "Genus_B", "Genus_C", "Genus_D"),
      pollen_prop = c(
        sum(data_dummy$pollen_prop[1:2]),
        data_dummy$pollen_prop[3],
        sum(data_dummy$pollen_prop[4:5]),
        data_dummy$pollen_prop[6]
      )
    )

  testthat::expect_equal(res, expected_res)
})

testthat::test_that("classify_taxonomic_resolution() handles invalid input", {
  set.seed(900723)
  data_dummy <-
    data.frame(
      dataset_name = "dataset_1",
      age = 0,
      taxon = paste0("Taxon_", 1:6),
      pollen_prop = runif(6, 0, 1)
    )

  classification_table_dummy <-
    data.frame(
      sel_name = paste0("Taxon_", 1:6),
      family = c(
        "Family_A", "Family_A", "Family_A",
        "Family_B", "Family_B", "Family_B"
      ),
      genus = c(
        "Genus_A", "Genus_A", "Genus_B",
        "Genus_C", "Genus_C", "Genus_D"
      ),
      species = c(
        "Species_A", "Species_B", "Species_C",
        "Species_D", "Species_E", "Species_F"
      )
    )

  testthat::expect_error(
    classify_taxonomic_resolution(
      data = NULL,
      data_classification_table = classification_table_dummy,
      taxonomic_resolution = "genus"
    )
  )

  testthat::expect_error(
    classify_taxonomic_resolution(
      data = data.frame(),
      data_classification_table = classification_table_dummy,
      taxonomic_resolution = "genus"
    )
  )

  testthat::expect_error(
    classify_taxonomic_resolution(
      data = NA,
      data_classification_table = classification_table_dummy,
      taxonomic_resolution = "genus"
    )
  )

  testthat::expect_error(
    classify_taxonomic_resolution(
      data = "invalid_data",
      data_classification_table = classification_table_dummy,
      taxonomic_resolution = "genus"
    )
  )

  testthat::expect_error(
    classify_taxonomic_resolution(
      data = data_dummy,
      data_classification_table = NULL,
      taxonomic_resolution = "genus"
    )
  )

  testthat::expect_error(
    classify_taxonomic_resolution(
      data = data_dummy,
      data_classification_table = data.frame(),
      taxonomic_resolution = "genus"
    )
  )

  testthat::expect_error(
    classify_taxonomic_resolution(
      data = data_dummy,
      data_classification_table = NA,
      taxonomic_resolution = "genus"
    )
  )

  testthat::expect_error(
    classify_taxonomic_resolution(
      data = data_dummy,
      data_classification_table = "invalid_table",
      taxonomic_resolution = "genus"
    )
  )

  testthat::expect_error(
    classify_taxonomic_resolution(
      data = data_dummy,
      data_classification_table = classification_table_dummy,
      taxonomic_resolution = NULL
    )
  )

  testthat::expect_error(
    classify_taxonomic_resolution(
      data = data_dummy,
      data_classification_table = classification_table_dummy,
      taxonomic_resolution = "non_existent"
    )
  )

  testthat::expect_error(
    classify_taxonomic_resolution(
      data = data_dummy,
      data_classification_table = classification_table_dummy,
      taxonomic_resolution = NA
    )
  )
})

testthat::test_that(
  "classify_taxonomic_resolution() accepts all seven taxonomic ranks",
  {
    set.seed(900723)
    data_dummy <-
      data.frame(
        dataset_name = "dataset_1",
        age = 0,
        taxon = paste0("Taxon_", 1:4),
        pollen_prop = runif(4, 0, 1)
      )

    classification_table_dummy <-
      data.frame(
        sel_name = paste0("Taxon_", 1:4),
        kingdom = c("Kingdom_A", "Kingdom_A", "Kingdom_A", "Kingdom_A"),
        phylum  = c("Phylum_A",  "Phylum_A",  "Phylum_B",  "Phylum_B"),
        class   = c("Class_A",   "Class_A",   "Class_B",   "Class_B"),
        order   = c("Order_A",   "Order_A",   "Order_B",   "Order_C"),
        family  = c("Family_A",  "Family_A",  "Family_B",  "Family_C"),
        genus   = c("Genus_A",   "Genus_B",   "Genus_C",   "Genus_D"),
        species = paste0("Species_", 1:4)
      )

    for (
      sel_rank in c(
        "kingdom", "phylum", "class", "order",
        "family", "genus", "species"
      )
    ) {
      testthat::expect_no_error(
        classify_taxonomic_resolution(
          data = data_dummy,
          data_classification_table = classification_table_dummy,
          taxonomic_resolution = sel_rank
        )
      )
    }
  }
)

testthat::test_that(
  "classify_taxonomic_resolution() drops taxa with no rank",
  {
    set.seed(900723)
    # Taxon_3: family only (genus NA) — falls back to Family_B
    # Taxon_4: both family and genus NA — dropped with warning
    data_dummy <-
      data.frame(
        dataset_name = "dataset_1",
        age = 0,
        taxon = paste0("Taxon_", 1:4),
        pollen_prop = stats::runif(4, 0, 1)
      )

    classification_table_dummy <-
      data.frame(
        sel_name = paste0("Taxon_", 1:4),
        family = c(
          "Family_A", "Family_A", "Family_B", NA_character_
        ),
        genus = c("Genus_A", "Genus_B", NA_character_, NA_character_)
      )

    res <-
      testthat::expect_warning(
        classify_taxonomic_resolution(
          data = data_dummy,
          data_classification_table = classification_table_dummy,
          taxonomic_resolution = "genus"
        )
      )

    # No NA taxa in output
    testthat::expect_false(
      base::any(base::is.na(dplyr::pull(res, taxon)))
    )

    # Fully classified taxa present
    testthat::expect_true(
      base::all(
        c("Genus_A", "Genus_B") %in% dplyr::pull(res, taxon)
      )
    )

    # Taxon_3 falls back to its family name — present as Family_B
    testthat::expect_true(
      "Family_B" %in% dplyr::pull(res, taxon)
    )

    # Taxon_4 had no classification at any rank — absent
    testthat::expect_false(
      base::any(dplyr::pull(res, taxon) == "Taxon_4")
    )
  }
)

testthat::test_that(
  "classify_taxonomic_resolution() falls back to coarser rank",
  {
    set.seed(900723)
    # Taxon_3 classifiable only to family; should appear as Family_B
    data_dummy <-
      data.frame(
        dataset_name = "dataset_1",
        age = 0,
        taxon = paste0("Taxon_", 1:4),
        pollen_prop = stats::runif(4, 0, 1)
      )

    classification_table_dummy <-
      data.frame(
        sel_name = paste0("Taxon_", 1:4),
        family = c(
          "Family_A", "Family_A", "Family_B", "Family_B"
        ),
        genus = c(
          "Genus_A", "Genus_B", NA_character_, "Genus_C"
        )
      )

    # Fallback to coarser rank should not trigger a warning
    res <-
      testthat::expect_no_warning(
        classify_taxonomic_resolution(
          data = data_dummy,
          data_classification_table = classification_table_dummy,
          taxonomic_resolution = "genus"
        )
      )

    # Taxon_3 appears under its family name
    testthat::expect_true(
      "Family_B" %in% dplyr::pull(res, taxon)
    )

    # Genus-level taxa still present
    testthat::expect_true(
      base::all(
        c("Genus_A", "Genus_B", "Genus_C") %in%
          dplyr::pull(res, taxon)
      )
    )

    # No NA taxa in output
    testthat::expect_false(
      base::any(base::is.na(dplyr::pull(res, taxon)))
    )

    # Pollen of Taxon_3 is not merged with any other taxon
    n_family_b_rows <-
      res |>
      dplyr::filter(taxon == "Family_B") |>
      base::nrow()

    testthat::expect_equal(n_family_b_rows, 1L)
  }
)

testthat::test_that(
  "classify_taxonomic_resolution() ignores ranks finer than requested",
  {
    set.seed(900723)
    # Taxon_1: has species but no genus — should fall back to family,
    #   NOT use species (which is finer than the requested genus level)
    data_dummy <-
      data.frame(
        dataset_name = "dataset_1",
        age = 0,
        taxon = c("Taxon_1", "Taxon_2"),
        pollen_prop = stats::runif(2, 0, 1)
      )

    classification_table_dummy <-
      data.frame(
        sel_name = c("Taxon_1", "Taxon_2"),
        family = c("Family_A", "Family_B"),
        genus = c(NA_character_, "Genus_B"),
        species = c("Species_A", "Species_B")
      )

    res <-
      testthat::expect_no_warning(
        classify_taxonomic_resolution(
          data = data_dummy,
          data_classification_table = classification_table_dummy,
          taxonomic_resolution = "genus"
        )
      )

    # Taxon_1 should be Family_A (not Species_A)
    testthat::expect_true(
      "Family_A" %in% dplyr::pull(res, taxon)
    )

    # Species_A must not appear — it exceeds the requested resolution
    testthat::expect_false(
      "Species_A" %in% dplyr::pull(res, taxon)
    )

    # Taxon_2 classified at genus level as expected
    testthat::expect_true(
      "Genus_B" %in% dplyr::pull(res, taxon)
    )

    testthat::expect_false(
      base::any(base::is.na(dplyr::pull(res, taxon)))
    )
  }
)

testthat::test_that(
  "classify_taxonomic_resolution() no warning when no NA taxa",
  {
    set.seed(900723)
    data_dummy <-
      data.frame(
        dataset_name = "dataset_1",
        age = 0,
        taxon = paste0("Taxon_", 1:3),
        pollen_prop = stats::runif(3, 0, 1)
      )

    classification_table_dummy <-
      data.frame(
        sel_name = paste0("Taxon_", 1:3),
        genus = c("Genus_A", "Genus_B", "Genus_C")
      )

    testthat::expect_no_warning(
      classify_taxonomic_resolution(
        data = data_dummy,
        data_classification_table = classification_table_dummy,
        taxonomic_resolution = "genus"
      )
    )
  }
)
