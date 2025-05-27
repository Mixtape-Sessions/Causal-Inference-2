*-----------------------------------------------------------
* name: donohue_lm.do. 
* author: scott cunningham (baylor)
* Replicating Aneja, Donohue and Zhang, et al. (2011) who was updating Lott and Mustard (1997) for mixtape second edition
*-----------------------------------------------------------

clear 
capture log close 

* Home
* cd "/Users/scott_cunningham/Library/CloudStorage/Dropbox-MixtapeConsulting/scott cunningham/Classes/Archive/Advanced causal inference/Lott_Mustard/Programs"

* Laptop
cd "/Users/scunning/Library/CloudStorage/Dropbox-MixtapeConsulting/scott cunningham/Classes/Archive/Advanced causal inference/Lott_Mustard/Programs"

use https://github.com/scunning1975/mixtape/raw/master/adz_lm.dta, clear

/*
\item[Step 1.] Define the Research Question Using Potential Outcomes

\item[Step 2.] Is Everyone Treated at the Same Time?

\item[Step 3.] Plot Treatment Rollout

\item[Step 4.] Validity of Unconditional Parallel Trends Assumption

\item[Step 5.] Check Overlap

\item[Step 6.] Plot Average Outcomes Across Cohorts

\item[Step 7.] Estimator Selection and Assumptions

\item[Step 8.] Sensitivity Analysis for Parallel Trends Violations

\item[Step 9.] Don't Do Diff-in-Diff (DDDiD)

*/


* [Step 2.] Is Everyone Treated at the Same Time?

* Step 1: Restrict to county-year observations where shallf == 1
gen shallf_year = year if shallf == 1

* Step 2: Collapse to the first year by state (stnumber)
collapse (min) first_shallf_year=shallf_year, by(stnumber)

* Step 3: List the result
list stnumber first_shallf_year, sepby(stnumber)

* Save the collapsed state-level adoption year
tempfile state_adoption
save `state_adoption'

* Reload or return to your original county-year data
use https://github.com/scunning1975/mixtape/raw/master/adz_lm.dta, clear

* Merge in first adoption year by state
merge m:1 stnumber using `state_adoption'

drop treat_date
ren first_shallf_year treat_date
replace treat_date=0 if treat_date==.
replace treat_date=0 if treat_date>1992

drop if year>1992 // matching Lott and Mustard years


* Tabulate the unique treatment cohorts by `treat_date`
estpost tabulate treat_date if year==1990, nototal

* Get the total unique county count
quietly count if year==2000
local total_count : display %9.0fc r(N)

* Define labels for treatment dates in treat_date
label define treat_date_labels 0 "Never treated" ///
                              1977 "1977 cohort" ///
                              1986 "1986 cohort" ///
                              1988 "1988 cohort" ///
                              1989 "1989 cohort" ///
                              1990 "1990 cohort" ///
                              1991 "1991 cohort" ///
                              1992 "1992 cohort" ///

* Apply the label to the treat_date variable
label values treat_date treat_date_labels			  

* Step 3: Generate LaTeX table for treatment cohorts
esttab using "./lm_counties_by_treatment_date.tex", ///
    cells("b(fmt(%9.0fc) label(Count))") ///
    noobs nonumber nomtitle nonote ///
    collabels(none) ///
    varlabels(`labels') ///
    title("Number of Counties by Shall-Issue Law Treatment Date") ///
    addnotes("Total unique counties: `total_count'") ///
    replace style(tex) booktabs ///
    prehead("\begin{table}[htbp]\centering" "\caption{Number of Counties by Shall-Issue Law Treatment Date}\label{tab:countybycohort}" "\begin{tabular}{lc}") ///
    posthead("\toprule" "\textbf{Treatment Date (Shall-issue law)} & \textbf{Number of Counties Treated} \\" "\midrule") ///
    postfoot("\midrule" ///
             "Total counties & `total_count' \\" ///
             "\bottomrule" "\end{tabular}" "\end{table}")

* Step 4: Clean up temporary variable and restore original data

drop if treat_date==1977

* Clear any previous estimates
preserve 

eststo clear

* Step 2: Generate a count variable for tabulation
count if year==1990
gen count=`r(N)'

* Tabulate the unique treatment cohorts by `treat_date`
estpost tabulate treat_date if year==1990, nototal

* Get the total unique county count
quietly count if year==1990
local total_count : display %9.0fc r(N)

* Define labels for treatment dates in treat_date
label define treat_date_labels2 0 "Never treated" ///
                              1977 "1977 cohort" ///
                              1985 "1985 cohort" ///
                              1988 "1988 cohort" ///
                              1989 "1989 cohort" ///
                              1990 "1990 cohort" ///
                              1991 "1991 cohort" ///
                              1992 "1992 cohort" ///

* Apply the label to the treat_date variable
label values treat_date treat_date_labels2			  

* Step 3: Generate LaTeX table for treatment cohorts
esttab using "./lm_counties_by_treatment_date2.tex", ///
    cells("b(fmt(%9.0fc) label(Count))") ///
    noobs nonumber nomtitle nonote ///
    collabels(none) ///
    varlabels(`labels') ///
    title("Number of Counties by Concealed Carry Law Treatment Date") ///
    addnotes("Total unique counties: `total_count'") ///
    replace style(tex) booktabs ///
    prehead("\begin{table}[htbp]\centering" "\caption{Number of Counties by Shall-Issue Law Treatment Date}\label{tab:countybycohort}" "\begin{tabular}{lc}") ///
    posthead("\toprule" "\textbf{Treatment Date (Shall-issue law)} & \textbf{Number of Counties Treated} \\" "\midrule") ///
    postfoot("\midrule" ///
             "Total counties & `total_count' \\" ///
             "\bottomrule" "\end{tabular}" "\end{table}")

restore





* [Step 3.] Plot Treatment Rollout

gen 	post = 0
replace post = 1 if year >= treat_date & treat_date != 0

panelview lratmur post, prepost bytiming ///
    i(fipsid) t(year) type(treat) ///
    xtitle("Year") ///
    ytitle("Individual Counties") ///
    ylabel(none) ///
    title("Cohort Rollout of Concealed Carry Law", size(medsmall)) ///
    subtitle("1977 to 2000", size(small)) ///
    legend(order(1 "Never treated" 2 "Treated (Pre)" 3 "Treated (Post)") ///
           pos(6) ring(0) col(1) size(small))
		   


* Step 4. Is Unconditional Parallel Trends Plausible?

gen 	treat = 0
replace treat = 1 if treat_date<year 
replace treat = 0 if treat_date==0

gen 	time_til = year - treat_date
replace time_til = . if treat_date==0 




* LASSO on pre-trends in covariates. I need to calculate pre-trends.

xtset fipsid year

areg lratmur i.stnumber##i.year if treat_date == 0 | time_til < 0, absorb(fipsid) cluster(fipsid)
predict murder_resid, resid

gen d_murder = D.murder_resid

lasso linear d_murder aovio rpcpi rpcui rpcim rpcrpo popc density ppb* ppw* ppn*   ///
    if (treat_date == 0 | time_til < 0)
estimates store lasso_model1
lassocoef, display(coef, standardized) // Cuts it down 31 nonzero coefficients

    

	
* Step 5. Check for normalized differences in covariate means

* Close any previous file handle if open
capture file close tableout

* Step 1: Define treatment and control groups in 1985
gen 	treated = 1 if treat_date != 0
replace treated = 0 if treat_date == 0

* Step 2: Define local covariates
local covariates "aovio rpcpi rpcu popc ppb* ppw*"

* Step 3: Open LaTeX table file
file open tableout using covariate_balance_1985.tex, write replace
file write tableout "\\begin{table}[htbp]\\centering" _n
file write tableout "\\tiny" _n
file write tableout "\\caption{Covariate Balance in 1985 (Treatment vs. Never-Treated)}" _n
file write tableout "\\label{tab:covariate_balance_1985}" _n
file write tableout "\\begin{tabular}{lccc}" _n
file write tableout "\\toprule" _n
file write tableout "Covariate & Treated Mean & Control Mean & Std. Diff \\\\" _n
file write tableout "\\midrule" _n

* Step 4: Loop through covariates and calculate standardized differences
foreach var of varlist `covariates' {
    local line "`var'"

    * Mean and SD for treated
    quietly summarize `var' if treated == 1 & year == 1985
    local treat_mean = r(mean)
    local sd_treat = r(sd)

    * Mean and SD for control
    quietly summarize `var' if treated == 0 & year == 1985
    local control_mean = r(mean)
    local sd_control = r(sd)

    * Difference in means
    local diff_mean = `treat_mean' - `control_mean'

    * Ensure no missing SDs before computing pooled SD
    if `sd_treat' != . & `sd_control' != . {
        local pooled_sd = sqrt((`sd_treat'^2 + `sd_control'^2) / 2)
        local std_diff = `diff_mean' / `pooled_sd'
    }
    else {
        local std_diff = .
    }

    * Write LaTeX line
    local line "`line' & `: di %9.3f `treat_mean'' & `: di %9.3f `control_mean'' & `: di %9.3f `std_diff''"
    file write tableout "`line' \\\\" _n
}
* Step 5: Close table
file write tableout "\\bottomrule" _n
file write tableout "\\end{tabular}" _n
file write tableout "\\end{table}" _n
file close tableout



local covariates "rpcpi  popc ppb* ppw*"
logit treated `covariates'
predict propensity

* Expansion counties
kdensity propensity if treated == 1, gen(x1 d1) nograph n(100)

* Non-Expansion counties
kdensity propensity if treated == 0, gen(x2 d2) nograph n(100)

twoway (line d1 x1, lcolor(red) lwidth(medthick)) ///
       (line d2 x2, lcolor(blue) lpattern(dash) lwidth(medthick)), ///
       title("Distribution of Propensity Scores") legend(order(1 "Treated" 2 "Never Treated")) ///
       name(wtd, replace)

graph export "figure1_propensity_scores_sc.pdf", replace



	
* Step 6. Plot Average Outcomes Across Cohorts

preserve
collapse (mean) lratmur, by(treat_date year)
xtset treat_date year

label variable lratmur "Average County Log Murder Rate"

// For births
separate lratmur, by(treat_date) gen(yr)

// Create individual birth rates plots with reference lines
foreach t in 0 1986 1988 1989 1990 1991 1992 {
    if (`t' == 0) {
        local label "never treated"
        local linecolor "blue"
    }
    else {
        local label "`t' cohort"
        local rline `t'
        local linecolor "blue"
    }

    scatter yr* year, recast(line) lc(gs12 ...) lp(solid ...) ///
        legend(off) || line lratmur year if treat_date == `t', ///
        lc(`linecolor') lp(solid) lw(medthick) xtitle("") subtitle("`label'") ///
        name(plot_`t', replace) ///
        `= cond(`t' != 0, "xline(`rline', lcolor(red) lpattern(dash))", "")' ///
        xlabel(1977(3)1992, labsize(small)) ///
        xscale(range(1977 1992)) ///
        ylabel(, angle(0) labsize(small))
}

// Combine the birth rate individual plots into a single graph
graph combine plot_0 plot_1986 plot_1988 plot_1989 plot_1990 plot_1991 plot_1992 , ///
    title("Average Log Murder Rates by Cohort") ///
    ysize(8) xsize(10) ///
    scale(0.9)
graph export "rollout_murderrate.png", as(png) name("Graph") replace width(2000)

restore

* Step 7. Estimation

local covariates "rpcpi popc ppb* ppw*"
local z = invnormal(0.975)

* TWFE Models
reghdfe lratmur i.year shallf, absorb(fipsid) cluster(stnumber)
scalar ATT1 = _b[shallf]
scalar SE1  = _se[shallf]
scalar CI_lower1 = ATT1 - `z' * SE1
scalar CI_upper1 = ATT1 + `z' * SE1
scalar N1 = e(N)

reghdfe lratmur i.year `covariates' shallf, absorb(fipsid) cluster(stnumber)
scalar ATT2 = _b[shallf]
scalar SE2  = _se[shallf]
scalar CI_lower2 = ATT2 - `z' * SE2
scalar CI_upper2 = ATT2 + `z' * SE2
scalar N2 = e(N)

* CSDID Models
csdid lratmur, ivar(fipsid) time(year) gvar(treat_date) dr long2
csdid_estat simple
mat b3 = r(b)
mat V3 = r(V)
scalar ATT3 = b3[1,1]
scalar SE3  = sqrt(V3[1,1])
scalar CI_lower3 = ATT3 - `z' * SE3
scalar CI_upper3 = ATT3 + `z' * SE3
scalar N3 = e(N)

csdid lratmur `covariates', ivar(fipsid) time(year) gvar(treat_date) dr long2
csdid_estat simple
mat b4 = r(b)
mat V4 = r(V)
scalar ATT4 = b4[1,1]
scalar SE4  = sqrt(V4[1,1])
scalar CI_lower4 = ATT4 - `z' * SE4
scalar CI_upper4 = ATT4 + `z' * SE4
scalar N4 = e(N)

* Create LaTeX Table
capture file close tablefile
file open tablefile using "table_ccl_effects.tex", write replace

file write tablefile "\begin{table}[htbp]\\centering" _n
file write tablefile "\scriptsize" _n
file write tablefile "\caption{Estimated Effect of CCL on Log Homicide Rates}" _n
file write tablefile "\label{tab:cc_effect_loghomicide}" _n
file write tablefile "\begin{threeparttable}" _n
file write tablefile "\begin{tabular}{lcccc}" _n
file write tablefile "\toprule" _n
file write tablefile "& \multicolumn{2}{c}{\textbf{TWFE}} & \\multicolumn{2}{c}{\textbf{CSDID}} \\" _n
file write tablefile "\cmidrule(lr){2-3} \cmidrule(lr){4-5}" _n
file write tablefile "& (1) & (2) & (3) & (4) \\" _n
file write tablefile "\midrule" _n

file write tablefile "Estimated Effect & `=string(ATT1,"%9.4f")' & `=string(ATT2,"%9.4f")' & `=string(ATT3,"%9.4f")' & `=string(ATT4,"%9.4f")' \\" _n
file write tablefile "Robust SE & (`=string(SE1,"%9.4f")') & (`=string(SE2,"%9.4f")') & (`=string(SE3,"%9.4f")') & (`=string(SE4,"%9.4f")') \\" _n
file write tablefile "95\% CI & [`=string(CI_lower1,"%9.4f")', `=string(CI_upper1,"%9.4f")'] & [`=string(CI_lower2,"%9.4f")', `=string(CI_upper2,"%9.4f")'] & [`=string(CI_lower3,"%9.4f")', `=string(CI_upper3,"%9.4f")'] & [`=string(CI_lower4,"%9.4f")', `=string(CI_upper4,"%9.4f")'] \\" _n

file write tablefile "\midrule" _n
file write tablefile "Covariates & No & Yes & No & Yes \\\\" _n
file write tablefile "Observations & `=N1' & `=N2' & `=N3' & `=N4' \\" _n
file write tablefile "\bottomrule" _n
file write tablefile "\end{tabular}" _n

file write tablefile "\begin{tablenotes}" _n
file write tablefile "\tiny" _n
file write tablefile "\item Columns (1) and (2) report two-way fixed effects (TWFE) estimates with and without covariates. Columns (3) and (4) report doubly robust estimates from Callaway and Sant'Anna (2021), using simple (unweighted) group-time ATT aggregation. Covariates include real per capita income, county population, and demographic shares by age, race, and sex. Robust standard errors clustered at the state level." _n
file write tablefile "\end{tablenotes}" _n
file write tablefile "\end{threeparttable}" _n
file write tablefile "\end{table}" _n

file close tablefile


tempfile csdid
save `csdid', replace


*----------------------------------------------------------------------
* 1. Estimate Callaway–Sant'Anna CSDID with covariates
*----------------------------------------------------------------------
preserve

local covariates "rpcpi popc ppb* ppw*"
csdid lratmur `covariates', ivar(fipsid) time(year) gvar(treat_date) dr long2

*----------------------------------------------------------
* 2. Extract ATT(g,t) point estimates for all cohorts
*----------------------------------------------------------
clear

* Pull only ATT(g,t) rows: 6 groups × 15 periods = 90
matrix b0 = e(b_attgt)
matrix V  = e(V_attgt)
matrix b0 = b0[1,1..90]
matrix V  = V[1..90, 1..90]
matrix b  = b0'
local labels : colnames b0
matrix rownames b = `labels'

svmat b, name(att)
gen str40 gt_label = ""
local i = 1
foreach l of local labels {
    replace gt_label = "`l'" in `i'
    local ++i
}

*----------------------------------------------------------
* 4. Attach standard errors and confidence intervals
*----------------------------------------------------------
gen se = .
gen ll = .
gen ul = .
quietly forvalues r = 1/`=_N' {
    local s = sqrt(V[`r',`r'])
    replace se = `s' in `r'
    replace ll = att1 - 1.96 * `s' in `r'
    replace ul = att1 + 1.96 * `s' in `r'
}



*----------------------------------------------------------
* 3. Assign cohort (g) and year (t) from gt_label
*----------------------------------------------------------
local cohorts 1986 1988 1989 1990 1991 1992
local npergroup 15
local ncohort : word count `cohorts'

gen cohort = .

forvalues k = 1/`ncohort' {
    local c = word("`cohorts'", `k')
    local first = 1 + (`k'-1)*`npergroup'
    local last = `k'*`npergroup'
    replace cohort = `c' in `first'/`last'
}

* Manually code it because I can't figure it out

gen max_pre = .
gen max_post = .
foreach g of numlist 1986 1988 1989 1990 1991 1992 {
    replace max_pre  = `g' - 1977 - 1 if cohort == `g'
    replace max_post = 1992 - `g' + 1 if cohort == `g'
}

* Assume data is sorted by cohort and within cohort (so, by default, the first 15 are 1986, next 15 are 1988, etc.)
local cohorts 1986 1988 1989 1990 1991 1992
local first_year 1977
local last_year 1992
local npergroup 15
local totalobs = _N

gen event_time = .

local row = 1
foreach g of local cohorts {
    local min_evttime = `first_year' - `g'
    local max_evttime = `last_year' - `g'
    local ecount = 0

    forvalues t = `min_evttime'/`max_evttime' {
        if `t' == -1 continue
        replace event_time = `t' in `row'
        local ++row
        local ++ecount
        if `ecount' == `npergroup' continue, break
    }
}


tempfile with_baseline
save `with_baseline', replace


* Create 6 baseline rows (one per cohort)
clear
input cohort
1986
1988
1989
1990
1991
1992
end

gen year = cohort - 1
gen event_time = -1
gen att1 = 0
gen is_baseline = 1
gen gt_label = "baseline"

* Combine with your main data
append using `with_baseline'

replace year = cohort + event_time if missing(year)

* For one cohort (say 1986)
twoway  (scatter att1 event_time if cohort==1986 & is_baseline==., msymbol(circle) mcolor(blue)) ///
        (scatter att1 event_time if cohort==1986 & is_baseline==1, msymbol(Oh) mcolor(blue)), ///
        yline(0) xline(-1) legend(off) title("Cohort 1986")



*----------------------------------------------------------
* 5. Plot each group: hollow circle for baseline, vertical line
*----------------------------------------------------------
levelsof cohort, local(groups)
foreach g of local groups {
    local baseyr = `g' - 1
    twoway ///
      (rcap ul ll year if cohort==`g' & event_time != -1, lc(gs10) lw(vthin)) ///
      (scatter att1 year if cohort==`g' & event_time != -1, mc(navy) msymbol(circle)) ///
      (scatter att1 year if cohort==`g' & event_time == -1, mc(navy) msymbol(Oh)), ///
      yline(0, lp(dash)) xline(`baseyr', lp(dash) lc(black)) ///
      title("Group `g'", size(medsmall)) ///
      xtitle("Year", size(small)) ///
      ytitle("ATT(g,t)", size(small)) ///
      xlabel(, labsize(vsmall) angle(45)) ///
      xscale(range(1977 1992)) /// <--- This is the magic!
      ylabel(, labsize(vsmall)) ///
      legend(off) name(g`g', replace)
}

*----------------------------------------------------------
* 6. Combine all panels into a single figure
*----------------------------------------------------------
graph combine g1986 g1988 g1989 g1990 g1991 g1992, ///
    cols(3) imargin(zero) ///
    title("ATT(g,t) for Each Treatment Cohort", size(medsmall)) ///
    note("CSDID, doubly–robust, with covariates", size(vsmall))

graph export "attgt_by_cohort.pdf", replace

restore


*----------------------------------------------------------

local covariates "rpcpi popc ppb* ppw*"
csdid lratmur `covariates', ivar(fipsid) time(year) gvar(treat_date) dr long2

csdid_estat event
csdid_plot, ///
    title("CS Event Study With Covariates") ///
    ytitle("Estimated ATT(t)") ///
    xtitle("Event Time") ///
    name(attgt_eventstudy, replace)
	
graph export Figures/event_study_GxT_covs.pdf, replace


*------------------------------------------------------------
* Step 8: Sensitivity analysis (honestdid)
*------------------------------------------------------------

local covars "rpcpi popc ppb* ppw*"

// Estimate the event study
	csdid lratmur `covariates', ivar(fipsid) time(year) gvar(treat_date) dr long2 

csdid_estat event, window(-15 7)
matlist e(b)
matrix l_vec = J(1, 8, 1/8)

honestdid, pre(1/15) post(16/23) mvec(0(0.05)0.5) delta(rm) ///
    l_vec(l_vec) b(e(b)) vcov(e(V)) coefplot ///
    title("Sensitivity Analysis of CCL on Log Homicide Rates") ///
    subtitle("Robustness to Parallel Trends Violations")
	


capture log close
exit
