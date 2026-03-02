---
applyTo: "**/*.R"
description: >
  Standard debugging workflow for this project: isolate issues in
  temporary R scripts, test in a clean terminal session, and verify
  the fix by running the full pipeline before closing the task.
---

# Debugging Workflow

## Guiding Principle

**Never guess at a fix.** Before touching any project file, reproduce and
fully understand the root cause in an isolated environment. Only then apply
the minimal necessary change to the source.

---

## Step-by-Step Workflow

### 1. Reproduce the Error in a Temp Script

Create a self-contained R script in `Data/Temp/` that:

- Imports **only** the packages needed to demonstrate the bug
- Does **not** `source()` the project setup — keep it minimal
- Contains a clear minimal reproducible example (MRE)
- Prints enough diagnostic output to see exactly what is happening

**Naming**: use a descriptive, throwaway name, e.g. `debug_<topic>.R`.
These files are git-ignored and must never carry important information.

```r
# Data/Temp/debug_<topic>.R
# Minimal reproduction of the issue with <function/package>

library(<pkg>)

# ... MRE code ...
cat("result:", class(result), "\n")
```

### 2. Run the Script in a Clean Terminal Session

Execute the script non-interactively to avoid any state leaked from a
running R session:

```powershell
Rscript "D:/path/to/project/Data/Temp/debug_<topic>.R" `
  > "D:/path/to/project/Data/Temp/debug_out.txt" 2>&1
Get-Content "D:/path/to/project/Data/Temp/debug_out.txt"
```

Key rules:

- Always redirect to a file and then `Get-Content` — this avoids
  PowerShell terminal encoding artefacts swallowing output
- Do **not** rely on an interactive R session; hidden state causes
  false positives
- If the first script does not fully expose the root cause, iterate:
  create `debug_<topic>2.R`, `debug_<topic>3.R`, etc.

### 3. Probe the Environment Chain / Internal Behaviour

For bugs involving R's scoping or NSE (non-standard evaluation):

- Print `environmentName(environment())` and
  `environmentName(parent.env(environment()))` from within the suspect
  function to map the environment chain
- Inspect internals with `getAnywhere('<fn>')` or
  `body(<package>::<fn>)`
- Test alternative call patterns side-by-side in the same script
  (bare name, inline literal, `do.call`, `identity()` wrapper, etc.)
  so the contrast between broken and working is explicit in the output

### 4. Apply the Fix to the Source File

Once the root cause is confirmed:

- Apply the **minimal** targeted change to the project source file
- Add a concise comment explaining *why* the fix is necessary
  (future readers will not have the debugging session in context)

Example of a good explanatory comment:

```r
# Note: sjSDM::linear uses match.call() and re-evaluates bare formula
#   symbols in parent.env(environment()) = namespace:sjSDM.
#   Using do.call passes the formula as an already-evaluated object
#   so the bare-name eval branch is never triggered.
spatial <-
  do.call(
    sjSDM::linear,
    list(
      data = scale(data_spatial),
      formula = sel_spatial_formula
    )
  )
```

### 5. Clean Up Temp Files

Remove all debug scripts and output files immediately after the fix
is confirmed:

```powershell
Remove-Item "D:/path/to/project/Data/Temp/debug_<topic>*.R",
            "D:/path/to/project/Data/Temp/debug_out*.txt" `
  -ErrorAction SilentlyContinue
```

### 6. Run the Targeted Test File

Run only the test file for the function that was changed. This gives
fast feedback before committing time to the full suite:

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

Fix any failures before moving on.

### 7. Run the Full Test Suite

Once the targeted tests pass, run the entire suite to confirm no
regressions were introduced elsewhere:

```r
library(here)

source(
  here::here("R/___setup_project___.R")
)

testthat::test_dir(
  here::here("R/03_Supplementary_analyses/testthat")
)
```

All tests must pass before proceeding. If a previously passing test
now fails, treat it as a new bug introduced by the fix and return to
step 1.

### 8. Final Verification — Run the Full Pipeline

**This step is mandatory for all implementation work** — bug fixes,
new features, refactors, and pipeline changes — not only for debugging
sessions. After cleaning up, verify end-to-end by running the basic
pipeline with the `project_cz` configuration. The run must complete
without unexpected errors:

```r
library(here)

source(
  here::here("R/___setup_project___.R")
)

# Set specific config active
Sys.setenv(R_CONFIG_ACTIVE = "project_cz")

# Basic pipeline
run_pipeline(
  sel_script = "R/02_Main_analyses/pipeline_basic.R",
  level_separation = 100
)
```

**Do not consider a bug fix complete until this step passes without
errors.**

Note: steps 6, 7, and 8 must all pass — the targeted test catches
regressions in the changed function, the full suite catches wider
regressions, and the pipeline run confirms end-to-end correctness.

---

## Quick Reference

| Step | Action |
|------|--------|
| 1 | Create `Data/Temp/debug_<topic>.R` — minimal MRE |
| 2 | Run with `Rscript` → file redirect → `Get-Content` |
| 3 | Probe environments / call patterns until root cause is clear |
| 4 | Apply minimal fix + explanatory comment to source |
| 5 | `Remove-Item` all temp debug files |
| 6 | Run `testthat::test_file()` for the changed function — passes |
| 7 | Run `testthat::test_dir()` — all tests pass |
| 8 | Run full `pipeline_basic.R` under `project_cz` — no errors |

---

## Common Pitfalls

- **Do not assign to `parent.env()`** of your function as a workaround
  for NSE issues. `parent.env()` is the *enclosing* (lexical) env of
  the function, which for package functions is that package's namespace
  — completely unrelated to your calling code. Use `do.call` instead to
  pass already-evaluated objects.

- **Do not trust an interactive R session** to reproduce
  environment-related bugs: leftover global variables create false
  positives. Always use a fresh `Rscript` call.

- **Do not batch-test multiple hypotheses** in one script run. One
  hypothesis per script iteration keeps the output readable and the
  diagnosis unambiguous.
