* Checklist using CS

clear 
capture log close
* ssc install panelview
* ssc install csdid, replace
* ssc install drdid, replace
* ssc install honestdid, replace

* 1. Define the target paramter
* 2. Make a table of when units are treated
* 3. Plot the treatment rollout
* 4. Pick your control group
* 5. Pick covariates
* 6. Check covariate imbalance
* 7. Plot the average outcomes over time per treatment group (and never treated group)
* 8. Estimator (e.g., TWFE, CS, SA, etc)
* 9. Sensitivity analysis (honest diff in diff)
* 10. Don't do diff in diff

use https://github.com/scunning1975/mixtape/raw/master/castle.dta, clear
xtset sid year

* Step 1: define the target parameter. For diff in diff, there's really only one choice to make.  Will you weight by population or not? Do I want to know the effect of this gun law on the average person (which means that large states will be more influential than small ones) or do I want to know the effect on the averate state? I'm going to do try to estimate BOTH the average treatment effect on the treated groups for the average person (weight by state population) AND the average treatment effect on the average state (don't weight by state population). That is TWO SEPARATE TARGET PARAMETERS, and rememeber, they don't have to be the same number. 

* Step 2: make a table of when units are treated. 

gen 	treat_date = effyear
replace treat_date = 0 if effyear==.
label variable treat_date "Timing Group Treatment Date (never-treated is zero)"

ta treat_date if year==2000

gen 	treat=0
replace treat=1 if year>=effyear

* Generate a variable indicating that they will "ever be treated"
gen 	ever_treat = 0
replace ever_treat = 1 if effyear~=.


* Step 3. Plot the treatment rollout. Stata helpfile here:  https://yiqingxu.org/packages/panelview_stata/Stata_tutorial.pdf
panelview l_homicide treat, prepost bytiming i(state) t(year) type(treat) xtitle("Year") title("Rollout of Castle Doctrine Law") ylabel(none) legend(label(1 "Never Treated") label(2 "Treated (Pre)") label(3 "Treated(Post)"))


/* Step 4. Picking covariates and we will start with these:

police unemployrt income blackm_15_24 whitem_15_24 blackm_25_44 whitem_25_44 prisoner lagprisoner poverty exp_subsidy exp_pubwelfare northeast midwest south west

*/

* Step 5. Create a covariate imbalance table using that Imbens and Rubin (2015) rule, as well as Baker, Callaway, Cunningham, Goodman-Bacon and Sant'Anna JEL "Practitioner's Guide" which says if the normalized difference in means between the treatment and control group is greater than 0.25 in absolute value, there is "problematic imbalance in that covariate" and you may need to control for it. Our treatments start in 2005, then is each year after for different groups, so I am going to create an imbalance table for 2004 covariates.

/*********************************************************************/
/*    Covariate Balance Table - Baseline Year 2004 (Clean Version)  */
/*********************************************************************/

*---------------------------------------------------------------------
* Define covariates
*---------------------------------------------------------------------
local covs police unemployrt income blackm_15_24 whitem_15_24 ///
           blackm_25_44 whitem_25_44 prisoner lagprisoner poverty ///
           exp_subsidy exp_pubwelfare northeast midwest south west

*---------------------------------------------------------------------
* Create the balance table
*---------------------------------------------------------------------
preserve
    keep if year == 2004
    
    * Create empty results matrix
    matrix results = J(16, 3, .)
    matrix colnames results = "Control_Mean" "Treated_Mean" "Norm_Diff"
    
    local i = 1
    foreach var of local covs {
        * Get means by group
        quietly sum `var' if ever_treat==0 // unweighted
        local mean0 = r(mean)
        quietly sum `var' if ever_treat==1  // unweighted (if weighted then [aw=population])
        local mean1 = r(mean)
        
        * Get standard deviations by group
        quietly sum `var' if ever_treat==0
        local sd0 = r(sd)
        quietly sum `var' if ever_treat==1
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
    matrix rownames results = `covs'
    
    * Display the table
    matrix list results, format(%9.3f)
    
restore

/* Covariates imbalanced for unweighted:

police (0.279)
unemployrt (0.484)
income (-1.486)
prisoner (0.940)
lagprisoner (0.924)
poverty (1.260)
exp_pubwelfare (-0.253)
northeast (-0.932)
midwest (0.369)
south (0.776)
west (-0.474)

So I will control for those

*/

global controls "police unemployrt income prisoner lagprisoner poverty exp_pubwelfare midwest south west"

* Step 6: Plot average l_homicide for treatment cohorts

preserve

collapse (mean) l_homicide, by(treat_date year)
xtset treat_date year

* Create separate variables for each treatment group  
separate l_homicide, by(treat_date) gen(yr)

* Create individual plots for each cohort
foreach t in 0 2005 2006 2007 2008 2009 {
    if (`t' == 0) {
        local label "never treated"
        local rline 0
    }
    else {
        local label "`t' cohort" 
        local rline `t'
    }
    local linecolor = cond(`t' == 0, "blue", "blue")
    
    scatter yr* year, recast(line) lc(gs12 ...) lp(solid ...) ///
        legend(off) || line l_homicide year if treat_date == `t', ///
        lc(`linecolor') lp(solid) lw(medthick) xtitle("") subtitle("`label'") ///
        name(plot_`t', replace) ///
        xline(`rline', lcolor(red) lpattern(dash)) ///
        xlabel(2000(1)2010, labsize(small)) ///
        xscale(range(2000 2010)) ///
        ylabel(, angle(0) labsize(small))
}

* Combine all plots
graph combine plot_0 plot_2005 plot_2006 plot_2007 plot_2008 plot_2009, ///
    title("Average Log Homicides by Cohort") ///
    subtitle("per 100,000") ///
    ysize(8) xsize(8) ///
    scale(0.9)
    
graph export "./ln_homicides_plots.png", as(png) name("Graph") replace width(2000)

restore

* Step 8: Estimator. We are going to use CS.  I am estimating the ATT for the average US state which means I will *not* be weighting by population (though others can do that -- it just will be a different parameter with a different interpretation with a different parallel trend assumption).  I'm going to make two things: a simple ATT and an event study and my covariates will be:

xtset sid year

global controls "police unemployrt income prisoner lagprisoner poverty exp_pubwelfare midwest south west"

csdid l_homicide $controls, gvar(treat_date) ivar(sid) time(year) long2 method(drimp) wboot reps(1000) notyet rseed(1)

csdid_estat simple

* we have some thing weird going on with these covariates because when we include all these covariates, like 90% of the ATTs are not estimated. And we went one by one, and one by one, it's fine, but when we did all the regionals and one continuous covariate, then we started losing.  So we are going to plot propensity scores for 2004.

* Attempt #1 -- fail.
preserve
keep if year==2004

logit ever_treat $controls
predict propensity_score
label variable propensity_score "Propensity score"
	
twoway (kdensity propensity_score if ever_treat==1,  color(red)) ///
       (kdensity propensity_score if ever_treat==0,  ///
	   fcolor(none) lcolor(black)), legend(order(1 "Treated" 2 "Not treated" ))
	   
twoway (histogram propensity_score if ever_treat==1,  color(red)) ///
       (histogram propensity_score if ever_treat==0,  ///
	   fcolor(none) lcolor(black)), legend(order(1 "Treated" 2 "Not treated" ))
	   
bysort ever_treat: su propensity_score, detail

su propensity_score if ever_treat==1 // treatment group 
count if propensity_score>=`r(min)' & ever_treat==0 // control group
	   

* Unfortunately, even though I think I need those covariates as controls, CS cannot accomodate them because of the lack of common support in my propensity score, and if you recall, one of the four assumptions in CS was "common support" and I currently do not have it. So I am going cheat a little. I am going to "coarsen" the covariates and see if that helps.  But technically, all I've done is made units have similar covariates by taking giant blocks of those covariate values. 

restore

* Attempt 2: all the covariates that are continuous I will discretize into quartiles (25th, 50th, 75th percentile)

* POLICE
xtile police_q = police, nq(4) 
ta police_q, gen(police_q)

* UNEMPLOYMENT
xtile unemployrt_q = unemployrt, nq(4) 
ta unemployrt_q, gen(unemployrt_q)

* INCOME
xtile income_q = income, nq(4) 
ta income_q, gen(income_q)

* PRISONER
xtile prisoner_q = prisoner, nq(4)
ta prisoner_q, gen(prisoner_q)

* LAGPRISONER
xtile lagprisoner_q = lagprisoner, nq(4) 
ta lagprisoner_q, gen(lagprisoner_q)

* POVERTY
xtile poverty_q = poverty, nq(4) 
ta poverty_q, gen(poverty_q)

* EXP_PUBWELFARE
xtile exp_pubwelfare_q = exp_pubwelfare, nq(4) 
ta exp_pubwelfare_q, gen(exp_pubwelfare_q)

global coarsened_controls ///
police_q1 police_q2 police_q3 unemployrt_q1 unemployrt_q2 unemployrt_q3 income_q1 income_q2 income_q3 prisoner_q1 prisoner_q2 prisoner_q3 lagprisoner_q1 lagprisoner_q2 lagprisoner_q3 poverty_q1 poverty_q2 poverty_q3 exp_pubwelfare_q1 exp_pubwelfare_q2 exp_pubwelfare_q3 	   
	   
	   
* Now we see if CS "works", but "works" does not mean I like the results. For us, "works" means NO Xs. But first let's see how we did on the propensity score -- remember our propensity score before had so many continuous variables (we think this was it anyway) that we only had 4 control group observations with more propensity score values than the minimum in the treatment group. Let's see what it is now.

preserve
keep if year==2004

logit ever_treat $coarsened_controls
predict propensity_score
label variable propensity_score "Propensity score"
	
twoway (kdensity propensity_score if ever_treat==1,  color(red)) ///
       (kdensity propensity_score if ever_treat==0,  ///
	   fcolor(none) lcolor(black)), legend(order(1 "Treated" 2 "Not treated" ))
	   
twoway (histogram propensity_score if ever_treat==1,  color(red)) ///
       (histogram propensity_score if ever_treat==0,  ///
	   fcolor(none) lcolor(black)), legend(order(1 "Treated" 2 "Not treated" ))
	   
bysort ever_treat: su propensity_score, detail

su propensity_score if ever_treat==1
count if propensity_score>=`r(min)' & ever_treat==0
	   
restore

* Attempt 3: parsimoniously chosen yet TONS of researcher degrees of freedom and discretion so we are as a group a teeny bit anxious about this.  and not int toal agreement. 


preserve
keep if year==2004
global democracy_controls "unemployrt income police"

logit ever_treat $democracy_controls

predict propensity_score
label variable propensity_score "Propensity score"
	
twoway (kdensity propensity_score if ever_treat==1,  color(red)) ///
       (kdensity propensity_score if ever_treat==0,  ///
	   fcolor(none) lcolor(black)), legend(order(1 "Treated" 2 "Not treated" ))
	   
twoway (histogram propensity_score if ever_treat==1,  color(red)) ///
       (histogram propensity_score if ever_treat==0,  ///
	   fcolor(none) lcolor(black)), legend(order(1 "Treated" 2 "Not treated" ))
	   
bysort ever_treat: su propensity_score, detail

su propensity_score if ever_treat==1
count if propensity_score>=`r(min)' & ever_treat==0

restore


* Attempt 3: Claude

/*
Most Important/Strong Associations:
Police - Wilson would emphasize this heavily given his "broken windows" theory and belief in deterrence effects. The literature generally shows negative correlation with crime, though causality is debated.
Prisoner/Lagprisoner - Both would cite this as crucial. The incapacitation effect was well-established by 2000-2010, with estimates that each additional prisoner prevents 2-5 crimes annually. Donohue's work on abortion and crime also emphasized incarceration's role.
Blackm_15_24 - Unfortunately, both would acknowledge this as one of the strongest demographic predictors. Young males aged 15-24 have the highest offending rates, and this was a key variable in Donohue's abortion-crime research.
Unemployrt - Mixed but important. Wilson might be more skeptical given weak empirical relationships in some studies, but Donohue would likely include it given economic theories of crime.

*/

drop *_q*

preserve
keep if year==2004

global claude "unemployrt police blackm_15_24 whitem_15_24 prisoner"

logit ever_treat $claude

predict propensity_score
label variable propensity_score "Propensity score"
	
twoway (kdensity propensity_score if ever_treat==1,  color(red)) ///
       (kdensity propensity_score if ever_treat==0,  ///
	   fcolor(none) lcolor(black)), legend(order(1 "Treated" 2 "Not treated" ))
	   
twoway (histogram propensity_score if ever_treat==1,  color(red)) ///
       (histogram propensity_score if ever_treat==0,  ///
	   fcolor(none) lcolor(black)), legend(order(1 "Treated" 2 "Not treated" ))
	   
bysort ever_treat: su propensity_score, detail

su propensity_score if ever_treat==1
count if propensity_score>=`r(min)' & ever_treat==0

restore

* POLICE
xtile police_q = police, nq(2) 
ta police_q, gen(police_q)

* PRISONER
xtile prisoner_q = prisoner, nq(2) 
ta prisoner_q, gen(prisoner_q)

* YOUTH
xtile blackm_15_24_q = blackm_15_24, nq(2) 
ta blackm_15_24_q, gen(blackm_15_24_q)

xtile whitem_15_24_q = whitem_15_24, nq(2) 
ta whitem_15_24_q, gen(whitem_15_24_q)

* UNEMPLOYMENT
xtile unemployrt_q  = unemployrt , nq(2) 
ta unemployrt_q, gen(unemployrt_q)

* URL for google sheet: https://docs.google.com/spreadsheets/d/1dQ6Cx7FGLpA5IqK6Pkpaa1FtLko684oDYNq4AFuIYMw/edit?usp=sharing

* URL for google doc:
* https://docs.google.com/document/d/1O43WJws4LiDcQqplpFx2ywFGfW3ZDQYkLLSLc_7ke1k/edit?usp=sharing

* Scott:

csdid l_homicide police_q2 prisoner_q2 blackm_15_24_q2  unemployrt_q2, gvar(treat_date) ivar(sid) time(year) long2 method(drimp) wboot reps(1000) notyet rseed(1)

csdid_estat simple
csdid_estat group
csdid_estat event

csdid_plot, ///
    title("Effect of Castle Doctrine Law on Ln(Homicides)") ///
    subtitle("Controls and Long Differences") ///
note("Note: Uses the not-yet-treated as controls, with three covariates -- above median police, above  " ///
     "median black male youth, above median white male youth, above median unemployment rates." ///
	 "Circles are ATT(g,t) estimates by relative event time. All groups and bands are 95% uniform" ///
	 " confidence intervals. Mean ln(homicide rate) was approximately 1.67 in 2004 for the ever-treated" ///
	 "states in 2000.") ///
    xtitle("Relative Years Before and After Law Change") ///
    ytitle("Estimated average treatment effects") ///
    style(rspike) ///
    xlabel(, labsize(small)) ///
    ylabel(, labsize(small) angle(0)) ///
    xscale(titlegap(*1.5)) ///
    yscale(titlegap(*1.5))

graph export "./cs_homicides.png", as(png) name("Graph")	replace


