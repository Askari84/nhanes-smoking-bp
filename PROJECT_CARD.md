# PROJECT CARD — Phase 1

## 1. Dataset and Subset
- **Dataset:** NHANES August 2021–August 2023
- **Files used:**
  - `DEMO_L.xpt` (demographics and sample weights)
  - `BPXO_L.xpt` (oscillometric blood pressure measurements)
  - `SMQ_L.xpt` (smoking – cigarette use questionnaire)
- **Merge key:** `SEQN`
- **Analytic subset:** Adults aged 20 years and older with valid MEC exam weight (`WTMEC2YR > 0`) and non-missing smoking status.

## 2. Working Title
**"Association between current cigarette smoking and elevated blood pressure in U.S. adults: NHANES 2021–2023"**

## 3. Main Statistical Question
In U.S. adults aged 20 years and older (NHANES 2021–2023), is the proportion of individuals with elevated blood pressure (systolic ≥ 130 mmHg or diastolic ≥ 80 mmHg) different between current cigarette smokers and non-smokers?

## 4. Observation Unit and Target Population
- **Observation unit:** One individual (each row = one participant, identified by `SEQN`).
- **Target population:** Non-institutionalized U.S. adults aged 20+ years.
- **Independence assumption:** One observation per participant; no repeated measures in this phase.

## 5. Key Variables and Measurement Scale

| Role | Variable | Source | Type | Scale |
|---|---|---|---|---|
| Outcome | Elevated blood pressure (`BP_HIGH`) | `BPXO_L` | Binary | Nominal (0/1) |
| Exposure | Current smoker (`SMOKER`) | `SMQ_L` | Binary | Nominal (0/1) |
| Weight | MEC exam weight (`WTMEC2YR`) | `DEMO_L` | Continuous | Ratio |
| Covariate (descriptive) | Age (`RIDAGEYR`) | `DEMO_L` | Continuous | Ratio |
| Covariate (descriptive) | Sex (`RIAGENDR`) | `DEMO_L` | Binary | Nominal |

### Operational definitions:
- **`BP_HIGH = 1`** if mean systolic BP (average of `BPXOSY1`, `BPXOSY2`, `BPXOSY3`) ≥ 130 **OR** mean diastolic BP (average of `BPXODI1`, `BPXODI2`, `BPXODI3`) ≥ 80; otherwise 0.
- **`SMOKER = 1`** if `SMQ040` = 1 (every day) or 2 (some days); **0** if `SMQ040` = 3 (not at all) or `SMQ020` = 2 (never smoked 100 cigarettes).

## 6. Variable Roles
- **Response:** `BP_HIGH` (elevated blood pressure)
- **Explanatory:** `SMOKER` (current smoking status)
- **Grouping/descriptive:** Age group, sex

## 7. Question Type
**Comparative** (comparison of a proportion between two groups). Phase 1 remains purely descriptive; no inferential claims.

## 8. Initial Hypothesis (for later phases)
The proportion of individuals with elevated blood pressure is higher among current cigarette smokers than among non-smokers.

## 9. Phase 1 Special Requirements (Path A) — Checklist
- [ ] **A1:** Introduce files and merge key; report N before and after merge.
- [ ] **A2:** Identify sample weights; explain why each individual represents a different number of population members.
- [ ] **A3:** Compare crude vs. weighted proportion for at least one estimate.
- [ ] **A4:** Define analytic population (age ≥ 20, valid `WTMEC2YR`, non-missing `BP_HIGH` and `SMOKER`); report exclusions at each step.

## 10. Reproducibility Notes
- All data files downloaded from CDC NHANES official page (see `data/README.md`).
- Analysis code: `src/phase1_analysis.R`
- Environment: R with `haven`, `dplyr`, `survey`, `ggplot2`.
