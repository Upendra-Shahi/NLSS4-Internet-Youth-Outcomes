# Analysis file notes: youth_analysis.rds

**Author:** Upendra Shahi
**Date:** 2026-07-15 (design section added 2026-08-23)
**Produced by:** `R/04_build_analysis_file.R` + `R/05_add_weights.R`;
design declared in `R/06_survey_design.R`
**Output:** `data/youth_analysis.rds` (microdata-derived, not in repo;
`data/` gitignored)
**Inputs:** S01 (roster), S07 (education), S02 (housing/facilities),
weight.dta (weights/design) — see respective codebooks in `docs/`.

## Sample construction

| Step | Criterion | n |
|---|---|---|
| Roster-listed individuals (spine) | all rows, S01 | 46,870 |
| Age filter | 15 <= age <= 24 (`q01_03`, completed years) | — |
| Presence filter | member_cat == 1 (present members only) | — |
| **Analysis sample** | both filters | **6,950** |

Youth defined as **age 15-24** per this project's research question,
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
| S01 <- S07 (education) | psu_number + hh_number + idcode | 1:1 | nrow unchanged at 46,870 (no row explosion) |
| S01 <- S02 (internet) | psu_number + hh_number | many:1 | 0 NA on internet_hh (every person's household present in S02) |
| youth <- weight.dta | psu_number + hh_number | many:1 | nrow unchanged at 6,950; 0 NA on hhs_wt |

Script 05 drops any pre-existing weight/design columns before its join
(`select(-any_of(...))`), so the 04 -> 05 chain is safe to re-run in any
state of `data/youth_analysis.rds`.

## Constructed variables

| Variable | Construction | Notes |
|---|---|---|
| internet_hh | 1 if q02_31_c1 == 1, else 0 | source is 1/2 coded (1=YES, 2=NO) |
| female | 1 if q01_02 == 2, else 0 | source is 1/2 coded (1=Male, 2=Female) |
| age | q01_03 | completed years |
| ever_attended | 1 if q07_04 in {2, 3}, else 0 | from routing variable |
| enrolled | 1 if q07_04 == 3, else 0 | from routing variable, NOT q07_11 |
| attain_raw | coalesce(q07_06, q07_12) | parallel track variables; identical code schemes (label-text difference at code 11 only — expected coalesce() warning, cosmetic) |
| attainment | 0 if never attended; NA if attain_raw in {16, 17}; else attain_raw | see decisions below |

Carried from weight.dta: `hhs_wt`, `ind_wt`, `prov`, `urbrur`, `domain`
(analytical domain / strata).

### Coding decisions

1. **Codes 16/17 (Literate levelless / Illiterate) -> NA.**
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

Source: `weight.dta` (9,600 households x 12; household level; key
psu_number + hh_number, verified unique). Also carries design
variables: province, analytical domain (strata), district, local
level, urban/rural, season. (Note: `season` from the questionnaire ID
box lives in this file, not in the section files.)

### The two weights and their verified relationship

| Weight | Label | Verified structure |
|---|---|---|
| hhs_wt | Household weight | constant within PSU; sums to 7,185,103 households |
| ind_wt | Individual weight | = hhs_wt x PRESENT household members, exactly (max abs deviation ~8e-7 across all 9,600 households; 0 exceptions) |

Hypothesis trail (documented in `R/05_add_weights.R`): ind_wt =
hhs_wt x total roster size was tested first and REJECTED (max
deviation 15 — a household with 15 absent members); the
present-members version is exact. ind_wt therefore targets the
RESIDENT population and exists to make person-level estimates from
household-level rows.

### Which weight for which analysis

**Per-person weight for the individual-row youth file: `hhs_wt`.**
Each sampled person represents hhs_wt persons like them (all members
of sampled households were enumerated). Attaching ind_wt per person
would weight households by size^2, double-counting household size.

Validation: hhs_wt summed over PRESENT roster members =
**28,740,504** ~ Nepal's resident population (~29M). Household total
7,185,103 vs 2021 census ~6.66M (+8%: growth to 2022-23 fieldwork
plus NSO projection benchmarking — to reconcile against the NLSS-IV
survey report's stated totals).

## Survey design

Declared in `R/06_survey_design.R` using `srvyr`/`survey`:

- **Clusters (ids):** `psu_number` — 800 PSUs total
- **Strata:** `domain` — 15 strata. `domain` = province digit +
  urban/rural digit (11 = prov 1 rural, 12 = prov 1 urban, ...).
  15 not 14 because province 3 (Bagmati, incl. Kathmandu Valley) is
  split into three domains (30/31/32), an NSO design refinement.
- **Weights:** `hhs_wt` (verified per-person weight, above)
- **nest = TRUE:** PSU ids restart within strata, so PSUs are treated
  as nested inside strata.
- Every stratum has 41-65 PSUs -> no lonely-PSU issue; no special
  `survey.lonely.psu` option required.
- Design prints as "with replacement" (survey default; slightly
  conservative variance, standard at small sampling fractions).

Design inputs (`domain`, `psu_number`, `hhs_wt`) must be plain numeric,
not haven_labelled, or `as_survey_design()` errors — `zap_labels()`
applied before declaring.

### Design-based descriptives (95% CIs)

Point estimates match the weighted.mean() results exactly (verification
that the design weights correctly); CIs are the new content.

| Estimate | Value | 95% CI |
|---|---|---|
| Internet access (present youth 15-24) | 42.4% | [39.4%, 45.3%] |
| Enrolled — no internet | 41.2% | [38.9%, 43.5%] |
| Enrolled — internet | 58.4% | [55.3%, 61.5%] |
| Mean attainment — no internet | 8.20 | [8.01, 8.40] |
| Mean attainment — internet | 10.2 | [10.0, 10.4] |

Enrollment and attainment CIs are cleanly separated between internet
and non-internet households.

### Enrollment-gap test

Design-based t-test (`svyttest`): difference in mean enrollment =
**17.2 pp**, 95% CI **[13.5, 20.8]**, t = 9.24, df = 784, p < 2.2e-16.
Note df = (PSUs - strata) = 800 - 15 ~ 785, not n = 6,950 — the
clustering correction. **Unadjusted association; no causal
interpretation.**

## First descriptives — headline (design-based, no causal interpretation)

Among present Nepali youth aged 15-24: 42.4% (95% CI 39.4-45.3) live in
households with internet access. Youth in internet households are 17.2
percentage points more likely to be currently enrolled (95% CI for the
difference 13.5-20.8) and average ~2.0 completed levels more schooling.
These are unadjusted associations: internet households differ
systematically in wealth, urbanicity, parental education, and age
composition within 15-24. Figures motivate the adjusted, design-based
regression analysis; they do not anticipate its results.

## Selection caveat (for methods)

The analysis sample is necessarily PRESENT youth. Youth absence
(especially labor migration) is not random: it plausibly correlates
with sex, region, and household characteristics including those that
predict internet access. Planned robustness: compare present vs.
absent youth on roster observables (age, sex, parental education,
caste) — absentees have full roster demographics — to characterize
the selection. See `docs/codebook_roster_vars.md`.

## Pending / next steps

- [x] Merge survey weights (`weight.dta`); per-person weight = hhs_wt
      (verified) — done 2026-07-16
- [x] Survey-design setup (`srvyr`/`survey`: PSU clustering, domain
      strata, hhs_wt) for design-based CIs — done 2026-08-23
- [ ] Document and recode covariates (marital, caste/ethnicity,
      parental education, urban/rural) to model-ready form
- [ ] Survey-weighted logistic regression (`svyglm`) of enrollment on
      internet access with controls — the adjusted analysis
- [ ] Present vs. absent youth comparison table (selection
      characterization)
- [ ] Examine `poverty.dta` (NSO consumption aggregate) as candidate
      household covariate
- [ ] Reconcile weighted totals (7.185M households, 28.74M persons)
      against NLSS-IV survey report