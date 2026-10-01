# CSPE 2026 results provenance

## Conference snapshot

The CSPE 2026 presentation displays a frozen copy of the result artifacts used by the IAVS 2026 presentation. The PNG, GIF, and poster files under `figures/results/` are copied byte-for-byte, and their SHA-256 values are recorded in `results_asset_manifest.csv`.

The result-generation, GIF-poster, QR-generation, and appendix-generation chunks are explicitly disabled in `index.qmd`. The active render reads the copied assets and `results_snapshot.json`; it does not read a `{targets}` store, query VegVault, download climate data, or run a result visualisation script.

The HTML deck displays the copied animated GIFs. PDF rendering uses the copied poster PNGs through the existing `?pdf-static=true` presentation behavior.

## Why the results are frozen

The project is being rerun with added cross-validation and corrected trait data, but the updated model fits will not be complete before the CSPE presentation on 9 September 2026. Freezing the previously presented artifacts keeps the conference deck internally consistent and prevents an incomplete rerun from mixing old and new estimates.

The first result slide and the synthesis slide disclose that the displayed results are the frozen 31 August 2026 pre-rerun snapshot and that the updated rerun remains in progress.

## Archived targets

The spatial archive is recorded in `results_snapshot.json` as `D:/GITHUB/BIODYNAMICS_vegetation_cooccurrence/Data/targets/_archive/2026-08-31_pre_trait_cv_rerun`.

That archive contains the modern and palaeo spatial stores at continental, regional, and local scales. It does not contain the trait-reference store or the three palaeo-temporal stores required by the complete presentation. The archive path is therefore provenance for the spatial results only and is intentionally not dereferenced by the frozen render.

## Future result update

1. Finish and validate the cross-validation and corrected-trait rerun.
2. Assemble one immutable snapshot containing every spatial, temporal, trait-reference, and prediction dependency used by the deck.
3. Replace the frozen-results contract with an explicit complete-snapshot configuration and update the presentation-local store resolvers.
4. Re-enable result-generation chunks one group at a time and regenerate PNG, GIF, poster, and appendix assets.
5. Recompute synthesis counts from the complete snapshot and review every result claim against the regenerated figures.
6. Replace `results_asset_manifest.csv`, rerender HTML and PDF, and complete scientific and visual review before removing the frozen-results disclosure.