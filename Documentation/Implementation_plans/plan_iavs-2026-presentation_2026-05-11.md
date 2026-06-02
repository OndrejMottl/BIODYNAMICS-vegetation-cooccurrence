# Plan: IAVS 2026 Conference Presentation — MOTHER Terminal

**Date:** 2026-05-11
**Author:** plan-large-changes agent
**Status:** Final (Open Questions Answered)

---

## Goal

Build a complete, publicly-deployed Quarto RevealJS presentation for the IAVS 2026
conference (22 June 2026) that frames the BIODYNAMICS vegetation co-occurrence
research as an interaction with **MOTHER** — a retro sci-fi ecological
biosurveillance terminal inspired by the *Alien* MU-TH-UR 6000 computer. The
presentation will:
- Cover the full talk arc (motivation → data → methods → results → synthesis)
- Fit within a 12-minute oral slot (+ 3 minutes discussion)
- Exceed 20 slides in a 16:9 aspect ratio
- Deliver a visually consistent dark-phosphor-green aesthetic across all slide types,
  ggplot2 figures, and atmospheric story visuals
- Be published to the project GitHub Pages site as an integrated sub-section

---

## Scope

### In scope

- **GitHub Pages integration**: the presentation is integrated into the main project
  `_quarto.yml` website. The presentation folder
  `Documentation/Presentations/IAVS_2026/` renders as part of the regular site build
  and appears under `/presentations/iavs-2026/` on the live site.
- Presentation Quarto sub-project in `Documentation/Presentations/IAVS_2026/`
  with its own `_quarto.yml`, SCSS, and asset folder
- A **single source of truth** for all design constants: `design_config.json` (colors,
  fonts, sizing)
- An R preprocessing script that reads `design_config.json` at render time and generates
  R objects + auto-generated SCSS file (`mother_generated.scss`)
- A presentation-local `theme_mother()` ggplot2 helper script (not a project-level
  function with tests)
- SCSS CRT visual system (scanlines, phosphor glow, blinking cursor, MOTHER dialogue
  boxes, slide archetypes)
- Talk script (narrative, MOTHER dialogue, slide-by-slide content plan)
- Slide template QMD defining all reusable Quarto div classes
- Atmospheric / story figures (R-generated ggplot2 art, AI-generated via ChatGPT or
  similar, or web-sourced Creative Commons images)
- Result figure integration: real `tar_read()` outputs for pipeline-generated data,
  simulated R placeholders for unavailable targets
- ggplot2 styling of all result figures using the local MOTHER theme
- Time-fitted narrative: 12-minute presentation (slides timed and scripted accordingly)
- Iterative passes: script → first slides → figure integration → visual polish →
  second content pass → final delivery

### Out of scope

- Promoting `theme_mother()` to a project-level tested function
- Changes to any pipeline, pipe segment, or analysis script
- Modifications to the project's core analysis infrastructure

### Affected files / components

- New directory tree: `Documentation/Presentations/IAVS_2026/` (all files new)
- Modified: `_quarto.yml` (at root) — add presentation section to render and sidebar
- `Data/Temp/presentation/` — reference images and brainstorm documents (read-only)
- Git worktree: new branch `<N>-presentation-iavs-2026` in
  `..\BIODYNAMICS_presentation_iavs_2026`

---

## Git Worktree Setup

Follow `.github/instructions/git-workflow.instructions.md`.
Create the GitHub umbrella issue first, then name the branch after it.

1. Ensure `main` is current:
   ```powershell
   git checkout main
   git pull origin main
   ```
2. Create the worktree (replace `<N>` with the created issue number):
   ```powershell
   git worktree add -b <N>-presentation-iavs-2026 ..\BIODYNAMICS_presentation_iavs_2026
   ```
3. Verify:
   ```powershell
   git worktree list
   ```
4. Open in a new VS Code window:
   ```powershell
   code -n ..\BIODYNAMICS_presentation_iavs_2026
   ```
5. Symlink VegVault (elevated cmd — only needed if result figures require live
   pipeline reads):
   ```cmd
   mklink "D:\GITHUB\BIODYNAMICS_presentation_iavs_2026\Data\Input\VegVault.sqlite" ^
          "D:\GITHUB\BIODYNAMICS_vegetation_cooccurrence\Data\Input\VegVault.sqlite"
   ```
6. Restore renv in the new worktree's R session:
   ```r
   renv::restore()
   ```

---

## Refactoring Strategy

The integration scope is "Large" but is **additive only** — no existing analysis or
pipeline code is changed. The integration work is:

- **Single source of truth for design**: `design_config.json` holds all MOTHER colors,
  typography, and sizing constants. One edit point for the entire visual system.
- **R preprocessing pipeline**: `R/load_design_config.R` reads the JSON at render time,
  exports R objects (`col_palette`, `typography` etc.) for use by `theme_mother()`,
  and writes `mother_generated.scss` for SCSS to import.
- **Shared graphical vocabulary**: all figures and slides pull from the same config
  objects, ensuring consistency across R and CSS.
- **Shared figure pipeline**: a local `figures/` directory holds all presentation
  figures. A dedicated `R/make_figures.R` script produces or copies every figure used.
- **Quarto div system**: all slide archetypes (section/story, problem, query, pipeline,
  result-one, result-multi, closing) are defined as CSS classes and used consistently.
- **Figure source discipline**: `figures/README_figures.md` records for each figure
  whether it is real (`tar_read()` target name), simulated (R script), or externally
  sourced (URL/tool + license).
- **GitHub Pages integration**: minimal modification to root `_quarto.yml` to include
  the presentation folder in the site render. The presentation appears as a dedicated
  sub-section on the live site.

Order of integration steps — each phase leaves the presentation in a renderable state:

1. Design config JSON + preprocessing script + SCSS imports → render passes
2. All slide archetypes defined as divs → render passes
3. Atmospheric figures inserted → render passes
4. Each result section gets placeholder figure → render passes
5. Placeholders replaced with real/simulated figures one section at a time
6. Polish passes
7. Deploy to GitHub Pages as part of the main site

---

## Implementation Phases

### Phase 1 — Infrastructure & Visual System

**Goal:** A rendering Quarto RevealJS project with the full MOTHER visual framework
applied, proven on a 3-slide proof-of-concept. Design config is the single source of
truth. GitHub Pages integration is configured.

**Estimated window:** Days 1–3 (by ~14 May 2026)

**Tasks:**
- [ ] Create `Documentation/Presentations/IAVS_2026/` directory structure:
  - `_quarto.yml` (RevealJS project sub-config, 16:9 aspect ratio)
  - `index.qmd` (main presentation file)
  - `design_config.json` (all colors, fonts, sizes — single source of truth)
  - `mother.scss` (CRT visual system, imports `mother_generated.scss`)
  - `R/load_design_config.R` (reads JSON, generates R objects + `mother_generated.scss`)
  - `R/theme_mother.R` (ggplot2 theme helper using loaded config)
  - `R/palette_mother.R` (named vectors exported by `load_design_config.R`)
  - `figures/` (empty, with `README_figures.md`)
  - `assets/` (fonts, any static images)
- [ ] Create `design_config.json` with structure:
  ```json
  {
    "palette": {
      "bg": "#050805",
      "primary_green": "#33FF33",
      "cyan": "#00E5FF",
      "amber": "#FFB000",
      "coral": "#FF6B6B",
      "violet": "#C792EA",
      "secondary_green": "#1a331a",
      "soft_white": "#E8F1EF"
    },
    "typography": {
      "font_mono": "IBM Plex Mono",
      "font_mono_header": "Share Tech Mono",
      "font_sans": "Inter",
      "font_vt323": "VT323",
      "base_size_px": 18
    },
    "visual_effects": {
      "scanline_opacity": 0.2,
      "scanline_height_px": 3,
      "cursor_blink_speed_ms": 1000,
      "glow_blur_px": 15,
      "glow_opacity": 0.6
    }
  }
  ```
- [ ] Implement `R/load_design_config.R`:
  - Read `design_config.json` using `jsonlite::fromJSON()`
  - Export named vectors: `col_palette`, `typography`, `visual_effects`
  - Assign to global environment or return as list
  - Generate `mother_generated.scss` with CSS custom properties (`--col-bg`, `--col-green`, etc.)
  - Write `mother_generated.scss` to the presentation folder
- [ ] Create presentation-specific `_quarto.yml` in `Documentation/Presentations/IAVS_2026/`:
  - Configure RevealJS format, aspect ratio 16:9
  - Set SCSS include list: `mother.scss` (which imports `mother_generated.scss`)
  - Font imports (IBM Plex Mono, Share Tech Mono, VT323 from Google Fonts)
  - Transition settings, slide numbers
  - Pre-render hook to call `source("R/load_design_config.R")` before rendering
- [ ] Update root `_quarto.yml`:
  - Add `Documentation/Presentations/IAVS_2026/` to the render list
  - Add a "Presentations" sidebar item linking to the presentation (e.g., under
    `/presentations/iavs-2026/`)
- [ ] Implement `mother.scss`:
  - Import `mother_generated.scss` at the top
  - Use CSS variables (`var(--col-bg)`, etc.) for all colors and sizing
  - Scanline overlay, phosphor glow, blinking cursor, `mother-says` dialogue box,
    monochrome image filter, glow animations
  - Slide-archetype CSS classes (`.section-slide`, `.query-slide`, `.result-one`,
    `.result-multipanel`, `.problem`, `.pipeline`)
- [ ] Implement `R/theme_mother.R`:
  - Source or reference the loaded `col_palette` and `typography`
  - Create `theme_mother()` function returning a ggplot2 theme
  - Use palette values for all color and size parameters
  - Set `base_size` to at least 18 for projection legibility
- [ ] Implement `R/palette_mother.R`:
  - Will be auto-populated by `load_design_config.R`, or define empty stubs for IDE
    purposes
- [ ] Draft 3 proof-of-concept slides (title boot, query, result-one with dummy
  figure) and confirm render
- [ ] Test that the presentation folder renders independently:
  `quarto render Documentation/Presentations/IAVS_2026/`
- [ ] Test that the full site renders with the presentation integrated:
  `quarto render` at the root

**Validation:**
- `quarto render Documentation/Presentations/IAVS_2026/` completes without errors
- `quarto render` at root completes without errors
- `mother_generated.scss` is created and contains all CSS custom properties
- All 3 demo slide types display correctly in browser
- SCSS scanline, cursor blink, and MOTHER dialogue box render as expected
- `load_design_config.R` can be sourced independently in R without errors
- `theme_mother()` sourced in an R session produces a correct ggplot2 object with
  colors from the config
- Changing one color in `design_config.json` and re-rendering updates both SCSS and
  ggplot2 figures
- Root `_quarto.yml` modifications are minimal and non-breaking; existing site renders
  correctly
- *This phase does not meet the larger-code-change threshold for the mandatory
  subagent review (no source, pipeline, analysis, or test files modified).*

---

### Phase 2 — Talk Script & Slide Architecture

**Goal:** A written slide-by-slide script mapping every slide to its archetype,
MOTHER dialogue, figure slot, and content — the blueprint for all QMD authoring.
Script must fit within 12 minutes of oral presentation time.

**Estimated window:** Days 3–6 (by ~17 May 2026)

**Tasks:**
- [ ] Write complete narrative arc in `Documentation/Presentations/IAVS_2026/script.md`:
  - Opening boot sequence (system init)
  - Story/premise (why hidden interactions matter)
  - Mission / data axes (spatial, temporal, taxonomic)
  - MOTHER companion introduction
  - Methods: data ingestion, model framework, latent space, network inference,
    uncertainty quantification
  - Results (one query per major result): temporal dynamics, spatial patterns,
    taxonomic signals, environmental drivers
  - Synthesis / key insights
  - Implications & conservation
  - Limitations & future work
  - Closing transmission
- [ ] For each slide, record: slide number, archetype, title, MOTHER prompt, MOTHER
  dialogue text, figure slot (type + source), key bullets, confidence/status line
- [ ] Estimate speaking time per slide (target: 12 minutes total, ~45 seconds per
  slide for >20 slides)
- [ ] Decide which slides need atmospheric story figures vs. real data figures vs.
  simulated R figures
- [ ] Map result slides to specific `tar_read()` target names
- [ ] Flag slides needing AI / web-sourced story art as `[GENAI]`

**Validation:**
- Script reviewed and approved by user before Phase 3 begins
- Every slide has a defined archetype, figure slot decision, and MOTHER dialogue text
- Target-name mapping confirmed against `targets::tar_manifest()`
- Speaking time estimate totals ≤ 12 minutes

---

### Phase 3 — Atmospheric & Story Figures

**Goal:** All non-data "story" figures (particle clouds, network art, world map base,
MOTHER portrait) are produced and placed in `figures/story/`. AI image generation
approach (ChatGPT, DALL-E, or similar) is tested and integrated.

**Estimated window:** Days 6–10 (by ~21 May 2026)

**Tasks:**
- [ ] Test AI image generation tool (ChatGPT's image generation, or external tool like
  DALL-E): establish workflow and style prompts
- [ ] Title boot slide: animated terminal log (pure CSS/HTML in QMD — no external
  figure)
- [ ] "Hidden majority" particle scatter: R/ggplot2 — random point cloud with
  observed/hidden contrast
- [ ] Abstract network art: R/igraph + ggraph — network with MOTHER palette
- [ ] Latent space trajectory art: R/ggplot2 swarm/trajectory illustration
- [ ] World map base (for spatial results): R/sf + ggplot2 in MOTHER theme
- [ ] MOTHER companion portrait (`assets/mother_face.png`): AI-generated via chosen
  tool; license and generation notes recorded in `README_figures.md`
- [ ] Atmospheric planet/biosphere image: AI-generated, Creative Commons sourced, or
  generated in R; license noted
- [ ] All story figures styled with MOTHER palette and saved to `figures/story/`

**Validation:**
- All figures render in slides without visual overflow
- Colors match `col_palette` constants from `design_config.json`
- `README_figures.md` lists every figure with source, license, and generation method
  (e.g., "AI: ChatGPT image generation, license: CC-BY")

---

### Phase 4 — First Pass: All Slides (Skeleton)

**Goal:** Every slide exists in `index.qmd` with correct archetype, placeholder figure,
and MOTHER dialogue populated from the approved script. Slide count confirmed ≥ 20.

**Estimated window:** Days 10–16 (by ~27 May 2026)

**Tasks:**
- [ ] Translate every slide from `script.md` into QMD using the established div
  archetypes
- [ ] Insert story figures (Phase 3) into their slots
- [ ] Insert labelled grey-box placeholder calls for all missing result figures
- [ ] Verify slide count ≥ 20; adjust granularity if needed
- [ ] Scaffold all Quarto fragments, incremental reveals, and transitions
- [ ] Add speaker notes (`:::notes`) with time cues per slide to aid rehearsal
- [ ] Confirm `quarto render` passes end-to-end

**Validation:**
- `quarto render` completes without errors
- All >20 slides render; no blank or broken layouts
- Presentation is reviewable as a complete narrative draft
- Speaker notes with time cues are present

---

### Phase 5 — Result Figure Integration

**Goal:** Every result-slide placeholder is replaced with a real or convincingly
simulated figure styled with `theme_mother()`.

**Estimated window:** Days 16–24 (by ~4 June 2026)

**Tasks:**
- [ ] Create `R/make_figures.R` — master script that produces all presentation figures
  and saves to `figures/results/`
- [ ] Source pipeline data via `tar_read()` to extract data for each result figure.
  Targets to produce:
  - Co-occurrence network snapshot (2020)
  - Temporal stability (Jaccard similarity over time)
  - Spatial hotspot map (mean edge probability)
  - Trajectories in latent space
  - Environmental drivers (variable importance + partial effects)
  - Taxonomic signals (within vs. between clades)
  - Uncertainty / posterior credible intervals example
- [ ] For each target: extract → apply `theme_mother()` → save PNG
- [ ] For unavailable targets: generate plausible simulated data in R; mark
  `[SIMULATED]` in `README_figures.md`
- [ ] Style all figures at 1920×1080 canvas size (to match display resolution);
  test for font size (base_size ≥ 18) and overflow
- [ ] Update `README_figures.md` with source, license, and real vs. simulated status

**Validation:**
- All result figures render without overflow or font-size issues
- Simulated figures labeled in `README_figures.md` and as `fig.cap` in QMD
- `quarto render` passes
- All figures visually consistent with MOTHER palette and typography

---

### Phase 6 — Visual Polish Pass

**Goal:** Every slide meets the MOTHER aesthetic fully — glow, color semantics,
typography, layout precision, and transitions.

**Estimated window:** Days 24–30 (by ~10 June 2026)

**Tasks:**
- [ ] SCSS refinements via `design_config.json`: glow intensity, scanline density,
  cursor speed, visual effect parameters; test on dark projected background
- [ ] Typography audit: confirm fonts load in browser; specify monospace fallbacks
- [ ] Color semantic audit: cyan = spatial, amber = temporal, violet = latent,
  coral = warning
- [ ] Layout audit: no text overflow, no clipped figures across all slide types
- [ ] Animation/transition audit: fade-to-black between sections; fragment order
- [ ] MOTHER dialogue box refinements: consistent padding, amber `MOTHER>` prefix,
  spacing
- [ ] Slide footer/header system: session ID, version string, slide numbers if desired

**Validation:**
- Full render reviewed slide-by-slide in browser at 1920×1080
- Colleague or peer review for legibility at projection distance
- No browser console errors (font loading, SCSS)
- Visual consistency check: all figures, dialogue boxes, and text use the MOTHER
  palette

---

### Phase 7 — Second Content & Narrative Pass

**Goal:** All slide text, MOTHER dialogue, and narrative flow are tightened and
scientifically accurate. 12-minute timing is confirmed.

**Estimated window:** Days 30–35 (by ~15 June 2026)

**Tasks:**
- [ ] Read every slide as continuous narrative; fix gaps and redundancies
- [ ] Tighten MOTHER dialogue to ≤ 4 lines per panel
- [ ] Cross-check all factual claims against `script.md` and the abstract
- [ ] Confirm all three abstract expectations (scale, rapid-change, taxonomic-grain)
  appear explicitly in methods and results slides
- [ ] Refine confidence/status lines to reflect actual model outputs
- [ ] Update speaker notes with finalized timing per slide (≤ 12 minutes total)
- [ ] Verify talk fits the conference oral time slot (12 min presentation)

**Validation:**
- User approves the narrative pass
- All three abstract expectations are traceable to specific slides
- Speaker notes with timing exist for all non-trivial slides
- Full rehearsal run times ≤ 12 minutes

---

### Phase 8 — Final Polish & Delivery Prep

**Goal:** Presentation is conference-ready and deployed to GitHub Pages. Export
formats tested, accessibility pass complete, rehearsal confirmed.

**Estimated window:** Days 35–40 (by ~20 June 2026)

**Tasks:**
- [ ] Replace remaining `[SIMULATED]` figures with real pipeline outputs if targets
  are now computed
- [ ] Export self-contained HTML backup (for local/USB backup on conference day)
- [ ] Export PDF backup via `decktape` or RevealJS-PDF renderer; verify legibility
- [ ] Accessibility pass: alt-text on all figures, color-contrast check on text-over
  backgrounds
- [ ] Final rehearsal: time the talk with all pauses and transitions; confirm ≤ 12 min
- [ ] Commit and push all presentation files to the GitHub branch
- [ ] Verify that the full site renders correctly with the presentation integrated:
  `quarto render` at root
- [ ] Prepare deployment instructions for user (confirm GitHub Pages auto-deploy is
  active, or provide manual deployment command)

**Validation:**
- HTML backup renders fully offline
- PDF backup is legible at A4/letter scale
- Talk times ≤ 12 minutes in final rehearsal
- Root `_quarto.yml` site still builds and renders correctly
- Presentation appears correctly on the live GitHub Pages site (or is ready for
  immediate deploy)
- User confirms readiness for conference presentation

---

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|-----------|
| Key pipeline results not available before Phase 5 | High | Simulated R figures as drop-in placeholders from Day 1; swap when ready |
| SCSS font loading fails in browser / on conference laptop | Medium | Embed fonts as base64 or host locally in `assets/`; specify monospace fallbacks |
| ggplot2 figure text too small at projection distance | High | Test at 1920×1080 from Phase 3; set `base_size` ≥ 18 in config |
| RevealJS layout breaks with large figures | Medium | Use `fig-width`/`fig-height` YAML per chunk; test early |
| AI-generated MOTHER portrait licensing / quality issues | Medium | Test ChatGPT early in Phase 3; document license; have backup hand-drawn or web option |
| Conference laptop has no R/Quarto installed | Medium | Export fully self-contained HTML and PDF; travel with USB backup |
| 12-minute time slot proves too tight | Medium | Speaker notes track time per section; rehearse aggressively in Phase 7; trim lowest-priority detail slides |
| Root `_quarto.yml` integration breaks existing site | Low | Test root render in Phase 1; changes are minimal and isolated to presentation section |
| GitHub Pages deploy timing / automation fails | Low | Prepare manual deployment command; test in advance; confirm auto-deploy is active |

---

## Answers to Open Questions

**1. Conference oral presentation time limit?**  
✅ 12 minutes for presentation + 3 minutes discussion = 15 minutes total slot  
Impact: Phase 7 and Phase 8 are timed to fit ≤ 12 minutes; speaker notes track timing per slide.

**2. Should the presentation be published to GitHub Pages?**  
✅ Yes, integrated into the main project site under `/presentations/iavs-2026/`  
Approach: `Documentation/Presentations/IAVS_2026/` is added to the root `_quarto.yml`
render list, so the presentation builds and deploys alongside the main website.

**3. Which AI tool for story images (MOTHER face, atmospheric planet)?**  
✅ Will be tested (likely ChatGPT or similar) in Phase 3  
Impact: Phase 3 timeline includes testing and workflow establishment; AI-generated
figures are documented with license/generation notes in `README_figures.md`.

**4. Are any result figures already available in `_targets/`?**  
✅ No; pipeline provides data only  
Impact: All result figures in Phase 5 are produced fresh via `tar_read()` extraction.
Simulated placeholders are used in Phases 1–4 and swapped for real figures as targets
become available.

---

## GitHub Issues Scaffold

### Umbrella Issue

**Title:** IAVS 2026 Presentation: MOTHER Terminal RevealJS

**Body:**

```
## Background

The BIODYNAMICS vegetation co-occurrence project needs a conference presentation for
IAVS 2026 (22 June 2026). A retro sci-fi "MOTHER terminal" visual aesthetic has been
designed (phosphor green, CRT scanlines, MOTHER dialogue boxes) based on the
*Alien* MU-TH-UR 6000 computer interface. The presentation will be built as a
standalone Quarto RevealJS project in `Documentation/Presentations/IAVS_2026/`,
integrated into the main project website, and published to GitHub Pages.

Design constants (colors, fonts, sizing) are managed through a single source of truth:
`design_config.json`, which is read at render time and used to generate both R objects
and auto-generated SCSS.

The presentation fits within a 12-minute oral slot (+ 3 minutes discussion) with a
16:9 aspect ratio.

## Goal

Deliver a conference-ready, >20-slide Quarto RevealJS presentation that frames the
BIODYNAMICS research as queries to the MOTHER ecological biosurveillance system,
with a fully consistent visual identity across all slide types, ggplot2 figures,
and atmospheric story visuals. Publish the presentation to the project GitHub Pages
site as an integrated sub-section.

## Approach

Eight sequential phases: (1) infrastructure & visual system with design config
single-source-of-truth and GitHub Pages integration, (2) talk script & slide
architecture (12-minute timing), (3) atmospheric/story figures with AI image generation
testing, (4) first skeleton pass on all slides, (5) result figure integration from
pipeline data, (6) visual polish, (7) second content/narrative pass (timing validation),
(8) final delivery prep and GitHub Pages deployment. Each phase has its own validation
gate.

## Acceptance Criteria

- [ ] `quarto render Documentation/Presentations/IAVS_2026/` completes without errors
- [ ] Root `quarto render` completes without errors (site + presentation integrated)
- [ ] Design config (`design_config.json`) is the single source of truth for colors,
      fonts, and visual effects
- [ ] All >20 slides use established MOTHER div archetypes consistently
- [ ] All ggplot2 figures use `theme_mother()` with colors from design config
- [ ] Every figure has a record in `README_figures.md` (source, license, real/simulated)
- [ ] Self-contained HTML and PDF backup both render correctly
- [ ] Talk times within the 12-minute presentation slot
- [ ] Presentation appears correctly on GitHub Pages site (or is ready for immediate
      deploy)
- [ ] No existing project files (analysis scripts, pipelines, core functions) are
      modified

## Sub-issues

- [ ] #placeholder Phase 1 — Infrastructure & Visual System
- [ ] #placeholder Phase 2 — Talk Script & Slide Architecture
- [ ] #placeholder Phase 3 — Atmospheric & Story Figures
- [ ] #placeholder Phase 4 — First Pass: All Slides (Skeleton)
- [ ] #placeholder Phase 5 — Result Figure Integration
- [ ] #placeholder Phase 6 — Visual Polish Pass
- [ ] #placeholder Phase 7 — Second Content & Narrative Pass
- [ ] #placeholder Phase 8 — Final Polish & Delivery Prep
```

---

### Sub-issues (one per phase)

#### [Pres Phase 1] Infrastructure & Visual System

```
## Context

Sets up the standalone Quarto RevealJS project in
`Documentation/Presentations/IAVS_2026/` with the complete MOTHER SCSS visual
framework and design config single-source-of-truth, proven on a 3-slide proof-of-concept.
Integrates the presentation into the main project website for GitHub Pages publication.

## Tasks

- [ ] Create directory structure: design_config.json, presentation _quarto.yml,
      index.qmd, mother.scss, R/load_design_config.R, R/theme_mother.R, R/palette_mother.R,
      figures/, assets/
- [ ] Implement design_config.json with palette, typography, visual effects
- [ ] Implement R/load_design_config.R: read JSON, export R objects, generate
      mother_generated.scss with CSS custom properties
- [ ] Configure presentation _quarto.yml with pre-render hook; set 16:9 aspect ratio
- [ ] Update root _quarto.yml: add presentation folder to render list and sidebar
- [ ] Implement mother.scss: use CSS variables, scanlines, cursor blink, MOTHER-says box,
      slide archetype classes
- [ ] Implement theme_mother.R and palette_mother.R using loaded config; base_size ≥ 18
- [ ] Draft 3 proof-of-concept slides; confirm independent render
- [ ] Test full site render at root; confirm presentation integrated correctly
- [ ] Verify single-source-of-truth: edit one color in JSON, re-render confirms
      both SCSS and R figures update

## Validation

- quarto render Documentation/Presentations/IAVS_2026/ passes
- quarto render (at root) passes; site + presentation render together
- mother_generated.scss is created with all CSS custom properties
- 3 demo slide types render correctly in browser
- load_design_config.R sources without errors in R
- theme_mother() produces ggplot2 object with correct colors from config
- Presentation appears in site navigation (sidebar / menu)
- Root _quarto.yml modifications are minimal and non-breaking
- git diff --stat shows no changes to existing analysis/pipeline files
- Part of: IAVS 2026 Presentation (umbrella issue)
```

#### [Pres Phase 2] Talk Script & Slide Architecture

```
## Context

Produces the detailed slide-by-slide script mapping every slide to its archetype,
MOTHER dialogue, figure slot decision, and pipeline target name. Script is timed
to fit within a 12-minute oral presentation slot. Blueprint for all QMD authoring.

## Tasks

- [ ] Write complete narrative arc in script.md
- [ ] For each slide: number, archetype, title, MOTHER prompt/dialogue, figure slot,
      key bullets, confidence line, estimated speaking time
- [ ] Estimate speaking time per slide (target: 12 minutes total for >20 slides,
      ~45 seconds/slide)
- [ ] Map result slides to tar_read() target names
- [ ] Flag slides needing AI/web story art as [GENAI]

## Validation

- Script reviewed and approved by user before Phase 3
- Every slide has archetype, figure slot, and MOTHER dialogue defined
- Target name mapping confirmed against targets::tar_manifest()
- Speaking time estimate totals ≤ 12 minutes
- Part of: IAVS 2026 Presentation (umbrella issue)
```

#### [Pres Phase 3] Atmospheric & Story Figures

```
## Context

Produces all non-data "story" figures used in opening, section, and atmospheric
slides. Tests AI image generation tool (ChatGPT or similar) for MOTHER portrait
and atmospheric images. Mix of R-generated art, Creative Commons images, and
AI-generated content.

## Tasks

- [ ] Test AI image generation tool; establish prompts and style guide
- [ ] Particle scatter "hidden majority" figure (R/ggplot2)
- [ ] Abstract network art (R/igraph + ggraph)
- [ ] Latent space trajectory art (R/ggplot2)
- [ ] World map base layer (R/sf + ggplot2)
- [ ] MOTHER companion portrait (AI-generated → assets/mother_face.png)
- [ ] Atmospheric planet/biosphere image (AI, CC, or R-generated)
- [ ] All figures saved to figures/story/; README_figures.md updated with license
      and generation method

## Validation

- All figures render in slides without overflow
- Colors match col_palette from design_config.json
- README_figures.md lists every figure with source, license, and generation method
- AI tool workflow is documented for future updates
- Part of: IAVS 2026 Presentation (umbrella issue)
```

#### [Pres Phase 4] First Pass — All Slides Skeleton

```
## Context

Translates the approved script into complete QMD using established div archetypes.
Every slide exists with correct structure, placeholder figures, and MOTHER dialogue.
Speaker notes with time cues scaffold the oral delivery.

## Tasks

- [ ] Translate every slide from script.md into QMD div archetypes
- [ ] Insert story figures; labelled placeholder boxes for missing results
- [ ] Verify slide count ≥ 20
- [ ] Scaffold all fragments and transitions
- [ ] Add speaker notes with time cues per slide for rehearsal aid
- [ ] Confirm quarto render passes end-to-end

## Validation

- quarto render completes without errors
- All >20 slides render; no blank or broken layouts
- Presentation reviewable as complete narrative draft
- Speaker notes with time cues present on all slides
- Part of: IAVS 2026 Presentation (umbrella issue)
```

#### [Pres Phase 5] Result Figure Integration

```
## Context

Replaces all placeholder figures with real pipeline outputs (tar_read()) or
convincingly simulated R figures, all styled with theme_mother() at 1920×1080 canvas
resolution.

## Tasks

- [ ] Create R/make_figures.R master figure production script
- [ ] Extract pipeline data via tar_read(); integrate: network snapshot, temporal
      stability, spatial map, latent trajectories, environmental drivers, taxonomic
      signals, uncertainty examples
- [ ] Apply theme_mother() with base_size ≥ 18 to all figures
- [ ] Simulated R figures for unavailable targets (mark [SIMULATED])
- [ ] Save all at 1920×1080 resolution; test for overflow and text size
- [ ] Update README_figures.md

## Validation

- All result figures render without overflow or font-size issues
- Simulated figures labeled in README_figures.md and fig.cap in QMD
- quarto render passes
- All figures consistent with MOTHER palette and typography
- Part of: IAVS 2026 Presentation (umbrella issue)
```

#### [Pres Phase 6] Visual Polish Pass

```
## Context

Full visual audit: every slide must meet the MOTHER aesthetic for glow, color
semantics, typography, layout precision, and transitions.

## Tasks

- [ ] SCSS refinements via design_config.json (glow, scanlines, cursor speed)
- [ ] Typography audit (font loading, fallbacks)
- [ ] Color semantic audit (cyan=spatial, amber=temporal, violet=latent, coral=warning)
- [ ] Layout audit (no overflow, no clipped figures)
- [ ] Animation/transition audit
- [ ] MOTHER dialogue box refinements
- [ ] Slide footer/header system

## Validation

- Full render reviewed slide-by-slide at 1920×1080 in browser
- Peer review for legibility at projection distance
- No browser console errors
- All figures and text use MOTHER palette consistently
- Part of: IAVS 2026 Presentation (umbrella issue)
```

#### [Pres Phase 7] Second Content & Narrative Pass

```
## Context

All slide text and MOTHER dialogue reviewed for scientific accuracy, narrative flow,
and projection legibility. 12-minute timing is validated. Speaker notes finalized.

## Tasks

- [ ] Read every slide as continuous narrative; fix gaps and redundancies
- [ ] Tighten MOTHER dialogue to ≤ 4 lines per panel
- [ ] Cross-check all factual claims against script.md and abstract
- [ ] Confirm all three abstract expectations appear explicitly
- [ ] Update speaker notes with finalized timing per slide
- [ ] Verify talk totals ≤ 12 minutes

## Validation

- User approves narrative pass
- All three abstract expectations traceable to specific slides
- Speaker notes with timing exist for all non-trivial slides
- Full rehearsal run times ≤ 12 minutes
- Part of: IAVS 2026 Presentation (umbrella issue)
```

#### [Pres Phase 8] Final Polish & Delivery Prep

```
## Context

Conference-readiness and GitHub Pages deployment: remaining simulated figures
replaced if possible, export formats tested, accessibility pass complete,
rehearsal confirmed, presentation deployed to live site.

## Tasks

- [ ] Replace remaining [SIMULATED] figures with real outputs if available
- [ ] Export self-contained HTML backup for USB/local use
- [ ] Export PDF backup; verify legibility
- [ ] Accessibility pass (alt-text, color-contrast)
- [ ] Final rehearsal: time the talk; confirm ≤ 12 minutes
- [ ] Commit and push all presentation files
- [ ] Test root quarto render (full site + presentation)
- [ ] Verify presentation appears on GitHub Pages live site (or prepare deployment)

## Validation

- HTML backup renders fully offline
- PDF backup legible
- Talk times ≤ 12 minutes in final rehearsal
- Root site still renders correctly
- Presentation live on GitHub Pages (or ready for immediate deploy)
- User confirms readiness for conference
- Part of: IAVS 2026 Presentation (umbrella issue)
```

---

## Summary

**8 phases, ~40 working days, deadline 20 June 2026 (2 days before conference):**

| Phase | Deliverable | Target date |
|---|---|---|
| 1 | Infrastructure, design config, GitHub Pages integration | ~14 May |
| 2 | Talk script, slide architecture, 12-minute timing | ~17 May |
| 3 | Atmospheric figures, AI image testing | ~21 May |
| 4 | All slides skeleton, >20 slides | ~27 May |
| 5 | Result figures from pipeline data | ~4 June |
| 6 | Visual polish, final styling | ~10 June |
| 7 | Content tightening, 12-minute validation | ~15 June |
| 8 | Export, deploy, conference readiness | ~20 June |

**Key decisions confirmed:**
- 12-minute presentation (+ 3 min discussion)
- 16:9 aspect ratio
- GitHub Pages: integrated into main site
- AI images: will test ChatGPT or similar
- No pre-computed figures; build from pipeline data
