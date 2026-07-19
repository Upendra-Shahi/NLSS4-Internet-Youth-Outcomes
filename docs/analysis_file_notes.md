# Analysis file notes: youth_analysis.rds

**Author:** Upendra Shahi
**Date:** 2026-07-15
**Produced by:** `R/04_build_analysis_file.R` + `R/05_add_weights.R`
**Output:** `data/youth_analysis.rds` (microdata-derived, not in repo;
`data/` gitignored)
**Inputs:** S01 (roster), S07 (education), S02 (housing/facilities),
weight.dta (weights/design) — see respective codebooks in `docs/`.

## Sample construction

| Step | Criterion | n |
|---|---|---|
| Roster-listed individuals (spine) | all rows, S01 | 46,870 |
| Age filter | 15 ≤ age ≤ 24 (`q01_03`, completed years) | — |
| Presence filter | member_cat == 1 (present members only) | — |
| **Analysis sample** | both filters | **6,950** |

Youth defined as **age 15–24** per this project's research question,
consistent with the ILO standard youth definition.

Presence filter is required, not optional: absentees (member_cat 2/3)
were skipped in the S07 education module regardless of age and have no
outcome data. 29.0% of roster-listed youth (2,835 of 9,785) are thereby
excluded — see selection caveat below.

Sample count independently verified: 6,950 matches the roster-side
count obtained in `R/03_map_roster_vars.R` via a separate construction
path.

## Merge structure

Roster (S01) is the spine; joins verified in scripts:

| Join | Key | Type | Verification |
|---|---|---|---|
| S01 ← S07 (education) | psu_number + hh_number + idcode | 1:1 | nrow unchanged at 46,870 (no row explosion) |
| S01 ← S02 (internet) | psu_number + hh_number | many:1 | 0 NA on internet_hh (every person's household present in S02) |
| youth ← weight.dta | psu_number + hh_number | many:1 | nrow unchanged at 6,950; 0 NA on hhs_wt |

Script 05 drops any pre-existing weight/design columns before its join
(`select(-any_of(...))`), so the 04 → 05 chain is safe to re-run in any
state of `data/youth_analysis.rds`.

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

Carried from weight.dta: `hhs_wt`, `ind_wt`, `prov`, `urbrur`, `domain`
(analytical domain / strata).

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

## Survey weights

Source: `weight.dta` (9,600 households × 12; household level; key
psu_number + hh_number, verified unique). Also carries design
variables: province, analytical domain (strata), district, local
level, urban/rural, season. (Note: `season` from the questionnaire ID
box lives in this file, not in the section files.)

### The two weights and their verified relationship

| Weight | Label | Verified structure |
|---|---|---|
| hhs_wt | Household weight | constant within PSU; sums to 7,185,103 households |
| ind_wt | Individual weight | = hhs_wt × PRESENT household members, exactly (max abs deviation ~8e-7 across all 9,600 households; 0 exceptions) |

Hypothesis trail (documented in `R/05_add_weights.R`): ind_wt =
hhs_wt × total roster size was tested first and REJECTED (max
deviation 15 — a household with 15 absent members); the
present-members version is exact. ind_wt therefore targets the
RESIDENT population and exists to make person-level estimates from
household-level rows.

### Which weight for which analysis

**Per-person weight for the individual-row youth file: `hhs_wt`.**
Each sampled person represents hhs_wt persons like them (all members
of sampled households were enumerated). Attaching ind_wt per person
would weight households by size², double-counting household size.

Validation: hhs_wt summed over PRESENT roster members =
**28,740,504** ≈ Nepal's resident population (~29M). Household total
7,185,103 vs 2021 census ~6.66M (+8%: growth to 2022–23 fieldwork
plus NSO projection benchmarking — to reconcile against the NLSS-IV
survey report's stated totals).

### Weighted vs. unweighted descriptives (analysis sample, n = 6,950)

| | Unweighted | Weighted (hhs_wt) |
|---|---|---|
| Youth in internet households | 36.9% | **42.4%** |
| Enrolled — no internet | 43.4% | 41.2% |
| Enrolled — internet | 58.2% | 58.4% |
| Enrollment gap | +14.8 pp | **+17.2 pp** |
| Mean attainment — no internet | 8.36 | 8.20 |
| Mean attainment — internet | 10.1 | 10.2 |
| Attainment gap | ~1.7 levels | **~2.0 levels** |

Weighted internet share exceeds unweighted → the sample
over-represents low-connectivity households, consistent with design
oversampling of remote domains for subgroup precision.

**Point estimates only.** Correct standard errors under the clustered,
stratified design (PSU clustering; `domain` strata) require the
survey-design setup (`survey`/`srvyr`) — next block. No uncertainty
statements until then.

## First descriptives — headline (weighted, no causal interpretation)

Among present Nepali youth aged 15–24: 42.4% live in households with
internet access. Youth in internet households are 17.2 percentage
points more likely to be currently enrolled (58.4% vs 41.2%) and
average ~2.0 completed levels more schooling (10.2 vs 8.20). These are
unadjusted associations: internet households differ systematically in
wealth, urbanicity, parental education, and age composition within
15–24. Figures motivate the adjusted, survey-weighted analysis; they
do not anticipate its results.

## Selection caveat (for methods)

The analysis sample is necessarily PRESENT youth. Youth absence
(especially labor migration) is not random: it plausibly correlates
with sex, region, and household characteristics including those that
predict internet access. Planned robustness: compare present vs.
absent youth on roster observables (age, sex, parental education,
caste) — absentees have full roster demographics — to characterize
the selection. See `docs/codebook_roster_vars.md`.

## Pending / next steps

- [x] Merge survey weights (`weight.dta`) and re-run descriptives
      weighted — done 2026-07-16; per-person weight = hhs_wt
      (verified); see Survey weights section
- [ ] Survey-design setup (`survey`/`srvyr`: PSU clustering, domain
      strata, hhs_wt) for correct standard errors — required before
      any inference; precedes the survey-weighted logit
- [ ] Document and recode covariates (marital, caste/ethnicity,
      parental education)
- [ ] Present vs. absent youth comparison table (selection
      characterization)
- [ ] Examine `poverty.dta` (NSO consumption aggregate) as candidate
      household covariate
- [ ] Reconcile weighted totals (7.185M households, 28.74M persons)
      against NLSS-IV survey report