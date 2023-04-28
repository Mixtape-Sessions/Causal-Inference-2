# ------------------------------------------------------------------------------
# name: baker_cs.R
# author: scott cunningham (baylor), pedro sant'anna (microsoft, vandy)
# description: implement cs on the baker simulated dataset
# last updated: february 19, 2022
# ------------------------------------------------------------------------------

# load packages
install.packages("readstata13", dependencies = TRUE)
library(readstata13)
install.packages("devtools")
devtools::install_github("bcallaway11/did")
library(ggplot2)
library(did) # Callaway & Sant'Anna

# load data
baker <- data.frame(read.dta13("https://github.com/scunning1975/mixtape/raw/master/baker.dta"))
baker$treat_date[is.na(baker$treat_date)] <- 0 # untreated units have effective year of 0

# Estimating the effect on y2 (constant) and y (dynamic treatment)
atts <- att_gt(yname = "y", # LHS variable
               tname = "year", # panel time variable
               idname = "id", # firms' panel id variable
               gname = "treat_date", # first treatment period variable
               data = baker, # data
               xformla = NULL, # no covariates
               #xformla = ~ l_police, # with covariates
               est_method = "ipw", # "dr" is doubly robust. "ipw" is inverse probability weighting. "reg" is regression
               control_group = "notyettreated", # set the comparison group which is either "nevertreated" or "notyettreated" 
               bstrap = TRUE, # if TRUE compute bootstrapped SE
               biters = 1000, # number of bootstrap iterations
               print_details = FALSE, # if TRUE, print detailed results
               clustervars = "state", # cluster level
               panel = TRUE) # whether the data is panel or repeated cross-sectional

# ------------------------------------------------------------------------------
# Static model
# ------------------------------------------------------------------------------

# Calculate group-time ("group") ATTs and overall ("simple") ATT
agg_effects <- aggte(atts, type = "simple", balance_e=TRUE)
summary(agg_effects)

# Group-time ATTs
summary(atts)

# Plot group-time ATTs
ggdid(atts)

# ------------------------------------------------------------------------------
# Event-study
# ------------------------------------------------------------------------------

# Calculate group-time ATTs in relative event time
agg_effects_es <- aggte(atts, type = "dynamic")
summary(agg_effects_es)

# Plot event-study coefficients
ggdid(agg_effects_es)
