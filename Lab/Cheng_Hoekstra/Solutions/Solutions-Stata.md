
# Cheng and Hoekstra (2013)

We are going to revisit the analysis performed by Cheng and Hoekstra on
the effect of “Stand Your Ground” gun laws on homicides. To begin, load
the data from
`https://github.com/scunning1975/mixtape/raw/master/castle.dta`. The
main variables of interest are: the state id, denoted by `sid`; the
`year` of the observation; the log of the number of homocides in the
state denoted `l_homicide`; and `effyear` which measures the year in
which the Stand Your Ground law was implemented in a state.

Before we begin, we need to do some data work to prepare for estimation.
For estimators, we need to change `effyear` to 0 for the control states.
They are in the data as `NA` in R or `.` in Stata. Then, Take the
variable `effyear` and `year` and construct an event-time variable
(i.e. `year` - `effyear` or $t - g$ in Callaway and Sant’Anna’s syntax).
For the control units, you should set the relative year indicator to
`-1`. More, create a variable `treat` that denotes when treatment is
active, i.e. when `year` is greater than or equal to `effyear`.

``` stata
********************************************************************************
* name: cheng_hoekstra.do
* description: Various Difference-in-Differences Estimators with Cheng and 
* Hoekstra dataset.
********************************************************************************

* To install packages, run:
* ssc install reghdfe
* ssc install csdid
* net install github, from("https://haghish.github.io/github/")
* github install kylebutts/did2s_stata
* github install lsun20/eventstudyinteract

use "https://github.com/scunning1975/mixtape/raw/master/castle.dta", clear

* for csdid, effyear needs to be 0 for untreated group
replace effyear = 0 if effyear == .

gen rel_year = year - effyear
replace rel_year = -1 if effyear == 0

* can't have negative years for factor variable
gen rel_year_shifted = rel_year + 9

gen treat = (year >= effyear)
```

    (319 real changes made)


    (319 real changes made)

1.  Now that our data is in the correct order, we will estimate the
    standard TWFE event-study.

``` stata
* 1. TWFE Event-study regression -----------------------------------------------

* 8 is relative-year -1, so we want that to be the reference
reghdfe l_homicide ib8.rel_year_shifted, absorb(sid year) cluster(sid)
```

    (MWFE estimator converged in 2 iterations)

    HDFE Linear regression                            Number of obs   =        550
    Absorbing 2 HDFE groups                           F(  14,     49) =       8.29
    Statistics robust to heteroskedasticity           Prob > F        =     0.0000
                                                      R-squared       =     0.9133
                                                      Adj R-squared   =     0.8997
                                                      Within R-sq.    =     0.0430
    Number of clusters (sid)     =         50         Root MSE        =     0.1869

                                           (Std. Err. adjusted for 50 clusters in sid)
    ----------------------------------------------------------------------------------
                     |               Robust
          l_homicide |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
    -----------------+----------------------------------------------------------------
    rel_year_shifted |
                  0  |  -.2484057   .0570123    -4.36   0.000    -.3629763   -.1338352
                  1  |  -.0766955    .158832    -0.48   0.631    -.3958804    .2424893
                  2  |  -.2262526   .1263759    -1.79   0.080    -.4802145    .0277093
                  3  |   .0383738    .063393     0.61   0.548    -.0890192    .1657668
                  4  |   .0240412   .0598185     0.40   0.690    -.0961685    .1442508
                  5  |  -.0015389    .059078    -0.03   0.979    -.1202607    .1171828
                  6  |   .0541307   .0452908     1.20   0.238    -.0368846    .1451461
                  7  |   .0585765    .050259     1.17   0.249    -.0424228    .1595757
                  9  |   .0918614   .0431759     2.13   0.038      .005096    .1786267
                 10  |    .105671   .0519573     2.03   0.047     .0012588    .2100832
                 11  |   .1146227   .0658122     1.74   0.088    -.0176319    .2468774
                 12  |   .1095202   .0663352     1.65   0.105    -.0237854    .2428257
                 13  |   .0835843   .0589927     1.42   0.163    -.0349659    .2021345
                 14  |   .1272444   .0500376     2.54   0.014     .0266902    .2277986
                     |
               _cons |   1.385299   .0102449   135.22   0.000     1.364711    1.405887
    ----------------------------------------------------------------------------------

    Absorbed degrees of freedom:
    -----------------------------------------------------+
     Absorbed FE | Categories  - Redundant  = Num. Coefs |
    -------------+---------------------------------------|
             sid |        50          50           0    *|
            year |        11           0          11     |
    -----------------------------------------------------+
    * = FE nested within cluster; treated as redundant for DoF computation

2.  Use the Callaway and Sant’Anna estimator to estimate the group-time
    average treatment effects, $ATT(g,t)$. Then aggregate these to
    event-study treatment effects. *Note:* use `did` package in R or the
    `csdid` package in Stata.

``` stata
* 2. Callaway and Santa'Anna ---------------------------------------------------

csdid l_homicide, ivar(sid) time(year) gvar(effyear) agg(event)
```

    Difference-in-difference with Multiple Time Periods

                                                    Number of obs     =        550
    Outcome model  : weighted least squares
    Treatment model: inverse probability tilting
    ------------------------------------------------------------------------------
                 |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -------------+----------------------------------------------------------------
             T-8 |   .5276058   .0414008    12.74   0.000     .4464617    .6087498
             T-7 |  -.2750778   .2076307    -1.32   0.185    -.6820265    .1318709
             T-6 |   .2581694   .0908255     2.84   0.004     .0801548     .436184
             T-5 |  -.0149105    .050696    -0.29   0.769    -.1142729    .0844518
             T-4 |  -.0393112   .0541868    -0.73   0.468    -.1455153    .0668929
             T-3 |   .0644989   .0444428     1.45   0.147    -.0226074    .1516051
             T-2 |   .0011024   .0453654     0.02   0.981    -.0878121    .0900169
             T-1 |   -.057916   .0437708    -1.32   0.186    -.1437052    .0278731
             T+0 |   .0972154   .0396431     2.45   0.014     .0195162    .1749145
             T+1 |   .1115491   .0493212     2.26   0.024     .0148814    .2082169
             T+2 |   .1115662   .0593121     1.88   0.060    -.0046834    .2278157
             T+3 |   .1368254   .0572429     2.39   0.017     .0246313    .2490195
             T+4 |   .0925866   .0537054     1.72   0.085    -.0126741    .1978473
             T+5 |   .1119418    .050854     2.20   0.028     .0122698    .2116139
    ------------------------------------------------------------------------------
    Control: Never Treated

    See Callaway and Sant'Anna (2021) for details

1.  In R you will receive the following error:

<!-- -->

    Warning messages:
    1: In pre_process_did(yname = yname, tname = tname, idname = idname,  :
      Be aware that there are some small groups in your dataset.
      Check groups: 2005,2007,2008,2009.

Describe why you might be getting this error

*Answer*: This error comes up because there are few treated states in
each of these groups. Therefore you should be careful when conducting
inference on any particular $ATT(g,t)$. This problem can be mitigated by
averaging $ATT(g,t)$

3.  Then, use the imputation-estimator to estimate event-study
    coefficients. Note that BJS, Gardner, and Wooldridge’s Mundlak
    estimators will produce the same exact point estimate. *Note:* use
    `did2s` package in R or Stata.

``` stata
* 3. Imputation Estimator ------------------------------------------------------

did2s l_homicide, first_stage(i.sid i.year) second_stage(ib8.rel_year_shifted) treatment(treat) cluster(sid)
```

                                            (Std. Err. adjusted for clustering on sid)
    ----------------------------------------------------------------------------------
                     |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
    -----------------+----------------------------------------------------------------
    rel_year_shifted |
                  0  |  -.1176073   .0380883    -3.09   0.002    -.1922591   -.0429555
                  1  |  -.0000888   .1369312    -0.00   0.999    -.2684689    .2682913
                  2  |  -.1668483   .0751039    -2.22   0.026    -.3140493   -.0196474
                  3  |    .057559   .0244415     2.35   0.019     .0096545    .1054636
                  4  |   .0151893   .0248271     0.61   0.541    -.0334708    .0638494
                  5  |  -.0019635   .0226105    -0.09   0.931    -.0462793    .0423523
                  6  |   .0142492   .0154866     0.92   0.358    -.0161041    .0446024
                  7  |   .0211324   .0213172     0.99   0.322    -.0206486    .0629134
                  9  |   .0137094   .0643583     0.21   0.831    -.1124307    .1398494
                 10  |   .0455315   .0657877     0.69   0.489      -.08341    .1744729
                 11  |  -.1019078   .0815181    -1.25   0.211    -.2616804    .0578648
                 12  |   .0062769   .0878007     0.07   0.943    -.1658093    .1783632
                 13  |  -.0546316   .0802317    -0.68   0.496    -.2118829    .1026197
                 14  |  -.0115709   .0298056    -0.39   0.698    -.0699888     .046847
    ----------------------------------------------------------------------------------

4.  Next, use the Sun and Abraham event-study estimator. *Note:* use
    `sunab` function within the `fixest` package in R or the
    `eventstudyinteract` package in Stata.

``` stata
* 4. Sun and Abraham -----------------------------------------------------------

* generate relative time indicators
sum rel_year
* Leads, drop -1
forvalues k = `r(min)'(1)-2 {
  local k = -`k'
  gen rel_year_lag`k' = rel_year == -`k'
}
* Lags
forvalues k = 0(1)`r(max)' {
  gen rel_year_lead`k' = rel_year == `k'
}

gen never_treated = effyear == 0

* Drop rel_year = -1
eventstudyinteract l_homicide rel_year_lag* rel_year_lead*, cohort(effyear) control_cohort(never_treated) absorb(sid year) vce(cluster sid)
```

        Variable |        Obs        Mean    Std. Dev.       Min        Max
    -------------+---------------------------------------------------------
        rel_year |        550        -1.2    2.146714         -9          5




    (obs=231)

    IW estimates for dynamic effects                Number of obs     =        550
    Absorbing 2 HDFE groups                         F(  50,     49)   =          .
                                                    Prob > F          =          .
                                                    R-squared         =     0.9191
                                                    Adj R-squared     =     0.8988
                                                    Root MSE          =     0.1878
                                         (Std. Err. adjusted for 50 clusters in sid)
    --------------------------------------------------------------------------------
                   |               Robust
        l_homicide |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
    ---------------+----------------------------------------------------------------
     rel_year_lag9 |  -.4039674   .0611656    -6.60   0.000    -.5268842   -.2810506
     rel_year_lag8 |  -.1238113   .1212362    -1.02   0.312    -.3674446    .1198221
     rel_year_lag7 |   -.233131   .1311019    -1.78   0.082    -.4965901    .0303282
     rel_year_lag6 |   .0453398   .0737414     0.61   0.541    -.1028491    .1935287
     rel_year_lag5 |   .0316259   .0651257     0.49   0.629    -.0992491    .1625009
     rel_year_lag4 |  -.0076853   .0546014    -0.14   0.889    -.1174108    .1020403
     rel_year_lag3 |   .0568136   .0494877     1.15   0.257    -.0426356    .1562629
     rel_year_lag2 |    .057916    .046046     1.26   0.214    -.0346168    .1504488
    rel_year_lead0 |   .0972154    .042176     2.30   0.025     .0124595    .1819712
    rel_year_lead1 |   .1115491   .0520222     2.14   0.037     .0070066    .2160917
    rel_year_lead2 |   .1115662   .0630838     1.77   0.083    -.0152054    .2383377
    rel_year_lead3 |   .1368254   .0612578     2.23   0.030     .0137233    .2599275
    rel_year_lead4 |   .0925866   .0574662     1.61   0.114     -.022896    .2080691
    rel_year_lead5 |   .1119418   .0544307     2.06   0.045     .0025592    .2213245
    --------------------------------------------------------------------------------

5.  Last, construct a stacked estimator where for each group, you keep
    all not-yet-treated observations and the never treated obserations.
    Keep observations only for event-time between -5 and +4. Make sure
    to properly stack the data and cluster at the `sid` x stack_id
    level.

``` stata
* 5. Stacking Estimator --------------------------------------------------------

* Step 1: Loop through by using only a group and the never treated
* and assigning it a unique stack_id
* We are aiming for a panel with event_time -5 to 4

forvalues i = 2005(1)2009 {
  preserve
  gen stack_id = `i'

  * Keep if effyear == `i', never-treated, or untreated observations 
  keep if effyear == `i' | effyear == 0 | year < effyear

  * keep rel_year -5 through 4
  keep if rel_year >= -5 & rel_year <= 4

  save ./stack_`i', replace
  restore
}

* Step 2: Now append the datasets into one single stacked dataset.

use ./stack_2005, clear
rm ./stack_2005.dta
forvalues i = 2006(1)2009 {
  append using ./stack_`i'.dta
  * Clean up
  rm ./stack_`i'.dta
}

* Step 3: Estimation with dataset interaction fixed effects and 
* relative event time fixed effects, clustering on unique stateXdataset
* identifiers

* relative year = -1 is rel_year 8
egen sid_x_stack_id = group(sid stack_id)
egen year_x_stack_id = group(year stack_id)
reghdfe l_homicide ib8.rel_year_shift, absorb(sid_x_stack_id year_x_stack_id) cluster(sid_x_stack_id)
```

    (89 observations deleted)
    (32 observations deleted)
    (note: file ./stack_2005.dta not found)
    file ./stack_2005.dta saved
    (30 observations deleted)
    (31 observations deleted)
    (note: file ./stack_2006.dta not found)
    file ./stack_2006.dta saved
    (79 observations deleted)
    (31 observations deleted)
    (note: file ./stack_2007.dta not found)
    file ./stack_2007.dta saved
    (89 observations deleted)
    (31 observations deleted)
    (note: file ./stack_2008.dta not found)
    file ./stack_2008.dta saved
    (93 observations deleted)
    (31 observations deleted)
    (note: file ./stack_2009.dta not found)
    file ./stack_2009.dta saved






    (MWFE estimator converged in 7 iterations)

    HDFE Linear regression                            Number of obs   =      2,214
    Absorbing 2 HDFE groups                           F(   9,    249) =       4.69
    Statistics robust to heteroskedasticity           Prob > F        =     0.0000
                                                      R-squared       =     0.9246
                                                      Adj R-squared   =     0.9122
                                                      Within R-sq.    =     0.0102
    Number of clusters (sid_x_stack_id) =        250  Root MSE        =     0.1751

                               (Std. Err. adjusted for 250 clusters in sid_x_stack_id)
    ----------------------------------------------------------------------------------
                     |               Robust
          l_homicide |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
    -----------------+----------------------------------------------------------------
    rel_year_shifted |
                  4  |   .0286859   .0258045     1.11   0.267     -.022137    .0795089
                  5  |  -.0043934   .0262632    -0.17   0.867    -.0561196    .0473329
                  6  |    .057394   .0195429     2.94   0.004     .0189036    .0958845
                  7  |   .0609569   .0213489     2.86   0.005     .0189095    .1030043
                  9  |   .0947044   .0502204     1.89   0.060    -.0042065    .1936154
                 10  |   .1101395   .0558033     1.97   0.050     .0002329    .2200461
                 11  |   .1058127   .0651503     1.62   0.106    -.0225031    .2341286
                 12  |   .1320576   .0657312     2.01   0.046     .0025977    .2615175
                 13  |   .0891524   .0574108     1.55   0.122    -.0239203     .202225
                     |
               _cons |    1.33829   .0039996   334.60   0.000     1.330413    1.346168
    ----------------------------------------------------------------------------------

    Absorbed degrees of freedom:
    ---------------------------------------------------------+
         Absorbed FE | Categories  - Redundant  = Num. Coefs |
    -----------------+---------------------------------------|
      sid_x_stack_id |       250         250           0    *|
     year_x_stack_id |        55           0          55     |
    ---------------------------------------------------------+
    * = FE nested within cluster; treated as redundant for DoF computation
