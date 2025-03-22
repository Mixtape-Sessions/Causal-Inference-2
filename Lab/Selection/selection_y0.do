* selection_y0.do: selection into treatment based on Y(0) with constant Y0

  * Set up
  clear all
  set seed 2

  * First create the states
  quietly set obs 40
  gen state = _n

  * Generate 1000 workers. These are in each state. So 25 per state.
  expand 25
  bysort state: gen unit_fe=runiform(1,1000)
  label variable unit_fe "Unique worker fixed effect per state"
  egen id = group(state unit_fe)
  
  * Generate pontential outcomes
  gen y0 = unit_fe + rnormal(0,10)

  * Determine treatment status in 1990
  su y0, detail
  gen treat = 0 
  replace treat = 1 if y0 < `r(p25)'
  
  * Generate the years
  expand 2
  sort state
  bysort state unit_fe: gen year = _n
  gen n = year
  replace year = 1990 if year == 1
  replace year = 1991 if year == 2

  * Post-treatment
  gen post = 0  
  replace post = 1 if year == 1991
  
  replace y0 = y0 + 1000 if year == 1991

  gen y1 = y0
  replace y1 = y0 + 7500 if year==1991

  * Treatment effect
  gen delta = y1 - y0
  label var delta "Treatment effect for unit i (unobservable in the real world)"
    
  sum delta if post == 1, meanonly
  gen ate = `r(mean)' // $7,500
  sum delta if treat==1 & post==1, meanonly
  gen att = `r(mean)' // $7,500

  * Generate observed outcome based on treatment assignment
  gen         earnings = y0
  qui replace earnings = y1 if post == 1 & treat == 1

  * Illustrate parallel trends assumption
  su y0 if treat==1 & post==0
  gen ey0_10 = `r(mean)'
  su y0 if treat==1 & post==1
  gen ey0_11 = `r(mean)'
  su y0 if treat==0 & post==0
  gen ey0_00 = `r(mean)'
  su y0 if treat==0 & post==1
  gen ey0_01 = `r(mean)'
  
  gen parallel_trends = (ey0_11 - ey0_10) - (ey0_01 - ey0_00) 
  
  * Diff-in-diff
  su earnings if treat==1 & post==0
  gen ey_10 = `r(mean)'
  su earnings if treat==1 & post==1
  gen ey_11 = `r(mean)'
  su earnings if treat==0 & post==0
  gen ey_00 = `r(mean)'
  su earnings if treat==0 & post==1
  gen ey_01 = `r(mean)'
  
  gen did = (ey_11 - ey_10) - (ey_01 - ey_00) 
  
  reg earnings post##treat, robust
  
  su did att
  
  reg earnings post##treat, robust
  
  
  su parallel_trends
  