* name: covariates.do

clear
capture log close
set seed 20200403
set scheme cleanplots

********************************************************************************
* Define dgp
********************************************************************************
cap program drop dgp
program define dgp

  * First create the states
  quietly set obs 40
  gen state = _n

  * Generate 1000 workers. These are in each state. So 25 per state.
  quietly expand 25
  bysort state: gen worker=runiform(0,5)
  label variable worker "Unique worker fixed effect per state"
  quietly egen id = group(state worker)

  * Generate Covariates (Baseline values)
  gen age = rnormal(35, 10)
  gen gpa = rnormal(2.0, 0.5)

  * Center Covariates (Baseline)
  sum age, meanonly
  qui replace age = age - r(mean)
  sum gpa, meanonly
  qui replace gpa = gpa - r(mean)

  * Generate Polynomial and Interaction Terms (Baseline)
  gen age_sq = age^2
  gen gpa_sq = gpa^2
  gen interaction = age * gpa
  
  * Treatment probability increases with age and decrease with gpa
  gen propensity = 0.3 + 0.3 * (age > 0) + 0.2 * (gpa > 0)
  gen treat = runiform() < propensity

  * Generate the years
  quietly expand 2
  sort state
  bysort state worker: gen year = _n
  gen n = year

  qui replace year = 1990 if year == 1
  qui replace year = 1991 if year == 2
  
  * Post-treatment
  gen post = 0  
  qui replace post = 1 if year == 1991

  * Generate fixed effect with control group making 10,000 more at baseline
  qui gen unit_fe = 40000 + 10000 * (treat == 0) 
  
  * Generate Potential Outcomes with Baseline and Year Difference
  gen          e = rnormal(0, 1500)
  qui gen     y0 = unit_fe        + 100 * age + 1000 * gpa + e if year == 1990
  qui replace y0 = unit_fe + 1000 + 200 * age + 2000 * gpa + e if year == 1991
  * ^ NOTE: 
  * The change in coefficients on age and gpa generate trends in outcomes.
  * If two units have the same age and same gpa, then they will have the same change in y0.

  * Covariate-based treatment effect heterogeneity
  gen         y1 = y0
  qui replace y1 = y0 + 1000  if year == 1991

  * Treatment effect
  gen delta = y1 - y0
  label var delta "Treatment effect for unit i (unobservable in the real world)"
  
  sum delta if post == 1, meanonly
  gen ate = `r(mean)'
  sum delta if treat==1 & post==1, meanonly
  gen att = `r(mean)'

  * Generate observed outcome based on treatment assignment
  gen         earnings = y0
  qui replace earnings = y1 if post == 1 & treat == 1
end

********************************************************************************
* Generate a sample
********************************************************************************
clear
quietly dgp
sum att ate

* Regression breaks
regress earnings i.post i.treat i.post#i.treat i.post#c.age i.post#c.gpa i.post#c.age_sq i.post#c.gpa_sq, robust

* DRDID works
drdid earnings age gpa age_sq gpa_sq, time(year) ivar(id) tr(treat) all

********************************************************************************
* Monte-carlo simulation
********************************************************************************
cap program drop sim
program define sim, rclass
  clear
  quietly dgp
  
  * DRDID
  quietly drdid earnings age gpa age_sq gpa_sq, time(year) ivar(id) tr(treat) all
  
  return scalar dripw = e(b)[1,1]
  return scalar regadjust = e(b)[1,3]
  return scalar ipw = e(b)[1,4]
  quietly su att
  return scalar att = `r(mean)'
  
  * OLS
  quietly regress earnings i.post i.treat i.post#i.treat i.post#c.age i.post#c.gpa i.post#c.age_sq i.post#c.gpa_sq, robust
  return scalar ols = _b[1.post#1.treat]
end

simulate att = r(att) dripw = r(dripw) regadjust = r(regadjust) ipw = r(ipw) ols = r(ols), reps(1000): sim
sum

save ./covariates.dta, replace


* Graphics
use ./covariates.dta, replace

* Calculate true ATT
sum att
local true_att = r(mean)

* Generate bias variables
gen ols_bias = ols - `true_att'
gen dripw_bias = dripw - `true_att'
gen regadjust_bias = regadjust - `true_att'
gen ipw_bias = ipw - `true_att'

* Generate the combined plot
twoway (kdensity ols_bias, lcolor(black) lpattern(solid) lwidth(thick)) ///
       (kdensity dripw_bias, lcolor(gs8) lpattern(solid) lwidth(medthick)) ///
       (kdensity regadjust_bias, lcolor(gs4) lpattern(solid) lwidth(thin)) ///
       (kdensity ipw_bias, lcolor(gs12) lpattern(solid) lwidth(vthick)), ///
       legend(order(1 "OLS" 2 "DRIPW" 3 "Reg. Adjust" 4 "IPW") cols(1) position(3) ring(0) size(small) ///
              symplacement(center) symxsize(7) keygap(1) ///
              label(1 "OLS (black, thick)") label(2 "DRIPW (dark gray, medium)") ///
              label(3 "Reg. Adjust (medium gray, thin)") label(4 "IPW (light gray, very thick)")) ///
       xtitle("Bias in Estimated ATT") ytitle("Density") ///
       title("Distribution of Bias in ATT Estimates by Method") ///
       subtitle("Comparison of Different Estimators") ///
       xline(0, lcolor(gray) lpattern(dash) lwidth(medthick)) ///
       xlabel(-750(250)500) ylabel(, angle(horizontal)) ///
       note("Vertical dashed line at 0 represents unbiased estimates")

graph export ./covariates.png, as(png) name("Graph") replace

capture log close
exit
	   
	   


* Generate the combined plot
twoway (kdensity ols_bias, lcolor(navy%70) lpattern(solid) lwidth(medthick)) ///
       (kdensity dripw_bias, lcolor(maroon%70) lpattern(dash) lwidth(medthick)) ///
       (kdensity regadjust_bias, lcolor(black) lpattern(dash_dot_dot) lwidth(medthick)) ///
       (kdensity ipw_bias, lcolor(dkorange%70) lpattern(dash_dot) lwidth(medthick)), ///
       legend(order(1 "OLS" 2 "DRIPW" 3 "Reg. Adjust" 4 "IPW") cols(1) position(3) ring(0) size(small) ///
              symplacement(center) symxsize(7) keygap(1) ///
              label(1 "OLS (navy, solid)") label(2 "DRIPW (maroon, dashed)") ///
              label(3 "Reg. Adjust (black, dash-dot-dot)") label(4 "IPW (orange, dash-dot)")) ///
       xtitle("Bias in Estimated ATT") ytitle("Density") ///
       title("Distribution of Bias in ATT Estimates by Method") ///
       subtitle("Comparison of Different Estimators") ///
       xline(0, lcolor(gray) lpattern(dash) lwidth(medthick)) ///
       xlabel(-750(250)500) ylabel(, angle(horizontal)) ///
       note("Vertical dashed line at 0 represents unbiased estimates")

graph export ./covariates.png, as(png) name("Graph") replace



capture log close
exit
