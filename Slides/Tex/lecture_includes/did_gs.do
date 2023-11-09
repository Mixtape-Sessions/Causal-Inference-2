********************************************************************************
* name: did_gs.do
* author: scott cunningham (baylor)
* description: make did and event study google scholar figures
********************************************************************************

clear
capture log close

* Home laptop
* cd "/Users/scunning/Causal-Inference-2/Slides/Tex/lecture_includes"

* Work iMac
cd "/Users/scott_cunningham/Documents/Causal-Inference-2/Slides/Tex/lecture_includes"

import excel "./google_scholar_did.xlsx", sheet("PT DID") firstrow case(preserve) allstring

destring Year, gen(year) force
destring PT, gen(pt) force
destring DID, gen(did) force
destring PT_DID, gen(pt_did) force
destring ES_PT, gen(es_pt) force
destring DID_ES, gen(did_es) force
destring CT, gen(ct) force
destring DID_CT, gen(did_ct) force

* Third wave
destring DID_ATT, gen(did_att) force
destring DID_HET, gen(did_het) force
destring DID_TWFE, gen(did_twfe) force
destring TWFE, gen(twfe) force

* Time set the time series
xtset pt year

* List of variables for which you want to create indices
local vars did pt ct twfe
      
* Loop over each variable
foreach var of local vars {
    * Find the value of the variable in 1990
    su `var' if year==1990
    
    * Generate a base value using the mean for the year 1990
    gen `var'_base = `r(mean)'
    
    * Generate the normalized series for the variable
    gen `var'_index = `var' / `var'_base
}

* Main figure: Plot CT and PT together. 

twoway (tsline pt_index, lcolor(black) lwidth(medthick) lpattern(solid)) (tsline ct_index, lcolor(blue) lwidth(medthick) lpattern(dash)), ytitle(`"Total counts relative to 1990 counts"') ytitle(, size(medsmall) margin(medium)) ttitle(`"Year"') title(`"Parallel Trends vs Common Trends"') subtitle(`"Google Scholar Counts"') note(`"Each series normalized relative to its own count in 1990: PT was 182 and CT was 286."') legend(order(1 "Parallel trends" 2 "Common trends"))

graph export "./trends_graph.jpg", as(jpg) name("Graph") quality(90) replace


* Main figure: Plot DID and TWFE together. 

twoway (tsline did_index, lcolor(black) lwidth(medthick) lpattern(solid)) (tsline twfe_index, lcolor(blue) lwidth(medthick) lpattern(dash)), ytitle(`"Total counts relative to 1990 counts"') ytitle(, size(medsmall) margin(medium)) ttitle(`"Year"') title(`"Diff-in-diff vs TWFE"') subtitle(`"Google Scholar Counts"') note(`"Each series normalized relative to its own count in 1990: DID was 10 and TWFE was 19."') legend(order(1 "Diff-in-Diff" 2 "Twoway Fixed Effects"))

graph export "./twfe_did_graph.jpg", as(jpg) name("Graph") quality(90) replace

gen ln_did=ln(did_index)
gen ln_twfe=ln(twfe_index)

twoway (tsline ln_did, lcolor(black) lwidth(medthick) lpattern(solid)) (tsline ln_twfe, lcolor(blue) lwidth(medthick) lpattern(dash)), ytitle(`"Total counts relative to 1990 counts"') ytitle(, size(medsmall) margin(medium)) ttitle(`"Year"') title(`"Diff-in-diff vs TWFE"') subtitle(`"Google Scholar Counts"') note(`"Each series normalized relative to its own count in 1990: DID was 10 and TWFE was 19."') legend(order(1 "Diff-in-Diff" 2 "Twoway Fixed Effects"))


* Second figure: DiD + CT/PT/ES together (early and late periods)

* List of variables for which you want to create indices
local vars did_es pt_did did_ct

* Loop over each variable
foreach var of local vars {
    * Find the value of the variable in 1990
    su `var' if year==2000
    
    * Generate a base value using the mean for the year 1990
    gen `var'_base = `r(mean)'
    
    * Generate the normalized series for the variable
    gen `var'_index = `var' / `var'_base
}

preserve
drop if year < 2007 | year > 2022


// Create the dual-axis plot
twoway (tsline es_pt, lcolor(blue) lwidth(medthick) yaxis(1)) ///
       (tsline ln_es_pt, lcolor(red) lwidth(medthick) yaxis(2)), ///
       ytitle("Total google scholar counts", axis(1)) ///
       ytitle("Logged total google scholar counts", axis(2)) ///
       ttitle("Year") ///
       title("Total mentions of both event study and parallel trends") ///
       subtitle("Google Scholar from 2007 to 2022") ///
       note("Only 3 mentions before 2007 so I restrict the sample to 2007-2022") ///
       xtick(2007(1)2022) ///
       legend(label(1 "Total Counts") label(2 "Logged Counts")) ///
       yscale(axis(1)) yscale(axis(2))

graph display
restore

graph export "./espt_graph.jpg", as(jpg) name("Graph") quality(90) replace




* 2000 to 2010 only
preserve
drop if year<2000
drop if year>2010

* Combined all
twoway (tsline pt_did_index, lcolor(black) lwidth(medthick) lpattern(solid)) (tsline did_ct_index, lcolor(blue) lwidth(medthick) lpattern(dash)) (tsline did_es_index, lcolor(blue) lwidth(medthick) lpattern(dot)), ytitle(`"Normalized Counts in Google Scholar"') ytitle(, size(medsmall) margin(medium)) ttitle(`"Year"') title(`"Trends in Technical Diff-in-Diff Terms"') subtitle(`"2000 to 2010"') note(`"Base values of series in 2000 are 3, 2 and 4 for ES, PT and CT respectively"') legend(order(1 "PT plus DID" 2 "CT plus DID" 3 "Event Study plus DID")) 

graph export "./did_graph_early.jpg", as(jpg) name("Graph") quality(90) replace
graph save "./did_graph_early.gph", replace
restore


* Combinations but for only 2000-2020
preserve
drop if year<2010

* List of variables for which you want to create indices
local vars did_es pt_did did_ct

* Loop over each variable
foreach var of local vars {
    * Find the value of the variable in 1990
    su `var' if year==2010
    
    * Generate a base value using the mean for the year 1990
    gen `var'_newbase = `r(mean)'
    
    * Generate the normalized series for the variable
    gen `var'_newindex = `var' / `var'_newbase
}


* Combined all
twoway (tsline pt_did_newindex if year <= 2022, lcolor(black) lwidth(medthick) lpattern(solid)) (tsline did_ct_newindex if year <= 2022, lcolor(blue) lwidth(medthick) lpattern(dash)) (tsline did_es_newindex if year <= 2022, lcolor(blue) lwidth(medthick) lpattern(dot)), ytitle(`"Normalized Counts in Google Scholar"') ytitle(, size(medsmall) margin(medium)) ttitle(`"Year"') title(`"Trends in Technical Diff-in-Diff Terms"') subtitle(`"2010 to 2022"') note(`"Base values of series in 2010 are 52, 41 and 37 for ES, PT and CT respectively"') legend(order(1 "PT plus DID" 2 "CT plus DID" 3 "Event Study plus DID")) 

graph export "./did_graph_late_all.jpg", as(jpg) name("Graph") quality(90) replace
graph save "./did_graph_late_all.gph", replace
restore


preserve
drop if year>=2010
twoway (tsline pt_did, lcolor(black) lwidth(medthick) lpattern(solid)) (tsline es_pt, lcolor(blue) lwidth(medthick) lpattern(dash)) (tsline did_es, lcolor(blue) lwidth(medthick) lpattern(dot)), ytitle(`"Counts in Google Scholar"') ytitle(, size(medsmall) margin(medium)) ttitle(`"Year"') title(`"Trends in Diff-in-Diff Terms"') subtitle(`"Combinations of Popular DiD Methods"') note(`"Early parallel trends is NOT differerence-in-differences reference"') legend(order(1 "PT AND DID" 2 "PT AND Event Study" 3 "DID AND Event Study")) 

graph export "./did_graph_early.jpg", as(jpg) name("Graph") quality(90) replace
graph save "./did_graph_early.gph", replace
restore


preserve
drop if year<2010

twoway (tsline pt_did, lcolor(black) lwidth(medthick) lpattern(solid)) (tsline es_pt, lcolor(blue) lwidth(medthick) lpattern(dash)) (tsline did_es, lcolor(blue) lwidth(medthick) lpattern(dot)), ytitle(`"Counts in Google Scholar"') ytitle(, size(medsmall) margin(medium)) xtitle(`"Year"') xscale(range(2010 2022)) xlabel(2010(4)2022) title(`"Trends in Diff-in-Diff Terms"') subtitle(`"Combinations of Popular DiD Methods"') note(`"Early parallel trends is NOT difference-in-differences reference"') legend(order(1 "PT AND DID" 2 "PT AND Event Study" 3 "DID AND Event Study"))


graph export "./did_graph_later.jpg", as(jpg) name("Graph") quality(90) replace
graph save "./did_graph_later.gph", replace

restore



* Third wave

* List of variables for which you want to create indices
local vars did_att did_het did_twfe

* Loop over each variable
foreach var of local vars {
    * Find the value of the variable in 1990
    su `var' if year==2000
    
    * Generate a base value using the mean for the year 1990
    gen `var'_base = `r(mean)'
    
    * Generate the normalized series for the variable
    gen `var'_index = `var' / `var'_base
}


preserve
drop if year<2010

twoway (tsline pt_did, lcolor(black) lwidth(medthick) lpattern(solid)) (tsline es_pt, lcolor(blue) lwidth(medthick) lpattern(dash)) (tsline did_es, lcolor(blue) lwidth(medthick) lpattern(dot)), ytitle(`"Counts in Google Scholar"') ytitle(, size(medsmall) margin(medium)) xtitle(`"Year"') xscale(range(2010 2022)) xlabel(2010(4)2022) title(`"Trends in Diff-in-Diff Terms"') subtitle(`"Combinations of Popular DiD Methods"') note(`"Early parallel trends is NOT difference-in-differences reference"') legend(order(1 "PT AND DID" 2 "PT AND Event Study" 3 "DID AND Event Study"))


graph export "./did_graph_later.jpg", as(jpg) name("Graph") quality(90) replace
graph save "./did_graph_later.gph", replace

restore




capture log close
exit

























twoway (tsline pt_did, lcolor(black) lwidth(medthick) lpattern(solid)), ytitle(`"PT AND DID Counts in Google Scholar"') ttitle(`"Year"') title(`"Mentions of Parallel Trends AND DiD in Google Scholar"') 

graph export "./ptdid_graph.jpg", as(jpg) name("Graph") quality(90) replace
graph save "./ptdid_graph.gph", replace

twoway (tsline es_pt, lcolor(black) lwidth(medthick) lpattern(solid)), ytitle(`"PT AND ES Counts in Google Scholar"') ttitle(`"Year"') title(`"Mentions of Parallel Trends AND Event Study"') 

graph export "./espt_graph.jpg", as(jpg) name("Graph") quality(90) replace
graph save "./espt_graph.gph", replace

twoway (tsline did_es, lcolor(black) lwidth(medthick) lpattern(solid)), ytitle(`"DiD AND ES Counts in Google Scholar"') ttitle(`"Year"') title(`"Mentions of DID AND Event Study in Google Scholar"') note(`"Early mentions of event study is referring to finance"')

graph export "./dides_graph.jpg", as(jpg) name("Graph") quality(90) replace
graph save "./dides_graph.gph", replace




twoway (tsline did, lcolor(black) lwidth(medthick) lpattern(solid)), ytitle(`"DiD Counts in Google Scholar"') ttitle(`"Year"') title(`"Mentions of Difference-in-Differences in Google Scholar"') 

graph export "./did_graph.jpg", as(jpg) name("Graph") quality(90) replace

twoway (tsline es if year<2000, lcolor(black) lwidth(medthick) lpattern(solid)), ytitle(`"Event study counts in Google Scholar"') ttitle(`"Year"') title(`"Mentions of Event Study in Google Scholar"') 

graph export "./es_graph.jpg", as(jpg) name("Graph") quality(90) replace


twoway (tsline pt, lcolor(black) lwidth(medthick) lpattern(solid)) (tsline did, lcolor(blue) lwidth(medthick) lpattern(dash)), ytitle(`"Counts in Google Scholar"') ytitle(, size(medsmall) margin(medium)) ttitle(`"Year"') title(`"Parallel Trends vs Difference in Differences"') subtitle(`"Google Scholar Counts"') note(`"Early parallel trends is NOT differerence-in-differences reference"') legend(order(1 "Parallel trends" 2 "Difference-in-differences"))

graph export "./did_vs_pt_graph.jpg", as(jpg) name("Graph") quality(90) replace


