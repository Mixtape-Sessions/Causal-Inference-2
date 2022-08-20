********************************************************************************
* name: lalonde-did-stata.do
* description: simple estimation of ATT using Lalonde 1986 data with DW 2003 sample
********************************************************************************
* ssc install drdid, replace
clear


* 1. Experimental data
use "https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_exp_panel.dta", clear 

  * Difference-in-means
  reg re i.treat if year == 78, r

  * Difference-in-differences
  reghdfe re i.treat, absorb(id year) vce(robust)


* 2. CPS data
use "https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_nonexp_panel.dta", clear 

  * Difference-in-means
  reg re i.treat if year == 78, r

  * Initial Difference-in-difference
  reghdfe re i.treat, absorb(id year) vce(robust)

  * Doubly-robust DID
  drdid re age agesq agecube educ educsq marr nodegree black hisp re74 u74 if year == 75 | year == 78, time(year) ivar(id) tr(ever_treated)
  