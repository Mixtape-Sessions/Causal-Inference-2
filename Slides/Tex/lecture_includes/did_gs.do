********************************************************************************
* name: did_gs.do
* author: scott cunningham (baylor)
* description: make did and event study google scholar figures
********************************************************************************

clear
capture log close

cd "/Users/scott_cunningham/Documents/Causal-Inference-2/Slides/Tex/lecture_includes"

import excel "./google_scholar_did.xlsx", sheet("PT DID") firstrow case(preserve) allstring

destring Year, gen(year) force
destring PT, gen(pt) force
destring DID, gen(did) force
destring PT_DID, gen(pt_did) force
destring ES_PT, gen(es_pt) force
destring DID_ES, gen(did_es) force

xtset pt year

* Make pt figure alone, did alone, and then together and then combined

twoway (tsline pt, lcolor(black) lwidth(medthick) lpattern(solid)), ytitle(`"Parallel Trends Counts in Google Scholar"') ttitle(`"Year"') title(`"Mentions of Parallel Trends in Google Scholar"') note(`"Much of the early part of google scholar the phrase parallel trends is not referring to DiD assumption"')

graph export "./pt_graph.jpg", as(jpg) name("Graph") quality(90) replace

twoway (tsline did, lcolor(black) lwidth(medthick) lpattern(solid)), ytitle(`"DiD Counts in Google Scholar"') ttitle(`"Year"') title(`"Mentions of Difference-in-Differences in Google Scholar"') 

graph export "./did_graph.jpg", as(jpg) name("Graph") quality(90) replace

twoway (tsline pt, lcolor(black) lwidth(medthick) lpattern(solid)) (tsline did, lcolor(blue) lwidth(medthick) lpattern(dash)), ytitle(`"Counts in Google Scholar"') ytitle(, size(medsmall) margin(medium)) ttitle(`"Year"') title(`"Parallel Trends vs Difference in Differences"') subtitle(`"Google Scholar Counts"') note(`"Early parallel trends is NOT differerence-in-differences reference"') legend(order(1 "Parallel trends" 2 "Difference-in-differences"))

graph export "./did_vs_pt_graph.jpg", as(jpg) name("Graph") quality(90) replace


drop if year<2000

* Combinations but for only 2000-2020
twoway (tsline pt_did, lcolor(black) lwidth(medthick) lpattern(solid)), ytitle(`"PT AND DID Counts in Google Scholar"') ttitle(`"Year"') title(`"Mentions of Parallel Trends AND DiD in Google Scholar"') 

graph export "./ptdid_graph.jpg", as(jpg) name("Graph") quality(90) replace
graph save "./ptdid_graph.gph", replace

twoway (tsline es_pt, lcolor(black) lwidth(medthick) lpattern(solid)), ytitle(`"PT AND ES Counts in Google Scholar"') ttitle(`"Year"') title(`"Mentions of Parallel Trends AND Event Study"') 

graph export "./espt_graph.jpg", as(jpg) name("Graph") quality(90) replace
graph save "./espt_graph.gph", replace

twoway (tsline did_es, lcolor(black) lwidth(medthick) lpattern(solid)), ytitle(`"DiD AND ES Counts in Google Scholar"') ttitle(`"Year"') title(`"Mentions of DID AND Event Study in Google Scholar"') note(`"Early mentions of event study is referring to finance"')

graph export "./dides_graph.jpg", as(jpg) name("Graph") quality(90) replace
graph save "./dides_graph.gph", replace

* Combined all
twoway (tsline pt_did, lcolor(black) lwidth(medthick) lpattern(solid)) (tsline es_pt, lcolor(blue) lwidth(medthick) lpattern(dash)) (tsline did_es, lcolor(blue) lwidth(medthick) lpattern(dot)), ytitle(`"Counts in Google Scholar"') ytitle(, size(medsmall) margin(medium)) ttitle(`"Year"') title(`"Trends in Diff-in-Diff Terms"') subtitle(`"Combinations of Popular DiD Methods"') note(`"Early parallel trends is NOT differerence-in-differences reference"') legend(order(1 "PT AND DID" 2 "PT AND Event Study" 3 "DID AND Event Study")) 

graph export "./did_graph_all.jpg", as(jpg) name("Graph") quality(90) replace
graph save "./did_graph_all.gph", replace

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






