# ---------------------------------------------------------------
# 01_map_internet_vars.R
# Purpose : Identify and document internet-related variables in
#           NLSS-IV Section 02 (housing & household facilities)
# Data    : data-raw/NLSSIV_2022-23/Data/S02.dta (NSO, not in repo)
# Author  : Upendra Shahi
# Date    : 2026-07-11
# Output  : docs/codebook_internet_vars.md (written by hand from
#           the console output below)
# ---------------------------------------------------------------

library(haven)
library(dplyr)

# Load Section 02 ------------------------------------------------
s02 <- read_dta("data-raw/NLSSIV_2022-23/Data/S02.dta")

# Quick orientation: how big is this file?
dim(s02)

# Find internet-related variables --------------------------------
# 1) By name pattern
s02 %>%
  select(starts_with("q02_31")) %>%
  glimpse()

# 2) Variable labels (what each question asks)
sapply(s02 %>% select(starts_with("q02_31")), attr, "label")

# 3) Value labels (what the numeric codes mean)
sapply(s02 %>% select(starts_with("q02_31")), attr, "labels")

# 4) Frequencies incl. missings ----------------------------------
s02 %>% count(q02_31_c1)
# Search ALL variable labels in S02 for "internet"
labs <- sapply(s02, attr, "label")
labs[grepl("internet", labs, ignore.case = TRUE)]
# Household ID verification ---------------------------------------
# Questionnaire: ID = PSU (Q0.01, 4 digits) + hh number (Q0.02, 2 digits) + season

# What are the ID-ish columns actually called in S02?
names(s02)[1:10]          # ID vars are usually the first columns

# Is PSU + household number unique on its own?
s02 %>% count(psu_number, hh_number) %>% filter(n > 1)