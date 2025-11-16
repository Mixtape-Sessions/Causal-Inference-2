********************************************************************************
* Tennessee Valley Authority Empirical Application
* by Kyle Butts
********************************************************************************

* ## Intro
* This exercise is going to work with data from Kline and Moretti (2014). This 
* paper aims to analyze the impacts of the "Tennessee Valley Authority" (TVA)
* on local agriculture and manufacturing employment. The TVA was a huge federal
* spending program in the 1940s that aimed at electrification of the region, 
* building hundreds of large dams (in Scott's terms, a ton of 'bite').
* 
* The region was centered in Tennessee and surrounding other southern states.
* The region had a large agriculture industry, but very little manufacturing. 
* Electrification brought in a lot industry, moving the economy away from
* agriculture. We are going to test for this in the data using census data 
* (recorded every 10 years). 
* 
* ![Tennessee Valley Authority Dam](img/tva_map.jpeg)
* 
* ![Tennessee Valley Authority Map](img/tva_dam.jpeg)
* 
* First, we will load our dataset:

  * cd "~/Desktop/Madrid-2024/Labs/Kline-Moretti/"

  use data/tva.dta, clear
  sum


* ## Question 1
* 
* We will perform the basic 2x2 DID using just the years 1940 and 1960.
* We will use as outcomes `ln_agriculture` and `ln_manufacturing`.
* 
* First, run the "classic" version using an indicator for treatment, `tva`, 
* and indicator for being the post-period, `post`, and the product of the two. 
* I recommend the package `fixest` for regression analysis. I'll be using it 
* in the solutions.

  cap drop tva_x_post
  gen tva_x_post = tva * post

  reghdfe ln_agriculture i.tva_x_post ///
    if (year == 1940 | year == 1960), ///
    absorb(tva post)
  est store agg_40_60

  reghdfe ln_manufacturing i.tva_x_post ///
    if (year == 1940 | year == 1960), ///
    absorb(tva post)
  est store man_40_60

* Second, we will see in the 2x2 DID case, using county and time fixed effects 

  reghdfe ln_agriculture i.tva_x_post ///
    if (year == 1940 | year == 1960), ///
    absorb(county_code year)
  est store agg_40_60_full

  reghdfe ln_manufacturing i.tva_x_post ///
    if (year == 1940 | year == 1960), ///
    absorb(county_code year)
  est store man_40_60_full

  * Report coefficients in table
  est table man_* agg_*


* ## Question 2
* 
* Moretti and Kline were nervous that the parallel trends assumption is 
* a bit of a strong assumption in the context. Why might that be in the 
* context of the Tennessee Valley Authority? 
* 
* Answer: The TVA was built in the Tenneessee area precisely because the area 
* was not developing a strong manufacturing base. It is unlikely in the 
* absence of treatment that counties in the TVA area were going to grow in 
* manufacturing the same as outside counties
* 
* Let's run a placebo analysis to test for this using 1920 as the pre-treatment
* period and 1930 as the post-treatment period. What does this tell us about 
* the plausability of a parallel trends type assumption?

  cap drop tva_x_1930
  gen tva_x_1930 = tva * (year == 1930)

  reghdfe ln_agriculture i.tva_x_1930 ///
    if (year == 1920 | year == 1930), ///
    absorb(county_code year)

  reghdfe ln_manufacturing i.tva_x_1930 ///
    if (year == 1920 | year == 1930), ///
    absorb(county_code year)


* ## Question 3
* 
* Let's put this analysis together and run an event-study regression using 
* the full dataset
* 
* To do this, create a set of dummy variables that interact year with 
* treatment status. Estimate the TWFE model with these dummy variables.

  * Generate tva x year variables
  cap drop tva_x_19*
  gen tva_x_1920 = tva * (year == 1920)
  gen tva_x_1930 = tva * (year == 1930)
  gen tva_x_1940 = tva * (year == 1940)
  gen tva_x_1950 = tva * (year == 1950)
  gen tva_x_1960 = tva * (year == 1960)

  * Event-study estimate
  reghdfe ln_agriculture ///
    i.tva_x_1920 i.tva_x_1930 i.tva_x_1950 i.tva_x_1960, ///
    absorb(county_code year)
  est store agg_es

  reghdfe ln_manufacturing ///
    i.tva_x_1920 i.tva_x_1930 i.tva_x_1950 i.tva_x_1960, ///
    absorb(county_code year)
  est store man_es

  est table *_es

* ## Question 4

  gen tva_x_year = cond(tva, year, 1940)
  reghdfe ln_manufacturing ///
    ib1940.tva_x_year, ///
    absorb(county_code year) noconstant
  
  * I don't know how to add the 0 for 1940 or the line extension on stata :-) 
  coefplot, vertical yline(0) ciopts(recast(rcap)) xlabel(,angle(45))

  * Using HonestDiD: https://github.com/mcaceresb/stata-honestdid#honestdid
  honestdid, pre(1/2) post(3/4) mvec(0.25(0.5)1.5)
  honestdid, coefplot cached

  matrix avg_l_vec = 0.5 \ 0.5
  matrix first_l_vec = 1 \ 0
  matrix second_l_vec = 0 \ 1
  * honestdid, pre(1/2) post(3/4) mvec(0.25(0.5)1.5) l_vec(avg_l_vec) coefplot
  * honestdid, pre(1/2) post(3/4) mvec(0.25(0.5)1.5) l_vec(first_l_vec) coefplot
  * honestdid, pre(1/2) post(3/4) mvec(0.25(0.5)1.5) l_vec(second_l_vec) coefplot


* ## Question 5
* 
* Let's use some controls to weaken the assumption to conditional
* parallel trends. In particular, we are going to use a few covariates: 
* `agriculture_share_1920`, `agriculture_share_1930`, 
* `manufacturing_share_1920`, and `manufacturing_share_1930`. 
* 
* What happens if we add those controls in linearly to our original estimate?

  reghdfe ln_agriculture ///
    i.tva_x_1920 i.tva_x_1930 i.tva_x_1950 i.tva_x_1960 ///
    agriculture_share* manufacturing_share*, ///
    absorb(county_code year)

* *Answer:* The covariates are dropped because they are collinear with the
* county fixed effects.
* 
* The term $X_i \beta$ just causes a level shift in outcomes. This is not what
* we want. We really want to allow for the *trends* in outcomes to vary by
* covariate values. The simplest way to do this is to change our model to
* interact covariates with indicators for each year $X_i * 1(t = s) \beta$ for
* each year $s$. This is often written more simply as $X_i \beta_t$ which lets
* $beta$ vary by year.
* 
* If you take first-differences, you end up with
* $$
*  X_i \beta_t - X_i \beta_{t-1} = X_i (\beta_t - \beta_{t-1}),
* $$
* which says changes in outcome over time depend on your value of $X_i$.


* ## Question 6
* 
* This question shows different weighs to incorporate covariates in a 2x2 difference-in-differences estimator. The goal is to relax our parallel trends assumption to be conditional on X:
* $$
*   E(Y_{i1}(0) - Y_{i1}(0) | D = 1, X = x) = E(Y_{i1}(0) - Y_{i1}(0) | D = 0, X = x).
* $$
* 
* In words, this assumption says "take treated and control units with the same value of $X$. These units on average have the same counterfactual trend". Full details to help with this question are given below in the appendix notes. This question will walk you through three different covariates-based estimators of ATTs: outcome regression, inverse propensity of treatment weighting, and a doubly-robust combination of the two. 
* 
* Note: Some of the data contains missing values for the covariates. Subset the data using `county_has_no_missing == TRUE` (for later).

  keep if county_has_no_missing == 1
  
  egen county_code_numeric = group(county_code)
  xtset county_code_numeric year
  gen D_ln_manufacturing = ln_manufacturing - l20.ln_manufacturing

  preserve
  keep if year == 1960

* ### Part 1: Difference-in-Differences
* Take first-differences of the outcome variable to form $\Delta Y$. Create a new dataset that collapses the dataset using first-differences for the outcome variables (each county should be a single row in the dataset). 
* 
* In part a, estimate the normal difference-in-differences estimate. Additionally, run a second model that linearly controls for `agriculture_share_1920`, `agriculture_share_1930`, `manufacturing_share_1920`, and `manufacturing_share_1930`.

  reg D_ln_manufacturing i.tva, r
  global X = "manufacturing_share_* agriculture_share_*"
  reg D_ln_manufacturing i.tva $X, r

* ### Part 2: Outcome Regression
* 
* Including covariates linearly is very simple and intuitively it allows for $X_i$-specific trends. However, this assumes that treatment effects can not vary by the value of $X$. For example, say $X$ is a dummy variable for age. Then you are allowing for gender-specific trends, but you are not allowing for treatment effects to vary by age. Note, this problem is only with continuous covariates in X_i, we won't estimate the ATT (see Angrist 1998 or Słoczyński 2022). 
* 
* Instead, we want to use outcome regression when doing covariate adjustment in the outcome model. First, regress `D_ln_y` on the four covariates *using just the untreated observations* (`tva == 0`). This estimates $E(\Delta y | X, D = 0)$. 
* 
* Second, predict out of sample this model for the full dataset. Let's call this `D_ln_y0_hat`. Last, take the difference between `D_ln_y` and the predicted `D_ln_y0_hat` and average this for the treated group (`tva == 1`). This is our outcome regression estimate.

  reg D_ln_manufacturing $X if tva == 0, r
  predict Dy0_hat, xb

  gen Dy = D_ln_manufacturing
  gen D = tva

  * Form weights
  egen mean_D = mean(D)
  gen w1 = D / mean_D
  
  gen t_or = (w1 * Dy) - (w1 * Dy0_hat)
  sum t_or


* ### Part 3: Inverse Probability of Treatment Weighting
* 
* Now, lets use a propensity score method. Estimate a logistic regression of $D$ on the covariates $X$ using the full sample. Predict fitted propensity scores of this model. 
* 
* Form the weights $w_1$ and $w_0$ as written in the appendix and form the IPTW estimate.

  logit tva $X
  predict ps

  * Generate propensity score weights for units
  cap drop w1 
  gen w1 = D / mean_D
  gen w0 = (1 - D) / mean_D * ps / (1 - ps)

  gen t_iptw = (w1 * Dy) - (w0 * Dy)
  sum t_iptw

* ### Part 4: Doubly-Robust DID Estimator
* 
* From the previous questions, you have all the parts to estimate the doubly-robust DID estimator. Do this.

  gen t_dr = (w1 * (Dy - Dy0_hat)) -(w0 * (Dy - Dy0_hat))
  sum t_dr

* ## Question 7
* 
* Now, let’s try using the `DRDID` package to do this more simply.
* 
* Note: DRDID requires the `idname` to be a numeric, so you need to create a new variable for this.
* 
* Note: DRDID requires the `idname` to be a numeric, so I'm using
* `encode` to create unique integer for each county

  * ssc install drdid
  
  * get back full panel
  restore
  
  * Filter to counties that have no missing covariates
  keep if county_has_no_missing == 1
  
  * Outcome Regression
  drdid ln_manufacturing $X ///
    if (year == 1940 | year == 1960), ///
    ivar(county_code_numeric) time(year) treatment(tva) ///
    reg

  * Inverse Probability of Treatment Weighting
  drdid ln_manufacturing $X ///
    if (year == 1940 | year == 1960), ///
    ivar(county_code_numeric) time(year) treatment(tva) ///
    ipw

  * DRDID
  drdid ln_manufacturing $X ///
    if (year == 1940 | year == 1960), ///
    ivar(county_code_numeric) time(year) treatment(tva) ///
    dripw

* ## Question 8
* 
* We are going to now use `did` to estimate an event study.
* As a default, `did` calls `DRDID` under the hood. Let's see this using 
* `did::att_gt`. We need to create a variable for "treatment timing groups", 
* i.e. what year a county starts treatment. The package takes the convention 
* that group = 0 for never-treated group.
* 

  * ssc install csdid

  * = 0 for never-treated, = 1950 for TVA counties
  cap drop g 
  gen g = tva * 1945

  csdid ln_manufacturing $X, ///
    ivar(county_code_numeric) time(year) gvar(g) dripw
  csdid_plot, group(1945)

