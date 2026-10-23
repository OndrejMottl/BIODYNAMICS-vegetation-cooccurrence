#' @title Run or Reuse One Content-Matched Sensitivity Phase
#' @description
#' Evaluates a lazy phase expression and atomically saves successful results.
#' @param expr Lazy expression evaluated only on a cache miss.
#' @param path_checkpoint Optional directory for immutable RDS checkpoints.
#' @param signature Content signature including upstream scientific inputs.
#' @param phase Character phase identifier used in filenames and messages.
#' @param verbose Logical; print timestamped phase and reuse messages.
#' @return The computed or previously saved phase result.
#' @details
#' Errors and interrupted temporary files are never accepted as results.
#' @examples
#' run_sjsdm_sensitivity_checkpoint(
#'   expr = 42L,
#'   signature = "example_inputs",
#'   phase = "fit",
#'   verbose = FALSE
#' )
#' @export
run_sjsdm_sensitivity_checkpoint <- function(
    expr,
    path_checkpoint = NULL,
    signature,
    phase,
    verbose = TRUE) {
  assertthat::assert_that(
    assertthat::is.string(signature),
    !base::is.na(signature),
    base::nzchar(signature),
    msg = "signature must identify the scientific phase inputs."
  )
  assertthat::assert_that(
    assertthat::is.string(phase),
    !base::is.na(phase),
    stringr::str_detect(phase, "^[a-z][a-z0-9_]*$"),
    msg = "phase must be a safe lower-snake-case identifier."
  )
  assertthat::assert_that(
    base::is.null(path_checkpoint) ||
      (assertthat::is.string(path_checkpoint) &&
        !base::is.na(path_checkpoint) && base::nzchar(path_checkpoint)),
    assertthat::is.flag(verbose),
    !base::is.na(verbose),
    msg = "Supply a checkpoint directory or NULL and logical verbose."
  )
  file_checkpoint <-
    if (
      base::is.null(path_checkpoint)
    ) {
      NULL
    } else {
      fs::path(
        path_checkpoint,
        stringr::str_c(phase, "_", digest::digest(signature), ".rds")
      )
    }
  if (
    !base::is.null(file_checkpoint) && fs::file_exists(file_checkpoint)
  ) {
    list_checkpoint <-
      base::readRDS(file = file_checkpoint)
    if (
      !base::identical(list_checkpoint[["signature"]], signature) ||
        !base::identical(list_checkpoint[["phase"]], phase) ||
        !"result" %in% base::names(list_checkpoint)
    ) {
      cli::cli_abort("Incompatible sensitivity checkpoint: {file_checkpoint}")
    }
    if (
      base::isTRUE(verbose)
    ) {
      text_time <-
        base::format(base::Sys.time(), tz = "UTC", usetz = TRUE)
      cli::cli_inform(stringr::str_glue(
        "[{text_time}] ",
        "{phase}: reusing {file_checkpoint}"
      ))
    }
    return(list_checkpoint[["result"]])
  }
  if (
    base::isTRUE(verbose)
  ) {
    text_time <-
      base::format(base::Sys.time(), tz = "UTC", usetz = TRUE)
    cli::cli_inform(stringr::str_glue(
      "[{text_time}] {phase}: starting"
    ))
  }
  res <-
    base::force(expr)
  if (
    !base::is.null(file_checkpoint)
  ) {
    fs::dir_create(path = path_checkpoint)
    file_temporary <-
      base::tempfile(pattern = ".writing_", tmpdir = path_checkpoint)
    base::on.exit(
      if (
        fs::file_exists(file_temporary)
      ) {
        fs::file_delete(path = file_temporary)
      },
      add = TRUE
    )
    base::saveRDS(
      object = base::list(
        signature = signature,
        phase = phase,
        result = res
      ),
      file = file_temporary,
      compress = FALSE
    )
    fs::file_move(path = file_temporary, new_path = file_checkpoint)
  }
  if (
    base::isTRUE(verbose)
  ) {
    text_time <-
      base::format(base::Sys.time(), tz = "UTC", usetz = TRUE)
    cli::cli_inform(stringr::str_glue(
      "[{text_time}] {phase}: completed"
    ))
  }
  return(res)
}
