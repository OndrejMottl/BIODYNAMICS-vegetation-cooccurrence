#' @title Build the Difference Between Resolved Configuration Profiles
#' @description
#' Lists the key paths at which resolved configuration profiles differ from
#' the semantic reference.
#' @param list_profiles_current
#' Named list of resolved profiles, as compared by the configuration
#' generator.
#' @param list_profiles_reference
#' Named list of reference profiles with the same profile identifiers.
#' @return
#' A tibble with columns `profile_id` and `key_path` (keys joined with `.`),
#' one row per differing leaf. A key present on one side only is reported at
#' the level where it is missing. Zero rows mean the profiles are identical.
#' @details
#' Nested named lists are compared key by key; any other value (vector,
#' unnamed list, or `NULL`) is a leaf compared with [base::identical()]. A
#' different order of the shared keys is reported as `<path>[order]`
#' (because the generator compares whole profiles with `identical()`), and
#' the children are still compared key by key.
#' @seealso [save_configuration_profile_reference()],
#'   [run_configuration_generation()]
#' @examples
#' build_configuration_reference_diff(
#'   list_profiles_current = list(p = list(a = 1, b = list(c = 2))),
#'   list_profiles_reference = list(p = list(a = 1, b = list(c = 3)))
#' )
#' @export
build_configuration_reference_diff <- function(
    list_profiles_current,
    list_profiles_reference) {
  assertthat::assert_that(
    base::is.list(list_profiles_current),
    base::is.list(list_profiles_reference),
    !base::is.null(base::names(list_profiles_current)),
    base::setequal(
      base::names(list_profiles_current),
      base::names(list_profiles_reference)
    ),
    msg = "Supply two named profile lists with the same profile identifiers."
  )

  vec_profile_ids <-
    base::names(list_profiles_current)

  res <-
    vec_profile_ids |>
    purrr::map(
      .f = ~ {
        profile_id <- .x

        # Iterative walk of both nested lists; differing leaves are recorded.
        list_queue <-
          base::list(
            base::list(
              path = base::character(),
              value_current = list_profiles_current[[profile_id]],
              value_reference = list_profiles_reference[[profile_id]]
            )
          )
        vec_paths_changed <- base::character()

        while (
          base::length(list_queue) > 0L
        ) {
          list_item <- list_queue[[1L]]
          list_queue <- list_queue[-1L]

          value_current <- list_item[["value_current"]]
          value_reference <- list_item[["value_reference"]]

          flag_both_named_lists <-
            base::is.list(value_current) &&
            base::is.list(value_reference) &&
            !base::is.data.frame(value_current) &&
            !base::is.data.frame(value_reference) &&
            !base::is.null(base::names(value_current)) &&
            !base::is.null(base::names(value_reference))

          if (
            flag_both_named_lists
          ) {
            # The generator compares whole profiles with identical(), so a
            #   change in key order is a difference of its own.
            if (
              !base::identical(
                base::intersect(
                  base::names(value_current),
                  base::names(value_reference)
                ),
                base::intersect(
                  base::names(value_reference),
                  base::names(value_current)
                )
              )
            ) {
              vec_paths_changed <-
                base::c(
                  vec_paths_changed,
                  stringr::str_c(
                    stringr::str_c(list_item[["path"]], collapse = "."),
                    "[order]"
                  )
                )
            }
            vec_keys <-
              base::union(
                base::names(value_current),
                base::names(value_reference)
              )
            list_queue <-
              base::c(
                list_queue,
                vec_keys |>
                  purrr::map(
                    .f = ~ base::list(
                      path = base::c(list_item[["path"]], .x),
                      value_current = value_current[[.x]],
                      value_reference = value_reference[[.x]]
                    )
                  )
              )
          } else if (
            !base::identical(value_current, value_reference)
          ) {
            vec_paths_changed <-
              base::c(
                vec_paths_changed,
                stringr::str_c(list_item[["path"]], collapse = ".")
              )
          }
        }

        tibble::tibble(
          profile_id = base::rep(profile_id, base::length(vec_paths_changed)),
          key_path = vec_paths_changed
        )
      }
    ) |>
    purrr::list_rbind()

  if (
    base::is.null(res)
  ) {
    res <-
      tibble::tibble(
        profile_id = base::character(),
        key_path = base::character()
      )
  }

  return(res)
}
