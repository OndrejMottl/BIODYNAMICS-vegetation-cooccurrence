# Cross-validation reference runs

## Purpose and backstory

These runners preserve frozen cross-validation reference configurations from
issues #138, #139, and #141. They support regression testing, scientific
comparison, and performance investigations while the shared cross-validation
implementation is refactored.

They were moved from `R/02_Main_analyses` by issue #152 because reference runs
validate analytical contracts but are not part of the supported production
analysis sequence.

## Usage

Select the corresponding configuration profile documented in
`Configuration/Profiles/References/cross_validation.yml`, then run only the
matching script. The runners are independent reference entry points; their
filename order does not define a pipeline sequence.

Outputs use isolated target stores recorded in the configuration profile
catalog. Do not replace those stores with production outputs.
