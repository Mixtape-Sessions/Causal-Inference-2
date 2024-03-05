#-------------------------------------------------------------------------------
# name: ddd2.R
# author: scott cunningham (baylor), kyle butts (arkansas)
# description: simulation for triple diff with potential outcomes but using a biased did and an unbiased triple diff
# last updated: march 5, 2024
#-------------------------------------------------------------------------------

# %%
#| warning: false
library(tidyverse)
library(fixest)
library(glue)

#' ## Simulate data:
# %%
set.seed(20200403)


df <- expand_grid(
  # 40 states
  state = 1:40,
  # 50 cities per state
  city = 1:50,
  # Three groups per city: men (1), married women (2), and older women (3)
  worker = 1:3,
  # 10 years
  year = 2010:2020
)

# Generate treatment groups -- 20 states that adopted the maternity benefit policy
df$experimental <- as.numeric(df$state <= 20)
# Define the after period (post-2015)
df$after <- as.numeric(df$year >= 2015)

# Unique city id and worker id
df$city <- fixest::to_integer(df$state, df$city)
df$id <- fixest::to_integer(df$state, df$city, df$worker)

# %%
# Baseline earnings in 2010 with different values for experimental and non-experimental states
df$baseline <- case_when(
  df$worker == 1 ~ 50000,
  df$worker == 2 ~ 45000,
  df$worker == 3 ~ 40000
)

# Adjust baseline for experimental states.  Experimental states will be on a different trend.
df$baseline <- if_else(df$experimental == 1, df$baseline * 1.5, df$baseline)

# Create counter for the annual wage growth for Y(0) below
df$year_diff <- df$year - 2010

# Setting trends for states and groups
df$state_trend <- if_else(df$experimental == 1, 1000, 1500)
df$group_trend <- if_else(df$worker == 2, 500, 1000)

# Annual wage growth for Y(0) incorporating state and group trends
df$error <- rnorm(nrow(df), mean = 0, sd = 1500)
df$y0 <- df$baseline + df$state_trend * df$year_diff + df$group_trend * df$year_diff + df$error

# Define Y(1) with an ATT of -$5000 for married women in experimental states post-2015
df$treat <- (df$experimental == 1 & df$worker == 2 & df$after == 1)
df$y1 <- df$y0 - 5000 * df$treat

# Treatment effect
df$delta <- df$y1 - df$y0

# Final earnings using switching equation
df$earnings <- df$treat * df$y1 + (1 - df$treat) * df$y0


#' ## Biased DiD Case 1: married women to married women but in different states
#' ### Calculating the 8 averages
# %%
# 1. After, Married, Experimental
avg_wage_ame <- with(df, mean(earnings[after == 1 & experimental == 1 & worker == 2]))

# 2. Before, Married, Experimental
avg_wage_bme <- with(df, mean(earnings[after == 0 & experimental == 1 & worker == 2]))

# 3. After, Single Men and Older Women, Experimental
avg_wage_asoe <- with(df, mean(earnings[after == 1 & experimental == 1 & worker != 2]))

# 4. Before, Single Men and Older Women, Experimental
avg_wage_bsoe <- with(df, mean(earnings[after == 0 & experimental == 1 & worker != 2]))

# 5. After, Married, Non-Experimental
avg_wage_amn <- with(df, mean(earnings[after == 1 & experimental == 0 & worker == 2]))

# 6. Before, Married, Non-Experimental
avg_wage_bmn <- with(df, mean(earnings[after == 0 & experimental == 0 & worker == 2]))

# 7. After, Single Men and Older Women, Non-Experimental
avg_wage_ason <- with(df, mean(earnings[after == 1 & experimental == 0 & worker != 2]))

# 8. Before, Single Men and Older Women, Non-Experimental
avg_wage_bson <- with(df, mean(earnings[after == 0 & experimental == 0 & worker != 2]))

# %%
# Calculate the DiD estimate
DiD_case1 <- (avg_wage_ame - avg_wage_bme) - (avg_wage_amn - avg_wage_bmn)
print(paste0(
  "Difference-in-differences estimate: ", round(DiD_case1, 2)
))

# Regression event study for biased DID.
df$treated1 <- case_when(
  df$experimental == 1 & df$worker == 2 ~ 1,
  df$worker == 2 ~ 0,
  .default = NA_integer_
)

# Same bias
feols(
  earnings ~ i(treated1 * after) | treated1 + after,
  df,
  cluster = ~state
)

# Biased event study too
df$treated1_x_year <- if_else(
  df$treated1 == 1, df$year * df$treated1, 2014
)
es_treated1 <- feols(
  earnings ~ i(treated1_x_year, ref = 2014) | year + treated1,
  df,
  cluster = ~state
)

iplot(es_treated1)


#' ## Biased DiD Case 2: Placebo DiD using Single Men and Older Women
# %%
DiD_placebo <- (avg_wage_asoe - avg_wage_bsoe) - (avg_wage_ason - avg_wage_bson)
print(paste0(
  "Placebo Difference-in-differences estimate: ", round(DiD_placebo, 2)
))

# Create treatment indicator for Single Men and Older Women in experimental states
df$treated_placebo <- case_when(
  df$experimental == 1 & df$worker %in% c(1, 3) ~ 1,
  df$worker %in% c(1, 3) ~ 0,
  .default = NA_integer_
)

# Run the regression for the Placebo DiD
feols(
  earnings ~ i(treated_placebo * after) | treated_placebo + after,
  df,
  cluster = ~state
)

# Run the event study for Placebo DiD to illustrate the bias
df$placebo_x_year <- if_else(
  df$treated_placebo == 1, df$year * df$treated_placebo, 2014
)
es_placebo <- feols(
  earnings ~ i(placebo_x_year, ref = 2014) | year + treated_placebo,
  df,
  cluster = ~state
)

# Plot the event study results for Placebo DiD
iplot(es_placebo)

#' ## Unbiased triple differences
# %%

# Calculate the DiD for married women and control group in experimental states
DiD_married_exp <- (avg_wage_ame - avg_wage_bme)
DiD_control_exp <- (avg_wage_asoe - avg_wage_bsoe)

# Calculate the DiD for married women and control group in non-experimental states
DiD_married_nonexp <- (avg_wage_amn - avg_wage_bmn)
DiD_control_nonexp <- (avg_wage_ason - avg_wage_bson)

# Calculate the Triple Difference estimate
TripleDiff <- (DiD_married_exp - DiD_control_exp) - (DiD_married_nonexp - DiD_control_nonexp)

print(paste0(
  "Triple Difference Estimate: ", round(TripleDiff, 2)
))

# Triple Diff regression
# %%
df$married_women <- as.numeric(df$worker == 2)

feols(
  earnings ~ i(after * experimental * married_women) +
    i(after) + i(experimental) + i(married_women) +
    i(after * experimental) + i(after * married_women) + i(experimental * married_women),
  data = df, cluster = ~state
)

with(df, mean(delta[experimental == 1 & worker == 2 & after == 1]))


# Triple diff event study
# %%
es_triple <- feols(
  earnings ~ i(year, experimental * married_women) +
    i(year) + i(experimental) + i(married_women) +
    i(year, experimental) + i(year, married_women) + i(experimental * married_women),
  data = df, cluster = ~state
)

iplot(es_triple)


#' ## Plotting all of the event studies
# %%
library(broom)

pts_treated1 <- es_treated1 |>
  broom::tidy() |>
  mutate(
    estimator = "Biased DD",
    year = as.numeric(str_replace(term, "treated1_x_year::", ""))
  )

pts_placebo <- es_placebo |>
  broom::tidy() |>
  mutate(
    estimator = "Biased Placebo DD",
    year = as.numeric(str_replace(term, "placebo_x_year::", ""))
  )

pts_triple <- es_triple |>
  broom::tidy() |>
  filter(
    str_detect(term, "year::.*:experimental \\* married_women")
  ) |>
  mutate(
    estimator = "Unbiased DDD",
    year = as.numeric(str_extract(term, "year::(.*):experimental", group = 1))
  )

pts <- bind_rows(pts_treated1, pts_placebo, pts_triple)

# %%
ggplot(pts) +
  geom_hline(yintercept = 0) + 
  geom_vline(xintercept = 2014.5, linetype = "dashed") + 
  geom_point(
    aes(x = year, y = estimate, color = estimator), 
    size = 2
  ) +
  geom_errorbar(
    aes(
      x = year, color = estimator,
      ymin = estimate - 1.96 * std.error, 
      ymax = estimate + 1.96 * std.error
    ), 
    width = 0.2
  ) + 
  scale_x_continuous(breaks = 2010:2020) + 
  scale_color_viridis_d(
  ) + 
  labs(
    x = NULL, y = "Treatment Effect Estimate",
    color = NULL,
    title = "Two Biased DiDs vs. Unbiased Triple Diff",
    subtitle = "Illustrating Parallel Bias"
  ) + 
  theme_bw(base_size = 16) + 
  theme(
    legend.position = "bottom",
    legend.key.spacing.x = unit(16, "pt"),
    legend.box.background = element_rect()
  )


