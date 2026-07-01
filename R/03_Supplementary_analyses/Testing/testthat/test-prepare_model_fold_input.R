make_model_fold_test_data <- function() {
  data_community_matrix <-
    base::matrix(
      data = base::c(
        1, 0, 0,
        1, 1, 0,
        1, 0, 1,
        0, 1, 1
      ),
      nrow = 4,
      byrow = TRUE,
      dimnames = base::list(
        base::c("a__0", "b__0", "c__0", "d__0"),
        base::c("taxon_drop", "taxon_keep", "taxon_test")
      )
    )

  data_abiotic_wide <-
    tibble::tibble(
      dataset_name = base::c("a", "b", "c", "d"),
      age = base::c(0, 0, 0, 0),
      bio = base::c(10, 12, 14, 1000)
    )

  data_spatial_train <-
    base::data.frame(mev_1 = base::c(1, 3, 5))

  data_spatial_test <-
    base::data.frame(mev_1 = 7)

  base::rownames(data_spatial_train) <-
    base::c("a__0", "b__0", "c__0")

  base::rownames(data_spatial_test) <- "d__0"

  res <-
    base::list(
      data_community_matrix = data_community_matrix,
      data_abiotic_wide = data_abiotic_wide,
      data_spatial_train = data_spatial_train,
      data_spatial_test = data_spatial_test
    )

  return(res)
}

testthat::test_that(
  "prepare_model_fold_input() filters taxa from training only",
  {
    list_data <-
      make_model_fold_test_data()

    res <-
      prepare_model_fold_input(
        data_community_matrix = list_data[["data_community_matrix"]],
        data_abiotic_wide = list_data[["data_abiotic_wide"]],
        data_spatial_train = list_data[["data_spatial_train"]],
        data_spatial_test = list_data[["data_spatial_test"]],
        train_ids = base::c("a__0", "b__0", "c__0"),
        test_ids = "d__0",
        error_family = "binomial",
        min_n_taxa = 1L,
        age_scale_mode = "center"
      )

    data_train_input <-
      res[["data_train_input"]]

    testthat::expect_equal(
      base::colnames(data_train_input[["data_community_to_fit"]]),
      base::c("taxon_keep", "taxon_test")
    )
    testthat::expect_equal(
      base::colnames(res[["data_test_observed"]]),
      base::c("taxon_keep", "taxon_test")
    )
    testthat::expect_equal(
      res[["data_test_observed"]][1, ],
      base::c(taxon_keep = 1, taxon_test = 1)
    )
  }
)

testthat::test_that(
  "prepare_model_fold_input() returns an explicit taxon mapping",
  {
    list_data <-
      make_model_fold_test_data()

    res <-
      prepare_model_fold_input(
        data_community_matrix = list_data[["data_community_matrix"]],
        data_abiotic_wide = list_data[["data_abiotic_wide"]],
        data_spatial_train = list_data[["data_spatial_train"]],
        data_spatial_test = list_data[["data_spatial_test"]],
        train_ids = base::c("a__0", "b__0", "c__0"),
        test_ids = "d__0",
        error_family = "binomial",
        min_n_taxa = 1L,
        age_scale_mode = "center"
      )

    data_mapping <-
      res[["data_taxa_mapping"]]

    testthat::expect_equal(
      base::colnames(data_mapping),
      base::c(
        "taxon",
        "taxon_index_full",
        "taxon_index_retained",
        "retained",
        "status"
      )
    )
    testthat::expect_equal(
      dplyr::pull(data_mapping, status),
      base::c("constant_in_training", "retained", "retained")
    )
    testthat::expect_equal(
      dplyr::pull(data_mapping, taxon_index_retained),
      base::c(NA_integer_, 1L, 2L)
    )
  }
)

testthat::test_that(
  "prepare_model_fold_input() records complete fold diagnostics",
  {
    list_data <-
      make_model_fold_test_data()

    res <-
      prepare_model_fold_input(
        data_community_matrix = list_data[["data_community_matrix"]],
        data_abiotic_wide = list_data[["data_abiotic_wide"]],
        data_spatial_train = list_data[["data_spatial_train"]],
        data_spatial_test = list_data[["data_spatial_test"]],
        train_ids = base::c("a__0", "b__0", "c__0"),
        test_ids = "d__0",
        error_family = "binomial",
        min_n_taxa = 1L,
        age_scale_mode = "center"
      )

    data_diagnostics <-
      res[["data_diagnostics"]]

    testthat::expect_equal(
      data_diagnostics[["n_taxa_dropped"]],
      1L
    )
    testthat::expect_equal(
      data_diagnostics[["n_train_requested"]],
      3L
    )
    testthat::expect_equal(
      data_diagnostics[["n_train_aligned"]],
      3L
    )
    testthat::expect_equal(
      data_diagnostics[["n_train_dropped_alignment"]],
      0L
    )
    testthat::expect_equal(
      data_diagnostics[["n_train_missing_abiotic"]],
      0L
    )
    testthat::expect_equal(
      data_diagnostics[["n_train_missing_spatial"]],
      0L
    )
    testthat::expect_true(data_diagnostics[["train_alignment_exact"]])
    testthat::expect_equal(
      data_diagnostics[["n_test_requested"]],
      1L
    )
    testthat::expect_equal(
      data_diagnostics[["n_test_aligned"]],
      1L
    )
    testthat::expect_equal(
      data_diagnostics[["n_test_dropped_alignment"]],
      0L
    )
    testthat::expect_equal(
      data_diagnostics[["n_test_missing_abiotic"]],
      0L
    )
    testthat::expect_equal(
      data_diagnostics[["n_test_missing_spatial"]],
      0L
    )
    testthat::expect_true(data_diagnostics[["test_alignment_exact"]])
  }
)

testthat::test_that(
  "prepare_model_fold_input() records missing predictor rows",
  {
    list_data <-
      make_model_fold_test_data()

    data_abiotic_missing <-
      list_data[["data_abiotic_wide"]] |>
      dplyr::mutate(
        bio = dplyr::if_else(
          .data[["dataset_name"]] == "b",
          NA_real_,
          .data[["bio"]]
        )
      )

    res <-
      prepare_model_fold_input(
        data_community_matrix = list_data[["data_community_matrix"]],
        data_abiotic_wide = data_abiotic_missing,
        data_spatial_train = list_data[["data_spatial_train"]],
        data_spatial_test = list_data[["data_spatial_test"]],
        train_ids = base::c("a__0", "b__0", "c__0"),
        test_ids = "d__0",
        error_family = "binomial",
        min_n_taxa = 1L,
        age_scale_mode = "center"
      )

    data_diagnostics <-
      res[["data_diagnostics"]]

    testthat::expect_equal(
      data_diagnostics[["n_train_missing_abiotic"]],
      1L
    )
    testthat::expect_equal(
      data_diagnostics[["n_train_dropped_alignment"]],
      1L
    )
    testthat::expect_equal(
      data_diagnostics[["n_train_aligned"]],
      2L
    )
    testthat::expect_false(data_diagnostics[["train_alignment_exact"]])
    testthat::expect_equal(
      base::rownames(
        res[["data_train_input"]][["data_community_to_fit"]]
      ),
      base::c("a__0", "c__0")
    )
  }
)

testthat::test_that(
  "prepare_model_fold_input() learns scaling from training rows",
  {
    list_data <-
      make_model_fold_test_data()

    res <-
      prepare_model_fold_input(
        data_community_matrix = list_data[["data_community_matrix"]],
        data_abiotic_wide = list_data[["data_abiotic_wide"]],
        data_spatial_train = list_data[["data_spatial_train"]],
        data_spatial_test = list_data[["data_spatial_test"]],
        train_ids = base::c("a__0", "b__0", "c__0"),
        test_ids = "d__0",
        error_family = "binomial",
        min_n_taxa = 1L,
        age_scale_mode = "center"
      )

    data_train_input <-
      res[["data_train_input"]]

    data_test_input <-
      res[["data_test_input"]]

    testthat::expect_equal(
      data_train_input[["data_abiotic_to_fit"]][["bio"]],
      base::c(-1, 0, 1)
    )
    testthat::expect_equal(
      data_test_input[["data_abiotic_to_fit"]][["bio"]],
      494
    )
    testthat::expect_equal(
      data_test_input[["data_spatial_to_fit"]][["mev_1"]],
      2
    )
  }
)

testthat::test_that(
  "prepare_model_fold_input() isolates training transformations",
  {
    list_data_original <-
      make_model_fold_test_data()

    data_community_changed <-
      base::rbind(
        list_data_original[["data_community_matrix"]][1:3, ],
        base::c(1, 0, 0)
      )

    base::rownames(data_community_changed) <-
      base::rownames(list_data_original[["data_community_matrix"]])

    data_abiotic_changed <-
      list_data_original[["data_abiotic_wide"]] |>
      dplyr::mutate(
        bio = dplyr::if_else(.data[["dataset_name"]] == "d", -5000, bio)
      )

    data_spatial_test_changed <-
      base::data.frame(mev_1 = 5000)

    base::rownames(data_spatial_test_changed) <- "d__0"

    list_data_changed <-
      base::list(
        data_community_matrix = data_community_changed,
        data_abiotic_wide = data_abiotic_changed,
        data_spatial_train = list_data_original[["data_spatial_train"]],
        data_spatial_test = data_spatial_test_changed
      )

    res_original <-
      prepare_model_fold_input(
        data_community_matrix =
          list_data_original[["data_community_matrix"]],
        data_abiotic_wide = list_data_original[["data_abiotic_wide"]],
        data_spatial_train = list_data_original[["data_spatial_train"]],
        data_spatial_test = list_data_original[["data_spatial_test"]],
        train_ids = base::c("a__0", "b__0", "c__0"),
        test_ids = "d__0",
        error_family = "binomial",
        min_n_taxa = 1L,
        age_scale_mode = "center"
      )

    res_changed <-
      prepare_model_fold_input(
        data_community_matrix =
          list_data_changed[["data_community_matrix"]],
        data_abiotic_wide = list_data_changed[["data_abiotic_wide"]],
        data_spatial_train = list_data_changed[["data_spatial_train"]],
        data_spatial_test = list_data_changed[["data_spatial_test"]],
        train_ids = base::c("a__0", "b__0", "c__0"),
        test_ids = "d__0",
        error_family = "binomial",
        min_n_taxa = 1L,
        age_scale_mode = "center"
      )

    testthat::expect_equal(
      res_original[["data_train_input"]],
      res_changed[["data_train_input"]]
    )
    testthat::expect_equal(
      res_original[["data_taxa_mapping"]],
      res_changed[["data_taxa_mapping"]]
    )
  }
)

testthat::test_that(
  "prepare_model_fold_input() preserves requested row alignment",
  {
    list_data <-
      make_model_fold_test_data()

    res <-
      prepare_model_fold_input(
        data_community_matrix = list_data[["data_community_matrix"]],
        data_abiotic_wide = list_data[["data_abiotic_wide"]],
        data_spatial_train = list_data[["data_spatial_train"]],
        data_spatial_test = list_data[["data_spatial_test"]],
        train_ids = base::c("c__0", "a__0", "b__0"),
        test_ids = "d__0",
        error_family = "binomial",
        min_n_taxa = 1L,
        age_scale_mode = "center"
      )

    data_train_input <-
      res[["data_train_input"]]

    testthat::expect_equal(
      base::rownames(data_train_input[["data_community_to_fit"]]),
      base::c("c__0", "a__0", "b__0")
    )
    testthat::expect_equal(
      base::rownames(data_train_input[["data_abiotic_to_fit"]]),
      base::c("c__0", "a__0", "b__0")
    )
    testthat::expect_equal(
      base::rownames(data_train_input[["data_spatial_to_fit"]]),
      base::c("c__0", "a__0", "b__0")
    )
  }
)

testthat::test_that(
  "prepare_model_fold_input() supports non-spatial folds",
  {
    list_data <-
      make_model_fold_test_data()

    res <-
      prepare_model_fold_input(
        data_community_matrix = list_data[["data_community_matrix"]],
        data_abiotic_wide = list_data[["data_abiotic_wide"]],
        train_ids = base::c("a__0", "b__0", "c__0"),
        test_ids = "d__0",
        error_family = "binomial",
        min_n_taxa = 1L,
        age_scale_mode = "center"
      )

    testthat::expect_false(
      "data_spatial_to_fit" %in% base::names(res[["data_train_input"]])
    )
    testthat::expect_false(
      "data_spatial_to_fit" %in% base::names(res[["data_test_input"]])
    )
  }
)

testthat::test_that(
  "prepare_model_fold_input() rejects overlapping partitions",
  {
    list_data <-
      make_model_fold_test_data()

    testthat::expect_error(
      prepare_model_fold_input(
        data_community_matrix = list_data[["data_community_matrix"]],
        data_abiotic_wide = list_data[["data_abiotic_wide"]],
        data_spatial_train = list_data[["data_spatial_train"]],
        data_spatial_test = list_data[["data_spatial_test"]],
        train_ids = base::c("a__0", "b__0", "c__0"),
        test_ids = "c__0",
        error_family = "binomial",
        min_n_taxa = 1L,
        age_scale_mode = "center"
      ),
      "must be disjoint"
    )
  }
)
