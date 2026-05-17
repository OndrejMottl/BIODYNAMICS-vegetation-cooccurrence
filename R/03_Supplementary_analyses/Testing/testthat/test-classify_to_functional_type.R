# -- Input validation: data argument ------------------------------------------

testthat::test_that("classify_to_functional_type() errors if data not df", {
  data_ft <-
    tibble::tibble(
      taxon_name = "Taxon_1",
      functional_type = 1L
    )

  testthat::expect_error(
    classify_to_functional_type(
      data = "not_a_dataframe",
      data_ft_classification = data_ft
    )
  )
})

testthat::test_that("classify_to_functional_type() errors if taxon missing", {
  data_dummy <-
    tibble::tibble(
      dataset_name = "ds1",
      age = 0L,
      value = 0.5
    )

  data_ft <-
    tibble::tibble(
      taxon_name = "Taxon_1",
      functional_type = 1L
    )

  testthat::expect_error(
    classify_to_functional_type(
      data = data_dummy,
      data_ft_classification = data_ft
    )
  )
})

testthat::test_that(
  "classify_to_functional_type() errors if dataset_name missing",
  {
    data_dummy <-
      tibble::tibble(
        taxon = "Taxon_1",
        age = 0L,
        value = 0.5
      )

    data_ft <-
      tibble::tibble(
        taxon_name = "Taxon_1",
        functional_type = 1L
      )

    testthat::expect_error(
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft
      )
    )
  }
)

testthat::test_that("classify_to_functional_type() errors if age missing", {
  data_dummy <-
    tibble::tibble(
      taxon = "Taxon_1",
      dataset_name = "ds1",
      value = 0.5
    )

  data_ft <-
    tibble::tibble(
      taxon_name = "Taxon_1",
      functional_type = 1L
    )

  testthat::expect_error(
    classify_to_functional_type(
      data = data_dummy,
      data_ft_classification = data_ft
    )
  )
})

testthat::test_that(
  "classify_to_functional_type() errors if value missing",
  {
    data_dummy <-
      tibble::tibble(
        taxon = "Taxon_1",
        dataset_name = "ds1",
        age = 0L
      )

    data_ft <-
      tibble::tibble(
        taxon_name = "Taxon_1",
        functional_type = 1L
      )

    testthat::expect_error(
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft
      )
    )
  }
)

# -- Input validation: data_ft_classification argument ------------------------

testthat::test_that(
  "classify_to_functional_type() errors if ft_class not df",
  {
    data_dummy <-
      tibble::tibble(
        taxon = "Taxon_1",
        dataset_name = "ds1",
        age = 0L,
        value = 0.5
      )

    testthat::expect_error(
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = list(taxon_name = "Taxon_1")
      )
    )
  }
)

testthat::test_that(
  "classify_to_functional_type() errors if taxon_name col missing",
  {
    data_dummy <-
      tibble::tibble(
        taxon = "Taxon_1",
        dataset_name = "ds1",
        age = 0L,
        value = 0.5
      )

    data_ft <-
      tibble::tibble(
        functional_type = 1L
      )

    testthat::expect_error(
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft
      )
    )
  }
)

testthat::test_that(
  "classify_to_functional_type() errors if functional_type col missing",
  {
    data_dummy <-
      tibble::tibble(
        taxon = "Taxon_1",
        dataset_name = "ds1",
        age = 0L,
        value = 0.5
      )

    data_ft <-
      tibble::tibble(
        taxon_name = "Taxon_1"
      )

    testthat::expect_error(
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft
      )
    )
  }
)

# -- Input validation: verbose argument ---------------------------------------

testthat::test_that(
  "classify_to_functional_type() errors if verbose not logical",
  {
    data_dummy <-
      tibble::tibble(
        taxon = "Taxon_1",
        dataset_name = "ds1",
        age = 0L,
        value = 0.5
      )

    data_ft <-
      tibble::tibble(
        taxon_name = "Taxon_1",
        functional_type = 1L
      )

    testthat::expect_error(
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = "yes"
      )
    )
  }
)

# -- Return structure ---------------------------------------------------------

testthat::test_that(
  "classify_to_functional_type() returns a data frame",
  {
    data_dummy <-
      tibble::tibble(
        taxon = c("Taxon_1", "Taxon_2"),
        dataset_name = "ds1",
        age = 0L,
        value = c(0.4, 0.6)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = c("Taxon_1", "Taxon_2"),
        functional_type = c(1L, 2L)
      )

    res <-
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )

    testthat::expect_s3_class(res, "data.frame")
  }
)

testthat::test_that(
  "classify_to_functional_type() returns correct columns",
  {
    data_dummy <-
      tibble::tibble(
        taxon = c("Taxon_1", "Taxon_2"),
        dataset_name = "ds1",
        age = 0L,
        value = c(0.4, 0.6)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = c("Taxon_1", "Taxon_2"),
        functional_type = c(1L, 2L)
      )

    res <-
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )

    testthat::expect_true(
      base::all(
        c("taxon", "dataset_name", "age", "value") %in%
          base::colnames(res)
      )
    )
  }
)

testthat::test_that(
  "classify_to_functional_type() has no extra columns",
  {
    data_dummy <-
      tibble::tibble(
        taxon = c("Taxon_1", "Taxon_2"),
        dataset_name = "ds1",
        age = 0L,
        value = c(0.4, 0.6)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = c("Taxon_1", "Taxon_2"),
        functional_type = c(1L, 2L)
      )

    res <-
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )

    testthat::expect_equal(
      base::length(base::colnames(res)),
      4L
    )
  }
)

testthat::test_that(
  "classify_to_functional_type() preserves sample_name",
  {
    data_dummy <-
      tibble::tibble(
        taxon = c("Taxon_1", "Taxon_2"),
        dataset_name = c("ds1", "ds1"),
        sample_name = c("sample_a", "sample_a"),
        age = c(0L, 0L),
        value = c(0.4, 0.6)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = c("Taxon_1", "Taxon_2"),
        functional_type = c(1L, 1L)
      )

    res <-
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )

    testthat::expect_equal(
      base::colnames(res),
      base::colnames(data_dummy)
    )

    testthat::expect_equal(
      base::unique(res$sample_name),
      "sample_a"
    )
  }
)

# -- Core behavior: FT labels -------------------------------------------------

testthat::test_that(
  "classify_to_functional_type() creates FT_ taxon labels",
  {
    data_dummy <-
      tibble::tibble(
        taxon = c("Taxon_1", "Taxon_2", "Taxon_3"),
        dataset_name = "ds1",
        age = 0L,
        value = c(0.3, 0.3, 0.4)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = c("Taxon_1", "Taxon_2", "Taxon_3"),
        functional_type = c(1L, 2L, 3L)
      )

    res <-
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )

    vec_taxon <-
      dplyr::pull(res, taxon)

    testthat::expect_true(
      base::all(
        stringr::str_detect(vec_taxon, "^FT_[0-9]+$")
      )
    )
  }
)

testthat::test_that(
  "classify_to_functional_type() uses correct FT number in label",
  {
    data_dummy <-
      tibble::tibble(
        taxon = "Taxon_1",
        dataset_name = "ds1",
        age = 0L,
        value = 1.0
      )

    data_ft <-
      tibble::tibble(
        taxon_name = "Taxon_1",
        functional_type = 5L
      )

    res <-
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )

    vec_taxon <-
      dplyr::pull(res, taxon)

    testthat::expect_true("FT_5" %in% vec_taxon)
  }
)

# -- Core behavior: value aggregation -----------------------------------

testthat::test_that(
  "classify_to_functional_type() sums value within FT group",
  {
    data_dummy <-
      tibble::tibble(
        taxon = c("Taxon_1", "Taxon_2"),
        dataset_name = "ds1",
        age = 0L,
        value = c(0.3, 0.4)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = c("Taxon_1", "Taxon_2"),
        functional_type = c(1L, 1L)
      )

    res <-
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )

    vec_prop <-
      dplyr::pull(res, value)

    testthat::expect_equal(
      base::sum(vec_prop, na.rm = TRUE),
      0.7,
      tolerance = 1e-9
    )
  }
)

testthat::test_that(
  "classify_to_functional_type() aggregates per dataset/age/FT",
  {
    data_dummy <-
      tibble::tibble(
        taxon = c(
          "Taxon_1", "Taxon_2",
          "Taxon_1", "Taxon_2"
        ),
        dataset_name = c("ds1", "ds1", "ds2", "ds2"),
        age = c(0L, 0L, 0L, 0L),
        value = c(0.2, 0.3, 0.5, 0.1)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = c("Taxon_1", "Taxon_2"),
        functional_type = c(1L, 1L)
      )

    res <-
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )

    res_ds1 <-
      dplyr::filter(res, dataset_name == "ds1")

    res_ds2 <-
      dplyr::filter(res, dataset_name == "ds2")

    prop_ds1 <-
      dplyr::pull(res_ds1, value)

    prop_ds2 <-
      dplyr::pull(res_ds2, value)

    testthat::expect_equal(prop_ds1, 0.5, tolerance = 1e-9)
    testthat::expect_equal(prop_ds2, 0.6, tolerance = 1e-9)
  }
)

# -- Core behavior: preserve all (dataset_name, age) combinations -------------

testthat::test_that(
  "classify_to_functional_type() preserves true negatives",
  {
    data_dummy <-
      tibble::tibble(
        taxon = c("Taxon_1", "Taxon_2", "Taxon_1"),
        dataset_name = c("ds1", "ds1", "ds2"),
        age = c(0L, 0L, 100L),
        value = c(0.5, 0.5, 0.5)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = c("Taxon_1", "Taxon_2"),
        functional_type = c(1L, 2L)
      )

    res <-
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )

    vec_ds <-
      dplyr::pull(res, dataset_name)

    testthat::expect_true("ds2" %in% vec_ds)
  }
)

# -- Unmatched taxa -----------------------------------------------------------

testthat::test_that(
  "classify_to_functional_type() drops unmatched taxa",
  {
    data_dummy <-
      tibble::tibble(
        taxon = c("Taxon_1", "Taxon_unknown"),
        dataset_name = "ds1",
        age = 0L,
        value = c(0.6, 0.4)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = "Taxon_1",
        functional_type = 1L
      )

    res <-
      base::suppressWarnings(
        classify_to_functional_type(
          data = data_dummy,
          data_ft_classification = data_ft,
          verbose = FALSE
        )
      )

    vec_taxon <-
      dplyr::pull(res, taxon)

    testthat::expect_false("Taxon_unknown" %in% vec_taxon)
  }
)

testthat::test_that(
  "classify_to_functional_type() warns when taxa are dropped",
  {
    data_dummy <-
      tibble::tibble(
        taxon = c("Taxon_1", "Taxon_unknown"),
        dataset_name = "ds1",
        age = 0L,
        value = c(0.6, 0.4)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = "Taxon_1",
        functional_type = 1L
      )

    testthat::expect_warning(
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )
    )
  }
)

testthat::test_that(
  "classify_to_functional_type() warns and returns 0 rows if all unmatched",
  {
    data_dummy <-
      tibble::tibble(
        taxon = "Taxon_unknown",
        dataset_name = "ds1",
        age = 0L,
        value = 1.0
      )

    data_ft <-
      tibble::tibble(
        taxon_name = "Taxon_1",
        functional_type = 1L
      )

    res <-
      testthat::expect_warning(
        classify_to_functional_type(
          data = data_dummy,
          data_ft_classification = data_ft,
          verbose = FALSE
        )
      )

    testthat::expect_equal(base::nrow(res), 0L)

    testthat::expect_true(
      base::all(
        c("taxon", "dataset_name", "age", "value") %in%
          base::colnames(res)
      )
    )
  }
)

# -- Edge case: single FT group -----------------------------------------------

testthat::test_that(
  "classify_to_functional_type() handles single FT group correctly",
  {
    data_dummy <-
      tibble::tibble(
        taxon = c("Taxon_1", "Taxon_2", "Taxon_3"),
        dataset_name = "ds1",
        age = 0L,
        value = c(0.2, 0.3, 0.5)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = c("Taxon_1", "Taxon_2", "Taxon_3"),
        functional_type = c(1L, 1L, 1L)
      )

    res <-
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )

    vec_taxon <-
      dplyr::pull(res, taxon)

    testthat::expect_equal(
      base::unique(vec_taxon),
      "FT_1"
    )

    vec_prop <-
      dplyr::pull(res, value)

    testthat::expect_equal(
      base::sum(vec_prop, na.rm = TRUE),
      1.0,
      tolerance = 1e-9
    )
  }
)

# -- Edge case: multiple datasets and ages ------------------------------------

testthat::test_that(
  "classify_to_functional_type() handles multiple datasets and ages",
  {
    data_dummy <-
      tibble::tibble(
        taxon = base::rep(c("Taxon_1", "Taxon_2"), times = 4L),
        dataset_name = base::rep(
          c("ds1", "ds1", "ds2", "ds2"),
          each = 2L
        ),
        age = base::rep(c(0L, 100L, 0L, 100L), each = 2L),
        value = base::rep(0.5, 8L)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = c("Taxon_1", "Taxon_2"),
        functional_type = c(1L, 2L)
      )

    res <-
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )

    vec_ds <-
      dplyr::pull(res, dataset_name)

    vec_age <-
      dplyr::pull(res, age)

    testthat::expect_true("ds1" %in% vec_ds)
    testthat::expect_true("ds2" %in% vec_ds)
    testthat::expect_true(0L %in% vec_age)
    testthat::expect_true(100L %in% vec_age)
  }
)

# -- Edge case: NA in value aggregated with na.rm = TRUE ----------------

testthat::test_that(
  "classify_to_functional_type() sums value ignoring NA",
  {
    data_dummy <-
      tibble::tibble(
        taxon = c("Taxon_1", "Taxon_2"),
        dataset_name = "ds1",
        age = 0L,
        value = c(0.4, NA_real_)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = c("Taxon_1", "Taxon_2"),
        functional_type = c(1L, 1L)
      )

    res <-
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )

    vec_prop <-
      dplyr::pull(res, value)

    testthat::expect_equal(
      vec_prop[[1L]],
      0.4,
      tolerance = 1e-9
    )
  }
)

# -- verbose = FALSE suppresses messages --------------------------------------

testthat::test_that(
  "classify_to_functional_type() verbose=FALSE suppresses messages",
  {
    data_dummy <-
      tibble::tibble(
        taxon = c("Taxon_1", "Taxon_2"),
        dataset_name = "ds1",
        age = 0L,
        value = c(0.4, 0.6)
      )

    data_ft <-
      tibble::tibble(
        taxon_name = c("Taxon_1", "Taxon_2"),
        functional_type = c(1L, 2L)
      )

    testthat::expect_no_message(
      classify_to_functional_type(
        data = data_dummy,
        data_ft_classification = data_ft,
        verbose = FALSE
      )
    )
  }
)
