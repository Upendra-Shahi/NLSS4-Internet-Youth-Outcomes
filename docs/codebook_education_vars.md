# Codebook: Education variables, NLSS-IV Section 07

**Author:** Upendra Shahi
**Date:** 2026-07-14
**Source file:** `data-raw/NLSSIV_2022-23/Data/S07.dta` (NSO microdata, not in repo)
**File dimensions:** 46,870 individuals × 30 variables
**Level:** Individual (one row per person)
**Universe:** Present household members aged 5 years and older
(member_cat = 1 in S01 roster). Absentees (member_cat 2/3) skipped
regardless of age. Persons outside the universe appear as rows with
NA on all module variables (n = 12,142 = 3,373 present under-5s
+ 8,769 absentees; verified empty across q07_02–q07_21).
**Produced by:** `R/02_map_education_vars.R`

## ID structure

Individuals uniquely identified by `psu_number` + `hh_number` + `idcode`
(verified: 0 duplicate combinations across 46,870 rows).

Merge to S02 internet status: many-to-one join on
`psu_number` + `hh_number` only (household value copied to all members).

Age and sex are NOT in S07 — require merge from the household roster
(section/file to be identified in next task).

Note: `q07_01` is "ID CODE OF RESPONDENT" — some module answers may be
given by proxy respondents rather than the person themselves.

## Module routing (q07_04)

`q07_04` ("educational background") sorts every in-universe person into
one of three mutually exclusive tracks. This is why some labels appear
twice in the file: q07_06/q07_12 (highest level completed) and
q07_09–q07_10 / q07_20–q07_21 (completion durations) are parallel
questions asked in different tracks. Nobody answers both blocks.

| Code | Track | n | Answers questions |
|---|---|---|---|
| 1 | Never attended school | 8,817 | none further |
| 2 | School attended in past | 14,919 | q07_05–q07_10 |
| 3 | Current schooling | 10,992 | q07_11–q07_21 |
| NA | Out of universe (under-5 or absentee) | 12,142 | none |

In-universe n = 34,728. Unweighted shares: never attended 25.4%,
attended in past 43.0%, currently enrolled 31.6%.

## Outcome variables (constructed)

| Outcome | Construction | Notes |
|---|---|---|
| Ever attended school (0/1) | `q07_04 %in% c(2, 3)` | full in-universe sample |
| Currently enrolled (0/1) | `q07_04 == 3` | headline enrollment outcome; taken from routing variable, NOT q07_11 (which asks school type among the enrolled) |
| Highest level completed | coalesce logic across q07_06 (track 2) and q07_12 (track 3); persons with q07_04 == 1 coded as no schooling | code schemes verified identical (see below) |
| Literacy (secondary) | q07_02 (read), q07_03 (write) | value codes to confirm (expect 1 = YES, 2 = NO as in S02) |

## Attainment coding (q07_06 / q07_12)

Verified: q07_06 and q07_12 share the same numeric code scheme (0–17,
identical levels at every value). Sole difference is label text at
code 11 ("SEE/SLC" in q07_06 vs "SLC" in q07_12) — same credential
(class-10 examination, renamed SEE post-2016). No recoding needed
before coalescing.

| Code | Level |
|---|---|
| 0 | Pre-school/kindergarten |
| 1–10 | Class 1 – Class 10 |
| 11 | SEE/SLC |
| 12 | Intermediate/Class 12 |
| 13 | Bachelor level |
| 14 | Master level or higher |
| 15 | Professional degree |
| 16 | Literate (levelless) |
| 17 | Illiterate |

**Caution — variable is not fully ordinal as stored:** codes 16 and 17
are catch-alls, not grades. Any years-of-schooling or ordered-scale
treatment must recode 16/17 as "no completed level" (below code 0/1),
not leave them above Professional degree. Check frequencies of 16/17
when constructing the variable; if common among tracks 2/3, a coding
decision is needed.

For youth aged 15–24, realistic attainment range is approximately
codes 0–13 (sanity-check after roster merge).

## Source variables (shortlist)

| Variable | Label | Universe | Notes |
|---|---|---|---|
| q07_02 | Can you read? | 5+ | literacy component |
| q07_03 | Can you write? | 5+ | literacy component |
| q07_04 | Educational background (routing) | 5+ | 1/2/3, see routing table |
| q07_06 | What was the highest level that you completed? | track 2 | codes 0–17 |
| q07_12 | What was the highest level that you completed? | track 3 | codes 0–17 |
| q07_08 | Why did you leave school / college? | track 2 | descriptive use (dropout reasons) |
| q07_11 | What type of school/college are you currently attending? | track 3 | school type, not enrollment status |
| q07_17_a–g | Household schooling expenditure, past 12 months (battery) | track 3 | possible covariate/descriptive |
| q07_18 | Received scholarship? | track 3 | possible covariate |
| q07_19 | Scholarship amount, past 12 months (NPR) | track 3, if q07_18 = YES | |

Variable labels in the .dta are truncated at ~80 characters (e.g.
q07_09); exact question wording per questionnaire PDF, Section 7.

## To verify

- [x] Universe verified via roster merge (2026-07-12, see
      R/03_map_roster_vars.R): Section 7 universe = PRESENT household
      members (member_cat = 1) aged 5+. NA on q07_04 decomposes exactly
      as 3,373 present under-5s + 8,769 absentees of all ages
      (member_cat 2/3). Original age-only hypothesis rejected —
      absentees skipped regardless of age. The 25.9% NA share is
      thereby fully explained (present under-5s alone = 7.2%,
      consistent with population structure).
- [ ] Value codes of q07_02/q07_03 (expect 1 = YES, 2 = NO).
- [ ] Frequencies of attainment codes 16/17 among tracks 2/3.
- [x] q07_06 vs q07_12: identical code schemes (verified; label-text
      difference at code 11 only).
- [ ] Identify household roster section/file (for age, sex,
      relationship to head).
