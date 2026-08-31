# Trait review agent orchestration report

## Scope and outcome

The BIODYNAMICS raw trait-review automation pilot completed two valid independent agent reviews and one valid separate adjudication for every assigned agent batch. All 54 assigned candidates are covered exactly once in each accepted reviewer file and adjudication file. Agent outputs remain proposals only; this orchestration did not approve or apply any trait correction.

The discovered batches were `diaspore_mass_01` (19 candidates), `stem_specific_density_01` (25 candidates), and `stem_specific_density_02` (10 candidates). The 91 rows serialized with `agent_batch_id = NA` are missing batch assignments representing policy-acceptance candidates, not runnable agent batches, and were not included in the agent-review set.

## Existing work reused and invalid work preserved

Two pre-existing Diaspore mass reviews were fully validated and reused without modification: `diaspore_mass_01_reviewer_a_test_a_001.csv` and `diaspore_mass_01_reviewer_b_test_b_001.csv`.

The first `stem_specific_density_01` reviewer B submission, `stem_specific_density_01_reviewer_b_pilot_20260814T200527Z_b.csv`, was preserved unchanged but rejected from the accepted set because its serialized columns were shifted: rationale text populated `confidence` and `conflicts_or_uncertainty` was blank. A blind replacement with run ID `pilot_20260814T201532Z_b2` was created and validated. No invalid or incomplete output was overwritten.

## Completion and validation by batch

| Batch | Candidates | Reviewer A | Reviewer B | Adjudicator | Exact consensus | Adjudicated `insufficient_evidence` |
|---|---:|---|---|---|---:|---:|
| `diaspore_mass_01` | 19 | valid, reused | valid, reused | valid | 1 | 18 |
| `stem_specific_density_01` | 25 | valid | valid replacement | valid | 25 | 25 |
| `stem_specific_density_02` | 10 | valid | valid | valid | 10 | 10 |
| **Total** | **54** | **complete** | **complete** | **complete** | **36** | **53** |

Validation checked filename/batch/role/run identity, exact ordered schema, one-to-one batch coverage, absence of outside candidates, allowed recommendations, positive finite scale factors, atomic correction selectors, recomputed current matched-record counts, required evidence text, and absence of claims of human approval or production readiness. Adjudications were additionally checked against both accepted reviewer files field by field. All nine accepted outputs passed.

## Agents and runtime ledger

Eight agents were spawned in this orchestration. Every spawned reviewer and adjudicator used `gpt-5.6-terra` with high reasoning effort and was prohibited from spawning further agents. No more than two blind reviewers ran concurrently, and each adjudicator started only after both accepted reviews for its batch had validated.

| Batch | Role | Run ID | Model | Reasoning | Status | Validation | Elapsed seconds |
|---|---|---|---|---|---|---|---:|
| `diaspore_mass_01` | reviewer A | `test_a_001` | unavailable | unavailable | reused | valid | unavailable |
| `diaspore_mass_01` | reviewer B | `test_b_001` | unavailable | unavailable | reused | valid | unavailable |
| `stem_specific_density_02` | reviewer A | `pilot_20260814T195648Z_a` | `gpt-5.6-terra` | high | completed | valid | 261 |
| `stem_specific_density_02` | reviewer B | `pilot_20260814T195648Z_b` | `gpt-5.6-terra` | high | completed | valid | 485 |
| `stem_specific_density_01` | reviewer A | `pilot_20260814T200527Z_a` | `gpt-5.6-terra` | high | completed | valid | 589 |
| `stem_specific_density_01` | reviewer B | `pilot_20260814T200527Z_b` | `gpt-5.6-terra` | high | completed, excluded | invalid | 589 |
| `stem_specific_density_02` | adjudicator | `pilot_20260814T200527Z_adj` | `gpt-5.6-terra` | high | completed | valid | 589 |
| `stem_specific_density_01` | reviewer B replacement | `pilot_20260814T201532Z_b2` | `gpt-5.6-terra` | high | completed | valid | 368 |
| `diaspore_mass_01` | adjudicator | `pilot_20260814T201617Z_adj` | `gpt-5.6-terra` | high | completed | valid | 323 |
| `stem_specific_density_01` | adjudicator | `pilot_20260814T202200Z_adj` | `gpt-5.6-terra` | high | completed | valid | 362 |

Exact input, output, reasoning, and total token telemetry was not exposed by the runtime. The ledger therefore records `NA` for every token field and `usage_source = not_exposed`; no token counts were estimated.

## Recommendation and confidence counts

| Output set | `none` | `exclude` | `scale` | `insufficient_evidence` | Total rows |
|---|---:|---:|---:|---:|---:|
| Six accepted blind reviews | 4 | 3 | 5 | 96 | 108 |
| Three accepted adjudications | 1 | 0 | 0 | 53 | 54 |
| **Combined accepted outputs** | **5** | **3** | **5** | **149** | **162** |

| Output set | `agent_consensus` | high | medium | low | Total rows |
|---|---:|---:|---:|---:|---:|
| Six accepted blind reviews | 0 | 6 | 22 | 80 | 108 |
| Three accepted adjudications | 36 | 0 | 11 | 7 | 54 |
| **Combined accepted outputs** | **36** | **6** | **33** | **87** | **162** |

The invalid reviewer B submission is excluded from all scientific and aggregate counts.

## Reviewer agreement and adjudication

Strict action-and-every-selector agreement occurred for 36 of 54 candidates (66.7%); 18 of 54 candidates (33.3%) disagreed under the adjudication rule. Action alone agreed for 47 of 54 candidates (87.0%), but 11 Diaspore mass candidates shared the action `insufficient_evidence` while differing in selector scope and therefore correctly failed strict consensus. Seven Diaspore mass candidates differed in action or correction selector/factor. No adjudicated `exclude` or `scale` recommendation survived.

### Candidates receiving exact agent consensus

- `diaspore_mass_01`: Ambrosia artemisifolia (`c3a40ec04f6620229125ebedc4452dd8b8eec32ae8a0e2a7d74cd9510600a695`) received exact consensus on `none`; it currently matches zero records and remains only an agent proposal.
- `stem_specific_density_01`: Quercus ilex (`882b650269ae27ebf65e472317ab49a965e7c6cd522c8b4bbd90d2abcef75db8`); Fagus sylvatica (`04e42cc9c9ef231aa26c4d6c264b5467d1bbfad11a0f7077a5407d96436f0ff6`); Betula pendula (`8fc7e84e1beb36ac1a8a4b033f1974a5941034552f8606703a44c5117ed47aa1`); Quercus faginea (`69ee254030c9f14b3c40edde335768c46095fb2d86e24637b0524038362d96f7`); Salvia rosmarinus (`63a2858bcacf39765a072500fec5b768aa9246d988c49409a6e5e40c44954a0f`); Pistacia lentiscus (`4fb581a31aa4a894a0a902c7515e2a4079508f27eb98d34e6066e36a82898973`); Picea glauca (`98a14f5fa2441e92088bb2cfee58c209c36e8cf5ab26c7d7ce571ecabb9b0030`); Thymus vulgaris (`ab49e11435bf9b1af0452d808667222bc58347d55cd34b0d38a10645a3e3472a`); Pinus ponderosa (`8b5318dc539d90a76a31a9692784fd9e461d55ac43f2826f34fc60eae3129e46`); ARCTOSTAPHYLOS UVA-URSI (`caece8493dbff8bb31f0bc7100eb5e4b92b5dc9667b82a8cfac7f196932c71e0`); Pseudotsuga menziesii (`735aca1279e6a25ca1f71ca33f70270959940db5bc0e9ae20ed9f203995f86e6`); Fumana ericoides (`940f3291a12f489c4d1e96047e590742bf926b7e1adc1e2c4a0038c87a0c016c`); Helianthemum cinereum (`8180b859140050dc996f31c13e1d68a820c17039806be63c00e66b95b4765b13`); Genista scorpius (`9e0c974538744c992217319f179d7b08f4ed3b44155e24da11df42af1d1d6565`); Helichrysum italicum (`aeadec2147da858ebc640d0d1b7c43470211026ebb222e1511099c78a9d438f4`); Betula alleghaniensis (`c27de0ddeaa7340c4e0602ba3277c6db5ea0a8c3c19f1408d88107779c129088`); Rhamnus lycioides (`dfffddcae31539967717b5bfbb11f1128f6f6cf39507e7a3901506ccaba9315d`); Cistus albidus (`7e8f1edb11f53ef713aaa8fb5adbf8976798e0457c97855b00b29e1380dd0064`); Clinopodium obovatum (`81af6341e5d7978ee43d58a4de3b2414860a0b9235da73ec338fdc547a4cc13f`); VACCINIUM VITIS-IDAEA (`f306b97baf34dd09e9b0077033ab821f853cb622167cfb6825f4174d0c34483c`); Quercus alba (`4c5926f60d79b5e40f30dfc7849ea6a63e5d07e7f4b7d9b4ed1b451ba4a7944e`); Fumana laevipes (`18958c5d7248b3b0668849f50a71bb8aa075062d39d43ea3fab167d895ccaab4`); Teucrium capitatum (`09d4c1c00b55e43f427fda8d3b65ba77a300a816f0c73ec8e621cbf6a70cd0c2`); Quercus rubra (`0b188cc5571c6f8429173abc4b6876762671fb0683a064e2f44dded5e47e4561`); and Carya ovata (`ec2e6d0f3e46c86117fb9583a3a89aa6a4d1062d4f33018f80c7e0493b23d35b`) received exact consensus on `insufficient_evidence`.
- `stem_specific_density_02`: Helianthemum syriacum (`96db4702823b52425bb01a87dfa986cf9b32fe1019786911bf243cf039784fb2`); Betula lenta (`0edd55e98ff70bd1fb7ed5c5d6f515e59f32800ea27357dcbd2fa9321d3ebdf6`); Liriodendron tulipifera (`6e8b15a36c98cf5bb9b51d8659aafa12635164fd04615a0eadbbb7e6f9fcc148`); Hormathophylla lapeyrousiana (`bf40ff979cfad48fc4481bca33e36a42de27880303f961ee425080f65e6d67bf`); Atriplex sp (`f91c03d1885dfaa70d49c03f81a6d9709cd1086e63f60f912476e45a6488a833`); Bupleurum fruticescens (`04476eb389eabea6ca1cdb02bd732d6d645b093da16fef3c453781bf548d990b`); Genista sp (`423c8c46af538fefed2581897c11b4ae7f330973bf31a705e9cac117075a2808`); Phagnalon saxatile (`6a64ecd1f653a6b80b0e46ec900d175835943fd559acd6cbe2c833fb2fda5b1e`); Teucrium polium (`298235d7ce4a7b65db8d4ad931faa0d42e8f3181397e7cfd405762cec5c791b2`); and Thymus mastichina (`e0575548592a0f75604e6e0bac350c04d0f6134da0f17f91ba86851fcd1aebd7`) received exact consensus on `insufficient_evidence`.

### Candidates remaining `insufficient_evidence`

- `diaspore_mass_01` (18): Pinus pinaster (`3602d1f8f859bea6a7f26606735878481abd144feb389a7be369b29ed40c6754`); Helictotrichon pratense (`a9d720c1c4fb821c9861f2933835044586e7cb4c08b8fd9c1a5fd2d697b361c5`); Physospermum cornubiense (`45f0ee1224e1f0acbd4f26fc56695e94c7ac77e405c38a7f61c0381640ddf502`); Dryas octopetala (`eb3c46506b67c223aab83e80d61d8045701aa7ef76ac8065f896472ebc42e89d`); Myrtus communis (`91900ca595c627fc199c7c66877b5fe2e349880a5ec4d2a0352577ada132a1f7`); ARCTOSTAPHYLOS UVA-URSI (`7c99a752f9946eeca7b6fcfcd36261f71183d31519a6c963bafa4e5b1abbda6c`); VACCINIUM VITIS-IDAEA (`311d9b8cd9b6453bad2398d87074e9e2e03990e95abf35fdd973013ac9ecec30`); Daucus carota (`f3e193f2de5c0446e9e11050baf8c95da0be8627d3c26c4a39888e0e08a0b19c`); Calluna vulgaris (`c0e62c615ba94b09c81349b795853d15e319fc5d242576ac8cb85f8c5cf624b0`); Rhododendron ferrugineum (`8690b5f3f486f1ec1a58196ff4e0918b61c64bc949d9d5746e45f563046eb48e`); Eremogone congesta (`2c97b7c0491c480cb3ab9dbdcb34d2f022f5d6599427576db926ae37a285ac3a`); Chrysopsis villosa (`4367600f4d2dcb01cf454e3ec25579c5e0df4e3de8af0ae62c5edbb838aefaaa`); Quercus ilex (`14ca88e069bea7542b7196056044376ff8974e97eddb9efd3366c0548654e441`); Quercus suber (`66f4d476277f778be7a05787baa5c8b245a8f4e08ad7615ffe68dfb225daf6bd`); Phyllodoce caerulea (`eda003dd928ecddded98d69696a3ca1983621d677dc10e35db7fef35d7821881`); Festuca ovina (`3f3f513936908a451bb4a68e7f4afa069cf07ff03afa5135196c14c98c4fc256`); Rhamnus alaternus (`ab309ab8a4366eda0f01ac5d2ff0de75e71e1d8e369f44d38aa734e27029331a`); and Cymopterus lemmonii (`9ef0d018cfafb07cc5ff94065e8cab3b561ace9a25194e16b6788e808ad6155e`).
- `stem_specific_density_01` (25): all 25 exact-consensus candidates listed above remain `insufficient_evidence`.
- `stem_specific_density_02` (10): all 10 exact-consensus candidates listed above remain `insufficient_evidence`.

## Recovered-selector and unit-pattern findings

The pilot contained 12 recovered selector rules, all of which still matched current records: seven Diaspore mass rules selecting 12 records and five Stem specific density rules selecting 1,127 records. A current match demonstrates selector recovery only; it does not establish that exclusion or scaling is scientifically correct. No recovered selector became an adjudicated correction.

Seven candidates were flagged for possible unit patterns: Physospermum cornubiense in `diaspore_mass_01`; ARCTOSTAPHYLOS UVA-URSI, Rhamnus lycioides, Quercus rubra, and Carya ovata in `stem_specific_density_01`; and Helianthemum syriacum and Betula lenta in `stem_specific_density_02`. Reviewers found the apparent factors to be hypotheses lacking source-specific unit or measurement documentation. Every one of these candidates remains `insufficient_evidence`.

The reviews consistently retained plausible uncertain values while keeping them flagged. Extreme observations, family or growth-form expectations, historical selector recovery, and cross-dataset ratios were not treated as sufficient evidence for a whole-group correction.

## Output paths

Durably archived accepted reviewer and adjudicator outputs:

- `Outputs/Reports/Trait_corrections/raw/review_evidence/pilot/accepted/diaspore_mass_01_reviewer_a_test_a_001.csv`
- `Outputs/Reports/Trait_corrections/raw/review_evidence/pilot/accepted/diaspore_mass_01_reviewer_b_test_b_001.csv`
- `Outputs/Reports/Trait_corrections/raw/review_evidence/pilot/accepted/diaspore_mass_01_adjudicator_pilot_20260814T201617Z_adj.csv`
- `Outputs/Reports/Trait_corrections/raw/review_evidence/pilot/accepted/stem_specific_density_01_reviewer_a_pilot_20260814T200527Z_a.csv`
- `Outputs/Reports/Trait_corrections/raw/review_evidence/pilot/accepted/stem_specific_density_01_reviewer_b_pilot_20260814T201532Z_b2.csv`
- `Outputs/Reports/Trait_corrections/raw/review_evidence/pilot/accepted/stem_specific_density_01_adjudicator_pilot_20260814T202200Z_adj.csv`
- `Outputs/Reports/Trait_corrections/raw/review_evidence/pilot/accepted/stem_specific_density_02_reviewer_a_pilot_20260814T195648Z_a.csv`
- `Outputs/Reports/Trait_corrections/raw/review_evidence/pilot/accepted/stem_specific_density_02_reviewer_b_pilot_20260814T195648Z_b.csv`
- `Outputs/Reports/Trait_corrections/raw/review_evidence/pilot/accepted/stem_specific_density_02_adjudicator_pilot_20260814T200527Z_adj.csv`

Preserved invalid output:

- `Outputs/Reports/Trait_corrections/raw/review_evidence/pilot/rejected/stem_specific_density_01_reviewer_b_pilot_20260814T200527Z_b.csv`

Orchestration records:

- `Outputs/Reports/Trait_corrections/raw/review_evidence/pilot/orchestration_ledger.csv`
- `Outputs/Reports/Trait_corrections/raw/trait_review_agent_orchestration_report.md`

## Integrity confirmation

During agent orchestration, no canonical decision file, immutable review submission, trait record, pipeline target, Git index entry, commit, or remote branch was changed. The canonical raw and classified decision files retained their starting SHA-256 value `ACE776A0803968A2AB6ADDDD83451262BB9ED4472E8A1C70E5D3DCC61DD7387B`. The orchestration started from commit `26a57de065c6b7e3a8cc4267c6b7f916a5e10a26`, and no existing reviewer or adjudicator submission was overwritten. The files listed above are subsequent byte-identical archival copies of that evidence.
