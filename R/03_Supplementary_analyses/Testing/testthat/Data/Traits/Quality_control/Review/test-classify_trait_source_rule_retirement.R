# -- Helpers ---------------------------------------------------------------

make_retirement_rules <- function() {
  tibble::tibble(
    source_scale_rule_id = base::c("rule_a", "rule_b", "rule_c", "rule_d"),
    data_source_id = base::c(10L, 20L, 30L, 40L),
    expected_data_source_desc = base::c(
      "Source A",
      "Source B",
      "Source C",
      "Source D"
    ),
    trait_domain_name = base::c(
      "Leaf Area",
      "Leaf Area",
      "Plant heigh",
      "Stem specific density"
    ),
    trait_name = NA_character_,
    scale_factor = base::c(100, 100, 100, 0.001)
  )
}

make_retirement_records <- function(
    vec_source_ids,
    trait_domain_name,
    vec_values,
    vec_taxa = base::c("t1", "t2", "t3", "t4")) {
  tidyr::expand_grid(
    data_source_id = vec_source_ids,
    taxon_name = vec_taxa
  ) |>
    dplyr::mutate(
      trait_domain_name = trait_domain_name,
      trait_name = "trait",
      trait_value = vec_values
    )
}

make_retirement_sources_after <- function() {
  tibble::tibble(
    data_source_id = base::c(110L, 120L, 140L, 199L),
    data_source_desc = base::c(
      "Source A",
      "Source B",
      "Source D",
      "Reference"
    )
  )
}

make_retirement_records_before <- function() {
  dplyr::bind_rows(
    make_retirement_records(10L, "Leaf Area", base::c(1, 2, 3, 4)),
    make_retirement_records(20L, "Leaf Area", base::c(1, 2, 3, 4)),
    make_retirement_records(99L, "Leaf Area", base::c(50, 60, 70, 80)),
    make_retirement_records(30L, "Plant heigh", base::c(1, 2, 3, 4)),
    make_retirement_records(99L, "Plant heigh", base::c(5, 6, 7, 8)),
    make_retirement_records(
      40L,
      "Stem specific density",
      base::c(500, 600, 700, 800)
    ),
    make_retirement_records(
      99L,
      "Stem specific density",
      base::c(0.5, 0.6, 0.7, 0.8)
    )
  )
}

make_retirement_records_after <- function(reference_ratio = 1) {
  dplyr::bind_rows(
    make_retirement_records(
      110L,
      "Leaf Area",
      base::c(100, 200, 300, 400) * reference_ratio
    ),
    make_retirement_records(
      120L,
      "Leaf Area",
      base::c(1, 2, 3, 4) * reference_ratio
    ),
    make_retirement_records(
      199L,
      "Leaf Area",
      base::c(50, 60, 70, 80) * reference_ratio
    ),
    make_retirement_records(199L, "Plant heigh", base::c(5, 6, 7, 8)),
    make_retirement_records(
      140L,
      "Stem specific density",
      base::c(0.5, 0.6, 0.7, 0.8)
    ),
    make_retirement_records(
      199L,
      "Stem specific density",
      base::c(0.5, 0.6, 0.7, 0.8)
    )
  )
}

# -- Output ----------------------------------------------------------------

testthat::test_that(
  "classify_trait_source_rule_retirement() returns one row per rule",
  {
    res <-
      classify_trait_source_rule_retirement(
        data_source_scale_rules = make_retirement_rules(),
        data_trait_records_before = make_retirement_records_before(),
        data_trait_records_after = make_retirement_records_after(),
        data_sources_after = make_retirement_sources_after()
      )

    testthat::expect_s3_class(res, "tbl_df")
    testthat::expect_equal(
      dplyr::pull(res, source_scale_rule_id),
      base::c("rule_a", "rule_b", "rule_c", "rule_d")
    )
    testthat::expect_true(
      base::all(
        base::c(
          "data_source_id",
          "expected_data_source_desc",
          "trait_domain_name",
          "scale_factor",
          "data_source_id_after",
          "n_taxa_before",
          "n_taxa_after",
          "n_taxa_shared",
          "ratio_source",
          "ratio_reference",
          "scale_exponent",
          "retirement_status"
        ) %in%
          base::names(res)
      )
    )
  }
)

# -- Classification --------------------------------------------------------

testthat::test_that(
  "classify_trait_source_rule_retirement() separates fixed and unscaled",
  {
    res <-
      classify_trait_source_rule_retirement(
        data_source_scale_rules = make_retirement_rules(),
        data_trait_records_before = make_retirement_records_before(),
        data_trait_records_after = make_retirement_records_after(),
        data_sources_after = make_retirement_sources_after()
      )

    testthat::expect_equal(
      dplyr::pull(res, retirement_status),
      base::c(
        "fixed_at_source",
        "still_unscaled",
        "absent_from_release",
        "fixed_at_source"
      )
    )
    testthat::expect_equal(
      dplyr::pull(res, data_source_id_after),
      base::c(110L, 120L, NA_integer_, 140L)
    )
    testthat::expect_equal(
      dplyr::pull(res, scale_exponent)[base::c(1L, 2L, 4L)],
      base::c(1, 0, 1),
      tolerance = 1e-8
    )
    testthat::expect_equal(
      dplyr::pull(res, n_taxa_shared),
      base::c(4L, 4L, 0L, 4L)
    )
  }
)

testthat::test_that(
  "classify_trait_source_rule_retirement() removes domain unit changes",
  {
    res <-
      classify_trait_source_rule_retirement(
        data_source_scale_rules = make_retirement_rules()[1:2, ],
        data_trait_records_before = make_retirement_records_before(),
        data_trait_records_after = make_retirement_records_after(
          reference_ratio = 10
        ),
        data_sources_after = make_retirement_sources_after()
      )

    testthat::expect_equal(
      dplyr::pull(res, ratio_reference),
      base::c(10, 10),
      tolerance = 1e-8
    )
    testthat::expect_equal(
      dplyr::pull(res, retirement_status),
      base::c("fixed_at_source", "still_unscaled")
    )
  }
)

testthat::test_that(
  "classify_trait_source_rule_retirement() leaves unclear rules unresolved",
  {
    data_records_after <-
      make_retirement_records_after() |>
      dplyr::mutate(
        trait_value = dplyr::if_else(
          .data[["data_source_id"]] == 120L,
          .data[["trait_value"]] * 10,
          .data[["trait_value"]]
        )
      ) |>
      dplyr::filter(
        !(.data[["data_source_id"]] == 110L &
          .data[["taxon_name"]] %in% base::c("t3", "t4"))
      )

    res <-
      classify_trait_source_rule_retirement(
        data_source_scale_rules = make_retirement_rules()[1:2, ],
        data_trait_records_before = make_retirement_records_before(),
        data_trait_records_after = data_records_after,
        data_sources_after = make_retirement_sources_after()
      )

    testthat::expect_equal(
      dplyr::pull(res, retirement_status),
      base::c("unresolved", "unresolved")
    )
    testthat::expect_equal(
      dplyr::pull(res, scale_exponent)[[2L]],
      0.5,
      tolerance = 1e-8
    )
  }
)

testthat::test_that(
  "classify_trait_source_rule_retirement() marks sources without records",
  {
    data_records_after <-
      make_retirement_records_after() |>
      dplyr::filter(.data[["data_source_id"]] != 140L)

    res <-
      classify_trait_source_rule_retirement(
        data_source_scale_rules = make_retirement_rules()[4L, ],
        data_trait_records_before = make_retirement_records_before(),
        data_trait_records_after = data_records_after,
        data_sources_after = make_retirement_sources_after()
      )

    testthat::expect_equal(
      dplyr::pull(res, retirement_status),
      "absent_from_release"
    )
    testthat::expect_equal(dplyr::pull(res, data_source_id_after), 140L)
    testthat::expect_equal(dplyr::pull(res, n_taxa_after), 0L)
  }
)

testthat::test_that(
  "classify_trait_source_rule_retirement() keeps to the rule's trait name",
  {
    data_rules <-
      make_retirement_rules()[1L, ] |>
      dplyr::mutate(trait_name = "trait")
    data_records_after <-
      make_retirement_records_after() |>
      dplyr::bind_rows(
        make_retirement_records(
          110L,
          "Leaf Area",
          base::c(1, 2, 3, 4)
        ) |>
          dplyr::mutate(trait_name = "other trait")
      )

    res <-
      classify_trait_source_rule_retirement(
        data_source_scale_rules = data_rules,
        data_trait_records_before = make_retirement_records_before(),
        data_trait_records_after = data_records_after,
        data_sources_after = make_retirement_sources_after()
      )

    testthat::expect_equal(
      dplyr::pull(res, retirement_status),
      "fixed_at_source"
    )
  }
)

# -- Arguments -------------------------------------------------------------

testthat::test_that(
  "classify_trait_source_rule_retirement() validates its arguments",
  {
    testthat::expect_error(
      classify_trait_source_rule_retirement(
        data_source_scale_rules = make_retirement_rules() |>
          dplyr::select(-"scale_factor"),
        data_trait_records_before = make_retirement_records_before(),
        data_trait_records_after = make_retirement_records_after(),
        data_sources_after = make_retirement_sources_after()
      ),
      regexp = "missing required columns"
    )
    testthat::expect_error(
      classify_trait_source_rule_retirement(
        data_source_scale_rules = make_retirement_rules(),
        data_trait_records_before = make_retirement_records_before(),
        data_trait_records_after = make_retirement_records_after() |>
          dplyr::select(-"taxon_name"),
        data_sources_after = make_retirement_sources_after()
      ),
      regexp = "missing required columns"
    )
    purrr::walk(
      .x = base::list(0.5, -0.1, NA_real_, base::c(0.1, 0.2)),
      .f = ~ testthat::expect_error(
        classify_trait_source_rule_retirement(
          data_source_scale_rules = make_retirement_rules(),
          data_trait_records_before = make_retirement_records_before(),
          data_trait_records_after = make_retirement_records_after(),
          data_sources_after = make_retirement_sources_after(),
          exponent_tolerance = .x
        ),
        regexp = "'exponent_tolerance' must be"
      )
    )
    testthat::expect_error(
      classify_trait_source_rule_retirement(
        data_source_scale_rules = make_retirement_rules(),
        data_trait_records_before = make_retirement_records_before(),
        data_trait_records_after = make_retirement_records_after(),
        data_sources_after = make_retirement_sources_after(),
        min_shared_taxa = 0L
      ),
      regexp = "'min_shared_taxa' must be"
    )
  }
)
