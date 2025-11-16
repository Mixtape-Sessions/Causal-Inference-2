# name: equivalence.R
# author: scott cunningham  
# description: OLS and Manual are the same

# Clear workspace
rm(list = ls())

# Load required libraries
library(haven)
library(dplyr)
library(lmtest)
library(sandwich)
library(fixest)

# Load data
castle <- read_dta("https://github.com/scunning1975/mixtape/raw/master/castle.dta")

# Set up panel structure (R doesn't need explicit xtset like Stata)
# Just noting that sid is the panel ID and year is time

# Drop observations where effyear is 2005, 2007, 2008, or 2009
castle <- castle[!(castle$effyear %in% c(2005, 2007, 2008, 2009)), ]

# Drop existing post variable if it exists and create new one
castle$post <- NULL
castle$post <- 0
castle$post[castle$year >= 2006] <- 1

# Create treatment variable
castle$treat <- 0
castle$treat[castle$effyear == 2006] <- 1

# Keep only years 2005 and 2006
castle <- castle[castle$year %in% c(2005, 2006), ]

# Manual unweighted 2x2 DiD calculation
# Calculate group means
y11 <- mean(castle$l_homicide[castle$treat == 1 & castle$post == 1], na.rm = TRUE)
y10 <- mean(castle$l_homicide[castle$treat == 1 & castle$post == 0], na.rm = TRUE)
y01 <- mean(castle$l_homicide[castle$treat == 0 & castle$post == 1], na.rm = TRUE)
y00 <- mean(castle$l_homicide[castle$treat == 0 & castle$post == 0], na.rm = TRUE)

# Add these as variables to the dataset
castle$y11 <- y11
castle$y10 <- y10
castle$y01 <- y01
castle$y00 <- y00

# Calculate DiD estimator
castle$did <- (y11 - y10) - (y01 - y00)

# Display the DiD estimate
cat("DiD Estimate:", unique(castle$did), "\n")
summary(castle$did)

# Load additional library for clustered standard errors
library(lmtest)
library(sandwich)

# Regression Example 1: OLS regression with interactions (interactioned OLS)
model1 <- lm(l_homicide ~ post * treat, data = castle)

# Get clustered standard errors
clustered_se <- vcovCL(model1, cluster = castle$sid)
coeftest(model1, vcov = clustered_se)

# Regression Example 2: Two-way fixed effects (state and year fixed effects)
model2 <- feols(l_homicide ~ treat:post | sid + year, 
                data = castle, 
                cluster = ~sid)
summary(model2)

# Regression Example 3: Regress "long difference" onto treatment dummy
# Create a subset for long difference (preserve/restore equivalent)
castle_long <- castle %>%
  select(sid, year, l_homicide, treat) %>%
  pivot_wider(names_from = year, 
              values_from = l_homicide, 
              names_prefix = "l_homicide") %>%
  mutate(diff = l_homicide2006 - l_homicide2005)

# Run regression with clustered standard errors using fixest
model3 <- feols(diff ~ treat, 
                data = castle_long, 
                cluster = ~sid)
summary(model3)


# Manual weighted 2x2 DiD calculation
# Calculate weighted group means
wy11 <- weighted.mean(castle$l_homicide[castle$treat == 1 & castle$post == 1], 
                      castle$popwt[castle$treat == 1 & castle$post == 1], na.rm = TRUE)
wy10 <- weighted.mean(castle$l_homicide[castle$treat == 1 & castle$post == 0], 
                      castle$popwt[castle$treat == 1 & castle$post == 0], na.rm = TRUE)
wy01 <- weighted.mean(castle$l_homicide[castle$treat == 0 & castle$post == 1], 
                      castle$popwt[castle$treat == 0 & castle$post == 1], na.rm = TRUE)
wy00 <- weighted.mean(castle$l_homicide[castle$treat == 0 & castle$post == 0], 
                      castle$popwt[castle$treat == 0 & castle$post == 0], na.rm = TRUE)

# Add these as variables to the dataset
castle$wy11 <- wy11
castle$wy10 <- wy10
castle$wy01 <- wy01
castle$wy00 <- wy00

# Calculate weighted DiD estimator
castle$wdid <- (wy11 - wy10) - (wy01 - wy00)

# Display the weighted DiD estimate
cat("Weighted DiD Estimate:", unique(castle$wdid), "\n")
summary(castle$wdid)

# Weighted Regression Example 1: OLS regression with interactions and population weights
wmodel1 <- lm(l_homicide ~ post * treat, data = castle, weights = popwt)

# Get clustered standard errors for weighted regression
wclustered_se <- vcovCL(wmodel1, cluster = castle$sid)
coeftest(wmodel1, vcov = wclustered_se)

# Weighted Regression Example 2: Two-way fixed effects (state and year fixed effects)
wmodel2 <- feols(l_homicide ~ treat:post | sid + year, 
                 data = castle, 
                 weights = ~popwt,
                 cluster = ~sid)
summary(wmodel2)

# Weighted Regression Example 3: Regress "long difference" onto treatment dummy
# Create weighted long difference dataset
castle_wlong <- castle %>%
  select(sid, year, l_homicide, popwt, treat) %>%
  pivot_wider(names_from = year, 
              values_from = c(l_homicide, popwt), 
              names_sep = "") %>%
  mutate(diff = l_homicide2006 - l_homicide2005)

# Run weighted regression with clustered standard errors
wmodel3 <- feols(diff ~ treat, 
                 data = castle_wlong, 
                 weights = ~popwt2005,
                 cluster = ~sid)
summary(wmodel3)



