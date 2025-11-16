# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Medicaid expansion on pct of county low-income residents who have health insurance ----
library(tidyverse)
df <- read_csv(
  "Labs/Medicaid-Expansion/sahie_low_income_county_panel.csv"
)

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Overall effect ----
est_es <- did2s::did2s(
  data = df,
  yname = "pct_insured_total",
  first_stage = ~ 0 | year + fips,
  second_stage = ~ i(rel_year, ref = -15),
  treatment = "treat",
  cluster_var = "fips"
)
iplot(est_es)

# e.g. rural/urban county event-study estimates
# did2s::did2s(
#   data = df,
#   yname = "pct_insured_total",
#   first_stage = ~ 0 | year + fips,
#   second_stage = ~ i(rel_year, i.urban, ref = -15),
#   treatment = "treat",
#   cluster_var = "fips"
# )

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Adding census region-by-year time effects ----
est_es <- did2s::did2s(
  data = df,
  yname = "pct_insured_total",
  first_stage = ~ 0 | fips + census_region^year,
  second_stage = ~ i(rel_year, ref = -15),
  treatment = "treat",
  cluster_var = "fips"
)
iplot(est_es)


# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# By gender ----
est_female <- did2s::did2s(
  data = df,
  yname = "pct_insured_female",
  first_stage = ~ 0 | year + fips,
  second_stage = ~ i(rel_year, ref = -15),
  treatment = "treat",
  cluster_var = "fips"
)
est_male <- did2s::did2s(
  data = df,
  yname = "pct_insured_male",
  first_stage = ~ 0 | year + fips,
  second_stage = ~ i(rel_year, ref = -15),
  treatment = "treat",
  cluster_var = "fips"
)
iplot(list(est_female, est_male))
