# ---------------------------------------------------------------
# 06_survey_design.R
# Purpose : Declare the NLSS-IV complex survey design (PSU clustering,
#           stratification, weights) and produce design-based
#           descriptives with 95% confidence intervals.
# Data    : data/youth_analysis.rds (from 04 + 05) — derived, not in repo
# Author  : Upendra Shahi
# Date    : 2026-08-23
# Output  : design-based descriptives + enrollment-gap test
#           (documented in docs/analysis_file_notes.md)
# Note    : Point estimates here MUST match the weighted.mean() results
#           from 05_add_weights.R (same weights); what is new is the CIs.
# ---------------------------------------------------------------

library(haven)
library(dplyr)
library(srvyr)
library(survey)   # for svyttest()

youth_w <- readRDS("data/youth_analysis.rds")

# Prepare design variables ----------------------------------------
# domain / psu_number / hhs_wt must be plain numerics, not
# haven_labelled, or as_survey_design() errors ("can't convert
# <haven_labelled> to <character>"). zap_labels() keeps the value,
# drops the Stata label decoration (correct for stratum/cluster IDs,
# where only the code matters).
youth_w <- youth_w %>%
  mutate(
    domain     = zap_labels(domain),
    psu_number = zap_labels(psu_number),
    hhs_wt     = zap_labels(hhs_wt)
  )

# Design structure check (run before declaring) -------------------
# domain = province digit + urban/rural digit (e.g. 11 = prov 1 rural,
# 12 = prov 1 urban). 15 strata, not 14: province 3 (Bagmati, incl.
# Kathmandu Valley) is split into 3 domains (30, 31, 32) — an NSO
# design refinement for its most populous region.
# All strata have 41-65 PSUs -> no lonely-PSU problem, no special
# survey.lonely.psu option needed.
youth_w %>%
  group_by(domain) %>%
  summarise(n_psu = n_distinct(psu_number), n_youth = n())

# Declare the survey design ---------------------------------------
youth_design <- youth_w %>%
  as_survey_design(
    ids     = psu_number,   # clusters: PSUs
    strata  = domain,       # stratification: province x urban/rural (15 strata)
    weights = hhs_wt,       # verified per-person weight (see 05)
    nest    = TRUE          # PSU ids restart within strata -> nested
  )

youth_design
# -> Stratified 1-level Cluster Sampling design, 800 clusters.
#    "with replacement" is survey's default (slightly conservative
#    variance; standard when the sampling fraction is small).

# Design-based descriptives (95% CIs) -----------------------------

# Internet access among present youth 15-24.
# 42.4%, 95% CI [39.4%, 45.3%]
youth_design %>%
  summarise(internet = survey_mean(internet_hh, vartype = "ci"))

# Enrollment and attainment by household internet.
# Enrolled: 41.2% [38.9, 43.5] (no internet) vs 58.4% [55.3, 61.5]
# Attain : 8.20 [8.01, 8.40]   (no internet) vs 10.2 [10.0, 10.4]
# CIs cleanly separated in both cases.
youth_design %>%
  group_by(internet_hh) %>%
  summarise(
    enrolled = survey_mean(enrolled,   na.rm = TRUE, vartype = "ci"),
    attain   = survey_mean(attainment, na.rm = TRUE, vartype = "ci")
  )

# Formal difference test on the enrollment gap --------------------
# Difference in mean enrollment = 0.1717 (17.2 pp),
# 95% CI [0.135, 0.208], design-based t = 9.24, df = 784, p < 2.2e-16.
# df = (PSUs - strata) = 800 - 15 ~ 785, NOT n = 6,950 -> the
# clustering correction at work.
# UNADJUSTED association; no causal interpretation.
svyttest(enrolled ~ internet_hh, design = youth_design)