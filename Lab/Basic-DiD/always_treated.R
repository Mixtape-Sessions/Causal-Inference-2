# Set seed for reproducibility
set.seed(12345)

# Step 1: Generate 1000 workers
n_workers <- 1000
id <- 1:n_workers

# Generate fixed effects from Uniform(0,5)
fe <- runif(n_workers, 0, 5)

# Step 2: Define treatment based on fixed effects
median_fe <- median(fe)
treat <- as.numeric(fe > median_fe)

# Step 3: Generate data for two years (1990, 1991)
library(dplyr)
df <- data.frame(id = rep(id, each = 2),
                 year = rep(c(1990, 1991), n_workers),
                 fe = rep(fe, each = 2),
                 treat = rep(treat, each = 2)) %>%
  mutate(post = as.numeric(year == 1991))

# Step 4: Potential outcomes Y0 and Y1
# Adding normally distributed errors
df <- df %>%
  group_by(id) %>%
  mutate(e = rnorm(1),
         Y0 = fe + e,
         Y1 = Y0 + 5)

# Step 5: Generate Y1_C for Constant Treatment Effects
df <- df %>%
  mutate(Y1_C = ifelse(post == 0, Y0, Y0 + 5))

# Step 6: Delta_C
df <- df %>%
  mutate(Delta_C = Y1_C - Y0)

# Summarize Delta_C if treated and year == 1991
summary_delta_c <- df %>%
  filter(post == 1 & treat == 1) %>%
  summarise(mean_delta = mean(Delta_C))
print(summary_delta_c)

# Step 7: Earnings_C (Switching Equation for Constant TE)
df <- df %>%
  mutate(earnings_C = ifelse(treat == 1,
                             ifelse(post == 0, Y0, Y1),
                             ifelse(post == 0, Y0 + 5, Y0 + 5)))

# Step 8: Run DiD regression with constant TE
model_constant <- lm(earnings_C ~ post * treat, data = df)
summary(model_constant)

# ---- Dynamic Treatment Effects ----

# Step 9: Generate Y1_D for Dynamic Treatment Effects
df <- df %>%
  mutate(Y1_D = ifelse(treat == 1,
                       ifelse(post == 0, Y0, Y0 + 5),
                       ifelse(post == 0, Y0 + 5, Y0 + 10)))

# Step 10: Earnings_D (Switching Equation for Dynamic TE)
df <- df %>%
  mutate(earnings_D = Y1_D)

# Step 11: Run DiD regression with dynamic TE
model_dynamic <- lm(earnings_D ~ post * treat, data = df)
summary(model_dynamic)
