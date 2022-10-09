## lalonde-did.R ---------------------------------------------------------------
## Kyle Butts, CU Boulder Economics
## 
## Difference-in-Differences analysis of Lalonde data

library(tidyverse)
library(fixest)
library(DRDID) # devtools::install_github("pedrohcgs/DRDID")
library(haven)

# 1. Experimental data
df_exp <- haven::read_dta("https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_exp_panel.dta")

# ---- Difference-in-means - Averages
with(df_exp, {
  mean(re[year == 78 & ever_treated == 1]) -
    mean(re[year == 78 & ever_treated == 0])
})


# ---- Difference-in-means - OLS
feols(
  re ~ i(treat),
  data = df_exp |> filter(year == 78), vcov = "hc1"
)

# ---- Difference-in-Differences - Averages
with(df_exp, {
  y00 = mean(re[year == 75 & ever_treated == 0])
  y01 = mean(re[year == 78 & ever_treated == 0])
  y10 = mean(re[year == 75 & ever_treated == 1])
  y11 = mean(re[year == 78 & ever_treated == 1])

  did = (y11 - y10) - (y01 - y00)
  did
})

# ---- Difference-in-Differences - OLS
feols(
  re ~ i(treat) | id + year, 
  data = df_exp |> filter(year %in% c(75, 78)), 
  vcov = "hc1"
)

# ---- Event study and pre-trends using manually calculated averages
with(df_exp, {
  y00 = mean(re[year == 75 & ever_treated == 0])
  y01 = mean(re[year == 74 & ever_treated == 0])
  y10 = mean(re[year == 75 & ever_treated == 1])
  y11 = mean(re[year == 74 & ever_treated == 1])

  did = (y11 - y10) - (y01 - y00)
  did
})

# ---- Event study and pre-trends using OLS 

df_exp$pre = df_exp$ever_treated * (df_exp$year == 74)
df_exp$post = df_exp$ever_treated * (df_exp$year == 78)

feols(
  re ~ i(post) + i(pre) | id + year, 
  data = df_exp, 
  vcov = "hc1"
)


# 2. CPS data
df_nonexp <- haven::read_dta("https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_nonexp_panel.dta")

# ---- Difference-in-means - Averages
with(df_nonexp, {
  mean(re[year == 78 & ever_treated == 1]) -
    mean(re[year == 78 & ever_treated == 0])
})


# ---- Difference-in-means - OLS
feols(
  re ~ i(treat),
  data = df_exp |> filter(year == 78), vcov = "hc1"
)

# ---- Difference-in-Differences - Averages
with(df_nonexp, {
  y00 = mean(re[year == 75 & ever_treated == 0])
  y01 = mean(re[year == 78 & ever_treated == 0])
  y10 = mean(re[year == 75 & ever_treated == 1])
  y11 = mean(re[year == 78 & ever_treated == 1])

  did = (y11 - y10) - (y01 - y00)
  did
})

# ---- Difference-in-Differences - OLS
feols(
  re ~ i(treat) | id + year, 
  data = df_exp |> filter(year %in% c(75, 78)),
  vcov = "hc1"
)

# ---- Event study and pre-trends using manually calculated averages
with(df_nonexp, {
  y00 = mean(re[year == 75 & ever_treated == 0])
  y01 = mean(re[year == 74 & ever_treated == 0])
  y10 = mean(re[year == 75 & ever_treated == 1])
  y11 = mean(re[year == 74 & ever_treated == 1])

  did = (y11 - y10) - (y01 - y00)
  did
})

# ---- Event study and pre-trends using OLS 

df_nonexp$pre = df_nonexp$ever_treated * (df_nonexp$year == 74)
df_nonexp$post = df_nonexp$ever_treated * (df_nonexp$year == 78)

feols(
  re ~ i(post) + i(pre) | id + year, 
  data = df_nonexp, 
  vcov = "hc1"
)

# ---- Difference-in-differeces - OLS with covariates 
# age, agesq, agecube, educ, educsq, marr, nodegree, black, hisp

feols(re ~ i(post) + age + agesq + agecube + educ + educsq +
  marr + nodegree + black + hisp | ever_treated + year, 
   data = df_nonexp,
   vcov = "hc1"
)

# ---- Double-robust DID

DRDID::drdid(
  yname = "re", tname = "year", idname = "id", dname = "ever_treated", 
  xformla = ~ age + agesq + agecube + educ + educsq +
    marr + nodegree + black + hisp + re74 + u74,
  data = df_nonexp |> filter(year == 75 | year == 78)
)

