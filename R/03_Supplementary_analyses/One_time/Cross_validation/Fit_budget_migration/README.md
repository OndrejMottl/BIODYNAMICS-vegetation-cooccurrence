# Historical CV fit-budget migration

This one-time workflow audits models created before CV and final-model fitting budgets were separated. It is not part of a clean reproduction.

After stage 02 calibration has published accepted budgets, run `audit_completed_sjsdm_continental_results.R`. Then run `build_sjsdm_cv_invalidation_manifest.R` without `SJSMD_APPLY_CV_INVALIDATION` and review the dry-run manifest. Set `SJSMD_APPLY_CV_INVALIDATION=true` only when intentionally applying the reviewed target invalidations. Prepared folds and archived stores are excluded.

Stage 03 model fitting should be started only after this migration has been resolved for stores containing legacy artifacts.

## October 2026 operational-memory recovery

`run_sjsdm_cv_operational_evidence_migration.R` is an evidence-only one-time migration for modern continental Europe functional types. Run it with `Rscript` in a fresh process. It verifies preparation freshness, reconstructs all original folds using tracked pre–October 6 MEM code, requires exact original-signature and complete analytical-equivalence proof, archives the original evidence, and migrates to version five. It does not fit models, publish budgets, or bypass the incompatible paleo evidence.

`run_bounded_sjsdm_cv_recalibration.R` is the separately approved timing diagnostic for paleo regional `eu_r005` functional types. It stops after ladder rung two, retaining the complete ladder signature and scientific acceptance gates. Its isolated directory is `Data/Temp/Sjsdm_cv_calibration_bounded/20261013/`; at most 48 screening and 20 confirmation fits can be requested. Outputs under `Documentation/Reports/Model_calibration/calibration_safeguards_2026-10-13/` are review evidence, not automatic production publication. Further rungs, recalibration of the other representatives, and a modern restart require approval.

These scripts are not additional numbered replication stages and are deliberately not called by the Stage 02 master. The normal five-stage replication sequence is unchanged.
