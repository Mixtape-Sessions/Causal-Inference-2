################################################################################
# name: equivalence.R
# author: scott cunningham and chatgpt4 code generator
# description: show that did equation is numerically equivalent to OLS specification
################################################################################

# Load necessary libraries
# install.packages(c("dplyr", "readr", "tidyr", "broom", "plm", "vctrs", "sandwich"), dependencies = TRUE)

# Load necessary libraries
library(dplyr)
library(readr)
library(tidyr)
library(broom)
library(plm)
library(vctrs)
library(sandwich)
library(readstata13)
library(foreign)  # for reading .dta files

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

# Calculate means for different groups
mean_values <- data %>%
  group_by(post, treat) %>%
  summarise(mean_l_homicide = mean(l_homicide, na.rm = TRUE))

# Print mean_values for debugging
print(mean_values)

# Calculate the DiD manually
did <- ((mean_values %>% filter(post == 1, treat == 1) %>% pull(mean_l_homicide)) -
          (mean_values %>% filter(post == 0, treat == 1) %>% pull(mean_l_homicide))) -
  ((mean_values %>% filter(post == 1, treat == 0) %>% pull(mean_l_homicide)) -
     (mean_values %>% filter(post == 0, treat == 0) %>% pull(mean_l_homicide)))

print(did)

# Run the regression with clustered standard errors
model <- plm(l_homicide ~ post*treat, data = data, model = "pooling")
se_cluster <- sqrt(diag(vcovHC(model, type = "HC1", cluster = "group", adjust = "none")))

# Print the coefficient on the interaction
print(coef(model)["post:treat"])

# Run the regression with population weights
model_weighted <- plm(l_homicide ~ post*treat, data = data, model = "pooling", weights = data$popwt)

# Print the coefficient on the interaction
print(coef(model_weighted)["post:treat"])
