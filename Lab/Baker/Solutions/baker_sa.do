*******************************************************************************
* baker_sa.do
* author: Daniel H and scott cunningham
* implement the Sun and Abraham estimator and plot it
********************************************************************************
clear
capture log close
use https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Baker/baker.dta, clear

gen 	lastcohort = 0
replace lastcohort = 1 if treat_date==2004

* Event study with heterogeneity, dropping two leads, TWFE estimation (biased)
areg y i.year dd1 - dd20 dd22-dd23 dd25-dd48, a(id) robust 

coefplot, keep(dd1 dd2 dd3 dd4 dd5 dd6 dd7 dd8 dd9 dd10 dd11 dd12 dd13 dd14 dd15 dd16 dd17 dd18 dd19 dd20 dd22 dd23 dd25 dd26 dd27 dd28 dd29 dd30 dd31 dd32 dd33 dd34 dd35 dd36 dd37 dd38 dd39 dd40 dd41 dd42) xlabel(, angle(vertical)) yline(0) vertical msymbol(D) mfcolor(white) ciopts(lwidth(*3) lcolor(*.6)) grid(between) mlabel format(%9.3f) mlabposition(12) mlabgap(*2) title(Baker simulation) 

* Event study with heterogeneity estimated by Sun and Abraham (2020)
eventstudyinteract y dd1 - dd20 dd22-dd23 dd25-dd48  if year < 2004 ,  cohort(treat_date) control_cohort(lastcohort) absorb(i.id i.year) vce(cluster state)

/* Get event_plot working
event_plot e(b_iw)#e(V_iw), default_look graph_opt(xtitle("Periods since the event ") ytitle("Average causal effect") xlabel(-14(1)5) ///
	title("Sun and Abraham (2020)"))  together
*/

csdid y ,  ivar(id)  time(year) gvar(treat_date) method(ipw) notyet
