testthat::test_that("classify_taxonomic_resolution() return correct class", {
  set.seed(1234)
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
  set.seed(1234)
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
  set.seed(1234)
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
    set.seed(1234)
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
  "classify_taxonomic_resolution() drops taxa with NA at resolution",
  {
    set.seed(900723)
    # Taxon_3 has no genus classification (NA), the rest are resolved
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
        genus = c("Genus_A", "Genus_B", NA, "Genus_C")
      )

    res <-
      testthat::expect_warning(
        classify_taxonomic_resolution(
          data = data_dummy,
          data_classification_table = classification_table_dummy,
          taxonomic_resolution = "genus"
        )
      )

    testthat::expect_false(
      base::any(base::is.na(dplyr::pull(res, taxon)))
    )

    testthat::expect_true(
      base::all(
        c("Genus_A", "Genus_B", "Genus_C") %in%
          dplyr::pull(res, taxon)
      )
    )

    testthat::expect_false(
      "Taxon_3" %in% dplyr::pull(res, taxon)
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
