

# Tennessee Valley Authority Empirical Application

## Intro

This exercise is going to work with data from Kline and Moretti (2014).
This paper aims to analyze the impacts of the “Tennessee Valley
Authority” (TVA) on local agriculture and manufacturing employment. The
TVA was a huge federal spending program in the 1940s that aimed at
electrification of the region, building hundreds of large dams (in
Scott’s terms, a ton of ‘bite’).

The region was centered in Tennessee and surrounding other southern
states. The region had a large agriculture industry, but very little
manufacturing. Electrification brought in a lot industry, moving the
economy away from agriculture. We are going to test for this in the data
using census data (recorded every 10 years).

![Tennessee Valley Authority Dam](img/tva_map.jpeg)

![Tennessee Valley Authority Map](img/tva_dam.jpeg)

``` r
library(tidyverse)
library(fixest)
library(DRDID)
library(did)

options(readr.show_progress = FALSE, readr.show_col_types = FALSE)
setFixest_etable(markdown = FALSE)
```

First, we will load our dataset:

``` r
df <- read_csv("data/tva.csv")
head(df)
```

    # A tibble: 6 × 18
      county_code  year   tva treat  post ln_agriculture ln_manufacturing
      <chr>       <dbl> <dbl> <dbl> <dbl>          <dbl>            <dbl>
    1 01001        1920     0     0     0           8.49             6.41
    2 01001        1930     0     0     0           8.64             6.36
    3 01001        1940     0     0     0           8.39             6.66
    4 01001        1950     0     0     1           7.78             7.14
    5 01001        1960     0     0     1           7.12             7.26
    6 01003        1920     0     0     0           8.35             7.10
    # ℹ 11 more variables: agriculture_share_1920 <dbl>,
    #   agriculture_share_1930 <dbl>, manufacturing_share_1920 <dbl>,
    #   manufacturing_share_1930 <dbl>, ln_avg_farm_value_1920 <dbl>,
    #   ln_avg_farm_value_1930 <dbl>, white_share_1920 <dbl>,
    #   white_share_1930 <dbl>, white_share_1920_sq <dbl>,
    #   white_share_1930_sq <dbl>, county_has_no_missing <lgl>

## Question 1

We will perform the basic 2x2 DID using just the years 1940 and 1960. We
will use as outcomes `ln_agriculture` and `ln_manufacturing`.

First, for `ln_agriculture`, we will manually calculate the means and
form the difference-in-differences.

``` r
m_d1_y1960 <- mean(df[df$year == 1960 & df$tva == 1, ]$ln_agriculture)
m_d1_y1940 <- mean(df[df$year == 1940 & df$tva == 1, ]$ln_agriculture)
m_d0_y1960 <- mean(df[df$year == 1960 & df$tva == 0, ]$ln_agriculture)
m_d0_y1940 <- mean(df[df$year == 1940 & df$tva == 0, ]$ln_agriculture)

(m_d1_y1960 - m_d1_y1940) - (m_d0_y1960 - m_d0_y1940)
```

    [1] -0.2281978

``` r
# -0.2281978
```

Second, run the “classic” version using an indicator for treatment,
`tva`, and indicator for being the post-period, `post`, and the product
of the two. I recommend the package `fixest` for regression analysis.
I’ll be using it in the solutions.

``` r
# `reghdfe`
df_2by2 <- df |>
  filter(year == 1940 | year == 1960)

did_2by2 = feols(
  c(ln_agriculture, ln_manufacturing) ~ 
    i(post) + i(tva) + i(post * tva),
  data = df_2by2, 
  cluster = ~ county_code
)
```

Second, we will see in the 2x2 DID case, using county and time fixed
effects is equivalent:

``` r
did_2by2_fixed_effects = feols(
  c(ln_agriculture, ln_manufacturing) ~ 
    i(post * tva) | county_code + year,
  data = df_2by2, 
  cluster = ~ county_code
)

etable(
  did_2by2, did_2by2_fixed_effects
)
```

                             did_2by2.1         did_2by2.2 did_2by2_fixed_e..1
    Dependent Var.:      ln_agriculture   ln_manufacturing      ln_agriculture
                                                                              
    Constant          7.671*** (0.0157)  6.188*** (0.0383)                    
    post = 1        -0.7426*** (0.0097) 0.7506*** (0.0124)                    
    tva = 1          0.3806*** (0.0493)    0.1369 (0.1098)                    
    post x tva = 1  -0.2282*** (0.0214) 0.2774*** (0.0470) -0.2282*** (0.0214)
    Fixed-Effects:  ------------------- ------------------ -------------------
    county_code                      No                 No                 Yes
    year                             No                 No                 Yes
    _______________ ___________________ __________________ ___________________
    S.E.: Clustered     by: county_code    by: county_code     by: county_code
    Observations                  5,470              5,470               5,470
    R2                          0.17484            0.04164             0.93323
    Within R2                        --                 --             0.01371

                    did_2by2_fixed_..2
    Dependent Var.:   ln_manufacturing
                                      
    Constant                          
    post = 1                          
    tva = 1                           
    post x tva = 1  0.2774*** (0.0470)
    Fixed-Effects:  ------------------
    county_code                    Yes
    year                           Yes
    _______________ __________________
    S.E.: Clustered    by: county_code
    Observations                 5,470
    R2                         0.97357
    Within R2                  0.01182
    ---
    Signif. codes: 0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

## Question 2

Moretti and Kline were nervous that the parallel trends assumption is a
bit of a strong assumption in the context. Why might that be in the
context of the Tennessee Valley Authority?

Answer: The TVA was built in the Tenneessee area precisely because the
area was not developing a strong manufacturing base. It is unlikely in
the absence of treatment that counties in the TVA area were going to
grow in manufacturing the same as outside counties

Let’s run a placebo analysis to test for this using 1920 as the
pre-treatment period and 1930 as the post-treatment period. What does
this tell us about the plausability of a parallel trends type
assumption?

``` r
df_1920_1930 = df |>
  filter(year == 1920 | year == 1930) |>
  mutate(is_1930 = (year == 1930))

# 1930 = "treatment period"
# 1920 = "control period"
feols(
  c(ln_agriculture, ln_manufacturing) ~ 
    i(tva * is_1930) | county_code + year,
  data = df_1920_1930,
  cluster = ~county_code
)
```

    Standard-errors: Clustered (county_code) 
    Dep. var.: ln_agriculture
                      Estimate Std. Error  t value Pr(>|t|) 
    tva * is_1930::1 -0.026524   0.025722 -1.03121  0.30253 
    ---
    Dep. var.: ln_manufacturing
                     Estimate Std. Error  t value Pr(>|t|) 
    tva * is_1930::1 0.125824   0.195052 0.645078  0.51893 

## Question 3

Let’s put this analysis together and run an event-study regression using
the full dataset

To do this, create a set of dummy variables that interact year with
treatment status. Estimate the TWFE model with these dummy variables.

``` r
# Duflo, Mullinathan, and Bertrand (2004)
df = df |>
  mutate(
    rel_year = ifelse(tva == 0, 1940, year)
  )

es_agriculture = feols(
  ln_agriculture ~ i(rel_year, ref = c(1940)) | county_code + year,
  data = df,
  cluster = ~ county_code
)
iplot(es_agriculture)
```

![](README_files/figure-commonmark/unnamed-chunk-7-1.png)

``` r
es_manufacturing = feols(
  ln_manufacturing ~ i(rel_year, ref = c(1940)) | county_code + year,
  data = df,
  cluster = ~ county_code
)
iplot(es_manufacturing)
```

![](README_files/figure-commonmark/unnamed-chunk-8-1.png)

## Question 4

We see some evidence of pre-trends for `ln_manufacturing` which makes us
concerned about the plausability of parallel counterfactual trends in
the post-period. Let’s show this visually by extending a linear
regression through the pre-period estimates.

``` r
est = broom::tidy(es_manufacturing)
est = est |> 
  mutate(
    rel_year = as.numeric(str_replace(est$term, "rel_year::", ""))
  )
est = est |>
  bind_rows(tibble(rel_year = 1940, estimate = 0))

pre_trend_line = lm(
  estimate ~ rel_year, 
  data = est |> filter(rel_year <= 1930)
)

ggplot(est) +
  geom_errorbar(
    aes(
      x = rel_year,
      ymin = estimate - 1.96 * std.error,
      ymax = estimate + 1.96 * std.error
    ),
    width = 1
  ) + 
  geom_point(aes(x = rel_year, y = estimate)) + 
  geom_abline(
    intercept = coef(pre_trend_line)[1],
    slope = coef(pre_trend_line)[2],
    color = "red"
  )
```

![](README_files/figure-commonmark/unnamed-chunk-9-1.png)

This exercise, assumes that changes in outcomes in the pre-period will
extend linearly into the future. However, this is a strong assumption;
instead we will use Jon Roth and Ashesh Rambachan’s work. First, we will
calculate the “the largest violations of parallel trends in the
pre-treatment period”. We measure a violation of parallel trends as the
change in pre-trend estimates $\hat{\delta}_t - \hat{\delta}_{t-1}$. In
our case, we only have two pre-period estimates so it’s the max.

Lets use the `HonestDiD` package to assess robustness to violations of
parallel trends. The function
`HonestDiD::createSensitivityResults_relativeMagnitudes` will calculate
the largest violation of parallel trends and then intuitively gauge “if
we have violations of similar magnitude, could our results go away”. We
can control the “magnitude” of violations by a value of $\bar{M}$ with a
value of 1 being equal to the largest violation and 0 being no bias. The
code is kind of complicated, so I include it here:

``` r
library(HonestDiD)

# need in time order, without reference group
betahat = coef(es_manufacturing)
sigma = vcov(es_manufacturing)

# first post period effect
first_l_vec <- basisVector(1, size = 2)
# second post period effect
second_l_vec <- basisVector(2, size = 2)
# average of event-study estimates
avg_l_vec <- matrix(c(0.5, 0.5), nrow = 2, ncol = 1)

delta_rm_results <- HonestDiD::createSensitivityResults_relativeMagnitudes(
  betahat = betahat,
  sigma = sigma,
  numPrePeriods = 2,
  numPostPeriods = 2,
  Mbarvec = seq(0.25, 1.5, by = 0.25), 
  l_vec = avg_l_vec
)
```

    Warning in .ARP_computeCI(betahat = betahat, sigma = sigma, numPrePeriods =
    numPrePeriods, : CI is open at one of the endpoints; CI length may not be
    accurate
    Warning in .ARP_computeCI(betahat = betahat, sigma = sigma, numPrePeriods =
    numPrePeriods, : CI is open at one of the endpoints; CI length may not be
    accurate
    Warning in .ARP_computeCI(betahat = betahat, sigma = sigma, numPrePeriods =
    numPrePeriods, : CI is open at one of the endpoints; CI length may not be
    accurate
    Warning in .ARP_computeCI(betahat = betahat, sigma = sigma, numPrePeriods =
    numPrePeriods, : CI is open at one of the endpoints; CI length may not be
    accurate
    Warning in .ARP_computeCI(betahat = betahat, sigma = sigma, numPrePeriods =
    numPrePeriods, : CI is open at one of the endpoints; CI length may not be
    accurate
    Warning in .ARP_computeCI(betahat = betahat, sigma = sigma, numPrePeriods =
    numPrePeriods, : CI is open at one of the endpoints; CI length may not be
    accurate
    Warning in .ARP_computeCI(betahat = betahat, sigma = sigma, numPrePeriods =
    numPrePeriods, : CI is open at one of the endpoints; CI length may not be
    accurate

``` r
originalResults <- HonestDiD::constructOriginalCS(
  betahat = betahat,
  sigma = sigma,
  numPrePeriods = 2,
  numPostPeriods = 2, 
  l_vec = avg_l_vec
)

HonestDiD::createSensitivityPlot_relativeMagnitudes(
  delta_rm_results, originalResults
)
```

![](README_files/figure-commonmark/unnamed-chunk-10-1.png)

## Question 5

Let’s use some controls to weaken the assumption to conditional parallel
trends. In particular, we are going to use a few covariates:
`agriculture_share_1920`, `agriculture_share_1930`,
`manufacturing_share_1920`, and `manufacturing_share_1930`.

What happens if we add those controls in linearly to our original
estimate?

``` r
feols(
  ln_manufacturing ~ i(year, agriculture_share_1920) + agriculture_share_1930 + manufacturing_share_1920 + manufacturing_share_1930 | year + county_code,
  data = df
)
```

    The variables 'year::1960:agriculture_share_1920', 'agriculture_share_1930', 'manufacturing_share_1920' and 'manufacturing_share_1930' have been removed because of collinearity (see $collin.var).

    OLS estimation, Dep. Var.: ln_manufacturing
    Observations: 13,675
    Fixed-effects: year: 5,  county_code: 2,735
    Standard-errors: Clustered (year) 
                                       Estimate Std. Error       t value  Pr(>|t|)
    year::1920:agriculture_share_1920 -3.560604   4.70e-14 -7.580830e+13 < 2.2e-16
    year::1930:agriculture_share_1920 -2.324021   4.78e-14 -4.866365e+13 < 2.2e-16
    year::1940:agriculture_share_1920 -0.558494   4.89e-14 -1.141093e+13 < 2.2e-16
    year::1950:agriculture_share_1920 -0.335565   5.10e-14 -6.576429e+12 < 2.2e-16
                                         
    year::1920:agriculture_share_1920 ***
    year::1930:agriculture_share_1920 ***
    year::1940:agriculture_share_1920 ***
    year::1950:agriculture_share_1920 ***
    ... 4 variables were removed because of collinearity (year::1960:agriculture_share_1920, agriculture_share_1930 and 2 others [full set in $collin.var])
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
    RMSE: 0.954523     Adj. R2: 0.812832
                     Within R2: 0.104899

*Answer:* The covariates are dropped because they are collinear with the
county fixed effects.

The term $X_i \beta$ just causes a level shift in outcomes. This is not
what we want. We really want to allow for the *trends* in outcomes to
vary by covariate values. The simplest way to do this is to change our
model to interact covariates with indicators for each year
$X_i * 1(t = s) \beta$ for each year $s$. This is often written more
simply as $X_i \beta_t$ which lets $beta$ vary by year.

If you take first-differences, you end up with $$
 X_i \beta_t - X_i \beta_{t-1} = X_i (\beta_t - \beta_{t-1}),
$$ which says changes in outcome over time depend on your value of
$X_i$.

## Question 6

This question shows different weighs to incorporate covariates in a 2x2
difference-in-differences estimator. The goal is to relax our parallel
trends assumption to be conditional on X: $$
  E(Y_{i1}(0) - Y_{i1}(0) | D = 1, X = x) = E(Y_{i1}(0) - Y_{i1}(0) | D = 0, X = x).
$$

In words, this assumption says “take treated and control units with the
same value of $X$. These units on average have the same counterfactual
trend”. Full details to help with this question are given below in the
appendix notes. This question will walk you through three different
covariates-based estimators of ATTs: outcome regression, inverse
propensity of treatment weighting, and a doubly-robust combination of
the two.

Note: Some of the data contains missing values for the covariates.
Subset the data using `county_has_no_missing == TRUE` (for later).

``` r
# Drop counties with missing covariates
df <- filter(df, county_has_no_missing == TRUE)

# First-differenced data
first_diff = df |>
  arrange(county_code, year) |>
  filter(year == 1940 | year == 1960) |>
  mutate(
    D_ln_manufacturing = ln_manufacturing - lag(ln_manufacturing, 1),
    D_ln_agriculture = ln_agriculture - lag(ln_agriculture, 1),
    .by = "county_code"
  ) |> 
  filter(year == 1960)
```

### Part 1: Difference-in-Differences

Take first-differences of the outcome variable to form $\Delta Y$.
Create a new dataset that collapses the dataset using first-differences
for the outcome variables (each county should be a single row in the
dataset).

In part a, estimate the normal difference-in-differences estimate.
Additionally, run a second model that linearly controls for
`agriculture_share_1920`, `agriculture_share_1930`,
`manufacturing_share_1920`, and `manufacturing_share_1930`.

``` r
setFixest_fml(
  ..X = ~ agriculture_share_1920 + agriculture_share_1930 + manufacturing_share_1920 + manufacturing_share_1930
)
```

### Part 2: Outcome Regression

Including covariates linearly is very simple and intuitively it allows
for $X_i$-specific trends. However, this assumes that treatment effects
can not vary by the value of $X$. For example, say $X$ is a dummy
variable for age. Then you are allowing for gender-specific trends, but
you are not allowing for treatment effects to vary by age. Note, this
problem is only with continuous covariates in X_i, we won’t estimate the
ATT (see Angrist 1998 or Słoczyński 2022).

Instead, we want to use outcome regression when doing covariate
adjustment in the outcome model. First, regress `D_ln_y` on the four
covariates *using just the untreated observations* (`tva == 0`). This
estimates $E(\Delta y | X, D = 0)$.

Second, predict out of sample this model for the full dataset. Let’s
call this `D_ln_y0_hat`. Last, take the difference between `D_ln_y` and
the predicted `D_ln_y0_hat` and average this for the treated group
(`tva == 1`). This is our outcome regression estimate.

### Part 3: Inverse Probability of Treatment Weighting

Now, lets use a propensity score method. Estimate a logistic regression
of $D$ on the covariates $X$ using the full sample. Predict fitted
propensity scores of this model.

Form the weights $w_1$ and $w_0$ as written in the appendix and form the
IPTW estimate.

> \[!WARNING\]  
> The weights are the ones proposed originally in Abadie (2005). They
> are based on Horvitz-Thompson weights (1952, JASA). These are
> sensitive when there is problems with the overlap conditions.
> Sant’Anna and Zhao (2020) (amongst others) suggest using Hajek
> weights, normalizing the Horvitz-Thompson weights by the sample mean
> of $w$. This is the default with `drdid::ipwdid`.
>
> For $w_0$, the Hajek weights are
> $\frac{1}{\mathbb{P}_n(D = 1)} \frac{(1-D) \hat{p}(X)}{1 - \hat{p}(X)} / \mathbb{E}_n(\frac{(1-D) \hat{p}(X)}{1 - \hat{p}(X)})$.
> The Hajek weights are unchanged for $w_1$ since
> $w_1 = \frac{D}{\mathbb{P}_n(D = 1)} / \mathbb{E}(\frac{D}{\mathbb{P}_n(D = 1)}) = w_1$.
>
> (h/t to Pedro Sant’Anna for bringing this up)

### Part 4: Doubly-Robust DID Estimator

From the previous questions, you have all the parts to estimate the
doubly-robust DID estimator. Do this.

## Question 7

Now, let’s try using the `DRDID` package to do this more simply.

Note: DRDID requires the `idname` to be a numeric, so you need to create
a new variable for this.

## Question 8

We are going to now use `did` to estimate an event study. As a default,
`did` calls `DRDID` under the hood. Let’s see this using `did::att_gt`.
We need to create a variable for “treatment timing groups”, i.e. what
year a county starts treatment. The package takes the convention that
group = 0 for never-treated group.
