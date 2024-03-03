********************************************************************************
* name: simple_eventstudy.do
* author: scott cunningham (baylor)
* description: simulation for diff-in-diff
* last updated: january 2, 2024
********************************************************************************

clear
capture log close
set seed 20200403

* States, Groups, and Time Setup
set obs 40
gen state = _n

* Generate treatment groups
gen experimental = 0
replace experimental = 1 in 1/20

* 50 cities per state
expand 50
bysort state: gen city_no = _n
egen city = group(city_no state)
drop city_no

* Time, 10 years
expand 10
sort state
bysort state city: gen year = _n

* Setting years
foreach y of numlist 1/10 {
    local year 2010 + `y' - 1
    replace year = `year' if year == `y'
}

* Define the after period (post-2015)
gen after = year >= 2015

* Baseline earnings in 2010 with different values for experimental and non-experimental states
gen 	baseline = 40000 // Married women

* Adjust baseline for experimental states
replace baseline = 2 * baseline if experimental == 1

* Trend
gen year_diff = year - 2010

* Annual wage growth for Y(0) incorporating state and group trends
gen y0 = baseline + year_diff*1000 

* Adding random error to Y(0)
gen error = rnormal(0, 2000)
replace y0 = y0 + error

* Define Y(1) with an ATT of -$5000 for married women in experimental states post-2015
gen 	y1 = y0
replace y1 = y0 - 1000 if experimental == 1 & after == 1

* Treatment effect
gen delta = y1-y0
su delta if after==1 & experimental ==1
gen att = `r(mean)'
su att

* Treatment indicator
gen 	treat = 0
replace treat = 1 if experimental == 1 & after==1

* Final earnings using switching equation
gen earnings = treat * y1 + (1 - treat) * y0

* The easy way without the connectedness. 

reg earnings experimental##ib2014.year, cluster(state)

coefplot, keep(1.experimental#*) omitted baselevels cirecast(rcap) ///
    rename(1.experimental#([0-9]+).year = \1, regex) at(_coef) ///
    yline(0, lp(solid)) xline(2014, lpattern(dash)) yline(-1000, lp(dash)) ///
    xlab(2010(1)2019) ///
    title("Difference-in-differences regression") ///
    subtitle("Disconnected Event study graphic")
	
* Not make with the connectedness.

reg earnings experimental##ib2014.year, cluster(state)

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



* Create the picture
set scheme s2color
twoway (rcap ul ll year, sort lcolor(gray) lwidth(thin) lpattern(solid)) ///
       (scatter coef year, sort mcolor(black) msize(medium) msymbol(circle)) ///
       , yline(0, lwidth(medium) lpattern(solid) lcolor(black)) ///
       xline(2014, lwidth(medium) lpattern(dash) lcolor(black)) ///
       xtitle("Years relative to policy/event change") ///
       ytitle("Estimated effect on earnings") ///
       title("Difference-in-differences regression") ///
       subtitle("Event study graphic #1") ///
       legend(order(2 "Estimated coefficient" 1 "95% Confidence interval"))
       xlabel(2009(1)2019, valuelabel angle(45)) ///
       ylabel(, nogrid)
	
	
#delimit ;	
twoway (scatter coef ul ll year , 
        lpattern(solid dash dash dot dot solid solid) 
        lcolor(gray gray gray red blue) 
        lwidth(thick medium medium medium medium thick thick)
        msymbol(i i i i i i i i i i) msize(medlarge medlarge)
        mcolor(gray black gray gray red blue) 
        c(l l l l l l l l l l ) 
        cmissing(n n n n n n n n n n n ) 
       xline(2014, lwidth(medium) lpattern(dash) lcolor(black)) ///
        yline(0, lcolor(black)) 
       xlabel(2010(1)2019, valuelabel angle(45)) ///
       ylabel(, nogrid)
        xsize(7.5) ysize(5.5)           
       legend(order(2 "Estimated coefficient" 1 "95% Confidence interval"))
       title("Difference-in-differences regression") ///
       subtitle("Event study graphic #1") ///
       xtitle("Years relative to policy/event change") ///
       ytitle("Estimated effect on earnings") ///
        graphregion(fcolor(white) color(white) icolor(white) margin(zero)));

	   