********************************************************************************
* baker_sa.do
* author: Daniel H and scott cunningham
* implement the Sun and Abraham estimator and plot it
********************************************************************************
clear
capture log close
use https://raw.github.com/Mixtape-Sessions/Causal-Inference-2/master/Lab/Baker/baker.dta, clear

gen 	lastcohort=0
replace lastcohort if treat_date==2004

* Event study with heterogeneity, dropping two leads, estimated with TWFE
areg y i.year dd1 - dd20 dd22-dd23 dd25-dd48, a(id) cluster(state)

* Event study with heterogeneity estimated by Sun and Abraham (2020)
eventstudyinteract y dd2 - dd20 dd22-dd23 dd25-dd48  if year < 2004 ,  cohort(treat_date) control_cohort(lastcohort) absorb(i.id i.year) vce(cluster state)

/* Get event_plot working
event_plot e(b_iw)#e(V_iw), default_look graph_opt(xtitle("Periods since the event") ytitle("Average causal effect") xlabel(-14(1)5) ///
	title("Sun and Abraham (2020)"))  together
*/

