library(tidyverse)
library(fixest)
library(marginaleffects)
library(modelsummary)

df <- read_csv("https://raw.githubusercontent.com/hollina/stacked-did-weights/main/data/acs1860_unins_2008_2021.csv")

#' The user will provide functions:
#' 
#' 1. `sub_exp` accepts an event `e` and produces a vector. The
#' vector takes values:
#'    - 0 denotes all omitted observations, 
#'    - 1 denotes the clean control observations, 
#'    - 2 denotes the pre-treatment observations for the treated group, and
#'    - 3 denotes the post-treatment observations for the treated group
#' 
#' 2. `est_fs` takes the data and the result of `sub_exp` and estimates
#' a model for $y_{it}(0)$ using clean control and pre-treatment obs.
#' 
# %%
sub_exp <- function(df, e, kappa_pre = 3, kappa_post = 2) {
  balance_event_time <- between(df$year, e - kappa_pre, e + kappa_post)
  clean_control <- is.na(df$adopt_year) | (df$adopt_year > e + kappa_post)
  treat <- (df$adopt_year == e)
  post <- (df$year >= df$adopt_year)

  # MORE FILTERING HERE (e.g. bordering counties, same census region, etc.)

  case_when(
    !balance_event_time ~ 0L,
    clean_control       ~ 1L, 
    treat & !post       ~ 2L, 
    treat & post        ~ 3L,
    .default = 0L
  )
}

est_fs <- function(df, exp) {
  est <- feols(
    unins ~ 0 | st + year, 
    data = df[exp %in% c(1,2), ]
  )
  return(est)
}

#' For each event, 
#' 
#' 1. Get treat and clean controls using `sub_exp`
#' 2. Estimate $y_{it}(0)$ using $d_{it} = 0$
#' 3. Impute $y_{it}(0)$ for treated units
# %%
events <- unique(na.omit(df$adopt_year))
events <- events[order(events)]
kappa_pre = 3; kappa_post = 2
for (e in events) {
  # Skip e if doesn't have enough pre-/post-periods
  valid_e <- c(e - kappa_pre, e + kappa_post) %in% min(df$year):max(df$year)
  if (!all(valid_e)) {
    next
  } 

  # Get treat and clean controls
  exp_e = sub_exp(df, e, kappa_pre, kappa_post)

  # Estimate y_{it}(0) using pre-treatment and never-treated
  est_e = est_fs(df, exp_e)

  # impute y_{it}(0) for treated group
  df[exp_e == c(2,3), "y0_hat"] = 
    predict(est_e, newdata = df )[exp_e == c(2,3)]
}

#' Second stage: get treatment effect coefficients
# %% 
df$te_hat = df$unins - df$y0_hat
df$event_time = with(df, if_else(is.na(adopt_year), -1, year - adopt_year))
est = feols(
  te_hat ~ 0 + i(event_time),
  df[!is.na(df$te_hat), ]
)

# %% 
coefplot(est)

# %% 
hypotheses(
  est,
  "(`event_time::0` + `event_time::1` + `event_time::2`) / 3 = 0",
  df = 50
)
