# Issue 138 staged validation runners

## Purpose and backstory

These one-time runners reproduce the representative staged benchmarks created
for issue #138. They remain available because issue #141 uses the results to
check cross-validation behaviour and computational performance.

They were moved from `R/02_Main_analyses` by issue #152. They are historical
validation evidence, not production analyses.

## Usage

Each script activates its matching frozen profile from
`Configuration/Profiles/One_time/Issues/issue_138.yml`. Run only the
continent and data domain required by the validation question.

The profiles write to isolated stores under
`Data/targets/issue138_validation`. Preserve those stores as benchmark
evidence and do not treat them as current production results.
