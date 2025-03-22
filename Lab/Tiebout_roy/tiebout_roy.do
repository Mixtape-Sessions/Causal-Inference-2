* Randomized sorting into geographic units with heterogenous treatment effects
set seed 123

* Define population parameters
local num_people = 30000000 // 30 million people (Texas).
local num_large_counties = 5 
local num_small_counties = 249
local total_counties = `num_large_counties' + `num_small_counties'

* Define county populations
local large_county_pop = 3000000 // 3M each for large counties
local small_county_pop = 15000000 / `num_small_counties' // Remaining split equally

* Clear current data and create new dataset
clear
set obs `num_people'

* Generate individual-level potential outcomes
gen y0 = rnormal(10, 2)
gen treatment_effect = rnormal(2, 1)
gen y1 = y0 + treatment_effect
gen individual_ate = y1 - y0

* Assign counties
gen county = .
local current_idx = 1

* Assign large counties
forvalues i = 1/`num_large_counties' {
    replace county = `i' if _n >= `current_idx' & _n < `current_idx' + `large_county_pop'
    local current_idx = `current_idx' + `large_county_pop'
}

* Assign small counties
forvalues i = 1/`num_small_counties' {
    local county_num = `i' + `num_large_counties'
    replace county = `county_num' if _n >= `current_idx' & _n < `current_idx' + `small_county_pop'
    local current_idx = `current_idx' + `small_county_pop'
}

* Calculate ATEs
sum individual_ate
local overall_ate = r(mean)

* Create county-level dataset
preserve
collapse (mean) county_ate=individual_ate, by(county)
sum county_ate
local county_level_ate = r(mean)

* Sort counties by ATE for visualization
sort county_ate
gen county_index = _n

* Create plot
graph bar county_ate, over(county_index, label(nolabel)) ///
    title("County-Level Average Treatment Effects") ///
    ytitle("Average Treatment Effect (ATE)") ///
    name(ate_graph, replace)

* Add reference lines (using post-estimation command)
local overall_ate_rounded = round(`overall_ate', 0.01)
local county_level_ate_rounded = round(`county_level_ate', 0.01)

graph bar county_ate, over(county_index, label(nolabel)) ///
    title("County-Level Average Treatment Effects") ///
    ytitle("Average Treatment Effect (ATE)") ///
    yline(`overall_ate' `county_level_ate', lpattern(dash)) ///
    text(3.5 `total_counties' "Overall ATE = `overall_ate_rounded'", place(e)) ///
    text(2.8 `total_counties' "County Average ATE = `county_level_ate_rounded'", place(e)) ///
    name(ate_graph, replace)

* Print the means to verify they're close
di "Overall ATE: " %5.4f `overall_ate'
di "County-level Average ATE: " %5.4f `county_level_ate'
restore
