******************************************************************
* name: castle.do
******************************************************************

clear all
capture log close

* Load files
* net install grc1leg, from(http://www.stata.com/users/vwiggins) replace
* net install gr0075, from(http://www.stata-journal.com/software/sj18-4) replace
* ssc install labutil, replace
* ssc install sencode, replace
 
* cap ado uninstall panelview //in-case already installed
* net install panelview, all replace from("https://yiqingxu.org/packages/panelview_stata")

use "https://github.com/scunning1975/mixtape/raw/master/castle.dta", clear

* Check with TWFE
areg l_homicide post i.year, a(sid) robust cluster(sid)

replace effyear=0 if effyear==. // remember to make "never treated" treatment dates equal to 0.
csdid l_homicide, i(sid) t(year) gvar(effyear) ipw long2 

csdid_estat simple

csdid l_homicide police whitem_25_44 poverty, i(sid) t(year) gvar(effyear) ipw long2 notyet

csdid_estat simple
