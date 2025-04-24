#' @title Extract Data from VegVault
#' @description
#' Extracts data from the VegVault SQLite database based on specified
#' geographic, temporal, and dataset type constraints.
#' @param path_to_vegvault
#' A character string specifying the path to the VegVault SQLite database
#' (default: "Data/Input/VegVault.sqlite").
#' @param x_lim
#' A numeric vector of length 2 specifying the longitude range.
#' @param y_lim
#' A numeric vector of length 2 specifying the latitude range.
#' @param age_lim
#' A numeric vector of length 2 specifying the age range.
#' @param sel_dataset_type
#' A character vector specifying the dataset types to select.
#' @param sel_abiotic_var_name
#' A character vector specifying the abiotic variable names to select.
#' @return
#' A data frame containing the extracted data.
#' @details
#' The function performs the following steps:
#'   
#'   1. Validates input parameters.
#'   2. Checks the presence of the VegVault SQLite database.
#'   3. Accesses the database and filters data based on geographic, temporal,
#'      and dataset type constraints.
#'   4. Retrieves abiotic data and taxa information.
#'   5. Returns the extracted data as a data frame.
#' @export
extract_data_from_vegvault <- function(
    path_to_vegvault = here::here("Data/Input/VegVault.sqlite"),
    x_lim = NULL,
    y_lim = NULL,
    age_lim = NULL,
    sel_dataset_type = NULL,
    sel_abiotic_var_name = NULL) {
  `%>%` <- magrittr::`%>%`

  assertthat::assert_that(
    is.character(path_to_vegvault),
    length(path_to_vegvault) == 1,
    msg = "path_to_vegvault must be a single character string"
  )

  # Check if the VegVault file exists
  check_presence_of_vegvault(path_to_vegvault)

  assertthat::assert_that(
    is.numeric(x_lim) && length(x_lim) == 2,
    msg = "x_lim must be a numeric vector of length 2"
  )

  assertthat::assert_that(
    is.numeric(y_lim) && length(y_lim) == 2,
    msg = "y_lim must be a numeric vector of length 2"
  )

  assertthat::assert_that(
    is.numeric(age_lim) && length(age_lim) == 2,
    msg = "age_lim must be a numeric vector of length 2"
  )

  assertthat::assert_that(
    is.character(sel_dataset_type) && length(sel_dataset_type) > 0,
    msg = "sel_dataset_type must be a character vector of length > 0"
  )

  assertthat::assert_that(
    is.character(sel_abiotic_var_name) && length(sel_abiotic_var_name) > 0,
    msg = "sel_abiotic_var_name must be a character vector of length > 0"
  )

  vaultkeepr_plan <-
    # Access the VegVault file
    vaultkeepr::open_vault(
      path = path_to_vegvault
    ) %>%
    # Add the dataset information
    vaultkeepr::get_datasets() %>%
    # Select modern plot data and climate
    vaultkeepr::select_dataset_by_type(
      sel_dataset_type = sel_dataset_type
    ) %>%
    # Limit data to Czech Republic
    vaultkeepr::select_dataset_by_geo(
      lat_lim = y_lim,
      long_lim = x_lim,
      verbose = FALSE
    ) %>%
    # Add samples
    vaultkeepr::get_samples() %>%
    # select only modern data
    vaultkeepr::select_samples_by_age(
      age_lim = age_lim,
      verbose = FALSE
    ) %>%
    # Add abiotic data
    vaultkeepr::get_abiotic_data(verbose = FALSE) %>%
    # Select only Mean Anual Temperature (bio1)
    vaultkeepr::select_abiotic_var_by_name(
      sel_var_name = sel_abiotic_var_name) %>%
    # add taxa
    vaultkeepr::get_taxa()

  data_extracted <-
    vaultkeepr_plan %>%
    vaultkeepr::extract_data(
      return_raw_data = FALSE,
      verbose = FALSE
    )

  return(data_extracted)
}
