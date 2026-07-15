# Codebook: Household roster variables, NLSS-IV Section 01

**Author:** Upendra Shahi
**Date:** 2026-07-14
**Source file:** `data-raw/NLSSIV_2022-23/Data/S01.dta` (NSO microdata, not in repo)
**File dimensions:** 46,870 individuals × 19 variables
**Level:** Individual (one row per roster-listed household member,
including absentees)
**Universe:** All persons listed on the household roster — present
members AND absentees within country / abroad (see `member_cat`).
**Produced by:** `R/03_map_roster_vars.R`

## ID structure

Individuals uniquely identified by `psu_number` + `hh_number` + `idcode`
(verified: 0 duplicate combinations across 46,870 rows).

Row count is identical to S07 (46,870): the education file carries the
full roster, with out-of-universe persons as all-NA rows. Roster ↔ S07
join on the three ID columns is one-to-one with every person matching.

## Key variables

| Variable | Label | Type | Codes | Notes |
|---|---|---|---|---|
| q01_02 | Sex | dbl+lbl | 1 = Male, 2 = Female | 1/2 coding, NOT 0/1 — recode before use (e.g. `female = q01_02 == 2`) |
| q01_03 | Age | dbl (continuous) | completed years, range 0–99 | no negatives or sentinel codes; median 26, mean 29.4. Max 99 may be top-coded (irrelevant for youth analysis) |
| member_cat | Household/absentee member category | dbl+lbl | 1 = Household Member, 2 = Absentees within country, 3 = Absentees abroad | derived by NSO; central to sample definition (see below) |

Member category frequencies (all ages):

| Code | Category | n | Share |
|---|---|---|---|
| 1 | Household member (present) | 38,101 | 81.3% |
| 2 | Absentee within country | 4,499 | 9.6% |
| 3 | Absentee abroad | 4,270 | 9.1% |

## Covariates available in roster (for analysis-file stage)

| Variable | Label | Planned use |
|---|---|---|
| q01_04 | Relationship to household head | control / identify head |
| q01_05 | Marital status | control |
| q01_07 | Caste/ethnic group code | control (standard in Nepali context) |
| q01_12 | Father's highest education level | key control (parental education) |
| q01_15 | Mother's highest education level | key control (parental education) |
| q01_11 / q01_14 | ID code of father / mother | in-household parent linkage |

Value labels and universes for these to be documented when the merged
analysis file is constructed.

## Sample implications (youth analysis)

Youth defined as age 15–24 (`q01_03`). Roster-listed youth: 9,785.

| Category | n | Share |
|---|---|---|
| Present (member_cat = 1) | 6,950 | 71.0% |
| Absent within country (2) | 1,834 | 18.7% |
| Absent abroad (3) | 1,001 | 10.2% |

**29.0% of roster-listed youth are absent and have NO education
outcomes in S07** (absentees skipped in the education module regardless
of age — verified, see below). The analysis sample is therefore
necessarily PRESENT youth: n = 6,950 before further exclusions.

Selection caveat for methods: youth absence (especially labor
migration) is not random — it plausibly correlates with sex, region,
and household characteristics including those predicting internet
access. Planned robustness: compare present vs. absent youth on
roster observables (age, sex, parental education, caste), which
absentees DO have, to characterize the selection.

## S07 universe resolution (cross-file verification)

Merging roster demographics onto S07's routing variable (q07_04)
resolves the education module's universe exactly:

| member_cat | Age | q07_04 | n |
|---|---|---|---|
| 1 (present) | 5+ | answered | 34,728 |
| 1 (present) | <5 | NA | 3,373 |
| 2 (absent in country) | 5+ | NA | 4,276 |
| 2 (absent in country) | <5 | NA | 223 |
| 3 (absent abroad) | 5+ | NA | 4,168 |
| 3 (absent abroad) | <5 | NA | 102 |

No exceptions in either direction: no present 5+ person is missing,
no under-5 or absentee has answers. **Section 7 universe = present
household members aged 5+.** The 12,142 NA rows decompose exactly as
3,373 present under-5s + 8,769 absentees. Present under-5s = 7.2% of
the file, consistent with population structure (the initially
puzzling 25.9% NA share is fully explained by the absentee skip).

Corresponding correction made in `docs/codebook_education_vars.md`.

## To verify

- [ ] Value labels and universes of covariates q01_04, q01_05, q01_07,
      q01_12, q01_15 (at analysis-file stage)
- [ ] Whether age 99 is top-coded (questionnaire/manual; immaterial
      for youth sample)
- [x] Youth age range confirmed as 15–24 per project research question