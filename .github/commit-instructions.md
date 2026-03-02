# Commit Message Instructions

## Format

One single line. No body. No period at the end. Max 72 characters.

```
<subject>: <short summary>
```

The subject identifies *what was changed*. The summary states *what was done*.

---

## Subject Rules

### Single function edited

Use the function name with parentheses:

```
add_anova(): correct column name mismatch
filter_rare_taxa(): add minimum occurrence threshold argument
```

### Single pipeline or pipe segment edited

Use the pipeline or segment name with a colon:

```
pipe_segment_community_data: adjust taxa filtering step
pipeline_basic: update seed source to config.yml
```

### Specific analysis or analytical topic

Use a plain descriptive label matching the analysis:

```
Selection of environmental variables: add collinearity check
sjSDM-spatial component: switch to exponential decay kernel
Model evaluation: update WAIC extraction logic
```

### Multiple functions or scripts edited around a common topic

Use the general topic as subject:

```
Taxonomic harmonisation: align resolution levels across functions
Data extraction: update VegVault query structure
```

### Non-code changes

Use a short plain label:

```
renv: update lockfile after package upgrades
config: add project_europe block
docs: update installation instructions
tests: add edge-case coverage for get_anova
refactor: simplify taxa filtering logic across scripts
data: update input data extraction from VegVault
ci: add GitHub Actions workflow for tests
chore: add Data/Temp to .gitignore
vscode: update settings for commit message generation  ← .vscode/ files only (settings.json, tasks.json, launch.json, …)
copilot: update commit instructions and add debugging skill  ← .github/ files only (copilot-instructions.md, commit-instructions.md, instructions/, skills/, …)
```

---

## Banned Words

Do not use: *enhance*, *feat*, *feature*, *fix* (use a specific verb instead,
e.g. *correct*, *remove*, *add*, *update*, *switch*, *adjust*, *replace*).

---

## Examples

```
add_anova(): correct wrong grouping variable reference
filter_rare_taxa(): add minimum occurrence threshold argument
pipe_segment_community_data: adjust taxa filtering step
Selection of environmental variables: add collinearity check
sjSDM-spatial component: switch to exponential decay kernel
Model evaluation: update WAIC extraction logic
Taxonomic harmonisation: align resolution levels across functions
config: add project_europe block to config.yml
renv: update lockfile after package upgrades
chore: add Data/Temp to .gitignore
vscode: add commit-instructions.md and wire up profile setting
copilot: add debugging instructions and update r-coding skill
```
