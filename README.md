# Household Internet Access and Youth Education & Employment Outcomes in Nepal

**Status: Work in progress - preliminary analysis**

## Overview

This repository contains the analysis code for an ongoing study examining the relationship between household internet access and education and employment outcomes among Nepali youth, using microdata from the Nepal Living Standards Survey IV (NLSS-IV, 2022/23).

## Research Question

How is household internet access associated with education participation and employment outcomes among youth (aged 15–24) in Nepal, and how does this relationship vary across provinces and urban/rural residence?

## Data

- **Source:** Nepal Living Standards Survey IV (NLSS-IV, 2022/23), National Statistics Office, Government of Nepal
- **Access:** Microdata used under a limited data access agreement with the National Statistics Office. **Raw data files are not included in this repository** and cannot be redistributed. Researchers can request access directly from the [National Statistics Office](https://nsonepal.gov.np/).
- **Design:** Nationally representative household survey; all analyses apply survey weights and account for the complex sampling design.

## Methods

- Survey-weighted descriptive statistics and cross-tabulations
- [To be extended: regression analysis of youth outcomes on household internet access with demographic and geographic controls]

All analysis is conducted in **R**.

## Repository Structure

```
├── R/                  # Analysis scripts, numbered in order of execution
│   ├── 01_import_clean.R
│   ├── 02_descriptives.R
│   └── 03_analysis.R
├── output/             # Tables and figures (no microdata)
├── docs/               # Notes and documentation
├── .gitignore          # Excludes all data files
└── README.md
```

## Reproducibility

Scripts run sequentially (01 → 02 → 03). To reproduce the analysis, obtain NLSS-IV microdata from the National Statistics Office and place the files in a local `data/` folder (excluded from version control).

## Author

Upendra Shahi  
MSc Public Policy (University of Bristol, UK)  
MA International Relations and Diplomacy (Tribhuvan University, Nepal)

## Changelog

- **[July 2026]:** Repository created; data import and cleaning scripts drafted.
- <!-- Add one line per week summarizing progress -->

## License

Code is released under the MIT License. Data are subject to the National Statistics Office access agreement and are not distributed here.
