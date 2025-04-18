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
}
