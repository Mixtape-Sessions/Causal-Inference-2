# Baker

Twoway fixed effects (TWFE) is a common estimator used with panel data or repeated cross sections which is part of its appeal for difference-in-differences with differential timing.  Differential timing is a scenario in which panel units, such as states or firms, are shocked with some intervention at different time periods.  Ten firms may be treated in 2010, another five firms in 2014, and the remaining firms in 2020.  If we are interested in estimating the causal effect of the intervention on firm outcomes using diff-in-diff, can we estimate the effect using TWFE? And if so, what causal effect are we estimating?

The purpose of this exercise is to illustrate the bias of TWFE with differential timing if treatment effects are dynamic and to show that it is not biased if treatment effects are not dynamic. We will decompose the aggregate coefficient estimated using TWFE into the weighted average of underlying diff-in-diff calculations using the [Goodman-Bacon (2021)](https://www.sciencedirect.com/science/article/abs/pii/S0304407621001445) decomposition. The second purpose of the exercise is to illustrate the concept of the group-time ATT parameter and show that [Callaway and Sant'anna (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620303948?via%3Dihub) estimates through manual calculations. Finally, we estimate various aggregate parameters both across groups and relative event time using both [Callaway and Sant'anna (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620303948?via%3Dihub) as well as [Sun and Abraham (2020)](https://www.sciencedirect.com/science/article/abs/pii/S030440762030378X). 

1. We will perform analysis on a simulated dataset which can be downloaded 


1. We will first perform analysis on the experimental dataset `https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_exp_panel.dta`

a. Under random assignment, the simple difference-in-means identifies the ATE, and since the original NSW was a randomized experiment, we can do this.  Calculate the simple difference-in-means on the experimental dataset to estimate the "treatment effect" two separate ways: (1) manually calculate averages for both treatment (`ever_treated=1`) and control (`ever_treated=0`) and use them to estimate the returns to the program, and (2) estimate the effect with an OLS specification. In both cases, use only the year `78` and `re` variable for real earnings. 

b. Estimate the effect of the treatment, `ever_treated`, on real earnings, `re`, in a difference-in-differences estimator using years `78` for post period and `75` as the pre-period (ignoring for now year `74`). As with 1a, do this in the following two ways: (1) manually calculate the four means you need for the DiD equation and then estimate using the DiD equation, and (2) estimate the ATT using the OLS specification for the DiD equation with robust standard errors. Reminder to only use `78` and `75` (i.e., do not include `74` in OLS analysis). 

c. Check the pre-trends for 1974 relative to 1975 two ways: (1) manually calculate the DiD equation on 1974 relative to 1975 and (2) estimate the dynamic OLS specification with an interaction of `ever_treated` with `74`, an interaction of `ever_treated` with `78`.  Compare your answers for 2c to what you found in 2a and 2b. 

2. Now, we turn to the non-experimental dataset `https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_nonexp_panel.dta`. 

a. Repeat 1a (simple difference-in-means for `78` only), 1b (DiD using manual calculations and OLS specification for `78` and `75` only) and 1c (event study calculations manually and dynamic OLS specification for `78`, `75` and `74`)

b. Repeat 1b and 1c (OLS specifications) controlling linearly for `age, agesq, agecube, educ, educsq, marr, nodegree, black, hisp, re74, u74` with robust standard errors.

c. Use the `DRDID` command to estimate a doubly-robust difference-in-differences with covariates `age + agesq + agecube + educ + educsq + marr + nodegree + black + hisp + re74 + u74`, `id` panel unit identifier, `year` as the panel time identifier, and reporting the outcome regression analysis [(Heckman, Ichimura and Todd 1997)](http://jenni.uchicago.edu/papers/Heckman_Ichimura-Todd_REStud_v64-4_1997.pdf), inverse probability weight estimator [(Abadie 2005)](https://academic.oup.com/restud/article-abstract/72/1/1/1581053?redirectedFrom=fulltext), doubly robust [(Sant'anna and Zhao 2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620301901).  Compare these results with 1a, 1b, 2a and 2b. 
