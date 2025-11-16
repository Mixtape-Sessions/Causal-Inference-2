library(tidyverse)
library(here)

df <- haven::read_dta(here(
  "Labs/China-WTO/data/AEJ_ind_DID_3-digit.dta"
))

# construct key variables
df <- df |>
  mutate(
    tariff01 = ifelse(
      any(year == 2001),
      avgtariff_ind3[year == 2001] / 100,
      NA_real_
    ),
    .by = "sic3"
  ) |>
  mutate(
    hightariff = tariff01 > median(tariff01, na.rm = TRUE),
    g = ifelse(hightariff == TRUE, 2002, Inf),
    hightariff_post02 = hightariff & year > 2001,
    rel_year = if_else(hightariff, year - 2002, -Inf),
    pre_post = case_when(
      rel_year > -Inf & rel_year < 0 ~ "pre",
      rel_year >= 0 ~ "post",
      .default = "control"
    )
  ) |>
  filter(!is.na(tariff01))

df <- df |>
  mutate(
    ln_gini = log(gini),
    ln_theil = log(theil),
    ln_cv = log(cv),
    ln_mld = log(mld),
    ln_rmd = log(rmd),
    lnn = log(n),
    lnasset = log(assets),
    lnexports = log(exports),
    lnfdi = log(foreign),
    lnit = log(input_tariff),
    tariff = avgtariff_ind3 / 100
  )

df <- df |>
  arrange(sic3, year)

write_csv(df, "Labs/China-WTO/data/industry_by_year.csv")
haven::write_dta(df, "Labs/China-WTO/data/industry_by_year.dta")
