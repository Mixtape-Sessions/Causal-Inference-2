* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Trade Liberalization and Markup Dispersion: Evidence from China's WTO
* By Yi Lu and Linhui Yu
* American Economic Journal: Applied Economics 2015
* %%
* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
cd ~/Documents/Mixtape-Sessions/Codechella-Madrid/Labs/China-WTO/
use "data/industry_by_year.dta", clear

* Load and clean data ----------------------------------------------------------
* 2x2
keep if year == 2004 | year == 2000

* Create the wide-format variables using bysort
bysort sic3: gen ln_theil_2004 = ln_theil if year == 2004
bysort sic3: gen ln_theil_2000 = ln_theil if year == 2000
bysort sic3: gen tariff_2000 = tariff if year == 2000
bysort sic3: egen temp_ln_theil_2004 = max(ln_theil_2004)
bysort sic3: egen temp_ln_theil_2000 = max(ln_theil_2000)
bysort sic3: egen temp_tariff_2000 = max(tariff_2000)
replace ln_theil_2004 = temp_ln_theil_2004
replace ln_theil_2000 = temp_ln_theil_2000
replace tariff_2000 = temp_tariff_2000
drop temp_*

* First-differenced outcome
gen Delta_ln_theil = ln_theil_2004 - ln_theil_2000
* treatment dose
gen dose = max(tariff_2000 - 0.1, 0)

* Collapse to one observation per sic3
collapse (firstnm) Delta_ln_theil tariff_2000 dose, by(sic3)

* drop NAs
drop if Delta_ln_theil >= .


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Estimate continuous treatment effects
* Average change in Y for 0 dose group
sum Delta_ln_theil if dose == 0
local count_trend_estimate = r(mean)

gen Delta_y_diff = Delta_ln_theil - `count_trend_estimate'

* Regress \Delta Y - count trend estimate on a linear function of dose
reg Delta_y_diff dose if dose > 0

* Get points for plotting
predict te_est_linear if dose > 0, xb

* Regress \Delta Y - count trend estimate on a spline
cap drop _bsp_*
makespline bspline dose if dose > 0
reg Delta_y_diff _bsp_* dose if dose > 0

* different non-parametric estimator for the treatment effect
npregress kernel Delta_y_diff dose if dose > 0

* Get points for plotting
predict te_est_spline if dose > 0, xb

* Regress \Delta Y - count trend estimate on a set of bins
cap drop bin_*
gen bin_1 = dose < 0.1
gen bin_2 = dose >= 0.1 & dose < 0.2
gen bin_3 = dose >= 0.2
reg Delta_y_diff i.bin_1 i.bin_2 i.bin_3 if dose > 0, nocons

* Get points for plotting
predict te_est_bins if dose > 0, xb

* Plot
sort dose
twoway ///
  (scatter Delta_y_diff dose) ///
  (line te_est_linear dose) ///
  (line te_est_spline dose) ///
  (line te_est_bins dose), ///
  xlabel(, grid) ///
  ylabel(-1(0.5)1, grid) ///
  yscale(range(-1 1)) ///
  xtitle("(Predicted) decline in tariff from WTO Entrance") ///
  ytitle("Estimated ATT(d|d)") ///
  legend(order(2 "Linear Estimate" 3 "Spline Estimate" 4 "Bins Estimate") ///
          position(6) cols(2) region(style(none))) ///
  graphregion(color(white)) ///
  plotregion(style(none)) ///
  name(continuous)


* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Pre-trends test ----
use "data/industry_by_year.dta", clear

* 2x2
keep if year == 2000 | year == 1998

* Create the wide-format variables using bysort
bysort sic3: gen ln_theil_2000 = ln_theil if year == 2000
bysort sic3: gen ln_theil_1998 = ln_theil if year == 1998
bysort sic3: gen tariff_2000 = tariff if year == 2000
bysort sic3: egen temp_ln_theil_2000 = max(ln_theil_2000)
bysort sic3: egen temp_ln_theil_1998 = max(ln_theil_1998)
bysort sic3: egen temp_tariff_2000 = max(tariff_2000)
replace ln_theil_2000 = temp_ln_theil_2000
replace ln_theil_1998 = temp_ln_theil_1998
replace tariff_2000 = temp_tariff_2000
drop temp_*

* First-differenced outcome
gen Delta_ln_theil = ln_theil_1998 - ln_theil_2000
* treatment dose
gen dose = max(tariff_2000 - 0.1, 0)

* Collapse to one observation per sic3
collapse (firstnm) Delta_ln_theil tariff_2000 dose, by(sic3)

* drop NAs
drop if Delta_ln_theil >= .

* Average change in Y for 0 dose group
sum Delta_ln_theil if dose == 0
local count_trend_estimate = r(mean)

gen Delta_y_diff = Delta_ln_theil - `count_trend_estimate'

* Regress \Delta Y - count trend estimate on a linear function of dose
reg Delta_y_diff dose if dose > 0

* Get points for plotting
predict te_est_linear if dose > 0, xb

* Regress \Delta Y - count trend estimate on a spline
cap drop _bsp_*
makespline bspline dose
reg Delta_y_diff _bsp_* dose if dose > 0

* Get points for plotting
predict te_est_spline if dose > 0, xb

* Plot
sort dose
twoway ///
  (scatter Delta_y_diff dose) ///
  (line te_est_linear dose) ///
  (line te_est_spline dose) ///
  xlabel(, grid) ///
  ylabel(-1(0.5)1, grid) ///
  yscale(range(-1 1)) ///
  xtitle("(Predicted) decline in tariff from WTO Entrance") ///
  ytitle("Estimated ATT(d|d)") ///
  legend(order(2 "Linear Estimate" 3 "Spline Estimate") ///
          position(6) cols(2) region(style(none))) ///
  graphregion(color(white)) ///
  plotregion(style(none)) ///
  name(pretrends)
