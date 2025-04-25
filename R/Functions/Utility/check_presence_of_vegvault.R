#' @title Check Presence of VegVault File
#' @description
#' Checks whether the `VegVault.sqlite` file exists in the specified directory.
#' @param relative_path
#' Relative path to the `VegVault.sqlite` file (default: "Data/Input/Vegvault.sqlite").
#' @return
#' Logical value indicating whether the file exists. Stops with an error if
#' the file is not found.
#' @details
#' Verifies the presence of the `VegVault.sqlite` file. If not found, throws
#' an error with instructions to consult the `Data/Input/README.md` file.
#' @export
check_presence_of_vegvault <- function(relative_path = "Data/Input/Vegvault.sqlite") {
  vegvault_present <-
    file.exists(
      here::here(relative_path)
    )

  if (
    isFALSE(vegvault_present)
  ) {
    stop(
      paste(
        "The VegVault.sqlite file is not present in",
        "the `Data/Input/` directory.",
        "Please read the `Data/Input/README.md` file for more information."
      )
    )

    return(vegvault_present)
  }

  return(vegvault_present)
}
