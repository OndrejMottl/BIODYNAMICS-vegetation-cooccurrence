list_programmatic_triage_test_inputs <- base::local({
  vec_candidate_ids <-
    base::vapply(
      base::letters[1:4],
      digest::digest,
      base::character(1L),
      algo = "sha256",
      serialize = FALSE
    ) |>
    base::unname()
  data_candidates <-
    tibble::tibble(
      candidate_id = vec_candidate_ids,
      taxon_name = stringr::str_c("Taxon ", base::LETTERS[1:4]),
      trait_domain_name = "Leaf Area",
      deterministic_outcome = "investigate_submitted_note",
      n_records_current = 2L,
      candidate_impact_score = base::c(0.2, 0.3, 0.4, 0.5)
    )
  data_datasets <-
    tibble::tibble(
      candidate_id = base::rep(vec_candidate_ids, each = 2L),
      taxon_name = base::rep(
        stringr::str_c("Taxon ", base::LETTERS[1:4]),
        each = 2L
      ),
      trait_domain_name = "Leaf Area",
      dataset_id = base::rep(base::c(1L, 2L), times = 4L),
      dataset_name = base::rep(base::c("Source A", "Source B"), times = 4L),
      trait_name = "Leaf area",
      n_records_source = 1L,
      source_median = base::c(1, 10, 2, 20, 3, 30, 4, 5)
    )
  data_records <-
    data_datasets |>
    dplyr::mutate(trait_value = .data[["source_median"]]) |>
    dplyr::select(
      "candidate_id",
      "taxon_name",
      "trait_domain_name",
      "dataset_id",
      "dataset_name",
      "trait_name",
      "trait_value"
    )
  data_decisions <-
    tibble::tibble(
      candidate_id = character(),
      review_status = character()
    )
  data_proposals <-
    tibble::tibble(
      decision_id = character(),
      candidate_id = character(),
      taxon_name = character(),
      trait_domain_name = character(),
      trait_name = character(),
      dataset_id = integer(),
      value_lower = double(),
      value_lower_inclusive = logical(),
      value_upper = double(),
      value_upper_inclusive = logical(),
      action = character(),
      scale_factor = double(),
      proposal_match_status = character()
    )
  data_adjudications <-
    tibble::tibble(
      candidate_id = character(),
      review_role = character(),
      recommendation = character(),
      evidence_reference = character()
    )
  base::list(
    candidates = data_candidates,
    decisions = data_decisions,
    proposals = data_proposals,
    datasets = data_datasets,
    records = data_records,
    adjudications = data_adjudications
  )
})

testthat::test_that(
  "programmatic triage groups repeated source-factor evidence",
  {
    list_inputs <-
      list_programmatic_triage_test_inputs

    res <-
      build_trait_review_programmatic_triage(
        data_candidate_recommendations = list_inputs[["candidates"]],
        data_approved_decisions = list_inputs[["decisions"]],
        data_proposal_diagnostics = list_inputs[["proposals"]],
        data_dataset_evidence = list_inputs[["datasets"]],
        data_record_evidence = list_inputs[["records"]],
        data_agent_adjudications = list_inputs[["adjudications"]],
        evidence_reference = "triage-report.md"
      )
    data_triage <-
      res[["data_candidate_triage"]]
    data_groups <-
      res[["data_exception_groups"]]

    testthat::expect_equal(
      base::sum(data_triage[["requires_agent"]]),
      3L
    )
    testthat::expect_equal(base::nrow(data_groups), 1L)
    testthat::expect_equal(data_groups[["group_kind"]], "source_pattern")
    testthat::expect_equal(data_groups[["n_candidates"]], 3L)
    testthat::expect_equal(
      base::sum(data_triage[["propose_none"]]),
      0L
    )
    testthat::expect_equal(
      data_triage[["triage_outcome"]][[4L]],
      "pending_submitted_note"
    )
  }
)

testthat::test_that(
  "programmatic triage groups recovered rules across taxa",
  {
    list_inputs <-
      list_programmatic_triage_test_inputs
    vec_candidate_ids <-
      list_inputs[["candidates"]][["candidate_id"]][1:2]
    data_candidates <-
      list_inputs[["candidates"]] |>
      dplyr::slice_head(n = 2L)
    data_proposals <-
      tibble::tibble(
        decision_id = base::vapply(
          vec_candidate_ids,
          digest::digest,
          base::character(1L),
          algo = "sha256",
          serialize = FALSE
        ),
        candidate_id = vec_candidate_ids,
        taxon_name = data_candidates[["taxon_name"]],
        trait_domain_name = "Leaf Area",
        trait_name = NA_character_,
        dataset_id = NA_integer_,
        value_lower = 100,
        value_lower_inclusive = TRUE,
        value_upper = NA_real_,
        value_upper_inclusive = NA,
        action = "exclude",
        scale_factor = NA_real_,
        proposal_match_status = "matched_selector"
      )

    res <-
      build_trait_review_programmatic_triage(
        data_candidate_recommendations = data_candidates,
        data_approved_decisions = list_inputs[["decisions"]],
        data_proposal_diagnostics = data_proposals,
        data_dataset_evidence =
          dplyr::slice_head(list_inputs[["datasets"]], n = 4L),
        data_record_evidence =
          dplyr::slice_head(list_inputs[["records"]], n = 4L),
        data_agent_adjudications = list_inputs[["adjudications"]],
        evidence_reference = "triage-report.md"
      )

    testthat::expect_equal(
      res[["data_exception_groups"]][["group_kind"]],
      "recovered_rule"
    )
    testthat::expect_equal(
      res[["data_exception_groups"]][["n_candidates"]],
      2L
    )
    testthat::expect_equal(
      base::sum(res[["data_candidate_triage"]][["requires_agent"]]),
      2L
    )
  }
)

testthat::test_that(
  "programmatic triage resolves completed and unsupported cases to none",
  {
    list_inputs <-
      list_programmatic_triage_test_inputs
    data_candidates <-
      list_inputs[["candidates"]] |>
      dplyr::slice_tail(n = 1L)
    candidate_id <- data_candidates[["candidate_id"]][[1L]]
    data_adjudications <-
      tibble::tibble(
        candidate_id = candidate_id,
        review_role = "adjudicator",
        recommendation = "insufficient_evidence",
        evidence_reference = "accepted/adjudication.csv"
      )

    res <-
      build_trait_review_programmatic_triage(
        data_candidate_recommendations = data_candidates,
        data_approved_decisions = list_inputs[["decisions"]],
        data_proposal_diagnostics = list_inputs[["proposals"]],
        data_dataset_evidence =
          dplyr::slice_tail(list_inputs[["datasets"]], n = 2L),
        data_record_evidence =
          dplyr::slice_tail(list_inputs[["records"]], n = 2L),
        data_agent_adjudications = data_adjudications,
        evidence_reference = "triage-report.md"
      )
    data_none <- res[["data_none_proposals"]]

    testthat::expect_equal(base::nrow(data_none), 1L)
    testthat::expect_equal(data_none[["candidate_id"]], candidate_id)
    testthat::expect_equal(data_none[["action"]], "none")
    testthat::expect_equal(data_none[["review_status"]], "proposed")
    testthat::expect_true(
      stringr::str_detect(data_none[["decision_id"]], "^[0-9a-f]{64}$")
    )
    testthat::expect_equal(
      res[["data_candidate_triage"]][["triage_outcome"]],
      "propose_none_completed_investigation"
    )
  }
)

testthat::test_that(
  "programmatic triage escalates invalid records by source",
  {
    list_inputs <-
      list_programmatic_triage_test_inputs
    data_candidates <-
      list_inputs[["candidates"]] |>
      dplyr::slice_head(n = 1L)
    data_records <-
      list_inputs[["records"]] |>
      dplyr::slice_head(n = 2L) |>
      dplyr::mutate(
        trait_value = base::c(-1, 1)
      )

    res <-
      build_trait_review_programmatic_triage(
        data_candidate_recommendations = data_candidates,
        data_approved_decisions = list_inputs[["decisions"]],
        data_proposal_diagnostics = list_inputs[["proposals"]],
        data_dataset_evidence =
          dplyr::slice_head(list_inputs[["datasets"]], n = 2L),
        data_record_evidence = data_records,
        data_agent_adjudications = list_inputs[["adjudications"]],
        evidence_reference = "triage-report.md"
      )

    testthat::expect_equal(
      res[["data_exception_groups"]][["group_kind"]],
      "invalid_source"
    )
    testthat::expect_equal(
      res[["data_candidate_triage"]][["triage_outcome"]],
      "agent_invalid_values"
    )
  }
)

testthat::test_that(
  "programmatic triage treats missing values separately from invalid values",
  {
    list_inputs <-
      list_programmatic_triage_test_inputs
    data_candidates <-
      list_inputs[["candidates"]] |>
      dplyr::slice_head(n = 1L)
    data_records_missing <-
      list_inputs[["records"]] |>
      dplyr::slice_head(n = 2L) |>
      dplyr::mutate(trait_value = base::c(NA_real_, 1))

    res_missing <-
      build_trait_review_programmatic_triage(
        data_candidate_recommendations = data_candidates,
        data_approved_decisions = list_inputs[["decisions"]],
        data_proposal_diagnostics = list_inputs[["proposals"]],
        data_dataset_evidence =
          dplyr::slice_head(list_inputs[["datasets"]], n = 2L),
        data_record_evidence = data_records_missing,
        data_agent_adjudications = list_inputs[["adjudications"]],
        evidence_reference = "triage-report.md"
      )

    testthat::expect_equal(
      res_missing[["data_candidate_triage"]][["triage_outcome"]],
      "pending_isolated_source_pattern"
    )
    testthat::expect_equal(
      base::nrow(res_missing[["data_exception_memberships"]]),
      0L
    )

    data_records_nan <-
      data_records_missing |>
      dplyr::mutate(trait_value = base::c(NaN, 1))
    res_nan <-
      build_trait_review_programmatic_triage(
        data_candidate_recommendations = data_candidates,
        data_approved_decisions = list_inputs[["decisions"]],
        data_proposal_diagnostics = list_inputs[["proposals"]],
        data_dataset_evidence =
          dplyr::slice_head(list_inputs[["datasets"]], n = 2L),
        data_record_evidence = data_records_nan,
        data_agent_adjudications = list_inputs[["adjudications"]],
        evidence_reference = "triage-report.md"
      )

    testthat::expect_equal(
      res_nan[["data_candidate_triage"]][["triage_outcome"]],
      "agent_invalid_values"
    )
  }
)

testthat::test_that(
  "programmatic triage checks finite patterns after ignoring missing values",
  {
    list_inputs <-
      list_programmatic_triage_test_inputs
    data_records <-
      dplyr::bind_rows(
        list_inputs[["records"]],
        list_inputs[["records"]] |>
          dplyr::slice_head(n = 1L) |>
          dplyr::mutate(trait_value = NA_real_)
      )

    res <-
      build_trait_review_programmatic_triage(
        data_candidate_recommendations = list_inputs[["candidates"]],
        data_approved_decisions = list_inputs[["decisions"]],
        data_proposal_diagnostics = list_inputs[["proposals"]],
        data_dataset_evidence = list_inputs[["datasets"]],
        data_record_evidence = data_records,
        data_agent_adjudications = list_inputs[["adjudications"]],
        evidence_reference = "triage-report.md"
      )
    data_triage <-
      res[["data_candidate_triage"]]

    testthat::expect_equal(
      base::sum(
        data_triage[["triage_outcome"]] ==
          "agent_repeated_source_pattern"
      ),
      3L
    )
    testthat::expect_equal(
      base::unique(res[["data_exception_groups"]][["group_kind"]]),
      "source_pattern"
    )
  }
)

testthat::test_that(
  "programmatic triage excludes approved candidates and reports cost gate",
  {
    list_inputs <-
      list_programmatic_triage_test_inputs
    data_decisions <-
      tibble::tibble(
        candidate_id =
          list_inputs[["candidates"]][["candidate_id"]][[1L]],
        review_status = "approved"
      )

    res <-
      build_trait_review_programmatic_triage(
        data_candidate_recommendations = list_inputs[["candidates"]],
        data_approved_decisions = data_decisions,
        data_proposal_diagnostics = list_inputs[["proposals"]],
        data_dataset_evidence = list_inputs[["datasets"]],
        data_record_evidence = list_inputs[["records"]],
        data_agent_adjudications = list_inputs[["adjudications"]],
        evidence_reference = "triage-report.md",
        min_source_pattern_candidates = 4L
      )
    data_cost_gate <- res[["data_cost_gate"]]

    testthat::expect_equal(
      base::nrow(res[["data_candidate_triage"]]),
      3L
    )
    testthat::expect_equal(data_cost_gate[["n_pending_candidates"]], 3L)
    testthat::expect_equal(data_cost_gate[["n_agent_candidates"]], 0L)
    testthat::expect_equal(data_cost_gate[["n_none_proposals"]], 0L)
    testthat::expect_equal(
      data_cost_gate[["n_pending_programmatic_candidates"]],
      3L
    )
  }
)

testthat::test_that(
  "programmatic triage retains isolated source factors for review",
  {
    list_inputs <-
      list_programmatic_triage_test_inputs
    data_candidates <-
      list_inputs[["candidates"]] |>
      dplyr::slice_head(n = 1L)

    res <-
      build_trait_review_programmatic_triage(
        data_candidate_recommendations = data_candidates,
        data_approved_decisions = list_inputs[["decisions"]],
        data_proposal_diagnostics = list_inputs[["proposals"]],
        data_dataset_evidence =
          dplyr::slice_head(list_inputs[["datasets"]], n = 2L),
        data_record_evidence =
          dplyr::slice_head(list_inputs[["records"]], n = 2L),
        data_agent_adjudications = list_inputs[["adjudications"]],
        evidence_reference = "triage-report.md",
        min_source_pattern_candidates = 2L
      )
    data_triage <-
      res[["data_candidate_triage"]]

    testthat::expect_equal(
      data_triage[["triage_outcome"]],
      "pending_isolated_source_pattern"
    )
    testthat::expect_false(data_triage[["propose_none"]])
    testthat::expect_false(data_triage[["requires_agent"]])
    testthat::expect_true(data_triage[["pending_programmatic"]])
    testthat::expect_equal(
      res[["data_cost_gate"]][["n_pending_programmatic_candidates"]],
      1L
    )
  }
)

testthat::test_that(
  "programmatic triage validates required columns and tuning arguments",
  {
    list_inputs <-
      list_programmatic_triage_test_inputs
    data_candidates_invalid <-
      dplyr::select(list_inputs[["candidates"]], -"candidate_id")

    testthat::expect_error(
      build_trait_review_programmatic_triage(
        data_candidate_recommendations = data_candidates_invalid,
        data_approved_decisions = list_inputs[["decisions"]],
        data_proposal_diagnostics = list_inputs[["proposals"]],
        data_dataset_evidence = list_inputs[["datasets"]],
        data_record_evidence = list_inputs[["records"]],
        data_agent_adjudications = list_inputs[["adjudications"]],
        evidence_reference = "triage-report.md"
      ),
      "missing required columns"
    )
    testthat::expect_error(
      build_trait_review_programmatic_triage(
        data_candidate_recommendations = list_inputs[["candidates"]],
        data_approved_decisions = list_inputs[["decisions"]],
        data_proposal_diagnostics = list_inputs[["proposals"]],
        data_dataset_evidence = list_inputs[["datasets"]],
        data_record_evidence = list_inputs[["records"]],
        data_agent_adjudications = list_inputs[["adjudications"]],
        evidence_reference = "triage-report.md",
        min_source_pattern_candidates = 0L
      ),
      "positive integer"
    )
  }
)

testthat::test_that(
  "programmatic triage handles many source groups without pair expansion",
  {
    list_inputs <-
      list_programmatic_triage_test_inputs
    data_candidates <-
      list_inputs[["candidates"]] |>
      dplyr::slice_head(n = 1L)
    candidate_id <- data_candidates[["candidate_id"]][[1L]]
    data_datasets <-
      tibble::tibble(
        candidate_id = candidate_id,
        taxon_name = "Taxon A",
        trait_domain_name = "Leaf Area",
        dataset_id = base::seq_len(1000L),
        dataset_name = stringr::str_c(
          "Source ",
          base::seq_len(1000L)
        ),
        trait_name = "Leaf area",
        n_records_source = 1L,
        source_median = base::seq_len(1000L)
      )
    data_records <-
      data_datasets |>
      dplyr::mutate(trait_value = .data[["source_median"]]) |>
      dplyr::select(
        "candidate_id",
        "taxon_name",
        "trait_domain_name",
        "dataset_id",
        "dataset_name",
        "trait_name",
        "trait_value"
      )

    res <-
      build_trait_review_programmatic_triage(
        data_candidate_recommendations = data_candidates,
        data_approved_decisions = list_inputs[["decisions"]],
        data_proposal_diagnostics = list_inputs[["proposals"]],
        data_dataset_evidence = data_datasets,
        data_record_evidence = data_records,
        data_agent_adjudications = list_inputs[["adjudications"]],
        evidence_reference = "triage-report.md"
      )

    testthat::expect_equal(
      base::nrow(res[["data_candidate_triage"]]),
      1L
    )
    testthat::expect_equal(
      base::nrow(res[["data_source_pairs"]]),
      1L
    )
  }
)
