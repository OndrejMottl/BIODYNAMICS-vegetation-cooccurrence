# Issue #156 — Comprehensive persisted contract migration

## Summary

Use the planned full pipeline rebuild to perform a one-time breaking migration
of unclear non-CV target names, owned result schemas, and generated artifact
filenames. Work from `OndrejMottl/issue156` at merged PR #164 and deliver one
PR with ordered, domain-based commits.

- Do not provide legacy aliases or dual schemas.
- Preserve Issue #141's public CV targets, schemas, profile IDs, and store
  paths. Its readers may be updated when they consume renamed full-data
  targets.
- Leave final blocking enforcement to Issue #157.
- Treat a clean rebuild as the supported migration path; do not delete or
  prune existing stores or generated artifacts automatically.

## Contract changes

Apply each base-target rename to every generated resolution, continent, age,
and `tar_map()` suffix.

### Shared and modelling targets

- `check_n_cores` -> `flag_available_core_count_validated`
- `check_taxa_classification` -> `flag_taxa_classification_validated`
- `abiotic_collinearity` -> `list_abiotic_collinearity`
- `model_formula` -> `formula_jsdm_environment`
- `model_jsdm` -> `mod_jsdm`
- `model_jsdm_standard_errors` -> `mod_jsdm_with_standard_errors`
- `model_jsdm_selected` -> `mod_jsdm_selected`
- `model_evaluation_fitted` -> `list_jsdm_evaluation_fitted`
- `model_anova` -> `list_jsdm_variance_partition`

Keep the Issue #141-owned `model_regularization_for_fit` and
`model_evaluation_cross_validated` contracts unchanged.

### Functional-type targets

- `ft_groups_max_continental` ->
  `config_functional_type_group_count_max_continental`
- `ft_groups_min_continental` ->
  `config_functional_type_group_count_min_continental`
- `metric_ft_continental` ->
  `config_functional_type_distance_metric_continental`
- `method_ft_continental` ->
  `config_functional_type_clustering_method_continental`
- `check_ft_reference_classification_paleo` ->
  `data_functional_type_reference_validation_paleo`
- `data_traits_for_ft` ->
  `data_traits_for_functional_type_classification`
- `data_classification_table_for_ft` ->
  `data_classification_table_for_functional_types`
- `dist_ft_continental` ->
  `data_functional_type_dissimilarity_continental`
- `hclust_ft_continental` ->
  `mod_functional_type_hierarchical_clustering_continental`
- `ft_groups_chosen_continental` ->
  `n_functional_type_groups_selected_continental`
- `ft_result_continental_unit` ->
  `data_functional_type_classification_continental`
- `file_ft_classification_paleo` ->
  `file_functional_type_classification_paleo`
- `file_ft_classification_modern` ->
  `file_functional_type_classification_modern`

Standardise the currently inactive trait-clustering target definitions too:

- `ft_groups_max_clustering` ->
  `config_functional_type_group_count_max_clustering`
- `ft_groups_min_clustering` ->
  `config_functional_type_group_count_min_clustering`
- `metric_ft_clustering` ->
  `config_functional_type_distance_metric_clustering`
- `method_ft_clustering` -> `config_functional_type_clustering_method`
- `dist_continent` -> `data_functional_type_dissimilarity_continent`
- `hclust_continent` ->
  `mod_functional_type_hierarchical_clustering_continent`
- `ft_groups_chosen_continent` ->
  `n_functional_type_groups_selected_continent`
- `ft_result_continent` -> `data_functional_type_classification_continent`

### Trait targets

- `trait_qc_report` -> `list_trait_quality_control_report`
- `trait_corrections_validated` -> `data_trait_corrections_validated`
- `check_trait_taxa_classification` ->
  `flag_trait_taxa_classification_validated`
- `trait_qc_report_classified` ->
  `list_trait_quality_control_report_classified`
- `trait_corrections_classified_validated` ->
  `data_trait_corrections_classified_validated`

### Owned result schemas

Change `evaluate_jsdm()` to return:

- `model` -> `vec_model_metrics`
- `species` -> `data_taxon_metrics`
- `convergence` -> `list_convergence_diagnostics`
- `R2-McFadden` -> `r2_mcfadden`
- `R2-Nagelkerke` -> `r2_nagelkerke`
- `species` -> `taxon_name`
- `AUC` -> `auc`
- `Accuracy` -> `accuracy`
- `LogLoss` -> `log_loss`
- `RMSE` -> `rmse`

Change `write_trait_quality_control_report()` to return:

- `summary_by_domain` -> `data_summary_by_domain`
- `summary_by_domain_taxon` -> `data_summary_by_domain_taxon`
- `suspected_outlier_taxa_domain` ->
  `vec_suspected_outlier_taxa_domain`
- `suspected_outlier_taxa_taxon` ->
  `vec_suspected_outlier_taxa_taxon`

Standardise its summary columns:

- `lwr_90` -> `quantile_05`
- `upr_90` -> `quantile_95`
- `IQR` -> `iqr`
- taxon-summary `n_suspected_outliers_taxon` ->
  `n_suspected_outliers`

Preserve shared and third-party schemas, including `collinear_output`,
`sjSDM`, `sjSDManova`, and the nested `diagnose_jsdm_convergence()` contract
used by CV work.

### Generated artifacts

- `data_ft_classification_*` -> `data_functional_type_classification_*`
- `trait_qc_report_*` -> `trait_quality_control_report_*`

Update save, resolve, load, report-rendering, diagnostic, presentation, and
test consumers. Old files remain untouched but are no longer selected by
active readers.

Preserve config keys such as `ft_groups_max`, the `ft_modern` resolution
identifier, all profile IDs, and all target-store paths.

## Implementation and delivery

1. Create a manifest-derived, append-only inventory covering every configured
   pipeline/profile, nested pipe target, result schema, artifact filename,
   consumer, and owner issue.
2. Write failing contract tests for the complete rename maps and new schemas
   before changing producers.
3. Migrate shared/model targets and `evaluate_jsdm()` with all readers.
4. Migrate functional-type targets, files, resolvers, and active consumers.
5. Migrate trait targets, list schemas, report columns, filenames, and review
   tooling.
6. Regenerate function documentation, architecture inventories, and the
   migration report.

Use five durable commits:

1. `Persisted contracts: inventory target and artifact schemas`
2. `Model pipelines: standardise persisted targets and evaluation results`
3. `Functional types: expand persisted target and artifact names`
4. `Trait quality control: standardise targets and report schemas`
5. `Persisted contracts: document clean rebuild migration`

## Test and acceptance plan

- Verify manifests differ only by approved mappings and dynamic suffixes;
  target counts and graph topology remain unchanged.
- Compare old and new outputs after translating schema names: numerical values,
  classes, dimensions, row order, scientific content, functional-type
  assignments, and fitted-model results remain identical.
- Preserve Issue #141's public targets, fields, status vocabulary, profiles,
  and stores exactly.
- Test new artifact discovery in directories containing legacy and new files;
  active readers select only the new convention.
- Run focused tests, affected diagnostics and visualisations, the Czech smoke
  suite, the frozen trait-reference workflow, and the complete test suite.
- Parse changed R files, regenerate documentation and inventories, run
  `git diff --check`, and complete mandatory change review.
- Full production pipelines are rebuilt after merge; PR checks may use small
  isolated stores.

Acceptance requires no legacy names in active code except migration fixtures,
historical records, frozen Issue #141 contracts, and preserved config/domain
identifiers.
