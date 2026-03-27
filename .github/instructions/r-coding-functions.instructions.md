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

**All function creation and editing follows Test-Driven Development (TDD).**
The mandatory cycle is:
1. Write (or update) the roxygen2 spec stub first
2. Write unit tests against the spec — before any implementation exists
3. Verify every test fails against the stub
4. Implement the function until all tests pass
5. Run the full test suite (`Rscript R/03_Supplementary_analyses/Run_tests.R`)
6. Run the `project_cz` pipeline end-to-end

See the TDD workflow in the project's `copilot-instructions.md` for the
full step-by-step procedure.

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

Use two different tools depending on what is being checked:

### Argument validation — `assertthat::assert_that()`

Use `assertthat::assert_that()` (from the
[assertthat](https://github.com/hadley/assertthat) package) to validate
function **arguments** (types, required columns, lengths, etc.). These
checks guard against incorrect inputs supplied by the caller:

```r
# Good — argument type and structure checks
assertthat::assert_that(
  base::is.numeric(x),
  msg = "'x' must be numeric."
)

assertthat::assert_that(
  base::all(c("col_a", "col_b") %in% base::names(df)),
  msg = paste0(
    "'df' must contain columns 'col_a' and 'col_b'."
  )
)

# Avoid - plain stop() gives no structured context
if (!is.numeric(x)) stop("x must be numeric")
```

### Internal / data-content checks — `cli::cli_abort()`

Use `cli::cli_abort()` (from the [cli](https://cli.r-lib.org/) package)
for checks that arise **inside** the function body — i.e. conditions that
depend on the *content* of data rather than the type/shape of arguments,
or on intermediate results that should be meaningful but may not be:

```r
# Good — data-content / internal logic check
if (base::sum(mat_binary) == 0L) {
  cli::cli_abort(
    c(
      "The binarized matrix contains no positive entries.",
      "i" = "Cannot compute network metrics on an empty matrix."
    )
  )
}
```

Use `cli::cli_warn()` and `cli::cli_inform()` for warnings and messages
respectively.

## Function Documentation

Each function should have documentation at the beginning of the function using
the [roxygen2](https://roxygen2.r-lib.org/) package. This can be useful also
for project-specific functions (not just within the package) as it is easier
to transition to a custom package.

The roxygen2 documentation should be placed before the function declaration
but keep the 80-character line limit for all R code and `#'` roxygen2 comment
lines. See
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
