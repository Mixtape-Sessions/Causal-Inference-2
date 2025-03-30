#**********************************************************************
# na.R
# Description: illustrating a no anticipation violation with diff-in-diff
#**********************************************************************

set.seed(20200403)
library(dplyr)
library(fixest)

# First create the states
states <- data.frame(state = 1:40)

# Generate 25 firms per state (total 1000 firms)
data <- states %>%
  slice(rep(1:n(), each = 25)) %>%
  group_by(state) %>%
  mutate(firms = runif(25, 0, 5)) %>%
  ungroup()

# Expand data for 4 years per firm
data <- data %>%
  slice(rep(1:n(), each = 4)) %>%
  group_by(state, firms) %>%
  mutate(year = 1990 + row_number() - 1,
         n = row_number()) %>%
  ungroup()

# Generate ID
data$id <- group_indices(data, state, firms)

# Define treatment group (upper half)
data <- data %>%
  mutate(group = ifelse(id >= 500, 1, 0))

# Correct post-treatment indicator (no anticipation satisfied)
data <- data %>%
  mutate(post = ifelse(year >= 1991, 1, 0))

# Incorrect post-treatment indicator (no anticipation violated)
data <- data %>%
  mutate(post_na = ifelse(year >= 1992, 1, 0))

# Data generating process
data <- data %>%
  mutate(e = rnorm(nrow(.), 0, 1),
         y0 = firms + n + e)

# Constant treatment effect
data <- data %>%
  mutate(y1_c = y0 + ifelse(year >= 1991, 10, 0))

# Dynamic treatment effect
data <- data %>%
  mutate(y1_d = case_when(
    year == 1991 ~ y0 + 10,
    year == 1992 ~ y0 + 20,
    year == 1993 ~ y0 + 30,
    TRUE ~ y0
  ))

# Treatment effects
data <- data %>%
  mutate(delta_c = y1_c - y0,
         delta_d = y1_d - y0)

summary(data$delta_c[data$year >= 1991 & data$group == 1])
summary(data$delta_d[data$year >= 1991 & data$group == 1])

# Treatment indicator
data <- data %>%
  mutate(d = ifelse(year >= 1991 & group == 1, 1, 0))

# Observed outcomes (switching equation)
data <- data %>%
  mutate(y_c = ifelse(d == 1, y1_c, y0),
         y_d = ifelse(d == 1, y1_d, y0))

# Aggregate causal parameters
att_c <- mean(data$delta_c[data$year >= 1991 & data$group == 1])
att_d <- mean(data$delta_d[data$year >= 1991 & data$group == 1])

cat("ATT (constant):", att_c, "\n")
cat("ATT (dynamic):", att_d, "\n")

# Correct specifications
cat("\nCorrect specifications:\n")
feols(y_c ~ group * post, data = data, vcov = "hc1") %>% summary()
feols(y_d ~ group * post, data = data, vcov = "hc1") %>% summary()

# Incorrect specifications (NA violated)
cat("\nIncorrect specifications (NA violated):\n")
feols(y_c ~ group * post_na, data = data %>% filter(year >= 1991), vcov = "hc1") %>% summary()
feols(y_d ~ group * post_na, data = data %>% filter(year >= 1991), vcov = "hc1") %>% summary()
