testthat::test_that(
  "select_continental_trait_table() errors on non-char scale_id",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_trait_records_classified <-
      tibble::tibble(
        scale_id = base::c("europe"),
        taxon_resolved = base::c("A")
      )

    testthat::expect_error(
      select_continental_trait_table(
        scale_id = 1L,
        data_trait_table = data_trait_table,
        data_trait_records_classified =
          data_trait_records_classified
      )
    )
  }
)

testthat::test_that(
  "select_continental_trait_table() errors on length > 1 scale_id",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_trait_records_classified <-
      tibble::tibble(
        scale_id = base::c("europe"),
        taxon_resolved = base::c("A")
      )

    testthat::expect_error(
      select_continental_trait_table(
        scale_id = base::c("europe", "asia"),
        data_trait_table = data_trait_table,
        data_trait_records_classified =
          data_trait_records_classified
      )
    )
  }
)

testthat::test_that(
  "select_continental_trait_table() errors on empty string scale_id",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_trait_records_classified <-
      tibble::tibble(
        scale_id = base::c("europe"),
        taxon_resolved = base::c("A")
      )

    testthat::expect_error(
      select_continental_trait_table(
        scale_id = "",
        data_trait_table = data_trait_table,
        data_trait_records_classified =
          data_trait_records_classified
      )
    )
  }
)

testthat::test_that(
  "select_continental_trait_table() errors on non-df trait_table",
  {
    data_trait_records_classified <-
      tibble::tibble(
        scale_id = base::c("europe"),
        taxon_resolved = base::c("A")
      )

    testthat::expect_error(
      select_continental_trait_table(
        scale_id = "europe",
        data_trait_table = "not_a_df",
        data_trait_records_classified =
          data_trait_records_classified
      )
    )
  }
)

testthat::test_that(
  "select_continental_trait_table() errors on missing taxon_name col",
  {
    data_trait_table <-
      tibble::tibble(
        species = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_trait_records_classified <-
      tibble::tibble(
        scale_id = base::c("europe"),
        taxon_resolved = base::c("A")
      )

    testthat::expect_error(
      select_continental_trait_table(
        scale_id = "europe",
        data_trait_table = data_trait_table,
        data_trait_records_classified =
          data_trait_records_classified
      )
    )
  }
)

testthat::test_that(
  "select_continental_trait_table() errors on non-df classified",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    testthat::expect_error(
      select_continental_trait_table(
        scale_id = "europe",
        data_trait_table = data_trait_table,
        data_trait_records_classified = "not_a_df"
      )
    )
  }
)

testthat::test_that(
  "select_continental_trait_table() errors on missing scale_id col",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_trait_records_classified <-
      tibble::tibble(
        region = base::c("europe"),
        taxon_resolved = base::c("A")
      )

    testthat::expect_error(
      select_continental_trait_table(
        scale_id = "europe",
        data_trait_table = data_trait_table,
        data_trait_records_classified =
          data_trait_records_classified
      )
    )
  }
)

testthat::test_that(
  "select_continental_trait_table() errors on missing taxon_resolved col",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_trait_records_classified <-
      tibble::tibble(
        scale_id = base::c("europe"),
        taxon_name = base::c("A")
      )

    testthat::expect_error(
      select_continental_trait_table(
        scale_id = "europe",
        data_trait_table = data_trait_table,
        data_trait_records_classified =
          data_trait_records_classified
      )
    )
  }
)

testthat::test_that(
  "select_continental_trait_table() returns a tibble",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D"),
        sla = base::c(1.0, 2.0, 3.0, 4.0),
        height = base::c(0.5, 1.0, 1.5, 2.0)
      )

    data_trait_records_classified <-
      tibble::tibble(
        scale_id = base::c("europe", "europe", "asia"),
        taxon_resolved = base::c("A", "B", "C")
      )

    data_trait_table_selected <-
      select_continental_trait_table(
        scale_id = "europe",
        data_trait_table = data_trait_table,
        data_trait_records_classified =
          data_trait_records_classified
      )

    testthat::expect_s3_class(data_trait_table_selected, "tbl_df")
  }
)

testthat::test_that(
  "select_continental_trait_table() returns only continent taxa",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D"),
        sla = base::c(1.0, 2.0, 3.0, 4.0),
        height = base::c(0.5, 1.0, 1.5, 2.0)
      )

    data_trait_records_classified <-
      tibble::tibble(
        scale_id = base::c("europe", "europe", "asia"),
        taxon_resolved = base::c("A", "B", "C")
      )

    data_trait_table_selected <-
      select_continental_trait_table(
        scale_id = "europe",
        data_trait_table = data_trait_table,
        data_trait_records_classified =
          data_trait_records_classified
      )

    vec_taxa <-
      dplyr::pull(data_trait_table_selected, taxon_name)

    testthat::expect_equal(base::nrow(data_trait_table_selected), 2L)
    testthat::expect_true(
      base::all(vec_taxa %in% base::c("A", "B"))
    )
  }
)

testthat::test_that(
  "select_continental_trait_table() excludes taxa from other continents",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D"),
        sla = base::c(1.0, 2.0, 3.0, 4.0),
        height = base::c(0.5, 1.0, 1.5, 2.0)
      )

    data_trait_records_classified <-
      tibble::tibble(
        scale_id = base::c("europe", "europe", "asia"),
        taxon_resolved = base::c("A", "B", "C")
      )

    data_trait_table_selected <-
      select_continental_trait_table(
        scale_id = "europe",
        data_trait_table = data_trait_table,
        data_trait_records_classified =
          data_trait_records_classified
      )

    vec_taxa <-
      dplyr::pull(data_trait_table_selected, taxon_name)

    testthat::expect_false("C" %in% vec_taxa)
    testthat::expect_false("D" %in% vec_taxa)
  }
)

testthat::test_that(
  "select_continental_trait_table() removes all-NA trait taxa",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, NA, NA),
        height = base::c(0.5, NA, NA)
      )

    data_trait_records_classified <-
      tibble::tibble(
        scale_id = base::c("europe", "europe", "europe"),
        taxon_resolved = base::c("A", "B", "C")
      )

    data_trait_table_selected <-
      select_continental_trait_table(
        scale_id = "europe",
        data_trait_table = data_trait_table,
        data_trait_records_classified =
          data_trait_records_classified
      )

    vec_taxa <-
      dplyr::pull(data_trait_table_selected, taxon_name)

    testthat::expect_equal(base::nrow(data_trait_table_selected), 1L)
    testthat::expect_true("A" %in% vec_taxa)
    testthat::expect_false("B" %in% vec_taxa)
    testthat::expect_false("C" %in% vec_taxa)
  }
)

testthat::test_that(
  "select_continental_trait_table() keeps taxa with partial NAs",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, NA),
        height = base::c(NA, 1.0)
      )

    data_trait_records_classified <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    data_trait_table_selected <-
      select_continental_trait_table(
        scale_id = "europe",
        data_trait_table = data_trait_table,
        data_trait_records_classified =
          data_trait_records_classified
      )

    testthat::expect_equal(base::nrow(data_trait_table_selected), 2L)
  }
)

testthat::test_that(
  "select_continental_trait_table() preserves all input columns",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0),
        height = base::c(0.5, 1.0)
      )

    data_trait_records_classified <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    data_trait_table_selected <-
      select_continental_trait_table(
        scale_id = "europe",
        data_trait_table = data_trait_table,
        data_trait_records_classified =
          data_trait_records_classified
      )

    testthat::expect_equal(
      base::colnames(data_trait_table_selected),
      base::colnames(data_trait_table)
    )
  }
)

testthat::test_that(
  "select_continental_trait_table() returns 0 rows for missing continent",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_trait_records_classified <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    data_trait_table_selected <-
      select_continental_trait_table(
        scale_id = "antarctica",
        data_trait_table = data_trait_table,
        data_trait_records_classified =
          data_trait_records_classified
      )

    testthat::expect_equal(base::nrow(data_trait_table_selected), 0L)
  }
)
