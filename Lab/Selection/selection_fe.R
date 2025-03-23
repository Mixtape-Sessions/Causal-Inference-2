# selection_fe.R - Heterogeneous trends in Y0 and selection on fixed effects

# Load required packages
library(dplyr)
library(tidyr)
library(ggplot2)
library(lmtest)
library(sandwich)
library(clubSandwich)

set.seed(2)

# ------------------------------
# 1. Create Base Sample
# ------------------------------
# Create 5 states
df <- data.frame(state = rep(1:5, each = 250))
n <- nrow(df)

# Generate unique worker fixed effects per state: uniform between 1 and 1000
df <- df %>% mutate(unit_fe = runif(n, min = 1, max = 1000))

# Create a unique worker id (each worker is unique)
df$id <- 1:n

# Generate a group variable that cycles through 1 to 40
df$group <- ((1:n) %% 40) + 1

# Generate worker characteristics
# Age: using a Beta(2,5) distribution multiplied by 65 then rounded
df$age <- round(rbeta(n, shape1 = 2, shape2 = 5) * 65)
# Sex: male indicator (1 if male, 0 if female)
df$male <- ifelse(runif(n) > 0.5, 1, 0)

# ------------------------------
# 2. Generate Potential Outcomes (Years 1987-1992)
# ------------------------------
years <- 1987:1992
trend <- 5

# For each worker, simulate a time series of potential outcomes.
# The outcome in 1987 is: unit_fe + error, and for later years we add a constant trend plus a new error.
df_long <- df %>%
  group_by(id) %>%
  do({
    n_years <- length(years)
    errors <- rnorm(n_years, mean = 0, sd = 10)
    y0 <- numeric(n_years)
    y0[1] <- .$unit_fe[1] + errors[1]
    if(n_years > 1){
      for(t in 2:n_years){
        y0[t] <- y0[t - 1] + trend + errors[t]
      }
    }
    data.frame(year = years, y0 = y0)
  }) %>%
  ungroup()

# Merge the time series back with the worker-level data
df_long <- df_long %>%
  left_join(df, by = "id")

# ------------------------------
# 3. Treatment Assignment and Post-treatment Indicator
# ------------------------------
# Determine treatment status in 1990 based on id.
# Compute the 25th percentile of id for observations in 1990.
p25 <- quantile(df_long$id[df_long$year == 1990], 0.25)
df_long <- df_long %>%
  mutate(treat = ifelse(year == 1990 & id <= p25, 1, 0)) %>%
  group_by(id) %>%
  mutate(treat = max(treat)) %>%  # Ensure treatment status is constant for each worker
  ungroup()

# Create a post-treatment indicator: post = 1 if year >= 1991
df_long <- df_long %>%
  mutate(post = ifelse(year >= 1991, 1, 0))

# ------------------------------
# 4. Introduce Group-specific Trends and Treatment Effects
# ------------------------------
# For years 1991 and 1992, adjust y0 by group-specific additive trends.
df_long <- df_long %>%
  mutate(y0 = case_when(
    year >= 1991 & group == 2 ~ y0 + 10,
    year >= 1991 & group == 3 ~ y0 + 20,
    year >= 1991 & group == 4 ~ y0 + 30,
    TRUE ~ y0
  ))

# Generate y1: the treated outcome equals y0 plus a treatment effect (only for treated units in specific years)
df_long <- df_long %>%
  mutate(y1 = y0,
         y1 = ifelse(year == 1991 & treat == 1, y0 + 300, y1),
         y1 = ifelse(year == 1992 & treat == 1, y0 + 600, y1))

# Compute the (unobserved) treatment effect delta
df_long <- df_long %>% mutate(delta = y1 - y0)
ate <- mean(df_long$delta[df_long$post == 1])
att <- mean(df_long$delta[df_long$treat == 1 & df_long$post == 1])
cat("ATE =", ate, "\nATT =", att, "\n")

# ------------------------------
# 5. Construct Observed Outcome: Earnings
# ------------------------------
# For untreated periods, earnings equals y0; for treated units in post-treatment periods, earnings equals y1.
df_long <- df_long %>%
  mutate(earnings = ifelse(post == 1 & treat == 1, y1, y0))

# ------------------------------
# 6. Check Baseline Differences and Parallel Trends
# ------------------------------
# Baseline (1990) earnings by treatment status
baseline <- df_long %>% 
  filter(year == 1990) %>% 
  group_by(treat) %>% 
  summarise(mean_earnings = mean(earnings))
print(baseline)

# Illustrate the parallel trends assumption by computing mean y0 in pre- and post-treatment periods
ey0_10 <- mean(df_long$y0[df_long$treat == 1 & df_long$post == 0])
ey0_11 <- mean(df_long$y0[df_long$treat == 1 & df_long$post == 1])
ey0_00 <- mean(df_long$y0[df_long$treat == 0 & df_long$post == 0])
ey0_01 <- mean(df_long$y0[df_long$treat == 0 & df_long$post == 1])
parallel_trends <- (ey0_11 - ey0_10) - (ey0_01 - ey0_00)
cat("Parallel Trends =", parallel_trends, "\n")

# ------------------------------
# 7. Difference-in-Differences Regressions
# ------------------------------
# Regression of y0 on post, treat and their interaction with robust, state-clustered SEs.
reg1 <- lm(y0 ~ post * treat, data = df_long)
vcov_cluster1 <- vcovCR(reg1, cluster = df_long$state, type = "CR2")
cat("Regression of y0:\n")
print(coeftest(reg1, vcov_cluster1))

# Compute diff-in-diff manually on earnings
ey_10 <- mean(df_long$earnings[df_long$treat == 1 & df_long$post == 0])
ey_11 <- mean(df_long$earnings[df_long$treat == 1 & df_long$post == 1])
ey_00 <- mean(df_long$earnings[df_long$treat == 0 & df_long$post == 0])
ey_01 <- mean(df_long$earnings[df_long$treat == 0 & df_long$post == 1])
did <- (ey_11 - ey_10) - (ey_01 - ey_00)
cat("Manual Diff-in-Diff =", did, "\n")
# Regression on earnings
reg2 <- lm(earnings ~ post * treat, data = df_long)
vcov_cluster2 <- vcovCR(reg2, cluster = df_long$state, type = "CR2")
cat("Regression of earnings:\n")
print(coeftest(reg2, vcov_cluster2))
cat("Manual Diff-in-Diff =", did, "and ATT =", att, "\n")

# ------------------------------
# 8. Event Study Regression and Coefficient Plot
# ------------------------------
# Create a factor for year with 1990 as the base level.
df_long <- df_long %>% mutate(year_f = factor(year))
df_long$year_f <- relevel(df_long$year_f, ref = "1990")
reg_event <- lm(earnings ~ treat * year_f, data = df_long)
vcov_cluster_event <- vcovCR(reg_event, cluster = df_long$state, type = "CR2")
cat("Event Study Regression:\n")
print(coeftest(reg_event, vcov_cluster_event))

# Extract coefficients for the interaction terms "treat:year_f" for plotting.
coef_event <- coef(reg_event)
coef_names <- names(coef_event)
int_idx <- grep("treat:year_f", coef_names)
coef_df <- data.frame(
  term = coef_names[int_idx],
  coef = coef_event[int_idx]
)
# Extract the year from the term names (e.g., "treatyear_f1987" or "treat:year_f1987")
coef_df$year <- as.numeric(gsub(".*([0-9]{4}).*", "\\1", coef_df$term))

# Also extract clustered standard errors for these coefficients.
se_event <- sqrt(diag(vcov_cluster_event))[int_idx]
coef_df$se <- se_event
coef_df <- coef_df %>% arrange(year)

# Create a coefficient plot.
ggplot(coef_df, aes(x = year, y = coef)) +
  geom_point() +
  geom_errorbar(aes(ymin = coef - 1.96 * se, ymax = coef + 1.96 * se), width = 0.2) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_vline(xintercept = 1990.5, linetype = "dotted") +
  scale_x_continuous(breaks = seq(1987, 1992, by = 1)) +
  labs(title = "Estimated Effect of Training on Earnings",
       subtitle = "Selection on fixed effects",
       x = "Year", y = "Coefficient") +
  theme_minimal()

# Save the plot as a PNG file.
ggsave("./selection_fe_es.png", width = 8, height = 6)