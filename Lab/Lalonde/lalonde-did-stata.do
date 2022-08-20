********************************************************************************
* name: lalonde-did-stata.do
* description: simple estimation of ATT using Lalonde 1986 data with DW 2003 sample
********************************************************************************
clear
capture log close

* Experimental controls
use "https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_exp_panel.dta", clear

xi: reg re treat ever_treated age* educ-nodegree i.year, robust

* Non-experimental controls
use "https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Lalonde/lalonde_nonexp_panel.dta", clear

xi: reg re treat ever_treated age* educ-nodegree i.year, robust

