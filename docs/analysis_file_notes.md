# Analysis file notes: youth_analysis.rds

**Author:** Upendra Shahi
**Date:** 2026-07-15
**Produced by:** `R/04_build_analysis_file.R`
**Output:** `data/youth_analysis.rds` (microdata-derived, not in repo;
`data/` gitignored)
**Inputs:** S01 (roster), S07 (education), S02 (housing/facilities) —
see respective codebooks in `docs/`.

## Sample construction

| Step | Criterion | n |
|---|---|---|
| Roster-listed individuals (spine) | all rows, S01 | 46,870 |
| Age filter | 15 ≤ age ≤ 24 (`q01_03`, completed years) | — |
| Presence filter | member_cat == 1 (present members only) | — |
| **Analysis sample** | both filters | **6,950** |

Youth defined as **age 15–24** per this project's research question
(ILO-consistent definition).

Presence filter is required, not optional: absentees (member_cat 2/3)
were skipped in the S07 education module regardless of age and have no
outcome data. 29.0% of roster-listed youth (2,835 of 9,785) are thereby
excluded — see selection caveat below.

Sample count independently verified: 6,950 matches the roster-side
count obtained in `R/03_map_roster_vars.R` via a separate construction
path.

## Merge structure

Roster (S01) is the spine; joins verified in script:

| Join | Key | Type | Verification |
|---|---|---|---|
| S01 ← S07 (education) | psu_number + hh_number + idcode | 1:1 | nrow unchanged at 46,870 (no row explosion) |
| S01 ← S02 (internet) | psu_number + hh_number | many:1 | 0 NA on internet_hh (every person's household present in S02) |

## Constructed variables

| Variable | Construction | Notes |
|---|---|---|
| internet_hh | 1 if q02_31_c1 == 1, else 0 | source is 1/2 coded (1=YES, 2=NO) |
| female | 1 if q01_02 == 2, else 0 | source is 1/2 coded (1=Male, 2=Female) |
| age | q01_03 | completed years |
| ever_attended | 1 if q07_04 ∈ {2, 3}, else 0 | from routing variable |
| enrolled | 1 if q07_04 == 3, else 0 | from routing variable, NOT q07_11 |
| attain_raw | coalesce(q07_06, q07_12) | parallel track variables; identical code schemes (label-text difference at code 11 only — expected coalesce() warning, cosmetic) |
| attainment | 0 if never attended; NA if attain_raw ∈ {16, 17}; else attain_raw | see decisions below |

### Coding decisions

1. **Codes 16/17 (Literate levelless / Illiterate) → NA.**
   Frequency among all attendees: n = 14 (of 25,911). Immaterial;
   recoded NA rather than forcing into the level scale.
2. **attainment = 0 pools two groups:** never-attended (q07_04 == 1)
   and attendees whose highest completed level is pre-school (code 0;
   n = 1,448 among all attendees). Defensible for a completed-grades
   measure — both have zero completed grades. `ever_attended`
   distinguishes them where needed.
3. Carried-over covariates not yet recoded (q01_05 marital, q01_07
   caste/ethnicity, q01_12/q01_15 parental education) — value labels
   and universes to be documented before use.

## First descriptives (unweighted, analysis sample n = 6,950)

Internet access: 36.9% of present youth live in households with
internet (2,566 of 6,950).

| | No internet (n = 4,384) | Internet (n = 2,566) | Gap |
|---|---|---|---|
| Currently enrolled | 43.4% | 58.2% | +14.8 pp |
| Mean attainment (level code) | 8.36 | 10.1 | ~1.7 levels |

**No causal interpretation.** These are unweighted, unadjusted
descriptive differences. Internet households differ systematically in
wealth, urbanicity, parental education, and potentially the age
composition within 15–24 (enrollment declines steeply with age, so
compositional differences alone move the gap). Figures motivate the
adjusted, survey-weighted analysis; they do not anticipate its results.

## Selection caveat (for methods)

The analysis sample is necessarily PRESENT youth. Youth absence
(especially labor migration) is not random: it plausibly correlates
with sex, region, and household characteristics including those that
predict internet access. Planned robustness: compare present vs.
absent youth on roster observables (age, sex, parental education,
caste) — absentees have full roster demographics — to characterize
the selection. See `docs/codebook_roster_vars.md`.

## Pending / next steps

- [ ] Merge survey weights (`weight.dta`) and re-run descriptives
      weighted — required before any reported estimate
      (survey-weighted logit per proposal)
- [ ] Document and recode covariates (marital, caste/ethnicity,
      parental education)
- [ ] Present vs. absent youth comparison table (selection
      characterization)
- [ ] Examine `poverty.dta` (NSO consumption aggregate) as candidate
      household covariate
