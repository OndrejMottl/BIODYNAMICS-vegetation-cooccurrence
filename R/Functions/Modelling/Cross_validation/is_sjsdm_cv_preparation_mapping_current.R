#' @title Test Cached Modern Community Mapping Against Current Inputs
#' @description
#' Reconstructs the known pure modern-resolution mapping in memory and requires
#' exact equality, without rewriting cached preprocessing or fitting models.
#' @param store_path,target_name,command
#' Existing store, mapping endpoint and its current manifest command.
#' @param read_target_function
#' Injectable cached target reader.
#' @param mapping_function
#' Optional test mapping function. Production loads the tracked inline mapper.
#' @return A logical scalar. Unknown commands and reconstruction errors fail.
#' @examples
#' \dontrun{
#' is_sjsdm_cv_preparation_mapping_current(store, target, manifest_command)
#' }
#' @export
is_sjsdm_cv_preparation_mapping_current <- function(
    store_path,
    target_name,
    command,
    read_target_function = targets::tar_read_raw,
    mapping_function = NULL) {
  flag_current <-
    base::tryCatch(
      expr = {
        expression_command <-
          base::parse(text = command)[[1L]]
        base::stopifnot(base::is.call(expression_command),
          base::identical(expression_command[[1L]],
            base::as.name("resolve_modern_community_resolution")))
        environment_mapping <-
          base::new.env(parent = base::parent.frame())
        if (
          base::is.null(mapping_function)
        ) {
          list_expressions <-
            base::parse(file = here::here("R/Pipelines/_pipes/",
              "pipe_segment_community_by_resolution_modern.R"))
          expression_definition <-
            purrr::keep(base::as.list(list_expressions), .p = ~
              base::is.call(.x) &&
                base::identical(.x[[1L]], base::as.name("<-")) &&
                base::identical(.x[[2L]],
                  base::as.name("resolve_modern_community_resolution"))
            )[[1L]]
          base::eval(expression_definition, envir = environment_mapping)
          vec_calls <-
            codetools::findGlobals(environment_mapping[[
              "resolve_modern_community_resolution"]], merge = FALSE)[[
              "functions"]]
          base::stopifnot(base::all(vec_calls %in% base::c(
            "{", "<-", "if", "==", "::", "return",
            "classify_to_functional_type", "classify_taxonomic_resolution"
          )))
        } else {
          environment_mapping[["resolve_modern_community_resolution"]] <-
            mapping_function
        }
        for (
          input_name in base::all.vars(expression_command)
        ) {
          base::assign(input_name,
            read_target_function(name = input_name, store = store_path),
            envir = environment_mapping)
        }
        base::identical(
          base::eval(expression_command, envir = environment_mapping),
          read_target_function(name = target_name, store = store_path)
        )
      },
      error = function(error_condition) FALSE
    )
  return(base::isTRUE(flag_current))
}
