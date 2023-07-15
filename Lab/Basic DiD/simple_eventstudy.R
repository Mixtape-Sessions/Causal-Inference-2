################################################################################
# name: simple_eventstudy.R
# author: scott cunningham and chatgpt4 code generator
# description: estimate an event study with a simple 2x2
################################################################################
# install.packages("stargazer", dependencies=TRUE)

# Load necessary libraries
library(dplyr)
library(readr)
library(tidyr)
library(broom)
library(haven)  # for reading .dta files
library(ggplot2)  # for plotting
library(stringr)  # for string manipulation
library(fixest)  # for feols function
library(readstata13)

# Load the data
data <- data.frame(read.dta13("https://github.com/scunning1975/mixtape/raw/master/castle.dta"))

# Convert year and effyear to numeric
data$year <- as.numeric(as.character(data$year))
data$effyear <- as.numeric(as.character(data$effyear))

# Filter the data
data <- data %>%
  filter(!(effyear %in% c(2005, 2007, 2008, 2009)))

# Generate post and treat variables
data <- data %>%
  mutate(year = as.numeric(year),
         post = ifelse(year >= 2006, 1, 0),
         treat = ifelse(!is.na(effyear), 1, 0))

# Event study
data <- data %>%
  mutate(treated = ifelse(effyear == 2006 & year >= 2006, 1, 0))

# Convert year to factor and set 2005 as reference level
data$year <- as.factor(data$year)
data$year <- relevel(data$year, ref = "2005")

# Run the regression
model <- felm(l_homicide ~ treat*year, data = data)

# Extract coefficients
coefs <- coef(summary(model))

# Convert to data frame for plotting
coefs_df <- as.data.frame(coefs)

# Compute the confidence intervals
coefs_df <- coefs_df %>%
  mutate(`2.5 %` = Estimate - 1.96 * `Std. Error`,
         `97.5 %` = Estimate + 1.96 * `Std. Error`)

# Filter the coefficients of interaction terms
coefs_event <- coefs_df %>%
  filter(str_detect(rownames(coefs_df), "treat:year"))

# Compute the year
coefs_event <- coefs_event %>%
  mutate(year = as.numeric(str_extract(rownames(coefs_df[rownames(coefs_df) %in% rownames(coefs_event), ]), "\\d+"))) %>%
  select(year, estimate = Estimate, conf.low = `2.5 %`, conf.high = `97.5 %`)

# Plot the event study
ggplot(coefs_event, aes(x = year, y = estimate)) +
  geom_line() +  
  geom_point() +
  geom_point(aes(x = 2005, y = 0), color = "red", size = 3) +  # Add this line
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2) +  
  geom_vline(xintercept = 2005.5, linetype = "dashed", color = "red") +  
  labs(x = "Years Since Policy Change", y = "Ln(Homicides)", title = "Event Study") +
  theme_minimal() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())

