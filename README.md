# Household Internet Access and Youth Education & Employment Outcomes in Nepal

**Status: Work in progress - analysis file constructed; weighted descriptives complete; regression analysis upcoming**

## Overview

This repository contains the analysis code for an ongoing study examining the relationship between household internet access and education and employment outcomes among Nepali youth, using microdata from the Nepal Living Standards Survey IV (NLSS-IV, 2022/23). Current work covers education outcomes; employment outcomes are planned.

The emphasis throughout is on documented, verifiable data construction: every variable used is mapped against the questionnaire, every merge key verified, and every coding decision recorded in `docs/`.

## Research Question

How is household internet access associated with education participation and employment outcomes among youth (aged 15–24) in Nepal, and how does this relationship vary across provinces and urban/rural residence?

## Data

- **Source:** Nepal Living Standards Survey IV (NLSS-IV, 2022/23), National Statistics Office, Government of Nepal
- **Access:** Microdata used under a limited data access agreement with the National Statistics Office. **Raw data files are not included in this repository** and cannot be redistributed. Researchers can request access directly from the [National Statistics Office](https://nsonepal.gov.np/).
- **Design:** Nationally representative household survey with a stratified, clustered design. Point estimates are survey-weighted (household weight per person; weight structure verified in `R/05_add_weights.R`). Design-based standard errors (PSU clustering, strata) are the next implementation step; no inferential claims are made yet.

## Current findings (descriptive)

Among present youth aged 15–24 (n = 6,950), weighted estimates: 42.4% live in households with internet access. Youth in internet households are 17.2 percentage points more likely to be currently enrolled (58.4% vs 41.2%) and average about two more completed schooling levels (10.2 vs 8.2). **These are unadjusted associations and carry no causal interpretation**; they motivate the planned adjusted analysis. Note also that 29% of roster-listed youth are absent household members with no outcome data.The sample is present youth, a scope condition documented in `docs/`.

## Repository Structure

```
├── R/                                # Pipeline scripts, numbered in run order
│   ├── 01_map_internet_vars.R        #   Map/document internet variables (S02)
│   ├── 02_map_education_vars.R       #   Map/document education module (S07)
│   ├── 03_map_roster_vars.R          #   Map roster; resolve S07 universe
│   ├── 04_build_analysis_file.R      #   Merge, recode, filter -> youth file
│   └── 05_add_weights.R              #   Verify weight structure; weighted descriptives
├── docs/                             # Codebooks and construction notes
│   ├── codebook_internet_vars.md
│   ├── codebook_education_vars.md
│   ├── codebook_roster_vars.md
│   └── analysis_file_notes.md
├── .gitignore                        # Excludes data-raw/ and data/ (all microdata)
├── LICENSE                           #MIT (code only; data not distributed)
└── README.md
```

## Reproducibility

Obtain NLSS-IV microdata from the National Statistics Office and place the package at `data-raw/NLSSIV_2022-23/` (with its `Data/` and `Documents/` subfolders; excluded from version control). The pipeline then runs end-to-end from a fresh R session:

```r
source("R/04_build_analysis_file.R")   # builds data/youth_analysis.rds
source("R/05_add_weights.R")           # adds verified weights + design variables
```

Scripts 01–03 are the mapping/verification record and can be run independently. Required packages: `haven`, `dplyr`.

## Author

Upendra Shahi  
MSc Public Policy (University of Bristol, UK)  
MA International Relations and Diplomacy (Tribhuvan University, Nepal)

## Changelog

- **[July 2026]:** Repository created; internet, education, and roster modules mapped and documented; youth analysis file constructed (n = 6,950); survey weight structure verified; weighted descriptives complete.

## License

Code is released under the MIT License. Data are subject to the National Statistics Office access agreement and are not distributed here.