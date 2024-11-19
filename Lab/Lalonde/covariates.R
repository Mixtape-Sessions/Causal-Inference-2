# Set the seed for reproducibility
set.seed(20200403)

# Load necessary packages
devtools::install_github("pedrohcgs/DRDID")
library(DRDID) 
library(ggplot2)
library(dplyr)
library(fixest)

# Set the seed for reproducibility
set.seed(20200403)

# Load necessary packages
# Install 'drdid' if you haven't already
if (!require(drdid)) {
  install.packages("drdid")
  library(drdid)
} else {
  library(drdid)
}
library(ggplot2)
library(dplyr)

# Define the data-generating process (DGP)
dgp <- function() {
  n_states <- 40
  n_workers_per_state <- 25
  n_obs <- n_states * n_workers_per_state
  
  # Create states and workers
  state <- rep(1:n_states, each = n_workers_per_state)
  id <- 1:n_obs
  worker <- runif(n_obs, 0, 5)
  
  # Generate baseline covariates
  age <- rnorm(n_obs, 35, 10)
  gpa <- rnorm(n_obs, 2.0, 0.5)
  
  # Center covariates
  age <- age - mean(age)
  gpa <- gpa - mean(gpa)
  
  # Generate polynomial and interaction terms
  age_sq <- age^2
  gpa_sq <- gpa^2
  interaction <- age * gpa
  
  # Treatment probability
  propensity <- 0.3 + 0.3 * (age > 0) + 0.2 * (gpa > 0)
  treat <- as.numeric(runif(n_obs) < propensity)
  
  # Expand data to two periods
  df <- data.frame(
    id = rep(id, each = 2),
    state = rep(state, each = 2),
    worker = rep(worker, each = 2),
    age = rep(age, each = 2),
    gpa = rep(gpa, each = 2),
    age_sq = rep(age_sq, each = 2),
    gpa_sq = rep(gpa_sq, each = 2),
    interaction = rep(interaction, each = 2),
    propensity = rep(propensity, each = 2),
    treat = rep(treat, each = 2),
    year = rep(c(1990, 1991), times = n_obs)
  )
  
  # Post-treatment indicator
  df$post <- ifelse(df$year == 1991, 1, 0)
  
  # Fixed effects
  df$unit_fe <- 40000 + 10000 * (df$treat == 0)
  
  # Potential outcomes
  df$e <- rnorm(nrow(df), 0, 1500)
  df$y0 <- ifelse(
    df$year == 1990,
    df$unit_fe + 100 * df$age + 1000 * df$gpa + df$e,
    df$unit_fe + 1000 + 200 * df$age + 2000 * df$gpa + df$e
  )
  
  # Covariate-based treatment effect heterogeneity
  df$y1 <- df$y0
  df$y1[df$year == 1991] <- df$y0[df$year == 1991] + 1000 + 100 * df$age[df$year == 1991] + 500 * df$gpa[df$year == 1991]
  
  # Treatment effect
  df$delta <- df$y1 - df$y0
  
  # Observed outcomes
  df$earnings <- df$y0
  df$earnings[df$post == 1 & df$treat == 1] <- df$y1[df$post == 1 & df$treat == 1]
  
  return(df)
}

# Define the simulation function
sim <- function() {
  df <- dgp()
  
  # True ATT
  att <- mean(df$delta[df$treat == 1 & df$post == 1])
  
  # Prepare covariates
  covariates <- df[, c("age", "gpa", "age_sq", "gpa_sq")]
  
  # DRDID estimator with Doubly Robust IPW (DR-IPW)
  result_dr <- drdid(
    y = df$earnings,
    post = df$post,
    D = df$treat,
    covariates = covariates,
    panel = FALSE,
    estMethod = "dr"
  )
  dr_estimate <- result_dr$ATT
  
  # DRDID estimator with Inverse Probability Weighting (IPW)
  result_ipw <- drdid(
    y = df$earnings,
    post = df$post,
    D = df$treat,
    covariates = covariates,
    panel = FALSE,
    estMethod = "ipw"
  )
  ipw_estimate <- result_ipw$ATT
  
  # DRDID estimator with Regression Adjustment (RA)
  result_ra <- drdid(
    y = df$earnings,
    post = df$post,
    D = df$treat,
    covariates = covariates,
    panel = FALSE,
    estMethod = "reg"
  )
  ra_estimate <- result_ra$ATT
  
  # OLS regression
  model <- lm(
    earnings ~ post + treat + post:treat + post:age + post:gpa + post:age_sq + post:gpa_sq,
    data = df
  )
  ols_estimate <- coef(model)["post:treat"]
  
  return(list(att = att, dripw = dr_estimate, ipw = ipw_estimate, regadjust = ra_estimate, ols = ols_estimate))
}

# Run Monte Carlo simulation with 1000 repetitions
results <- replicate(1000, sim(), simplify = FALSE)
results_df <- do.call(rbind, lapply(results, as.data.frame))

# Calculate bias variables
results_df$dripw_bias <- results_df$dripw - results_df$att
results_df$ipw_bias <- results_df$ipw - results_df$att
results_df$regadjust_bias <- results_df$regadjust - results_df$att
results_df$ols_bias <- results_df$ols - results_df$att

# Prepare data for plotting
bias_data <- data.frame(
  bias = c(results_df$ols_bias, results_df$dripw_bias, results_df$regadjust_bias, results_df$ipw_bias),
  method = factor(rep(c("OLS", "DRIPW", "Reg. Adjust", "IPW"), each = nrow(results_df)))
)

# Generate the combined plot
ggplot(bias_data, aes(x = bias, color = method, linetype = method)) +
  geom_density(size = 1) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray") +
  labs(
    title = "Distribution of Bias in ATT Estimates by Method",
    subtitle = "Comparison of Different Estimators",
    x = "Bias in Estimated ATT",
    y = "Density"
  ) +
  theme_minimal() +
  scale_color_manual(values = c("navy", "maroon", "black", "darkorange")) +
  scale_linetype_manual(values = c("solid", "dashed", "dotdash", "dotted")) +
  theme(legend.title = element_blank())

# Save the plot
ggsave("./covariates_R.png", width = 8, height = 6, dpi = 300)


