*-----------------------------------------------------------
* name: ccl.do. 
* Replicating Aneja, Donohue and Zhang, et al. (2011) who was updating Lott and Mustard (1997) for mixtape second edition
*-----------------------------------------------------------

clear 
capture log close 

* Change this to your working directory
cd "/Users/scunning/Library/CloudStorage/Dropbox-MixtapeConsulting/scott cunningham/Classes/Archive/Advanced causal inference/Lott_Mustard/Programs"

use https://github.com/scunning1975/mixtape/raw/master/adz_lm.dta, clear

/*
\item[Step 1.] Define the Research Question Using Potential Outcomes

Outcome variable is lratmur (log murder rate)

\item[Step 2.] Is Everyone Treated at the Same Time?

treat_date equals zero if never treated and the other years listed in treat_date are when those counties were commonly treated. 

\item[Step 3.] Plot Treatment Rollout

\item[Step 4.] Selecting Your Comparison Group

\item[Step 5.] Validity of Unconditional Parallel Trends Assumption

\item[Step 6.] Check Overlap

\item[Step 7.] Plot Average Outcomes Across Cohorts

\item[Step 8.] Estimator Selection and Assumptions

\item[Step 9.] Sensitivity Analysis for Parallel Trends Violations

\item[Step 10.] Don't Do Diff-in-Diff (DDDiD)

*/

* [Step 1.] Picking your treatment effect parameter is largely about weighting by population. 

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

drop if year>1992 // matching Lott and Mustard years (1977 to 1992)

gen pop_wt = popc
label variable pop_wt "County level population"



