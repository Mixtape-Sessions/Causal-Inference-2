#*******************************************
# R Simulation: Conditional Parallel Trends
# Example: Effect of Title X clinics on birth rates
# Illustrating subtlety of choosing event-study baseline
#*******************************************

# Load required packages
library(did)      # Callaway & Sant'Anna package
library(ggplot2)  # For plotting
library(dplyr)    # For data manipulation
library(fixest)   # For two-way fixed effects (feols)
library(data.table)

# Set seed for reproducibility
set.seed(12345)

# Step 1: Setup simulation parameters
county_id <- 1:500
n_counties <- length(county_id)

# Create county-level data
county_data <- data.frame(
  county_id = county_id,
  # Define urban (1) vs. rural (0)
  urban = as.numeric(runif(n_counties) < 0.5)
)

# Define treatment assignment (imbalanced, mostly urban)
county_data$treated <- (county_data$urban == 1 & runif(n_counties) < 0.7) | 
  (county_data$urban == 0 & runif(n_counties) < 0.3)

# Define treatment timing: treated counties treated at year 6, untreated = 0
county_data$treat_date <- ifelse(county_data$treated, 6, 0)

# Expand to panel data (10 years)
panel_data <- county_data[rep(seq_len(n_counties), each = 10), ]
panel_data$year <- rep(1:10, times = n_counties)

# Define pre/post treatment periods
panel_data$post <- panel_data$year >= 6

# Step 2: Generate potential outcomes (Revised to shrink pre-trends)
# Initialize trend variable
panel_data$trend <- NA

# Smaller urban decline, nearly flat rural increase
panel_data$trend[panel_data$year == 1] <- -0.15 * panel_data$urban[panel_data$year == 1] + 
  0.1 * (1 - panel_data$urban[panel_data$year == 1])
panel_data$trend[panel_data$year == 2] <- -0.25 * panel_data$urban[panel_data$year == 2] + 
  0.1 * (1 - panel_data$urban[panel_data$year == 2])
panel_data$trend[panel_data$year == 3] <- -0.15 * panel_data$urban[panel_data$year == 3] + 
  0.1 * (1 - panel_data$urban[panel_data$year == 3])
panel_data$trend[panel_data$year == 4] <- -0.1 * panel_data$urban[panel_data$year == 4] + 
  0.1 * (1 - panel_data$urban[panel_data$year == 4])
panel_data$trend[panel_data$year == 5] <- -0.1 * panel_data$urban[panel_data$year == 5] + 
  0.1 * (1 - panel_data$urban[panel_data$year == 5])
panel_data$trend[panel_data$year == 6] <- -0.5 * panel_data$urban[panel_data$year == 6] + 
  0.1 * (1 - panel_data$urban[panel_data$year == 6])
panel_data$trend[panel_data$year == 7] <- -1.0 * panel_data$urban[panel_data$year == 7] + 
  0.1 * (1 - panel_data$urban[panel_data$year == 7])
panel_data$trend[panel_data$year == 8] <- -1.5 * panel_data$urban[panel_data$year == 8] + 
  0.1 * (1 - panel_data$urban[panel_data$year == 8])
panel_data$trend[panel_data$year == 9] <- -2.0 * panel_data$urban[panel_data$year == 9] + 
  0.1 * (1 - panel_data$urban[panel_data$year == 9])
panel_data$trend[panel_data$year == 10] <- -2.5 * panel_data$urban[panel_data$year == 10] + 
  0.1 * (1 - panel_data$urban[panel_data$year == 10])

# Generate county-level fixed effects (increasing cross-sectional variance)
county_fe <- rnorm(n_counties, mean = 0, sd = 2)
panel_data$county_fe <- rep(county_fe, each = 10)

# Generate serially correlated errors within counties
panel_data <- panel_data %>%
  group_by(county_id) %>%
  mutate(
    u = c(rnorm(1, 0, 1), numeric(9))  # Placeholder for first value
  ) %>%
  ungroup()

# Complete the serially correlated errors
for (i in 1:n_counties) {
  county_indices <- which(panel_data$county_id == i)
  
  for (j in 2:10) {
    idx <- county_indices[j]
    prev_idx <- county_indices[j-1]
    panel_data$u[idx] <- 0.7 * panel_data$u[prev_idx] + rnorm(1, 0, 1)
  }
}

# Potential outcome y0 now includes county FE and serially correlated errors
panel_data$y0 <- 15 + panel_data$county_fe + panel_data$trend * panel_data$year + panel_data$u

# Clearly positive treatment effect
panel_data$y1 <- panel_data$y0 + panel_data$post * panel_data$treated * (panel_data$year - 5) * 0.6

# Observed outcome
panel_data$birth_rate <- panel_data$treated * panel_data$y1 + (1 - panel_data$treated) * panel_data$y0

# Prepare data for did package
# Convert data frame to data.table for efficiency
dt <- data.table(panel_data)

# Step 3: Run the did analysis (equivalent to csdid in Stata)
# Long-gap: baseline fixed at T-1 (equivalent to long2 option in csdid)
did_result <- att_gt(
  yname = "birth_rate",
  tname = "year",
  idname = "county_id",
  gname = "treat_date",
  data = dt,
  control_group = "notyettreated",
  base_period = "universal", # Universal base period (similar to long2)
  anticipation = 0,
  est_method = "dr", # Doubly-robust method (default)
  panel = TRUE,
  allow_unbalanced_panel = FALSE,
  bstrap = TRUE,
  cband = TRUE,
  clustervars = "county_id"
)

# Print summary
print("Summary of DiD results (without covariates):")
summary(did_result)

# Event study plot
event_study <- aggte(did_result, type = "dynamic")
print("Event study results (without covariates):")
summary(event_study)

# Plot event study
es_plot1 <- ggdid(event_study, title = "Long-gap (T-1 baseline): Event Study")
print(es_plot1)

# Step 4: Adding urban covariate (equivalent to dripw method)
did_result_urban <- att_gt(
  yname = "birth_rate",
  tname = "year",
  idname = "county_id",
  gname = "treat_date",
  xformla = ~ urban,
  data = dt,
  control_group = "notyettreated",
  base_period = "universal", # Universal base period (similar to long2)
  anticipation = 0,
  est_method = "ipw", # IPW method (similar to dripw in Stata)
  panel = TRUE,
  allow_unbalanced_panel = FALSE,
  bstrap = TRUE,
  cband = TRUE,
  clustervars = "county_id"
)

# Print summary
print("Summary of DiD results (with urban covariate):")
summary(did_result_urban)

# Event study plot with urban covariate
event_study_urban <- aggte(did_result_urban, type = "dynamic")
print("Event study results (with urban covariate):")
summary(event_study_urban)

# Plot event study with urban covariate
es_plot2 <- ggdid(event_study_urban, title = "Long-gap w/ urban covariate: Event Study")
print(es_plot2)

# Step 5 (Optional): Two-way fixed effects comparison
# This is equivalent to reghdfe in Stata
twfe_model <- feols(birth_rate ~ i(year, treated, ref = 5) | county_id + year, 
                    data = dt, 
                    cluster = "county_id")

# Print summary of TWFE model
print("Summary of Two-way Fixed Effects Model:")
summary(twfe_model)

# Save plots if needed
# ggsave("event_study_plot.png", es_plot1, width = 10, height = 6)
# ggsave("event_study_plot_urban.png", es_plot2, width = 10, height = 6)