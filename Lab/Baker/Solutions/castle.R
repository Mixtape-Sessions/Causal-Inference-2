# ------------------------------------------------------------------------------
# name: castle.R
# description: implement cs on the castle doctrine panel dataset
# ------------------------------------------------------------------------------
# load packages
# install.packages("haven", dependencies = TRUE)
library(haven)
# install.packages("devtools"); devtools::install_github("bcallaway11/did")
library(ggplot2)
library(did) # Callaway & Sant'Anna

castle <- read_dta("https://github.com/scunning1975/mixtape/raw/master/castle.dta")
# never treated states using CS (did) must have their treatment date recoded to 0 in order for the code to run
castle$effyear[is.na(castle$effyear)] <- 0 

# Estimating the effect on log homicides (l_homicide)
atts <- att_gt(
  yname = "l_homicide", # LHS variable
  tname = "year", # panel time variable
  idname = "sid", # states' panel id variable
  gname = "effyear", # first treatment period variable
  data = castle, # data
  #xformla = NULL, # no covariates
  xformla = ~ police + whitem_25_44 + poverty, # with covariates
  est_method = "ipw", # "dr" is doubly robust. "ipw" is inverse probability weighting. "reg" is regression
  control_group = "notyettreated", # set the comparison group which is either "nevertreated" or "notyettreated" 
  bstrap = TRUE, # if TRUE compute bootstrapped SE
  biters = 1000, # number of bootstrap iterations
  print_details = FALSE, # if TRUE, print detailed results
  base_period="universal", # long-differences
  clustervars = "sid", # cluster level
  panel = TRUE # whether the data is panel or repeated cross-sectional
) 

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

