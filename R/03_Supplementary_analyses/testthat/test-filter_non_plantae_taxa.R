testthat::test_that(
  "filter_non_plantae_taxa() returns correct class and columns",
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
        kingdom = c("Plantae", "Plantae", "Plantae")
      )

    res <-
      filter_non_plantae_taxa(
        data = data_dummy,
        data_classification_table = classification_table_dummy
      )

    testthat::expect_s3_class(res, "data.frame")

    testthat::expect_true(
      base::all(
        c("dataset_name", "age", "taxon", "pollen_prop") %in%
          base::colnames(res)
      )
    )

    testthat::expect_false(
      "kingdom" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "filter_non_plantae_taxa() keeps all Plantae taxa",
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
        kingdom = c("Plantae", "Plantae", "Plantae")
      )

    res <-
      filter_non_plantae_taxa(
        data = data_dummy,
        data_classification_table = classification_table_dummy
      )

    testthat::expect_equal(base::nrow(res), 3L)

    testthat::expect_true(
      base::all(
        paste0("Taxon_", 1:3) %in% dplyr::pull(res, taxon)
      )
    )
  }
)

testthat::test_that(
  "filter_non_plantae_taxa() drops non-Plantae with warning",
  {
    set.seed(900723)
    data_dummy <-
      data.frame(
        dataset_name = "dataset_1",
        age = 0,
        taxon = paste0("Taxon_", 1:4),
        pollen_prop = stats::runif(4, 0, 1)
      )

    # Taxon_3 = Fungi, Taxon_4 = NA kingdom — both should be dropped
    classification_table_dummy <-
      data.frame(
        sel_name = paste0("Taxon_", 1:4),
        kingdom = c("Plantae", "Plantae", "Fungi", NA_character_)
      )

    res <-
      testthat::expect_warning(
        filter_non_plantae_taxa(
          data = data_dummy,
          data_classification_table = classification_table_dummy
        )
      )

    testthat::expect_equal(base::nrow(res), 2L)

    testthat::expect_true(
      base::all(
        c("Taxon_1", "Taxon_2") %in% dplyr::pull(res, taxon)
      )
    )

    testthat::expect_false(
      "Taxon_3" %in% dplyr::pull(res, taxon)
    )

    testthat::expect_false(
      "Taxon_4" %in% dplyr::pull(res, taxon)
    )

    testthat::expect_false(
      base::any(base::is.na(dplyr::pull(res, taxon)))
    )
  }
)

testthat::test_that(
  "filter_non_plantae_taxa() drops NA-kingdom taxa with warning",
  {
    set.seed(900723)
    data_dummy <-
      data.frame(
        dataset_name = "dataset_1",
        age = 0,
        taxon = c("Taxon_1", "Taxon_2"),
        pollen_prop = stats::runif(2, 0, 1)
      )

    # Taxon_2 has no kingdom entry — treated as non-Plantae
    classification_table_dummy <-
      data.frame(
        sel_name = c("Taxon_1", "Taxon_2"),
        kingdom = c("Plantae", NA_character_)
      )

    res <-
      testthat::expect_warning(
        filter_non_plantae_taxa(
          data = data_dummy,
          data_classification_table = classification_table_dummy
        )
      )

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_true("Taxon_1" %in% dplyr::pull(res, taxon))
    testthat::expect_false("Taxon_2" %in% dplyr::pull(res, taxon))
  }
)

testthat::test_that(
  "filter_non_plantae_taxa() no warning when all Plantae",
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
        kingdom = c("Plantae", "Plantae", "Plantae")
      )

    testthat::expect_no_warning(
      filter_non_plantae_taxa(
        data = data_dummy,
        data_classification_table = classification_table_dummy
      )
    )
  }
)

testthat::test_that(
  "filter_non_plantae_taxa() warning lists taxon names",
  {
    set.seed(900723)
    data_dummy <-
      data.frame(
        dataset_name = "dataset_1",
        age = 0,
        taxon = c("Taxon_1", "NonPlant_X"),
        pollen_prop = stats::runif(2, 0, 1)
      )

    classification_table_dummy <-
      data.frame(
        sel_name = c("Taxon_1", "NonPlant_X"),
        kingdom = c("Plantae", "Fungi")
      )

    testthat::expect_warning(
      filter_non_plantae_taxa(
        data = data_dummy,
        data_classification_table = classification_table_dummy
      ),
      regexp = "NonPlant_X"
    )
  }
)

testthat::test_that(
  "filter_non_plantae_taxa() handles invalid input",
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
        kingdom = c("Plantae", "Plantae", "Plantae")
      )

    testthat::expect_error(
      filter_non_plantae_taxa(
        data = NULL,
        data_classification_table = classification_table_dummy
      )
    )

    testthat::expect_error(
      filter_non_plantae_taxa(
        data = NA,
        data_classification_table = classification_table_dummy
      )
    )

    testthat::expect_error(
      filter_non_plantae_taxa(
        data = "invalid",
        data_classification_table = classification_table_dummy
      )
    )

    testthat::expect_error(
      filter_non_plantae_taxa(
        data = data.frame(dataset_name = "x", age = 0),
        data_classification_table = classification_table_dummy
      )
    )

    testthat::expect_error(
      filter_non_plantae_taxa(
        data = data_dummy,
        data_classification_table = NULL
      )
    )

    testthat::expect_error(
      filter_non_plantae_taxa(
        data = data_dummy,
        data_classification_table = NA
      )
    )

    testthat::expect_error(
      filter_non_plantae_taxa(
        data = data_dummy,
        data_classification_table = "invalid"
      )
    )

    testthat::expect_error(
      filter_non_plantae_taxa(
        data = data_dummy,
        data_classification_table = data.frame(
          sel_name = paste0("Taxon_", 1:3)
        )
      )
    )
  }
)

testthat::test_that(
  "filter_non_plantae_taxa() returns correct structure",
  {
    set.seed(900723)
    data_dummy <-
      data.frame(
        dataset_name = rep("dataset_1", 4),
        age = c(0, 0, 100, 100),
        taxon = paste0("Taxon_", 1:4),
        pollen_prop = stats::runif(4, 0, 1)
      )

    classification_table_dummy <-
      data.frame(
        sel_name = paste0("Taxon_", 1:4),
        kingdom = c("Plantae", "Fungi", "Plantae", NA_character_)
      )

    res <-
      testthat::expect_warning(
        filter_non_plantae_taxa(
          data = data_dummy,
          data_classification_table = classification_table_dummy
        )
      )

    # Output has same columns as input
    testthat::expect_equal(
      base::sort(base::colnames(res)),
      base::sort(base::colnames(data_dummy))
    )

    # Only Plantae rows remain
    testthat::expect_equal(base::nrow(res), 2L)

    testthat::expect_true(
      base::all(
        dplyr::pull(res, taxon) %in% c("Taxon_1", "Taxon_3")
      )
    )
  }
)
