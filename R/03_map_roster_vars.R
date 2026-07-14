# ---------------------------------------------------------------
# 03_map_roster_vars.R
# Purpose : Map household roster variables (NLSS-IV Section 01):
#           age, sex, member category, parental education.
#           Verify individual ID key; resolve S07 education module
#           universe via roster merge; size youth absentee share.
# Data    : data-raw/NLSSIV_2022-23/Data/S01.dta (roster)
#           data-raw/NLSSIV_2022-23/Data/S07.dta (education, for
#           universe check) — NSO microdata, not in repo
# Author  : Upendra Shahi
# Date    : 2026-07-14
# Output  : docs/codebook_roster_vars.md (written from output below);
#           universe correction in docs/codebook_education_vars.md
# ---------------------------------------------------------------

library(haven)
library(dplyr)

# Load roster -----------------------------------------------------
roster <- read_dta("data-raw/NLSSIV_2022-23/Data/S01.dta")

dim(roster)            # expect 46,870 x 19 (same persons as S07)
names(roster)

# ID key verification ---------------------------------------------
# Individuals uniquely identified by psu_number + hh_number + idcode
# (expect 0 rows)
roster %>%
  count(psu_number, hh_number, idcode) %>%
  filter(n > 1)

# Variable labels -------------------------------------------------
labs <- sapply(roster, attr, "label")
tibble(variable = names(labs), label = unname(labs)) %>% print(n = 19)

# Key variables ---------------------------------------------------
# q01_02 : sex (1 = Male, 2 = Female — 1/2 coding, NOT 0/1)
attr(roster$q01_02, "labels")

# q01_03 : age in completed years (continuous, no value labels;
#          expect range 0-99, no negatives / sentinel codes)
summary(roster$q01_03)

# member_cat : household/absentee member category
attr(roster$member_cat, "labels")
roster %>% count(member_cat)

# Universe check for S07 education module -------------------------
# Hypothesis (v1): NA on q07_04 <=> age < 5.        REJECTED below.
# Hypothesis (v2): S07 universe = PRESENT members (member_cat = 1)
#                  aged 5+; absentees skipped regardless of age.

edu <- read_dta("data-raw/NLSSIV_2022-23/Data/S07.dta")

edu_check <- edu %>%
  select(psu_number, hh_number, idcode, q07_04) %>%
  left_join(
    roster %>% select(psu_number, hh_number, idcode, q01_03, member_cat),
    by = c("psu_number", "hh_number", "idcode")
  )

# v1 test: under-5 alone does NOT explain all NA
# (8,444 persons aged 5+ have missing q07_04)
edu_check %>%
  count(under5 = q01_03 < 5, missing_q07 = is.na(q07_04))

# v2 test: adding member_cat explains every NA exactly.
# Expected clean pattern:
#   cat 1, 5+   -> answered (34,728)
#   cat 1, <5   -> NA       ( 3,373)
#   cat 2/3     -> NA at all ages (4,276 + 223 + 4,168 + 102 = 8,769)
# Confirmed: no "present, 5+, missing" row and no under-5 with answers.
edu_check %>%
  count(member_cat,
        under5 = q01_03 < 5,
        missing_q07 = is.na(q07_04))

# Youth absentee share ---------------------------------------------
# Youth = age 15-24. Absent youth have NO education outcomes in S07,
# so the analysis sample is necessarily PRESENT youth (member_cat = 1).
# Result: 6,950 present (71.0%), 1,834 absent in country (18.7%),
# 1,001 absent abroad (10.2%) of 9,785 roster-listed youth.
roster %>%
  filter(q01_03 >= 15, q01_03 <= 24) %>%
  count(member_cat) %>%
  mutate(share = scales::percent(n / sum(n), accuracy = 0.1))

# Covariate shortlist noted for later mapping ----------------------
# q01_04 : relationship to household head
# q01_05 : marital status
# q01_07 : caste/ethnic group code
# q01_12 : father's highest education level
# q01_15 : mother's highest education level
# (value labels and universes to be documented when the analysis
#  file is constructed)

