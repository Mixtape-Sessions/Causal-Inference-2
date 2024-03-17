# %%
#| warning: false
library(tidyverse)

raw <- haven::read_dta("data/raw.dta")

df <- raw |>
  select(
    state_fips                 = fipstat,
    county_fips                = fipcnty,
    tva,
    ln_agriculture_1920        = lnagr20,
    ln_agriculture_1930        = lnagr30,
    ln_agriculture_1940        = lnagr40,
    ln_agriculture_1950        = lnagr50,
    ln_agriculture_1960        = lnagr60,
    ln_manufacturing_1920      = lnmanuf20,
    ln_manufacturing_1930      = lnmanuf30,
    ln_manufacturing_1940      = lnmanuf40,
    ln_manufacturing_1950      = lnmanuf50,
    ln_manufacturing_1960      = lnmanuf60,
    ln_max_elevation           = lnelevmax,
    ln_range_elevation         = lnelevrang,
    ln_county_area             = lnarea,
    ln_population_1920         = lnpop20,
    ln_population_1920sq       = lnpop20sq,
    ln_population_1930         = lnpop30,
    ln_population_1930sq       = lnpop30sq,
    agriculture_share_1920     = agrshr20,
    agriculture_share_1920_sq  = agrshr20sq,
    agriculture_share_1930     = agrshr30,
    agriculture_share_1930_sq  = agrshr30sq,
    manufacturing_share_1920   = manufshr20,
    manufacturing_share_1930   = manufshr30,
    ln_avg_wage_1920           = lnwage20,
    ln_avg_wage_1930           = lnwage30,
    ln_employment_1920         = lnemp20,
    ln_employment_1930         = lnemp30,
    urban_share_1920           = urbshare20,
    urban_share_1930           = urbshare30,
    ln_avg_farm_value_1920     = lnfaval20,
    ln_avg_farm_value_1930     = lnfaval30,
    ln_med_housing_value_1930  = lnmedhsval30,
    ln_med_rent_1930           = lnmedrnt30,
    white_share_1920           = white20,
    white_share_1920_sq        = white20sq,
    white_share_1930           = white30,
    white_share_1930_sq        = white30sq,
    unemployment_rate_1930     = urate30,
    foreign_born_share_1920    = fbshr20,
    foreign_born_share_1930    = fbshr30,
    pct_with_radio_1930        = PRADIO30
  )

df = df |>
  mutate(county_code = sprintf("%02d%03d", state_fips, county_fips)) |>
  select(-state_fips, -county_fips)

#' Pivot back into panel data form
# %%
make_longer <- function(df, var) {
  df |>
    select(county_code, starts_with(var)) |>
    pivot_longer(
      starts_with(var),
      names_pattern = ".*_([0-9]{4,})",
      values_to = var,
      names_to = "year",
      names_transform = list(
        year = readr::parse_number
      )
    )
}

# %%  
df = make_longer(df, "ln_agriculture") |> 
  full_join(
    make_longer(df, "ln_manufacturing"), 
    by = c("county_code", "year")
  ) |> 
  full_join(
    df |>
      select(!starts_with("ln_agriculture")) |>
      select(!starts_with("ln_manufacturing")),
    by = "county_code"
  )

df <- df |>
  select(county_code, year, tva, ln_agriculture, ln_manufacturing, everything()) |>
  mutate(
    treat = as.numeric(tva * year > 1940), 
    post = as.numeric(year > 1940)
  ) |>
  # No NAs for outcome variable
  filter( 
    !is.na(ln_agriculture), !is.na(ln_manufacturing), .by = county_code
  ) |> 
  # Make balanced
  filter(n() == 5, .by = county_code) |>
  # Dummy for no missing covariates
  mutate(
    county_has_no_missing = 
      !any(is.na(agriculture_share_1920)) &
      !any(is.na(agriculture_share_1930)) &
      !any(is.na(manufacturing_share_1920)) &
      !any(is.na(manufacturing_share_1930)) &
      !any(is.na(ln_avg_farm_value_1920)) &
      !any(is.na(ln_avg_farm_value_1930)) &
      !any(is.na(white_share_1920)) &
      !any(is.na(white_share_1930)),
    .by = county_code
  ) 
  
df = df |> 
  select(
    county_code, year, tva, treat, post, ln_agriculture, ln_manufacturing,
    agriculture_share_1920, agriculture_share_1930, 
    manufacturing_share_1920, manufacturing_share_1930, 
    ln_avg_farm_value_1920, ln_avg_farm_value_1930, 
    white_share_1920, white_share_1930, white_share_1920_sq, white_share_1930_sq,
    county_has_no_missing
  )

# %% 
write_csv(df, "data/tva.csv")
haven::write_dta(df, "data/tva.dta")
