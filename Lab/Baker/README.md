# Differential timing using Andrew Baker simulation

Twoway fixed effects (TWFE) is a common estimator used with panel data or repeated cross sections which is part of its appeal for difference-in-differences with differential timing.  Differential timing is a scenario in which panel units, such as states or firms, are shocked with some intervention at different time periods.  Ten firms may be treated in 2010, another five firms in 2014, and the remaining firms in 2020.  If we are interested in estimating the causal effect of the intervention on firm outcomes using diff-in-diff, can we estimate the effect using TWFE? And if so, what causal effect are we estimating?

The purpose of this exercise is to illustrate the bias of TWFE with differential timing if treatment effects are dynamic and to show that it is not biased if treatment effects are not dynamic. We will decompose the aggregate coefficient estimated using TWFE into the weighted average of underlying diff-in-diff calculations using the [Goodman-Bacon (2021)](https://www.sciencedirect.com/science/article/abs/pii/S0304407621001445) decomposition. The second purpose of the exercise is to illustrate the concept of the group-time ATT parameter and show that [Callaway and Sant'anna (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620303948) estimates through manual calculations. Finally, we estimate various aggregate parameters both across groups and relative event time using both [Callaway and Sant'anna (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620303948) as well as [Sun and Abraham (2020)](https://www.sciencedirect.com/science/article/abs/pii/S030440762030378X). 

We will perform analysis on a simulated dataset that Andrew Baker (assistant professor, University of California Berkeley College of Law) created. This can be generated yourself using either baker.R or baker.do, or you can download it yourself https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Baker/baker.dta.

There are 40 states, 250 firms per state, each of which is observed for 30 years from 1980 to 2009 (i.e., a balanced panel of firms). Ten firms are treated in 1986, another 10 in 1992, another 10 in 1998 and another 10 in 2004. There are two outcomes: `y2` is firm revenue under constant treatment effects that are on average equal to 10 for group 1 (i.e., the 1986 group), 8 for group 2, 6 for group 3 and 4 for group 4. The second outcome is a different outcome scenario in which treatment effects grow over time at a constant slope: 10 in 1986, 20 in 1987, 30 in 1988 and so on. You can view this data construction in lines 98-102 of baker.do. Write down what you think the aggregate treatment effect on the treatment group should for `y2` versus `y`. 

1. For this first question, we will focus on `y2`, the constant treatment effect outcome measure. 

   a. Calculate the simple and group ATT using the information at this spreadsheet https://docs.google.com/spreadsheets/d/1dI67eNNE2zrX4KrkoFvej-cKxqHkM8yJdMpD-0uE4q8/edit?usp=sharing in the first tab labeled Constant DiD.

   b. Generate a dummy labeled `post` equalling 0 if a unit is not treated and 1 if it is the year of treatment or after. Estimate the effect of the treatment `post` on `y2` using TWFE with cluster robust standard errors. Compare your answer to the simple and group ATT you calculated in the spreadsheet.  Is your TWFE estimate biased?

   c. Decompose the TWFE estimated coefficient using the [Goodman-Bacon (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407621001445) decomposition using either `ddtiming` or `bacondecomp`. Why did the use of late-to-early DiD calculations ("forbidden contrasts") not bias our estimate of the ATT?

2. For this second question, we will focus on `y`, the dynamic treatment effect outcome measure.

   a. Calculate the simple and group ATT using the information at this spreadsheet https://docs.google.com/spreadsheets/d/1dI67eNNE2zrX4KrkoFvej-cKxqHkM8yJdMpD-0uE4q8/edit?usp=sharing in the second tab labeled Dynamic DiD. Why is the ATT under dynamics larger than the ATT under constant treatment effects?

   b. You can still use the same dummy as before `post` equalling 0 if a unit is not treated and 1 if it is the year of treatment or after. Now estimate the effect of the treatment `post` on `y` using TWFE with cluster robust standard errors. Compare your answer to the simple and group ATT you calculated in the second table of the spreadsheet.  Is your TWFE estimate biased?

   c. Decompose the TWFE estimated coefficient using the [Goodman-Bacon (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407621001445) decomposition using either `ddtiming` or `bacondecomp`. Why did the use of late-to-early DiD calculations ("forbidden contrasts") bias our estimate of the ATT but hadn't earlier?

   d. Bonus question. The error term is `~N(0,0.5^2)`. There are no covariates and there are no policies, so there are no omitted variables. The same error term was used to produce `y` as was `y2`. Parallel trends in `E[Y(0)]` is linear and holds even at the unit level. So if TWFE is unbiased in the first but not the second, and parallel trends holds, then it implies strict exogeneity is violated with `y` but not `y2`. How then is it possible that strict exogeneity is violated if the error term is independent of the treatment?

3. Next we will estimate various group-time ATT(g,t) parameters using [Callaway and Sant'anna (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620303948). For simplicity, we will use the inverse probability weighting method associated with [Abadie (2005)](https://academic.oup.com/restud/article-abstract/72/1/1/1581053) though feel free to try outcome regression and doubly robust too. As there are no coveriates, the results should not differ.  The calculation of a given ATT(g,t) is given by this formula:

   $$
      ATT(g,t) = E \bigg [ \bigg ( \frac{G_g}{E[G_g]} - \frac{ \frac{\hat{p}(X)C}{1-\hat{p}(X)}}{E \bigg [ \frac{\hat{p}(X)C}{1-\hat{p}(X)} \bigg ]} \bigg ) (Y_t - Y_{g-1} ) \bigg ) \bigg ] ]
   $$

   a. We know from the second tab of [the spreadsheet](https://docs.google.com/spreadsheets/d/1dI67eNNE2zrX4KrkoFvej-cKxqHkM8yJdMpD-0uE4q8/edit?usp=sharing) that the ATT(1986,1986) is equal to 10. Calculate this yourself using the above formula.

   b. Calculate the ATT(1986,1986) using the above [Callaway and Sant'anna (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620303948) formula. 

    - Calculate a dummy for group 1 called `g1`.
    
    - Calculate the propensity score called `pscore` equalling the probability a group is in group 1 using all untreated groups in 1986 plus group 1 itself using logit.
  
    - Calculate the following two variables: `ypre` equal to `y` in `1985` and `ypost` equal to `y` in `1986`.

    - Calculate the mean value of `g1` called `g1-mean` and the mean value of the inverse probability weight:

      $$
        (1-g1)\frac{pscore}{1-pscore}
      $$

      as `pscore-mean`

    - Calculate a weight called `w1` equal to $\frac{g1}{g1-mean}$ and a weight called `w0` equal to

    $$
      \frac{(1-g1)\frac{pscore}{1-pscore}}{pscore-mean}. 
    $$

    - Calculate the four group cells for the DiD calculation as weighted averages according to:

    $$
      ATT(1986,1986) = \left( w1 * y_{post} - w1 * y_{pre} \right) - \left( w0 * y_{post} - w0 * y_{pre} \right)
    $$

    - Compare your answer to the known ATT(1986,1986). 

   c. Repeat 2a for ATT(1986, 1987)
      
   d. Repeate 2a for ATT(1986, 1988)

4. Now we will estimate aggregate the group-time ATT using the [Callaway and Sant'anna (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620303948) estimator with bootstrapping. 

   a. First, establish the ground truth by aggregating the group time ATT(g,t) parameters using the data in the second tab into Simple ATT and group ATT at https://docs.google.com/spreadsheets/d/1dI67eNNE2zrX4KrkoFvej-cKxqHkM8yJdMpD-0uE4q8/edit?usp=sharing. Simple ATT is a simple average over all ATT (using uniform weights). Group ATT is an equally weighted average of ATT(1986), ATT(1992), ATT(1998) and ATT(2004). Compare these two parameters to one another.  How are the underlying ATT(g,t) parameters different?  How are the weights different?

   b. [Callaway and Sant'anna (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620303948) avoids the biases of TWFE by not calculating any ATT(g,t) for which there is no untreated comparison group.  It in other words does not attempt to calculate ATT parameters when there is full adoption. Repeat 3a calculating simple and group ATT under this `feasible` ATT scenario.  Compare these two ATT parameters with the one from 3a.

   c. Using either `csdid` in Stata or `did` in R, estimate the simple ATT and the group ATT using the `baker` dataset.  Plot the event-study coefficients for each group.

   d. Estimate the relative event study plot using the `dynamic` model. Which firms contribute to which set of leads and lags and why is it that the longer lags have fewer firms contributing?

5. Now we will estimate event studies using TWFE and [Sun and Abraham (2020)](https://www.sciencedirect.com/science/article/abs/pii/S030440762030378X). The command in stata is called `eventstudyinteract` but in R it is called `fixest`. 

   a. Before we get started, go to the tab labeled "Event Study" at (https://docs.google.com/spreadsheets/d/1dI67eNNE2zrX4KrkoFvej-cKxqHkM8yJdMpD-0uE4q8/edit?usp=sharing). Calculate the cohort ATT in relative event time (column H, rows 2 to 25) using the group-time ATT(g,t) parameters corresponding to each relative event time.  Use simple averages for each estimate. 
  
   b. Estimate an event study in relative event time using TWFE and if you have time, fill in column I. Compare your TWFE estimates against coluumn H.
  
   c. Estimate an event study in relative event time now using [Sun and Abraham (2020)](https://www.sciencedirect.com/science/article/abs/pii/S030440762030378X) and insert in column J.  Then do the same using [Callaway and Sant'anna (2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620303948?via%3Dihub) and insert in column K. Compare your answers both to one another, to TWFE and to the ground truth.
  
   d. What is the differences in the control groups used by CS vs SA?

6. In one final analysis, let's revisit the TWFE analysis from question 2 using `y` as the firm revenue outcome, only instead of using the entire dataset as we did before, use only the dataset used in part 4. 

   a. Compare your TWFE to CS and SA aggregate parameter estimate.  How has it changed and is it still biased?
   
   b. Conduct the Bacon decomposition on this shorter panel and compare the decomposition results to what you had done earlier.  What's changed and why?
   
   c. How did the weights on the forbidden contrasts change when you shortened the sample and used TWFE? 
