* pta_weights.do
clear all
set seed 12345

* Set parameters
local n_counties = 500
local n_people = 50000
local base_outcome = 100

* Create county-level dataset
set obs `n_counties'
gen county_id = _n

* Generate county populations with variation
* Using a log-normal distribution to create realistic population skew
gen log_pop = rnormal(3, 1)
gen county_pop = round(exp(log_pop))

* Normalize to get exactly n_people
egen total_pop = sum(county_pop)
replace county_pop = round(county_pop * `n_people' / total_pop)

* Ensure we have exactly n_people (adjust largest county if needed)
egen new_total = sum(county_pop)
local diff = `n_people' - new_total
replace county_pop = county_pop + `diff' if county_id == 1

* Create treatment indicator (let's treat 40% of counties)
gen treated = (county_id <= 200)

* Expand to person-level data
expand county_pop
gen person_id = _n

* Now let's create the three scenarios

********************************************************************************
* SCENARIO 1: Unweighted PTA holds, Population-weighted PTA holds
********************************************************************************

preserve

* Y(0) has a common trend across all counties
gen y0_t1 = `base_outcome' + rnormal(0, 5)
gen y0_t2 = y0_t1 + 10 + rnormal(0, 5)  // Common trend of +10

* Calculate the change in Y(0)
gen change_y0 = y0_t2 - y0_t1

* Collapse to county level for unweighted analysis
collapse (mean) change_y0 y0_t1 y0_t2 treated county_pop, by(county_id)

* Check parallel trends - Unweighted
reg change_y0 treated
local unweight_diff = _b[treated]
local unweight_se = _se[treated]

* Check parallel trends - Population weighted
reg change_y0 treated [aw=county_pop]
local popweight_diff = _b[treated]
local popweight_se = _se[treated]

* Display results
di _n "SCENARIO 1: Both PTA hold"
di "Unweighted difference in trends: " %6.3f `unweight_diff' " (SE: " %6.3f `unweight_se' ")"
di "Pop-weighted difference in trends: " %6.3f `popweight_diff' " (SE: " %6.3f `popweight_se' ")"
di "(Values close to zero indicate parallel trends hold)"

restore




********************************************************************************
* SCENARIO 2: Unweighted PTA holds, Population-weighted PTA does NOT hold
********************************************************************************


* Y(0) in period 1
gen y0_t1 = `base_outcome' + rnormal(0, 5)

* First, ensure treated and control have similar county size distributions
egen pop_rank = rank(county_pop), track

* Key insight: We need trends to differ by county size AND treatment
* But in a way that cancels out in unweighted analysis

* Base trend
gen trend = 10

* Create the crucial interaction:
* Among TREATED counties: large ones have higher trends
* Among CONTROL counties: large ones have lower trends
gen large_county = (pop_rank > 250)

* This is the key mechanism:
replace trend = 15 if treated == 1 & large_county == 1  // Treated + Large: +15
replace trend = 5  if treated == 1 & large_county == 0  // Treated + Small: +5
replace trend = 5  if treated == 0 & large_county == 1  // Control + Large: +5
replace trend = 15 if treated == 0 & large_county == 0  // Control + Small: +15

* Generate Y(0) in period 2
gen y0_t2 = y0_t1 + trend + rnormal(0, 2)

* Calculate the change
gen change_y0 = y0_t2 - y0_t1

* Collapse to county level
collapse (mean) change_y0 y0_t1 y0_t2 treated county_pop large_county, by(county_id)

* Show the pattern (using older Stata syntax)
di _n "Average trends by treatment and county size:"
bysort treated large_county: sum change_y0 county_pop

* Check parallel trends - Unweighted
reg change_y0 treated
local unweight_diff = _b[treated]
local unweight_se = _se[treated]

* Check parallel trends - Population weighted  
reg change_y0 treated [aw=county_pop]
local popweight_diff = _b[treated]
local popweight_se = _se[treated]

* Display results
di _n "SCENARIO 2: Unweighted PTA holds, Population-weighted PTA fails"
di "Unweighted difference in trends: " %6.3f `unweight_diff' " (SE: " %6.3f `unweight_se' ")"
di "Pop-weighted difference in trends: " %6.3f `popweight_diff' " (SE: " %6.3f `popweight_se' ")"

* Let's also check the county counts to verify balance
di _n "County distribution:"
tab treated large_county, row col

capture log close 
exit



********************************************************************************
* SCENARIO 3: Unweighted PTA does NOT hold, Population-weighted PTA holds
********************************************************************************

preserve

* Small counties have violated parallel trends, but they have few people
* Create systematic difference in trends for small counties only
egen pop_pct20 = pctile(county_pop), p(20)
gen small_county = (county_pop <= pop_pct20)

* Small treated counties have different trends
gen y0_t1 = `base_outcome' + rnormal(0, 5)
gen trend = 10
replace trend = 25 if small_county == 1 & treated == 1  // Violation in small treated counties
gen y0_t2 = y0_t1 + trend + rnormal(0, 5)

* Since small counties have few people, population-weighting downweights the violation

* Check parallel trends (similar code as before)
* ... [checking code]

restore

********************************************************************************
* Create a program to check parallel trends more systematically
********************************************************************************

program check_pta
    * Collapse to county level for unweighted
    preserve
    collapse (mean) y0_t1 y0_t2 treated county_pop, by(county_id)
    
    * Unweighted parallel trends
    gen change = y0_t2 - y0_t1
    reg change treated
    local unweight_diff = _b[treated]
    local unweight_se = _se[treated]
    
    * Population-weighted parallel trends
    reg change treated [aw=county_pop]
    local popweight_diff = _b[treated]
    local popweight_se = _se[treated]
    
    restore
    
    * Display results
    di "Parallel Trends Test:"
    di "Unweighted diff: " %6.3f `unweight_diff' " (SE: " %6.3f `unweight_se' ")"
    di "Pop-weighted diff: " %6.3f `popweight_diff' " (SE: " %6.3f `popweight_se' ")"
end
