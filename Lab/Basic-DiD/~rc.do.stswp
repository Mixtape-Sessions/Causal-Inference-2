********************************************************************************
* name: baker.do
* author: scott cunningham (baylor) adapting andrew baker (stanford)
* description: illustrate TWFE with differential timing and
*              heterogenous treatment effects over time
* last updated: jan 5, 2022
********************************************************************************

clear
capture log close
set seed 20200403

* 1,000 firms (25 per state) but not the same firms, 40 states, 4 groups (250 per groups), 30 years
* First create the states
set obs 40
gen state = _n

* Second create the years
expand 30
sort state
bysort state: gen year=_n
gen n=year
replace year = 1980 if year==1
replace year = 1981 if year==2
replace year = 1982 if year==3
replace year = 1983 if year==4
replace year = 1984 if year==5
replace year = 1985 if year==6
replace year = 1986 if year==7
replace year = 1987 if year==8
replace year = 1988 if year==9
replace year = 1989 if year==10
replace year = 1990 if year==11
replace year = 1991 if year==12
replace year = 1992 if year==13
replace year = 1993 if year==14
replace year = 1994 if year==15
replace year = 1995 if year==16
replace year = 1996 if year==17
replace year = 1997 if year==18
replace year = 1998 if year==19
replace year = 1999 if year==20
replace year = 2000 if year==21
replace year = 2001 if year==22
replace year = 2002 if year==23
replace year = 2003 if year==24
replace year = 2004 if year==25
replace year = 2005 if year==26
replace year = 2006 if year==27
replace year = 2007 if year==28
replace year = 2008 if year==29
replace year = 2009 if year==30
egen id =group(state)

* Finally generate 1000 firms.  These are in each state. So 25 per state. But different firms.
expand 25
bysort state year: gen firms=runiform(0,5)
egen firm=group(firms state year)
label variable firm "Unique firm identifier per state/year"

* Add 250 firms treated every period with the treatment effect still 7 on average
* Cohort years 1986, 1992, 1998, 2004
su state, detail
gen     group=0
replace group=1 if state<=`r(p25)'
replace group=2 if state>`r(p25)' & state<=`r(p50)'
replace group=3 if state>`r(p50)' & state<=`r(p75)'
replace group=4 if state>`r(p75)' & `r(p75)'!=.
gen     treat_date = 0 
replace treat_date = 1986 if group==1
replace treat_date = 1992 if group==2
replace treat_date = 1998 if group==3
replace treat_date = 2004 if group==4
gen     treat=0  
replace treat=1 if group==1 & year>=1986
replace treat=1 if group==2 & year>=1992
replace treat=1 if group==3 & year>=1998
replace treat=1 if group==4 & year>=2004

* Data generating process
gen e 	= rnormal(0,(0.5)^2)
gen te1 = rnormal(10,(0.2)^2) 
gen te2 = rnormal(8,(0.2)^2)
gen te3 = rnormal(6,(0.2)^2)
gen te4 = rnormal(4,(0.2)^2)
gen te = .

replace te = te1 if group == 1
replace te = te2 if group == 2
replace te = te3 if group == 3
replace te = te4 if group == 4

**************************************************************************************************
* Non-dynamic treatment effects.  Notice, the treatment effect is constant over time.
gen y2 = firms + n + te*treat + e 

* Data generating process with dynamic treatment effects over time
gen y = firms + n + te*treat*(year - treat_date + 1) + e 

** Estimation
* Estimation using TWFE - constant treatment effects
areg y2 treat, a(id) robust 

* Estimation using TWFE - dynamic treatment effects over time
areg y treat, a(id) robust 

**************************************************************************************************
* Demean all variables: y and treat within state (id)

foreach x of varlist y treat y2 {
		egen mean_`x' = mean(`x'), by(id)
		gen demean_`x' = `x' - mean_`x'
		drop mean*
		
}
areg y treat, a(id) robust
reg demean_y demean_treat, robust

areg y2 treat, a(id) robust 
reg demean_y2 demean_treat, robust






use https://github.com/scunning1975/mixtape/raw/master/sasp_panel.dta, clear
tsset id session
foreach x of varlist lnw age asq bmi hispanic black other asian schooling cohab married divorced separated age_cl unsafe llength reg asq_cl appearance_cl provider_second asian_cl black_cl hispanic_cl othrace_cl hot massage_cl 
drop if `x'==.
bysort id: gen s=_N
keep if s==4
foreach x of varlist lnw age asq bmi hispanic black other asian schooling cohab married divorced separated age_cl unsafe llength reg asq_cl appearance_cl provider_second asian_cl black_cl hispanic_cl  othrace_cl hot massage_cl 

egen mean_`x'=mean(`x'), by(id)
gen demean_`x'=`x' - mean_`x'
drop mean*

xi: reg lnw  age asq bmi hispanic black other asian schooling cohab married divorced separated age_cl unsafe llength reg asq_cl appearance_cl provider_second asian_cl black_cl hispanic_cl othrace_cl hot massage_cl, robust
xi: xtreg lnw  age asq bmi hispanic black other asian schooling cohab married divorced separated age_cl unsafe llength reg asq_cl appearance_cl provider_second asian_cl black_cl hispanic_cl othrace_cl hot massage_cl, fe i(id) robust
reg demean_lnw demean_age demean_asq demean_bmi demean_hispanic demean_black demean_other demean_asian demean_schooling demean_cohab demean_married demean_divorced demean_separated demean_age_cl demean_unsafe demean_llength demean_reg demean_asq_cl demean_appearance_cl demean_provider_second demean_asian_cl demean_black_cl demean_hispanic_cl demean_othrace_cl demean_hot demean_massage_cl, robust cluster(id)
