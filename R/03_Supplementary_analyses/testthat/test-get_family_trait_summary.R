# Input validation: data_traits_raw -----

testthat::test_that("error if data_traits_raw is not a data frame", {
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  testthat::expect_error(
    get_family_trait_summary(
      data_traits_raw    = "not_a_df",
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  )
})

testthat::test_that("error if data_traits_raw missing required columns", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::c("Taxon_a"),
      trait_domain_name = base::c("Leaf Area")
      # trait_value intentionally absent
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  testthat::expect_error(
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  )
})

testthat::test_that("error if data_traits_raw missing taxon_name column", {
  data_traits <-
    tibble::tibble(
      trait_domain_name = base::c("Leaf Area"),
      trait_value       = base::c(10)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  testthat::expect_error(
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  )
})

# Input validation: data_classification -----

testthat::test_that("error if data_classification is not a data frame", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::c("Taxon_a"),
      trait_domain_name = base::c("Leaf Area"),
      trait_value       = base::c(10)
    )
  testthat::expect_error(
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = 42L,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  )
})

testthat::test_that("error if data_classification missing sel_name column", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::c("Taxon_a"),
      trait_domain_name = base::c("Leaf Area"),
      trait_value       = base::c(10)
    )
  data_class <-
    tibble::tibble(
      family = base::c("Asteraceae")
      # sel_name intentionally absent
    )
  testthat::expect_error(
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  )
})

testthat::test_that("error if data_classification missing family column", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::c("Taxon_a"),
      trait_domain_name = base::c("Leaf Area"),
      trait_value       = base::c(10)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a")
      # family intentionally absent
    )
  testthat::expect_error(
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  )
})

# Input validation: sel_taxon -----

testthat::test_that("error if sel_taxon is not character", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::c("Taxon_a"),
      trait_domain_name = base::c("Leaf Area"),
      trait_value       = base::c(10)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  testthat::expect_error(
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = 1L,
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  )
})

testthat::test_that("error if sel_taxon has length > 1", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::c("Taxon_a"),
      trait_domain_name = base::c("Leaf Area"),
      trait_value       = base::c(10)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  testthat::expect_error(
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = base::c("Taxon_a", "Taxon_b"),
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  )
})

# Input validation: sel_domain -----

testthat::test_that("error if sel_domain is not character", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::c("Taxon_a"),
      trait_domain_name = base::c("Leaf Area"),
      trait_value       = base::c(10)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  testthat::expect_error(
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = 1L,
      verbose            = FALSE
    )
  )
})

testthat::test_that("error if sel_domain has length > 1", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::c("Taxon_a"),
      trait_domain_name = base::c("Leaf Area"),
      trait_value       = base::c(10)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  testthat::expect_error(
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = base::c("Leaf Area", "Plant Height"),
      verbose            = FALSE
    )
  )
})

# Input validation: sel_rank -----

testthat::test_that("error if sel_rank is not character", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::c("Taxon_a"),
      trait_domain_name = base::c("Leaf Area"),
      trait_value       = base::c(10)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  testthat::expect_error(
    get_family_trait_summary(
      data_traits_raw     = data_traits,
      data_classification = data_class,
      sel_taxon           = "Taxon_a",
      sel_domain          = "Leaf Area",
      sel_rank            = 1L,
      verbose             = FALSE
    )
  )
})

testthat::test_that("error if sel_rank has length > 1", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::c("Taxon_a"),
      trait_domain_name = base::c("Leaf Area"),
      trait_value       = base::c(10)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  testthat::expect_error(
    get_family_trait_summary(
      data_traits_raw     = data_traits,
      data_classification = data_class,
      sel_taxon           = "Taxon_a",
      sel_domain          = "Leaf Area",
      sel_rank            = base::c("family", "genus"),
      verbose             = FALSE
    )
  )
})

testthat::test_that(
  "error if data_classification missing sel_rank column", {
    data_traits <-
      tibble::tibble(
        taxon_name        = base::c("Taxon_a"),
        trait_domain_name = base::c("Leaf Area"),
        trait_value       = base::c(10)
      )
    data_class <-
      tibble::tibble(
        sel_name = base::c("Taxon_a"),
        family   = base::c("Asteraceae")
        # No genus column
      )
    testthat::expect_error(
      get_family_trait_summary(
        data_traits_raw     = data_traits,
        data_classification = data_class,
        sel_taxon           = "Taxon_a",
        sel_domain          = "Leaf Area",
        sel_rank            = "genus",
        verbose             = FALSE
      )
    )
  }
)

# Input validation: verbose -----

testthat::test_that("error if verbose is not logical", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::c("Taxon_a"),
      trait_domain_name = base::c("Leaf Area"),
      trait_value       = base::c(10)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  testthat::expect_error(
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = "yes"
    )
  )
})

# Output structure -----

testthat::test_that("returns a tibble", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::rep("Taxon_a", 3L),
      trait_domain_name = base::rep("Leaf Area", 3L),
      trait_value       = base::c(10, 20, 30)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  testthat::expect_true(tibble::is_tibble(res))
})

testthat::test_that("has exactly the expected columns", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::rep("Taxon_a", 3L),
      trait_domain_name = base::rep("Leaf Area", 3L),
      trait_value       = base::c(10, 20, 30)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  testthat::expect_named(
    res,
    base::c("taxon_name", "n", "min", "q25", "median", "mean", "q75", "max")
  )
})

testthat::test_that("taxon_name column is character", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::rep("Taxon_a", 3L),
      trait_domain_name = base::rep("Leaf Area", 3L),
      trait_value       = base::c(10, 20, 30)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  vec_taxon <-
    dplyr::pull(res, taxon_name)
  testthat::expect_true(base::is.character(vec_taxon))
})

testthat::test_that("n column is integer or numeric >= 1", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::rep("Taxon_a", 3L),
      trait_domain_name = base::rep("Leaf Area", 3L),
      trait_value       = base::c(10, 20, 30)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  vec_n <-
    dplyr::pull(res, n)
  testthat::expect_true(base::is.numeric(vec_n) || base::is.integer(vec_n))
  testthat::expect_true(base::all(vec_n >= 1))
})

testthat::test_that("numeric summary columns are numeric", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::rep("Taxon_a", 3L),
      trait_domain_name = base::rep("Leaf Area", 3L),
      trait_value       = base::c(10, 20, 30)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  vec_min <-
    dplyr::pull(res, min)
  vec_q25 <-
    dplyr::pull(res, q25)
  vec_median <-
    dplyr::pull(res, median)
  vec_mean <-
    dplyr::pull(res, mean)
  vec_q75 <-
    dplyr::pull(res, q75)
  vec_max <-
    dplyr::pull(res, max)
  testthat::expect_true(base::is.numeric(vec_min))
  testthat::expect_true(base::is.numeric(vec_q25))
  testthat::expect_true(base::is.numeric(vec_median))
  testthat::expect_true(base::is.numeric(vec_mean))
  testthat::expect_true(base::is.numeric(vec_q75))
  testthat::expect_true(base::is.numeric(vec_max))
})

# Functional correctness: family lookup -----

testthat::test_that("returns 3 rows when 3 family taxa have data", {
  data_traits <-
    tibble::tibble(
      taxon_name = base::c(
        base::rep("Taxon_a", 3L),
        base::rep("Taxon_b", 2L),
        base::rep("Taxon_c", 3L)
      ),
      trait_domain_name = base::rep("Leaf Area", 8L),
      trait_value = base::c(10, 20, 30, 40, 50, 60, 70, 80)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a", "Taxon_b", "Taxon_c"),
      family   = base::rep("Asteraceae", 3L)
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  testthat::expect_equal(base::nrow(res), 3L)
  vec_taxa <-
    dplyr::pull(res, taxon_name)
  testthat::expect_true("Taxon_a" %in% vec_taxa)
  testthat::expect_true("Taxon_b" %in% vec_taxa)
  testthat::expect_true("Taxon_c" %in% vec_taxa)
})

# Functional correctness: sorted by median -----

testthat::test_that("result is sorted ascending by median", {
  data_traits <-
    tibble::tibble(
      taxon_name = base::c(
        base::rep("Taxon_a", 3L),
        base::rep("Taxon_b", 2L),
        base::rep("Taxon_c", 3L)
      ),
      trait_domain_name = base::rep("Leaf Area", 8L),
      trait_value = base::c(10, 20, 30, 40, 50, 60, 70, 80)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a", "Taxon_b", "Taxon_c"),
      family   = base::rep("Asteraceae", 3L)
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  vec_medians <-
    dplyr::pull(res, median)
  testthat::expect_true(!base::is.unsorted(vec_medians))
})

# Functional correctness: correct n values -----

testthat::test_that("n values match observation counts per taxon", {
  data_traits <-
    tibble::tibble(
      taxon_name = base::c(
        base::rep("Taxon_a", 3L),
        base::rep("Taxon_b", 2L),
        base::rep("Taxon_c", 3L)
      ),
      trait_domain_name = base::rep("Leaf Area", 8L),
      trait_value = base::c(10, 20, 30, 40, 50, 60, 70, 80)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a", "Taxon_b", "Taxon_c"),
      family   = base::rep("Asteraceae", 3L)
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  res_a <-
    dplyr::filter(res, taxon_name == "Taxon_a")
  res_b <-
    dplyr::filter(res, taxon_name == "Taxon_b")
  res_c <-
    dplyr::filter(res, taxon_name == "Taxon_c")
  n_a <-
    dplyr::pull(res_a, n)
  n_b <-
    dplyr::pull(res_b, n)
  n_c <-
    dplyr::pull(res_c, n)
  testthat::expect_equal(n_a, 3L)
  testthat::expect_equal(n_b, 2L)
  testthat::expect_equal(n_c, 3L)
})

# Functional correctness: correct statistics -----

testthat::test_that("correct stats for Taxon_a with values 10 20 30", {
  data_traits <-
    tibble::tibble(
      taxon_name = base::c(
        base::rep("Taxon_a", 3L),
        base::rep("Taxon_b", 2L),
        base::rep("Taxon_c", 3L)
      ),
      trait_domain_name = base::rep("Leaf Area", 8L),
      trait_value = base::c(10, 20, 30, 40, 50, 60, 70, 80)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a", "Taxon_b", "Taxon_c"),
      family   = base::rep("Asteraceae", 3L)
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  res_a <-
    dplyr::filter(res, taxon_name == "Taxon_a")
  val_min <-
    dplyr::pull(res_a, min)
  val_max <-
    dplyr::pull(res_a, max)
  val_median <-
    dplyr::pull(res_a, median)
  val_mean <-
    dplyr::pull(res_a, mean)
  val_q25 <-
    dplyr::pull(res_a, q25)
  vec_vals <-
    base::c(10, 20, 30)
  expected_q25 <-
    stats::quantile(vec_vals, 0.25, names = FALSE)
  testthat::expect_equal(val_min, 10)
  testthat::expect_equal(val_max, 30)
  testthat::expect_equal(val_median, 20)
  testthat::expect_equal(val_mean, 20)
  testthat::expect_equal(val_q25, expected_q25)
})

# Functional correctness: domain filtering -----

testthat::test_that("domain filtering excludes other domain observations", {
  data_traits <-
    tibble::tibble(
      taxon_name = base::c(
        base::rep("Taxon_a", 3L),
        "Taxon_a",
        base::rep("Taxon_b", 2L),
        base::rep("Taxon_c", 3L)
      ),
      trait_domain_name = base::c(
        base::rep("Leaf Area", 3L),
        "Plant Height",
        base::rep("Leaf Area", 2L),
        base::rep("Leaf Area", 3L)
      ),
      trait_value = base::c(10, 20, 30, 999, 40, 50, 60, 70, 80)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a", "Taxon_b", "Taxon_c"),
      family   = base::rep("Asteraceae", 3L)
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  res_a <-
    dplyr::filter(res, taxon_name == "Taxon_a")
  n_a <-
    dplyr::pull(res_a, n)
  testthat::expect_equal(n_a, 3L)
})

testthat::test_that("only requested domain data in result", {
  data_traits <-
    tibble::tibble(
      taxon_name = base::c(
        base::rep("Taxon_a", 3L),
        "Taxon_a",
        base::rep("Taxon_b", 2L)
      ),
      trait_domain_name = base::c(
        base::rep("Leaf Area", 3L),
        "Plant Height",
        base::rep("Leaf Area", 2L)
      ),
      trait_value = base::c(10, 20, 30, 999, 40, 50)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a", "Taxon_b"),
      family   = base::rep("Asteraceae", 2L)
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  val_max_a <-
    dplyr::pull(dplyr::filter(res, taxon_name == "Taxon_a"), max)
  testthat::expect_true(val_max_a < 999)
})

# Functional correctness: fallback when taxon not in table -----

testthat::test_that("fallback: taxon not in classification gives 1 row", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::rep("Missing_taxon", 3L),
      trait_domain_name = base::rep("Leaf Area", 3L),
      trait_value       = base::c(1, 2, 3)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Other_taxon"),
      family   = base::c("Asteraceae")
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Missing_taxon",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  testthat::expect_equal(base::nrow(res), 1L)
  vec_taxon <-
    dplyr::pull(res, taxon_name)
  testthat::expect_equal(vec_taxon, "Missing_taxon")
})

# Functional correctness: fallback when family is NA -----

testthat::test_that("fallback: NA family gives 1 row for sel_taxon", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::rep("Taxon_a", 3L),
      trait_domain_name = base::rep("Leaf Area", 3L),
      trait_value       = base::c(10, 20, 30)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c(NA_character_)
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  testthat::expect_equal(base::nrow(res), 1L)
})

# Functional correctness: no data for domain -----

testthat::test_that("0-row result with correct cols when no domain data", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::rep("Taxon_a", 3L),
      trait_domain_name = base::rep("Plant Height", 3L),
      trait_value       = base::c(10, 20, 30)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  testthat::expect_equal(base::nrow(res), 0L)
  testthat::expect_true(tibble::is_tibble(res))
  testthat::expect_named(
    res,
    base::c("taxon_name", "n", "min", "q25", "median", "mean", "q75", "max")
  )
})

# Functional correctness: partial family data -----

testthat::test_that("only taxa with domain data are in result rows", {
  data_traits <-
    tibble::tibble(
      taxon_name = base::c(
        base::rep("Taxon_a", 3L),
        base::rep("Taxon_b", 2L)
        # Taxon_c has no observations
      ),
      trait_domain_name = base::rep("Leaf Area", 5L),
      trait_value = base::c(10, 20, 30, 40, 50)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a", "Taxon_b", "Taxon_c"),
      family   = base::rep("Asteraceae", 3L)
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  testthat::expect_equal(base::nrow(res), 2L)
})

# Verbose messages -----

testthat::test_that("verbose TRUE emits a message", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::rep("Taxon_a", 3L),
      trait_domain_name = base::rep("Leaf Area", 3L),
      trait_value       = base::c(10, 20, 30)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  testthat::expect_message(
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = TRUE
    )
  )
})

testthat::test_that("verbose FALSE emits no message", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::rep("Taxon_a", 3L),
      trait_domain_name = base::rep("Leaf Area", 3L),
      trait_value       = base::c(10, 20, 30)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  testthat::expect_no_message(
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  )
})

# Edge cases -----

testthat::test_that("single taxon in family: result has 1 row", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::rep("Taxon_a", 4L),
      trait_domain_name = base::rep("Leaf Area", 4L),
      trait_value       = base::c(5, 10, 15, 20)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a"),
      family   = base::c("Asteraceae")
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  testthat::expect_equal(base::nrow(res), 1L)
})

testthat::test_that("only sel_taxon in family: result has 1 row", {
  data_traits <-
    tibble::tibble(
      taxon_name        = base::rep("Taxon_a", 3L),
      trait_domain_name = base::rep("Leaf Area", 3L),
      trait_value       = base::c(1, 2, 3)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a", "Taxon_b"),
      family   = base::c("Asteraceae", "Poaceae")
    )
  res <-
    get_family_trait_summary(
      data_traits_raw    = data_traits,
      data_classification = data_class,
      sel_taxon          = "Taxon_a",
      sel_domain         = "Leaf Area",
      verbose            = FALSE
    )
  testthat::expect_equal(base::nrow(res), 1L)
  vec_taxon <-
    dplyr::pull(res, taxon_name)
  testthat::expect_equal(vec_taxon, "Taxon_a")
})

# Functional correctness: non-default sel_rank -----

testthat::test_that("sel_rank = genus groups by genus column", {
  data_traits <-
    tibble::tibble(
      taxon_name = base::c(
        base::rep("Taxon_a", 3L),
        base::rep("Taxon_b", 2L),
        base::rep("Other_genus_sp", 2L)
      ),
      trait_domain_name = base::rep("Leaf Area", 7L),
      trait_value = base::c(10, 20, 30, 40, 50, 90, 100)
    )
  data_class <-
    tibble::tibble(
      sel_name = base::c("Taxon_a", "Taxon_b", "Other_genus_sp"),
      family   = base::rep("Asteraceae", 3L),
      genus    = base::c(
        "Genus_one", "Genus_one", "Genus_two"
      )
    )
  res <-
    get_family_trait_summary(
      data_traits_raw     = data_traits,
      data_classification = data_class,
      sel_taxon           = "Taxon_a",
      sel_domain          = "Leaf Area",
      sel_rank            = "genus",
      verbose             = FALSE
    )
  # Only taxa in the same genus as Taxon_a (Genus_one):
  # Taxon_a and Taxon_b
  testthat::expect_equal(base::nrow(res), 2L)
  vec_taxa <-
    dplyr::pull(res, taxon_name)
  testthat::expect_true("Taxon_a" %in% vec_taxa)
  testthat::expect_true("Taxon_b" %in% vec_taxa)
  testthat::expect_false("Other_genus_sp" %in% vec_taxa)
})
