---
applyTo: "**/R/Functions/"
description: This file contains instructions for using the `roxygen2` package in R to generate documentation from comments in the code.
---

# Instructions for documenting functions with {roxygen2}

## The goal

The goal is to make make sure all functions in the project are documented using the `roxygen2` package. Each function is stored in a separate script. All such scripts are stored within [R/Functions/](../R/Functions/) folder. There are several subfolders, but the documentation should be created for all functions recursively.

## The process

1. Make a list of all functions in the project - check the [R/Functions/](../R/Functions/) folder **recursively** for all R scripts that contain function declarations.
2. Check if each function has documentation
3. If a function does not have documentation, create it following the template below

### Specifications of the documentation

Each function should have documentation at the beginning of the function using the [roxygen2](https://roxygen2.r-lib.org/) package. This can be useful also for project-specific functions (not just within the package) as it is easier to transition to a custom package.

The roxygen2 documentation should be placed before the function declaration but keep the line limit of 80 characters. The documentation should be in the following:

```r
#' @title Title of the function
#' @description 
#' Description of the function
#' @param arg1 
#' Description of the first argument
#' @param arg2 
#' Description of the second argument
#' @param arg3 
#' Description of the third argument
#' @return 
#' Description of the return value
#' @details 
#' Details about the function
#' @seealso Related functions or references
#' @export
```
