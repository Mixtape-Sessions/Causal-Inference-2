# Lalonde

This dataset is one of the most commonly used dataset in econometrics based on [Lalonde (1986)](https://econpapers.repec.org/article/aeaaecrev/v_3a76_3ay_3a1986_3ai_3a4_3ap_3a604-20.htm) and [Dehejia and Wahba (2002)](https://www.uh.edu/~adkugler/Dehejia&Wahba.pdf). Both the paper by Lalonde and Dehejia and Wahba both wanted to evaluate causal inference methods using non-experimental data. Cleverly, they start with an experimental dataset to estimate the 'true' causal effect and then use non-experimental data to evaluate an econometric method.

In [Causal Inference 1](github.com/Mixtape-Sessions/Causal-Inference-1), we have already shown that the nonexperimental dataset performs poorly at estimating the effects of a job training program on earnings, finding a substantial negative effect. That lab shows that matching-based methods are effective at recovering effects close to the experimental effect. This lab will study difference-in-differences estimators of the effects.

1. We will first perform analysis on the experimental dataset `https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Labs/Lalonde/lalonde_exp_panel.dta`

a. Estimate the effect of treatment, `treat`, on real-earnings, `re` in a difference-in-differences estimator. This will be the "true" treatment effect estimate that we will try to recreate with the non-experimental CPS sample. 

2. Now, we turn to the non-experimental dataset `https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Labs/Lalonde/lalonde_nonexp_panel.dta`. 

a. As a reminder, perform a simple difference-in-means on the combined dataset to estimate the "treatment effect". Use only the year `78` and compare average real earnings for the treated and the control groups.

b. Estimate a difference-in-differences estimator for the non-experimental group.

c. Use the `DRDID` command to estimate a doubly-robust DID with covariates `age + agesq + agecube + educ + educsq + marr + nodegree + black + hisp`


