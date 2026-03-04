---
applyTo: "**/*.R"
description: >
  Guidelines for writing R functions: argument style, anonymous functions,
  error handling with cli, roxygen2 documentation, and testthat testing.
---

# Function Writing Guidelines

For function calls, always state the arguments even though R can have anonymous
arguments. The only exception is for functions where arguments are not known
(i.e. `...` argument).

## Creating Functions

Specific rules apply for making custom functions:

- For naming of functions see the Naming Conventions section in
  [r-coding.instructions.md](r-coding.instructions.md)
- Each function (declaration) should be placed in a separate script named
  after the function. Therefore, there should be only a single function
  in each function script
- Function should always return (`return(res_value)`)

## Anonymous Functions

In various instances, it might be better to not create a new function but to
use an anonymous function (e.g. inside of `purrr::map_*()`).

Use tilde (`~`) for anonymous functions in purrr:

```r
purrr::map(
  .f = ~ {
    mean(.x)
  }
)
```

For `purrr::pmap_*()`, use `..1`, `..2`, etc:

```r
purrr::pmap(
  .l = list(
    list_1,
    list_2,
    list_3,
    .f = ~ {
      ..1 + ..2 + ..3
    }
  )
)
```

## Error Handling

Use `cli::cli_abort()` (from the [cli](https://cli.r-lib.org/) package) for
error messages in functions. It produces structured, user-friendly output and
supports inline formatting and hints:

```r
# Good
if (!is.numeric(x)) {
  cli::cli_abort(
    c(
      "{.arg x} must be numeric.",
      "i" = "Provided type: {.cls {class(x)}}"
    )
  )
}

# Avoid - plain stop() gives no structured context
if (!is.numeric(x)) stop("x must be numeric")
```

Use `cli::cli_warn()` and `cli::cli_inform()` for warnings and messages
respectively.

## Function Documentation

Each function should have documentation at the beginning of the function using
the [roxygen2](https://roxygen2.r-lib.org/) package. This can be useful also
for project-specific functions (not just within the package) as it is easier
to transition to a custom package.

The roxygen2 documentation should be placed before the function declaration
but keep the line limit of 80 characters. See
[make_roxygen2_documentation.instructions.md](make_roxygen2_documentation.instructions.md)
for the full template and detailed rules.

```R
#' @title Title of the function
#' @description Description of the function
#' @param arg1 Description of the first argument
#' @param arg2 Description of the second argument
#' @param arg3 Description of the third argument
#' @return Description of the return value
#' @details Details about the function
#' @seealso Related functions or references
#' @export
```

## Testing Functions

All tests are done using the [testthat](https://testthat.r-lib.org/) package.
Each function should have its own test file, which is named after the function
(e.g., `test-<function_name>.R`). See
[make_test_file_for_a_function.instructions.md](make_test_file_for_a_function.instructions.md)
for the full conventions.

Generally, the function should be tested for:

- output of correct type
- output of correct data
- handling of input errors

**Reproducibility:**
- When randomness is involved, always use `set.seed(900723)` as the standard
  seed value for this project
