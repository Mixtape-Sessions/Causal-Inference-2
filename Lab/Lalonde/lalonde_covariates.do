* lalonde-covariates.do.  Table of normalized difference in means
clear


* Input the NSW and appended CPS data
use "https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_nonexp_panel.dta", clear 

gen 	post=0
replace post = 1 if year==75

* Covariate selection -- they're all selected
lasso linear re age educ black hisp marr nodegree u74 u75 if year<78
estimates store lasso_model
lassocoef, display(coef, standardized)

* Covariate Balance Calculation for DiD Analysis

* Define the list of covariates
local covariates age educ black hisp marr nodegree u74 u75

* Create a temporary file to store the results
tempname memhold
tempfile results
postfile `memhold' str20 variable double norm_diff mean_treated mean_control using "`results'"

foreach var of local covariates {
    * Calculate weighted means and variances for the treated group in the pre-treatment year (1974)
    sum `var' if ever_treated == 1 & year == 74
    local mean_treated = r(mean)
    local var_treated = r(Var)

    * Calculate weighted means and variances for the control group in the pre-treatment year (1974)
    sum `var' if ever_treated == 0 & year == 74
    local mean_control = r(mean)
    local var_control = r(Var)

    * Calculate the normalized difference
    local norm_diff = (`mean_treated' - `mean_control') / sqrt((`var_treated' + `var_control') / 2)

    * Store the results
    post `memhold' ("`var'") (`norm_diff') (`mean_treated') (`mean_control')
}

* Close the postfile
postclose `memhold'

* Load and display the results
use "`results'", clear
list, sep(0)

* Optionally, export the results to a CSV file for further formatting or analysis
export delimited using "./covariate_balance_results.csv", replace
