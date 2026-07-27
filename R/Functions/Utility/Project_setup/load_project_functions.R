#' @title Load Project Functions
#' @description
#' Validates and deterministically loads the active project function tree.
#' @param path_function_root
#' A single existing directory containing project function files.
#' @param environment_target
#' The environment into which validated functions are loaded.
#' @param vec_excluded_directory_names
#' Character vector of exact directory names to exclude with all descendants.
#' @return
#' A data frame describing the validated functions in source order.
#' @details
#' Validation occurs before any function is loaded. Each active file must
#' contain exactly one top-level function declaration and no other top-level
#' expressions. Function names must match file basenames; a single leading dot
#' is allowed for an internal function. Duplicate symbols and case-insensitive
#' duplicate basenames are rejected.
#' @examples
#' \dontrun{
#' load_project_functions(
#'   path_function_root = here::here("R/Functions"),
#'   environment_target = base::globalenv()
#' )
#' }
#' @export
load_project_functions <- function(
    path_function_root,
    environment_target,
    vec_excluded_directory_names = base::character()) {
  assertthat::assert_that(
    base::is.character(path_function_root) &&
      base::length(path_function_root) == 1L &&
      !base::is.na(path_function_root) &&
      base::nzchar(path_function_root) &&
      base::dir.exists(path_function_root),
    msg = "`path_function_root` must be one existing directory."
  )
  assertthat::assert_that(
    base::is.environment(environment_target),
    msg = "`environment_target` must be an environment."
  )
  assertthat::assert_that(
    base::is.character(vec_excluded_directory_names) &&
      !base::anyNA(vec_excluded_directory_names),
    msg = "`vec_excluded_directory_names` must be a character vector."
  )
  assertthat::assert_that(
    base::all(base::nzchar(vec_excluded_directory_names)),
    msg = "`vec_excluded_directory_names` cannot contain empty names."
  )
  assertthat::assert_that(
    !base::anyDuplicated(vec_excluded_directory_names),
    msg = "`vec_excluded_directory_names` must contain unique names."
  )
  assertthat::assert_that(
    !base::any(
      vec_excluded_directory_names %in% base::c(".", "..") |
        base::grepl(
          pattern = "[/\\\\]",
          x = vec_excluded_directory_names
        )
    ),
    msg = paste0(
      "`vec_excluded_directory_names` entries must be single ",
      "directory names."
    )
  )

  path_function_root_normalized <-
    base::normalizePath(
      path = path_function_root,
      winslash = "/",
      mustWork = TRUE
    )

  vec_function_paths_all <-
    base::list.files(
      path = path_function_root_normalized,
      pattern = "[.]R$",
      recursive = TRUE,
      full.names = TRUE
    )

  vec_function_paths_all_normalized <-
    base::normalizePath(
      path = vec_function_paths_all,
      winslash = "/",
      mustWork = TRUE
    )

  vec_relative_paths_all <-
    base::substring(
      text = vec_function_paths_all_normalized,
      first = base::nchar(path_function_root_normalized) + 2L
    )

  list_directory_components <-
    base::lapply(
      X = base::dirname(vec_relative_paths_all),
      FUN = function(path_directory) {
        if (
          base::identical(path_directory, ".")
        ) {
          return(base::character())
        }

        return(
          base::strsplit(
            x = path_directory,
            split = "/",
            fixed = TRUE
          )[[1L]]
        )
      }
    )

  vec_directory_names_present <-
    list_directory_components |>
    base::unlist(
      use.names = FALSE
    ) |>
    base::unique()

  vec_missing_excluded_directory_names <-
    base::setdiff(
      x = vec_excluded_directory_names,
      y = vec_directory_names_present
    )

  if (
    base::length(vec_missing_excluded_directory_names) > 0L
  ) {
    cli::cli_abort(
      message = base::c(
        "An excluded function directory is not present.",
        "x" = stringr::str_c(
          vec_missing_excluded_directory_names,
          collapse = ", "
        )
      ),
      class = "biodynamics_error_function_exclusion_directory_missing"
    )
  }

  vec_path_is_excluded <-
    base::vapply(
      X = list_directory_components,
      FUN = function(vec_directory_components) {
        base::any(
          vec_directory_components %in%
            vec_excluded_directory_names
        )
      },
      FUN.VALUE = base::logical(1L)
    )

  vec_relative_paths_active <-
    vec_relative_paths_all[!vec_path_is_excluded]

  vec_path_order <-
    base::order(
      base::tolower(vec_relative_paths_active),
      vec_relative_paths_active,
      method = "radix"
    )

  vec_relative_paths_active <-
    vec_relative_paths_active[vec_path_order]

  vec_active_indices <-
    base::match(
      x = vec_relative_paths_active,
      table = vec_relative_paths_all
    )

  vec_function_paths_active <-
    vec_function_paths_all_normalized[vec_active_indices]

  vec_file_basenames <-
    vec_relative_paths_active |>
    base::basename() |>
    tools::file_path_sans_ext()

  vec_file_basenames_lower <-
    base::tolower(vec_file_basenames)

  vec_duplicate_basenames <-
    vec_file_basenames[
      base::duplicated(vec_file_basenames_lower) |
        base::duplicated(
          vec_file_basenames_lower,
          fromLast = TRUE
        )
    ] |>
    base::unique()

  if (
    base::length(vec_duplicate_basenames) > 0L
  ) {
    cli::cli_abort(
      message = base::c(
        "Duplicate function-file basename detected.",
        "x" = stringr::str_c(
          vec_duplicate_basenames,
          collapse = ", "
        )
      ),
      class = "biodynamics_error_function_basename_duplicate"
    )
  }

  n_function_files <-
    base::length(vec_function_paths_active)

  vec_function_names <-
    base::character(n_function_files)

  for (
    index_file in base::seq_along(vec_function_paths_active)
  ) {
    path_function <-
      vec_function_paths_active[[index_file]]

    expressions <-
      base::tryCatch(
        expr = base::parse(
          file = path_function,
          keep.source = FALSE
        ),
        error = function(condition) {
          cli::cli_abort(
            message = stringr::str_glue(
              "Cannot parse function file ",
              "`{vec_relative_paths_active[[index_file]]}`."
            ),
            class = "biodynamics_error_function_parse",
            parent = condition
          )
        }
      )

    vec_declared_names <-
      base::character()

    n_other_expressions <- 0L

    for (
      index_expression in base::seq_along(expressions)
    ) {
      expression <-
        expressions[[index_expression]]

      flag_assignment <-
        base::is.call(expression) &&
        (
          base::identical(expression[[1L]], base::as.name("<-")) ||
            base::identical(expression[[1L]], base::as.name("="))
        )

      flag_named_assignment <-
        flag_assignment &&
        base::is.symbol(expression[[2L]])

      flag_function_declaration <-
        flag_named_assignment &&
        base::is.call(expression[[3L]]) &&
        base::identical(
          expression[[3L]][[1L]],
          base::as.name("function")
        )

      if (
        base::isTRUE(flag_function_declaration)
      ) {
        vec_declared_names <-
          base::c(
            vec_declared_names,
            base::as.character(expression[[2L]])
          )
      } else {
        n_other_expressions <- n_other_expressions + 1L
      }
    }

    if (
      base::length(vec_declared_names) != 1L
    ) {
      cli::cli_abort(
        message = stringr::str_glue(
          "Function file ",
          "`{vec_relative_paths_active[[index_file]]}` must contain ",
          "exactly one top-level function declaration; found ",
          "{base::length(vec_declared_names)}."
        ),
        class = "biodynamics_error_function_declaration_count"
      )
    }

    if (
      n_other_expressions > 0L
    ) {
      cli::cli_abort(
        message = stringr::str_glue(
          "Function file ",
          "`{vec_relative_paths_active[[index_file]]}` contains an ",
          "unapproved top-level expression."
        ),
        class = "biodynamics_error_function_top_level_expression"
      )
    }

    vec_function_names[[index_file]] <-
      vec_declared_names[[1L]]
  }

  vec_duplicate_function_names <-
    vec_function_names[
      base::duplicated(vec_function_names) |
        base::duplicated(
          vec_function_names,
          fromLast = TRUE
        )
    ] |>
    base::unique()

  if (
    base::length(vec_duplicate_function_names) > 0L
  ) {
    cli::cli_abort(
      message = base::c(
        "Duplicate function symbol detected.",
        "x" = stringr::str_c(
          vec_duplicate_function_names,
          collapse = ", "
        )
      ),
      class = "biodynamics_error_function_symbol_duplicate"
    )
  }

  vec_expected_internal_names <-
    stringr::str_c(".", vec_file_basenames)

  vec_name_matches <-
    vec_function_names == vec_file_basenames |
    vec_function_names == vec_expected_internal_names

  if (
    base::any(!vec_name_matches)
  ) {
    index_mismatch <-
      base::which(!vec_name_matches)[[1L]]

    cli::cli_abort(
      message = stringr::str_glue(
        "Function `{vec_function_names[[index_mismatch]]}` must match ",
        "its file basename `{vec_file_basenames[[index_mismatch]]}`."
      ),
      class = "biodynamics_error_function_basename_mismatch"
    )
  }

  for (
    path_function in vec_function_paths_active
  ) {
    base::sys.source(
      file = path_function,
      envir = environment_target,
      keep.source = TRUE
    )
  }

  res_inventory <-
    base::data.frame(
      path_relative = vec_relative_paths_active,
      path_absolute = vec_function_paths_active,
      function_name = vec_function_names,
      is_internal = base::startsWith(
        x = vec_function_names,
        prefix = "."
      ),
      source_order = base::seq_along(vec_function_paths_active),
      stringsAsFactors = FALSE
    )

  return(res_inventory)
}
