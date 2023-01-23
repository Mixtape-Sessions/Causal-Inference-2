library(tidyverse)
library(haven)
library(Synth)
library(devtools)
if(!require(SCtools)) devtools::install_github("bcastanho/SCtools")
library(SCtools)
library(augsynth)

read_data <- function(df)
{
  full_path <- paste("https://raw.github.com/scunning1975/mixtape/master/", 
                     df, sep = "")
  df <- read_dta(full_path)
  return(df)
}

texas <- read_data("texas.dta") %>%
  as.data.frame(.)

# create a treated variable
texas <- texas %>% 
  mutate(treated =  ifelse(state == 'Texas' & year >= 1993, 1, 0))

# Augmented Synthetic Controls - No covariate
syn_tx <- augsynth(bmprison ~ treated, 
                statefip, # unit variable
                year, # time variable
                texas, # data
                progfunc = "none", # function (ridge, elastic net, etc.) to be used to impute control outcomes. ?augsynth for more options  
                scm = T) # scm = T means using synthetic control method weighting method

summary(syn_tx) # ATTs and average ATT
plot(syn_tx) 
plot(syn_tx, inf_type = "jackknife+") # compute point-wise confidence intervals using the Jackknife+ procedure

# When using outcome model: in augsyth(), when set progfunc = 'ridge' (or other functions), we can plot cross-validation MSE by setting cv = T 
plot(syn_tx, cv = T)

# Augmented Synthetic Controls - With covariates
augsynth_tx <- augsynth(bmprison ~ treated|poverty +income + alcohol + aidscapita + black + perc1519, # covariates are put behind vertical bar |
                        state, # unit variable
                        year, # time variable
                        texas, # data
                        progfunc = "none", # function (ridge, elastic net, etc.) to be used to impute control outcomes
                        scm = T)  #scm = T means using synthetic control method weighting method

summary(augsynth_tx)
plot(augsynth_tx)
plot(augsynth_tx, inf_type = "jackknife+")
