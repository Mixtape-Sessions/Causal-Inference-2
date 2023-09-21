*-> Install packages, if needed
  * ssc install reghdfe, replace
  * ssc install drdid, replace
  * ssc install csdid, replace
  * ssc install eventstudyinteract, replace
  * ssc install did_imputation, replace
  * ssc install event_plot, replace
  * ssc install did2s, replace
  * ssc install jwdid, replace
  * ssc install xtevent, replace

*-> Load data 
  use "https://github.com/scunning1975/mixtape/raw/master/castle.dta", clear

  cap drop treated
  gen treated = 0
  replace treated = 1 if year > effyear & effyear ~= .

  * First year is year 1
  cap drop rel_year
  gen rel_year = year - effyear + 1
  qui sum rel_year

  * Stata requires you to not have negative numbers in factor variable for regressions, so you have to shift
  cap drop rel_year_shifted
  local min_rel_year = `r(min)'
  gen rel_year_shifted = rel_year + -1 * `min_rel_year'

  * leads/lags of treatment, excluding -1
  forvalues k = 8(-1)0 {
    gen pre_`k' = rel_year == -`k'
  }
  forvalues k = 1/6 {
    gen post_`k' = rel_year == `k'
  }

  * Dummy for never-treated group
  cap drop control_group
  gen control_group = (effyear == .)

  * csdid and jwdid require group = 0 for never treated
  cap drop gvar
  gen gvar = cond(effyear == ., 0, effyear)

*-> TWFE
  * pre_0 is omitted
  reghdfe l_homicide pre_8-pre_1 post_1-post_6, absorb(sid year) vce(cluster sid)
  est store est_twfe
  event_plot est_twfe, default_look stub_lead(pre_#) stub_lag(post_#)

*-> Sun and Abraham
  eventstudyinteract l_homicide pre_8-pre_1 post_1-post_6, ///
    absorb(sid year) vce(cluster sid) ///
    cohort(effyear) control_cohort(control_group)
  event_plot e(b_iw)#e(V_iw), default_look stub_lead(pre_#) stub_lag(post_#)

  * Store for later
  matrix sa_b = e(b_iw)
  matrix sa_v = e(V_iw)

*-> Callaway and Sant'anna
  csdid l_homicide, ivar(sid) time(year) gvar(gvar)
  estat event, estore(est_cs)
  event_plot est_cs, default_look stub_lead(Tm#) stub_lag(Tp#) 

*-> BJS
  did_imputation l_homicide sid year effyear, allhorizons pretrends(8) minn(0)
  est store est_bjs
  event_plot est_bjs, default_look stub_lead(pre#) stub_lag(tau#) 

*-> Gardner 
  did2s l_homicide, first_stage(i.year i.sid) second_stage(pre_8-pre_0 post_1-post_6) treatment(treated) cluster(sid)
  est store est_gardner
  event_plot est_gardner, default_look stub_lead(pre_#) stub_lag(post_#) 

*-> Wooldridge
  jwdid l_homicide, ivar(sid) tvar(year) gvar(gvar) never
  estat event, post
  matrix w_b = e(b)
  matrix w_v = e(V)
  * clean-up names for event_plot
  matrix colnames w_b = pre_8 pre_7 pre_6 pre_5 pre_4 pre_3 pre_2 pre_1 pre_0  post_1 post_2 post_3 post_4 post_5 post_6
  matrix colnames w_v = pre_8 pre_7 pre_6 pre_5 pre_4 pre_3 pre_2 pre_1 pre_0  post_1 post_2 post_3 post_4 post_5 post_6
  matrix rownames w_v = pre_8 pre_7 pre_6 pre_5 pre_4 pre_3 pre_2 pre_1 pre_0  post_1 post_2 post_3 post_4 post_5 post_6

  event_plot w_b#w_v, default_look stub_lead(pre_#) stub_lag(post_#)

*-> All together

event_plot est_twfe est_bjs est_gardner est_cs sa_b#sa_v w_b#w_v, ///
  stub_lead(pre_# pre# pre_# Tm# pre_# pre_#) ///
	stub_lag(post_# tau# post_# Tp# post_# post_#) /// 
  default_look plottype(scatter) ciplottype(rcap) ///
  together perturb(-0.325(0.13)0.325) noautolegend /// 
	graph_opt( ///
		xtitle("Periods since the event") ytitle("Average causal effect") ///
    xline(-0.5, lcolor(gs8) lpattern(dash)) yline(0, lcolor(gs8)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal)) ///
    legend( ///
      order(1 "OLS" 3 "Borusyak et al." 5 "Gardner" 7 "Callaway-Sant'Anna" 9 "Sun and Abraham" 11 "Wooldridge") ///
    ) ///
	) ///
	lag_opt1(msymbol(Sh) color(black)) lag_ci_opt1(color(black)) ///
	lag_opt2(msymbol(+) color(cranberry)) lag_ci_opt2(color(cranberry)) ///
	lag_opt3(msymbol(D) color(navy)) lag_ci_opt3(color(navy)) ///
	lag_opt4(msymbol(T) color(forest_green)) lag_ci_opt4(color(forest_green)) ///
	lag_opt5(msymbol(S) color(dkorange)) lag_ci_opt5(color(dkorange)) ///
	lag_opt6(msymbol(O) color(purple)) lag_ci_opt6(color(purple)) 

