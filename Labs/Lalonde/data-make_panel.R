## data-make_panel.R -----------------------------------------------------------
## Kyle Butts, CU Boulder Economics
## 
## Take cross-sectional lalonde data and transform it into panel data

library(tidyverse)
library(fixest)
library(haven)
library(MatchIt)

# Experimental data
df_exp <- haven::read_dta("https://raw.github.com/scunning1975/mixtape/master/nsw_mixtape.dta")


# CPS data
df_cps <- haven::read_dta("https://raw.github.com/scunning1975/mixtape/master/cps_mixtape.dta")

df_nonexp <- bind_rows(df_exp |> filter(treat == 1), df_cps)

df_exp_panel <- df_exp |>
  mutate(
    id = 1:n(),
    agesq = age^2,
    agecube = age^3,
    educsq = educ^2,
    tempre74 = re74,
    tempre75 = re75,
    u74 = (re74 == 0),
    u75 = (re75 == 0)
  ) |>
  pivot_longer(
    cols = starts_with("re"),
    names_pattern = "re(.*)",
    names_to = "year", values_to = "re"
  ) |> 
  mutate(
    ever_treated = treat,
    treat = (year == 78) * treat,
    year = as.numeric(year)
  ) |>
  rename(
    re74 = tempre74,
    re75 = tempre75
  ) 

haven::write_dta(df_exp_panel, here::here("Labs/Lalonde/lalonde_exp_panel.dta"))


df_nonexp_panel <- df_nonexp |>
  mutate(
    id = 1:n(),
    agesq = age^2,
    agecube = age^3,
    educsq = educ^2,
    tempre74 = re74,
    tempre75 = re75,
    u74 = (re74 == 0),
    u75 = (re75 == 0)
  ) |>
  pivot_longer(
    cols = starts_with("re"),
    names_pattern = "re(.*)",
    names_to = "year", values_to = "re"
  ) |> 
  mutate(
    ever_treated = treat,
    treat = (year == 78) * treat,
    year = as.numeric(year)
  ) |>
  rename(
    re74 = tempre74,
    re75 = tempre75
  )

haven::write_dta(df_nonexp_panel, here::here("Labs/Lalonde/lalonde_nonexp_panel.dta"))



