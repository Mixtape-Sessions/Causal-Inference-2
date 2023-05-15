# ------------------------------------------------------------------------------
# name: baker_sa.R
# author: scott cunningham (with massive help from grant mcdermott who basically
#         fixed all of it, so I think he's the author tbh)
# description: implement SA on the baker dataset
# last updated: february 20, 2022
# ------------------------------------------------------------------------------

# load libraries
#install.packages("haven")
library(haven)  # Read Stata .dta files
library(fixest) # Sun & Abraham (and regular TWFE and high-dimensional FEs, etc., etc.)

# load data
baker = read_dta('https://github.com/scunning1975/mixtape/raw/master/baker.dta')

baker$treated = baker$treat_date!=0 # change to 0 anyone never treated, but
# because all units in this dataset are treated it is kind of pointless. But I 
# include it so you remember to do it, but you don't need to in baker.dta.

# Naive TWFE (bc it assumes homogeneous treatment profiles) Event Study (SEs clustered by state)
res_naive = feols(y ~ i(time_til, treated, ref = -1) | 
                    id + year,
                  baker, vcov = ~state)
summary(res_naive)
iplot(res_naive, main = "Naive TWFE")

# Again, because all units are treated you could just as well have run the
# following:
feols(y ~ i(time_til, ref = -1) | 
        id + year,
      baker, vcov = ~state) |>
  iplot()

# Sun and Abraham (SA20)

unique(baker$treat_date)

# This time, our SA implementation is a little different because we don't have a
# "never treated" group. (Everyone get's treated eventually.) So, we'll use our
# last treated cohort (i.e. 2004) as the control group. In practice this means
# that we have to subset our data by dropping all observations after this final
# treatment year. You could create a new dataset, but here we'll just use the
# `subset` argument to drop these observations on the fly.
res_cohort = feols(y ~ sunab(treat_date, year) | id + year, 
                   baker, subset = ~year<2004, ## NB: subset!
                   vcov = ~state)
summary(res_cohort)
iplot(res_cohort, ref.line = -1, main = "Sun & Abraham")

# Can also use iplot to plot them together
iplot(list(res_naive, res_cohort), ref.line = -1,
      main = "Treatment's effect on y")
legend("topright", col = c(1, 2), pch = c(20, 17), 
       legend = c("TWFE", "Sun & Abraham"))

# The full ATT
summary(res_cohort, agg = "att")

# Full disaggregation 
summary(res_cohort)


# Aside: If you'd prefer ggplot2 versions of these plots then you can try...
library(ggiplot) # remotes::install_github("grant_mcdermott/ggiplot")
library(ggplot2)
ggiplot(list("TWFE" = res_naive, "Sun & Abraham" = res_cohort), 
      main = "Treatment's effect on outcome (y)")
