* name: equivalence.do
* author: scott cunningham
* description: OLS and Manual are the same

clear 
capture log close

use https://github.com/scunning1975/mixtape/raw/master/castle.dta, clear
xtset sid year

* Keep only the 2006 treated states and the never-treated states
drop if effyear==2005 | effyear==2007 | effyear==2008 | effyear==2009

* Generate regression variables
drop 	post
gen 	post = 0
replace post = 1 if year>=2006

gen 	treat = 0
replace treat = 1 if effyear==2006

* OLS regression model 
reg l_homicide post##treat, cluster(state)

* Include state and year fixed effects
reg l_homicide i.sid i.year post##treat, cluster(state)


* Four averages and three subtractions
egen y11 = mean(l_homicide) if post==1 & treat==1
egen y10 = mean(l_homicide) if post==0 & treat==1
egen ey11 = max(y11)
egen ey10 = max(y10)

egen y01 = mean(l_homicide) if post==1 & treat==0
egen y00 = mean(l_homicide) if post==0 & treat==0
egen ey01 = max(y01)
egen ey00 = max(y00)

gen did = (ey11 - ey10) - (ey01 - ey00)
sum did
