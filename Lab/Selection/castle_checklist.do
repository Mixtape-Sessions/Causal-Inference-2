******************************************************************
* name: castle_checklist.do
* description: First three steps of the Pedro checklist
******************************************************************

clear all
capture log close

* Load files
*  net install grc1leg, from(http://www.stata.com/users/vwiggins) replace
* net install gr0075, from(http://www.stata-journal.com/software/sj18-4) replace
* ssc install labutil, replace
* ssc install sencode, replace
 
* cap ado uninstall panelview //in-case already installed
* net install panelview, all replace from("https://yiqingxu.org/packages/panelview_stata")

use "https://github.com/scunning1975/mixtape/raw/master/castle.dta", clear

gen treat_date = effyear
replace treat_date = 2020 if effyear==.

// Define the labels for each unique value
label define treat_date_lbl 2020 "never treated" ///
                      2005 "2005 cohort" ///
                      2006 "2006 cohort" ///
                      2007 "2007 cohort" ///
                      2008 "2008 cohort" ///
                      2009 "2009 cohort cohort"

// Assign the labels to the treat_date variable
label values treat_date treat_date_lbl

* Step 1: Show all the rollout alphabetically
panelview l_homicide post, i(state) t(year) type(treat) xtitle("Year") ytitle("State") title("Treatment Status by Timing Group")

graph export "./rollout1.png", as(png) name("Graph") replace

* But maybe you'd like to group them together by treatment timing group
panelview l_homicide post, bytiming i(state) t(year) type(treat) xtitle("Year") ytitle("State") title("Treatment Status by Timing Group")

graph export "./rollout2.png", as(png) name("Graph") replace

* Distinguish visually the pre/post period
panelview l_homicide post, prepost bytiming i(state) t(year) type(treat) xtitle("Year") ytitle("State") title("Treatment Status by Timing Group")

graph export "./rollout3.png", as(png) name("Graph") replace


* Step 2: Document how many units are treated in each cohort
// Tabulate treat_date for the year 1970
tabulate effyear if year == 2009, matcell(freq) matrow(names)

* Get state names by treat_date for the year 2009 (or any year)
levelsof treat_date, local(treat_dates)

foreach x in `treat_dates' {
    display "Treatment date: `x'"
    tabulate state if treat_date == `x' & year==2009
}

* Step 3 of checklist: plot the outcome by cohort (means)

// Just to remind you we are using the mean outcome per timing group
preserve
collapse (mean) l_homicide, by(treat_date year)
xtset treat_date year


// Create individual plots with reference lines
foreach t in 2020 2005 2006 2007 2008 2009 {
    local label = cond(`t' == 2020, "never treated", "`t' cohort")
    local rline = cond(`t' == 0, 0, `t')
    
    twoway (line l_homicide year if treat_date == `t', lcolor(blue) lwidth(medium)) ///
           , ///
           subtitle("`label'") ///
           name(plot_`t', replace) ///
           xline(`rline', lcolor(red) lpattern(dash))
}

// Combine the individual plots into a single graph
graph combine plot_2020 plot_2005 plot_2006 plot_2007 plot_2008 plot_2009, ///
    title("Average Log Homicides by Cohort")
	
graph export "../combined_outcomes.png", as(png) name("Graph") replace


separate l_homicide, by(treat_date) gen(yr)
 
// Create individual plots with reference lines
foreach t in 2020 2005 2006 2007 2008 2009 2010 {
    local label = cond(`t' == 2020, "never treated", "`t' cohort")
    local rline = cond(`t' == 0, 0, `t')

	local linecolor = cond(`t' == 2020, "blue", "gs12")
	
      scatter yr* year, recast(line) lc(gs12 ...) lp(solid ...) ///
        legend(off) || line l_homicide year if treat_date == `t', ///
        lp(solid) lw(medthick) xtitle("") subtitle("`label'") ///
      name(plot_`t', replace) ///
      xline(`rline', lcolor(red) lpattern(dash))
}
 
// Combine the individual plots into a single graph
graph combine plot_2020 plot_2005 plot_2006 plot_2007 plot_2008 plot_2009, ///
    title("Average Log Homicides by Cohort")

graph export "./pretty_outcomes.png", as(png) name("Graph") replace


restore

capture log close
exit

