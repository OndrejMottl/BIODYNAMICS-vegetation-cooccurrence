# ── Helpers ───────────────────────────────────────────────────────────── #

make_clean_traits <- function() {
  tibble::tibble(
    dataset_id = base::c(10L, 10L, 11L),
    dataset_name = base::c("A", "A", "B"),
    data_source_id = base::c(294L, 294L, 509L),
    sample_id = base::c(100L, 101L, 102L),
    trait_id = base::c(200L, 201L, 202L),
    taxon_id = base::c(1L, 2L, 3L),
    trait_domain_name = base::c("SLA", "SLA", "Height"),
    trait_name = base::c("sla_mm", "sla_mm", "h_m"),
    trait_value = base::c(10.0, 12.0, 3.0)
  )
}

path_fake <- "nonexistent.sqlite"

# ── data_trait_records type checks ─────────────────────────────────── #

testthat::test_that(
  "resolve_trait_taxon_ids() errors when data_trait_records not a data frame",
  {
    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_trait_records = "not a df",
        path_vegvault = path_fake
      )
    )

    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_trait_records = NULL,
        path_vegvault = path_fake
      )
    )

    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_trait_records = 1L,
        path_vegvault = path_fake
      )
    )
  }
)

testthat::test_that(
  "resolve_trait_taxon_ids() errors when taxon_id column missing",
  {
    data_no_id <-
      tibble::tibble(
        trait_domain_name = "SLA",
        trait_value = 10.0
      )
    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_trait_records = data_no_id,
        path_vegvault = path_fake
      )
    )
  }
)

# ── path_vegvault checks ───────────────────────────────────────────── #

testthat::test_that(
  "resolve_trait_taxon_ids() errors for non-character path",
  {
    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_trait_records = make_clean_traits(),
        path_vegvault = 123
      )
    )

    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_trait_records = make_clean_traits(),
        path_vegvault = TRUE
      )
    )
  }
)

testthat::test_that(
  "resolve_trait_taxon_ids() errors for path length > 1",
  {
    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_trait_records = make_clean_traits(),
        path_vegvault = base::c("a.sqlite", "b.sqlite")
      )
    )
  }
)

testthat::test_that(
  "resolve_trait_taxon_ids() errors for missing db file",
  {
    testthat::expect_error(
      resolve_trait_taxon_ids(
        data_trait_records = make_clean_traits(),
        path_vegvault = "nonexistent_path.sqlite"
      )
    )
  }
)

# ── Output structure ──────────────────────────────────────────────────── #

testthat::test_that(
  "resolve_trait_taxon_ids() retains source identifiers",
  {
    # We can only verify column names by using a mock/temp SQLite DB
    tmp_db <-
      base::tempfile(fileext = ".sqlite")

    con <-
      DBI::dbConnect(RSQLite::SQLite(), tmp_db)

    DBI::dbWriteTable(
      con,
      "Taxa",
      tibble::tibble(
        taxon_id = base::c(1L, 2L, 3L),
        taxon_name = base::c("Quercus", "Betula", "Pinus")
      )
    )

    DBI::dbDisconnect(con)

    res <-
      resolve_trait_taxon_ids(
        data_trait_records = make_clean_traits(),
        path_vegvault = tmp_db
      )

    testthat::expect_true(
      base::all(
        base::c(
          "dataset_id",
          "dataset_name",
          "data_source_id",
          "sample_id",
          "trait_id",
          "taxon_id"
        ) %in% base::colnames(res)
      )
    )

    testthat::expect_true(
      "taxon_name" %in% base::colnames(res)
    )

    testthat::expect_true(
      "trait_domain_name" %in% base::colnames(res)
    )

    testthat::expect_true(
      "trait_name" %in% base::colnames(res)
    )

    testthat::expect_true(
      "trait_value" %in% base::colnames(res)
    )
  }
)

testthat::test_that(
  "resolve_trait_taxon_ids() keeps the unit and rule columns",
  {
    path_vault <-
      withr::local_tempfile(fileext = ".sqlite")

    connection_vault <-
      DBI::dbConnect(RSQLite::SQLite(), path_vault)

    DBI::dbWriteTable(
      connection_vault,
      "Taxa",
      tibble::tibble(
        taxon_id = base::c(1L, 2L, 3L),
        taxon_name = base::c("Quercus", "Betula", "Pinus")
      )
    )

    DBI::dbDisconnect(connection_vault)

    data_traits_with_units <-
      make_clean_traits() |>
      dplyr::mutate(
        trait_unit = base::c("mg/mm2", "mg/mm2", "m"),
        conversion_rule_key = base::c(
          "bien_sla",
          "bien_sla",
          "bien_height"
        ),
        derivation_rule_key = base::c(
          "sla_to_lma",
          "sla_to_lma",
          NA_character_
        )
      )

    res <-
      resolve_trait_taxon_ids(
        data_trait_records = data_traits_with_units,
        path_vegvault = path_vault
      )

    testthat::expect_named(
      res,
      base::c(
        "taxon_name",
        "dataset_id",
        "dataset_name",
        "data_source_id",
        "sample_id",
        "trait_id",
        "taxon_id",
        "trait_domain_name",
        "trait_name",
        "trait_value",
        "trait_unit",
        "conversion_rule_key",
        "derivation_rule_key"
      )
    )
    testthat::expect_equal(
      dplyr::pull(res, trait_unit),
      base::c("mg/mm2", "mg/mm2", "m")
    )
    testthat::expect_equal(
      dplyr::pull(res, derivation_rule_key),
      base::c("sla_to_lma", "sla_to_lma", NA_character_)
    )
  }
)

testthat::test_that(
  "resolve_trait_taxon_ids() returns correct taxon names",
  {
    tmp_db <-
      base::tempfile(fileext = ".sqlite")

    con <-
      DBI::dbConnect(RSQLite::SQLite(), tmp_db)

    DBI::dbWriteTable(
      con,
      "Taxa",
      tibble::tibble(
        taxon_id = base::c(1L, 2L, 3L),
        taxon_name = base::c("Quercus", "Betula", "Pinus")
      )
    )

    DBI::dbDisconnect(con)

    res <-
      resolve_trait_taxon_ids(
        data_trait_records = make_clean_traits(),
        path_vegvault = tmp_db
      )

    testthat::expect_equal(
      base::sort(dplyr::pull(res, "taxon_name")),
      base::c("Betula", "Pinus", "Quercus")
    )
  }
)

testthat::test_that(
  "resolve_trait_taxon_ids() returns same row count as input",
  {
    tmp_db <-
      base::tempfile(fileext = ".sqlite")

    con <-
      DBI::dbConnect(RSQLite::SQLite(), tmp_db)

    DBI::dbWriteTable(
      con,
      "Taxa",
      tibble::tibble(
        taxon_id = base::c(1L, 2L, 3L),
        taxon_name = base::c("Quercus", "Betula", "Pinus")
      )
    )

    DBI::dbDisconnect(con)

    data_input <-
      make_clean_traits()

    res <-
      resolve_trait_taxon_ids(
        data_trait_records = data_input,
        path_vegvault = tmp_db
      )

    testthat::expect_equal(
      base::nrow(res),
      base::nrow(data_input)
    )
  }
)

testthat::test_that(
  "resolve_trait_taxon_ids() returns a data frame",
  {
    tmp_db <-
      base::tempfile(fileext = ".sqlite")

    con <-
      DBI::dbConnect(RSQLite::SQLite(), tmp_db)

    DBI::dbWriteTable(
      con,
      "Taxa",
      tibble::tibble(
        taxon_id = 1L,
        taxon_name = "Quercus"
      )
    )

    DBI::dbDisconnect(con)

    data_one <-
      tibble::tibble(
        taxon_id = 1L,
        trait_domain_name = "SLA",
        trait_name = "sla_mm",
        trait_value = 10.0
      )

    res <-
      resolve_trait_taxon_ids(
        data_trait_records = data_one,
        path_vegvault = tmp_db
      )

    testthat::expect_true(base::is.data.frame(res))
  }
)
