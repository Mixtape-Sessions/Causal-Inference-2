# Differential timing using Andrew Baker simulation

Twoway fixed effects (TWFE) is a common estimator used with panel data or repeated cross sections which is part of its appeal for difference-in-differences with differential timing.  Differential timing is a scenario in which panel units, such as states or firms, are shocked with some intervention at different time periods.  Ten firms may be treated in 2010, another five firms in 2014, and the remaining firms in 2020.  If we are interested in estimating the causal effect of the intervention on firm outcomes using diff-in-diff, can we estimate the effect using TWFE? And if so, what causal effect are we estimating?

The purpose of this exercise is to illustrate the bias of TWFE with differential timing if treatment effects are dynamic and to show that it is not biased if treatment effects are not dynamic. We will decompose the aggregate coefficient estimated using TWFE into the weighted average of underlying diff-in-diff calculations using the [Goodman-Bacon (2021)](https://www.sciencedirect.com/science/article/abs/pii/S0304407621001445) decomposition. The second purpose of the exercise is to illustrate the concept of the group-time ATT parameter and show that [Callaway and Sant'anna (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620303948?via%3Dihub) estimates through manual calculations. Finally, we estimate various aggregate parameters both across groups and relative event time using both [Callaway and Sant'anna (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620303948?via%3Dihub) as well as [Sun and Abraham (2020)](https://www.sciencedirect.com/science/article/abs/pii/S030440762030378X). 

We will perform analysis on a simulated dataset that Andrew Baker (assistant professor, University of California Berkeley College of Law) created. This can be generated yourself using either baker.R or baker.do, or you can download it yourself `https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Baker/baker.dta`.

There are 40 states, 250 firms per state, each of which is observed for 30 years from 1980 to 2009 (i.e., a balanced panel of firms). Ten firms are treated in 1986, another 10 in 1992, another 10 in 1998 and another 10 in 2004. There are two outcomes: `y2` is firm revenue under constant treatment effects that are on average equal to 10 for group 1 (i.e., the 1986 group), 8 for group 2, 6 for group 3 and 4 for group 4. The second outcome is a different outcome scenario in which treatment effects grow over time at a constant slope: 10 in 1986, 20 in 1987, 30 in 1988 and so on. You can view this data construction in lines 98-102 of baker.do. Write down what you think the aggregate treatment effect on the treatment group should for `y2` versus `y`. 

1. For this first question, we will focus on `y2`, the constant treatment effect outcome measure. 

a. Calculate the simple and group ATT using the information at this spreadsheet `https://docs.google.com/spreadsheets/d/1dI67eNNE2zrX4KrkoFvej-cKxqHkM8yJdMpD-0uE4q8/edit?usp=sharing` in the first tab labeled Constant DiD.

b. Generate a dummy labeled `post` equalling 0 if a unit is not treated and 1 if it is the year of treatment or after. Estimate the effect of the treatment `post` on `y2` using TWFE with cluster robust standard errors. Compare your answer to the simple and group ATT you calculated in the spreadsheet.  Is your TWFE estimate biased?

c. Decompose the TWFE estimated coefficient using the [Goodman-Bacon (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407621001445) decomposition using either `ddtiming` or `bacondecomp`. Why did the use of late-to-early DiD calculations ("forbidden contrasts") not bias our estimate of the ATT?

2. For this second question, we will focus on `y`, the dynamic treatment effect outcome measure.

a. Calculate the simple and group ATT using the information at this spreadsheet `https://docs.google.com/spreadsheets/d/1dI67eNNE2zrX4KrkoFvej-cKxqHkM8yJdMpD-0uE4q8/edit?usp=sharing` in the second tab labeled Dynamic DiD. Why is the ATT under dynamics larger than the ATT under constant treatment effects?

b. You can still use the same dummy as before `post` equalling 0 if a unit is not treated and 1 if it is the year of treatment or after. Now estimate the effect of the treatment `post` on `y` using TWFE with cluster robust standard errors. Compare your answer to the simple and group ATT you calculated in the second table of the spreadsheet.  Is your TWFE estimate biased?

c. Decompose the TWFE estimated coefficient using the [Goodman-Bacon (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407621001445) decomposition using either `ddtiming` or `bacondecomp`. Why did the use of late-to-early DiD calculations ("forbidden contrasts") bias our estimate of the ATT but hadn't earlier?

3. 

![\Large x=\frac{-b\pm\sqrt{b^2-4ac}}{2a}](https://latex.codecogs.com/svg.latex?\Large&space;x=\frac{-b\pm\sqrt{b^2-4ac}}{2a}) 

