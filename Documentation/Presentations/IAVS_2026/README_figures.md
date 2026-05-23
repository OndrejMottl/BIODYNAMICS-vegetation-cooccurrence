# IAVS 2026 Figure Register

This register documents non-result figures and atmospheric assets for the IAVS 2026 ORACLE RevealJS presentation.
These assets are story and setup visuals only.
They must not be interpreted as analysis outputs or evidence from the vegetation co-occurrence pipelines.

## Note

Through the project development, the terminal was originally named MOTHER, but the final presentation will refer to it as ORACLE.

## Style Guide

- Use `design_config.json` as the single source of truth for colours and visual effects.
- Follow the reference direction: Nostromo-style CRT terminal, phosphor noise, thin panel frames, small system prompts, and rough instrument readouts.
- Background and interface elements should stay mostly monochrome green; cyan, amber, and red should read as data or status channels.
- Avoid glossy cinematic sci-fi, polished dashboard cards, large decorative titles, and modern neon gradients.
- Keep story figures compatible with 16:9 RevealJS slides.
- Mark conceptual graphics as non-data or non-result figures when they could be mistaken for pipeline output.
- Do not use AI-generated content for pipeline result figures.
- Record source, license, generation method, and prompts before reusing any external or AI-generated asset.

## Asset Register

| Asset | Type | Source | License | Generation method |
|---|---|---|---|---|
| `figures/story/hidden_majority_particles.png` | R-generated conceptual terminal panel | Synthetic particles from `R/generate_story_figures.R` | Repository MIT license | `ggplot2`, `theme_oracle()`, `ggview::save_ggplot()`; seed `900723` |
| `figures/story/abstract_network_art.png` | R-generated conceptual terminal panel | Synthetic preferential-attachment graph from `R/generate_story_figures.R` | Repository MIT license | `igraph`, `ggplot2`, `theme_oracle()`, `ggview::save_ggplot()`; seed `900723` |
| `figures/story/latent_space_trajectory.png` | R-generated conceptual terminal panel | Synthetic latent trajectory from `R/generate_story_figures.R` | Repository MIT license | `ggplot2`, `theme_oracle()`, `ggview::save_ggplot()`; seed `900723` |
| `figures/story/world_map_base_layer.png` | R-generated basemap terminal panel | `maps::map("world")` paths transformed into terminal coordinates | Generated figure stored under repository MIT license where applicable; source map data follows the `maps` package data terms | `maps`, `ggplot2`, `theme_oracle()`, `ggview::save_ggplot()` |
| `figures/story/atmospheric_planet_biosphere.png` | R-generated atmospheric terminal panel | Synthetic point-field planet from `R/generate_story_figures.R` | Repository MIT license | `ggplot2`, `theme_oracle()`, `ggview::save_ggplot()`; seed `900723` |

## AI Generation Test

The built-in image generation workflow was tested for the ORACLE portrait and atmospheric planet assets.
The first generated outputs were visually coherent but too slick and modern for the reference direction.
The final committed assets therefore use deterministic R-generated terminal panels instead.
Future AI attempts should be prompted as low-fidelity CRT terminal composites, not cinematic concept art.

### GenAI Draft Outputs

The following draft outputs are retained for comparison only.
They are not currently the canonical assets referenced in the asset register.
The exact prompts are saved in `figures/story/genai_drafts/PROMPTS.md`.

| Draft asset | Prompt variant | Assessment |
|---|---|---|
| `figures/story/genai_drafts/oracle_terminal_face_v1.png` | ORACLE face as a low-fidelity terminal diagnostic screen | Strong candidate: matches CRT frame, green point face, and system-panel style while remaining less polished than the first AI pass |
| `figures/story/genai_drafts/planet_terminal_scan_v1.png` | Earth as alien biosphere archive scan | Strong candidate: good old-terminal planet scan with useful empty/title space and status panels |
| `figures/story/genai_drafts/oracle_abstract_face_v2.png` | Abstract non-human ORACLE face from data points and branching traces | Strong candidate for companion slide: more ecological and less android-like |
| `figures/story/genai_drafts/planet_abstract_scan_v2.png` | Abstract biosphere half-disc with ecological traces | Strong candidate for atmospheric opening/closing slide: closest to the `Data/Temp/Presentation/` terminal-reference mood |
| `figures/story/genai_drafts/vegetation_camera_moon_v1.png` | Pixelated terminal camera feed looking at trees and shrubs with a moon in the background | Strong candidate for story/premise slide 2: directly follows the May 11 reference composition while making the biosphere-camera premise explicit |
| `figures/story/genai_drafts/oracle_abstract_face_motif_v3.png` | Motif-only edit of `oracle_abstract_face_v2.png` with terminal decorations removed | Strong candidate for direct slide placement: centered ORACLE face on dark CRT background |
| `figures/story/genai_drafts/planet_abstract_scan_motif_v3.png` | Motif-only edit of `planet_abstract_scan_v2.png` with terminal decorations removed | Strong candidate for full-slide atmospheric use: centered biosphere half-disc with clean negative space |
| `figures/story/genai_drafts/vegetation_camera_moon_motif_v2.png` | Motif-only edit of `vegetation_camera_moon_v1.png` with terminal decorations removed | Strong candidate for story slide placement: vegetation and moon only on dark CRT background |

### Rejected Draft Prompt Pattern

```text
Create a cinematic sci-fi concept image for an ecological biosurveillance terminal using a dark background, phosphor green, cyan rim light, amber highlights, subtle CRT scanlines, and no text.
```

Issue with this pattern: it tends to produce polished modern sci-fi artwork rather than the rough ORACLE terminal style.

### Preferred Future AI Prompt Pattern

```text
Create a low-fidelity 1979 ship-computer CRT terminal screen, not a modern sci-fi illustration.
Use black background, monochrome green phosphor, thin vector panel frames, visible scanlines, sparse pixel noise, terminal prompts, and rough instrument-readout composition.
Avoid cinematic lighting, glossy surfaces, modern holograms, photoreal portrait polish, neon cyberpunk, smooth dashboards, and decorative gradients.
```

### Successful Prompt Variant: ORACLE Terminal Face

```text
Create a low-fidelity 1979 ship-computer CRT terminal screen for an ecological biosurveillance system called ORACLE.
Use a barely human face implied only by green phosphor dots and vector scan traces, like a diagnostic point cloud on an old terminal, not a realistic portrait.
Make it a degraded monochrome green computer terminal output with black background, thin green terminal frame, sparse system text blocks, scanlines, raster noise, dim phosphor bloom, and a few amber status accents.
Avoid photoreal face, glossy android, modern hologram, cinematic rim light, smooth dashboard UI, neon cyberpunk, polished concept art, logos, and watermark.
```

### Successful Prompt Variant: Planet Terminal Scan

```text
Create a low-fidelity old CRT terminal screen showing Earth as an alien biosphere archive being scanned by ORACLE.
The planet should be made of green phosphor dots, contour rings, and crude vector scan lines, like terminal data rather than a NASA render.
Use a black 1970s spacecraft computer display with thin panel border, sparse grid, scanlines, random phosphor speckles, and small system-status boxes.
Avoid photoreal Earth, modern holographic UI, blue atmosphere glow, glossy sci-fi, cinematic space poster, lens flare, cyberpunk neon, spacecraft, logos, and watermark.
```

## Regeneration

Run all deterministic story assets from the repository root:

```powershell
Rscript Documentation/Presentations/IAVS_2026/R/generate_story_figures.R
```

Then render the presentation:

```powershell
Rscript -e "quarto::quarto_render('Documentation/Presentations/IAVS_2026')"
```
