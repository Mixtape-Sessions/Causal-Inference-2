
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

``` stata
* ssc install drdid, replace
clear
use "https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_exp_panel.dta", clear 
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

``` stata
* Difference-in-means - Averages
summarize re if ever_treated==1 & year==78 // $6349.144
summarize re if ever_treated==0 & year==78 // $4554.801

display 6349.144 - 4554.801

* Difference-in-means - OLS
reg re i.ever_treated if year == 78, robust
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...

        Variable |        Obs        Mean    Std. Dev.       Min        Max
    -------------+---------------------------------------------------------
              re |        185    6349.144    7867.402          0   60307.93

        Variable |        Obs        Mean    Std. Dev.       Min        Max
    -------------+---------------------------------------------------------
              re |        260    4554.801    5483.836          0   39483.53

    1794.343


    Linear regression                               Number of obs     =        445
                                                    F(1, 443)         =       7.15
                                                    Prob > F          =     0.0078
                                                    R-squared         =     0.0178
                                                    Root MSE          =     6579.5

    --------------------------------------------------------------------------------
                   |               Robust
                re |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
    ---------------+----------------------------------------------------------------
    1.ever_treated |   1794.342   670.8245     2.67   0.008     475.9486    3112.736
             _cons |   4554.801   340.2038    13.39   0.000     3886.187    5223.415
    --------------------------------------------------------------------------------

2.  Estimate the effect of the treatment, `ever_treated`, on real
    earnings, `re`, in a difference-in-differences estimator using years
    `78` for post period and `75` as the pre-period (ignoring for now
    year `74`). As with 1a, do this in the following two ways: (1)
    manually calculate the four means you need for the DiD equation and
    then estimate using the DiD equation, and (2) estimate the ATT using
    the OLS specification for the DiD equation with robust standard
    errors. Reminder to only use `78` and `75` (i.e., do not include
    `74` in OLS analysis).

``` stata
* Difference-in-differences - Averages
egen y00=mean(re) if ever_treated==0 & year==75
egen y01=mean(re) if ever_treated==0 & year==78
egen y10=mean(re) if ever_treated==1 & year==75
egen y11=mean(re) if ever_treated==1 & year==78

egen ey00 = max(y00)
egen ey01 = max(y01)
egen ey10 = max(y10)
egen ey11 = max(y11)

gen did = (ey11 - ey10) - (ey01 - ey00)
sum did
drop y00-did

* Difference-in-differences - OLS
gen post        = 0 if year==75
replace post    = 1 if year==78
reg re ever_treated##post, robust 
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...


    (1075 missing values generated)

    (1075 missing values generated)

    (1150 missing values generated)

    (1150 missing values generated)

        Variable |        Obs        Mean    Std. Dev.       Min        Max
    -------------+---------------------------------------------------------
             did |      1,335    1529.196           0   1529.196   1529.196


    (890 missing values generated)

    (445 real changes made)


    Linear regression                               Number of obs     =        890
                                                    F(3, 886)         =      43.51
                                                    Prob > F          =     0.0000
                                                    R-squared         =     0.1382
                                                    Root MSE          =     5158.7

    -----------------------------------------------------------------------------------
                      |               Robust
                   re |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
    ------------------+----------------------------------------------------------------
       1.ever_treated |   265.1463   304.9998     0.87   0.385      -333.46    863.7526
               1.post |   3287.892   390.8905     8.41   0.000     2520.713    4055.071
                      |
    ever_treated#post |
                 1 1  |   1529.196   736.9059     2.08   0.038     82.91126    2975.481
                      |
                _cons |   1266.909   192.5014     6.58   0.000      889.097    1644.721
    -----------------------------------------------------------------------------------

3.  Check the pre-trends for 1974 relative to 1975 two ways: (1)
    manually calculate the DiD equation on 1974 relative to 1975 and (2)
    estimate the dynamic OLS specification with an interaction of
    `ever_treated` with `74`, an interaction of `ever_treated` with
    `78`. Compare your answers for 2c to what you found in 2a and 2b.

``` stata

* Event study and pre-trends using manually calculated averages
egen y00=mean(re) if ever_treated==0 & year==75
egen y01=mean(re) if ever_treated==0 & year==74
egen y10=mean(re) if ever_treated==1 & year==75
egen y11=mean(re) if ever_treated==1 & year==74

egen ey00 = max(y00)
egen ey01 = max(y01)
egen ey10 = max(y10)
egen ey11 = max(y11)

gen did = (ey11 - ey10) - (ey01 - ey00)
sum did
drop y00-did post

* Event study and pre-trends using OLS 
gen pre = 0
replace pre=1 if year==74
gen post = 0 
replace post = 1 if year==78

reg re ever_treated##post ever_treated##pre, robust
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...


    (1075 missing values generated)

    (1075 missing values generated)

    (1150 missing values generated)

    (1150 missing values generated)

        Variable |        Obs        Mean    Std. Dev.       Min        Max
    -------------+---------------------------------------------------------
             did |      1,335   -276.5991           0  -276.5991  -276.5991

    variable post not found
    r(111);

    end of do-file
    r(111);

2.  Now, we turn to the non-experimental dataset
    `https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Labs/Lalonde/lalonde_nonexp_panel.dta`.

``` stata
use "https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_nonexp_panel.dta", clear 
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...

1.  Repeat 1a (simple difference-in-means for `78` only), 1b (DiD using
    manual calculations and OLS specification for `78` and `75` only)
    and 1c (event study calculations manually and dynamic OLS
    specification for `78`, `75` and `74`)

``` stata
* Difference-in-means - Averages
summarize re if ever_treated==1 & year==78 // $6349.144
summarize re if ever_treated==0 & year==78 // $4554.801

display 6349.144 - 4554.801

* Difference-in-means - OLS
reg re i.ever_treated if year == 78, robust
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...

        Variable |        Obs        Mean    Std. Dev.       Min        Max
    -------------+---------------------------------------------------------
              re |        185    6349.144    7867.402          0   60307.93

        Variable |        Obs        Mean    Std. Dev.       Min        Max
    -------------+---------------------------------------------------------
              re |     15,992    14846.66    9647.392          0   25564.67

    1794.343


    Linear regression                               Number of obs     =     16,177
                                                    F(1, 16175)       =     213.24
                                                    Prob > F          =     0.0000
                                                    R-squared         =     0.0087
                                                    Root MSE          =       9629

    --------------------------------------------------------------------------------
                   |               Robust
                re |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
    ---------------+----------------------------------------------------------------
    1.ever_treated |  -8497.516   581.9158   -14.60   0.000    -9638.135   -7356.897
             _cons |   14846.66   76.29073   194.61   0.000     14697.12     14996.2
    --------------------------------------------------------------------------------

``` stata
* Difference-in-differences - Averages
egen y00=mean(re) if ever_treated==0 & year==75
egen y01=mean(re) if ever_treated==0 & year==78
egen y10=mean(re) if ever_treated==1 & year==75
egen y11=mean(re) if ever_treated==1 & year==78

egen ey00 = max(y00)
egen ey01 = max(y01)
egen ey10 = max(y10)
egen ey11 = max(y11)

gen did = (ey11 - ey10) - (ey01 - ey00)
sum did
drop y00-did

* Difference-in-differences - OLS
gen post        = 0 if year==75
replace post    = 1 if year==78
reg re ever_treated##post, robust 
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...


    (32539 missing values generated)

    (32539 missing values generated)

    (48346 missing values generated)

    (48346 missing values generated)

        Variable |        Obs        Mean    Std. Dev.       Min        Max
    -------------+---------------------------------------------------------
             did |     48,531    3621.233           0   3621.233   3621.233


    (32,354 missing values generated)

    (16,177 real changes made)


    Linear regression                               Number of obs     =     32,354
                                                    F(3, 32350)       =    1012.82
                                                    Prob > F          =     0.0000
                                                    R-squared         =     0.0179
                                                    Root MSE          =     9428.6

    -----------------------------------------------------------------------------------
                      |               Robust
                   re |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
    ------------------+----------------------------------------------------------------
       1.ever_treated |  -12118.75   247.1795   -49.03   0.000    -12603.23   -11634.27
               1.post |   1195.856   105.8044    11.30   0.000     988.4756    1403.237
                      |
    ever_treated#post |
                 1 1  |   3621.232    632.237     5.73   0.000     2382.024     4860.44
                      |
                _cons |    13650.8   73.30954   186.21   0.000     13507.11    13794.49
    -----------------------------------------------------------------------------------

``` stata

* Event study and pre-trends using manually calculated averages
egen y00=mean(re) if ever_treated==0 & year==75
egen y01=mean(re) if ever_treated==0 & year==74
egen y10=mean(re) if ever_treated==1 & year==75
egen y11=mean(re) if ever_treated==1 & year==74

egen ey00 = max(y00)
egen ey01 = max(y01)
egen ey10 = max(y10)
egen ey11 = max(y11)

gen did = (ey11 - ey10) - (ey01 - ey00)
sum did
drop y00-did post

* Event study and pre-trends using OLS 
gen pre = 0
replace pre=1 if year==74
gen post = 0 
replace post = 1 if year==78

reg re ever_treated##post ever_treated##pre, robust
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...


    (32539 missing values generated)

    (32539 missing values generated)

    (48346 missing values generated)

    (48346 missing values generated)

        Variable |        Obs        Mean    Std. Dev.       Min        Max
    -------------+---------------------------------------------------------
             did |     48,531    197.5214           0   197.5214   197.5214

    variable post not found
    r(111);

    end of do-file
    r(111);

2.  Repeat 1b and 1c (OLS specifications) controlling linearly for
    `age, agesq, agecube, educ, educsq, marr, nodegree, black, hisp`
    with robust standard errors.

``` stata
reg re ever_treated##post age agesq agecube educ educsq marr nodegree black hisp, robust
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...



    Linear regression                               Number of obs     =     48,531
                                                    F(12, 48518)      =    2101.41
                                                    Prob > F          =     0.0000
                                                    R-squared         =     0.2304
                                                    Root MSE          =     8377.1

    -----------------------------------------------------------------------------------
                      |               Robust
                   re |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
    ------------------+----------------------------------------------------------------
       1.ever_treated |  -6385.489   303.2459   -21.06   0.000    -6979.855   -5791.123
               1.post |   1012.858   85.42733    11.86   0.000      845.419    1180.296
                      |
    ever_treated#post |
                 1 1  |   3522.471   664.7319     5.30   0.000     2219.588    4825.354
                      |
                  age |   3064.963   122.6054    25.00   0.000     2824.655    3305.272
                agesq |  -66.59655   3.679685   -18.10   0.000    -73.80877   -59.38432
              agecube |   .4638878   .0349294    13.28   0.000     .3954258    .5323499
                 educ |   914.1473   66.59316    13.73   0.000     783.6239    1044.671
               educsq |  -33.97047   2.800125   -12.13   0.000    -39.45876   -28.48219
                 marr |   3329.035   105.4695    31.56   0.000     3122.313    3535.757
             nodegree |  -1001.025   122.0254    -8.20   0.000    -1240.196   -761.8536
                black |  -2159.037   143.8506   -15.01   0.000    -2440.986   -1877.088
                 hisp |  -962.5539   146.9593    -6.55   0.000    -1250.596   -674.5118
                _cons |  -36877.53   1380.915   -26.71   0.000    -39584.14   -34170.92
    -----------------------------------------------------------------------------------

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

``` stata
* Doubly-robust DID
drdid re age agesq agecube educ educsq marr nodegree black hisp re74 u74 if year == 75 | year == 78, time(year) ivar(id) tr(ever_treated) all
```

    running /Users/kylebutts/Documents/Mixtape-Sessions/Causal-Inference-2/Lab/Lalonde/Solutions/pro> e.do ...


    convergence not achieved
        The Gauss-Newton stopping criterion has been met but missing standard errors indicate some of
        the parameters are not identified.

    Doubly robust difference-in-differences estimator summary
    ------------------------------------------------------------------------------
                 |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
    ATET         |
           dripw |   1979.021   728.8671     2.72   0.007     550.4682    3407.575
           drimp |   2032.922    707.456     2.87   0.004     646.3334     3419.51
             reg |   1769.998   643.0797     2.75   0.006     509.5854    3030.411
             ipw |   1860.971    766.724     2.43   0.015       358.22    3363.723
          stdipw |   2048.197   724.1008     2.83   0.005     628.9856    3467.409
          sipwra |   2032.628   707.1039     2.87   0.004     646.7293    3418.526
    ------------------------------------------------------------------------------
    Note: This table is provided for comparison across estimations only. You cannot use it to compare
    estimates across different estimators
    dripw :Doubly Robust IPW
    drimp :Doubly Robust Improved estimator
    reg   :Outcome regression or Regression augmented estimator
    ipw   :Abadie(2005) IPW estimator
    stdipw:Standardized IPW estimator
    sipwra:IPW and Regression adjustment estimator.
