* NOT WORKING

use https://github.com/scunning1975/mixtape/raw/master/baker.dta, clear
* ssc install csdid, replace
* ssc install drdid, replace

csdid  y, ivar(id) time(year) gvar(treat_date) ipw asinr 
csdid_estat simple 
