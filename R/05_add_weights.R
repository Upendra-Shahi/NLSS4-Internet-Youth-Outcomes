# ---------------------------------------------------------------
# 05_add_weights.R
# Purpose : Inspect NLSS-IV weight/design file (weight.dta); verify
#           weight structure; merge weights and design variables
#           onto the youth analysis file; weighted descriptives.
# Data    : data-raw/NLSSIV_2022-23/Data/weight.dta
#           data-raw/NLSSIV_2022-23/Data/S01.dta (roster, for
#           household-size verification)
#           data/youth_analysis.rds (from 04_build_analysis_file.R)
#           — NSO microdata / derived, none in repo
# Author  : Upendra Shahi
# Date    : 2026-07-19
# Output  : data/youth_analysis.rds (overwritten, now including
#           hhs_wt, ind_wt, prov, urbrur, domain);
#           "Survey weights" section in docs/analysis_file_notes.md
# Key finding: per-person weight for individual-level analysis is
#           hhs_wt. ind_wt = hhs_wt x PRESENT household members
#           (verified exact) and must NOT be attached per person.
# ---------------------------------------------------------------

library(haven)
library(dplyr)

# Load weight/design file ------------------------------------------
wt <- read_dta("data-raw/NLSSIV_2022-23/Data/weight.dta")

dim(wt)      # 9,600 x 12 — household level
names(wt)    # two weights (hhs_wt, ind_wt) + design vars:
# prov_code/prov, domain (analytical domain / strata),
# dist_code, lcode/lname, urbrur, season
# (note: 'season' from the questionnaire ID box lives
#  here, not in the section files)

sapply(wt, attr, "label")

# Key uniqueness (household level; expect 0 rows) -------------------
wt %>% count(psu_number, hh_number) %>% filter(n > 1)

# Weight sanity checks ----------------------------------------------
summary(wt$hhs_wt)   # strictly positive, median ~631, long right tail
summary(wt$ind_wt)
sum(is.na(wt$hhs_wt)); sum(is.na(wt$ind_wt))   # expect 0, 0

# Population-total check: household weights should approximate the
# number of households in Nepal.
# Result: 7,185,103 vs 2021 census ~6.66M (+8%; growth to 2022-23
# fieldwork + NSO projection benchmarking — reconcile against the
# NLSS-IV survey report's stated totals).
sum(wt$hhs_wt)

# What is ind_wt? Hypothesis testing --------------------------------
# Observed within-PSU pattern: hhs_wt constant; ind_wt an integer
# multiple of hhs_wt.

roster <- read_dta("data-raw/NLSSIV_2022-23/Data/S01.dta")

# Hypothesis v1: ind_wt = hhs_wt x TOTAL roster size.  REJECTED:
# max |ind_wt/hhs_wt - size_total| = 15 (a household with 15
# absent members).
# Hypothesis v2: ind_wt = hhs_wt x PRESENT members only.  EXACT:
# max abs diff ~ 8e-7 (floating point), 0 households off.
hh_size <- roster %>%
  group_by(psu_number, hh_number) %>%
  summarise(size_total   = n(),
            size_present = sum(member_cat == 1),
            .groups = "drop")

wt %>%
  left_join(hh_size, by = c("psu_number", "hh_number")) %>%
  mutate(ratio = ind_wt / hhs_wt) %>%
  summarise(
    max_abs_diff_total   = max(abs(ratio - size_total)),    # 15 (v1 rejected)
    max_abs_diff_present = max(abs(ratio - size_present)),  # ~0  (v2 exact)
    n_off_present        = sum(abs(ratio - size_present) > 0.01)  # 0
  )

# Conclusion: ind_wt exists to make person-level estimates FROM
# household-level rows (targets the RESIDENT population). Attaching
# ind_wt per person would weight households by size^2. For the
# individual-row youth file, the per-person weight is hhs_wt.

# Independent validation: hhs_wt summed over PRESENT roster members
# should reproduce Nepal's population. Result: 28,740,504 (~29M). ----
roster %>%
  select(psu_number, hh_number, member_cat) %>%
  left_join(wt %>% select(psu_number, hh_number, hhs_wt),
            by = c("psu_number", "hh_number")) %>%
  filter(member_cat == 1) %>%
  summarise(implied_population = sum(hhs_wt))

# Merge weights + design variables onto youth file ------------------
# drop any prior weight/design columns so re-running is safe
youth <- readRDS("data/youth_analysis.rds") %>%
  select(-any_of(c("hhs_wt", "ind_wt", "prov", "urbrur", "domain")))

youth_w <- youth %>%
  left_join(wt %>% select(psu_number, hh_number, hhs_wt, ind_wt,
                          prov, urbrur, domain),
            by = c("psu_number", "hh_number"))

nrow(youth_w)                  # expect 6,950 (no row explosion)
sum(is.na(youth_w$hhs_wt))     # expect 0

# Weighted descriptives (point estimates only; correct SEs require
# survey-design setup [PSU clustering, strata] — next block) --------

# Internet access among present youth 15-24:
# unweighted 36.9% -> weighted 42.4%. Weighted > unweighted implies
# the sample over-represents low-connectivity households, consistent
# with design oversampling of remote domains.
youth_w %>%
  summarise(internet_unwtd = mean(internet_hh),
            internet_wtd   = weighted.mean(internet_hh, hhs_wt))

# Outcome gradient by household internet (weighted):
# enrollment 41.2% vs 58.4% (+17.2 pp); attainment 8.20 vs 10.2
# (~2.0 levels). Unadjusted associations; no causal interpretation.
youth_w %>%
  group_by(internet_hh) %>%
  summarise(enrolled_wtd = weighted.mean(enrolled, hhs_wt, na.rm = TRUE),
            attain_wtd   = weighted.mean(attainment, hhs_wt, na.rm = TRUE),
            n            = n())

# Save enriched analysis file (overwrites unweighted version; the
# scripts 04 -> 05 reconstruct everything from raw data) ------------
saveRDS(youth_w, "data/youth_analysis.rds")