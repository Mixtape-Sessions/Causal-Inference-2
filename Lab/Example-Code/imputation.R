library(tidyverse)
library(fixest)
library(did2s)

# ACS Data from 2008 - 2021
# Medicare expansion in ACA Expansion
df <- read_csv("https://raw.githubusercontent.com/hollina/stacked-did-weights/main/data/acs1860_unins_2008_2021.csv")
head(df)

# Create treatment dummy and event-study dummies
df = df |>
  mutate(
    rel_year = if_else(is.na(adopt_year), -1, year - adopt_year),
    treat    = rel_year >= 0
  )

# Manual
fs = feols(
  unins ~ 0 | statefip + year, 
  data = df |> filter(treat == 0)
)
df$y0_hat = predict(fs, newdata = as.data.frame(df))
df$te_hat = df$unins - df$y0_hat

feols(
  te_hat ~ i(treat, ref = FALSE), 
  data = df
)
ss = feols(
  te_hat ~ i(rel_year), 
  data = df
)
iplot(ss)

# With `did2s` for correct standard errors
est = did2s::did2s(
  data = df,
  yname = "unins",
  first_stage = ~ 0 | statefip + year,
  second_stage = ~ i(rel_year), 
  treatment = "treat",
  cluster_var = "statefip"
)
iplot(est)



