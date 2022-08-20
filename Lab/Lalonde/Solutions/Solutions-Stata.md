
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

``` stata
* ssc install drdid, replace
clear
use "https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_exp_panel.dta", clear 
```

1.  As a reminder, perform a simple difference-in-means on the
    experimental dataset to estimate the “treatment effect”. Use only
    the year `78` and compare average real earnings for the treated and
    the control groups. This is our baseline estimate of the treatment
    effect

``` stata
* Difference-in-means
reg re i.treat if year == 78, r
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...



    Linear regression                               Number of obs     =        445
                                                    F(1, 443)         =       7.15
                                                    Prob > F          =     0.0078
                                                    R-squared         =     0.0178
                                                    Root MSE          =     6579.5

    ------------------------------------------------------------------------------
                 |               Robust
              re |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
         1.treat |   1794.342   670.8245     2.67   0.008     475.9486    3112.736
           _cons |   4554.801   340.2038    13.39   0.000     3886.187    5223.415
    ------------------------------------------------------------------------------

2.  Estimate the effect of treatment, `treat`, on real-earnings, `re` in
    a difference-in-differences estimator. This will be the “true”
    treatment effect estimate that we will try to recreate with the
    non-experimental CPS sample.

``` stata
* Difference-in-differences
reghdfe re i.treat, absorb(id year) vce(robust)
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...


    (MWFE estimator converged in 2 iterations)

    HDFE Linear regression                            Number of obs   =      1,335
    Absorbing 2 HDFE groups                           F(   1,    887) =       6.41
                                                      Prob > F        =     0.0115
                                                      R-squared       =     0.5178
                                                      Adj R-squared   =     0.2748
                                                      Within R-sq.    =     0.0101
                                                      Root MSE        =  4697.2672

    ------------------------------------------------------------------------------
                 |               Robust
              re |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
         1.treat |   1667.496   658.7107     2.53   0.012     374.6824    2960.309
           _cons |   2695.646   147.0073    18.34   0.000     2407.124    2984.169
    ------------------------------------------------------------------------------

    Absorbed degrees of freedom:
    -----------------------------------------------------+
     Absorbed FE | Categories  - Redundant  = Num. Coefs |
    -------------+---------------------------------------|
              id |       445           0         445     |
            year |         3           1           2     |
    -----------------------------------------------------+

2.  Now, we turn to the non-experimental dataset
    `https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Labs/Lalonde/lalonde_nonexp_panel.dta`.

``` stata
* 2. CPS data
use "https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_nonexp_panel.dta", clear 
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...

1.  As a reminder, perform a simple difference-in-means on the combined
    dataset to estimate the “treatment effect”. Use only the year `78`
    and compare average real earnings for the treated and the control
    groups.

``` stata
* Difference-in-means
reg re i.treat if year == 78, r
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...



    Linear regression                               Number of obs     =     16,177
                                                    F(1, 16175)       =     213.24
                                                    Prob > F          =     0.0000
                                                    R-squared         =     0.0087
                                                    Root MSE          =       9629

    ------------------------------------------------------------------------------
                 |               Robust
              re |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
         1.treat |  -8497.516   581.9158   -14.60   0.000    -9638.135   -7356.897
           _cons |   14846.66   76.29073   194.61   0.000     14697.12     14996.2
    ------------------------------------------------------------------------------

2.  Estimate a difference-in-differences estimator for the
    non-experimental group.

``` stata
* Initial Difference-in-difference
reghdfe re i.treat, absorb(id year) vce(robust)
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...


    (MWFE estimator converged in 2 iterations)

    HDFE Linear regression                            Number of obs   =     48,531
    Absorbing 2 HDFE groups                           F(   1,  32351) =      41.12
                                                      Prob > F        =     0.0000
                                                      R-squared       =     0.8180
                                                      Adj R-squared   =     0.7269
                                                      Within R-sq.    =     0.0019
                                                      Root MSE        =  4989.0649

    ------------------------------------------------------------------------------
                 |               Robust
              re |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
         1.treat |   3522.471   549.3185     6.41   0.000     2445.786    4599.156
           _cons |   14033.96   22.70983   617.97   0.000     13989.45    14078.47
    ------------------------------------------------------------------------------

    Absorbed degrees of freedom:
    -----------------------------------------------------+
     Absorbed FE | Categories  - Redundant  = Num. Coefs |
    -------------+---------------------------------------|
              id |     16177           0       16177     |
            year |         3           1           2     |
    -----------------------------------------------------+

3.  Use the `DRDID` command to estimate a doubly-robust DID with
    covariates
    `age + agesq + agecube + educ + educsq + marr + nodegree + black + hisp`

``` stata
* Doubly-robust DID
drdid re age agesq agecube educ educsq marr nodegree black hisp re74 u74 if year == 75 | year == 78, time(year) ivar(id) tr(ever_treated)
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...


    No estimator selected. Using default drimp

    Doubly robust difference-in-differences         Number of obs     =     32,354
    Outcome model  : weighted least squares
    Treatment model: inverse probability tilting
    ------------------------------------------------------------------------------
                 |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
    ATET         |
    ever_treated |
       (1 vs 0)  |   2032.922    707.456     2.87   0.004     646.3334     3419.51
    ------------------------------------------------------------------------------
