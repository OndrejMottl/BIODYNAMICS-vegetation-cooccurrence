# R Function, Documentation, and Test Guidance

Canonical guidance for authoring R functions, writing roxygen2 documentation, and creating testthat coverage in this repository.

## Function Authoring Conventions

# Function Writing Guidelines

For function calls, always state the arguments even though R can have anonymous arguments. The only exception is for functions where arguments are not known (i.e. `...` argument).

## Creating Functions

Specific rules apply for making custom functions:

- For naming of functions see the Naming Conventions section in [.ai/r-coding.md](.ai/r-coding.md)
- Each function (declaration) should be placed in a separate script named after the function. Therefore, there should be only a single function in each function script
- Function should always return (`return(res_value)`)

### Reuse Existing Helpers Before Creating New Ones

Before creating a new helper function, search the existing project helpers and nearby analysis code for similar behaviour. Check `R/Functions/` recursively first, then relevant pipeline or analysis scripts if the helper would be local to a workflow.

Prefer clean, DRY code over narrow one-off helpers. If an existing helper already does something very similar, extend or adjust that helper and its tests so it supports the new use case while preserving its existing contract. Create a new helper only when reusing or generalising the existing one would make its purpose misleading, add unsafe branching, or break established behaviour. When a helper is extended, update its roxygen2 documentation and tests, and run the affected tests to confirm the original behaviour still passes.

**All function creation and editing follows Test-Driven Development (TDD).** The mandatory cycle is:
1. Write (or update) the roxygen2 spec stub first
2. Write unit tests against the spec  -  before any implementation exists
3. Verify every test fails against the stub
4. Implement the function until all tests pass
5. Run the full test suite (`Rscript R/03_Supplementary_analyses/Testing/Run_tests.R`)
6. Run `Rscript R/02_Main_analyses/Run_CZ_test.R`

See the TDD workflow in the project's `AGENTS.md` for the full step-by-step procedure.

## Anonymous Functions

In various instances, it might be better to not create a new function but to use an anonymous function (e.g. inside of `purrr::map_*()`).

Use tilde (`~`) for anonymous functions in purrr. **Never use the backslash lambda syntax (`\(x) { ... }`) inside purrr calls** â€” always use `~` with `.x`, `.y`, or `..1`/`..2`/etc:

```r
# Good
purrr::map(
  .f = ~ {
    mean(.x)
  }
)

# NEVER â€” backslash lambda is forbidden inside purrr calls
purrr::map(
  .f = \(x) mean(x)  # wrong
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

### Argument validation  -  `assertthat::assert_that()`

Use `assertthat::assert_that()` (from the [assertthat](https://github.com/hadley/assertthat) package) to validate function **arguments** (types, required columns, lengths, etc.). These checks guard against incorrect inputs supplied by the caller:

```r
# Good  -  argument type and structure checks
assertthat::assert_that(
  base::is.numeric(x),
  msg = "'x' must be numeric."
)

assertthat::assert_that(
  base::all(c("col_a", "col_b") %in% base::names(df)),
  msg = stringr::str_glue(
    "'df' must contain columns 'col_a' and 'col_b'."
  )
)

# Avoid - plain stop() gives no structured context
if (!is.numeric(x)) stop("x must be numeric")
```

### Internal / data-content checks  -  `cli::cli_abort()`

Use `cli::cli_abort()` (from the [cli](https://cli.r-lib.org/) package) for checks that arise **inside** the function body  -  i.e. conditions that depend on the *content* of data rather than the type/shape of arguments, or on intermediate results that should be meaningful but may not be:

```r
# Good  -  data-content / internal logic check
if (base::sum(mat_binary) == 0L) {
  cli::cli_abort(
    c(
      "The binarized matrix contains no positive entries.",
      "i" = "Cannot compute network metrics on an empty matrix."
    )
  )
}
```

Use `cli::cli_warn()` and `cli::cli_inform()` for warnings and messages respectively.

Do not use `cli::cli_abort()` for routine function argument assertions. Those
checks should use `assertthat::assert_that()` so argument contracts stay
separate from runtime data-content failures.

## Verbose Argument for Console Output

Any function that prints to the console (via `cli::cli_inform()` or
`cli::cli_warn()`) **must** accept a `verbose` argument (default `TRUE`) and
guard every print call with it. Only `cli::cli_abort()` (errors) should fire
unconditionally â€” errors are never silenced.

```r
# Good
my_function <- function(x, verbose = TRUE) {
  # ... work ...
  if (
    isTRUE(verbose)
  ) {
    cli::cli_inform(
      c(
        "v" = "Processing complete."
      )
    )
  }
  return(res)
}

# NEVER â€” unconditional informational printing in a function
my_function <- function(x) {
  cli::cli_inform("Processing complete.")  # wrong: no verbose guard
  return(res)
}
```

- Document `verbose` in the roxygen2 block:

```r
#' @param verbose 
#' Logical. If `TRUE` (default), progress messages are printed to
#' the console via `cli`.
```

- When calling a helper that also accepts `verbose`, forward the argument:

```r
result <-
  helper_function(
    data = data_input,
    verbose = verbose
  )
```

## Function Documentation

Each function should have documentation at the beginning of the function using the [roxygen2](https://roxygen2.r-lib.org/) package. This can be useful also for project-specific functions (not just within the package) as it is easier to transition to a custom package.

The roxygen2 documentation should be placed before the function declaration but keep the 80-character line limit for all R code and `#'` roxygen2 comment lines. See [.ai/r-functions.md](.ai/r-functions.md) for the full template and detailed rules.

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

All tests are done using the [testthat](https://testthat.r-lib.org/) package. Each function should have its own test file, which is named after the function (e.g., `test-<function_name>.R`). See [.ai/r-functions.md](.ai/r-functions.md) for the full conventions.

Generally, the function should be tested for:

- output of correct type
- output of correct data
- handling of input errors

**Reproducibility:**
- When randomness is involved, always use `set.seed(900723)` as the standard seed value for this project

## Roxygen2 Documentation Conventions

# Instructions for documenting functions with {roxygen2}

## The goal

The goal is to make sure all functions in the project are documented using the `roxygen2` package. Each function is stored in a separate script. All such scripts are stored within the [R/Functions/](../../R/Functions/) folder. There are several subfolders, but the documentation should be created for all functions recursively.

**IMPORTANT:** All code and documentation must follow the project's R coding conventions defined in `.ai/r-coding.md`, including:
- 80 character line limit for all **R code lines** (including `#'` roxygen2 comment lines inside `.R` files  -  but **not** for markdown prose in `.md` or `.qmd` files)
- Function naming conventions (verbs, snake_case)
- Proper spacing and formatting

## The process

1. Make a list of all functions in the project  -  check the [R/Functions/](../../R/Functions/) folder **recursively** for all R scripts that contain function declarations.
2. Check if each function has documentation
3. If a function does not have documentation, create it following the template below

### Specifications of the documentation

Each function should have documentation at the beginning of the function using the [roxygen2](https://roxygen2.r-lib.org/) package. This can be useful also for project-specific functions (not just within the package) as it is easier to transition to a custom package.

The roxygen2 documentation should be placed before the function declaration but keep the 80-character line limit for all R code and `#'` roxygen2 comment lines. The documentation should be in the following:

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

If the function prints to the console, include a `verbose` parameter and
document it:

```r
#' @param verbose 
#' Logical. If `TRUE` (default), progress messages are printed to
#' the console via `cli`.
```

## Function Test Conventions

# Instructions for Writing Complete Test Files for R Functions

## Your Role

You are an expert R developer and testthat user tasked with writing comprehensive test suites.

**IMPORTANT:** All code must follow the project's R coding conventions defined in `.ai/r-coding.md`. This includes:

- Object naming conventions (snake_case with type prefixes: `data_*`, `vec_*`, `list_*`, `mod_*`)
- Syntax rules (spaces, new lines, assignment with `<-`)
- Function namespace usage (`package::function()`)
- Line width limit (80 characters per line of **R code**)
- Use of `TRUE`/`FALSE` instead of `T`/`F`

### Most-commonly violated rules in test files

These rules are frequently missed  -  treat them as a checklist before finishing any test file:

**1. 80-character line limit applies to all R code**, including `test_that()` description strings. If a description string would exceed 80 characters, shorten it (do **not** break the string with `paste0()` unless truly unavoidable). Count the leading spaces + quotes + text + `",`  -  all of it counts.

> **Note:** This limit applies to R source code only. Markdown prose in `.md` files is NOT subject to the 80-character limit.

**2. Never use `$` to access data frame columns.** The project standards explicitly ban `df$column`. Use `dplyr::pull(df, column)` instead:

```r
# Wrong
res$abiotic_variable_name

# Correct
dplyr::pull(res, abiotic_variable_name)
```

**3. Newline after `<-` when the RHS is a function call.** Every assignment where the right-hand side is a function call must be split across two lines (newline + 2-space indent after `<-`):

```r
# Wrong  -  function call on the same line as <-
data_coords <- tibble::tibble(x = 1, y = 2)
res <- my_function(arg = value)
out <- purrr::pluck(list_obj, "key")
mat <- base::matrix(c(0, 1), nrow = 1)
list_params <- base::list(a = 1, b = 2)

# Correct  -  newline + 2-space indent after <-
data_coords <-
  tibble::tibble(x = 1, y = 2)

res <-
  my_function(arg = value)

out <-
  purrr::pluck(list_obj, "key")

mat <-
  base::matrix(c(0, 1), nrow = 1)

list_params <-
  base::list(a = 1, b = 2)
```

The **only** assignments that may stay on one line are scalar literals and `NULL`:

```r
vec_center <- 50.0   # OK: numeric literal
name <- "triangle"   # OK: string literal
flag <- NULL         # OK: NULL
count <- 3L          # OK: integer literal
```

This rule applies to **every variable** inside `test_that()` blocks  -  `data_*`, `res`, `vec_*`, `list_*`, `mat_*`, and any intermediate result. Treat this as a hard requirement: scan every `<-` in your output before submitting.

**4. Always use fully-qualified namespaces**, even for base R and testthat functions. This is required by the project standard ("Always use the full package namespace with a function call").

All `testthat` assertion and block functions must be prefixed with `testthat::`:

| Bare call | Namespaced form |
|-----------|-----------------|
| `test_that(...)` | `testthat::test_that(...)` |
| `expect_error(...)` | `testthat::expect_error(...)` |
| `expect_equal(...)` | `testthat::expect_equal(...)` |
| `expect_true(...)` | `testthat::expect_true(...)` |
| `expect_false(...)` | `testthat::expect_false(...)` |
| `expect_named(...)` | `testthat::expect_named(...)` |
| `expect_length(...)` | `testthat::expect_length(...)` |
| `expect_warning(...)` | `testthat::expect_warning(...)` |
| `expect_message(...)` | `testthat::expect_message(...)` |
| `expect_s3_class(...)` | `testthat::expect_s3_class(...)` |
| `expect_type(...)` | `testthat::expect_type(...)` |

Common base R calls that must also be namespaced in test files include:

| Bare call | Namespaced form |
|-----------|-----------------|
| `nrow(x)` | `base::nrow(x)` |
| `ncol(x)` | `base::ncol(x)` |
| `colnames(x)` | `base::colnames(x)` |
| `is.data.frame(x)` | `base::is.data.frame(x)` |
| `all(x)` | `base::all(x)` |
| `any(x)` | `base::any(x)` |
| `sort(x)` | `base::sort(x)` |
| `unique(x)` | `base::unique(x)` |
| `length(x)` | `base::length(x)` |
| `seq_along(x)` | `base::seq_along(x)` |
| `seq_len(n)` | `base::seq_len(n)` |
| `paste0(...)` | `base::paste0(...)` |
| `sample(x, n)` | `base::sample(x, n)` |
| `structure(x, ...)` | `base::structure(x, ...)` |
| `class(x) <- y` | `base::class(x) <- y` |
| `character(n)` | `base::character(n)` |
| `sd(x)` | `stats::sd(x)`  -  **NOT** `base::sd()` (sd lives in `stats`) |
| `rep(x, n)` | `base::rep(x, n)` |

## Objective

Write a COMPLETE testthat test file for a single R function. You will receive only the function definition (name, arguments, roxygen documentation, and body). From this, you must infer the intended behavior and create thorough tests.

## Test File Organization

**Workflow:**

1. **Identify all functions** in `R/Functions/` (recursively search all subdirectories for function declarations)
2. **Check for existing tests** in `R/03_Supplementary_analyses/Testing/testthat` directory
3. **Create missing test files** named as `test-function_name.R` (e.g., `get_data()` -> `test-get_data.R`)

**File structure:**

- **No script header**  -  test files must NOT start with the project-level script header block (the `#--...#` banner). Start the file directly with the first `test_that()` block or a section header.
- Assume the function is already available (do NOT redefine or source it)
- Use multiple `test_that()` blocks grouped logically
- Name tests descriptively: `"function_name() validates input types"`, `"function_name() handles NA values"`

## Core Principle: Test Intended Behavior, Not Implementation Bugs

**CRITICAL:** Your tests should capture the *intended* behavior, not reproduce potentially incorrect current behavior.

**Inference hierarchy:**

1. **Primary sources** (highest priority):
   - Function name (assume descriptive and meaningful)
   - Argument names and default values
   - Roxygen comments (`#'`)
   - Inline comments
2. **Secondary source** (for technical details only):
   - Actual code implementation (use only to understand data types, shapes, internal invariants)

**When there's conflict:** If the name/comments suggest one behavior but the implementation appears inconsistent, write tests that enforce the name/comment-based intention.

**Output format:** Return ONLY valid R code for the test file (no explanations, no prose, no standalone comments).

---

## What to Test

### 1. Input Validation

Test each argument systematically:

**Valid inputs (happy path):**

- At least one valid example where all arguments are correct
- For data.frames/lists: verify correct column/element names are accepted
- For constrained arguments: test that valid values (length, range, choices, flags) work without error

**Invalid inputs (error handling):**

- Wrong class/type for each argument
- Wrong or missing names in data.frames/named vectors
- Wrong length (vector when scalar expected, or vice versa)
- Invalid values (negative where non-negative required, unsupported options, out-of-range)
- Use `expect_error()` with regex to match error messages where implementation uses `stop()` or `stopifnot()`

**Special values:**

- Test `NA`, `NaN`, `Inf`, `-Inf`, `NULL`, empty vectors, zero-row data.frames where relevant
- Use `expect_error()` if these should be rejected, or verify defined behavior (e.g., NA propagation)

### 2. Output Structure

Using valid inputs, verify:

**Type and class:**

- Use `expect_s3_class()`, `expect_type()`, `expect_true(is.data.frame(...))`, etc.
- Align expectations with function name (e.g., `*_df()` should return data.frame/tibble)

**Names and dimensions:**

- For vectors/lists: `expect_named()`, `expect_length()`
- For data.frames: check `nrow()`, `ncol()`, `colnames()`
- Ensure all fields suggested by name/comments are present and correctly named

**Multiple output modes:**

- If arguments control output format (e.g., `return`, `summary`, `wide`/`long`, `as_list`), test each mode
- Verify each returns expected type and structure

### 3. Functional Correctness

Test that the function does what its name and comments promise:

**Hand-checkable examples:**

- Build small, simple inputs (tiny vectors/data.frames)
- Compute expected results manually using base R within the test
- Compare with `expect_equal()` (exact) or `expect_equal(..., tolerance = 1e-8)` (floating-point)

**Behavioral invariants:** If the name suggests properties, test them directly:

- **Sorted:** `expect_true(!is.unsorted(result))`
- **Unique:** `expect_equal(length(unique(result)), length(result))`
- **Probabilities:** `expect_true(all(result >= 0 & result <= 1))`, `expect_equal(sum(result), 1, tolerance = 1e-8)`
- **Monotonicity, preserved totals, matching sums**, etc.

**Argument combinations:**

- Test varying method flags (`method = "A"` vs `"B"`)
- Toggle logical switches
- Provide vs omit optional arguments
- Ensure behavior matches intended semantics (e.g., "weighted" vs "unweighted")

**Edge cases:**

- Boundary values: min/max, single-row data, single group, all-equal values
- Realistic edges: duplicates, unbalanced groups, rare factor levels
- Verify sensible behavior guided by function name/comments

**Randomness:**

- If function uses randomness, wrap calls in `set.seed(900723)` for reproducibility
- Always use `set.seed(900723)` as the standard seed value for this project
- Under fixed seed with same inputs, results should be stable

### 4. Side Effects and Messages

**Warnings:**

- Use `expect_warning()` for inputs that should trigger warnings (deprecated arguments, coercions)
- Match part of the warning message if possible

**Messages:**

- Use `expect_message()` if function prints progress/information

**Side effects:**

- If function writes files or modifies state, use `tempdir()` or `withr` patterns
- Ensure side effects occur only when intended

### 5. Performance and Scalability

For functions intended for larger data:

- Include at least one test with moderately large input (1000-10000 rows)
- Verify:
  - Function runs without error
  - Basic structural expectations hold
  - No pathological behavior at scale

### 6. Tidyverse / NSE Compatibility

If function uses non-standard evaluation (NSE) or tidyverse programming (`{{ }}`, `enquo`, `!!`, dplyr, rlang):

- Test usage with bare column names (`col = x`)
- Test behavior when columns are renamed
- Verify clear failure when required columns are missing
- Show correct NSE behavior with both bare names and quoted strings if intended

---

## Style and Formatting Rules

**CRITICAL: Follow R Coding Conventions** (`.github/skills/r.md`):

- Use `snake_case` for all object names with type prefixes where applicable
- Assignment with `<-` (never `=` or `->`)
- Use `TRUE`/`FALSE` (never `T`/`F`)
- Maximum 80 characters per line of R code
- Space after commas, before/after infix operators
- Use full namespace: `package::function()` for all function calls
- Vertical code style with new lines after assignment and pipes

**Dependencies:**

- Use only base R and testthat (plus packages the function clearly depends on)
- Do not call `library()` in test files. Use fully-qualified namespaces and
  rely on `source(here::here("R/___setup_project___.R"))` when project setup is
  needed before running the test.

**Precise expectations:**

- Prefer specific assertions: `expect_equal()`, `expect_error()`, `expect_warning()`, `expect_message()`, `expect_named()`
- Avoid generic `expect_true()` where more specific assertion exists

**Logical grouping:**

- Group expectations within `test_that()` blocks by purpose: inputs, outputs, functionality, edge cases, messages/warnings

**No extra output:**

- Do NOT print anything, use `cat()`, or include explanatory prose
- Do NOT include comments or text outside R code
- Return ONLY the R code for the test file

---

## TDD Context: Tests Are Written Before Implementation

This project follows **Test-Driven Development (TDD)**. Test files are created from the function **spec stub** (roxygen2 documentation + empty body)  -  not from a finished implementation.

**Your tests must describe the intended behaviour, not match existing code.**

### For a new function (most common case)

The function file will contain only:

- The roxygen2 documentation header
- A stub body such as `return(NULL)` or `stop("not implemented")`

When the test file you produce is run against this stub, **every test must fail**. If a test passes against an unimplemented stub, it is not guarding any real behaviour  -  revise it.

### After the implementation is complete

Once the function body is fully written, the same test file is re-run. At that point all tests are expected to pass.

---

## After Editing a Test File

**Step 1  -  Verify tests FAIL against the stub.** After creating or modifying a test file for an unimplemented (or not yet changed) function, run the test file immediately to confirm that every test fails. Functions are not auto-loaded  -  source the project setup first:

```r
library(here)

source(
  here::here("R/___setup_project___.R")
)

testthat::test_file(
  here::here(
    "R/03_Supplementary_analyses/Testing/testthat/test-<function_name>.R"
  )
)
```

A test that passes at this stage is not testing real behaviour  -  revise it.

**Step 2  -  Verify tests PASS after the implementation is complete.** Once the function body has been written and all individual tests pass, run the **full test suite** to verify nothing else broke:

```powershell
Rscript R/03_Supplementary_analyses/Testing/Run_tests.R
```

Do not consider the task complete until the full test suite produces **no failures and no errors**. Warnings are acceptable only if they are expected and intentional. If any test fails after an edit, fix the test (or the function) before finishing.

---

## Final Instruction

Based on the function definition provided, write the COMPLETE testthat test file following all guidelines above.
