call_generate_trait_qc_report <-
  function(...) {
    generate_trait_qc_report(
      ...,
      path_qc_report = base::tempfile(fileext = ".csv")
    )
  }


testthat::test_that(
  "generate_trait_qc_report() errors on non-data-frame input",
  {
    testthat::expect_error(
      call_generate_trait_qc_report(data_traits = "not a df")
    )

    testthat::expect_error(
      call_generate_trait_qc_report(data_traits = NULL)
    )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = base::c(1, 2, 3)
      )
    )
  }
)


testthat::test_that(
  "generate_trait_qc_report() writes report to custom path_qc_report",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::rep("Quercus", 12L),
        trait_domain_name = base::rep("SLA", 12L),
        trait_name = base::rep("LMA", 12L),
        trait_value = base::seq(10, 21, by = 1)
      )

    path_temp_corrections <-
      base::tempfile(fileext = ".csv")

    path_temp_report <-
      base::tempfile(fileext = ".csv")

    generate_trait_qc_report(
      data_traits = data_traits,
      path_corrections = path_temp_corrections,
      path_qc_report = path_temp_report
    )

    testthat::expect_true(
      base::file.exists(path_temp_report)
    )

    data_report <-
      readr::read_csv(
        path_temp_report,
        show_col_types = FALSE
      )

    testthat::expect_equal(
      base::nrow(data_report),
      1L
    )

    testthat::expect_true(
      base::all(
        base::c(
          "trait_domain_name",
          "taxon_name",
          "n_records",
          "n_suspected_outliers_taxon"
        ) %in% base::colnames(data_report)
      )
    )
  }
)


testthat::test_that(
  "generate_trait_qc_report() writes default date-stamped report",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::rep("Quercus", 12L),
        trait_domain_name = base::rep("SLA", 12L),
        trait_name = base::rep("LMA", 12L),
        trait_value = base::seq(10, 21, by = 1)
      )

    path_temp_corrections <-
      base::tempfile(fileext = ".csv")

    path_default_report <-
      here::here(
        "Data/Temp",
        "trait_qc_report_2099-12-31.csv"
      )

    if (
      base::file.exists(path_default_report)
    ) {
      base::unlink(path_default_report)
    }

    testthat::local_mocked_bindings(
      Sys.Date = function() {
        base::as.Date("2099-12-31")
      },
      .package = "base"
    )

    generate_trait_qc_report(
      data_traits = data_traits,
      path_corrections = path_temp_corrections
    )

    testthat::expect_true(
      base::file.exists(path_default_report)
    )

    base::unlink(path_default_report)
  }
)


testthat::test_that(
  "generate_trait_qc_report() errors on missing columns",
  {
    path_temp <-
      base::tempfile(fileext = ".csv")

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = tibble::tibble(
          taxon_name = "A",
          trait_domain_name = "SLA",
          trait_name = "LMA"
          # trait_value missing
        ),
        path_corrections = path_temp
      )
    )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = tibble::tibble(
          taxon_name = "A",
          trait_domain_name = "SLA",
          trait_value = 10
          # trait_name missing
        ),
        path_corrections = path_temp
      )
    )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = tibble::tibble(
          trait_domain_name = "SLA",
          trait_name = "LMA",
          trait_value = 10
          # taxon_name missing
        ),
        path_corrections = path_temp
      )
    )
  }
)


testthat::test_that(
  "generate_trait_qc_report() errors on bad path_corrections",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        trait_name = "LMA",
        trait_value = 10
      )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = 123L
      )
    )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = NULL
      )
    )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = base::c("a.csv", "b.csv")
      )
    )
  }
)


testthat::test_that(
  "generate_trait_qc_report() errors on bad outlier_iqr_multiplier",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        trait_name = "LMA",
        trait_value = 10
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        outlier_iqr_multiplier = "three"
      )
    )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        outlier_iqr_multiplier = -1
      )
    )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        outlier_iqr_multiplier = 0
      )
    )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        outlier_iqr_multiplier = base::c(3, 5)
      )
    )
  }
)


testthat::test_that(
  "custom outlier_iqr_multiplier changes which taxa are flagged",
  {
    # Values: 10, 11, 12, 50. IQR=2, median=11.
    # At multiplier=3:  threshold=6  => 50 is outlier  (|50-11|=39 > 6)
    # At multiplier=20: threshold=40 => 50 is NOT outlier (39 < 40)
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C", "Borderline"),
        trait_domain_name = base::rep("SLA", 4L),
        trait_name = base::rep("LMA", 4L),
        trait_value = base::c(10, 11, 12, 50)
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    # strict: Borderline is flagged
    list_strict <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        outlier_iqr_multiplier = 3
      )

    testthat::expect_true(
      "Borderline" %in%
        purrr::chuck(list_strict, "suspected_outlier_taxa_domain")
    )

    # lenient: Borderline is NOT flagged
    list_lenient <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        outlier_iqr_multiplier = 20
      )

    testthat::expect_false(
      "Borderline" %in%
        purrr::chuck(list_lenient, "suspected_outlier_taxa_domain")
    )
  }
)


testthat::test_that(
  "generate_trait_qc_report() returns named list",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Pinus"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_name = base::c("LMA", "LMA"),
        trait_value = base::c(10, 12)
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp
      )

    testthat::expect_type(list_result, "list")

    testthat::expect_named(
      list_result,
      base::c(
        "summary_by_domain",
        "summary_by_domain_taxon",
        "suspected_outlier_taxa_domain",
        "suspected_outlier_taxa_taxon"
      ),
      ignore.order = FALSE
    )
  }
)


testthat::test_that(
  "summary_by_domain is a tibble with one row per domain",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c(
          "Quercus", "Pinus", "Betula", "Betula"
        ),
        trait_domain_name = base::c(
          "SLA", "SLA", "SLA", "Height"
        ),
        trait_name = base::c(
          "LMA", "LMA", "LMA", "plant_height"
        ),
        trait_value = base::c(10, 12, 11, 100)
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp
      )

    data_summary <-
      purrr::chuck(list_result, "summary_by_domain")

    testthat::expect_s3_class(data_summary, "tbl_df")

    # Two unique domains: SLA and Height
    testthat::expect_equal(base::nrow(data_summary), 2L)
  }
)


testthat::test_that(
  "summary_by_domain has all required columns",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Pinus"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_name = base::c("LMA", "LMA"),
        trait_value = base::c(10, 12)
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp
      )

    data_summary <-
      purrr::chuck(list_result, "summary_by_domain")

    vec_expected_cols <-
      base::c(
        "trait_domain_name",
        "n_records",
        "n_taxa",
        "mean",
        "median",
        "sd",
        "lwr_90",
        "upr_90",
        "IQR",
        "n_suspected_outliers"
      )

    testthat::expect_true(
      base::all(
        vec_expected_cols %in% base::colnames(data_summary)
      )
    )
  }
)


testthat::test_that(
  "suspected_outlier_taxa_domain and _taxon are character vectors",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Pinus"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_name = base::c("LMA", "LMA"),
        trait_value = base::c(10, 12)
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp
      )

    testthat::expect_true(
      base::is.character(
        purrr::chuck(list_result, "suspected_outlier_taxa_domain")
      )
    )

    testthat::expect_true(
      base::is.character(
        purrr::chuck(list_result, "suspected_outlier_taxa_taxon")
      )
    )
  }
)


testthat::test_that(
  "summary_by_domain: n_records and n_taxa are correct",
  {
    # SLA: 3 records, 2 unique taxa; Height: 1 record, 1 taxon
    data_traits <-
      tibble::tibble(
        taxon_name = base::c(
          "Quercus", "Pinus", "Quercus", "Betula"
        ),
        trait_domain_name = base::c(
          "SLA", "SLA", "SLA", "Height"
        ),
        trait_name = base::c(
          "LMA", "LMA", "LMA", "plant_height"
        ),
        trait_value = base::c(10, 12, 11, 200)
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp
      )

    data_summary <-
      purrr::chuck(list_result, "summary_by_domain")

    data_sla <-
      data_summary |>
      dplyr::filter(trait_domain_name == "SLA")

    testthat::expect_equal(
      dplyr::pull(data_sla, n_records),
      3L
    )

    testthat::expect_equal(
      dplyr::pull(data_sla, n_taxa),
      2L
    )
  }
)


testthat::test_that(
  "summary_by_domain: median is correct",
  {
    # median of c(10, 12, 11) = 11
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        trait_domain_name = base::c("SLA", "SLA", "SLA"),
        trait_name = base::c("LMA", "LMA", "LMA"),
        trait_value = base::c(10, 12, 11)
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp
      )

    data_summary <-
      purrr::chuck(list_result, "summary_by_domain")

    testthat::expect_equal(
      dplyr::pull(data_summary, median),
      stats::median(base::c(10, 12, 11))
    )
  }
)


testthat::test_that(
  "outlier taxon detected at > 3x IQR from median",
  {
    # Use 15 normal taxa (5x each of 10, 11, 12) plus one extreme.
    # With n=16, Q1=10, Q3=12, IQR=2, median=11, threshold=3*2=6.
    # Extreme=999: |999-11|=988 > 6 => is outlier.
    # Normal values: |10-11|=1 and |12-11|=1, both < 6.
    data_traits <-
      tibble::tibble(
        taxon_name = base::c(
          base::paste0("T", base::formatC(1:15, width = 2L, flag = "0")),
          "Extreme"
        ),
        trait_domain_name = base::rep("SLA", 16L),
        trait_name = base::rep("LMA", 16L),
        trait_value = base::c(
          base::rep(base::c(10, 11, 12), times = 5L),
          999
        )
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp
      )

    vec_outliers <-
      purrr::chuck(list_result, "suspected_outlier_taxa_domain")

    testthat::expect_true(
      "Extreme" %in% vec_outliers
    )

    # Normal taxa should NOT appear
    testthat::expect_false("T01" %in% vec_outliers)
    testthat::expect_false("T02" %in% vec_outliers)
    testthat::expect_false("T03" %in% vec_outliers)
  }
)


testthat::test_that(
  "n_suspected_outliers matches outlier count in domain",
  {
    # Two outliers in SLA
    data_traits <-
      tibble::tibble(
        taxon_name = base::c(
          "A", "B", "C", "Ext1", "Ext2"
        ),
        trait_domain_name = base::rep("SLA", 5L),
        trait_name = base::rep("LMA", 5L),
        trait_value = base::c(10, 11, 12, 999, -999)
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp
      )

    data_summary <-
      purrr::chuck(list_result, "summary_by_domain")

    testthat::expect_equal(
      dplyr::pull(data_summary, n_suspected_outliers),
      2L
    )
  }
)


testthat::test_that(
  "no outlier taxa when all values are normal",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("A", "B", "C"),
        trait_domain_name = base::c("SLA", "SLA", "SLA"),
        trait_name = base::c("LMA", "LMA", "LMA"),
        trait_value = base::c(10, 11, 12)
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp
      )

    vec_outliers <-
      purrr::chuck(list_result, "suspected_outlier_taxa_domain")

    testthat::expect_length(vec_outliers, 0L)
  }
)


testthat::test_that(
  "creates corrections template when file is absent",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Pinus"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_name = base::c("LMA", "LMA"),
        trait_value = base::c(10, 12)
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    # File must not exist before the call
    testthat::expect_false(base::file.exists(path_temp))

    call_generate_trait_qc_report(
      data_traits = data_traits,
      path_corrections = path_temp
    )

    # File should now exist
    testthat::expect_true(base::file.exists(path_temp))

    # Template should be header-only (zero data rows)
    data_template <-
      readr::read_csv(
        path_temp,
        show_col_types = FALSE
      )

    testthat::expect_equal(base::nrow(data_template), 0L)

    # Check expected column names
    vec_expected_cols <-
      base::c(
        "taxon_name",
        "trait_domain_name",
        "action",
        "scale_factor",
        "notes",
        "CHECKED"
      )

    testthat::expect_true(
      base::all(
        vec_expected_cols %in% base::colnames(data_template)
      )
    )
  }
)


testthat::test_that(
  "does NOT overwrite existing corrections file",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = base::c("Quercus", "Pinus"),
        trait_domain_name = base::c("SLA", "SLA"),
        trait_name = base::c("LMA", "LMA"),
        trait_value = base::c(10, 12)
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    # Pre-write a file with sentinel content
    readr::write_csv(
      tibble::tibble(
        taxon_name = "Sentinel",
        trait_domain_name = "Height",
        action = "exclude",
        scale_factor = NA_real_,
        notes = "do_not_overwrite",
        CHECKED = TRUE
      ),
      path_temp
    )

    call_generate_trait_qc_report(
      data_traits = data_traits,
      path_corrections = path_temp
    )

    data_after <-
      readr::read_csv(
        path_temp,
        show_col_types = FALSE
      )

    # File must still contain the sentinel row
    testthat::expect_equal(base::nrow(data_after), 1L)

    testthat::expect_equal(
      dplyr::pull(data_after, taxon_name),
      "Sentinel"
    )
  }
)


testthat::test_that(
  "single domain single taxon: zero outliers",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        trait_name = "LMA",
        trait_value = 10
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp
      )

    data_summary <-
      purrr::chuck(list_result, "summary_by_domain")

    testthat::expect_equal(base::nrow(data_summary), 1L)

    testthat::expect_equal(
      dplyr::pull(data_summary, n_suspected_outliers),
      0L
    )

    vec_outliers <-
      purrr::chuck(list_result, "suspected_outlier_taxa_domain")

    testthat::expect_length(vec_outliers, 0L)
  }
)


testthat::test_that(
  "generate_trait_qc_report() errors on bad outlier_iqr_multiplier_taxon",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        trait_name = "LMA",
        trait_value = 10
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        outlier_iqr_multiplier_taxon = "one-and-a-half"
      )
    )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        outlier_iqr_multiplier_taxon = -1
      )
    )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        outlier_iqr_multiplier_taxon = 0
      )
    )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        outlier_iqr_multiplier_taxon = base::c(1.5, 2.0)
      )
    )
  }
)


testthat::test_that(
  "generate_trait_qc_report() errors on bad min_records_per_taxon",
  {
    data_traits <-
      tibble::tibble(
        taxon_name = "Quercus",
        trait_domain_name = "SLA",
        trait_name = "LMA",
        trait_value = 10
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        min_records_per_taxon = "ten"
      )
    )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        min_records_per_taxon = 0
      )
    )

    testthat::expect_error(
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        min_records_per_taxon = base::c(5, 10)
      )
    )
  }
)


testthat::test_that(
  "summary_by_domain_taxon is a tibble with required columns",
  {
    # 12 records for Quercus x SLA so the per-taxon summary is computed
    data_traits <-
      tibble::tibble(
        taxon_name = base::c(
          base::rep("Quercus", 12L),
          base::rep("Pinus", 3L)
        ),
        trait_domain_name = base::rep("SLA", 15L),
        trait_name = base::rep("LMA", 15L),
        trait_value = base::c(
          base::seq(10, 21, by = 1),
          base::c(40, 41, 42)
        )
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        min_records_per_taxon = 10L
      )

    data_summary_taxon <-
      purrr::chuck(list_result, "summary_by_domain_taxon")

    testthat::expect_s3_class(data_summary_taxon, "tbl_df")

    vec_expected_cols <-
      base::c(
        "trait_domain_name",
        "taxon_name",
        "n_records",
        "mean",
        "median",
        "sd",
        "IQR",
        "n_suspected_outliers_taxon"
      )

    testthat::expect_true(
      base::all(
        vec_expected_cols %in% base::colnames(data_summary_taxon)
      )
    )
  }
)


testthat::test_that(
  "summary_by_domain_taxon excludes taxa below min_records_per_taxon",
  {
    # Quercus: 12 records (>= 10) => included
    # Pinus:    3 records (<  10) => excluded
    data_traits <-
      tibble::tibble(
        taxon_name = base::c(
          base::rep("Quercus", 12L),
          base::rep("Pinus", 3L)
        ),
        trait_domain_name = base::rep("SLA", 15L),
        trait_name = base::rep("LMA", 15L),
        trait_value = base::c(
          base::seq(10, 21, by = 1),
          base::c(40, 41, 42)
        )
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        min_records_per_taxon = 10L
      )

    data_summary_taxon <-
      purrr::chuck(list_result, "summary_by_domain_taxon")

    testthat::expect_true(
      "Quercus" %in% dplyr::pull(data_summary_taxon, taxon_name)
    )

    testthat::expect_false(
      "Pinus" %in% dplyr::pull(data_summary_taxon, taxon_name)
    )
  }
)


testthat::test_that(
  "taxon below min_records threshold never in suspected_outlier_taxa_taxon",
  {
    # SmallTaxon has only 5 records (< 10) but with one extreme value.
    # LargeTaxon has 15 records with all normal values.
    # SmallTaxon must NOT appear in suspected_outlier_taxa_taxon.
    data_traits <-
      tibble::tibble(
        taxon_name = base::c(
          base::rep("SmallTaxon", 5L),
          base::rep("LargeTaxon", 15L)
        ),
        trait_domain_name = base::rep("SLA", 20L),
        trait_name = base::rep("LMA", 20L),
        trait_value = base::c(
          # SmallTaxon: 4 normal + 1 extreme within-taxon value
          base::c(10, 11, 12, 11, 9999),
          # LargeTaxon: all normal
          base::rep(base::c(10, 11, 12), times = 5L)
        )
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        min_records_per_taxon = 10L
      )

    vec_taxon_outliers <-
      purrr::chuck(list_result, "suspected_outlier_taxa_taxon")

    testthat::expect_false(
      "SmallTaxon" %in% vec_taxon_outliers
    )
  }
)


testthat::test_that(
  "taxon above min_records threshold with within-taxon outlier is flagged",
  {
    # LargeTaxon: 11 records -- 10 clustered around 11, one extreme at 9999.
    # Within-taxon: IQR of the 10 normal records = 2, median = 11.
    # |9999 - 11| = 9988 >> 1.5 * 2 = 3 => flagged.
    # NormalTaxon: 15 records, all normal => not flagged.
    data_traits <-
      tibble::tibble(
        taxon_name = base::c(
          base::rep("LargeTaxon", 11L),
          base::rep("NormalTaxon", 15L)
        ),
        trait_domain_name = base::rep("SLA", 26L),
        trait_name = base::rep("LMA", 26L),
        trait_value = base::c(
          # LargeTaxon: 10 normal + 1 extreme
          base::c(
            base::rep(base::c(10, 11, 12), times = 3L),
            11,
            9999
          ),
          # NormalTaxon: all tightly clustered
          base::rep(base::c(10, 11, 12), times = 5L)
        )
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        min_records_per_taxon = 10L,
        outlier_iqr_multiplier_taxon = 1.5
      )

    vec_taxon_outliers <-
      purrr::chuck(list_result, "suspected_outlier_taxa_taxon")

    testthat::expect_true(
      "LargeTaxon" %in% vec_taxon_outliers
    )

    testthat::expect_false(
      "NormalTaxon" %in% vec_taxon_outliers
    )
  }
)


testthat::test_that(
  "taxon-level check does not flag when taxon_IQR is zero",
  {
    # AllSame: 12 identical records; IQR = 0 -- no outlier can be defined.
    data_traits <-
      tibble::tibble(
        taxon_name = base::rep("AllSame", 12L),
        trait_domain_name = base::rep("SLA", 12L),
        trait_name = base::rep("LMA", 12L),
        trait_value = base::rep(10, 12L)
      )

    path_temp <-
      base::tempfile(fileext = ".csv")

    list_result <-
      call_generate_trait_qc_report(
        data_traits = data_traits,
        path_corrections = path_temp,
        min_records_per_taxon = 10L
      )

    vec_taxon_outliers <-
      purrr::chuck(list_result, "suspected_outlier_taxa_taxon")

    testthat::expect_length(vec_taxon_outliers, 0L)
  }
)
