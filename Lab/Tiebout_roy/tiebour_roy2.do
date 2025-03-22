* Sorting by treatment effects into geographic units with heterogenous treatment effects
set seed 123

* Define population parameters
local num_people = 30000000
local num_large_counties = 5
local num_small_counties = 249
local total_counties = `num_large_counties' + `num_small_counties'

* Define county populations
local large_county_pop = 3000000  // 3M each for large counties
local total_large_pop = `large_county_pop' * `num_large_counties'
local small_county_pop = 60241     // Adjusted to make total population exact

* Clear current data and create new dataset
clear
set obs `num_people'

* Generate treatment effects with two different distributions
* First, create ID variable
gen id = _n

* For positive effects: Normal distribution with mean 5 and SD 1
gen treatment_effect = .
local half_people = `num_people'/2
replace treatment_effect = rnormal(5, 1) if _n <= `half_people'

* For negative effects: Normal distribution with mean -1 and SD 0.5
replace treatment_effect = rnormal(-1, 0.5) if _n > `half_people'

* Sort individuals by treatment effect in descending order
gsort -treatment_effect
gen sorted_index = _n

* Initialize county assignments
gen county = .

* Assign first 15M people (highest treatment effects) to large counties
local current_idx = 1
forvalues i = 1/`num_large_counties' {
    local end_idx = `current_idx' + `large_county_pop' - 1
    replace county = `i' if inrange(sorted_index, `current_idx', `end_idx')
    local current_idx = `end_idx' + 1
}

* Assign remaining to small counties
forvalues i = 1/`num_small_counties' {
    local county_num = `i' + `num_large_counties'
    local end_idx = min(`current_idx' + `small_county_pop' - 1, `num_people')
    replace county = `county_num' if inrange(sorted_index, `current_idx', `end_idx')
    local current_idx = `end_idx' + 1
    
    * Break if all people are assigned
    if `current_idx' > `num_people' {
        continue, break
    }
}

* Calculate ATEs
sum treatment_effect
local overall_ate = r(mean)  // Population average

* Create county-level dataset
preserve
collapse (mean) county_ate=treatment_effect (count) county_size=treatment_effect, by(county)
sum county_ate
local county_level_ate = r(mean)  // Average of county averages

* Sort counties by ATE for visualization
sort county_ate
gen county_index = _n

* Create plot
graph bar county_ate, over(county_index, label(nolabel)) ///
    title("County-Level Average Treatment Effects") ///
    ytitle("Average Treatment Effect (ATE)") ///
    name(ate_graph, replace)

* Add reference lines with text labels
local overall_ate_rounded = round(`overall_ate', 0.01)
local county_level_ate_rounded = round(`county_level_ate', 0.01)

graph bar county_ate, over(county_index, label(nolabel)) ///
    title("County-Level Average Treatment Effects") ///
    subtitle("Counties sorted by treatment effect") ///
    ytitle("Average Treatment Effect (ATE)") ///
    yline(`overall_ate' `county_level_ate', lpattern(dash)) ///
    text(5 `total_counties' "Overall ATE = `overall_ate_rounded'", place(e)) ///
    text(3 `total_counties' "County Average ATE = `county_level_ate_rounded'", place(e)) ///
    name(ate_graph, replace)

* Print values to verify
di "Overall ATE: " %9.4f `overall_ate'
di "County-level Average ATE: " %9.4f `county_level_ate'

* Print first 5 and last 5 county ATEs
sort county
di "First 5 county ATEs:"
list county county_ate if _n <= 5
di "Last 5 county ATEs:"
list county county_ate if _n > `total_counties' - 5

* Verify county sizes
tab county if county <= `num_large_counties', missing
sum county_size if county > `num_large_counties'
count if county == .

restore

* Optional: Return to original sort order if needed
sort id
