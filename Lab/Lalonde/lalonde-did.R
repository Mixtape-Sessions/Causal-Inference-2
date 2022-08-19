## lalonde-did.R ---------------------------------------------------------------
## Kyle Butts, CU Boulder Economics
## 
## Difference-in-Differences analysis of Lalonde data

library(tidyverse)
library(fixest)
library(DRDID) # devtools::install_github("pedrohcgs/DRDID")
library(haven)

# 1. Experimental data
df_exp <- haven::read_dta("https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Labs/Lalonde/lalonde_exp_panel.dta")

# ---- Difference-in-Differences Estimate
feols(
  re ~ i(treat) | id + year, 
  data = df_exp, vcov = "hc1"
)


# 2. CPS data
df_nonexp <- haven::read_dta("https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Labs/Lalonde/lalonde_nonexp_panel.dta")

# ---- Difference-in-means
feols(
  re ~ i(treat),
  data = df_nonexp[year == 78, ], vcov = "hc1"
)

# ---- Initial Difference-in-difference
feols(
  re ~ i(treat) | id + year, 
  data = df_nonexp, vcov = "hc1"
)


# ---- Double-robust DID
DRDID::drdid(
  yname = "re", tname = "year", idname = "id", dname = "ever_treated", 
  xformla = ~ age + agesq + agecube + educ + educsq +
    marr + nodegree + black + hisp + re74 + u74,
  data = df_nonexp %>% filter(year == 75 | year == 78)
)
