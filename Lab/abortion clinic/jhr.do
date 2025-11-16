* abortion_jhr.do 
clear all
cd "/Users/scunning/collegio-carlo-alberto/labs/abortion clinic"
use ./abortion_jhr.dta, clear

* First, a version of the old result with BOTH counts and rates
xtpoisson aborttotal travel_distance i.year if pop>0, exposure(pop) vce(robust) fe
est store poisson_rate

* Also run without exposure for comparison
xtpoisson aborttotal travel_distance i.year if pop>0, vce(robust) fe  
est store poisson_count

* Second, we use the continuous diff in diff approach
* ----------------------------------------------------------
* Keep just the pre and post periods
keep if year == 2013 | year == 2014

* Generate wide-format outcome and baseline treatment (travel distance)
bysort fips_code: gen abort_2013 = aborttotal if year == 2013
bysort fips_code: gen abort_2014 = aborttotal if year == 2014
bysort fips_code: gen pop_2013 = pop if year == 2013
bysort fips_code: gen pop_2014 = pop if year == 2014

replace travel_distance = travel_distance*100
bysort fips_code: gen travel_2013 = travel_distance if year == 2013

* Fill in across both years using max (since only one year is non-missing per obs)
bysort fips_code: egen temp_abort_2013 = max(abort_2013)
bysort fips_code: egen temp_abort_2014 = max(abort_2014)
bysort fips_code: egen temp_pop_2013 = max(pop_2013)
bysort fips_code: egen temp_pop_2014 = max(pop_2014)
bysort fips_code: egen temp_travel_2013 = max(travel_2013)

* Replace the variables with filled versions
replace abort_2013 = temp_abort_2013
replace abort_2014 = temp_abort_2014
replace pop_2013 = temp_pop_2013
replace pop_2014 = temp_pop_2014
replace travel_2013 = temp_travel_2013

* Clean up temporary variables
drop temp_*

* Create wide-format travel distance for 2014
bysort fips_code: gen travel_2014 = travel_distance if year == 2014
bysort fips_code: egen temp_travel_2014 = max(travel_2014)
replace travel_2014 = temp_travel_2014
drop temp_travel_2014

* Compute treatment dose: change in travel distance
gen dose = travel_2014 - travel_2013

* BOTH abortion counts and rates
gen delta_abort_count = abort_2014 - abort_2013
gen abort_rate_2013 = (abort_2013 / pop_2013) * 1000
gen abort_rate_2014 = (abort_2014 / pop_2014) * 1000
gen delta_abort_rate = abort_rate_2014 - abort_rate_2013

collapse (firstnm) delta_abort_count delta_abort_rate dose travel_2013 travel_2014 ///
    abort_2013 abort_2014 pop_2013 pop_2014 abort_rate_2013 abort_rate_2014, by(fips_code)

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Estimate continuous treatment effects - COUNTS VERSION
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

* Average change in Y for 0 dose group
sum delta_abort_count if dose <= 10
local cf_trend_count = r(mean) // "counterfactual trend" using the control

gen delta_y_diff_count = delta_abort_count - `cf_trend_count'

* Regress \Delta Y - count trend estimate on a linear function of dose
reg delta_y_diff_count dose if dose > 10
est store stata_hack_count

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Estimate continuous treatment effects - RATES VERSION  
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

* Average change in Y for 0 dose group
sum delta_abort_rate if dose <= 10
local cf_trend_rate = r(mean) // "counterfactual trend" using the control

gen delta_y_diff_rate = delta_abort_rate - `cf_trend_rate'

* Regress \Delta Y - rate trend estimate on a linear function of dose
reg delta_y_diff_rate dose if dose > 10
est store stata_hack_rate

* Add after the linear regression for both counts and rates:

  
  

* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Display comparison table
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

esttab poisson_count poisson_rate stata_hack_count stata_hack_rate, ///
    title("Comparison: Counts vs Rates") ///
    mtitles("Poisson Count" "Poisson Rate" "Stata Hack Count" "Stata Hack Rate") ///
    b(3) se(3) star(* 0.10 ** 0.05 *** 0.01)

* Plot both versions
* Get points for plotting
predict te_est_linear_count if dose > 10, xb
predict te_est_linear_rate if dose > 10, xb

* Plot counts
twoway ///
  (scatter delta_y_diff_count dose) ///
  (line te_est_linear_count dose), ///
  xlabel(, grid) ///
  ylabel(, grid) ///
  xtitle("Distance Increase (miles)") ///
  ytitle("Change in Abortion Count") ///
  title("Continuous DiD: Abortion Counts") ///
  legend(order(1 "Data" 2 "Linear fit")) ///
  name(counts_plot, replace)

* Plot rates  
twoway ///
  (scatter delta_y_diff_rate dose) ///
  (line te_est_linear_rate dose), ///
  xlabel(, grid) ///
  ylabel(, grid) ///
  xtitle("Distance Increase (miles)") ///
  ytitle("Change in Abortion Rate (per 1000)") ///
  title("Continuous DiD: Abortion Rates") ///
  legend(order(1 "Data" 2 "Linear fit")) ///
  name(rates_plot, replace)

* Combine plots
graph combine counts_plot rates_plot, ///
    title("Comparison: Counts vs Rates") ///
    name(combined, replace)
	
* SPLINES FOR COUNTS
* For rates
npregress kernel delta_y_diff_rate dose if dose > 10
predict te_est_spline_rate if dose > 10

* For counts  
npregress kernel delta_y_diff_count dose if dose > 10
predict te_est_spline_count if dose > 10

* Updated plots with splines
twoway ///
  (scatter delta_y_diff_count dose) ///
  (line te_est_linear_count dose) ///
  (line te_est_spline_count dose), ///
  xlabel(, grid) ylabel(, grid) ///
  xtitle("Distance Increase (miles)") ytitle("Change in Abortion Count") ///
  title("Continuous DiD: Abortion Counts") ///
  legend(order(1 "Data" 2 "Linear" 3 "Spline")) ///
  name(counts_plot, replace)

twoway ///
  (scatter delta_y_diff_rate dose) ///
  (line te_est_linear_rate dose) ///
  (line te_est_spline_rate dose), ///
  xlabel(, grid) ylabel(, grid) ///
  xtitle("Distance Increase (miles)") ytitle("Change in Abortion Rate") ///
  title("Continuous DiD: Abortion Rates") ///
  legend(order(1 "Data" 2 "Linear" 3 "Spline")) ///
  name(rates_plot, replace)

  