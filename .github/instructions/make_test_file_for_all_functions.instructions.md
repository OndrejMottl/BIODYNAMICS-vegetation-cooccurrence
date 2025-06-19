---
applyTo: '**/R/Functions/', '**/R/03_Supplementary_analyses/testthat' 
---

# Instructions for making empty test files for all functions

## The goal

The goal of this task is to create placeholder test files for all functions in the specified directories. This will help ensure that all functions are covered by tests and facilitate the development of a comprehensive test suite.

## The process

1. **Identify all functions**: Check the specified directories for all R scripts that contain function declarations. This includes the `R/Functions/` directory and any subdirectories.
2. **Identify which functions are missing tests**: For each function found, check if there is an existing test file in the `R/03_Supplementary_analyses/testthat` directory. If a test file does not exist for a function, it should be created.
3. **Create empty test files**: For each function without a test file, create an placeholder test file in the `R/03_Supplementary_analyses/testthat` directory.
4. **Ensure the test files are created**: Each test file should be created  as a placeholder for future tests, following the template below.

### Specifications for the test files

Each test file should be named according to the function it tests, using the following format: "test-function_name.R" for example function `get_data()`, defined in `R/Functions/get_data.R` would have a test file named `test-get_data.R`.

Each new created test file should contain the following template (this is example for `get_data()` function):
```r
testthat::test_that("get_data() returns correct class", {
 })

testthat::test_that("get_data() returns correct data", {
 })

 testthat::test_that("get_data() handles invalid input", {

 })
```
