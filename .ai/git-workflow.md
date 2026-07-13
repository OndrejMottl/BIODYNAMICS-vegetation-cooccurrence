# Git Workflow Guidance

Canonical git, branch, worktree, review, and merge workflow guidance for this repository.

# Git Workflow Instructions

## CRITICAL: The User Is in Full Control of Version Control

**Never perform any state-changing git operation without explicit user instruction.** The user must ask for it by name (e.g. "please commit", "push this", "merge the branch"). Do not infer intent â€” always wait for a direct request.

Forbidden without explicit user instruction:

- `git commit` (any form, including `--amend`)
- `git add` / staging files
- `git push` (any remote write)
- `git merge` / `git merge --squash`
- `git rebase`
- `git reset --hard` or `--mixed`
- `git branch -d` / `git branch -D` (branch deletion)
- `git worktree remove`
- Creating pull requests via any tool or MCP call
- Any MCP/tool-based equivalent: `mcp_gitkraken_git_add_or_commit`,
  `mcp_gitkraken_git_push`, `mcp_gitkraken_pull_request_create`, etc.

Safe read-only operations that are always permitted: `git status`, `git log`,
`git diff`, `git branch` (list), `git worktree list`.

When a workflow step calls for a commit or push (e.g. at the end of the TDD
cycle), **stop and tell the user what command to run** â€” do not run it.

## Durable Change Naming

Commit messages, pull-request titles, branch descriptions, release notes, and
other long-lived change summaries must describe the implemented behaviour or
domain outcome. Do not use time-specific implementation-plan labels such as
`Phase 1`, `Phase 2`, `stage 3`, or similar sequencing as the change name;
those labels lose meaning after the plan is complete.

A phase or stage label may be mentioned only when directly referencing a pull
request or issue that explicitly uses that label in its own title. Even then,
the durable change summary should still state what behaviour changed.

```text
# Good
CV: integrate adaptive spatial fold assignment across pipelines

# Avoid
CV: complete Phase 1
```

## Branch Strategy

This project uses `main` as the stable integration branch. All feature branches and worktrees **must** branch off `main`.

## Git Worktree Workflow

Git worktrees allow multiple branches to be checked out simultaneously in separate directories, sharing the same `.git` database. This is the recommended approach for developing new features or running new pipelines **while a long-running analysis (e.g. a continental-scale model) is active in the main worktree**.

`Data/targets/` and `Data/Temp/` are fully `.gitignore`'d, so each worktree has its own isolated pipeline outputs and temporary files  -  the running session is never disturbed.

### CRITICAL: Always branch from `main`

**Never create a worktree from a feature branch.**

```powershell
# WRONG: branching from a feature branch instead of main
git checkout spatial_scale          # feature branch  -  NOT main
git worktree add ..\new-folder -b new-feature
```

This silently inherits all commits from the feature branch, causing the new branch to diverge from `main` with unrelated work. Merging back later requires cherry-picking or complex rebasing.

### Creating a Worktree

```powershell
# 1. Ensure main is checked out and up to date BEFORE branching
git checkout main
git pull origin main

# 2. Create the new worktree; -b must come BEFORE the path (not after)
git worktree add -b <branch_name> ..\BIODYNAMICS_<feature_name>

# 3. Verify the worktree was created on the expected branch
git worktree list

# 4. Open it in a new VS Code window
code -n ..\BIODYNAMICS_<feature_name>
```

Symlink VegVault to avoid copying the large file. `mklink` requires an elevated prompt  -  open **cmd as Administrator**, then run:

```cmd
mklink "D:\GITHUB\BIODYNAMICS_<feature_name>\Data\Input\VegVault.sqlite" "D:\GITHUB\BIODYNAMICS_vegetation_cooccurrence\Data\Input\VegVault.sqlite"
```

Then in an R session inside the new worktree:

```r
# 5. Restore renv (fast  -  packages already in the global cache)
renv::restore()
```

### Checklist before adding a worktree

- [ ] Run `git branch` and confirm the current branch is `main`
- [ ] Run `git pull origin main` to ensure `main` is up to date
- [ ] Then run `git worktree add`

### Completing Work and Merging Back

After developing code and running the pipeline in the linked worktree:

```powershell
# 6. Copy only the specific pipeline's targets store to the main worktree
#    BEFORE merging (while the linked worktree directory still exists).
#    Copy only store(s) that were newly run or updated in this worktree  - 
#    do NOT copy the entire Data/targets/ folder.
Copy-Item -Recurse `
  "..\BIODYNAMICS_<feature_name>\Data\targets\<store_name>" `
  ".\Data\targets\<store_name>"
```

In the main worktree's R session, `targets::tar_make()` will then find the copied store, verify all content hashes, and report "All targets are up to date" without recomputing.

```powershell
# 7. Squash-merge the branch (one clean commit per feature)
git checkout main
git merge --squash <branch_name>
git commit -m "<descriptive message>"
git push origin main

# 8. Close the worktree's VS Code window FIRST, then remove.
#    Open file handles on Windows will prevent deletion.
git worktree remove ..\BIODYNAMICS_<feature_name>

# 9. Optionally delete the branch
git branch -d <branch_name>
```

If step 8 fails (e.g. a partial deletion already removed `.git` from the worktree directory), recover with:
```powershell
git worktree prune
Remove-Item -Recurse -Force "..\BIODYNAMICS_<feature_name>"
git branch -d <branch_name>
```

> Merge order matters: always merge branches into `main` in the order they were created (oldest-base first), so each squash contains only the work unique to that branch.

### Key Rules

- **Always branch from `main`**  -  never from another feature branch.
- **Two worktrees cannot be on the same branch**  -  git enforces this.
- **Copy targets store before removing** the linked worktree (step 6 before step 8).
- **`renv.lock` or `config.yml` changes** committed in one worktree require `git pull` + `renv::restore()` in the other worktree.
- `Data/Input/VegVault.sqlite` is git-ignored and must be symlinked manually in each new worktree.
