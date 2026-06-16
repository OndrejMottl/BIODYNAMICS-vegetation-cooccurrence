## Plan: Issue 102 Phase 5 Figure Framework

Start Phase 5 by stabilizing the token-driven plotting framework that already exists, then implement per-slide figure scripts and a qmd chunk pipeline that separates generation (cached) from display. Reuse existing Phase 6 visual classes/layouts, allowing only minor helper additions where a figure cannot fit without reducing readability.

### Steps

#### Phase A: Confirm and freeze the token pipeline for R plotting

This phase blocks all figure scripts.

1. Audit the current dynamic token chain used by ORACLE visuals in [Documentation/Presentations/IAVS_2026/design_config.json](Documentation/Presentations/IAVS_2026/design_config.json), [Documentation/Presentations/IAVS_2026/R/pre_render.R](Documentation/Presentations/IAVS_2026/R/pre_render.R), [R/03_Supplementary_analyses/Presentation/load_design_config.R](R/03_Supplementary_analyses/Presentation/load_design_config.R), [R/Functions/Presentation/IAVS/load_design_config.R](R/Functions/Presentation/IAVS/load_design_config.R), [R/Functions/Presentation/IAVS/write_oracle_generated_scss.R](R/Functions/Presentation/IAVS/write_oracle_generated_scss.R), [Documentation/Presentations/IAVS_2026/oracle_generated.scss](Documentation/Presentations/IAVS_2026/oracle_generated.scss), and [R/Functions/Presentation/IAVS/theme_oracle.R](R/Functions/Presentation/IAVS/theme_oracle.R).
2. Define the Phase 5 framework contract document (in Presentation docs) stating that all output-derived figures must pull palette/typography only through theme_oracle/oracle token helpers and never hardcode visual constants. Depends on step 1.
3. Add a lightweight validation step in the render flow to fail early when generated tokens are stale versus design_config changes (for example timestamp or checksum comparison emitted by pre-render). Depends on step 1.

#### Phase B: Build per-slide script architecture

This phase can run in parallel after Phase A.

4. Create one script per analytical slide placeholder group under Presentation R scripts: slide 03, slide 05, slide 08, slide 09, slide 10, slide 11, slide 12. Each script should contain data load, figure assembly, save calls, and explicit provenance labels for register updates. Depends on step 2.
5. Keep shared internals in small reusable helpers (data access, file naming, save wrapper, common scales), but keep final figure definitions in per-slide scripts per your selected workflow. Parallel with step 4.
6. Standardize figure output naming convention by slide and panel (for example slide_08_spatial_map, slide_10_temporal_density) so qmd chunks remain stable while figure internals evolve. Parallel with step 4.
7. Add a thin orchestrator script only for optional batch rebuild convenience (non-authoritative), while preserving per-slide scripts as primary sources. Depends on step 4.

#### Phase C: Wire qmd chunk pattern

Generation first (cached), then render.

8. In [Documentation/Presentations/IAVS_2026/index.qmd](Documentation/Presentations/IAVS_2026/index.qmd), for each Phase 5 slot, use two chunks: a hidden generation chunk with cache true and a separate render chunk that only includes the saved artifact. Depends on step 4.
9. Configure chunk labels and cache keys to invalidate when design tokens or source scripts change, preventing stale themed outputs while keeping fast iteration. Depends on step 8.
10. Keep existing Phase 6 classes and slide archetypes untouched unless a figure cannot fit legibly; in those cases add only minimal utility classes, not new archetype structures. Depends on step 8.

#### Phase D: Implement figure-by-figure rollout aligned to Issue 102

11. Replace placeholders in this order to reduce dependency risk: slide 05 (single diagnostic), slide 03 (map plus ingestion visual), slide 08 and slide 09 (spatial and taxonomic matrix), slide 10 and slide 11 (temporal multipanel and trajectories), slide 12 (synthesis panel). Depends on step 8.
12. For unavailable outputs, render clearly provisional visuals with explicit on-slide and register labels; never style them as verified evidence. Depends on step 11.
13. Update [Documentation/Presentations/IAVS_2026/README_figures.md](Documentation/Presentations/IAVS_2026/README_figures.md) after each slide replacement with source path, provenance, verification state, and placement notes. Parallel with step 11.

#### Phase E: Verification gates

14. Run presentation render via [Documentation/Presentations/IAVS_2026/R/render.R](Documentation/Presentations/IAVS_2026/R/render.R) and direct Quarto render command for the deck, confirming no overflow and projector-legible text on slides 03, 05, and 08-12. Depends on steps 8-13.
15. Perform a visual compliance pass against [Documentation/Presentations/IAVS_2026/VISUAL_GUIDE.md](Documentation/Presentations/IAVS_2026/VISUAL_GUIDE.md): semantic color channels, figure-dominant layout, and restrained internal motion. Depends on step 14.
16. Record completion status for Issue 102 acceptance criteria and residual provisional items in the figure register and deck notes. Depends on step 15.

### Relevant files

- [Documentation/Presentations/IAVS_2026/design_config.json](Documentation/Presentations/IAVS_2026/design_config.json) — canonical design token source used by both SCSS and R plotting.
- [Documentation/Presentations/IAVS_2026/VISUAL_GUIDE.md](Documentation/Presentations/IAVS_2026/VISUAL_GUIDE.md) — visual policy for semantic channels, archetypes, and result-vs-story boundaries.
- [Documentation/Presentations/IAVS_2026/README_figures.md](Documentation/Presentations/IAVS_2026/README_figures.md) — source of truth for figure inventory and Phase 5 replacement contract.
- [Documentation/Presentations/IAVS_2026/index.qmd](Documentation/Presentations/IAVS_2026/index.qmd) — placeholders to replace and chunk architecture to wire for cached generation plus render.
- [Documentation/Presentations/IAVS_2026/_quarto.yml](Documentation/Presentations/IAVS_2026/_quarto.yml) — pre-render entrypoint and execution defaults.
- [Documentation/Presentations/IAVS_2026/R/pre_render.R](Documentation/Presentations/IAVS_2026/R/pre_render.R) — token-generation trigger before render.
- [Documentation/Presentations/IAVS_2026/R/render.R](Documentation/Presentations/IAVS_2026/R/render.R) — render wrapper for validation pass.
- [Documentation/Presentations/IAVS_2026/R/generate_story_figures.R](Documentation/Presentations/IAVS_2026/R/generate_story_figures.R) — existing figure script pattern and output handling reference.
- [R/03_Supplementary_analyses/Presentation/load_design_config.R](R/03_Supplementary_analyses/Presentation/load_design_config.R) — compatibility loader currently used by pre-render.
- [R/Functions/Presentation/IAVS/load_design_config.R](R/Functions/Presentation/IAVS/load_design_config.R) — canonical JSON loader.
- [R/Functions/Presentation/IAVS/oracle_palette_values.R](R/Functions/Presentation/IAVS/oracle_palette_values.R) — palette retrieval path from loaded design config.
- [R/Functions/Presentation/IAVS/theme_oracle.R](R/Functions/Presentation/IAVS/theme_oracle.R) — required plot theme for all output-derived figures.
- [R/Functions/Presentation/IAVS/write_oracle_generated_scss.R](R/Functions/Presentation/IAVS/write_oracle_generated_scss.R) — generated SCSS/token bridge.
- [Documentation/Presentations/IAVS_2026/oracle_generated.scss](Documentation/Presentations/IAVS_2026/oracle_generated.scss) — generated token artifact consumed by theme SCSS.
- [Documentation/Implementation_plans/plan_iavs-2026-presentation_2026-05-11.md](Documentation/Implementation_plans/plan_iavs-2026-presentation_2026-05-11.md) — original Phase 5/6 decomposition and acceptance context.

### Verification

1. Token parity check: modify one non-critical token in [Documentation/Presentations/IAVS_2026/design_config.json](Documentation/Presentations/IAVS_2026/design_config.json), run pre-render, and verify both [Documentation/Presentations/IAVS_2026/oracle_generated.scss](Documentation/Presentations/IAVS_2026/oracle_generated.scss) and at least one test plot from theme_oracle reflect the change.
2. Chunk cache behavior: first render should build all Phase 5 figures; second render should skip unchanged generation chunks; changing one slide script should invalidate only that slide’s cache.
3. Slide replacement check: verify placeholders are replaced on slides 03, 05, 08, 09, 10, 11, 12 in [Documentation/Presentations/IAVS_2026/index.qmd](Documentation/Presentations/IAVS_2026/index.qmd).
4. Provenance check: each replaced figure has a matching entry in [Documentation/Presentations/IAVS_2026/README_figures.md](Documentation/Presentations/IAVS_2026/README_figures.md) with verified or provisional status.
5. Render check: full presentation render passes and generated deck has no clipped labels or unreadable text at target dimensions.

### Decisions

- Include: Issue 102 Phase 5 framework plus rollout for result figure integration.
- Include: strict token-driven theming from design_config with dynamic loading path already present in repo.
- Include: per-slide scripts as primary implementation unit.
- Include: qmd two-chunk pattern with cache true for generation chunks.
- Include: reuse of existing Phase 6 visual system, with minor helper-class additions allowed only when necessary.
- Exclude: broad rework of slide archetypes, major SCSS redesign, or non-Phase-5 narrative rewrites.

### Further Considerations

1. Data source precedence for Phase 5 figures: prefer target store outputs first, then validated qs exports, then clearly marked provisional assets only when source outputs are unavailable.
2. Keep a single naming registry for figure files to avoid qmd churn and reduce broken-link risk during iterative replacements.
3. If any placeholder needs multi-panel composition beyond current layout capacity, add utility classes only in the local slide context and document them in visual guide decision log.
