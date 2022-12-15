library(tidyverse)
library(haven)
library(Synth)
library(devtools)
#devtools::install_github("ebenmichael/augsynth")
library(SCtools)
if(!require(SCtools)) devtools::install_github("bcastanho/SCtools")
library(augsynth)

# load the data from github
texas <- haven::read_dta("https://github.com/scunning1975/causal-inference-class/raw/master/texas.dta")

# create a treated variable
texas <- texas %>% 
  mutate(treated =  ifelse(state == 'Texas' & year >= 1993, 1, 0))

# Synthetic Controls - No covariates
syn_tx <- augsynth(bmprison ~ treated, 
                state, # unit variable
                year, # time variable
                texas, # data
                progfunc = "none", # function (ridge, elastic net, etc.) to be used to impute control outcomes. ?augsynth for more options  
                scm = T) # scm = T means using synthetic control method weighting method

# The default test statistic is the sum of the absolute treatment effects function(x) sum(abs(x))
summary(syn_tx) # ATTs and average ATT, notice the L2 imbalance of 2440.626

print(syn_tx$weights)

# Graph event study plot with conformal inference
plot(syn_tx) 

# Graph event study plot with jackknife inference
plot(syn_tx, inf_type = "jackknife+") # compute point-wise confidence intervals using the Jackknife+ procedure

# Augmented Synthetic Controls - Still no covariates but now with ridge regression
augsynth_nocov_tx <- augsynth(bmprison ~ treated, 
                        state, # unit variable
                        year, # time variable
                        texas, # data
                        progfunc = "ridge", # function (ridge, elastic net, etc.) to be used to impute control outcomes
                        scm = T)  #scm = T means using synthetic control method weighting method

# When using outcome model: in augsyth(), when set progfunc = 'ridge' (or other functions), we can plot cross-validation MSE by setting cv = T 
plot(augsynth_nocov_tx, cv = T) # Chose lambda that minimizes the cross validation

print(augsynth_nocov_tx$weights)

# Summarizing treatment effects row by row
summary(augsynth_nocov_tx) ## Notice the covariate L2 imbalance is 2436.210, not a ton of improvement

# Event study style graphic with conformal inference (Chernozhukov, et al. 2021)
plot(augsynth_nocov_tx)

# Event study style graphic with jackkife inference (Barber, et al. 2019)
plot(augsynth_nocov_tx, inf_type = "jackknife+")





# Augmented Synthetic Controls - With covariates and ridge regression
augsynth_tx <- augsynth(bmprison ~ treated|aidscapita + black, # covariates are put behind vertical bar |
                        state, # unit variable
                        year, # time variable
                        texas, # data
                        progfunc = "ridge", # function (ridge, elastic net, etc.) to be used to impute control outcomes
                        scm = T)  #scm = T means using synthetic control method weighting method

# When using outcome model: in augsyth(), when set progfunc = 'ridge' (or other functions), we can plot cross-validation MSE by setting cv = T 
plot(augsynth_tx, cv = T) # Chose lambda that minimizes the cross validation

# Summarizing treatment effects row by row
summary(augsynth_tx) ## Notice the covariate L2 imbalance is 31.220 and the L2 imbalance is 1513.071

# Event study style graphic with conformal inference (Chernozhukov, et al. 2021)
plot(augsynth_tx)

# Event study style graphic with jackkife inference (Barber, et al. 2019)
plot(augsynth_tx, inf_type = "jackknife+")



# Augmented Synthetic Controls - With covariates and ridge regression, fit on the residuals
augsynth_resid_tx <- augsynth(bmprison ~ treated|aidscapita + black, # covariates are put behind vertical bar |
                        state, # unit variable
                        year, # time variable
                        texas, # data
                        progfunc = "ridge", # function (ridge, elastic net, etc.) to be used to impute control outcomes
                        scm = T,
                        lambda = augsynth_nocov_tx$lambda, 
                        residualize = T)  

# Summarizing treatment effects row by row
summary(augsynth_resid_tx) 

# Event study style graphic with conformal inference (Chernozhukov, et al. 2021)
plot(augsynth_resid_tx)

# Event study style graphic with jackkife inference (Barber, et al. 2019)
plot(augsynth_resid_tx, inf_type = "jackknife+")



# Augmented Synthetic Controls - augment synth with many different outcome models
augsynth_desyn <- augsynth(bmprison ~ treated, 
                              state, # unit variable
                              year, # time variable
                              texas, # data
                              progfunc = "none", # function (ridge, elastic net, etc.) to be used to impute control outcomes
                              scm = T,  #scm = T means using synthetic control method weighting method
                              fixedeff = T) 


# Summarizing treatment effects row by row
summary(augsynth_desyn) 

# Event study style graphic with conformal inference (Chernozhukov, et al. 2021)
plot(augsynth_desyn)

# Event study style graphic with jackkife inference (Barber, et al. 2019)
plot(augsynth_desyn, inf_type = "jackknife+")
