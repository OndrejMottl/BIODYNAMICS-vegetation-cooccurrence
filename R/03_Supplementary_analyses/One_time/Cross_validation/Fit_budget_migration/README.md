# Historical CV fit-budget migration

This one-time workflow audits models created before CV and final-model fitting budgets were separated. It is not part of a clean reproduction.

After stage 02 calibration has published accepted budgets, run `audit_completed_sjsdm_continental_results.R`. Then run `build_sjsdm_cv_invalidation_manifest.R` without `SJSMD_APPLY_CV_INVALIDATION` and review the dry-run manifest. Set `SJSMD_APPLY_CV_INVALIDATION=true` only when intentionally applying the reviewed target invalidations. Prepared folds and archived stores are excluded.

Stage 03 model fitting should be started only after this migration has been resolved for stores containing legacy artifacts.
