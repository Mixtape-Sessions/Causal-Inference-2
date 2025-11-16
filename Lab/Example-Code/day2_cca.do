* name: day2_cca.do

clear 
capture log close

use https://github.com/scunning1975/mixtape/raw/master/castle.dta, clear
xtset sid year

drop if effyear==2005 | effyear==2007 | effyear==2008 | effyear==2009

* Outcome: l_homicide. Natural log of homicides. 
* Treatment variable is "effyear" which means "effective year that the law changed". We will keep only the 2006 group which is 13 states. 

gen 	treat=0
replace treat=1 if effyear==2006
label variable treat "Treated units are states treated in 2006; non-treated units were never treated by 2010"

* 2x2
cap n drop post
gen 	post=0
replace post=1 if year>=2006

reg l_homicide post##treat, cluster(sid)

* 2xT -- event study

reg l_homicide i.year##treat // this would require parallel trends to hold from the omitted year which is 2000. 

reg l_homicide treat##ib2005.year, cluster(sid)

* Simple event study using coefplot

coefplot, keep(1.treat#*) omitted baselevels cirecast(rcap) ///
    rename(1.treat#([0-9]+).year = \1, regex) at(_coef) ///
    yline(0, lp(solid)) xline(2005.5, lpattern(dash)) ///
    xlab(2000(1)2010)

/*********************************************************************/
/*    Covariate Balance Table - Baseline Year 2004 (Clean Version)  */
/*********************************************************************/

gen 	ever_treated=0
replace ever_treated=1 if effyear==2006
*---------------------------------------------------------------------
* Define covariates
*---------------------------------------------------------------------
local covs police unemployrt income blackm_15_24 whitem_15_24 ///
           blackm_25_44 whitem_25_44 prisoner lagprisoner poverty ///
           exp_subsidy exp_pubwelfare northeast midwest south west

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

/* Covariates imbalanced for unweighted:

police (0.279)
unemployrt (0.484)
income (-1.486)
prisoner (0.940)
lagprisoner (0.924)
poverty (1.260)
exp_pubwelfare (-0.253)
northeast (-0.932)
midwest (0.369)
south (0.776)
west (-0.474)

So I will control for those

*/


* Abadie IPW

* Step 1. Get the "long difference" for each group
preserve
keep if year==2005 | year==2006

* Regression
areg l_homicide unemployrt i.year post##treat, a(sid) robust	
	
* As a comparison
drdid l_homicide ///
      unemployrt, ///
      ivar(sid) time(year) tr(treat) all

* Get the long difference for treatment and control group
    keep sid year l_homicide unemployrt treat
    reshape wide l_homicide unemployrt, i(sid) j(year)
	drop unemployrt2006 // dropping post-treatment X
    gen diff = l_homicide2006 - l_homicide2005
	
* Step 2.  Get a propensity score. 
	logit treat unemployrt2005 // baseline X 
	predict pscore

* Step 3. Abadie IPW -- weight the long differences using the IPW formula
	
	gen w0_num = (1 - treat) * (pscore / (1 - pscore))

	sum treat 
	scalar mean_treated = r(mean)

	sum w0_num 
	scalar mean_w0 = r(mean)

* 3. Normalize weights
	gen w1 = treat / mean_treated
	gen w0 = w0_num / mean_w0

* Treated: E[ D * diff_2009 ] / E[D]
	gen contrib_treated = w1 * diff
	sum contrib_treated
	scalar att_treated = r(mean)

* Control: E[ w0 * diff_2009 ] / E[w0]
	gen contrib_control = w0 * diff
	sum contrib_control
	scalar att_control = r(mean)

	scalar att = att_treated - att_control
	di "Manual IPW ATT = " att

 
* Make the propensity score figure in addition to the imbalance table:
twoway (kdensity pscore if treat==1,  color(red)) ///
       (kdensity pscore if treat==0,  ///
	   fcolor(none) lcolor(black)), legend(order(1 "Treated" 2 "Not treated" ))

restore
