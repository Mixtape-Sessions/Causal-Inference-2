********************************************************************************
* name: cheng_hoekstra.do
* description: Various Difference-in-Differences Estimators with Cheng and 
* Hoekstra dataset.
********************************************************************************

  * To install packages, run:
  * ssc install reghdfe
  * ssc install csdid
  * net install github, from("https://haghish.github.io/github/")
  * github install kylebutts/did2s_stata
  * github install lsun20/eventstudyinteract

  use "https://github.com/scunning1975/mixtape/raw/master/castle.dta", clear

  * for csdid, effyear needs to be 0 for untreated group
  replace effyear = 0 if effyear == .
  
  gen rel_year = year - effyear
  replace rel_year = -1 if effyear == 0

  * can't have negative years for factor variable
  gen rel_year_shifted = rel_year + 9

  gen treat = (year >= effyear)



* 1. TWFE Event-study regression -----------------------------------------------

  * 8 is relative-year -1, so we want that to be the reference
  reghdfe l_homicide ib8.rel_year_shifted, absorb(sid year) cluster(sid)

* 2. Callaway and Santa'Anna ---------------------------------------------------

  csdid l_homicide, ivar(sid) time(year) gvar(effyear) agg(event)

* 3. Imputation Estimator ------------------------------------------------------

  did2s l_homicide, first_stage(i.sid i.year) second_stage(ib8.rel_year_shifted) treatment(treat) cluster(sid)

* 4. Sun and Abraham -----------------------------------------------------------

  * generate relative time indicators
  sum rel_year
  * Leads, drop -1
  forvalues k = `r(min)'(1)-2 {
    local k = -`k'
    gen rel_year_lag`k' = rel_year == -`k'
  }
  * Lags
  forvalues k = 0(1)`r(max)' {
    gen rel_year_lead`k' = rel_year == `k'
  }
  
  gen never_treated = effyear == 0

  * Drop rel_year = -1
  eventstudyinteract l_homicide rel_year_lag* rel_year_lead*, cohort(effyear) control_cohort(never_treated) absorb(sid year) vce(cluster sid)


* 5. Stacking Estimator --------------------------------------------------------

  * Step 1: Loop through by using only a group and the never treated
  * and assigning it a unique stack_id
  * We are aiming for a panel with event_time -5 to 4

    forvalues i = 2005(1)2009 {
      preserve
      gen stack_id = `i'

      * Keep if effyear == `i', never-treated, or untreated observations 
      keep if effyear == `i' | effyear == 0 | year < effyear

      * keep rel_year -5 through 4
      keep if rel_year >= -5 & rel_year <= 4

      save ./stack_`i', replace
      restore
    }

  * Step 2: Now append the datasets into one single stacked dataset.

    use ./stack_2005, clear
    rm ./stack_2005.dta
    forvalues i = 2006(1)2009 {
      append using ./stack_`i'.dta
      * Clean up
      rm ./stack_`i'.dta
    }

  * Step 3: Estimation with dataset interaction fixed effects and 
  * relative event time fixed effects, clustering on unique stateXdataset
  * identifiers

    * relative year = -1 is rel_year 8
    egen sid_x_stack_id = group(sid stack_id)
    egen year_x_stack_id = group(year stack_id)
    reghdfe l_homicide ib8.rel_year_shift, absorb(sid_x_stack_id year_x_stack_id) cluster(sid_x_stack_id)


