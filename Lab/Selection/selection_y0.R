# Load necessary libraries
library(dplyr)
library(tidyr)
library(ggplot2)
set.seed(2)

# Create 40 states
states <- 1:40

# Generate 1000 workers (25 per state)
df <- data.frame(state = rep(states, each = 25)) %>%
  mutate(unit_fe = runif(n(), 1, 1000)) %>%
  group_by(state, unit_fe) %>%
  mutate(id = cur_group_id()) %>%
  ungroup()

# Potential outcomes
df <- df %>%
  mutate(y0 = unit_fe + rnorm(n(), mean = 0, sd = 10))

# Treatment assignment based on y0 (selection on Y(0))
p25 <- quantile(df$y0, 0.25)
df <- df %>%
  mutate(treat = ifelse(y0 < p25, 1, 0))

# Expand to two time periods
df <- df %>%
  slice(rep(1:n(), each = 2)) %>%
  group_by(id) %>%
  mutate(year = ifelse(row_number() == 1, 1990, 1991),
         post = ifelse(year == 1991, 1, 0)) %>%
  ungroup()

# Update potential outcomes
df <- df %>%
  mutate(
    y0 = ifelse(post == 1, y0 + 1000, y0),
    y1 = ifelse(post == 1, y0 + 7500, y0),  # treatment effect only in post
    delta = y1 - y0
  )

# Compute ATE and ATT
ate <- mean(df$delta[df$post == 1])
att <- mean(df$delta[df$post == 1 & df$treat == 1])

# Observed outcome
df <- df %>%
  mutate(earnings = ifelse(post == 1 & treat == 1, y1, y0))

# Illustrate parallel trends assumption
ey0_10 <- mean(df$y0[df$treat == 1 & df$post == 0])
ey0_11 <- mean(df$y0[df$treat == 1 & df$post == 1])
ey0_00 <- mean(df$y0[df$treat == 0 & df$post == 0])
ey0_01 <- mean(df$y0[df$treat == 0 & df$post == 1])

parallel_trends <- (ey0_11 - ey0_10) - (ey0_01 - ey0_00)

# DiD regression on Y(0) and on observed earnings
model_y0 <- lm(y0 ~ treat * post, data = df)
model_earnings <- lm(earnings ~ treat * post, data = df)

# Print results
summary(model_y0)
summary(model_earnings)
cat("ATE:", ate, "\n")
cat("ATT:", att, "\n")
cat("Parallel trends difference on Y(0):", parallel_trends, "\n")