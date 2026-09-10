#' @title Resolve the Preprocessing Worker Count
#' @description
#' Resolves a safe interpolation worker count from configured workers, a
#' resource profile, an explicit override, and currently available memory.
#' @param configured_workers
#' Positive integer worker count from the active analysis profile.
#' @param resource_profile
#' One of `shared`, `dedicated`, or `configured`.
#' @param workers_override
#' Optional explicit positive integer override. A non-empty value has highest
#' priority.
#' @param available_memory_bytes
#' Optional available-memory estimate in bytes. `NULL` queries `{ps}` when it
#' is available and otherwise skips the memory cap.
#' @return
#' A single positive integer worker count.
#' @details
#' The shared and dedicated profiles cap concurrency at four and eight workers,
#' respectively. The configured profile preserves the analysis configuration.
#' A conservative memory admission rule reserves eight GiB and allows at most
#' one worker per four remaining GiB. The explicit override bypasses profile
#' caps but not the memory admission rule.
#' @export
resolve_preprocessing_worker_count <- function(
    configured_workers = NULL,
    resource_profile = "shared",
    workers_override = NULL,
    available_memory_bytes = NULL) {
  assertthat::assert_that(
    base::is.numeric(configured_workers),
    base::length(configured_workers) == 1L,
    base::is.finite(configured_workers),
    configured_workers >= 1L,
    configured_workers == base::as.integer(configured_workers),
    msg = "configured_workers must be one positive integer."
  )
  assertthat::assert_that(
    base::is.character(resource_profile),
    base::length(resource_profile) == 1L,
    !base::is.na(resource_profile),
    resource_profile %in% base::c("shared", "dedicated", "configured"),
    msg = "resource_profile must be shared, dedicated, or configured."
  )
  assertthat::assert_that(
    base::is.null(workers_override) ||
      base::is.character(workers_override) ||
      base::is.numeric(workers_override),
    base::is.null(workers_override) ||
      base::length(workers_override) == 1L,
    base::is.null(workers_override) || !base::is.na(workers_override),
    msg = "workers_override must be NULL or one value."
  )

  flag_has_override <-
    !base::is.null(workers_override) &&
    base::nzchar(base::as.character(workers_override))
  selected_workers <-
    if (
      flag_has_override
    ) {
      base::suppressWarnings(base::as.numeric(workers_override))
    } else {
      base::as.numeric(configured_workers)
    }
  assertthat::assert_that(
    base::is.finite(selected_workers),
    selected_workers >= 1L,
    selected_workers == base::as.integer(selected_workers),
    msg = "workers_override must be empty or one positive integer."
  )

  profile_cap <-
    base::switch(
      resource_profile,
      shared = 4L,
      dedicated = 8L,
      configured = base::as.integer(configured_workers)
    )
  workers_profiled <-
    if (
      flag_has_override
    ) {
      base::as.integer(selected_workers)
    } else {
      base::min(base::as.integer(selected_workers), profile_cap)
    }

  memory_bytes_resolved <-
    if (
      base::is.null(available_memory_bytes) &&
        base::requireNamespace("ps", quietly = TRUE)
    ) {
      base::tryCatch(
        ps::ps_system_memory()[["avail"]],
        error = function(error_captured) NA_real_
      )
    } else if (
      base::is.null(available_memory_bytes)
    ) {
      NA_real_
    } else {
      available_memory_bytes
    }
  assertthat::assert_that(
    base::is.numeric(memory_bytes_resolved),
    base::length(memory_bytes_resolved) == 1L,
    base::is.na(memory_bytes_resolved) ||
      (
        base::is.finite(memory_bytes_resolved) &&
          memory_bytes_resolved > 0
      ),
    msg = "available_memory_bytes must be NULL or one positive number."
  )

  memory_worker_cap <-
    if (
      base::is.na(memory_bytes_resolved)
    ) {
      workers_profiled
    } else {
      available_memory_gib <-
        memory_bytes_resolved / 1024^3
      base::max(
        1L,
        base::as.integer(base::floor((available_memory_gib - 8) / 4))
      )
    }
  res_workers <-
    base::as.integer(base::min(workers_profiled, memory_worker_cap))

  return(res_workers)
}
