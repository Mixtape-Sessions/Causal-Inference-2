* baker_cs.do

use https://github.com/scunning1975/mixtape/raw/master/baker.dta, clear
ssc install csdid, replace
ssc install drdid, replace

csdid y, ivar(id) time(year) gvar(treat_date) ipw long2
csdid_estat simple 
csdid_estat group
csdid_estat calendar
csdid_estat event

estat event
csdid_plot
