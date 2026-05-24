# IAVS 2026 ORACLE Visual Guide

This is the canonical visual guidance for the IAVS 2026 ORACLE presentation.
Use this file to define, refine, and version all visual decisions.

## Scope

This guide covers:

- visual direction and narrative framing
- colour and typography standards
- GenAI prompt standards for story visuals
- R plotting settings for story figures and result compatibility
- Quarto slide conventions
- SCSS implementation patterns

This guide does not replace the figure register.
Figure inventory and implementation state are tracked in `README_figures.md`.

## Design Direction

ORACLE should feel like an ecological biosurveillance terminal:

- scientific instrument first
- narrative shell second
- no decorative sci-fi excess

Use the framing:

```text
QUERY -> PROCESS -> INTERPRET -> SIGNAL
```

## Visual Principles

- Terminal shell outside, clear science inside.
- Narrative visuals support interpretation but never impersonate analysis output.
- Data channel colours are semantic, not decorative.
- Motion should be subtle and sparse.

## Palette and Typography

Use `design_config.json` as the final authority.
The values below are the working defaults unless superseded there.

### Palette roles

- Background: `#08110D`
- Phosphor green: `#7CFFB2`
- Spatial channel (cyan): `#59E1FF`
- Temporal channel (amber): `#FFC857`
- Warning (coral/red): `#FF6B6B`
- Accent (violet, optional): `#C792EA`
- Light text: `#E8F1EF`
- Grid/metadata: `#29433A`

### Typography guidance

- Terminal/UI text: IBM Plex Mono or Share Tech Mono
- Body scientific text: IBM Plex Sans
- Use monospaced fonts selectively, not for entire dense slides

## Slide Archetypes

Use these archetypes consistently:

- `.oracle-title`: world-building title slides
- `.query-slide`: one question, one interface prompt
- `.system-slide`: method and pipeline explanations
- `.result-slide`: data figure plus concise interpretation panel

This may change as the deck evolves, but keep the archetype system for layout consistency.

## Figure-Type Rules

- Result figures: pipeline-derived only, never GenAI.
- Story and atmospheric figures: GenAI or deterministic R is allowed.
- Conceptual figures that look analytical must be labelled as non-result visuals.

## GenAI Prompt Standards

The canonical prompt log is `figures/story/genai_drafts/PROMPTS.md`.
Use these standards for future prompts.

### Core prompt template

```text
Create a low-fidelity 1979 ship-computer CRT terminal screen, not a modern sci-fi illustration.
Use black background, monochrome green phosphor, thin vector panel frames, visible scanlines, sparse pixel noise, terminal prompts, and rough instrument-readout composition.
Avoid cinematic lighting, glossy surfaces, modern holograms, photoreal portrait polish, neon cyberpunk, smooth dashboards, and decorative gradients.
```

### Good prompt characteristics

- explicit low-fidelity CRT constraint
- explicit anti-cinematic constraints
- composition instruction with negative space for slide text
- small and sparse terminal-text allowance only

### Reuse and provenance

When adding a new GenAI asset:

- store the prompt in `figures/story/genai_drafts/PROMPTS.md`
- add asset details to `README_figures.md`
- record intended slide use and status

## R Story Figure Settings

Deterministic story figures are generated via:

```powershell
Rscript Documentation/Presentations/IAVS_2026/R/generate_story_figures.R
```

### R style guidance

- use `theme_oracle()` where available
- use `ggview::save_ggplot()` for consistent output size and quality
- set fixed seeds for synthetic visuals
- keep line weights slightly thicker than default for projector readability

### R plotting checklist

- background contrast passes projector test
- labels remain readable at slide distance
- no decorative glow that reduces data clarity
- export dimensions match 16:9 slide context where needed

## Quarto Guidance

Presentation rendering target:

```powershell
Rscript -e "quarto::quarto_render('Documentation/Presentations/IAVS_2026')"
```

### Quarto layout conventions

- keep one primary visual message per slide
- use columns for figure plus interpretation panel layouts
- reserve dense multipanel layouts for diagnostic or appendix slides
- use fragments for staged explanation instead of animation-heavy backgrounds

### Motion policy

Prefer:

- cursor blink
- reveal fragments
- mild section-level pulse/flicker

Avoid:

- constant background motion on result slides
- heavy scanline overlays on dense figures
- rapid transitions that compete with scientific content

## SCSS Implementation Guidance

Centralize tokens and reuse classes.
Avoid per-slide ad-hoc colour overrides.

### Token scaffold

```scss
$oracle-bg: #08110d;
$oracle-green: #7cffb2;
$oracle-cyan: #59e1ff;
$oracle-amber: #ffc857;
$oracle-red: #ff6b6b;
$oracle-grid: #29433a;
$oracle-text: #e8f1ef;
```

### Panel style scaffold

```scss
.oracle-panel {
  border: 1px solid rgba($oracle-green, 0.55);
  border-radius: 0.5rem;
  background: rgba($oracle-bg, 0.82);
  box-shadow:
    0 0 12px rgba($oracle-green, 0.12),
    inset 0 0 18px rgba($oracle-green, 0.06);
  padding: 1rem;
}
```

### Cursor scaffold

```scss
.cursor::after {
  content: "_";
  color: $oracle-green;
  animation: blink 1s step-end infinite;
}

@keyframes blink {
  50% {
    opacity: 0;
  }
}
```

## Build-As-You-Go Workflow

Use this loop for incremental refinement:

1. Define one slide need in `README_figures.md`.
2. Create or update figure asset.
3. Verify style against this guide.
4. Render and review in Quarto.
5. Mark state in `README_figures.md`.

## Decision Log

Append short decisions here over time.

- 2026-05-24: canonical visual guidance moved from temporary brainstorming references to this file.
- 2026-05-24: retained look is terminal-native CRT, not cinematic sci-fi.
- 2026-05-24: story asset generation allows both deterministic R and selected GenAI drafts, while result figures stay output-derived only.
