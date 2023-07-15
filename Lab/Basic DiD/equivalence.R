################################################################################
# name: equivalence.R
# author: scott cunningham and chatgpt4 code generator
# description: show that did equation is numerically equivalent to OLS specification
################################################################################

# Load necessary libraries
# install.packages(c("tidyverse", "fixest", "haven"))
library(tidyverse)
library(fixest)
library(haven)

# Load the data
data <- haven::read_dta("https://github.com/scunning1975/mixtape/raw/master/castle.dta")

# Filter the data
data <- data %>%
  filter(!(effyear %in% c(2005, 2007, 2008, 2009)))

# Generate post and treat variables
data <- data %>%
  mutate(
    year = as.numeric(year),
    post = ifelse(year >= 2006, 1, 0),
    treat = ifelse(!is.na(effyear), 1, 0)
  )

# Calculate means for different groups
(mean_values <- data %>%
  group_by(post, treat) %>%
  summarise(mean_l_homicide = mean(l_homicide, na.rm = TRUE)))

# Calculate the DiD manually
(did <- with(mean_values, {
  (mean_l_homicide[post == 1 & treat == 1] - mean_l_homicide[post == 0 & treat == 1]) - 
  (mean_l_homicide[post == 1 & treat == 0] - mean_l_homicide[post == 0 & treat == 0])
}))


# Run the regression with clustered standard errors
model <- feols(
  l_homicide ~ i(post) + i(treat) + post:treat, 
  data = data, cluster = ~ state
)

model

# Run the regression with population weights
model_weighted <- feols(
  l_homicide ~ i(post) + i(treat) + post:treat, 
  data = data, cluster = ~ treat,
  weights = ~ popwt
)

model_weighted
