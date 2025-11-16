* Let's first install drdid
ssc install drdid, all replace

* Now let's install csdid
ssc install csdid, all replace

* Once these are installed, let's run some example files using the subset of data from Callaway and Sant'Anna (2020) that is available on Github
use https://friosavila.github.io/playingwithstata/drdid/mpdta.dta, clear


* Estimation of all ATTGT's using uncondition DiD with never-treated as comparison group
* Standard errors computed using analytical results
csdid lemp , ivar(countyreal) time(year) gvar(first_treat)
* Plot the event-study for Group 2004
csdid_plot, group(2004) title("Group 2004")

* Estimation of all ATTGT's using uncondition DiD with not-yet-treated as comparison group
* standard errors using wild-bootstrap
csdid lemp , ivar(countyreal) time(year) gvar(first_treat) notyet wboot rseed(08052021)

* Estimation of all ATT(g,t)'s using Doubly Robust IPW (DRIPW) estimation method with never-treated as comparison group
* Standard errors computed using analytical results
csdid lemp lpop , ivar(countyreal) time(year) gvar(first_treat) method(dripw)

* Estimation of all ATT(g,t)'s using IPW estimation method with not-yet-treated as comparison group
* standard errors using wild-bootstrap
csdid lemp lpop , ivar(countyreal) time(year) gvar(first_treat) notyet method(ipw)  wboot rseed(08052021)
csdid_plot, group(2004) title("Group 2004")


* Illustrate Post-estimation procedures to get summary of causal effects
csdid lemp lpop , ivar(countyreal) time(year) gvar(first_treat) method(dripw)
estat all
estat event
csdid_plot,  title("Event-Study")
