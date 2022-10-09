# Lalonde

This dataset is one of the most commonly used dataset in econometrics based on [Lalonde (1986)](https://econpapers.repec.org/article/aeaaecrev/v_3a76_3ay_3a1986_3ai_3a4_3ap_3a604-20.htm) and [Dehejia and Wahba (2002)](https://www.uh.edu/~adkugler/Dehejia&Wahba.pdf). Both the paper by Lalonde and Dehejia and Wahba both wanted to evaluate causal inference methods using non-experimental data. Cleverly, they start with an experimental dataset to estimate the 'true' causal effect and then use non-experimental data to evaluate an econometric method.

In [Causal Inference 1](github.com/Mixtape-Sessions/Causal-Inference-1), we have already shown that the nonexperimental dataset performs poorly at estimating the effects of a job training program on earnings, finding a substantial negative effect. That lab shows that matching-based methods are effective at recovering effects close to the experimental effect. This lab will study difference-in-differences estimators of the effects.

1. We will first perform analysis on the experimental dataset `https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Labs/Lalonde/lalonde_exp_panel.dta`

a. Under random assignment, the simnple difference-in-means identifies the ATE, and since the original NSW was a randomized experiment, we can do this.  Calculate the simple difference-in-means on the experimental dataset to estimat the "treatment effect" two separate ways: (1) manually calculating averages for both treatment (`ever_treated=1`) and control (`ever_treated=0`) and (2) OLS specification, both times using only the year `78` and `re` variable for real earnings. We will consider this to be the ATE and under random assignment it is also the ATT.

b. Estimate the effect of treatment, `ever_treated`, on real-earnings, `re` in a difference-in-differences estimator using years `78` for post period and `75` as the pre-period (ignore for now the `74`). Do this, again, two ways: (1) manually calculate the four means you need for the DiD equation and (2) estimate the DiD OLS specification with robust standard errors. Be sure you are only using the 1975 and 1978 years (you'll want to ensure that the 1974 is not included in the OLS analysis). 

c. Check the pre-trends for 1974 relative to 1975 two ways: (1) manually calculate the DiD equation on 1974 relative to 1975 and (2) the dynamic OLS specification with an interaction of `ever_treated` with `74`, an interaction of `ever_treated` with `78`.  Compare your answers here to 2a and 2b. 

2. Now, we turn to the non-experimental dataset `https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Labs/Lalonde/lalonde_nonexp_panel.dta`. 

a. Repeat 1a (simple difference-in-means for `78` only), 1b (DiD using manual calculations and OLS specification for `78` and `75` only) and `c (event study calculations manually and dynamic OLS specification)

b. Repeat 1b and 1c (OLS specifications) controlling `age, agesq, agecube, educ, educsq, marr, nodegree, black, hisp` with robust standard errors.

c. Use the `DRDID` command to estimate a doubly-robust DID with covariates `age + agesq + agecube + educ + educsq + marr + nodegree + black + hisp`, `id` panel unit identifier, `year` as the panel time identifier, and reporting the outcome regression analysis (Heckman, Ichimura, Todd 1997), inverse probability weight estimator (Abadie 2005), doubly robust (Sant'anna and Zhao 2020).  Compare these results with 1a, 1b, 2a and 2b. 
