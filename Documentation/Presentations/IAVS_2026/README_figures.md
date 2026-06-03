# IAVS 2026 Figure Register

This file is the source of truth for figures used in the IAVS 2026 ORACLE RevealJS presentation.
If a figure is not listed here, it is not selected for the current deck.
The register keeps the visual guidance, the selected figure inventory, and the regeneration steps in one place.

## Note

The terminal was originally named MOTHER during development, but the final presentation refers to it as ORACLE.

## Figure Policy

- Use `design_config.json` as the single source of truth for colours and visual effects.
- Keep story figures compatible with 16:9 RevealJS slides.
- Do not use AI-generated content for pipeline result figures.
- Record source, license, generation method, prompt, and slide use before reusing any external or AI-generated asset.
- The register only keeps selected figures; it does not track discarded alternatives.

## Visual Guidance Location

Detailed visual guidance is maintained in `Documentation/Presentations/IAVS_2026/VISUAL_GUIDE.md`.
That file is the canonical place for style evolution, prompt standards, R plotting settings, Quarto conventions, and SCSS implementation details.

This register keeps only the figure inventory and implementation status.

### Minimal style guardrails (for quick reference)

- Use `design_config.json` as the colour and effects authority.
- Keep the ORACLE look terminal-first: phosphor noise, thin panel frames, and restrained prompts.
- Keep backgrounds mostly monochrome green; use cyan, amber, and red semantically.
- Avoid glossy cinematic sci-fi and modern neon dashboard styling.
- Display story images without figure borders so their black backgrounds blend into the terminal canvas.
- Revisit selected GenAI assets in a later visual-polish pass if their exported black levels reveal rectangular image edges.
- Treat selected story images and all phase-5 output slots as dominant visual stages; keep explanatory terminal text in compact side rails.

## Selected Figure Checklist

This is the list of figures currently needed for the kept presentation concept.
It includes the one R-generated figure that is being kept and the GenAI story assets that are being kept.

| Role | Asset | Source | Slide use | State |
| --- | --- | --- | --- | --- |
| Canonical R story figure | `figures/story/hidden_majority_particles.png` | Synthetic particles from `R/generate_story_figures.R` | Slide 13 implication / conceptual terminal panel | Implemented |
| GenAI story figure | `figures/story/genai_drafts/oracle_abstract_face_motif_v3.png` | Motif-only terminal portrait asset | Slide 01 ORACLE introduction | Selected and placed |
| GenAI story figure | `figures/story/genai_drafts/planet_abstract_scan_motif_v3.png` | Motif-only terminal planet asset | Slides 00 and 17 opening/final frame | Selected and placed |
| GenAI story figure | `figures/story/genai_drafts/vegetation_camera_moon_motif_v2.png` | Motif-only vegetation-camera asset | Story premise slide | Kept |
| GenAI story figure | `figures/story/genai_drafts/query_three_streams_motif_v1.png` | Motif-only conceptual stream asset | Query setup / Slide 02 | Draft for review |
| GenAI story figure | `figures/story/genai_drafts/query_three_streams_motif_v2.png` | Triptych source-object revision with climograph and network | Query setup / Slide 02 | Draft for review |
| GenAI story figure | `figures/story/genai_drafts/query_three_streams_motif_v3.png` | Triptych revision with nested map, climate glyphs, and dense network | Query setup / Slide 02 | Draft for review |
| GenAI story figure | `figures/story/genai_drafts/query_three_streams_motif_v4.png` | Triptych revision with color-coded modular association network | Query setup / Slide 02 | Superseded by v6 |
| GenAI story figure | `figures/story/genai_drafts/query_three_streams_motif_v5.png` | Partition-divider revision of selected triptych | Query setup / Slide 02 | Superseded by v6 |
| GenAI story figure | `figures/story/genai_drafts/query_three_streams_motif_v6.png` | Partitioned triptych with widened divider gutters | Query setup / Slide 02 | Selected and placed |
| GenAI story figure | `figures/story/genai_drafts/analysis_axes_triptych_motif_v1.png` | Motif-only conceptual axis asset | Analysis axes / Slide 04 | Superseded by v2 |
| GenAI story figure | `figures/story/genai_drafts/analysis_axes_triptych_motif_v2.png` | Color-separated 3D spatial, temporal signal, and phylogenetic triptych without dividers | Analysis axes / Slide 04 | Selected and placed |
| GenAI story figure | `figures/story/genai_drafts/oracle_closing_signal_motif_v1.png` | Motif-only closing signal asset | Closing terminal / Slide 14 | Superseded by v2 |
| GenAI story figure | `figures/story/genai_drafts/oracle_closing_signal_motif_v2.png` | Fading analysis remnants resolving into terminal cursor | Closing terminal / Slide 14 | Selected and placed |

## Script-Derived Figure Checklist

This is the full checklist extracted from `script.md`.
It shows the figure needs for the main talk and the optional extra slides that may be added later.

### Main Deck

#### GenAI Story Visuals (Main Deck)

- [x] Slide 00: opening planet in semi-shadow, atmospheric hero image. Kept asset: `figures/story/genai_drafts/planet_abstract_scan_motif_v3.png`
- [x] Slide 01: ORACLE terminal portrait or biosurveillance head. Kept asset: `figures/story/genai_drafts/oracle_abstract_face_motif_v3.png`
- [x] Slide 02: terminal query panel with climate, space, and association streams. Selected asset: `figures/story/genai_drafts/query_three_streams_motif_v6.png`
- [x] Slide 04: three-card overview of spatial, temporal, and taxonomic axes. Selected asset: `figures/story/genai_drafts/analysis_axes_triptych_motif_v2.png`
- [x] Slide 14: cinematic closing-terminal slide. Selected asset: `figures/story/genai_drafts/oracle_closing_signal_motif_v2.png`
- [x] Slide 17: final closing background. Reused asset: `figures/story/genai_drafts/planet_abstract_scan_motif_v3.png`

#### Schematics (genAI/mermaid/SCSS)

- [ ] Slide 03: VegVault data-ingestion schematic with modern vegetation, fossil pollen archives, palaeoclimate, and functional traits.
- [ ] Slide 06: model core diagram showing environment, space, association, and community response.
- [ ] Slide 07: variance-partition schematic with abiotic, spatial, association, and shared fractions.

#### R-Based / Output-Derived Visuals (Main Deck)

- [ ] Slide 03: northern-hemisphere globe / map highlighting North America, Europe, and Asia.
- [ ] Slide 16: QR code and final resource/DOI access panel for VegVault and the rendered deck.
- [ ] Slide 05: CHELSA climate-variable collinearity table or selection-status panel.

- [ ] Slide 08: spatial unit map layout for local, regional, and continental scales.
- [ ] Slide 08: spatial result tile plot showing association strength across the three scales.
- [ ] Slide 09: 3 x 3 spatial-by-taxonomic tile plot.
- [ ] Slide 10: temporal data-density plot across the last 20,000 years.
- [ ] Slide 10: bipartite network pipeline schematic for one time slice.
- [ ] Slide 10: temporal processing pipeline schematic across 500-year slices.
- [ ] Slide 11: temporal trajectory panel for North America.
- [ ] Slide 11: temporal trajectory panel for Europe.
- [ ] Slide 11: temporal trajectory panel for Asia.
- [ ] Slide 12: synthesis terminal panel summarising spatial, taxonomic, and temporal results.
- [ ] Slide 16: public-availability slide with licence text, URL, and QR code.

### Phase 4 Placeholder Contract

Phase 4 deliberately renders labelled placeholders for output-derived figures rather than showing simulated or unverified analytical evidence.
The following slots are visible in `index.qmd` and are assigned to phase 5 unless marked as final-delivery content.

| Slide | Placeholder content | Replacement phase |
| --- | --- | --- |
| 03 | Northern Hemisphere coverage map and data-ingestion schematic | Phase 5 |
| 05 | Climate screening and collinearity diagnostic | Phase 5 |
| 08 | Spatial-unit map and association tile plot | Phase 5 |
| 09 | Spatial-by-taxonomic result matrix | Phase 5 |
| 10 | Temporal density, network, and temporal-pipeline panels | Phase 5 |
| 11 | Regional temporal trajectories | Phase 5 |
| 12 | Verified synthesis statements | Phase 5 |
| 16 | Public URL, licence, QR code, and final resource/DOI access | Phase 8 |

Placeholders on slides 03 and 05-12 are laid out as large replacement stages rather than small cards, so verified figures can be inserted in phase 5 without shrinking analytical content.
The VegVault access/QR slot is consolidated on slide 16 rather than competing with the large slide-03 map field.
Slide 10 reserves one composite multipanel field for coverage, network, and repeated-slice diagnostics.

### Optional Extra Slides

#### GenAI Story Visuals (Optional Extra Slides)

- [ ] Slide 21: closing atmospheric archive-signal image.
- [ ] Conceptual graphic showing co-occurrence is not the same as shared response.

#### Schematics (Optional Extra Slides; genAI/mermaid/SCSS)

- [ ] Model architecture and assumptions.
- [ ] Example of drivers for one model.
- [ ] Limitation and future work.
- [ ] Alignment-gate diagram showing community, climate, and coordinates intersecting by dataset-age index.

#### R-Based / Output-Derived Visuals (Optional Extra Slides)

- [ ] Slide 18: guardrails for interpolation and uncertainty.
- [ ] Slide 19: synthesis panel for what ORACLE can say now.
- [ ] Functional-type classification ordination with highlighted taxa.
- [ ] Contemporary vegetation comparison including the taxonomic axis.
- [ ] Animated spatial patterns through time for one selected genus, family, and functional type.
- [ ] MEM explanation graphic showing spatial-structure capture.
- [ ] Continental map trio for America, Europe, and Asia.

## Canonical Figure

The canonical committed figure is the deterministic R-generated asset below.
It is the only R-generated story figure currently kept in the register.

| Asset | Type | Source | License | Generation method | State |
| --- | --- | --- | --- | --- | --- |
| `figures/story/hidden_majority_particles.png` | R-generated conceptual terminal panel | Synthetic particles from `R/generate_story_figures.R` | Repository MIT license | `ggplot2`, `theme_oracle()`, `ggview::save_ggplot()`; seed `900723` | Implemented |

## Kept GenAI Figures

These GenAI story assets are retained for the presentation as narrative or atmospheric visuals only.
They must not be reused as evidence from the vegetation co-occurrence pipelines.
The prompt IDs are recorded in `figures/story/genai_drafts/PROMPTS.md`.

| Asset | Intended use | Prompt ID | Prompt variant | State |
| --- | --- | --- | --- | --- |
| `figures/story/genai_drafts/oracle_abstract_face_motif_v3.png` | Slide-ready ORACLE portrait | Prompt 8 | Motif-only edit of `oracle_abstract_face_v2.png` with terminal decorations removed | Kept |
| `figures/story/genai_drafts/planet_abstract_scan_motif_v3.png` | Slide-ready atmospheric planet | Prompt 9 | Motif-only edit of `planet_abstract_scan_v2.png` with terminal decorations removed | Kept |
| `figures/story/genai_drafts/vegetation_camera_moon_motif_v2.png` | Slide-ready premise visual | Prompt 10 | Motif-only edit of `vegetation_camera_moon_v1.png` with terminal decorations removed | Kept |

## New GenAI Drafts For Review

The following text-free conceptual assets were generated for the outstanding main-deck story slots.
They are not pipeline results and should be accepted or replaced during slide review.

| Asset | Intended use | Prompt ID | Source and generation method | License/provenance note | State |
| --- | --- | --- | --- | --- | --- |
| `figures/story/genai_drafts/query_three_streams_motif_v1.png` | Slide 02 query visual | Prompt 11 | Built-in `image_gen` generation from recorded prompt | Generated asset; no external source material asserted | Draft for review |
| `figures/story/genai_drafts/query_three_streams_motif_v2.png` | Slide 02 triptych query visual revision | Prompt 14 | Built-in `image_gen` generation from recorded prompt | Generated asset; no external source material asserted | Draft for review |
| `figures/story/genai_drafts/query_three_streams_motif_v3.png` | Slide 02 nested-map, climate-cue, and dense-network revision | Prompt 15 | Built-in `image_gen` edit using project drafts as visual references | Generated asset; no external source material asserted | Draft for review |
| `figures/story/genai_drafts/query_three_streams_motif_v4.png` | Slide 02 modular, color-coded association-network revision | Prompt 16 | Built-in `image_gen` edit using project draft as visual reference | Generated asset; no external source material asserted | Superseded by v6 |
| `figures/story/genai_drafts/query_three_streams_motif_v5.png` | Slide 02 partition-divider revision | Prompt 17 | Built-in `image_gen` edit using selected project draft as visual reference | Generated asset; no external source material asserted | Superseded by v6 |
| `figures/story/genai_drafts/query_three_streams_motif_v6.png` | Slide 02 partitioned triptych with clear separator gutters | Prompt 18 | Built-in `image_gen` edit using project draft as visual reference | Generated asset; no external source material asserted | Selected |
| `figures/story/genai_drafts/query_three_streams_motif_v6_spatial_v1.png` | Standalone spatial query-stream panel, 350 x 700 cyan | Prompt 25 | Built-in `image_gen` edit using selected triptych as visual reference, then cropped/resized to `350 x 700 px` | Generated asset; no external source material asserted | Draft for review |
| `figures/story/genai_drafts/query_three_streams_motif_v6_abiotic_v1.png` | Standalone abiotic query-stream panel, 350 x 700 amber | Prompt 26 | Built-in `image_gen` edit using selected triptych as visual reference, then cropped/resized to `350 x 700 px` | Generated asset; no external source material asserted | Draft for review |
| `figures/story/genai_drafts/query_three_streams_motif_v6_latent_v1.png` | Standalone latent query-stream panel, 350 x 700 purple | Prompt 27 | Built-in `image_gen` edit using selected triptych as visual reference, then cropped/resized to `350 x 700 px` | Generated asset; no external source material asserted | Draft for review |
| `figures/story/genai_drafts/analysis_axes_triptych_motif_v1.png` | Slide 04 analysis axes visual | Prompt 12 | Built-in `image_gen` generation from recorded prompt | Generated asset; no external source material asserted | Superseded by v2 |
| `figures/story/genai_drafts/analysis_axes_triptych_motif_v2.png` | Slide 04 colored axes visual without separators | Prompt 20 | Built-in `image_gen` generation and separator-removal edit from recorded prompts | Generated asset; no external source material asserted | Selected |
| `figures/story/genai_drafts/analysis_axes_triptych_motif_v2_spatial_v1.png` | Standalone spatial analysis-axis panel, 480 x 400 cyan | Prompt 28 | Built-in `image_gen` edit using selected triptych crop as visual reference, then cropped/resized to `480 x 400 px` | Generated asset; no external source material asserted | Draft for review |
| `figures/story/genai_drafts/analysis_axes_triptych_motif_v2_temporal_v1.png` | Standalone temporal analysis-axis panel, 480 x 400 amber | Prompt 29 | Built-in `image_gen` edit using selected triptych crop as visual reference, then cropped/resized to `480 x 400 px` | Generated asset; no external source material asserted | Draft for review |
| `figures/story/genai_drafts/analysis_axes_triptych_motif_v2_taxonomic_v1.png` | Standalone taxonomic analysis-axis panel, 480 x 400 purple | Prompt 30 | Built-in `image_gen` edit using selected triptych crop as visual reference, then cropped/resized to `480 x 400 px` | Generated asset; no external source material asserted | Draft for review |
| `figures/story/genai_drafts/oracle_abstract_face_motif_v3_crop_v2.png` | Centered 800 x 700 ORACLE portrait crop revision | Prompt 24 | Built-in `image_gen` edit using selected project crop as visual reference, then cropped/resized to `800 x 700 px` | Generated asset; no external source material asserted | Draft for review |
| `figures/story/genai_drafts/oracle_closing_signal_motif_v1.png` | Slide 14 closing terminal visual | Prompt 13 | Built-in `image_gen` generation from recorded prompt | Generated asset; no external source material asserted | Superseded by v2 |
| `figures/story/genai_drafts/oracle_closing_signal_motif_v2.png` | Slide 14 terminal dissolution visual | Prompt 21 | Built-in `image_gen` generation from recorded prompt | Generated asset; no external source material asserted | Selected |
| `figures/story/genai_drafts/oracle_closing_signal_motif_v3.png` | Slide 14 ORACLE face shutdown-line visual, 1600 x 900 | Prompt 31 | Built-in `image_gen` generation using the approved ORACLE face crop as visual reference, then resized to `1600 x 900 px` | Generated asset; no external source material asserted | Draft for review |
| `figures/story/genai_drafts/planet_abstract_scan_motif_v4.png` | Portrait right-lit title/final planet motif revision | Prompt 22 | Built-in `image_gen` generation from recorded prompt, then cropped/resized to `530 x 700 px` | Generated asset; no external source material asserted | Draft for review |
| `figures/story/genai_drafts/planet_abstract_scan_motif_v5.png` | Portrait left-lit planet motif with expanded unlit body | Prompt 23 | Built-in `image_gen` generation from recorded prompt, then cropped/resized to `530 x 700 px` | Generated asset; no external source material asserted | Draft for review |

## Regeneration

Run the deterministic story asset generator from the repository root:

```powershell
Rscript Documentation/Presentations/IAVS_2026/R/generate_story_figures.R
```

Then render the presentation:

```powershell
Rscript -e "quarto::quarto_render('Documentation/Presentations/IAVS_2026')"
```
