---
applyTo: '**/R/Functions/', '**/R/03_Supplementary_analyses/testthat' 
---

# Instructions for Writing Complete Test Files for R Functions

## Your Role

You are an expert R developer and testthat user tasked with writing comprehensive test suites.

**IMPORTANT:** All code must follow the project's R coding conventions defined in `.github/instructions/r-coding.instructions.md`. This includes:

- Object naming conventions (snake_case with type prefixes: `data_*`, `vec_*`,
  `list_*`, `mod_*`)
- Syntax rules (spaces, new lines, assignment with `<-`)
- Function namespace usage (`package::function()`)
- Line width limit (80 characters)
- Use of `TRUE`/`FALSE` instead of `T`/`F`

### Most-commonly violated rules in test files

These rules are frequently missed — treat them as a checklist before finishing
any test file:

**1. 80-character line limit applies everywhere**, including `test_that()`
description strings. If a description would exceed 80 characters, shorten it
(do **not** break the string with `paste0()` unless truly unavoidable).
Count the leading spaces + quotes + text + `",` — all of it counts.

**2. Never use `$` to access data frame columns.** The project standards
explicitly ban `df$column`. Use `dplyr::pull(df, column)` instead:

```r
# Wrong
res$abiotic_variable_name

# Correct
dplyr::pull(res, abiotic_variable_name)
```

**3. Newline after `<-` when the RHS is a function call.** Every assignment
where the right-hand side is a function call must be split across two lines
(newline + 2-space indent after `<-`):

```r
# Wrong — function call on the same line as <-
data_coords <- tibble::tibble(x = 1, y = 2)
res <- my_function(arg = value)
out <- purrr::pluck(list_obj, "key")
mat <- base::matrix(c(0, 1), nrow = 1)
list_params <- base::list(a = 1, b = 2)

# Correct — newline + 2-space indent after <-
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

The **only** assignments that may stay on one line are scalar literals and
`NULL`:

```r
vec_center <- 50.0   # OK: numeric literal
name <- "triangle"   # OK: string literal
flag <- NULL         # OK: NULL
count <- 3L          # OK: integer literal
```

This rule applies to **every variable** inside `test_that()` blocks —
`data_*`, `res`, `vec_*`, `list_*`, `mat_*`, and any intermediate result.
Treat this as a hard requirement: scan every `<-` in your output before
submitting.

**4. Always use fully-qualified namespaces**, even for base R and testthat
functions. This is required by the project standard ("Always use the full
package namespace with a function call").

All `testthat` assertion and block functions must be prefixed with
`testthat::`:

| Bare call | Namespaced form |
|-----------|-----------------|
| `test_that(…)` | `testthat::test_that(…)` |
| `expect_error(…)` | `testthat::expect_error(…)` |
| `expect_equal(…)` | `testthat::expect_equal(…)` |
| `expect_true(…)` | `testthat::expect_true(…)` |
| `expect_false(…)` | `testthat::expect_false(…)` |
| `expect_named(…)` | `testthat::expect_named(…)` |
| `expect_length(…)` | `testthat::expect_length(…)` |
| `expect_warning(…)` | `testthat::expect_warning(…)` |
| `expect_message(…)` | `testthat::expect_message(…)` |
| `expect_s3_class(…)` | `testthat::expect_s3_class(…)` |
| `expect_type(…)` | `testthat::expect_type(…)` |

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
| `sd(x)` | `stats::sd(x)` — **NOT** `base::sd()` (sd lives in `stats`) |
| `rep(x, n)` | `base::rep(x, n)` |

## Objective

Write a COMPLETE testthat test file for a single R function. You will receive only the function definition (name, arguments, roxygen documentation, and body). From this, you must infer the intended behavior and create thorough tests.

## Test File Organization

**Workflow:**

1. **Identify all functions** in `R/Functions/` (recursively search all subdirectories for function declarations)
2. **Check for existing tests** in `R/03_Supplementary_analyses/testthat` directory
3. **Create missing test files** named as `test-function_name.R` (e.g., `get_data()` → `test-get_data.R`)

**File structure:**

- **No script header** — test files must NOT start with the project-level script header block (the `#--...#` banner). Start the file directly with the first `test_that()` block or a section header.
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

**Behavioral invariants:**
If the name suggests properties, test them directly:

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

- Include at least one test with moderately large input (1000–10000 rows)
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
- Maximum 80 characters per line
- Space after commas, before/after infix operators
- Use full namespace: `package::function()` for all function calls
- Vertical code style with new lines after assignment and pipes

**Dependencies:**

- Use only base R and testthat (plus packages the function clearly depends on)
- Load required packages with `library()` at the top

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

## After Editing a Test File

**MANDATORY:** After creating or modifying any test file in
`R/03_Supplementary_analyses/testthat/`, immediately run that test file to
verify all tests pass. Functions are not auto-loaded by testthat — you must
source the project setup first so all project functions are available:

```r
library(here)

source(
  here::here("R/___setup_project___.R")
)

testthat::test_file(
  here::here(
    "R/03_Supplementary_analyses/testthat/test-<function_name>.R"
  )
)
```

To run the **full test suite**, use the canonical script that handles setup
automatically:

```powershell
Rscript R/03_Supplementary_analyses/Run_tests.R
```

Do not consider the task complete until the test run produces **no failures and
no errors**. Warnings are acceptable only if they are expected and intentional.
If any test fails after an edit, fix the test (or the function) before
finishing.

---

## Final Instruction

Based on the function definition provided, write the COMPLETE testthat test file following all guidelines above.
