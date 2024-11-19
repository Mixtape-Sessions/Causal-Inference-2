*******************************************************************************
* baker_sa.do
* author: Daniel H and scott cunningham
* implement the Sun and Abraham estimator and plot it
********************************************************************************
clear
capture log close
use https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Baker/baker.dta, clear

  * leads/lags of treatment, excluding -1
  forvalues k = 24(-1)0 {
    gen pre_`k' = time_til == -`k'
  }
  forvalues k = 1/17 {
    gen post_`k' = time_til == `k'
  }

gen 	lastcohort = 0
replace lastcohort = 1 if treat_date==2004

* Event study with heterogeneity, dropping two leads, TWFE estimation (biased)
areg y i.year dd1 - dd20 dd22-dd23 dd25-dd48, a(id) robust 

coefplot, keep(dd1 dd2 dd3 dd4 dd5 dd6 dd7 dd8 dd9 dd10 dd11 dd12 dd13 dd14 dd15 dd16 dd17 dd18 dd19 dd20 dd22 dd23 dd25 dd26 dd27 dd28 dd29 dd30 dd31 dd32 dd33 dd34 dd35 dd36 dd37 dd38 dd39 dd40 dd41 dd42) xlabel(, angle(vertical)) yline(0) vertical msymbol(D) mfcolor(white) ciopts(lwidth(*3) lcolor(*.6)) grid(between)  format(%9.3f) mlabposition(12) mlabgap(*2) title(Baker simulation) 

* Event study with heterogeneity estimated by Sun and Abraham (2020)
eventstudyinteract y dd1 - dd23 dd25-dd48  if year < 2004 ,  cohort(treat_date) control_cohort(lastcohort) absorb(i.id i.year) vce(cluster state)


// Get coefficients into a matrix
matrix b = e(b_iw)'
matrix V = e(V_iw)

// Create new variables to store the data
clear
svmat b
rename b1 coef

// Get standard errors (sqrt of diagonal elements of V)
matrix se = J(rowsof(V), 1, .)
forvalues i = 1/`=rowsof(V)' {
    matrix se[`i',1] = sqrt(V[`i',`i'])
}
svmat se
rename se1 se

// Generate period variable (-23 to 17, excluding 0)
gen period = _n - 24 if _n <= 23
replace period = _n - 24 if _n > 23
keep if period >= -17 & period <= 17 // Only keep through period 17

// Generate confidence intervals (95%)
gen ci_upper = coef + 1.96*se
gen ci_lower = coef - 1.96*se

// Create the plot
twoway (rcap ci_upper ci_lower period, lcolor(gs12)) ///
       (scatter coef period, mcolor(navy) msymbol(circle)) ///
       (line coef period, lcolor(navy) lpattern(solid)), ///
       xline(0, lpattern(dash) lcolor(red)) ///
       yline(0, lpattern(dash) lcolor(black)) ///
       ylabel(, angle(horizontal)) ///
       xlabel(-17(5)17) ///  
       xtitle("Periods Relative to Treatment") ///
       ytitle("Treatment Effect") ///
       legend(off) ///
       title("Event Study: Treatment Effects")
	   
	   