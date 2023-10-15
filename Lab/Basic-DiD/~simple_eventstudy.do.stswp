* name: simple_eventstudy.do
* author: scott cunningham
* description: illustrating an event study with Stata manually

clear 
capture log close

use https://github.com/scunning1975/mixtape/raw/master/castle.dta, clear

* Prepare the dataset
xtset sid year

drop if effyear==2005 | effyear==2007 | effyear==2008 | effyear==2009

drop post
gen 	post = 0
replace post = 1 if year>=2006

gen 	treat=0
replace treat=1 if effyear==2006

* Event study: interacts the treat dummy with calendar year but drops a single pre-treatment year. I will choose 2005 as my baseline. Every regression coefficient, both the post-treatment estimates of the ATT by year and the pre-treatment coefficients also by year will be calculated as DID coefficients using 2005 as the "pre" period. 


tabulate year, gen(pre)
tabulate year, gen(post)

gen 	treated=0
replace treated=1 if effyear==2006 & year>=2006

reg l_homicide treat##ib2005.year, cluster(state)

matrix b = r(table)

local  coef00 = b[1, 25]
local  coef01 = b[1, 26]
local  coef02 = b[1, 27]
local  coef03 = b[1, 28]
local  coef04 = b[1, 29]
local  coef05 = b[1, 30]
local  coef06 = b[1, 31]
local  coef07 = b[1, 32]
local  coef08 = b[1, 33]
local  coef09 = b[1, 34]
local  coef10 = b[1, 35]

local  ll00 = b[5, 25]
local  ll01 = b[5, 26]
local  ll02 = b[5, 27]
local  ll03 = b[5, 28]
local  ll04 = b[5, 29]
local  ll05 = b[5, 30]
local  ll06 = b[5, 31]
local  ll07 = b[5, 32]
local  ll08 = b[5, 33]
local  ll09 = b[5, 34]
local  ll10 = b[5, 35]

local  ul00 = b[6, 25]
local  ul01 = b[6, 26]
local  ul02 = b[6, 27]
local  ul03 = b[6, 28]
local  ul04 = b[6, 29]
local  ul05 = b[6, 30]
local  ul06 = b[6, 31]
local  ul07 = b[6, 32]
local  ul08 = b[6, 33]
local  ul09 = b[6, 34]
local  ul10 = b[6, 35]

clear
set obs 11
gen year = _n + 1999
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
replace coef = `coef10' in 11


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
replace ul = `ul10' in 11

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
replace ll = `ll10' in 11


twoway (rcap ul ll year, sort lcolor(black) lwidth(medium) lpattern(solid)) (scatter coef year, sort mcolor(black) msize(6-pt) msymbol(circle)), yline(0, lwidth(medthin) lpattern(solid) lcolor(blue)) xtitle(`"Year"') xline(2005.5, lwidth(medium) lpattern(dash) lcolor(blue)) xlabel(2000(1)2010) title(`"Ln(Homicides)"') legend(off)

****

* name: simple_eventstudy.do
* author: scott cunningham
* description: illustrating an event study with Stata using Ben Jann's coefplot


clear 
capture log close
ssc install coefplot, replace

use https://github.com/scunning1975/mixtape/raw/master/castle.dta, clear

* Prepare the dataset
xtset sid year

drop if effyear==2005 | effyear==2007 | effyear==2008 | effyear==2009

drop post
gen 	post = 0
replace post = 1 if year>=2006

gen 	treat=0
replace treat=1 if effyear==2006

* Event study
tabulate year, gen(pre)
tabulate year, gen(post)

gen 	treated=0
replace treated=1 if effyear==2006 & year>=2006

reg l_homicide treat##ib2005.year, cluster(state)

* addon by Ben Jann, 21may2023

coefplot, keep(1.treat#*) omitted baselevels cirecast(rcap) ///
    rename(1.treat#([0-9]+).year = \1, regex) at(_coef) ///
    yline(0, lp(solid)) xline(2005.5, lpattern(dash)) ///
    xlab(2000(1)2010)
