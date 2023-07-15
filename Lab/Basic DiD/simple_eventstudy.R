################################################################################
# name: simple_eventstudy.R
# author: scott cunningham and chatgpt4 code generator
# description: estimate an event study with a simple 2x2
################################################################################
# install.packages("stargazer", dependencies=TRUE)

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

# Event study
data <- data %>%
  mutate(treated = ifelse(effyear == 2006 & year >= 2006, 1, 0))


# Run the regression
model <- feols(
  l_homicide ~ i(treat, i.year, ref = 0, ref2 = 2005) + i(year) + i(treat),
  data = data, cluster = ~state
)

summary(model)

# Extract event-study coefficients
coefs_event <- broom::tidy(model) %>%
  # Select only event-study terms
  filter(str_detect(term, "treat::1:year")) %>%
  # Create year column
  mutate(
    year = as.numeric(str_extract(term, "treat::1:year::(.*)", group = 1))
  ) %>%
  mutate(
    conf.low = estimate - 1.96 * std.error,
    conf.high = estimate + 1.96 * std.error
  )

# Add 0 for omitted year 2005
coefs_event <- coefs_event %>%
  add_row(
    term = "treat::1:year::2005",
    estimate = 0,
    std.error = 0,
    year = 2005,
    conf.low = NA,
    conf.high = NA
  )

ggplot(coefs_event, aes(x = year, y = estimate)) +
  geom_line() +
  geom_point() +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2) +
  geom_vline(xintercept = 2005.5, linetype = "dashed", color = "blue") +
  geom_hline(yintercept = 0, color = "blue") +
  labs(x = "Years Since Policy Change", y = "Ln(Homicides)", title = "Event Study") +
  theme_minimal()
