* name: equivalence.do
* author: scott cunningham
* description: OLS and Manual are the same

clear 
capture log close

use https://github.com/scunning1975/mixtape/raw/master/castle.dta, clear
xtset sid year

drop if effyear==2005 | effyear==2007 | effyear==2008 | effyear==2009

drop 	post
gen 	post = 0
replace post = 1 if year>=2006

gen 	treat = 0
replace treat = 1 if effyear==2006

keep if year==2006 | year==2005


* Manual unweighted 2x2
summarize l_homicide if treat==1 & post==1
gen y11 = `r(mean)'

summarize l_homicide if treat==1 & post==0
gen y10 = `r(mean)'


summarize l_homicide if treat==0 & post==1
gen y01 = `r(mean)'


summarize l_homicide if treat==0 & post==0
gen y00 = `r(mean)'

gen did = (y11 - y10) - (y01 - y00)
sum did


* Regression Example 1: OLS regression with interactions (interactioned OLS)
reg l_homicide post##treat, cluster(sid)

* Regression Example 2: Twoway fixed effects (state and year fixed effects)
xtreg l_homicide c.treat#c.post i.year, fe vce(cluster sid)

* Regression Example 3: Regress "long difference" onto treatment dummy
preserve
    keep sid year l_homicide treat
    reshape wide l_homicide, i(sid) j(year)
    gen diff = l_homicide2006 - l_homicide2005
    reg diff treat, vce(cluster sid)
restore

* Now calculate the same thing using population weights as below


*Manual unweighted 2x2
summarize l_homicide if treat==1 & post==1 [aw=popwt]
gen wy11 = `r(mean)'

summarize l_homicide if treat==1 & post==0 [aw=popwt]
gen wy10 = `r(mean)'


summarize l_homicide if treat==0 & post==1 [aw=popwt]
gen wy01 = `r(mean)'


summarize l_homicide if treat==0 & post==0 [aw=popwt]
gen wy00 = `r(mean)'

gen wdid = (wy11 - wy10) - (wy01 - wy00)
sum wdid



* Regression Example 1: OLS regression with interactions and population weights
reg l_homicide post##treat [aweight=popwt], cluster(sid) 

* Regression Example 2: Twoway fixed effects (state and year fixed effects)
xtreg l_homicide c.treat#c.post i.year [aw=popwt], fe vce(cluster sid)

* Regression Example 3: Regress "long difference" onto treatment dummy
preserve
    keep sid year l_homicide popwt treat blackm_15_24 whitem_15_24 blackm_25_44 whitem_25_44
    reshape wide l_homicide popwt blackm_15_24 whitem_15_24 blackm_25_44 whitem_25_44 , i(sid) j(year)
    gen diff = l_homicide2006 - l_homicide2005
    reg diff treat [aw=popwt2005], vce(cluster sid)
restore

capture log close
exit
