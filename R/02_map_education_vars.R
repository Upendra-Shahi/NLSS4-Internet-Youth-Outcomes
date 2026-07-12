
#02_map_education_vars.R
#Purpose: Identify and document education module variables in
#           NLSS-IV Section 07
#Data: /data-raw/NLSSIV_2022-23/Data/S07.dta (NSO, not in repo)
#Author: Upendra Shahi
#Data: 2026-07-11
#output: docs/codebook_education_vars.md (written by hand from
#           the console output below)
library(haven)
library(dplyr)

edu <- read_dta("data-raw/NLSSIV_2022-23/Data/S07.dta")  # adjust name

dim(edu)                 # expect FAR more than 9,600 rows
names(edu)[1:10]         # what identifies a person?
edu %>% count(psu_number, hh_number, idcode) %>% filter(n > 1)
# adjust third name to reality; expect 0 rows
labs <- sapply(edu, attr, "label")

labs[grepl("school|educat|grade|class|literat|attend|enrol",
           labs, ignore.case = TRUE)]
labs   # print every label, all 30
attr(edu$q07_04, "labels")
edu %>% count(q07_04)
edu %>%
  filter(is.na(q07_04)) %>%
  summarise(across(q07_02:q07_21, ~ sum(!is.na(.))))
attr(edu$q07_06, "labels")
attr(edu$q07_12, "labels")
identical(attr(edu$q07_06, "labels"), attr(edu$q07_12, "labels"))
