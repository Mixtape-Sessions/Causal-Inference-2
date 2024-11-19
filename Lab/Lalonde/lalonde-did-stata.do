********************************************************************************
* name: lalonde-did-stata.do
********************************************************************************
* ssc install drdid, replace
clear

* 1. Experimental data
use "https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_exp_panel.dta", clear 

* Difference-in-means - Averages
summarize re if ever_treated==1 & year==78 // $6349.144
summarize re if ever_treated==0 & year==78 // $4554.801

display 6349.144 - 4554.801

* Difference-in-means - OLS
reg re i.ever_treated if year == 78, robust

* Difference-in-differences - Averages
egen y00=mean(re) if ever_treated==0 & year==75
egen y01=mean(re) if ever_treated==0 & year==78
egen y10=mean(re) if ever_treated==1 & year==75
egen y11=mean(re) if ever_treated==1 & year==78

egen ey00 = max(y00)
egen ey01 = max(y01)
egen ey10 = max(y10)
egen ey11 = max(y11)

gen did = (ey11 - ey10) - (ey01 - ey00)
sum did
drop y00-did

* Difference-in-differences
gen post 		= 0 if year==75
replace post 	= 1 if year==78
reg re ever_treated##post, robust

* Event study and pre-trends using manually calculated averages
egen y00=mean(re) if ever_treated==0 & year==75
egen y01=mean(re) if ever_treated==0 & year==74
egen y10=mean(re) if ever_treated==1 & year==75
egen y11=mean(re) if ever_treated==1 & year==74

egen ey00 = max(y00)
egen ey01 = max(y01)
egen ey10 = max(y10)
egen ey11 = max(y11)

gen did = (ey11 - ey10) - (ey01 - ey00)
sum did
drop y00-did post

* Event study and pre-trends using OLS 
gen pre = 0
replace pre=1 if year==74
gen post = 0 
replace post = 1 if year==78

reg re ever_treated##post ever_treated##pre, robust

* 2. CPS data
use "https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_nonexp_panel.dta", clear 

  * Difference-in-means - Averages
  summarize re if ever_treated==1 & year==78 // $6349.144
  summarize re if ever_treated==0 & year==78 // $14,846.66
  
  display 6349.144 - 14846.66 // -$8,497.516

  * Difference-in-means - OLS
  reg re i.ever_treated if year == 78, robust
  
  * Difference-in-differences - Averages
  egen y00=mean(re) if ever_treated==0 & year==75
  egen y01=mean(re) if ever_treated==0 & year==78
  egen y10=mean(re) if ever_treated==1 & year==75
  egen y11=mean(re) if ever_treated==1 & year==78
  
  egen ey00 = max(y00)
  egen ey01 = max(y01)
  egen ey10 = max(y10)
  egen ey11 = max(y11)
  
  gen did = (ey11 - ey10) - (ey01 - ey00)
  sum did
  drop y00-did
  
  * Difference-in-differences
  gen post 		= 0 if year==75
  replace post 	= 1 if year==78
  reg re ever_treated##post, robust
  
  * Event study and pre-trends using manually calculated averages
  egen y00=mean(re) if ever_treated==0 & year==75
  egen y01=mean(re) if ever_treated==0 & year==74
  egen y10=mean(re) if ever_treated==1 & year==75
  egen y11=mean(re) if ever_treated==1 & year==74
  
  egen ey00 = max(y00)
  egen ey01 = max(y01)
  egen ey10 = max(y10)
  egen ey11 = max(y11)
  
  gen did = (ey11 - ey10) - (ey01 - ey00)
  sum did
  drop y00-did post
  
  * Event study and pre-trends using OLS 
  gen pre = 0
  replace pre=1 if year==74
  gen post = 0 
  replace post = 1 if year==78
  
  reg re ever_treated##post ever_treated##pre, robust

  * Difference-in-differeces - OLS with covariates (age, agesq, agecube, educ, educsq, marr, nodegree, black, hisp)
  
  reg re ever_treated##post age agesq agecube educ educsq marr nodegree black hisp, robust

  * Doubly-robust DID
  drdid re age agesq agecube educ educsq marr nodegree black hisp re74 u74 if year == 75 | year == 78, time(year) ivar(id) tr(ever_treated) all
  