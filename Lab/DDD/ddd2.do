********************************************************************************
* name: ddd2.do
* author: scott cunningham (baylor)
* description: simulation for triple diff with potential outcomes but using a biased did and an unbiased triple diff
* last updated: march 5, 2024
********************************************************************************

clear
capture log close
set seed 20200403

* States, Groups, and Time Setup
set obs 40
gen state = _n

* Generate treatment groups -- 20 states that adopted the maternity benefit policy
gen 	experimental = 0
replace experimental = 1 in 1/20

* 50 cities per state
expand 50
bysort state: gen city_no = _n
egen city = group(city_no state)
drop city_no

* Three groups per city: men (1), married women (2), and older women (3)
expand 3
bysort city state: gen worker = _n
egen id = group(worker city state)

* Time, 10 years
expand 10
sort state
bysort state city worker: gen year = _n + 2010 - 1

* Define the after period (post-2015)
gen after = year >= 2015

* Baseline earnings in 2010 with different values for experimental and non-experimental states
gen 	baseline = 40000 if worker == 3  // Older women
replace baseline = 45000 if worker == 2  // Married women
replace baseline = 50000 if worker == 1  // Men

* Adjust baseline for experimental states.  Experimental states will be on a different trend.
replace baseline = 1.5 * baseline if experimental == 1

* Create counter for the annual wage growth for Y(0) below
gen year_diff = year - 2010

* Setting trends for states and groups
gen 	state_trend = 1000 if experimental == 1
replace state_trend = 1500 if experimental == 0

gen 	group_trend = 500  if worker == 2
replace group_trend = 1000 if worker == 1 | worker == 3

* Annual wage growth for Y(0) incorporating state and group trends
gen y0 = baseline + state_trend * year_diff + group_trend * year_diff

* Adding random error to Y(0)
gen 	error = rnormal(0, 1500)
replace y0 = y0 + error

* Define Y(1) with an ATT of -$5000 for married women in experimental states post-2015
gen 	y1 = y0
replace y1 = y0 - 5000 if experimental == 1 & worker == 2 & after == 1

* Treatment effect
gen delta = y1-y0
su delta if after==1 & experimental ==1 & worker==2
gen att = `r(mean)'
su att // ATT = -5000

* Treatment indicator
gen 	treat = 0
replace treat = 1 if experimental == 1 & worker == 2 & after == 1

* Final earnings using switching equation
gen earnings = treat * y1 + (1 - treat) * y0

**************************************************************************** 
* Calculating the 8 averages
**************************************************************************** 

* 1. After, Married, Experimental
egen avg_wage_ame = mean(earnings) if after == 1 & experimental == 1 & worker == 2

* 2. Before, Married, Experimental
egen avg_wage_bme = mean(earnings) if after == 0 & experimental == 1 & worker == 2

* 3. After, Single Men and Older Women, Experimental
egen avg_wage_asoe = mean(earnings) if after == 1 & experimental == 1 & worker != 2

* 4. Before, Single Men and Older Women, Experimental
egen avg_wage_bsoe = mean(earnings) if after == 0 & experimental == 1 & worker != 2

* 5. After, Married, Non-Experimental
egen avg_wage_amn = mean(earnings) if after == 1 & experimental == 0 & worker == 2

* 6. Before, Married, Non-Experimental
egen avg_wage_bmn = mean(earnings) if after == 0 & experimental == 0 & worker == 2

* 7. After, Single Men and Older Women, Non-Experimental
egen avg_wage_ason = mean(earnings) if after == 1 & experimental == 0 & worker != 2

* 8. Before, Single Men and Older Women, Non-Experimental
egen avg_wage_bson = mean(earnings) if after == 0 & experimental == 0 & worker != 2


**************************************************************************** 
* Biased DiD Case 1: married women to married women but in different states
**************************************************************************** 
summarize avg_wage_ame, meanonly
local after_married_exp = r(mean)

summarize avg_wage_bme, meanonly
local before_married_exp = r(mean)

summarize avg_wage_amn, meanonly
local after_married_nonexp = r(mean)

summarize avg_wage_bmn, meanonly
local before_married_nonexp = r(mean)

* Calculate the DiD estimate
local DiD_case1 = (`after_married_exp' - `before_married_exp') - (`after_married_nonexp' - `before_married_nonexp')

* Display the result
display "Difference-in-Differences Estimate: " `DiD_case1'

* Regression event study for biased DID. 
gen 	treated1=0
replace treated1=1 if experimental==1 & worker==2
replace treated1=. if worker~=2

* same bias
reg earnings treated1##after, cluster(state)

* Biased event study too
reg earnings treated1##ib2014.year, cluster(state)

coefplot, keep(1.treated1#*) omitted baselevels cirecast(rcap) ///
    rename(1.treated1#([0-9]+).year = \1, regex) at(_coef) ///
    yline(0, lp(solid)) yline(-5000, lp(dot)) xline(2014.5, lpattern(dash)) ///
    xlab(2010(1)2019) title("Biased Diff-in-Diff")

**************************************************************************** 
** Biased DiD Case 2: Placebo DiD using Single Men and Older Women
**************************************************************************** 

* Summarize and store the averages for Single Men and Older Women
summarize avg_wage_asoe, meanonly
local after_soe_exp = r(mean)

summarize avg_wage_bsoe, meanonly
local before_soe_exp = r(mean)

summarize avg_wage_ason, meanonly
local after_soe_nonexp = r(mean)

summarize avg_wage_bson, meanonly
local before_soe_nonexp = r(mean)

* Calculate the DiD estimate for Single Men and Older Women (Placebo DiD)
local DiD_placebo = (`after_soe_exp' - `before_soe_exp') - (`after_soe_nonexp' - `before_soe_nonexp')

* Display the result for Placebo DiD
display "Placebo Difference-in-Differences Estimate: " `DiD_placebo'

* Create treatment indicator for Single Men and Older Women in experimental states
gen 	treated_placebo = 0
replace treated_placebo = 1 if experimental == 1 & (worker == 1 | worker == 3)
replace treated_placebo = . if worker==2

* Run the regression for the Placebo DiD
reg earnings treated_placebo##after, cluster(state)

* Run the event study for Placebo DiD to illustrate the bias
reg earnings treated_placebo##ib2014.year, cluster(state)

* Plot the event study results for Placebo DiD
coefplot, keep(1.treated_placebo#*) omitted baselevels cirecast(rcap) ///
    rename(1.treated_placebo#([0-9]+).year = \1, regex) at(_coef) ///
    yline(0, lp(solid)) yline(-5000, lp(dot)) xline(2014.5, lpattern(dash)) ///
    xlab(2010(1)2019)  title("Control Diff-in-Diff With Same Bias")


**************************************************************************** 
* Unbiased triple differences
**************************************************************************** 

* Summarize and store the averages for control groups in macros
summarize avg_wage_asoe, meanonly
local after_control_exp = r(mean)

summarize avg_wage_bsoe, meanonly
local before_control_exp = r(mean)

summarize avg_wage_ason, meanonly
local after_control_nonexp = r(mean)

summarize avg_wage_bson, meanonly
local before_control_nonexp = r(mean)

* Calculate the DiD for married women and control group in experimental states
local DiD_married_exp = (`after_married_exp' - `before_married_exp')
local DiD_control_exp = (`after_control_exp' - `before_control_exp')

* Calculate the DiD for married women and control group in non-experimental states
local DiD_married_nonexp = (`after_married_nonexp' - `before_married_nonexp')
local DiD_control_nonexp = (`after_control_nonexp' - `before_control_nonexp')

* Calculate the Triple Difference estimate
local TripleDiff = (`DiD_married_exp' - `DiD_control_exp') - (`DiD_married_nonexp' - `DiD_control_nonexp')

* Display the result
display "Triple Difference Estimate: " `TripleDiff'


****** Triple diff regression

gen 	married_women = 0
replace married_women = 1 if worker==2

reg earnings after##experimental##married_women, cluster(state)

su delta if experimental==1 & worker==2 & after==1
di `r(mean)'

****** Triple diff event study

reg earnings i.year##experimental##married_women, cluster(state)


** A trick to plot the event study

gen 	treated3=0
replace treated3=1 if experimental==1 & married_women==1

reg earnings experimental##married_women year##experimental year##married_women treated3##ib2014.year, cluster(state)


coefplot, keep(1.treated3#*) omitted baselevels cirecast(rcap) ///
    rename(1.treated3#([0-9]+).year = \1, regex) at(_coef) ///
    yline(0, lp(solid)) yline(-5000, lp(dot)) xline(2014.5, lpattern(dash)) ///
    xlab(2010(1)2019)


********************************************************************************
* Plotting all of the event studies
********************************************************************************

* Define tempfiles
tempfile event1 event2 event3

********************************************************************************
* Biased DiD #1
********************************************************************************
* Run the regression for Biased DiD #1
reg earnings treated1##ib2014.year, cluster(state)

* Store the regression results in a matrix
matrix b = r(table)

* Extract coefficients and their confidence intervals
local coef00 = b[1, 23] 
local coef01 = b[1, 24]
local coef02 = b[1, 25]
local coef03 = b[1, 26]
local coef04 = b[1, 27]
local coef05 = b[1, 28]
local coef06 = b[1, 29]
local coef07 = b[1, 30]
local coef08 = b[1, 31]
local coef09 = b[1, 32]

local ll00 = b[5, 23]  // Lower limit of confidence interval for coef00
local ll01 = b[5, 24]  // Lower limit of confidence interval for coef01
local ll02 = b[5, 25]  // Lower limit of confidence interval for coef02
local ll03 = b[5, 26]  // Lower limit of confidence interval for coef03
local ll04 = b[5, 27]  // Lower limit of confidence interval for coef04
local ll05 = b[5, 28]  // Lower limit of confidence interval for coef05
local ll06 = b[5, 29]  // Lower limit of confidence interval for coef06
local ll07 = b[5, 30]  // Lower limit of confidence interval for coef07
local ll08 = b[5, 31]  // Lower limit of confidence interval for coef08
local ll09 = b[5, 32]  // Lower limit of confidence interval for coef09

local ul00 = b[6, 23]  // Upper limit of confidence interval for coef00
local ul01 = b[6, 24]  // Upper limit of confidence interval for coef01
local ul02 = b[6, 25]  // Upper limit of confidence interval for coef02
local ul03 = b[6, 26]  // Upper limit of confidence interval for coef03
local ul04 = b[6, 27]  // Upper limit of confidence interval for coef04
local ul05 = b[6, 28]  // Upper limit of confidence interval for coef05
local ul06 = b[6, 29]  // Upper limit of confidence interval for coef06
local ul07 = b[6, 30]  // Upper limit of confidence interval for coef07
local ul08 = b[6, 31]  // Upper limit of confidence interval for coef08
local ul09 = b[6, 32]  // Upper limit of confidence interval for coef09


preserve

clear
set obs 10
gen year = _n + 2009
gen coef = .
gen ll = .
gen ul = .

replace coef = `coef00' in 1
replace coef = `coef01' in 2
replace coef = `coef02' in 3
replace coef = `coef03' in 4
replace coef = `coef04' in 5
replace coef = `coef05' in 6
replace coef = `coef06' in 7
replace coef = `coef07' in 8
replace coef = `coef08' in 9
replace coef = `coef09' in 10


replace ul = `ul00' in 1
replace ul = `ul01' in 2
replace ul = `ul02' in 3
replace ul = `ul03' in 4
replace ul = `ul04' in 5
replace ul = `ul05' in 6
replace ul = `ul06' in 7
replace ul = `ul07' in 8
replace ul = `ul08' in 9
replace ul = `ul09' in 10

replace ll = `ll00' in 1
replace ll = `ll01' in 2
replace ll = `ll02' in 3
replace ll = `ll03' in 4
replace ll = `ll04' in 5
replace ll = `ll05' in 6
replace ll = `ll06' in 7
replace ll = `ll07' in 8
replace ll = `ll08' in 9
replace ll = `ll09' in 10

* Save this as a tempfile
tempfile event1
save `event1'

* Restore the original dataset
restore




********************************************************************************
* Biased Placebo DiD
********************************************************************************
* Run the regression for Biased DiD #2
reg earnings treated_placebo##ib2014.year, cluster(state)

* Store the regression results in a matrix
matrix b = r(table)

* Extract coefficients and their confidence intervals
local coef00 = b[1, 23] 
local coef01 = b[1, 24]
local coef02 = b[1, 25]
local coef03 = b[1, 26]
local coef04 = b[1, 27]
local coef05 = b[1, 28]
local coef06 = b[1, 29]
local coef07 = b[1, 30]
local coef08 = b[1, 31]
local coef09 = b[1, 32]

local ll00 = b[5, 23]  // Lower limit of confidence interval for coef00
local ll01 = b[5, 24]  // Lower limit of confidence interval for coef01
local ll02 = b[5, 25]  // Lower limit of confidence interval for coef02
local ll03 = b[5, 26]  // Lower limit of confidence interval for coef03
local ll04 = b[5, 27]  // Lower limit of confidence interval for coef04
local ll05 = b[5, 28]  // Lower limit of confidence interval for coef05
local ll06 = b[5, 29]  // Lower limit of confidence interval for coef06
local ll07 = b[5, 30]  // Lower limit of confidence interval for coef07
local ll08 = b[5, 31]  // Lower limit of confidence interval for coef08
local ll09 = b[5, 32]  // Lower limit of confidence interval for coef09

local ul00 = b[6, 23]  // Upper limit of confidence interval for coef00
local ul01 = b[6, 24]  // Upper limit of confidence interval for coef01
local ul02 = b[6, 25]  // Upper limit of confidence interval for coef02
local ul03 = b[6, 26]  // Upper limit of confidence interval for coef03
local ul04 = b[6, 27]  // Upper limit of confidence interval for coef04
local ul05 = b[6, 28]  // Upper limit of confidence interval for coef05
local ul06 = b[6, 29]  // Upper limit of confidence interval for coef06
local ul07 = b[6, 30]  // Upper limit of confidence interval for coef07
local ul08 = b[6, 31]  // Upper limit of confidence interval for coef08
local ul09 = b[6, 32]  // Upper limit of confidence interval for coef09


preserve

clear
set obs 10
gen year = _n + 2009
gen coef2 = .
gen ll2 = .
gen ul2 = .

replace coef2 = `coef00' in 1
replace coef2 = `coef01' in 2
replace coef2 = `coef02' in 3
replace coef2 = `coef03' in 4
replace coef2 = `coef04' in 5
replace coef2 = `coef05' in 6
replace coef2 = `coef06' in 7
replace coef2 = `coef07' in 8
replace coef2 = `coef08' in 9
replace coef2 = `coef09' in 10


replace ul2 = `ul00' in 1
replace ul2 = `ul01' in 2
replace ul2 = `ul02' in 3
replace ul2 = `ul03' in 4
replace ul2 = `ul04' in 5
replace ul2 = `ul05' in 6
replace ul2 = `ul06' in 7
replace ul2 = `ul07' in 8
replace ul2 = `ul08' in 9
replace ul2 = `ul09' in 10

replace ll2 = `ll00' in 1
replace ll2 = `ll01' in 2
replace ll2 = `ll02' in 3
replace ll2 = `ll03' in 4
replace ll2 = `ll04' in 5
replace ll2 = `ll05' in 6
replace ll2 = `ll06' in 7
replace ll2 = `ll07' in 8
replace ll2 = `ll08' in 9
replace ll2 = `ll09' in 10

* Save this as a tempfile
tempfile event2
save `event2'

* Restore the original dataset
restore



********************************************************************************
* Unbiased triple differences
********************************************************************************
* Run the regression for unbiased triple differences
reg earnings experimental##married_women year##experimental year##married_women treated3##ib2014.year, cluster(state)

* Store the regression results in a matrix
matrix b = r(table)


* Extract coefficients and their confidence intervals
local coef00 = b[1, 71] 
local coef01 = b[1, 72]
local coef02 = b[1, 73]
local coef03 = b[1, 74]
local coef04 = b[1, 75]
local coef05 = b[1, 76]
local coef06 = b[1, 77]
local coef07 = b[1, 78]
local coef08 = b[1, 79]
local coef09 = b[1, 80]

local ll00 = b[5, 71]  // Lower limit of confidence interval for coef00
local ll01 = b[5, 72]  // Lower limit of confidence interval for coef01
local ll02 = b[5, 73]  // Lower limit of confidence interval for coef02
local ll03 = b[5, 74]  // Lower limit of confidence interval for coef03
local ll04 = b[5, 75]  // Lower limit of confidence interval for coef04
local ll05 = b[5, 76]  // Lower limit of confidence interval for coef05
local ll06 = b[5, 77]  // Lower limit of confidence interval for coef06
local ll07 = b[5, 78]  // Lower limit of confidence interval for coef07
local ll08 = b[5, 79]  // Lower limit of confidence interval for coef08
local ll09 = b[5, 80]  // Lower limit of confidence interval for coef09

local ul00 = b[6, 71]  // Upper limit of confidence interval for coef00
local ul01 = b[6, 72]  // Upper limit of confidence interval for coef01
local ul02 = b[6, 73]  // Upper limit of confidence interval for coef02
local ul03 = b[6, 74]  // Upper limit of confidence interval for coef03
local ul04 = b[6, 75]  // Upper limit of confidence interval for coef04
local ul05 = b[6, 76]  // Upper limit of confidence interval for coef05
local ul06 = b[6, 77]  // Upper limit of confidence interval for coef06
local ul07 = b[6, 78]  // Upper limit of confidence interval for coef07
local ul08 = b[6, 79]  // Upper limit of confidence interval for coef08
local ul09 = b[6, 80]  // Upper limit of confidence interval for coef09

* Display some of the coefficients and confidence intervals to verify
display "Coefficient for coef00: " `coef00'
display "Lower limit for coef00: " `ll00'
display "Upper limit for coef00: " `ul00'



preserve

clear
set obs 10
gen year = _n + 2009
gen coef3 = .
gen ll3 = .
gen ul3 = .

replace coef3 = `coef00' in 1
replace coef3 = `coef01' in 2
replace coef3 = `coef02' in 3
replace coef3 = `coef03' in 4
replace coef3 = `coef04' in 5
replace coef3 = `coef05' in 6
replace coef3 = `coef06' in 7
replace coef3 = `coef07' in 8
replace coef3 = `coef08' in 9
replace coef3 = `coef09' in 10


replace ul3 = `ul00' in 1
replace ul3 = `ul01' in 2
replace ul3 = `ul02' in 3
replace ul3 = `ul03' in 4
replace ul3 = `ul04' in 5
replace ul3 = `ul05' in 6
replace ul3 = `ul06' in 7
replace ul3 = `ul07' in 8
replace ul3 = `ul08' in 9
replace ul3 = `ul09' in 10

replace ll3 = `ll00' in 1
replace ll3 = `ll01' in 2
replace ll3 = `ll02' in 3
replace ll3 = `ll03' in 4
replace ll3 = `ll04' in 5
replace ll3 = `ll05' in 6
replace ll3 = `ll06' in 7
replace ll3 = `ll07' in 8
replace ll3 = `ll08' in 9
replace ll3 = `ll09' in 10

* Save this as a tempfile
tempfile event3
save `event3'

* Restore the original dataset
restore

clear
use `event1'
merge using `event2'
drop _merge
merge using `event3'
drop _merge

* Event study
twoway (rcap ul ll year, sort lcolor(black) lwidth(thin) lpattern(solid)) ///
       (scatter coef year, sort mcolor(black) msize(small) msymbol(circle)) ///
       (rcap ul2 ll2 year, sort lcolor(red) lwidth(thin) lpattern(solid)) ///
       (scatter coef2 year, sort mcolor(red) msize(small) msymbol(triangle)) ///
       (rcap ul3 ll3 year, sort lcolor(green) lwidth(thin) lpattern(solid)) ///
       (scatter coef3 year, sort mcolor(green) msize(small) msymbol(square)), ///
       yline(0, lwidth(medium) lpattern(solid) lcolor(blue)) ///
       yline(-5000, lcolor(gs12) lpattern(dash) lwidth(thin)) ///
       text(-4000 2017 "ATT=-$5000", color(black) size(medium)) ///
       xtitle("Year") ///
       xline(2014.5, lwidth(medium) lpattern(dash) lcolor(blue)) ///
       xlabel(2010(1)2019) ///
       title("Two Biased DiDs vs. Unbiased Triple Diff") ///
       subtitle("Illustrating Parallel Bias") ///
       legend(order(2 "Biased DD" 4 "Biased Placebo DD" 6 "Unbiased DDD"))

	
capture log close
exit

