################################################################################
# name: abortion_jhr.R
# author: scott cunningham (baylor)
# description: illustrating callaway, goodman-bacon and sant'anna "continuous diff-in-diff" paper with abortion clinic closures from Lindo, Myers, Schlosser and Cunningham
################################################################################

library(contdid)
# https://github.com/bcallaway11/contdid
library(haven)
library(dplyr)
library(tidyr)  

# Set working directory
setwd("/Users/scott_cunningham/Documents/Causal-Inference-2/Lab/abortion clinic")

# Load data
# Use 3+ years to give more pre-treatment periods
df <- read_dta("abortion_jhr.dta") %>%
  mutate(
    travel_distance = travel_distance * 100,
    id = fips_code,
    time_period = year,
    Y = aborttotal
  ) %>%
  filter(time_period %in% c(2012, 2013, 2014))  # 3 years instead of 2

# Debug: Check the data structure before creating treatment variables
cat("Original data check:\n")
cat("Time periods:", sort(unique(df$time_period)), "\n")
cat("Number of units per period:\n")
table(df$time_period)
cat("Data dimensions:", dim(df), "\n")

# Create treatment assignment
epsilon <- 10

travel_wide <- df %>%
  select(id, time_period, travel_distance) %>%
  # Keep the same logic - dose calculated from 2013 to 2014 change
  filter(time_period %in% c(2013, 2014)) %>%  # This is still correct
  pivot_wider(
    names_from = time_period, 
    values_from = travel_distance,
    names_prefix = "travel_"
  ) %>%
  filter(!is.na(travel_2013) & !is.na(travel_2014)) %>%
  mutate(
    dose_change = travel_2014 - travel_2013,
    treated = dose_change > epsilon,
    D = ifelse(treated, dose_change, 0),
    G = ifelse(treated, 2014, 0)  # Treatment starts 2014, never-treated = 0
  ) %>%
  select(id, D, G)

# Debug: Check treatment assignment
cat("\nTreatment assignment:\n")
table(travel_wide$G, useNA = "ifany")
cat("Units by treatment status:\n")
travel_wide %>%
  group_by(G) %>%
  summarise(n = n(), min_D = min(D), max_D = max(D)) %>%
  print()

# Merge back
df <- df %>%
  left_join(travel_wide, by = "id")

# Debug: Check final data structure that contdid will see
cat("\nFinal data for contdid:\n")
cat("Data dimensions:", dim(df), "\n")
cat("Time periods:", sort(unique(df$time_period)), "\n")
cat("Treatment groups (G):", sort(unique(df$G)), "\n")

# Check that each G group has the expected time periods
df %>%
  group_by(G) %>%
  summarise(
    time_periods = paste(sort(unique(time_period)), collapse = ","),
    n_periods = n_distinct(time_period),
    n_units = n_distinct(id)
  ) %>%
  print()

# Clean the data more thoroughly before running contdid
df_clean <- df %>%
  # Remove any rows with missing key variables
  filter(!is.na(Y), !is.na(D), !is.na(G), !is.na(time_period), !is.na(id)) %>%
  # Remove any extreme outliers that might cause numerical issues
  filter(Y >= 0, Y < 50000) %>%  # Remove extremely large abortion counts
  filter(D >= 0, D < 500) %>%    # Remove extremely large distance changes
  # Ensure proper data types
  mutate(
    id = as.integer(id),
    time_period = as.integer(time_period),
    Y = as.numeric(Y),
    D = as.numeric(D),
    G = as.numeric(G)
  )

# Check what we have after cleaning
cat("Cleaned data summary:\n")
cat("Dimensions:", dim(df_clean), "\n")
cat("Y range:", range(df_clean$Y), "\n") 
cat("D range:", range(df_clean$D), "\n")
cat("Any missing values?", any(is.na(df_clean[c("Y", "D", "G", "time_period", "id")])), "\n")

# Check treatment groups again
df_clean %>%
  group_by(G) %>%
  summarise(
    n_obs = n(),
    n_units = n_distinct(id),
    n_periods = n_distinct(time_period),
    y_mean = mean(Y),
    d_mean = mean(D)
  ) %>%
  print()

# Recode time periods to match Brant's format
df_fixed <- df_clean %>%
  mutate(
    time_period = case_when(
      time_period == 2012 ~ 1,
      time_period == 2013 ~ 2, 
      time_period == 2014 ~ 3,
      TRUE ~ time_period
    ),
    # Also fix the treatment timing to match
    G = case_when(
      G == 0 ~ 0,
      G == 2014 ~ 3,  # Treatment starts in period 3 (was 2014)
      TRUE ~ G
    )
  )

# Check the recoded data
cat("Recoded time periods:\n")
table(df_fixed$time_period)
cat("Recoded treatment groups:\n") 
table(df_fixed$G)

# Now try contdid with recoded periods
cd_result <- cont_did(
  yname = "Y",
  tname = "time_period",
  idname = "id",
  dname = "D", 
  gname = "G",
  data = df_fixed,
  target_parameter = "level",
  aggregation = "dose",
  treatment_type = "continuous",
  control_group = "notyettreated",
  biters = 0
)

summary(cd_result)

# Plot the dose-response relationship
ggcont_did(cd_result, type = "att") +
  labs(
    title = "ATT(d): Effect by Distance Increase", 
    x = "Distance Increase (miles)",
    y = "Effect on Abortion Count"
  )

# For rates instead of counts:
df_fixed <- df_fixed %>%
  mutate(
    Y_rate = Y / (pop / 1000)  # Abortions per 1000 population
  )

cd_result_rate <- cont_did(
  yname = "Y_rate",  # Use rate instead of count
  tname = "time_period",
  idname = "id",
  dname = "D",
  gname = "G", 
  data = df_fixed,
  target_parameter = "level",
  aggregation = "dose",
  treatment_type = "continuous",
  control_group = "notyettreated",
  biters = 0
)

summary(cd_result_rate)

# Plot the dose-response relationship for rates
ggcont_did(cd_result_rate, type = "att") +
  labs(
    title = "ATT(d): Effect by Distance Increase", 
    x = "Distance Increase (miles)",
    y = "Effect on Abortion Rate"
  )

# Check treatment assignment
table(df_fixed$G)
summary(df_fixed$D[df_fixed$G > 0])  # Dose among treated

# Count unique counties by treatment status
df_fixed %>% 
  group_by(id) %>% 
  summarise(G = first(G)) %>% 
  count(G)

