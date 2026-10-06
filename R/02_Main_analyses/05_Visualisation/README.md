# Stage 05: visualisation

Run `01_run_visualisation.R` after stage 04. It runs seven components that rebuild eight journal-neutral manuscript figures in component order and does not launch model fitting or synthesis.

The seven components write eight canonical figures in vector PDF, 600-dpi TIFF, and 300-dpi review PNG formats. Component 03 writes only the paleo predictor-inclusive figure because its overlapping domains must not be stacked and its association panel would duplicate the same values. Component 04 retains the existing modern compositional figure plus a companion predictor-inclusive figure; every other component writes one figure. Physical dimensions are derived from the shared graphical canvas in the generated configuration, so the existing 2000 by 1600 pixel canvas becomes a fixed 6.67 by 5.33 inch manuscript figure. The TIFF uses twice the configured review resolution without changing the physical dimensions. The exact plot-ready tables are written to `Outputs/Tables/Visualisation/` so figure values can be audited without opening target stores.

| Component | Scientific content | Primary synthesis inputs | Canonical figure base |
| --- | --- | --- | --- |
| 01 | Nine-panel paleo association atlas; each spatial unit contains ordered genus, family, and functional-type glyphs with explicit unavailable-model status | Paleo spatial unit table, spatial-grid geometry, calibration preparation inventory | `paleo_spatial_association_atlas_<date>` |
| 02 | Paleo unit-level association distributions, medians, interquartile ranges, and eligible counts | Paleo spatial unit table | `paleo_spatial_association_summary_<date>` |
| 03 | Paleo predictor-inclusive domain contributions shown separately because shared fractions overlap | Paleo spatial unit table | `paleo_variance_partitioning_predictor_inclusive_<date>` |
| 04 | Modern normalized variance composition and association spread, plus the same companion predictor-inclusive domain figure | Modern spatial unit table | `modern_variance_partitioning_<date>`; `modern_variance_partitioning_predictor_inclusive_<date>` |
| 05 | Matched paleo-modern pairs and modern-minus-paleo differences with exclusion counts | Matched comparison unit and coverage tables | `paleo_modern_matched_comparison_<date>` |
| 06 | Europe functional-type NMDS and paired functional-type model comparison | Functional-type ordination and matched comparison tables | `functional_type_comparison_<date>` |
| 07 | Static continental predictor-inclusive domain trajectories, modularity, and sample-density support | Paleo temporal result and density tables | `paleo_temporal_trajectories_predictor_inclusive_<date>` |

The figure scripts use a shared white-background manuscript theme, semantic colour mappings, panel tags, and export function from `R/Functions/Visualisation/Manuscript/`. The presentation-only terminal font, black background, glow, title cards, and explanatory slogans are intentionally excluded.

## Data and scale contract

- Spatial association panels use only the `Associations` component. Unit values remain on the original 0–100 percentage scale; group summaries show medians and empirical intervals, never a fitted replacement for missing units.
- The atlas uses nine continent-by-tier maps rather than 27 separate resolution maps. Within each spatial unit, circle, square, and triangle glyphs show genus, family, and functional type respectively; hollow grey marks indicate expected infeasibility and crossed hollow marks indicate missing models.
- The retained modern compositional panel normalizes displayed abiotic, spatial, biotic, and unexplained components to 100 percent within each available unit.
- Predictor-inclusive variance panels count each shared fraction in full for Climate, Biotic co-occurrence, and Spatial. The domains overlap by design, are never stacked or renormalized across domains, and need not sum to 100 percent.
- Matched paleo-modern panels retain finite pairs joined by tier, unit, resolution, and component. The difference is modern minus paleo; excluded paleo-only and modern-only counts come from the stage 04 coverage table.
- Functional-type ordination uses the cached Europe continental trait dissimilarity, excludes singleton functional types, and runs two-dimensional NMDS with seed 900723. Only the four largest groups are labelled.
- Temporal plots show predictor-inclusive genus-domain contributions from the temporal pipeline. Shared fractions contribute in full to every relevant domain, so the three trajectories need not sum to 100 percent. Age is reversed, time slices are not interpolated, and missing fitted results remain gaps. The density strip records both sampling support and model availability.

Unavailable-model semantics are explicit. `available` means a finite model result exists, `expected_infeasible` means preparation or full-model feasibility established that the model could not be fitted, `unexpected_error` preserves a non-classified legacy or current model error for review, and `missing_model` means a model was expected but is absent. These states must never be recoded to zero.

Figures are written below `Outputs/Figures/Spatial/` or `Outputs/Figures/Temporal_continents/`. Their exact input rows and summaries are written below `Outputs/Tables/Visualisation/`.
