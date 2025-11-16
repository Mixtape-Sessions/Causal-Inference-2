* name: pscores.do
* author: scott cunningham
* description: OLS and Manual are the same

clear 
capture log close

use https://github.com/scunning1975/mixtape/raw/master/castle.dta, clear
xtset sid year

* Sample selection for 2x2 (keep only the 2006 and never-treated groups)
drop if effyear==2005 | effyear==2007 | effyear==2008 | effyear==2009

gen 	treat = 0
replace treat = 1 if effyear==2006

keep if year==2005

* Cheng and Hoekstra Covariates 

global covs police unemployrt income blackm_15_24 whitem_15_24 ///
           blackm_25_44 whitem_25_44 prisoner lagprisoner poverty ///
           exp_subsidy exp_pubwelfare northeast midwest south 

* Estimation of the propensity score

cap n drop pscore
probit treat $covs
predict pscore

* Will not converge.  Why?

* Visualize the imbalance
twoway (kdensity pscore if treat==1,  color(green)) ///
       (kdensity pscore if treat==0,  ///
	   fcolor(none) lcolor(black)), legend(order(1 "Treated" 2 "Not treated" ))


*---------------------------------------------------------------------
* Create the balance table
*---------------------------------------------------------------------
preserve
    keep if year == 2004
    
    * Create empty results matrix
    matrix results = J(16, 3, .)
    matrix colnames results = "Control_Mean" "Treated_Mean" "Norm_Diff"
    
    local i = 1
    foreach var of local covs {
        * Get means by group
        quietly sum `var' if ever_treat==0
        local mean0 = r(mean)
        quietly sum `var' if ever_treat==1  
        local mean1 = r(mean)
        
        * Get standard deviations by group
        quietly sum `var' if ever_treat==0
        local sd0 = r(sd)
        quietly sum `var' if ever_treat==1
        local sd1 = r(sd)
        
        * Calculate normalized difference
        local norm_diff = (`mean1' - `mean0') / sqrt((`sd0'^2 + `sd1'^2)/2)
        
        * Store in matrix
        matrix results[`i',1] = `mean0'
        matrix results[`i',2] = `mean1' 
        matrix results[`i',3] = `norm_diff'
        
        local ++i
    }
    
    * Add row names
    matrix rownames results = `covs'
    
    * Display the table
    matrix list results, format(%9.3f)
    
restore
