################################################################################
# name: covariates.R
# author: scott cunningham (baylor) and kyle butts (u of arkansas)
# description: illustrating heterogeneous treatment effects with respect to covariates in a panel
# last updated: may 28, 2024
################################################################################

library(tidyverse)
library(fixest)
library(DRDID)

################################################################################
# Define dgp
################################################################################
dgp <- function() { 
  df = 
    expand_grid(
      state = 1:40, id = 1:25, year = 1990:1991
    ) |>  
    # Unique worker id
    arrange(state, id, year) |>
    mutate(.by = c(state, id), id = cur_group_id())
  
  # Unit characteristics
  df = df |> 
    # Covariates
    mutate(.by = id,
      age = rnorm(1, 35, 10),
      gpa = rnorm(1, 2, 0.5),
      # Treatment probability increases with age and decrease with gpa
      propensity = 0.3 + 0.3 * (age > 0) + 0.2 * (gpa > 0),
      treat = as.numeric(runif(1) < propensity[1])
    ) |>
    mutate(
      # Center covariates
      age = age - mean(age),
      gpa = gpa - mean(gpa),

      # Generate Polynomial and Interaction Terms
      age_sq = age^2,
      gpa_sq = gpa^2,
      interaction = age * gpa, 
    ) 

  df = df |> 
    mutate(
      post = as.numeric(year == 1991),
      unit_fe = 40000 + 10000 * (1 - treat),
      e = rnorm(n(), 0, 1500),
      
      # Generate Potential Outcomes with Baseline and Year Difference
      # NOTE: The change in coefficients on age and gpa generate trends in outcomes.
	    # If two units have the same age and same gpa, then they will have the same change in y0.
      y0 = if_else(
        year == 1990, 
        unit_fe + 100 * age + 1000 * gpa + e, # 1990
        unit_fe + 200 * age + 2000 * gpa + e  # 1991
      ), 
      
      # Covariate-based treatment effect heterogeneity
      y1 = if_else(
        year == 1990, 
        y0,                                # 1990 (no anticipation)
        y0 + 1000 + 100 * age + 500 * gpa  # 1991
      ), 

      # Unit-specific treatment effect
      delta = y1 - y0,

      # Generate observed outcome based on treatment assignment
      earnings = if_else(post == 1 & treat == 1, y1, y0)
    )

  return(df)
}

df <- dgp()
(att <- df |> filter(treat == 1, year == 1991) |> pull(delta) |> mean())

df = arrange(df, id, year) # MUST BE IN ORDER, so Y_i1 and Y_i0 match i !!!!!!!!
y_i1 = df |> filter(year == 1991) |> pull(earnings)
y_i0 = df |> filter(year == 1990) |> pull(earnings)
D = df |> filter(year == 1990) |> pull(treat)
X = model.matrix(~ age + gpa + age_sq + gpa_sq, df |> filter(year == 1990))

DRDID::reg_did_panel(
  y1 = y_i1, y0 = y_i0, D = D, covariates = X
)
DRDID::ipw_did_panel(
  y1 = y_i1, y0 = y_i0, D = D, covariates = X
)
DRDID::drdid_panel(
  y1 = y_i1, y0 = y_i0, D = D, covariates = X
)
feols(
  earnings ~ i(treat * post) + i(year, age) + i(year, gpa) + i(year, age_sq) + i(year, gpa_sq) | id + year, 
  data = df
)

