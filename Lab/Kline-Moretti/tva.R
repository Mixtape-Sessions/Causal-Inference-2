# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Setup ----
library(tidyverse) # install.packages("tidyverse")
library(fixest) # install.packages("fixest")
library(DRDID) # install.packages("DRDID")
library(did) # install.packages("did")

# Data is county-by-year panel
df = read_csv("data/tva.csv")
df = df |> filter(county_has_no_missing)
glimpse(df)

# D_i = treated unit
# d_{it} = actively under going treatment (treat x post)

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Making data wide ----
# We will make our data wide (one row per county)
# I'm doing this in a bit of a verbose way
df_wide = df |>
  mutate(
    .by = county_code,
    ln_manufacturing_1920 = ln_manufacturing[year == 1920],
    ln_manufacturing_1930 = ln_manufacturing[year == 1930],
    ln_manufacturing_1940 = ln_manufacturing[year == 1940],
    ln_manufacturing_1950 = ln_manufacturing[year == 1950],
    ln_manufacturing_1960 = ln_manufacturing[year == 1960],
    ln_agriculture_1920 = ln_agriculture[year == 1920],
    ln_agriculture_1930 = ln_agriculture[year == 1930],
    ln_agriculture_1940 = ln_agriculture[year == 1940],
    ln_agriculture_1950 = ln_agriculture[year == 1950],
    ln_agriculture_1960 = ln_agriculture[year == 1960]
  ) |>
  # One row per county
  filter(year == 1940)

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Diff-in-diff ----
# TWFE Regression
feols(
  ln_manufacturing ~ i(tva * post) | year + county_code,
  data = df |> filter(year == 1960 | year == 1940),
  vcov = "HC1"
)
feols(
  ln_manufacturing ~ i(tva * post) | post + tva,
  data = df |> filter(year == 1960 | year == 1940),
  vcov = "HC1"
)

# \Delta Y on TVA dummy
feols(
  ln_manufacturing_1960 - ln_manufacturing_1940 ~ 1 + i(tva),
  data = df_wide,
  vcov = "HC1"
)

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Pre-trends ----
feols(
  ln_manufacturing_1930 - ln_manufacturing_1940 ~ 1 + i(tva),
  data = df_wide,
  vcov = "HC1"
)

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Event-study ----
df = df |>
  mutate(rel_year = ifelse(tva == 0, -10, year - 1950))

es = feols(
  ln_manufacturing ~ i(rel_year, ref = -10) | county_code + year,
  data = df,
  cluster = ~county_code
)
iplot(es)

# Pre-trends extended
est = broom::tidy(es)
est = est |>
  mutate(
    rel_year = as.numeric(str_replace(est$term, "rel_year::", ""))
  ) |>
  bind_rows(tibble(rel_year = -10, estimate = 0))

pre_trend_line = lm(
  estimate ~ rel_year,
  data = est |> filter(rel_year < -10)
)

ggplot(est) +
  geom_errorbar(
    aes(
      x = rel_year,
      ymin = estimate - 1.96 * std.error,
      ymax = estimate + 1.96 * std.error
    ),
    width = 1
  ) +
  geom_point(aes(x = rel_year, y = estimate)) +
  geom_abline(
    intercept = coef(pre_trend_line)[1],
    slope = coef(pre_trend_line)[2],
    color = "red"
  )

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Including covariates ----
df_wide$Delta_ln_manufacturing <-
  df_wide$ln_manufacturing_1960 - df_wide$ln_manufacturing_1940


## Outcome Regression ----
# Learn model of \Delta Y(0) on Xs
untreated_lm <- feols(
  Delta_ln_manufacturing ~
    agriculture_share_1930 +
      manufacturing_share_1930 +
      white_share_1930 +
      white_share_1930_sq,
  # can't use tva == 1 b/c Y_{i1960}(1) - Y_{i1940}(0)
  data = df_wide |> filter(tva == 0)
)

# Predicting Y_{i1960}(0) - Y_{i1940}(0) for the treatment group
df_wide$Delta_y0_hat <- predict(untreated_lm, newdata = df_wide)

# Treatment dummy
D <- df_wide$tva

# Observed change in ln_manufacturing
Delta_y <- df_wide$Delta_ln_manufacturing

# Predicted change in ln_manufacturing (in the absense of treatment)
Delta_y0_hat <- df_wide$Delta_y0_hat

# ≈ \hat{E}(y_i1 - y_i0 | D = 1) - \hat{E}(y_i1 - y_i0 | D = 0)
mean(Delta_y[D == 1]) - mean(Delta_y0_hat[D == 1])


# Using DRDID package
X = model.matrix(
  ~ agriculture_share_1930 +
    manufacturing_share_1930 +
    white_share_1930 +
    white_share_1930_sq,
  data = df_wide
)
DRDID::reg_did_panel(
  y1 = df_wide$ln_manufacturing_1960,
  y0 = df_wide$ln_manufacturing_1940,
  D = df_wide$tva,
  covariates = X
)


## IPW ----
# Propensity score model
logit_tva <- feglm(
  tva ~
    agriculture_share_1930 +
      manufacturing_share_1930 +
      white_share_1930 +
      white_share_1930_sq,
  data = df_wide,
  family = "logit"
)
print(logit_tva)

# Save propensity score
ps = predict(logit_tva, newdata = df_wide)

# IPW weights
w1 = D / mean(D)
w0 = 1 / mean(D) * (1 - D) * ps / (1 - ps)

# ≈ E(y_i1 - y_i0 | D = 1) - E(y_i1 - y_i0 | D = 0)
mean(w1 * Delta_y) - mean(w0 * Delta_y)
mean(Delta_y * (w1 - w0))

DRDID::ipw_did_panel(
  y1 = df_wide$ln_manufacturing_1960,
  y0 = df_wide$ln_manufacturing_1940,
  D = df_wide$tva,
  covariates = X
)


## Doubly-robust DID ----
# Normalize weights to be mean 1
w1 = w1 / mean(w1)
w0 = w0 / mean(w0)

# Doubly robust DID
mean(w1 * (Delta_y - Delta_y0_hat)) -
  mean(w0 * (Delta_y - Delta_y0_hat))

# Other way of writing it
(mean(w1 * Delta_y) - mean(w0 * Delta_y)) -
  (mean(w1 * Delta_y0_hat) - mean(w0 * Delta_y0_hat))

DRDID::drdid_panel(
  y1 = df_wide$ln_manufacturing_1960,
  y0 = df_wide$ln_manufacturing_1940,
  D = df_wide$tva,
  covariates = X
)

## Pre-trend DRDID estimates ----
DRDID::drdid_panel(
  y1 = df_wide$ln_manufacturing_1920,
  y0 = df_wide$ln_manufacturing_1940,
  D = df_wide$tva,
  covariates = X
)
DRDID::drdid_panel(
  y1 = df_wide$ln_manufacturing_1930,
  y0 = df_wide$ln_manufacturing_1940,
  D = df_wide$tva,
  covariates = X
)
DRDID::drdid_panel(
  y1 = df_wide$ln_manufacturing_1950,
  y0 = df_wide$ln_manufacturing_1940,
  D = df_wide$tva,
  covariates = X
)
DRDID::drdid_panel(
  y1 = df_wide$ln_manufacturing_1960,
  y0 = df_wide$ln_manufacturing_1940,
  D = df_wide$tva,
  covariates = X
)
DRDID::drdid_panel(
  y1 = df_wide$ln_manufacturing_1960,
  y0 = df_wide$ln_manufacturing_1940,
  D = df_wide$tva,
  covariates = cbind(rep(1, df_wide))
)

DRDID::drdid(
  yname = "ln_manufacturing",
  tname = "year",
  idname = "county_code_numeric",
  dname = "tva",
  data = df |> filter(year == 1940 | year == 1960)
)

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
# Event-study with covariates ----
df$county_code_numeric = as.numeric(factor(df$county_code))
df$g <- df$tva * 1945

# Internally, the package is estimating a bunch of 2x2 `drdid_panel` calls
# for each event-time (1920, 1930, 1950, and 1960)
#
# Note 1930 and 1960 estimate is exactly the same!!
#
(attgt <- did::att_gt(
  yname = "ln_manufacturing",
  tname = "year",
  idname = "county_code_numeric",
  gname = "g",
  xformla = ~ agriculture_share_1930 +
    manufacturing_share_1930 +
    white_share_1930 +
    white_share_1930_sq,
  base_period = "universal", # use 1940 as the reference period!
  est_method = "dr",
  data = df
))

ggdid(attgt)
