library(haven)
library(dplyr)

roster <- read_dta("data-raw/NLSSIV_2022-23/Data/S01.dta")
edu    <- read_dta("data-raw/NLSSIV_2022-23/Data/S07.dta")
s02    <- read_dta("data-raw/NLSSIV_2022-23/Data/S02.dta")
internet_hh <- s02 %>%
  select(psu_number, hh_number, q02_31_c1, q02_31_c2) %>%
  mutate(internet_hh = if_else(q02_31_c1 == 1, 1, 0))   # the 1/2 trap, handled

demog <- roster %>%
  select(psu_number, hh_number, idcode,
         q01_02, q01_03, member_cat, q01_05, q01_07, q01_12, q01_15) %>%
  mutate(female = if_else(q01_02 == 2, 1, 0),
         age    = q01_03)

educ <- edu %>%
  select(psu_number, hh_number, idcode,
         q07_02, q07_03, q07_04, q07_06, q07_12) %>%
  mutate(
    ever_attended = if_else(q07_04 %in% c(2, 3), 1, 0),
    enrolled      = if_else(q07_04 == 3, 1, 0),
    # attainment: coalesce across tracks; never-attended = no level.
    # Codes 16/17 (levelless/illiterate) recoded to NA for now —
    # check their frequency below before finalizing this decision.
    attain_raw = coalesce(q07_06, q07_12),
    attainment = case_when(
      q07_04 == 1                ~ 0,          # never attended: no level
      attain_raw %in% c(16, 17)  ~ NA_real_,   # PENDING decision
      TRUE                       ~ as.numeric(attain_raw)
    )
  )
analysis <- demog %>%
  left_join(educ,        by = c("psu_number", "hh_number", "idcode")) %>%
  left_join(internet_hh, by = c("psu_number", "hh_number"))
nrow(analysis)                          # must be exactly 46,870 (row explosion check)
sum(is.na(analysis$internet_hh))        # must be 0 (every person's household is in S02)
analysis %>% count(q07_04 == 1, attainment == 0)   # never-attended coded correctly
youth <- analysis %>%
  filter(age >= 15, age <= 24,    # youth per RQ; ILO-consistent definition
         member_cat == 1)         # present members only (S07 universe)

nrow(youth)                       # predict: 6,950

# First substantive descriptives
youth %>% count(internet_hh) %>% mutate(share = n / sum(n))

youth %>%
  group_by(internet_hh) %>%
  summarise(enrolled    = mean(enrolled, na.rm = TRUE),
            mean_attain = mean(attainment, na.rm = TRUE),
            n           = n())
dir.create("data", showWarnings = FALSE)
saveRDS(youth, "data/youth_analysis.rds")
file.exists("data/youth_analysis.rds")   # in the Console — expect TRUE