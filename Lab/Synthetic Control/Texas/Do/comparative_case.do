***********************************************************************************************
* The following code loops through and runs a set of permutations for each state/year interaction
* then stores it in its own table which we use later to construct event study graphs in Figure 2 
* (see Figure 2,7,8.do).  More specifically, we estimate each state-year interaction, and produce
* a distribution in a table (15 tables total).  Then we manually inputted those 5th, 95th and true
* coefficient values into an excel spreadsheet called eclplot3.xlsx.  In the Figures 2,7,8.do
* file, starting at line 23, these values are imported into Stata, where we use the -eclplot-
* command to create coefficient plots with 5th and 95th percentile whiskerplots.  Note that the
* 5th and 95th percentile plots refer to the empirical distribution itself.
***********************************************************************************************
clear all
clear matrix
clear mata
set more off, perm
capture log close

if "`c(username)'" == "scott_cunningham"	cd "/Users/scott_cunningham/Dropbox/Workshop/Texas/Do"
else										cd "C:\Users\skang\Dropbox\drug_courts\do"
do folderDeclare.do 

log using ./fig2_eventstudy.log, replace text

*==============================================================================*
* Prison Measures (only right for total incarceration)
*==============================================================================*
  note: Missing Value States:													///
		Total Incarceration Rate: DC
		
* a) Estimating the event study
  foreach i of numlist 1/7 9/51 {												// Loop over states
  foreach x in totalprison lntotalprison lnjurisdiction	lnjurisdiction_rate {	// Loop over each variable
		
	* Prepare the data set
	qui use if year >= 1985 & year <= 2003 using $data/mainfile.dta, replace
	ren (lntotal_prison_rate total_prison_rate lntotal_jurisdiction lntotal_jurisdiction_rate) (lntotalprison totalprison lnjurisdiction lnjurisdiction_rate)
				
	forvalues t = 1985/2003 {													// Creating treatment variables
	qui gen treat`t' = dummy_`t' * sdumm`i'
	}
	drop treat1993																// Excluding the year of the treatment as the comparison year
		
	* Regressions.
	* 1. time-variant controls, no state quadratic trends, no linear state trends.
		qui reghdfe `x' treat1985-treat2003 white-lunch, absorb(statefip year)			
		
		* Store the estimates
		qui gen treat_b = .
		qui gen treat_N = .
		
		foreach t of numlist 1985(1)1992 1994(1)2003 {
		qui replace treat_b=_b[treat`t'] if year == `t'
		qui replace treat_N=e(N) if year == `t'
		}
		
		* Keep one record per state
		qui keep year treat_b treat_N
		qui bysort year: keep if _n == 1
		qui gen state = `i'

		qui save $tempfiles/dd_placebo_`x'`i'.dta, replace
  }		
 	di "--> END (state=`i' of 51) time: "c(current_time)
  }

  
* b) Constructing the event study
  foreach x in totalprison lntotalprison lnjurisdiction lnjurisdiction_rate {
  
	* Append all placebo estimates
	use $tempfiles/dd_placebo_`x'1.dta, replace
	
	foreach i of numlist 2/7 9/51 {				
	qui append using $tempfiles/dd_placebo_`x'`i'.dta
   	}
   		
	* Identify the treated unit(s)
	qui gen tx = 0 
	replace tx = 1 if (state==44)
	label variable tx "Texas"
		
	* Get the 5th and 95th percentiles
	qui gen p05 = .
	qui gen p95 = .
	
	foreach t of numlist 1985(1)1992 1994(1)2003 {
	qui summ treat_b if year == `t' & tx != 1, de
	qui replace p05 = r(p5) if year == `t'
	qui replace p95 = r(p95) if year == `t'
	}
	
	save $inference/placebo/dd_placebo_`x'.dta, replace

	* Plot the event study
	#delimit ;
	twoway  (scatter treat_b year if tx!=1, msymbol(circle_hollow) mlcolor(black*0.75) mlwidth(vvvthin) jitter(0)) 
			(connected treat_b year if tx==1, msymbol(circle) mcolor(blue) lcolor(blue))
			(connected p05 year if tx==1, msymbol(point) mcolor(black) lcolor(black) lpattern(dash))
			(connected p95 year if tx==1, msymbol(point) mcolor(black) lcolor(black) lpattern(dash))
			, 
			xtitle(Year)
			xtick(1985(3)2003) xmtick(1985(1)2003) xlabel(1985(3)2003)
			xline(1993, lcolor(black))
			ytitle(Placebo coefficient)
			ytick(-300(100)300) ylabel(-300(100)300) yline(0, lcolor(black))
			legend(off)
			graphregion(fcolor(white))
			;
	#delimit cr
	
	graph save $figures/Event_Studies/eventStudy_`x'.gph, replace
	graph export $figures/Event_Studies/eventStudy_`x'.pdf, replace
  }

