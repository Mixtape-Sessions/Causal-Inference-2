
# Lalonde

This dataset is one of the most commonly used dataset in econometrics
based on [Lalonde
(1986)](https://econpapers.repec.org/article/aeaaecrev/v_3a76_3ay_3a1986_3ai_3a4_3ap_3a604-20.htm)
and [Dehejia and Wahba
(2002)](https://www.uh.edu/~adkugler/Dehejia&Wahba.pdf). Both the paper
by Lalonde and Dehejia and Wahba both wanted to evaluate causal
inference methods using non-experimental data. Cleverly, they start with
an experimental dataset to estimate the ‘true’ causal effect and then
use non-experimental data to evaluate an econometric method.

In [Causal Inference 1](github.com/Mixtape-Sessions/Causal-Inference-1),
we have already shown that the nonexperimental dataset performs poorly
at estimating the effects of a job training program on earnings, finding
a substantial negative effect. That lab shows that matching-based
methods are effective at recovering effects close to the experimental
effect. This lab will study difference-in-differences estimators of the
effects.

1.  We will first perform analysis on the experimental dataset
    `https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Labs/Lalonde/lalonde_exp_panel.dta`

``` r
library(tidyverse)
```

    ── Attaching packages ─────────────────────────────────────── tidyverse 1.3.1 ──

    ✔ ggplot2 3.3.6     ✔ purrr   0.3.4
    ✔ tibble  3.1.7     ✔ dplyr   1.0.9
    ✔ tidyr   1.2.0     ✔ stringr 1.4.0
    ✔ readr   2.1.2     ✔ forcats 0.5.1

    ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
    ✖ dplyr::filter() masks stats::filter()
    ✖ dplyr::lag()    masks stats::lag()

``` r
library(fixest)
library(DRDID) # devtools::install_github("pedrohcgs/DRDID")
library(haven)

# 1. Experimental data
df_exp <- haven::read_dta("https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_exp_panel.dta")
```

1.  As a reminder, perform a simple difference-in-means on the
    experimental dataset to estimate the “treatment effect”. Use only
    the year `78` and compare average real earnings for the treated and
    the control groups. This is our baseline estimate of the treatment
    effect

``` r
# ---- Difference-in-means
feols(
  re ~ i(treat),
  data = df_exp[df_exp$year == 78, ], vcov = "hc1"
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

2.  Estimate the effect of treatment, `treat`, on real-earnings, `re` in
    a difference-in-differences estimator. This will be the “true”
    treatment effect estimate that we will try to recreate with the
    non-experimental CPS sample.

``` r
# ---- Difference-in-Differences Estimate
feols(
  re ~ i(treat) | id + year, 
  data = df_exp, vcov = "hc1"
)
```

    OLS estimation, Dep. Var.: re
    Observations: 1,335 
    Fixed-effects: id: 445,  year: 3
    Standard-errors: Heteroskedasticity-robust 
             Estimate Std. Error t value Pr(>|t|)    
    treat::1   1667.5    658.711 2.53145 0.011531 *  
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 3,828.8     Adj. R2: 0.274779
                    Within R2: 0.010134

2.  Now, we turn to the non-experimental dataset
    `https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Labs/Lalonde/lalonde_nonexp_panel.dta`.

``` r
# 2. CPS data
df_nonexp <- haven::read_dta("https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_nonexp_panel.dta")
```

1.  As a reminder, perform a simple difference-in-means on the combined
    dataset to estimate the “treatment effect”. Use only the year `78`
    and compare average real earnings for the treated and the control
    groups.

``` r
# ---- Difference-in-means
feols(
  re ~ i(treat),
  data = df_nonexp[df_nonexp$year == 78, ], vcov = "hc1"
)
```

    OLS estimation, Dep. Var.: re
    Observations: 16,177 
    Standard-errors: Heteroskedasticity-robust 
                Estimate Std. Error  t value  Pr(>|t|)    
    (Intercept) 14846.66    76.2907 194.6063 < 2.2e-16 ***
    treat::1    -8497.52   581.9158 -14.6027 < 2.2e-16 ***
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 9,628.4   Adj. R2: 0.008667

2.  Estimate a difference-in-differences estimator for the
    non-experimental group.

``` r
# ---- Initial Difference-in-difference
feols(
  re ~ i(treat) | id + year, 
  data = df_nonexp, vcov = "hc1"
)
```

    OLS estimation, Dep. Var.: re
    Observations: 48,531 
    Fixed-effects: id: 16,177,  year: 3
    Standard-errors: Heteroskedasticity-robust 
             Estimate Std. Error t value   Pr(>|t|)    
    treat::1  3522.47    549.319 6.41244 1.4518e-10 ***
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 4,073.4     Adj. R2: 0.726947
                    Within R2: 0.001875

3.  Use the `DRDID` command to estimate a doubly-robust DID with
    covariates
    `age + agesq + agecube + educ + educsq + marr + nodegree + black + hisp`

``` r
# ---- Double-robust DID
drdid(
  yname = "re", tname = "year", idname = "id", dname = "ever_treated", 
  xformla = ~ age + agesq + agecube + educ + educsq +
    marr + nodegree + black + hisp + re74 + u74,
  data = df_nonexp %>% filter(year == 75 | year == 78)
)
```

     Call:
    drdid(yname = "re", tname = "year", idname = "id", dname = "ever_treated", 
        xformla = ~age + agesq + agecube + educ + educsq + marr + 
            nodegree + black + hisp + re74 + u74, data = df_nonexp %>% 
            filter(year == 75 | year == 78))
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
