# Codebook: Internet variables, NLSS-IV Section 02

**Author:** Upendra Shahi
**Date:** 2026-07-11
**Source file:** `data-raw/NLSSIV_2022-23/Data/S02.dta` (NSO microdata, not in repo)
**File dimensions:** 9,600 households × 62 variables
**Produced by:** `R/01_map_internet_vars.R`

## Context

Question 2.31 is a household services battery (a = landline, b = cable/
satellite TV, c = internet). For each service: `_1` asks possession
(1 = YES, 2 = NO); `_2` records annual expenditure in rupees, asked only
if `_1` = YES (skip pattern → NA means "not asked", not item nonresponse).

A label search across all 62 variables in S02 (`grepl("internet", ...)`)
confirmed that `q02_31_c1` and `q02_31_c2` are the only internet-related
variables in this section.

## Variables

| Variable | Label | Type | Codes | Valid n | NA | Notes |
|---|---|---|---|---|---|---|
| q02_31_c1 | {2.31c1} have Internet ? | dbl+lbl | 1 = YES, 2 = NO | 9,600 | 0 | Treatment variable. YES = 3,250 (33.9% unweighted) |
| q02_31_c2 | {2.31c2} Internet expenditure RUPEES | dbl | continuous, NPR | 3,250 | 6,350 | Annual expenditure (per questionnaire Q2.31). Asked only if c1 = YES |

## Merge key

Households uniquely identified by `psu_number` + `hh_number`
(verified: 0 duplicate combinations across 9,600 households).
All section merges join on both columns, e.g.
`left_join(x, y, by = c("psu_number", "hh_number"))`.
Season appears in the questionnaire ID box (Q0.01 PSU, 4 digits;
Q0.02 household number, 2 digits; season, 1 digit) but is not present
in S02 and is not needed for uniqueness.

## Derived variable (planned)

`internet_hh` = 1 if `q02_31_c1` == 1, else 0.
No missing handling needed (zero NA on source variable).
Caution: source coding is 1/2, NOT 0/1 — always recode before analysis.

## Limitations

Measures household-level internet access of any type; does not capture
connection type, quality, or individual (youth) usage. To be acknowledged
in methods.

## Verified

- [x] Q2.31 expenditure periodicity: **annual** (confirmed in questionnaire)
- [x] Household ID structure: PSU number (Q0.01, 4 digits) + household
      number (Q0.02, 2 digits) + season (1 digit) per questionnaire;
      in data, `psu_number` + `hh_number` is the unique key