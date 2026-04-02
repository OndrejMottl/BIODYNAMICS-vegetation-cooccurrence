# Git Workflow Instructions

## CRITICAL: Never Commit Without Asking

**Never run `git commit` (or any equivalent operation that creates a commit) without first asking the user for confirmation.** This applies to:

- `git commit`
- `git merge --squash` followed by `git commit`
- `mcp_gitkraken_git_add_or_commit` or any MCP/tool-based commit operation
- Amending commits (`git commit --amend`)

Always show the user what would be committed (staged files, proposed commit message) and wait for explicit approval before proceeding.

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

