* name: brazil.do
* author: scott cunningham (baylor)

/*
Replicating the homicide result from
American Economic Journal: Economic Policy 2024, 16(3): 257–289
https://doi.org/10.1257/pol.20220246
The Effects of a ­ Large-Scale Mental Health Reform:
Evidence from Brazil†
By Mateus Dias and Luiz Felipe Fontes*
*/

use https://github.com/scunning1975/mixtape/raw/master/brazil.dta, clear

xtset cod ano

gen rural=popruraltrend/ano

gen x = ano if ca==1
egen g = min(x), by(cod)
recode g (.=0)

gen homicide_rate = sim_agressao

* Step 1: decide on the target parameter.  

* Step 2: make a table of when units are treated. 

* Count municipalities by CAPS introduction cohort
* Use any single year to get unique municipality counts by cohort
preserve
keep if ano == 2005

* Define labels for treatment cohorts first
label define g_labels 0 "Never treated" ///
                     2002 "2002 cohort (always treated)" ///
                     2003 "2003 cohort" ///
                     2004 "2004 cohort" ///
                     2005 "2005 cohort" ///
                     2006 "2006 cohort" ///
                     2007 "2007 cohort" ///
                     2008 "2008 cohort" ///
                     2009 "2009 cohort" ///
                     2010 "2010 cohort" ///
                     2011 "2011 cohort" ///
                     2012 "2012 cohort" ///
                     2013 "2013 cohort" ///
                     2014 "2014 cohort" ///
                     2015 "2015 cohort" ///
                     2016 "2016 cohort"

* Apply the label to the g variable
label values g g_labels

* Close any open file handles first
capture file close tex

* Create a table with counts and percentages
contract g, freq(count)

* Calculate share of treated municipalities (excluding never treated and always treated)
gen share_treated = .
replace share_treated = count/1344 if g != 0 & g != 2002

* Get totals
quietly sum count
local total_count : display %9.0fc r(sum)

quietly sum count if g != 0 & g != 2002
local analysis_treated : display %9.0fc r(sum)

quietly sum count if g != 0
local all_treated : display %9.0fc r(sum)

quietly sum count if g == 0
local never_treated : display %9.0fc r(sum)

quietly sum count if g == 2002
local always_treated : display %9.0fc r(sum)

* Create formatted percentage
gen share_pct = share_treated
format share_pct %4.2f

* Export to LaTeX
file open tex using "./brazil_g.tex", write replace
file write tex "\begin{table}[htbp]\centering" _n
file write tex "\footnotesize" _n
file write tex "\caption{CAPS Introduction Timing and Sample Shares}" _n
file write tex "\label{tab:municipalitybycohort}" _n
file write tex "\begin{threeparttable}" _n
file write tex "\begin{tabular}{lcc}" _n
file write tex "\toprule" _n
file write tex "\textbf{CAPS Timing Group} & \textbf{Municipalities} & \textbf{Share of Treated Municipalities} \\" _n
file write tex "\midrule" _n

* Loop through treatment cohorts (2003-2016 only)
forvalues cohort = 2003/2016 {
   capture confirm numeric variable g
   quietly sum count if g == `cohort'
   if r(N) > 0 {
       local count = r(mean)
       quietly sum share_pct if g == `cohort'
       local pct = r(mean)
       file write tex "`cohort' cohort & " %9.0fc (`count') " & " %4.2f (`pct') " \\" _n
   }
}

file write tex "\midrule" _n
file write tex "\textbf{Total treated municipalities (analysis sample)} & \textbf{`analysis_treated'} & \textbf{1.00} \\" _n
file write tex "\midrule" _n
file write tex "Always treated (2002 cohort, excluded) & `always_treated' & -- \\" _n
file write tex "Never treated (control group) & `never_treated' & -- \\" _n
file write tex "\midrule" _n
file write tex "\textbf{Total} & \textbf{`total_count'} & \textbf{--} \\" _n
file write tex "\bottomrule" _n
file write tex "\end{tabular}" _n
file write tex "\begin{tablenotes}" _n
file write tex "\footnotesize" _n
file write tex "\item This table shows the number of municipalities that received a CAPS center in each year as well as the share of treated municipalities (2003-2016) that each timing cohort makes up. The 2002 cohort is excluded from the analysis as these are always-treated units." _n
file write tex "\end{tablenotes}" _n
file write tex "\end{threeparttable}" _n
file write tex "\end{table}" _n
file close tex

restore


* Step 3. Plot the treatment rollout using grayscale colors
panelview homicide_rate ca, bytiming i(cod) t(ano) type(treat) xtitle("Year") ylabel(none) ytitle("Brazil municipalities") mycolor("#f0f0f0" "#a0a0a0" "#505050") title("Rollout of CAPS Centers") legend(label(1 "Never Treated") label(2 "Treated (Pre)") label(3 "Treated (Post)"))
graph export "./brazil_rollout.png", as(png) name("Graph") replace width(2000)

* Step 4. Plot evolution of homicide_rate by cohort
preserve
collapse (mean) homicide_rate rural, by(g ano)
xtset g ano

// For homicides - create separate series for background lines
separate homicide_rate, by(g) gen(yr)

// Create individual homicide rate plots with reference lines
foreach t in 0 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 {
    if (`t' == 0) {
        local label "Never treated"
        local rline 0
    }
    else {
        local label "`t' cohort"
        local rline `t'
    }
    
    // Plot background lines in light gray, then highlight the focal cohort
    scatter yr* ano, recast(line) lc(gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14) ///
        lp(solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid) ///
        lw(thin thin thin thin thin thin thin thin thin thin thin thin thin thin thin thin thin) ///
        legend(off) || ///
        line homicide_rate ano if g == `t', ///
        lc(gs6) lp(solid) lw(thick) ///
        xtitle("") subtitle("`label'", size(medsmall)) ///
        name(plot_`t', replace) ///
        xline(`rline', lcolor(black) lpattern(dash) lw(medium)) ///
        xlabel(2002(2)2016, labsize(small)) ///
        xscale(range(2002 2016)) ///
        ylabel(, angle(0) labsize(small) format(%3.1f)) ///
        plotregion(color(white)) graphregion(color(white))
}

// Combine the homicide rate individual plots into a single graph
graph combine plot_0 plot_2002 plot_2003 plot_2004 plot_2005 plot_2006 plot_2007 plot_2008 plot_2009 plot_2010 plot_2011 plot_2012 plot_2013 plot_2014 plot_2015 plot_2016, ///
    title("Average Homicide Rates by Treatment Cohort", size(medium)) ///
    ysize(8) xsize(12) ///
    scale(0.85) ///
    plotregion(color(white)) graphregion(color(white))
    
graph export "./rollout_homiciderate.png", as(png) name("Graph") replace width(2400)
cap n drop yr*


// For rural
separate rural, by(g) gen(yr)

// Create individual rural density plots with reference lines
foreach t in 0 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 {
   if (`t' == 0) {
       local label "Never treated"
       local rline 0
   }
   else {
       local label "`t' cohort"
       local rline `t'
   }
   
   // Plot background lines in light gray, then highlight the focal cohort
   scatter yr* ano, recast(line) lc(gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14 gs14) ///
       lp(solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid solid) ///
       lw(thin thin thin thin thin thin thin thin thin thin thin thin thin thin thin thin thin) ///
       legend(off) || ///
       line rural ano if g == `t', ///
       lc(gs6) lp(solid) lw(thick) ///
       xtitle("") subtitle("`label'", size(medsmall)) ///
       name(plot_`t', replace) ///
       xline(`rline', lcolor(black) lpattern(dash) lw(medium)) ///
       xlabel(2002(2)2016, labsize(small)) ///
       xscale(range(2002 2016)) ///
       ylabel(, angle(0) labsize(small) format(%3.2f)) ///
       plotregion(color(white)) graphregion(color(white))
}

// Combine the rural individual plots into a single graph
graph combine plot_0 plot_2002 plot_2003 plot_2004 plot_2005 plot_2006 plot_2007 plot_2008 plot_2009 plot_2010 plot_2011 plot_2012 plot_2013 plot_2014 plot_2015 plot_2016, ///
   title("Average Rural Share by Treatment Cohort", size(medium)) ///
   ysize(8) xsize(12) ///
   scale(0.85) ///
   plotregion(color(white)) graphregion(color(white))
   
graph export "./rollout_rural.png", as(png) name("Graph") replace width(2400)
cap n drop yr*

restore

* Step 5: Covariate balance table (baseline year 2002, ignoring always treated 2002 cohort)

*---------------------------------------------------------------------
* Define covariates
*---------------------------------------------------------------------
global X lnpibpc_ lnpbftransfpc pop10a19anoslino pop20a29anoslino pop30a39anoslino pop40a49anoslino pop50a59anoslino pop60a69anoslino pop70a79anoslino pop10a19anosnino pop20a29anosnino pop30a39anosnino pop40a49anosnino pop50a59anosnino pop60a69anosnino pop70a79anosnino mhpf02trend estab02trend rural analfabs_2000trend sharepobres2000trend theil2000trend lnsaudepctrend poptotaltrend temperaturetrend municipality_areatrend distance_to_capitaltrend altitude_100trend rainfalltrend lnpbfpctrend lnpibpctrend

*---------------------------------------------------------------------
* Create the balance table
*---------------------------------------------------------------------
preserve
    * Keep baseline year 2002 and exclude the always-treated 2002 cohort
    keep if ano == 2002 & g != 2002
    
    * Count number of covariates for matrix dimensions
    local num_vars : word count $X
    
    * Create empty results matrix
    matrix results = J(`num_vars', 3, .)
    matrix colnames results = "Control_Mean" "Treated_Mean" "Norm_Diff"
    
    local i = 1
    foreach var of global X {
        * Get means by group (never treated vs ever treated, excluding 2002 cohort)
        quietly sum `var' if g == 0
        local mean0 = r(mean)
        quietly sum `var' if g > 2002
        local mean1 = r(mean)
        
        * Get standard deviations by group
        quietly sum `var' if g == 0
        local sd0 = r(sd)
        quietly sum `var' if g > 2002
        local sd1 = r(sd)
        
        * Calculate normalized difference
        local norm_diff = (`mean1' - `mean0') / sqrt((`sd0'^2 + `sd1'^2)/2)
        
        * Store in matrix
        matrix results[`i',1] = `mean0'
        matrix results[`i',2] = `mean1' 
        matrix results[`i',3] = `norm_diff'
        
        local ++i
    }
    
    * Add row names
    matrix rownames results = $X
    
    * Display the table
    matrix list results, format(%9.3f)
    
restore

/*
.     * Display the table
.     matrix list results, format(%9.3f)

results[31,3]
              Control_Mean  Treated_Mean     Norm_Diff
    lnpibpc_         2.043         2.104         0.087
lnpbftrans~c         2.020         2.078         0.062
pop10a1~lino         0.110         0.112         0.086
pop20a2~lino         0.087         0.089         0.254
pop30a3~lino         0.072         0.070        -0.207
pop40a4~lino         0.058         0.054        -0.384
pop50a5~lino         0.041         0.037        -0.612
pop60a6~lino         0.029         0.024        -0.757
pop70a7~lino         0.017         0.014        -0.590
pop10a1~nino         0.104         0.108         0.279
pop20a2~nino         0.081         0.088         0.745
pop30a3~nino         0.069         0.071         0.187
pop40a4~nino         0.055         0.055        -0.047
pop50a5~nino         0.040         0.038        -0.290
pop60a6~nino         0.029         0.026        -0.357
pop70a7~nino         0.017         0.016        -0.251
 mhpf02trend      1329.177      1374.646         0.012
estab02trend       502.425       315.642        -0.158
       rural         0.462         0.329        -0.603
analfabs_2~d     44850.928     45065.591         0.009
sharepobre~d     95726.954     94947.447        -0.017
theil2000t~d      1019.351      1100.385         0.368
lnsaudepct~d     11143.292     10612.132        -0.450
poptotaltr~d      1.89e+07      8.79e+07         0.692
temperatur~d     44977.371     46044.377         0.181
municipali~d      2.57e+06      4.15e+06         0.142
distance_t~d      5.35e+05      4.59e+05        -0.229
altitude_1~d      8531.203      7710.402        -0.139
rainfalltr~d      9432.808      9331.244        -0.144
lnpbfpctrend      4044.420      4159.756         0.062
lnpibpctrend      2633.203      2758.735         0.086
*/

gen 	event_time = ano - g
replace event_time = . if g==0
tab 	event_time

* Estimate propensity scores

global controls pop20a29anoslino pop40a49anoslino pop50a59anoslino pop60a69anoslino pop70a79anoslino pop10a19anosnino pop20a29anosnino pop50a59anosnino pop60a69anosnino pop70a79anosnino rural theil2000trend lnsaudepctrend poptotaltrend 

gen 	treat=0 if g==0
replace treat=1 if g>0 & g~=2002
probit treat $controls if ano==2002
predict pscore
label variable pscore "Propensity score"
	
twoway (histogram pscore if treat==1,  color(gray%70)) ///
       (histogram pscore if treat==0,  ///
	   fcolor(none) lcolor(black)), ///
	   legend(order(1 "Treated" 2 "Not treated")) ///
	   title("Propensity Score Distribution for CAPS Treatment") ///
	   xtitle("Propensity Score") ///
	   ytitle("Density")

graph export "./brazil_pscore.png", as(png) name("Graph") replace width(2000)
	   	   
su pscore if treat==0 & ano==2002
su pscore if treat==1 & ano==2002

count if pscore>0.995 & treat==0 & ano==2002
drop if pscore>0.995 & treat==0 & ano==2002



* Step 8: estimate with CS

global controls pop20a29anoslino pop40a49anoslino pop50a59anoslino pop60a69anoslino pop70a79anoslino pop10a19anosnino pop20a29anosnino pop50a59anosnino pop60a69anosnino pop70a79anosnino rural theil2000trend lnsaudepctrend poptotaltrend 

csdid homicide_rate $controls, gvar(g) ivar(cod) time(ano) long2 method(drimp) wboot reps(1000) notyet rseed(1)
csdid_estat simple
csdid_estat group
csdid_estat event

csdid_plot, ///
    title("Effect of Clinic Openings on Homicide Rates") ///
    subtitle("CS with imbalanced baseline covariates") ///
note("Note: Uses the 2008–2010 eventually treated and the never treated counties as controls. " ///
	 "Circles are ATT(l) estimates by relative time, l. All groups and bands are 95% uniform" ///
	 "confidence intervals. Mean homicide rate was approximately 1.23 in 2002.") ///
    xtitle("Relative Years Before and After Clinics Opened") ///
    ytitle("Estimated average treatment effects") ///
    style(rspike) ///
    xlabel(, labsize(small)) ///
    ylabel(, labsize(small) angle(0)) ///
    xscale(titlegap(*1.5)) ///
    yscale(titlegap(*1.5))

graph export "./cs_long2.png", as(png) name("Graph") replace width(2000)



* Run our CS estimation with only RUCC controls
csdid homicide_rate $controls, gvar(g) ivar(cod) time(ano) long2 method(drimp) wboot reps(1000) notyet rseed(1)

* Generate event study aggregation
csdid_estat event

* Extract the event study results
matrix b_event = r(b)
matrix V_event = r(V)

* Get dimensions and create dataset
local n_coef = colsof(b_event)
preserve

clear
set obs `n_coef'

* Extract coefficient names and values
gen coef_name = ""
gen coef_value = .
gen se = .

forvalues i = 1/`n_coef' {
    local name : colnames b_event
    local this_name : word `i' of `name'
    replace coef_name = "`this_name'" in `i'
    replace coef_value = b_event[1, `i'] in `i'
    replace se = sqrt(V_event[`i', `i']) in `i'
}

* Keep only the event time coefficients (Tm* and Tp*)
keep if regexm(coef_name, "^T[mp][0-9]+$")

* Create event time variable
gen event_time = .
replace event_time = -real(regexs(1)) if regexm(coef_name, "^Tm([0-9]+)$")
replace event_time = real(regexs(1)) if regexm(coef_name, "^Tp([0-9]+)$")

* Sort by event time
sort event_time

* Create confidence intervals (using bootstrap critical values if available)
gen ci_lower = coef_value - 1.96 * se
gen ci_upper = coef_value + 1.96 * se

* Add reference period at t = -1
local n = _N + 1
set obs `n'
replace event_time = -1 in `n'
replace coef_value = 0 in `n'
replace ci_lower = 0 in `n'
replace ci_upper = 0 in `n'
replace coef_name = "Reference" in `n'

* Sort again
sort event_time

* Create the beautiful plot
twoway ///
    (rcap ci_upper ci_lower event_time if event_time != -1, ///
        lcolor(black%60) lwidth(medium)) ///
    (line coef_value event_time, ///
        lcolor(black) lwidth(thick) lpattern(solid)) ///
    (scatter coef_value event_time if event_time != -1, ///
        mcolor(black) mfcolor(black) msymbol(circle) msize(medium) mlwidth(medium)) ///
    (scatter coef_value event_time if event_time == -1, ///
        mcolor(black) mfcolor(white) msymbol(Oh) msize(large)), ///
    yline(0, lpattern(dash) lcolor(gray%70) lwidth(medium)) ///
    xline(-0.5, lpattern(dot) lcolor(red%60) lwidth(medium)) ///
    title("Estimated Effect of Clinic Openings on Homicide Rates", ///
        size(large) color(black)) ///
    subtitle("CS with imbalanced controls", ///
        size(medium) color(black)) ///
    xtitle("Years relative to clinic openings", ///
        size(medium)) ///
    ytitle("Treatment effect", ///
        size(medium)) ///
    xlabel(-14(2)13, labsize(medium)) ///
    ylabel(, labsize(medium) format(%3.1f)) ///
    legend(off) ///
    graphregion(color(white) lwidth(medium) lcolor(black)) ///
    plotregion(color(white) lwidth(medium) lcolor(black)) ///
    xsize(8) ysize(6)

* Export the plot
graph export "./es_hrate_original.png", ///
    replace width(2400) height(1800)

di "SUCCESS: Beautiful event study plot created!"
di "File saved: ./es_hrate_original.png"

* Display key results
di ""
di "Event Study Results Summary:"
di "==========================="

restore	

* Use csdid2	
csdid2 homicide_rate $controls, gvar(g) ivar(cod) time(ano) long2 method(drimp) notyet 

* Generate event study aggregation
estat event

* Extract the event study results
matrix b_event = e(b)
matrix V_event = e(V)

* Get dimensions and create dataset
local n_coef = colsof(b_event)
preserve
clear
set obs `n_coef'

* Extract coefficient names and values
gen coef_name = ""
gen coef_value = .
gen se = .

local colnames : colnames b_event
forvalues i = 1/`n_coef' {
    local this_name : word `i' of `colnames'
    replace coef_name = "`this_name'" in `i'
    replace coef_value = b_event[1, `i'] in `i'
    replace se = sqrt(V_event[`i', `i']) in `i'
}

* Keep only the event time coefficients (tm* and tp*)
keep if regexm(coef_name, "^t[mp][0-9]+$")

* Create event time variable
gen event_time = .
replace event_time = -real(regexs(1)) if regexm(coef_name, "^tm([0-9]+)$")
replace event_time = real(regexs(1)) if regexm(coef_name, "^tp([0-9]+)$")

* Sort by event time
sort event_time

* Create confidence intervals
gen ci_lower = coef_value - 1.96 * se
gen ci_upper = coef_value + 1.96 * se

* Add reference period at t = -1
local n = _N + 1
set obs `n'
replace event_time = -1 in `n'
replace coef_value = 0 in `n'
replace ci_lower = 0 in `n'
replace ci_upper = 0 in `n'
replace coef_name = "Reference" in `n'

* Sort again
sort event_time

* Create the plot
twoway ///
    (rcap ci_upper ci_lower event_time if event_time != -1, ///
        lcolor(gs8) lwidth(medium)) ///
    (line coef_value event_time, ///
        lcolor(black) lwidth(thick) lpattern(solid)) ///
    (scatter coef_value event_time if event_time != -1, ///
        mcolor(black) mfcolor(black) msymbol(circle) msize(medium) mlwidth(medium)) ///
    (scatter coef_value event_time if event_time == -1, ///
        mcolor(black) mfcolor(white) msymbol(Oh) msize(large)), ///
    yline(0, lpattern(dash) lcolor(gs10) lwidth(medium)) ///
    xline(-0.5, lpattern(dot) lcolor(gs6) lwidth(medium)) ///
    title("Estimated Effect of CAPS on Homicide Rates", ///
        size(medium) color(black)) ///
    subtitle("Callaway-Sant'Anna with Imbalanced Controls", ///
        size(medsmall) color(black)) ///
    xtitle("Years relative to CAPS opening", ///
        size(medium)) ///
    ytitle("Treatment effect (homicides per 10,000)", ///
        size(medium)) ///
    xlabel(-14(2)12, labsize(medium)) ///
    ylabel(, labsize(medium) format(%3.1f)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    xsize(8) ysize(6)

* Export the plot
graph export "./es_hrate_original.png", ///
    replace width(2400) height(1800)

di "SUCCESS: Event study plot created!"
di "File saved: ./es_hrate_original.png"

restore



** Plot only the -4 and +4.  
* Plot only the -5 to +3 range (no need to rerun csdid2)
* Extract the event study results (already stored from previous run)
matrix b_event = e(b)
matrix V_event = e(V)

* Get dimensions and create dataset
local n_coef = colsof(b_event)
preserve
clear
set obs `n_coef'

* Extract coefficient names and values
gen coef_name = ""
gen coef_value = .
gen se = .

local colnames : colnames b_event
forvalues i = 1/`n_coef' {
    local this_name : word `i' of `colnames'
    replace coef_name = "`this_name'" in `i'
    replace coef_value = b_event[1, `i'] in `i'
    replace se = sqrt(V_event[`i', `i']) in `i'
}

* Keep only the event time coefficients (tm* and tp*)
keep if regexm(coef_name, "^t[mp][0-9]+$")

* Create event time variable
gen event_time = .
replace event_time = -real(regexs(1)) if regexm(coef_name, "^tm([0-9]+)$")
replace event_time = real(regexs(1)) if regexm(coef_name, "^tp([0-9]+)$")

* RESTRICT TO -5 TO +3 WINDOW
keep if event_time >= -5 & event_time <= 3

* Sort by event time
sort event_time

* Create confidence intervals
gen ci_lower = coef_value - 1.96 * se
gen ci_upper = coef_value + 1.96 * se

* Add reference period at t = -1
local n = _N + 1
set obs `n'
replace event_time = -1 in `n'
replace coef_value = 0 in `n'
replace ci_lower = 0 in `n'
replace ci_upper = 0 in `n'
replace coef_name = "Reference" in `n'

* Sort again
sort event_time

* Create the balanced plot
twoway ///
    (rcap ci_upper ci_lower event_time if event_time != -1, ///
        lcolor(gs8) lwidth(medium)) ///
    (line coef_value event_time, ///
        lcolor(black) lwidth(thick) lpattern(solid)) ///
    (scatter coef_value event_time if event_time != -1, ///
        mcolor(black) mfcolor(black) msymbol(circle) msize(medium) mlwidth(medium)) ///
    (scatter coef_value event_time if event_time == -1, ///
        mcolor(black) mfcolor(white) msymbol(Oh) msize(large)), ///
    yline(0, lpattern(dash) lcolor(gs10) lwidth(medium)) ///
    xline(-0.5, lpattern(dot) lcolor(gs6) lwidth(medium)) ///
    title("Estimated Effect of CAPS on Homicide Rates", ///
        size(medium) color(black)) ///
    subtitle("Balanced Event Study (-5 to +3 years)", ///
        size(medsmall) color(black)) ///
    xtitle("Years relative to CAPS opening", ///
        size(medium)) ///
    ytitle("Treatment effect (homicides per 10,000)", ///
        size(medium)) ///
    xlabel(-5(1)3, labsize(medium)) ///
    ylabel(, labsize(medium) format(%3.1f)) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    xsize(8) ysize(6)

* Export the plot
graph export "./es_hrate_balanced.png", ///
    replace width(2400) height(1800)

di "SUCCESS: Balanced event study plot created!"
di "File saved: ./es_hrate_balanced.png"

restore

*------------------------------------------------------------
* Step 8: Sensitivity analysis (honestdid)
*------------------------------------------------------------

// Estimate the event study
csdid2 homicide_rate $controls, gvar(g) ivar(cod) time(ano) long2 method(drimp) notyet 
estat event, window(-4 5)
matlist e(b)

* Create l_vec for just Post_avg (1 coefficient)
matrix l_vec = J(1, 1, 1)

* Run honestdid and store results
honestdid, pre(3/5) post(2/2) mvec(0(0.25)2) delta(rm) ///
    l_vec(l_vec) b(e(b)) vcov(e(V))

* Extract the results from honestdid
mata: CI = `s(HonestEventStudy)'.CI
mata: st_matrix("CI_results", CI)

* Create dataset from the matrix
preserve
clear
svmat CI_results, names(col)
rename c1 M_value
rename c2 ci_lower  
rename c3 ci_upper

* Create midpoint for plotting
gen ci_mid = (ci_lower + ci_upper) / 2

* Create grayscale colors - darker for M=0, lighter as M increases
gen color_shade = ""
replace color_shade = "black" if M_value == 0        // Original (darkest)
replace color_shade = "gs4" if M_value == 0.25       // Very dark gray
replace color_shade = "gs6" if M_value == 0.5        // Dark gray  
replace color_shade = "gs8" if M_value == 0.75       // Medium gray
replace color_shade = "gs10" if M_value == 1         // Medium-light gray
replace color_shade = "gs12" if M_value == 1.25      // Light gray
replace color_shade = "gs13" if M_value == 1.5       // Lighter gray
replace color_shade = "gs14" if M_value == 1.75      // Very light gray
replace color_shade = "gs15" if M_value == 2         // Lightest gray

* Create the plot without legend but with proper attribution
twoway ///
    (rcap ci_upper ci_lower M_value, lcolor(gs15) lwidth(thick)) ///
    (rcap ci_upper ci_lower M_value if M_value == 1.75, lcolor(gs14) lwidth(thick)) ///
    (rcap ci_upper ci_lower M_value if M_value == 1.5, lcolor(gs13) lwidth(thick)) ///
    (rcap ci_upper ci_lower M_value if M_value == 1.25, lcolor(gs12) lwidth(thick)) ///
    (rcap ci_upper ci_lower M_value if M_value == 1, lcolor(gs10) lwidth(thick)) ///
    (rcap ci_upper ci_lower M_value if M_value == 0.75, lcolor(gs8) lwidth(thick)) ///
    (rcap ci_upper ci_lower M_value if M_value == 0.5, lcolor(gs6) lwidth(thick)) ///
    (rcap ci_upper ci_lower M_value if M_value == 0.25, lcolor(gs4) lwidth(thick)) ///
    (rcap ci_upper ci_lower M_value if M_value == 0, lcolor(black) lwidth(vthick)) ///
    (scatter ci_mid M_value if M_value == 0, ///
        mcolor(black) mfcolor(black) msymbol(D) msize(large) mlwidth(thick)), ///
    yline(0, lpattern(dash) lcolor(gs10) lwidth(medium)) ///
    title("Sensitivity Analysis: CAPS Effects on Homicide Rates", ///
        size(medium) color(black)) ///
    subtitle("Robustness of Post-Treatment Average to Parallel Trends Violations", ///
        size(medsmall) color(black)) ///
    xtitle("M (Maximum Violation Relative to Pre-Treatment)", ///
        size(medium)) ///
    ytitle("95% Robust Confidence Interval", ///
        size(medium)) ///
    xlabel(0(0.25)2, labsize(medium)) ///
    ylabel(, labsize(medium) format(%3.2f)) ///
    legend(off) ///
    note("Robust confidence intervals using Rambachan and Roth (2023) bounding method" ///
         "implemented in Stata honestdid package. Black diamond shows original estimate.", ///
         size(vsmall)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    xsize(8) ysize(6)
	
* Export the plot
graph export "./honestdid_sensitivity.png", ///
    replace width(2400) height(1800)

di "SUCCESS: Custom sensitivity plot created!"
di "File saved: ./honestdid_sensitivity.png"

restore

		   
		   
