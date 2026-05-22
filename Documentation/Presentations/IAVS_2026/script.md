# IAVS 2026 ORACLE Talk Script

This script defines the slide architecture for the 21-slide ORACLE RevealJS presentation. It is result-led in structure, but placeholder-heavy for claims until target stores and `.qs` outputs are verified.

Scientific through-line: co-occurrence signal appears NOT to be scale-dependent.

## Review Status

- Status: draft for user approval.
- Claim policy: no unverified numerical claims. Quantitative details remain pending target verification
- Visual policy: `[GENAI]` is used only for atmospheric or story-art slots, not for pipeline result figures.

## Timing Overview

//TODO

## slide 00

Visuals aready following the style but looks like serious academic presentation

There should a figure of be a large planet (semi in shadow) (see 01 in ChatGPT Image May 11, 2026, 09_43_25 AM; `[GENAI]`? or try to generate with R)

Ondra dialogue:

> I will ask the audience to close their eyes and imagine there are on a space ship and their goal is to examine the vegtation patterns of this Planet called "Earth". We will use of the spaceship computer called ORACLE to do so. All the data, analysis, and results are real. The computer is not real and only serves as a narrative device.

---

title of the talk
My name
Date

## Slide 01

Key bullets:

- Introduce the talk as a query session with ORACLE, the ecological biosurveillance system.
- Signal the 12-minute constraint: one question, one model system, one set of
  cautious result slots.

status: to-be-implemented

Archetype: `.oracle-title`

Ondra dialogue:

> Welcome fellow scientists, you may open your eyes! I am Ondřej Mottl, the chief researcher at this space station. We have 12 minutes to explore the vegetation patterns of a alian planet called 'Earth' using the ORACLE system. Let's get started. ORACLE, please boot up and introduce yourself.

---

Title: ORACLE: Observational Runtime for Analysis of Community-Level Ecology

ORACLE dialogue:

> System online.
> Greetings Dr. Mottl. I am  Observational Runtime for Analysis of Community-Level Ecology, ORACLE for short. I am here to assist you in analyzing vegetation patterns on Earth.
> Awaiting ecological query.
> Proceed? Y/N?

Figure slot: `[GENAI]` atmospheric ORACLE terminal or biosurveillance portrait (a female head)

Ondra dialogue:

> Yes

## Slide 02

Key bullets:

- Central question: How **biotic interactions** scale up to form and **maintain biodiversity patterns** at various spatial/temporal/taxonomic scales
- This is not a presence-only story; it is a partitioning problem.

status: to-be-implemented

Archetype: `.query-slide`

Ondra dialogue:

> Oracle, I would like like to explore vegation patterns across space and time of this planet. From our knowlege banks we know that vegetation is mostly explaineby climate and spatial factors. However, I am particullary interested in the unexplained variation. My first question is simple: Does the unexplained part of the community pattern change with scale, or does it stay broadly consistent?

---

Query: Is there a **scale dependence** in the amount of unexplained variation (potentially due to biotic interactions) structuring vegetation?

ORACLE dialogue:

> Query accepted. Plan to partition observed plant co-occurrence into climate response, spatial structure, and residual association.

Figure slot: terminal query panel using `.oracle-says`, `.terminal-grid`, and three stream panels: climate, space, association.

## Slide 03

Key bullets:

- VegVault supplies modern data, fossil pollen archives, functional traits, and co-located palaeoclimate data.

status: to-be-tested

Archetype: `.system-slide`

Ondra dialogue:

> Oracle, Load the VegVault database to get vegetation data, climate predictors, and functional traits for our analysis.

---

Title: Archive mounted: VegVault

ORACLE dialogue:

> VegVault database: publicly available, open source database.
> VegVault scan complete. Community records, climate predictors, site coordinates, and functional traits are loaded as separate streams.
> Due to the data availability, I will focus on Nothren Hemisphere of the Planet

Figure slot 1: a line graph of globe focusing on Northen gemisphere with highlighs of North America, Europe, Asia
Figure slot 2: data-ingestion schematic for Europe with three terminal panels:
`modern vegetation`, `fossil pollen archives`, palaeoclimate predictors, and Functional Traits.
Figure slot 3: QR code and DOI URL for VegVault

Ondra dialogue:

> VegVault is publicly available and you can access it using the QR or DOI.

## Slide 04

Key bullets:

- Temporal axis: one model per 500-year slice through the palaeo record.
- Spatial axis: one model per spatial unit.
- temporal axis : genus -> family -> Functional types
- The shared core keeps interpretation comparable across all axes.

status: to-be-implemented

Archetype: `.system-slide`

Ondra dialogue:

> Now, we would like to split the analysis along space, time, and taxonomic resolution.

---

Title: Three analysis axes: spatial, time, and taxonomic resolution

ORACLE dialogue:

> Route selected
> Spatial-resolution runs test scale and taxonomic aggregation level
> Temporal slices test change through time

Figure slot: three cards with scheme for spatial (map), temporal (line curve), and taxonomic (phylogenetic tree).

Ondra dialogue:

> This is done so we can test effect of each of these axes separately.

## Slide 05

Key bullets:

- Raw pollen counts are reshaped and linked to sample age.
- Counts become proportions, are interpolated, then restricted to Plantae.
- Taxa are resolved to the requested taxonomic or functional resolution.
- Rare and sparse taxa are filtered before model assembly.
- Palaeoclimate predictors are co-registered with pollen records.
- Pairwise collinearity is assessed before fitting.
- The model receives a reduced climate matrix rather than all raw predictors.

status: to-be-implemented

Archetype: `.system-slide`

Ondra dialogue:

> Oracle, we now need to apply data processing to community data and climate predictors to make them ready for analysis.

---

Title: Data and climate streams: preparation

ORACLE dialogue:

> Data extracted, now preparation ...
> Community stream normalised. Taxa are classified, filtered, and routed to the analysis resolution.
> Climate stream screened. Redundant predictors are removed before model fitting.

Figure slot 1: compact step ladder: raw community, proportions, classification, rare-taxon filtering, analysis subset.
Figure slot 2: terminal table of CHELSA variables and collinearity-filter status (the statuts can be represented as the amount of times the variable was selected as predictor).

Ondra dialogue:

> This includes reshaping, interpolation, taxonomic resolution, filtering, and climate predictor screening.

## Slide 06

Key bullets:

- sjSDM is used because the community matrix and spatial design are too large
  for slower MCMC workflows.
- Climate predictors enter as the environment component.
- Moran eigenvector maps represent spatial structure.
- Residual species covariance is treated as the candidate association signal.

status: to-be-implemented

Archetype: `.system-slide`

Ondra dialogue:

> Oracle, build a model, which would include climate, spatial structure, and whatever residual association remains.

---

Title: Model core: environment, space, association

ORACLE dialogue:

> Model assembled.
> Abiotic predictors explain shared response
> Moran Eigenvector Maps (MEMs) absorb spatio-temporal autocorrelation
> Residual covariance carries association signal.

Figure slot: model block diagram: environment component, spatial MEM component, biotic or association component, and binomial community response.

Ondra dialogue:

> We will be uisng {sjSDM} R package is used because the community matrix and spatial design are too large for slower MCMC workflows

## Slide 07

Key bullets:

- The ANOVA step partitions explained variation into abiotic, spatial, and residual association components.
- Shared fractions are useful diagnostics, but the talk focuses on the association component.
- Result slides must avoid over-interpreting residual covariance as direct species interaction.

Archetype: `.system-slide`

status: to-be-worked-on

Ondra dialogue:

> Now we would like to decompose the explained variance so we can separate climate, space, and residual association.

---

Title: Variance decomposition: A, S, and residual association

ORACLE dialogue:

> Decomposition ready.
> Report what remains after climate and spatial structure have made their claims.

Figure slot: variance partition schematic with abiotic, spatial, association, and shared fractions.

// note that the colors of the fractions should be consistent with the colors used in the final result slides, to avoid confusion.

Ondra dialogue:

> The shared fractions are useful diagnostics for understanding the model fit. However, we will focus on the non-shared residual association component.

## Slide 08

Key bullets:

- The spatial result stack compares local, regional, and continental units.
- The first results are shown for genus level
- There is not obvious chnage in between the spatial scale (surprising!).

Archetype: `.result-slide`

status: to-be-worked-on

Ondra dialogue:

> Oracle, start with the spatial axis. Show how the association signal changes across local, regional, and continental units.

---

Title: Spatial result setup: units, scales, and maps

ORACLE dialogue:

> Spatial scan configured. Units are nested from local to regional to continental.

Figure slot 1: spatial map layout showing the size of individual unit scales (eg North America as example).
Figure slot 2: tile plot showing 3 columns (scale), each tile (a unit) is colored by the the amount of association

Ondra dialogue:

> What do we see? Is there a clear change in the association signal across spatial scales? I would expect that local units have stronger association signal than continental units, but the pattern is not showing!

## Slide 09

Key bullets:

- We are adding the taxonomic axis to the story
- Genus, family, and functional-type models ask whether the signal depends on
  biological resolution.
- The assumtion is that this should change the course of the patetrns
- Each unit is also evaluated at genus, family, and functional-type resolution.
- Surprisingly, there is very little effect

status: to-be-implemented

Archetype: `.query-slide`

Ondra dialogue:
> Oracle, how does the spatial pattern change when we add taxonomic resolution? We assume that higher higher taxonomic resolution will result in smaller association signal in local units and vice versa.

---

Query: Is the change in taxonomic resolution affecting the spatial patterns?

ORACLE dialogue:

> Query accepted
> Adding taxonomic axis
> Ploting the results

Figure slot: Expland on the Figure 2 from previous slide. Now 3 columns (spatial scale) and 3 rows (taxonomic scale), each tile (a unit) is colored by the the amount of association

Ondra dialogue:

> Interestingly, the change in taxonomic resolution does not seem to affect the spatial patterns. This is surprising, as we would expect that higher taxonomic resolution would result in smaller association signal in local units and vice versa.

## Slide 10

key bullets:

- We can now ask if some of the patters are changing through time - masking the spatial patterns
- The temporal pipeline is configured analyse each  500-year slice through the last 20,000 years.
- This is a stress test for whether the association signal is stable through changing climates.
- This treats time as a sequence of comparable model snapshots.
- Each slice first estimates the community structure (bipartite network analyses)
- Finally fo each time slice, repeats alignment, model input assembly, fitting, ANOVA.

Archetype: `.query-slide`

status: to-be-worked-on

Ondra dialogue:

> Oracle, now let' switch to temporal mode and test whether the association signal stays stable through time.

---

Query: Is the association signal stable through time?

ORACLE dialogue:

> Query accepted
> Temporal mode selected. Slicing the data into 500-year windows
> Network diagnostics loaded. Co-occurrence structure can change even when variance components look similar.
> Each slice receives an independent analyses and diagnostics
> Plotting the results

Figure slot 1: Distribution of data across the temporal axis, showing where the data are dense or sparse.
Figure slot 2: schematic of bipartite network pipeline, highligting one time slice from figure 1.
Figure slot 3: schematic of temporal pipeline, showing how each slice is processed independently.

ORACLE dialogue:

> Proceed? Y/N?

Ondra dialogue:

> Now each time slice receives an independent analyses and diagnostics. We will be looking at the temporal trajectories of the association signal, but also at the network structure, which can change even when variance components look similar. Proceed ORACLE!

## Slide 11

Key bullets:

- Temporal analyses of network structure
- Temporal ANOVA summaries show how variance components change through the last 20,000 years.

Archetype: `.result-slide`

status: to-be-worked-on

---

Title: Temporal trajectories

ORACLE dialogue:

> Plotting temporal trajectories.

Figure slot 1: Animated gif of temporal changes of the network structure and the variance components (eg line plot of variance components through time, with the network structure changing in the background) for North America
Figure slot 2: Same as figure slot 1 but for Europe
Figure slot 3: Same as figure slot 1 but for Asia

// check `Outputs/Figures/Temporal_continents/plot_temporal_continents_scaled.pdf`

Ondra dialogue:

> The network structure and the variance components are changing through time, There is no clear pattern change during the LGM transition and during the strong anthropogenic changes during late Holocene. However, this is not consistent for all continents. Moreover, the association signal is not respoding in the same way as the network structure.

## Slide 12

Key bullets:

-

Archetype:

status: to-be-worked-on

---

Title: Synthesis

ORACLE dialogue:

> Weawing realities together: spatial patterns, taxonomic resolution, temporal dynamics.
> Consulting deeeper resoing matrices
> Summarizing results.

Bulletpoint-terminal:

- The residual association signal is detectable across all spatial scales, but does not show a clear decrease from local to continental units as expected.
- The change in taxonomic resolution does not seem to affect the spatial patterns, which is surprising
- The network structure and the variance components are changing through time, There is no clear pattern change during the LGM transition and during the strong anthropogenic changes during late Holocene. However, this is not consistent for all continents. Moreover, the association signal is not respoding in the same way as the network structure.

Ondra dialogue: (read the bullet points)

## Slide 13

//TODO:Implications

## Slide 14

//TODO: Cinamatic slide of closing the terminal

## Slide 15

//TODO: Slide about myself

## Slide 16

//TODO: Decide on the visuals

This presentation is publically available under XXX licence at the following URL: XXX + QR codes (render + code).

## Slide 17 (final)

//TODO: Final slide with name of talk, my name, date, and contact information (email, Twitter, etc). Background image could be the same as the first slide (the planet) but with a more hopeful or inspiring tone.

# Extra slides

## Slide XXX

Limitation and future work

## Slide XXX

Model architecture and assumptions

## Slide XXX

Example of drivers for one model

## Slide XXX

Example of FT classification (ordination with colored points, higligting some taxa)

- names for some dominant species
- "suggested" names for some of the functional types (eg "shade-tolerant trees", "open-ground herbs", etc)

## Slide XXX

Compare the spatial anaylysis with contemporary vegetation patterns (include the taxononic axis)

## Slide XXX

Animated gif of spatial patterns changing through time of a selected genus, family, and functional type.

## Slide XXX

Explanation of MEMs and how they capture spatial structure

## Slide XXX

Key bullets:

- Co-occurrence alone does not identify interaction.
- Shared abiotic response can create an association-like signal.
- Spatial autocorrelation can make nearby archives look more similar than independent samples.
- The model is designed to remove those alternative explanations before interpreting residual association.

Archetype: `.query-slide`

---

Title: Association is not the same as shared response

ORACLE dialogue:

> Warning: co-occurrence is ambiguous. Climate can synchronize taxa without direct interaction.

Figure slot: `[GENAI]` or R-generated conceptual network art showing two visually similar co-occurrence patterns, one driven by shared climate and one by residual association.

# Leftover slides (may be added)

## Slide XXX

Key bullets:

- The model only sees samples present across all required streams.
- Spatial pipelines keep all valid ages within each unit.
- Temporal pipelines restrict each branch to the target age slice.
- Alignment is where temporal and spatial workflows diverge operationally.

Archetype: `.system-slide`

---

Title: Alignment gate: only shared samples enter the model

ORACLE dialogue:

> Gate condition: community, climate, and coordinates must resolve to the same dataset-age index.

Figure slot: intersection diagram for community, abiotic, and coordinate
streams, ending in `dataset_name__age` identifiers.

## Slide XXX

Key bullets:

- Continental views give geographic context for the scale-dependent result.

Archetype: `.result-slide`

Title: Continental maps: where the signal thins out

ORACLE dialogue:

> Continental view is diagnostic, not final. Broad windows reveal where local structure is diluted or missing.

Figure slot: continent map trio for America, Europe, and Asia using existing spatial map outputs.

## Slide XX

Slide number: 18

Archetype: `.result-slide`

Title: Guardrails: interpolation and uncertainty

ORACLE dialogue:

> Chronology is not exact. Interpolation uncertainty is tracked before model
> interpretation is trusted.

Figure slot: `Outputs/Figures/Supplementary/interpolation_uncertainty_*`.

Key bullets:

- Fossil archives are not perfectly synchronized through time.
- Interpolation and age uncertainty affect which samples enter each analysis
  window.
- This slide protects the result story from sounding cleaner than the data are.

Confidence: medium. Output figures exist; exact final placement pending Phase 5.

Estimated speaking time: 0:30

Target/output mapping:
`Outputs/Figures/Supplementary/interpolation_uncertainty_comparison_all_taxa.png`,
`Outputs/Figures/Supplementary/interpolation_uncertainty_comparison_by_age.png`,
`data_age_uncertainty`.

## Slide XXX

Slide number: 19

Archetype: `.result-slide`

Title: What ORACLE can say now

ORACLE dialogue:

> Interim inference: association signal is detectable, scale-dependent, and
> requires verification before numerical reporting.

Figure slot: synthesis terminal panel with three rows: spatial scale,
taxonomic resolution, temporal dynamics.

Key bullets:

- Current result-led draft: local and regional spatial structure are the main
  narrative focus.
- Taxonomic resolution modifies the visibility of association signal.
- Temporal dynamics provide a stress test for whether the pattern persists
  through changing climates.
- All exact values remain pending target-store and `.qs` verification.

Confidence: medium-low. This is the planned synthesis, not a final result claim.

Estimated speaking time: 0:45

Target/output mapping: synthesis of `model_anova*`,
`data_anova_components_by_age_percentage`, `data_network_metrics_by_age`, and
`Outputs/Data/data_anova_results_*.qs`.

## Slide XXX

Slide number: 21

Archetype: `.oracle-title`

Title: Closing query: archive signal to ecological inference

ORACLE dialogue:

> Query remains active. The archive does not answer with certainty; it narrows
> the space of plausible ecological explanations.

Figure slot: `[GENAI]` closing atmospheric biosphere/archive terminal image,
potentially reused as final-slide background.

Key bullets:

- Close on the value of partitioning co-occurrence rather than simply mapping
  it.
- The ORACLE frame turns the final message into a controlled inference:
  climate, space, and residual association must all be interrogated.
- End with the next step: verified figures and a timed full slide deck.

Confidence: high for closing frame; no numerical claim made.

Estimated speaking time: 0:25

Target/output mapping: no pipeline target. Story-art dependency only.
