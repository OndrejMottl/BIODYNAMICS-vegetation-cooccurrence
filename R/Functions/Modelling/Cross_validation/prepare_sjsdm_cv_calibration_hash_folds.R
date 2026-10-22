#' @title Prepare Scientific Fold Content for Calibration Hashing
#' @description
#' Excludes operational runtime and memory measurements from signatures.
#' Fold assignments, observations, predictors and spatial strategy provenance
#' remain unchanged. This does not alter the folds used for fitting.
#' @param list_prepared_folds
#' Cached records returned by [prepare_sjsdm_tuning_folds()].
#' @param contract_version
#' Signature version. Version four retains memory fields for exact migration
#' proof; the default version five excludes operational memory fields too.
#' @return A copy of the fold records without operational runtime fields.
#' @examples
#' prepare_sjsdm_cv_calibration_hash_folds(list())
#' @export
prepare_sjsdm_cv_calibration_hash_folds <- function(
    list_prepared_folds,
    contract_version = base::c("v5", "v4")) {
  contract_version <-
    base::match.arg(contract_version)
  assertthat::assert_that(
    base::is.list(list_prepared_folds),
    msg = "Prepared calibration folds must be a list."
  )

  res <-
    purrr::map(
      .x = list_prepared_folds,
      .f = ~ {
        list_record <-
          .x
        if (
          !base::is.list(list_record)
        ) {
          return(list_record)
        }
        list_record[["preparation_seconds"]] <-
          NULL
        list_fold <-
          list_record[["list_prepared_fold"]]
        if (
          base::is.list(list_fold) &&
            base::is.data.frame(list_fold[["data_spatial_provenance"]])
        ) {
          list_fold[["data_spatial_provenance"]][["elapsed_seconds"]] <-
            NULL
          if (
            contract_version == "v5"
          ) {
            list_fold[["data_spatial_provenance"]][["basis_bytes"]] <-
              NULL
            list_fold[["data_spatial_provenance"]][[
              "estimated_dense_matrix_bytes"
            ]] <-
              NULL
          }
          list_record[["list_prepared_fold"]] <-
            list_fold
        }
        return(list_record)
      }
    )

  return(res)
}
