testthat::test_that(
  "prepare_continent_trait_data() errors on non-char continent_id",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_traits_classified_corrected <-
      tibble::tibble(
        scale_id = base::c("europe"),
        taxon_resolved = base::c("A")
      )

    testthat::expect_error(
      prepare_continent_trait_data(
        continent_id = 1L,
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )
    )
  }
)

testthat::test_that(
  "prepare_continent_trait_data() errors on length > 1 continent_id",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_traits_classified_corrected <-
      tibble::tibble(
        scale_id = base::c("europe"),
        taxon_resolved = base::c("A")
      )

    testthat::expect_error(
      prepare_continent_trait_data(
        continent_id = base::c("europe", "asia"),
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )
    )
  }
)

testthat::test_that(
  "prepare_continent_trait_data() errors on empty string continent_id",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_traits_classified_corrected <-
      tibble::tibble(
        scale_id = base::c("europe"),
        taxon_resolved = base::c("A")
      )

    testthat::expect_error(
      prepare_continent_trait_data(
        continent_id = "",
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )
    )
  }
)

testthat::test_that(
  "prepare_continent_trait_data() errors on non-df trait_table",
  {
    data_traits_classified_corrected <-
      tibble::tibble(
        scale_id = base::c("europe"),
        taxon_resolved = base::c("A")
      )

    testthat::expect_error(
      prepare_continent_trait_data(
        continent_id = "europe",
        data_trait_table = "not_a_df",
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )
    )
  }
)

testthat::test_that(
  "prepare_continent_trait_data() errors on missing taxon_name col",
  {
    data_trait_table <-
      tibble::tibble(
        species = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_traits_classified_corrected <-
      tibble::tibble(
        scale_id = base::c("europe"),
        taxon_resolved = base::c("A")
      )

    testthat::expect_error(
      prepare_continent_trait_data(
        continent_id = "europe",
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )
    )
  }
)

testthat::test_that(
  "prepare_continent_trait_data() errors on non-df classified",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    testthat::expect_error(
      prepare_continent_trait_data(
        continent_id = "europe",
        data_trait_table = data_trait_table,
        data_traits_classified_corrected = "not_a_df"
      )
    )
  }
)

testthat::test_that(
  "prepare_continent_trait_data() errors on missing scale_id col",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_traits_classified_corrected <-
      tibble::tibble(
        region = base::c("europe"),
        taxon_resolved = base::c("A")
      )

    testthat::expect_error(
      prepare_continent_trait_data(
        continent_id = "europe",
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )
    )
  }
)

testthat::test_that(
  "prepare_continent_trait_data() errors on missing taxon_resolved col",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_traits_classified_corrected <-
      tibble::tibble(
        scale_id = base::c("europe"),
        taxon_name = base::c("A")
      )

    testthat::expect_error(
      prepare_continent_trait_data(
        continent_id = "europe",
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )
    )
  }
)

testthat::test_that(
  "prepare_continent_trait_data() returns a tibble",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D"),
        sla = base::c(1.0, 2.0, 3.0, 4.0),
        height = base::c(0.5, 1.0, 1.5, 2.0)
      )

    data_traits_classified_corrected <-
      tibble::tibble(
        scale_id = base::c("europe", "europe", "asia"),
        taxon_resolved = base::c("A", "B", "C")
      )

    res <-
      prepare_continent_trait_data(
        continent_id = "europe",
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )

    testthat::expect_s3_class(res, "tbl_df")
  }
)

testthat::test_that(
  "prepare_continent_trait_data() returns only continent taxa",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D"),
        sla = base::c(1.0, 2.0, 3.0, 4.0),
        height = base::c(0.5, 1.0, 1.5, 2.0)
      )

    data_traits_classified_corrected <-
      tibble::tibble(
        scale_id = base::c("europe", "europe", "asia"),
        taxon_resolved = base::c("A", "B", "C")
      )

    res <-
      prepare_continent_trait_data(
        continent_id = "europe",
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )

    vec_taxa <-
      dplyr::pull(res, taxon_name)

    testthat::expect_equal(base::nrow(res), 2L)
    testthat::expect_true(
      base::all(vec_taxa %in% base::c("A", "B"))
    )
  }
)

testthat::test_that(
  "prepare_continent_trait_data() excludes taxa from other continents",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "D"),
        sla = base::c(1.0, 2.0, 3.0, 4.0),
        height = base::c(0.5, 1.0, 1.5, 2.0)
      )

    data_traits_classified_corrected <-
      tibble::tibble(
        scale_id = base::c("europe", "europe", "asia"),
        taxon_resolved = base::c("A", "B", "C")
      )

    res <-
      prepare_continent_trait_data(
        continent_id = "europe",
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )

    vec_taxa <-
      dplyr::pull(res, taxon_name)

    testthat::expect_false("C" %in% vec_taxa)
    testthat::expect_false("D" %in% vec_taxa)
  }
)

testthat::test_that(
  "prepare_continent_trait_data() removes all-NA trait taxa",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        sla = base::c(1.0, NA, NA),
        height = base::c(0.5, NA, NA)
      )

    data_traits_classified_corrected <-
      tibble::tibble(
        scale_id = base::c("europe", "europe", "europe"),
        taxon_resolved = base::c("A", "B", "C")
      )

    res <-
      prepare_continent_trait_data(
        continent_id = "europe",
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )

    vec_taxa <-
      dplyr::pull(res, taxon_name)

    testthat::expect_equal(base::nrow(res), 1L)
    testthat::expect_true("A" %in% vec_taxa)
    testthat::expect_false("B" %in% vec_taxa)
    testthat::expect_false("C" %in% vec_taxa)
  }
)

testthat::test_that(
  "prepare_continent_trait_data() keeps taxa with partial NAs",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, NA),
        height = base::c(NA, 1.0)
      )

    data_traits_classified_corrected <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    res <-
      prepare_continent_trait_data(
        continent_id = "europe",
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )

    testthat::expect_equal(base::nrow(res), 2L)
  }
)

testthat::test_that(
  "prepare_continent_trait_data() preserves all input columns",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0),
        height = base::c(0.5, 1.0)
      )

    data_traits_classified_corrected <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    res <-
      prepare_continent_trait_data(
        continent_id = "europe",
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )

    testthat::expect_equal(
      base::colnames(res),
      base::colnames(data_trait_table)
    )
  }
)

testthat::test_that(
  "prepare_continent_trait_data() returns 0 rows for missing continent",
  {
    data_trait_table <-
      tibble::tibble(
        taxon_name = base::c("A", "B"),
        sla = base::c(1.0, 2.0)
      )

    data_traits_classified_corrected <-
      tibble::tibble(
        scale_id = base::c("europe", "europe"),
        taxon_resolved = base::c("A", "B")
      )

    res <-
      prepare_continent_trait_data(
        continent_id = "antarctica",
        data_trait_table = data_trait_table,
        data_traits_classified_corrected =
          data_traits_classified_corrected
      )

    testthat::expect_equal(base::nrow(res), 0L)
  }
)
