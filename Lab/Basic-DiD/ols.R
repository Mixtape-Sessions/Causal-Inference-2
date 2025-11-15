###############################################################################
# name: ols.R
# author: scott cunningham (R translation by cosmos)
# description: 2x2 DiD four ways on castle doctrine data
###############################################################################

library(tidyverse)
library(fixest)
library(haven)

# Load the data ---------------------------------------------------------------
df <- read_dta("https://github.com/scunning1975/mixtape/raw/master/castle.dta")

# Stata logic exactly:
# drop if effyear in 2005,2007,2008,2009
df <- df %>%
  filter(!(effyear %in% c(2005, 2007, 2008, 2009)))

# Keep only pre (2005) and post (2006) ----------------------------------------
df <- df %>% filter(year %in% c(2005, 2006))

# Generate treatment and post --------------------------------------------------
df <- df %>%
  mutate(
    post  = as.integer(year == 2006),
    treat = if_else(effyear == 2006, 1L, 0L)   # key fix
  )

###############################################################################
# 1. Manual 2x2 DiD using group means
###############################################################################

means <- df %>%
  group_by(treat, post) %>%
  summarise(y = mean(l_homicide), .groups = "drop")

print(means)

y11 <- means$y[means$treat == 1 & means$post == 1]
y10 <- means$y[means$treat == 1 & means$post == 0]
y01 <- means$y[means$treat == 0 & means$post == 1]
y00 <- means$y[means$treat == 0 & means$post == 0]

did_manual <- (y11 - y10) - (y01 - y00)
cat("Manual 2x2 DiD = ", did_manual, "\n")

###############################################################################
# 2. Canonical OLS with constant, treat, post, interaction
###############################################################################

mod_ols <- feols(
  l_homicide ~ treat * post,
  data = df,
  cluster = "sid"
)

summary(mod_ols)

###############################################################################
# 3. OLS with unit fixed effects (treat absorbed), post, interaction
###############################################################################

mod_fe <- feols(
  l_homicide ~ post * treat | sid,
  data = df,
  cluster = "sid"
)

summary(mod_fe)

###############################################################################
# 4. First-difference specification
###############################################################################

df_fd <- df %>%
  arrange(sid, year) %>%
  group_by(sid) %>%
  mutate(dl_homicide = l_homicide - lag(l_homicide)) %>%
  ungroup() %>%
  filter(year == 2006)

mod_fd <- feols(
  dl_homicide ~ treat,
  data = df_fd,
  cluster = "sid"
)

summary(mod_fd)
