********************************************************************************
* name: na.do
* author: scott cunningham (baylor) adapting andrew baker (stanford)
* description: illustrate TWFE with differential timing and
*              heterogenous treatment effects over time
* last updated: jan 5, 2022
********************************************************************************

clear
capture log close
set seed 20200403

* 1,000 firms (25 per state), 40 states, 4 groups (250 per groups), 30 years
* First create the states
set obs 40
gen state = _n

* Finally generate 1000 firms.  These are in each state. So 25 per state.
expand 25
bysort state: gen firms=runiform(0,5)
label variable firms "Unique firm fixed effect per state"

* Second create the years
expand 4
sort state
bysort state firms: gen year = _n
gen n=year

replace year = 1990 if year==1
replace year = 1991 if year==2
replace year = 1992 if year==3
replace year = 1993 if year==4
egen id =group(state firms)

* Treatment group is upper half
gen     group=0
replace group=1 if id >= 500

* Correct start date so that NA is satisfied
gen     post=0  
replace post=1 if year >= 1991

* Incorrect start date so that NA is violated
gen 	post_na=0
replace post_na=1 if year>=1992

* Data generating process
gen e 	= rnormal(0,1)

* Potential outcomes
gen 	y0 = firms + n + e 

* Constant treatment effects
gen 	y1_c = y0
replace y1_c = y0 + 10 if year>=1991

* dynamic treatment effects
gen 	y1_d = y0 
replace y1_d = y0 + 10 if year==1991
replace y1_d = y0 + 20 if year==1992
replace y1_d = y0 + 30 if year==1993

* Treatment effects
gen 	delta_c = y1_c - y0
gen 	delta_d = y1_d - y0

su delta_c if year>=1991 & group==1
su delta_d if year>=1991 & group==1

* Treatment period
gen 	d = 0
replace d = 1 if year>=1991 & group==1

* Switching equation for constant
gen 	y_c = d*y1_c + (1-d)*y0
gen 	y_d = d*y1_d + (1-d)*y0

* Aggregate causal parameters
egen att_c = mean(delta_c) if year>=1991 & group==1

egen att_d = mean(delta_d) if year>=1991 & group==1

su att_c att_d

* Correct specification
regress y_c group##post, robust // did = 10
regress y_d group##post, robust // did = 20

* Incorrect specification
regress y_c group##post_na if year>=1991, robust // did = 0
regress y_d group##post_na if year>=1991, robust // did = 15




