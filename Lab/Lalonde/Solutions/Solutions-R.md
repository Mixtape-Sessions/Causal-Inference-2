
# Lalonde

The National Supported Work (NSW) Demonstration dataset is one of the
most commonly used dataset in econometrics based on [Lalonde
(1986)](https://business.baylor.edu/scott_cunningham/teaching/lalonde-1986.pdf)
and [Dehejia and Wahba
(2002)](https://business.baylor.edu/scott_cunningham/teaching/dehejia-and-wahba-2002.pdf).
Both the original 1986 article by Lalonde as well as the follow-up
articles by Dehejia and Wahba used the data to evaluate contemporary
approaches to causal inference using non-experimental data. Cleverly,
they start with an experimental dataset to establish ‘true’ causal
effect and then use a non-experimental dataset consisting of a control
group of randomly sampled American households to see if covariate
adjustment can recover causal effects under fairly dramatic selection
problems.

In [Causal Inference 1](github.com/Mixtape-Sessions/Causal-Inference-1),
we have already shown that the nonexperimental dataset suffers from
severe negative selection into the job trainings program. Simple
comparisons often found negative effects of job training on earnings
despite the fact the program had an average positive effect of around
\$1700 higher real earnings in 1978. That lab found that some selection
on observable methods like propensity score weighting and nearest
neighbor matching recovered causal effects close to that found using
experimental data.

In this lab, we will study the performance of several
difference-in-differences estimators using both the experimental and
non-experimental datasets.

1.  We will first perform analysis on the experimental dataset
    `https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Labs/Lalonde/lalonde_exp_panel.dta`

``` r
library(tidyverse)
library(fixest)
library(DRDID) # devtools::install_github("pedrohcgs/DRDID")
library(haven)

# 1. Experimental data
df_exp <- haven::read_dta("https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_exp_panel.dta")
```

1.  Under random assignment, the simple difference-in-means identifies
    the ATE, and since the original NSW was a randomized experiment, we
    can do this. Calculate the simple difference-in-means on the
    experimental dataset to estimate the “treatment effect” two separate
    ways: (1) manually calculate averages for both treatment
    (`ever_treated=1`) and control (`ever_treated=0`) and use them to
    estimate the returns to the program, and (2) estimate the effect
    with an OLS specification. In both cases, use only the year `78` and
    `re` variable for real earnings.

``` r
# ---- Difference-in-means - Averages
with(df_exp, {
  y11 = mean(re[year == 78 & ever_treated == 1])
  y01 = mean(re[year == 78 & ever_treated == 0])

  dim = y11 - y01
  dim
})
```

    [1] 1794.342

``` r
# ---- Difference-in-means - OLS
feols(
  re ~ i(treat),
  data = df_exp |> filter(year == 78), vcov = "hc1"
)
```

    OLS estimation, Dep. Var.: re
    Observations: 445 
    Standard-errors: Heteroskedasticity-robust 
                Estimate Std. Error  t value  Pr(>|t|)    
    (Intercept)  4554.80    340.204 13.38845 < 2.2e-16 ***
    treat::1     1794.34    670.824  2.67483 0.0077534 ** 
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 6,564.7   Adj. R2: 0.015606

2.  Estimate the effect of the treatment, `ever_treated`, on real
    earnings, `re`, in a difference-in-differences estimator using years
    `78` for post period and `75` as the pre-period (ignoring for now
    year `74`). As with 1a, do this in the following two ways: (1)
    manually calculate the four means you need for the DiD equation and
    then estimate using the DiD equation, and (2) estimate the ATT using
    the OLS specification for the DiD equation with robust standard
    errors. Reminder to only use `78` and `75` (i.e., do not include
    `74` in OLS analysis).

``` r
# ---- Difference-in-Differences - Averages
with(df_exp, {
  y00 = mean(re[year == 75 & ever_treated == 0])
  y01 = mean(re[year == 78 & ever_treated == 0])
  y10 = mean(re[year == 75 & ever_treated == 1])
  y11 = mean(re[year == 78 & ever_treated == 1])

  did = (y11 - y10) - (y01 - y00)
  did
})
```

    [1] 1529.196

``` r
# ---- Difference-in-Differences - OLS
feols(
  re ~ i(treat) | id + year, 
  data = df_exp |> filter(year %in% c(75, 78)), 
  vcov = "hc1"
)
```

    OLS estimation, Dep. Var.: re
    Observations: 890 
    Fixed-effects: id: 445,  year: 2
    Standard-errors: Heteroskedasticity-robust 
             Estimate Std. Error t value Pr(>|t|)    
    treat::1   1529.2    714.956 2.13887 0.032992 *  
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 3,524.5     Adj. R2: 0.189077
                    Within R2: 0.011302

3.  Check the pre-trends for 1974 relative to 1975 two ways: (1)
    manually calculate the DiD equation on 1974 relative to 1975 and (2)
    estimate the dynamic OLS specification with an interaction of
    `ever_treated` with `74`, an interaction of `ever_treated` with
    `78`. Compare your answers for 2c to what you found in 2a and 2b.

``` r
# ---- Event study and pre-trends using manually calculated averages
with(df_exp, {
  y00 = mean(re[year == 75 & ever_treated == 0])
  y01 = mean(re[year == 74 & ever_treated == 0])
  y10 = mean(re[year == 75 & ever_treated == 1])
  y11 = mean(re[year == 74 & ever_treated == 1])

  did = (y11 - y10) - (y01 - y00)
  did
})
```

    [1] -276.5993

``` r
# ---- Event study and pre-trends using OLS 

df_exp$pre = df_exp$ever_treated * (df_exp$year == 74)
df_exp$post = df_exp$ever_treated * (df_exp$year == 78)

feols(
  re ~ i(post) + i(pre) | id + year, 
  data = df_exp, 
  vcov = "hc1"
)
```

    OLS estimation, Dep. Var.: re
    Observations: 1,335 
    Fixed-effects: id: 445,  year: 3
    Standard-errors: Heteroskedasticity-robust 
            Estimate Std. Error   t value Pr(>|t|)    
    post::1 1529.196    687.872  2.223082 0.026462 *  
    pre::1  -276.599    539.640 -0.512562 0.608385    
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 3,828.4     Adj. R2: 0.274114
                    Within R2: 0.010343

2.  Now, we turn to the non-experimental dataset
    `https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Labs/Lalonde/lalonde_nonexp_panel.dta`.

``` r
# 2. CPS data
df_nonexp <- haven::read_dta("https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_nonexp_panel.dta")
```

1.  Repeat 1a (simple difference-in-means for `78` only), 1b (DiD using
    manual calculations and OLS specification for `78` and `75` only)
    and 1c (event study calculations manually and dynamic OLS
    specification for `78`, `75` and `74`)

``` r
# ---- Difference-in-means - Averages
with(df_nonexp, {
  mean(re[year == 78 & ever_treated == 1]) -
    mean(re[year == 78 & ever_treated == 0])
})
```

    [1] -8497.516

``` r
# ---- Difference-in-means - OLS
feols(
  re ~ i(treat),
  data = df_exp |> filter(year == 78), vcov = "hc1"
)
```

    OLS estimation, Dep. Var.: re
    Observations: 445 
    Standard-errors: Heteroskedasticity-robust 
                Estimate Std. Error  t value  Pr(>|t|)    
    (Intercept)  4554.80    340.204 13.38845 < 2.2e-16 ***
    treat::1     1794.34    670.824  2.67483 0.0077534 ** 
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 6,564.7   Adj. R2: 0.015606

``` r
# ---- Difference-in-Differences - Averages
with(df_nonexp, {
  y00 = mean(re[year == 75 & ever_treated == 0])
  y01 = mean(re[year == 78 & ever_treated == 0])
  y10 = mean(re[year == 75 & ever_treated == 1])
  y11 = mean(re[year == 78 & ever_treated == 1])

  did = (y11 - y10) - (y01 - y00)
  did
})
```

    [1] 3621.232

``` r
# ---- Difference-in-Differences - OLS
feols(
  re ~ i(treat) | id + year, 
  data = df_nonexp |> filter(year %in% c(75, 78)),
  vcov = "hc1"
)
```

    OLS estimation, Dep. Var.: re
    Observations: 32,354 
    Fixed-effects: id: 16,177,  year: 2
    Standard-errors: Heteroskedasticity-robust 
             Estimate Std. Error t value   Pr(>|t|)    
    treat::1  3621.23    609.868 5.93773 2.9491e-09 ***
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 3,858.1     Adj. R2: 0.670904
                    Within R2: 0.002483

``` r
# ---- Event study and pre-trends using manually calculated averages
with(df_nonexp, {
  y00 = mean(re[year == 75 & ever_treated == 0])
  y01 = mean(re[year == 74 & ever_treated == 0])
  y10 = mean(re[year == 75 & ever_treated == 1])
  y11 = mean(re[year == 74 & ever_treated == 1])

  did = (y11 - y10) - (y01 - y00)
  did
})
```

    [1] 197.5215

``` r
# ---- Event study and pre-trends using OLS 

df_nonexp$pre = df_nonexp$ever_treated * (df_nonexp$year == 74)
df_nonexp$post = df_nonexp$ever_treated * (df_nonexp$year == 78)

feols(
  re ~ i(post) + i(pre) | id + year, 
  data = df_nonexp, 
  vcov = "hc1"
)
```

    OLS estimation, Dep. Var.: re
    Observations: 48,531 
    Fixed-effects: id: 16,177,  year: 3
    Standard-errors: Heteroskedasticity-robust 
            Estimate Std. Error  t value   Pr(>|t|)    
    post::1 3621.232    577.183 6.273972 3.5640e-10 ***
    pre::1   197.522    431.728 0.457513 6.4731e-01    
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 4,073.4     Adj. R2: 0.72694
                    Within R2: 0.00188

2.  Repeat 1b and 1c (OLS specifications) controlling linearly for
    `age, agesq, agecube, educ, educsq, marr, nodegree, black, hisp`
    with robust standard errors.

``` r
# ---- Difference-in-differeces - OLS with covariates 
# age, agesq, agecube, educ, educsq, marr, nodegree, black, hisp
feols(re ~ i(post) + age + agesq + agecube + educ + educsq +
  marr + nodegree + black + hisp | ever_treated + year, 
   data = df_nonexp,
   vcov = "hc1"
)
```

    OLS estimation, Dep. Var.: re
    Observations: 48,531 
    Fixed-effects: ever_treated: 2,  year: 3
    Standard-errors: Heteroskedasticity-robust 
                 Estimate Std. Error   t value   Pr(>|t|)    
    post::1   3522.471290 664.595928   5.30017 1.1620e-07 ***
    age       3064.963427 122.595591  25.00060  < 2.2e-16 ***
    agesq      -66.596546   3.679051 -18.10156  < 2.2e-16 ***
    agecube      0.463888   0.034921  13.28381  < 2.2e-16 ***
    educ       914.147339  66.589112  13.72818  < 2.2e-16 ***
    educsq     -33.970475   2.800199 -12.13145  < 2.2e-16 ***
    marr      3329.034931 105.472209  31.56315  < 2.2e-16 ***
    nodegree -1001.024881 122.001842  -8.20500 2.3620e-16 ***
    black    -2159.036745 143.815162 -15.01258  < 2.2e-16 ***
    hisp      -962.553918 146.958309  -6.54984 5.8171e-11 ***
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 8,374.6     Adj. R2: 0.230409
                    Within R2: 0.216879

3.  Use the `DRDID` command to estimate a doubly-robust
    difference-in-differences with covariates
    `age + agesq + agecube + educ + educsq + marr + nodegree + black + hisp`,
    `id` panel unit identifier, `year` as the panel time identifier, and
    reporting the outcome regression analysis [(Heckman, Ichimura and
    Todd
    1997)](http://jenni.uchicago.edu/papers/Heckman_Ichimura-Todd_REStud_v64-4_1997.pdf),
    inverse probability weight estimator [(Abadie
    2005)](https://academic.oup.com/restud/article-abstract/72/1/1/1581053?redirectedFrom=fulltext),
    doubly robust [(Sant’anna and Zhao
    2020)](https://www.sciencedirect.com/science/article/abs/pii/S0304407620301901).
    Compare these results with 1a, 1b, 2a and 2b.

``` r
# ---- Double-robust DID
DRDID::drdid(
  yname = "re", tname = "year", idname = "id", dname = "ever_treated", 
  xformla = ~ age + agesq + agecube + educ + educsq +
    marr + nodegree + black + hisp + re74 + u74,
  data = df_nonexp |> filter(year == 75 | year == 78)
)
```

     Call:
    DRDID::drdid(yname = "re", tname = "year", idname = "id", dname = "ever_treated", 
        xformla = ~age + agesq + agecube + educ + educsq + marr + 
            nodegree + black + hisp + re74 + u74, data = filter(df_nonexp, 
            year == 75 | year == 78))
    ------------------------------------------------------------------
     Further improved locally efficient DR DID estimator for the ATT:
     
       ATT     Std. Error  t value    Pr(>|t|)  [95% Conf. Interval] 
    2032.9217   707.4779    2.8735     0.0041    646.265   3419.5784 
    ------------------------------------------------------------------
     Estimator based on panel data.
     Outcome regression est. method: weighted least squares.
     Propensity score est. method: inverse prob. tilting.
     Analytical standard error.
    ------------------------------------------------------------------
     See Sant'Anna and Zhao (2020) for details.
