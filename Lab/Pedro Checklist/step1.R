
## panelview: Visualizing Panel Data
## User's Guide

## Hongyu Mou(PKU); Licheng Liu (MIT); Yiqing Xu (Stanford)
## Feb 12, 2023
## version 1.1.16

install.packages('devtools', repos = 'http://cran.us.r-project.org') # if not already installed
devtools::install_github('xuyiqing/panelview')


## require(ggplot2)
## require(gridExtra)
## require(grid)
## require(dplyr)

library(haven)
library(tidyverse)
library(fixest) 
library(did2s)
library(did)
library(bacondecomp)
library(panelView)

castle <- haven::read_dta('https://github.com/scunning1975/mixtape/raw/master/castle.dta')
ls(castle)


#############################################
## Plot treatment status
#############################################
castle[is.na(castle$effyear), ]$effyear <- 0
castle$rel_year = castle$year - castle$effyear
castle[castle$effyear == 0, ]$rel_year <- -1
castle$treat = (castle$year >= castle$effyear) & (castle$effyear != 0)

## Example: EDR and voter turnout
panelview(effyear ~, 
          data = turnout, index = c("abb","year"), 
          xlab = "Year", ylab = "sid")


## by treatment timing: treated on the top
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
          data = turnout, index = c("abb","year"), 
          xlab = "Year", ylab = "State", by.timing = TRUE, 
          legend.labs = c("No EDR", "EDR"), background = "white", 
          cex.main = 20, cex.axis= 8, cex.lab = 12, cex.legend = 12)


## distinguish pre-treatment and post-treatment for the treated
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
          data = turnout, index = c("abb","year"), 
          xlab = "Year", ylab = "State", pre.post = TRUE)


## adjust axis labels
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
          data = turnout, index = c("abb","year"), 
          xlab = "Year", ylab = "State", by.timing = TRUE, 
          pre.post = TRUE, legend.labs = c("Control States", 
                                           "Treated States (before EDR)", "Treated States (after EDR)"))

## not showing unit labels
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
          data = turnout, index = c("abb","year"), 
          main = "EDR Reform", axis.lab = "time")

## Give the variable name instead
panelview(D = "policy_edr", data = turnout, index = c("abb","year"), 
          xlab = "Year", ylab = "State", pre.post = TRUE, 
          main = "EDR Reform", axis.lab = "time")

## change color
library(dplyr)
turnout %>% panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
                      color = c("#B0C4DE","white"), by.timing = TRUE, 
                      index = c("abb","year"), xlab = "Year", ylab = "State")

## leave gap if time is not evenly distributed
turnout2<-turnout[!(turnout$year=="1924" | turnout$year=="1928" | turnout$year == "1940"),]
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
          data = turnout2, index = c("abb","year"),
          type = "treat", leave.gap = T)


## Example: democracy and state capacity
panelview(Capacity ~ demo + lnpop + lngdp, 
          data = capacity, index = c("ccode", "year"), 
          axis.lab.gap = c(2,10), main = "Democracy and State Capacity")

## by treatment timing
panelview(Capacity ~ demo + lnpop + lngdp, 
          data = capacity, index = c("ccode", "year"), 
          axis.lab.angle = 90, main = "Democracy and State Capacity: Treatment Status", 
          by.timing = TRUE, axis.lab = "time")

########################################
## Collapse by treatment history
#########################################

panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
          data = turnout, index = c("abb","year"), axis.lab.angle = 90, 
          by.timing = TRUE, collapse.history = "TRUE") 
# sorted by treatment timing

panelview(Capacity ~ demo + lnpop + lngdp, 
          data = capacity, index = c("ccode", "year"), 
          axis.lab.gap = c(2,0), axis.lab.angle = 90, 
          collapse.history = "TRUE") 
# sorted by cohort size

################
## plot subset
################

panelview(Capacity ~ demo + lnpop + lngdp, 
          data = capacity, index = c("ccode", "year"), 
          axis.lab.gap = c(2,0), main = "Democracy and State Capacity", 
          show.id = c(1:25))

## plot with treatment variable name
panelview(D = "demo", data = capacity, index = c("ccode", "year"), 
          axis.lab.gap = c(2,0), main = "Democracy and State Capacity", 
          show.id = c(1:25), type = "treat")

panelview(Capacity ~ demo + lnpop + lngdp, data = capacity, 
          index = c("ccode", "year"), axis.lab.gap = c(2,0), 
          main = "Democracy and State Capacity", 
          id = unique(capacity$ccode)[26:50], by.timing = TRUE)


#############################################
## Ignore treatment status (missingness)
#############################################

## ignore treatment status
library(dplyr)
capacity %>% panelview(Capacity ~ 1, index = c("ccode","year"), 
                       axis.lab="off", type = "miss")

capacity %>%  panelview(Capacity ~ demo, ignore.treat = TRUE, 
                        index = c("ccode","year"), axis.lab= "off")


## plot with outcome variable
capacity %>% panelview(Y = "Capacity", index = c("ccode", "year"), 
                       axis.lab.gap = c(2,10), type = "miss")


## leave gap if time is not evenly distributed
capacity$demo[capacity$year == "1960" | capacity$year == "1980"] <- NA
capacity$lngdp[capacity$year == "1990"] <- NA
panelview(1 ~ demo + lngdp, data = capacity, index = c("ccode","year"),
          type = "missing", leave.gap = TRUE, axis.lab.gap = c(2,10))


#############################################
##### More than 2 treatment levels
#############################################

demo2 <- rep(0, dim(capacity)[1])
demo2[which(capacity$polity2 < -0.5)] <- -1
demo2[which(capacity$polity2 > 0.5)] <- 1
capacity$demo2 <- demo2

panelview(Capacity ~ demo2 + lngdp, data = capacity, index = c("ccode", "year"), 
          axis.lab.gap = c(2,10), main = "Regime Type")

library(RColorBrewer)
mycol<-brewer.pal(3,"Set1")[c(1,3,2)]
panelview(Capacity ~ demo2, data = capacity, index = c("ccode", "year"), 
          axis.lab.gap = c(2), main = "Regime Type", axis.lab = c("time"), 
          color = mycol, legend.labs = c("Autocracy", "Hybrid", "Democracy"))

panelview(D = "demo2", data = capacity, index = c("ccode", "year"), 
          axis.lab.gap = c(2), main = "Regime Type", axis.lab = c("time"), 
          color = mycol, legend.labs = c("Autocracy", "Hybrid", "Democracy"))


## continuous treatment levels (>5 values)
panelview(Capacity ~ polity2 + lngdp, data = capacity, 
          index = c("ccode", "year"), axis.lab.gap = c(2,10), 
          main = "Regime Type", gridOff = TRUE)

## change colors
panelview(Capacity ~ polity2 + lngdp, data = capacity, 
          index = c("ccode", "year"), axis.lab.gap = c(2,10), main = "Regime Type",
          color = c("yellow", "red","blue","green","gray"), 
          background = "white")



########################################################################
## Plot the outcome variable (or any variable in a panel dataset)
########################################################################

panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
          data = turnout, index = c("abb","year"), type = "outcome", 
          main = "EDR Reform and Turnout", ylim = c(0,100),
          xlab = "Year", ylab = "Turnout")

## change legend
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor,
          data = turnout, index = c("abb","year"), type = "outcome",
          main = "EDR Reform and Turnout",
          legend.labs = c("Control States","Treated States (before EDR)",
                          "Treated States (after EDR)"))

## not use black and white theme
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
          data = turnout, index = c("abb","year"), type = "outcome", 
          main = "EDR Reform and Turnout", theme.bw = FALSE)

## change colors
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
          data = turnout, index = c("abb","year"), type = "outcome", 
          main = "EDR Reform and Turnout", color = c("#FC8D6280", "red", "#99999950"), 
          legend.labs = c("Control States","Treated States (before EDR)", "Treated States (after EDR)"), 
          theme.bw = FALSE)

## specify units
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
          data = turnout, index = c("abb","year"), type = "outcome", 
          main = "EDR Reform and Turnout (AL, AR, CT)", id = c("AL", "AR", "CT"))

## by group (in a column by default)
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
          data = turnout, index = c("abb","year"), type = "outcome", main = "", 
          by.group = TRUE, cex.main = 20, cex.main.sub = 15)

## by group (in a row)
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
          data = turnout, index = c("abb","year"), type = "outcome", 
          main = "", by.group.side = TRUE, cex.main = 20, cex.main.sub = 15)

## ignore treatment status
panelview(turnout ~ 1, data = turnout, index = c("abb","year"), 
          type = "outcome", main = "Turnout", ylim = c(0,100), 
          xlab = "Year", ylab = "Turnout")

# same as above
panelview(Y = "turnout", data = turnout, index = c("abb","year"), 
          type = "outcome", main = "Turnout", ylim = c(0,100), 
          xlab = "Year", ylab = "Turnout")

## by cohort (based on treatment timing)
panelview(turnout ~ policy_edr + policy_motor, data = turnout, 
          index = c("abb","year"), type = "outcome", main = "EDR Reform and Turnout", 
          by.cohort = TRUE, pre.post = FALSE)



#####################
## discrete outcomes
#####################

panelview(Y ~ D, data = simdata, index = c("id", "time"), 
          by.group = FALSE, outcome.type = "discrete", 
          type = "outcome", xlim = c(8, 15))

## by group
panelview(Y ~ D, data = simdata, index = c("id", "time"), 
          by.group = TRUE, outcome.type = "discrete", 
          type = "outcome",  xlim = c(8, 15))

## ignore treatment status
panelview(Capacity ~ polity2 + lngdp, data = capacity, 
          index = c("ccode", "year"), main = "Measuring State Capacity", 
          type = "outcome", legendOff = TRUE)


########################################################################
## Plotting Y and D against time in the same graph
########################################################################


##########################################
## Plot average time series for all units
##########################################

# 1. Continuous Y, discrete D:
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, 
          data = turnout, index = c("abb","year"), type = "bivariate",
          style = c("c","b"), main = "EDR Reform and Turnout", ylab = "Turnout")

panelview(lnpop ~ demo, data = capacity, index = c("country", "year"),
          ylim = list(c(8, 9.4), c(0.25, 0.6)), type = "bivar")

# 2. Discrete Y, discrete D:
panelview(Y ~ D, data = simdata, index = c("id", "time"),
          type = "bivar", theme.bw = FALSE, outcome.type = "discrete")

# 3. Continuous Y, continuous D:
panelview(lnpop ~ polity2, data = capacity, index = c("country", "year"),
          ylim = list(c(8.75,9.4), c(-0.2, 0.35)), type = "bivar")

# 4. Discrete Y, continuous D
simdata$x <- seq(0.001,0.9,0.001)
panelview(Y ~ x, data = simdata, index = c("id", "time"),
          type = "bivar", outcome.type = "discrete")


## Line the discete treatment
# 1. Y: continuous; D: discrete
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, data = turnout,
          index = c("abb","year"),
          type = "bivar",
          style = c("line","connected"),
          theme.bw = FALSE,
          ylab = "Turnout")

# 2. Y: Discrete; D: discrete
panelview(Y ~ D, data = simdata, index = c("id", "time"),
          type = "bivar", style = "line", theme.bw = FALSE, lwd = 0.4)


##########################################
## Plot by each unit
##########################################

# 1. Continuous Y, discrete D:
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, data = turnout,
          index = c("abb","year"), type = "bivar", by.unit = TRUE, 
          show.id = c(1:12), ylab = "Turnout")

panelview(lnpop ~ demo, data = capacity,
          index = c("country","year"), type = "bivar",
          by.unit = TRUE, ylim = list(c(8,10), c(-2, 2)),
          show.id = c(1:16))

# 2. Discrete Y, discrete D:
panelview(Y ~ D, data = simdata, index = c("id", "time"),
          type = "bivariate", by.unit = TRUE, theme.bw = FALSE,
          outcome.type = "discrete", id = unique(simdata$id)[1:12])

# 3. Continuous Y, continuous D:
panelview(lnpop ~ polity2, data = capacity,
          index = c("country","year"), type = "bivar",
          by.unit = TRUE, show.id = c(1:12))

# 4. Discrete Y, continuous D
simdata$x <- seq(0.001,0.9,0.001)
panelview(Y ~ x, data = simdata, index = c("id", "time"),
          type = "bivar", by.unit = TRUE,
          outcome.type = "discrete",
          lwd = 0.4, id = unique(simdata$id)[1:12])

## Line the discete treatment
# 1. Y: continuous; D: discrete
panelview(turnout ~ policy_edr + policy_mail_in + policy_motor, data = turnout,
          index = c("abb","year"), type = "bivar",
          by.unit = TRUE, style = "line", theme.bw = FALSE, lwd = 0.5,
          show.id = c(1:12), ylab = "Turnout")

# 2. Y: Discrete; D: discrete
panelview(Y ~ D, data = simdata, index = c("id", "time"),
          type = "bivar", by.unit = TRUE,
          outcome.type = "discrete", style = "line",
          theme.bw = FALSE, lwd = 0.4,
          id = unique(simdata$id)[1:20])