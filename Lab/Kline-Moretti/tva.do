* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Setup ----
* ssc install reghdfe
* ssc install coefplot
* ssc install drdid
* ssc install csdid
* ssc install csdid_plot

clear all
cd "~/Documents/Mixtape-Sessions/Codechella-Madrid/Labs/Kline-Moretti"
insheet using "data/tva.csv"

keep if county_has_no_missing == "TRUE"
egen county_code_numeric = group(county_code)
xtset county_code_numeric year

save "data/tva.dta", replace


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Making data wide ----
* Sorry, stata is weird and I'm not sure if there's an easier way to do this

* First, sort by county_code and year to ensure proper ordering
sort county_code year

* Create the wide-format variables using bysort
bysort county_code: gen ln_manufacturing_1920 = ln_manufacturing if year == 1920
bysort county_code: gen ln_manufacturing_1930 = ln_manufacturing if year == 1930
bysort county_code: gen ln_manufacturing_1940 = ln_manufacturing if year == 1940
bysort county_code: gen ln_manufacturing_1950 = ln_manufacturing if year == 1950
bysort county_code: gen ln_manufacturing_1960 = ln_manufacturing if year == 1960
bysort county_code: egen temp_mfg_1920 = max(ln_manufacturing_1920)
bysort county_code: egen temp_mfg_1930 = max(ln_manufacturing_1930)
bysort county_code: egen temp_mfg_1940 = max(ln_manufacturing_1940)
bysort county_code: egen temp_mfg_1950 = max(ln_manufacturing_1950)
bysort county_code: egen temp_mfg_1960 = max(ln_manufacturing_1960)
replace ln_manufacturing_1920 = temp_mfg_1920
replace ln_manufacturing_1930 = temp_mfg_1930
replace ln_manufacturing_1940 = temp_mfg_1940
replace ln_manufacturing_1950 = temp_mfg_1950
replace ln_manufacturing_1960 = temp_mfg_1960
drop temp_*

bysort county_code: gen ln_agriculture_1920 = ln_agriculture if year == 1920
bysort county_code: gen ln_agriculture_1930 = ln_agriculture if year == 1930
bysort county_code: gen ln_agriculture_1940 = ln_agriculture if year == 1940
bysort county_code: gen ln_agriculture_1950 = ln_agriculture if year == 1950
bysort county_code: gen ln_agriculture_1960 = ln_agriculture if year == 1960
bysort county_code: egen temp_agr_1920 = max(ln_agriculture_1920)
bysort county_code: egen temp_agr_1930 = max(ln_agriculture_1930)
bysort county_code: egen temp_agr_1940 = max(ln_agriculture_1940)
bysort county_code: egen temp_agr_1950 = max(ln_agriculture_1950)
bysort county_code: egen temp_agr_1960 = max(ln_agriculture_1960)
replace ln_agriculture_1920 = temp_agr_1920
replace ln_agriculture_1930 = temp_agr_1930
replace ln_agriculture_1940 = temp_agr_1940
replace ln_agriculture_1950 = temp_agr_1950
replace ln_agriculture_1960 = temp_agr_1960
drop temp_*

* Keep only rows where year == 1940 (one row per county)
keep if year == 1940
save "data/tva_wide.dta", replace


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Diff-in-diff ----
* TWFE Regression
use "data/tva.dta", clear
reghdfe ln_manufacturing i.tva#i.post if year == 1940 | year == 1960, absorb(county_code year) vce(robust)

* \Delta Y on TVA dummy
use "data/tva_wide", clear
gen Dy = ln_manufacturing_1960 - ln_manufacturing_1940
reg Dy i.tva, r


* Pre-trends ----
drop Dy
gen Dy = ln_manufacturing_1930 - ln_manufacturing_1940
reg Dy i.tva, r


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Event-study ----
use "data/tva.dta", clear

* Create event-time
gen rel_year = year

* For untreated group, use the dropped reference period 1940
replace rel_year = 1940 if tva == 0

reghdfe ln_manufacturing ib1940.rel_year, absorb(county_code year) vce(robust)





* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Including covariates ----
use "data/tva_wide.dta", clear
gen Delta_ln_manufacturing = ln_manufacturing_1960 - ln_manufacturing_1940

** Outcome Regression ----
* Learn model of \Delta Y(0) on Xs
reg Delta_ln_manufacturing agriculture_share_1930 manufacturing_share_1930 white_share_1930 white_share_1930_sq if tva == 0, r

* Predicting Y_{i1960}(0) - Y_{i1940}(0) for the treatment group
predict Delta_y0_hat, xb

* Treatment dummy
gen D = tva

* Observed change in ln_manufacturing
gen Delta_y = Delta_ln_manufacturing

* ≈ \hat{E}(y_i1 - y_i0 | D = 1) - \hat{E}(y_i1 - y_i0 | D = 0)
sum Delta_y if D == 1
loc mean_Delta_y = r(mean)

sum Delta_y0_hat if D == 1
loc mean_Delta_y0_hat = r(mean)

loc did_OR = `mean_Delta_y' - `mean_Delta_y0_hat'
disp in red "Outcome Regression Estimate: " `did_OR'

* Using DRDID package
preserve
  use "data/tva.dta", clear
  drdid ln_manufacturing agriculture_share_1930 manufacturing_share_1930 white_share_1930 white_share_1930_sq if year == 1940 | year == 1960, ivar(county_code) time(year) tr(tva) all
restore


** IPW ----
* Propensity score model
logit tva agriculture_share_1930 manufacturing_share_1930 white_share_1930 white_share_1930_sq

* Save propensity score
predict ps, pr

* IPW weights
sum D
loc mean_D = r(mean)
gen w1 = D / `mean_D'
gen w0 = 1 / `mean_D' * (1 - D) * ps / (1 - ps)

* ≈ E(y_i1 - y_i0 | D = 1) - E(y_i1 - y_i0 | D = 0)
gen prod = w1 * Delta_y
sum prod
loc mean_Delta_y = r(mean)
drop prod

gen prod = w0 * Delta_y
sum prod
loc mean_Delta_y0_hat = r(mean)
drop prod

loc did_ipw = `mean_Delta_y' - `mean_Delta_y0_hat'
disp in red "IPW Estimate: " `did_ipw'

* Using DRDID package
preserve
  use "data/tva.dta", clear
  drdid ln_manufacturing agriculture_share_1930 manufacturing_share_1930 white_share_1930 white_share_1930_sq if year == 1940 | year == 1960, ivar(county_code) time(year) tr(tva) all
restore


** Doubly-robust DID ----
* Normalize weights to be mean 1
sum w1
loc mean_w1 = r(mean)
replace w1 = w1 / `mean_w1'
sum w0
loc mean_w0 = r(mean)
replace w0 = w0 / `mean_w0'

* Doubly robust DID
gen prod = w1 * (Delta_y - Delta_y0_hat)
sum prod
loc mean_Delta_y = r(mean)
drop prod 

gen prod = w0 * (Delta_y - Delta_y0_hat)
sum prod
loc mean_Delta_y0_hat = r(mean)
drop prod 

loc did_drdid = `mean_Delta_y' - `mean_Delta_y0_hat'
disp in red "DRDID Estimate: " `did_drdid'

* Using DRDID package
preserve
  use "data/tva.dta", clear
  drdid ln_manufacturing agriculture_share_1930 manufacturing_share_1930 white_share_1930 white_share_1930_sq if year == 1940 | year == 1960, ivar(county_code) time(year) tr(tva) all
restore



** Pre-trend DRDID estimates ----
preserve
  use "data/tva.dta", clear
  drdid ln_manufacturing agriculture_share_1930 manufacturing_share_1930 white_share_1930 white_share_1930_sq if year == 1930 | year == 1940, ivar(county_code) time(year) tr(tva) all
restore




** %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
** Event-study with covariates ----
use "data/tva.dta", clear
gen g = tva * 1945

* Internally, the package is estimating a bunch of 2x2 `drdid_panel` calls
* for each event-time (1920, 1930, 1950, and 1960)
*
* Note 1930 and 1960 estimate is exactly the same!!
*
csdid ln_manufacturing agriculture_share_1930 manufacturing_share_1930 white_share_1930 white_share_1930_sq, ///
  ivar(county_code_numeric) time(year) gvar(g) dripw
csdid_plot, group(1945)
