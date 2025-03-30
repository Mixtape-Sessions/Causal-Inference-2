*******************************************
* Stata Simulation: Conditional Parallel Trends
* Example: Effect of Title X clinics on birth rates
* Illustrating subtlety of choosing event-study baseline
*******************************************

clear all
set seed 12345

* Step 0a: CSDID Analysis
* ssc install csdid, replace
* ssc install drdid, replace

* Step 0b: Two-way fixed effects comparison (traditional)
* ssc install reghdfe, replace

* Step 1: Setup simulation parameters
set obs 500

gen county_id = _n

* Define urban (1) vs. rural (0)
gen urban = (runiform() < 0.5)

* Define treatment assignment (imbalanced, mostly urban)
gen treated = (urban==1 & runiform()<0.7) | (urban==0 & runiform()<0.3)
label variable treated "Title X County"

* Define treatment timing: treated counties treated at year 6, untreated = 0
gen treat_date = cond(treated, 6, 0)

* Expand to panel data (10 years)
expand 10
bysort county_id: gen year = _n

* Define pre/post treatment periods
gen post = (year >= 6)

* Step 2: Generate potential outcomes (Revised to shrink pre-trends)

* Smaller urban decline, nearly flat rural increase
bys county_id: gen trend = .
replace trend = -0.15*urban + 0.1*(1-urban) if year==1
replace trend = -0.25*urban + 0.1*(1-urban) if year==2
replace trend = -0.15*urban + 0.1*(1-urban) if year==3
replace trend = -0.1*urban + 0.1*(1-urban) if year==4
replace trend = -0.1*urban + 0.1*(1-urban) if year==5
replace trend = -0.5*urban + 0.1*(1-urban) if year==6
replace trend = -1*urban + 0.1*(1-urban) if year==7
replace trend = -1.5*urban + 0.1*(1-urban) if year==8
replace trend = -2*urban + 0.1*(1-urban) if year==9
replace trend = -2.5*urban + 0.1*(1-urban) if year==10

* Generate county-level fixed effects (increasing cross-sectional variance)
bys county_id: gen county_fe = rnormal(0, 2)

* Declare panel before generating serial correlation
xtset county_id year

* Generate serially correlated errors within counties
gen u = .
bys county_id: replace u = rnormal(0, 1) if year==1
bys county_id: replace u = 0.7*u[_n-1] + rnormal(0, 1) if year>1

* Potential outcome y0 now includes county FE and serially correlated errors
bys county_id: gen y0 = 15 + county_fe + trend*(year) + u

* Clearly positive treatment effect
gen y1 = y0 + post*treated*(year - 5)*0.6

* Observed outcome
gen birth_rate = treated*y1 + (1-treated)*y0

* Long-gap: baseline fixed at T-1
csdid birth_rate, ivar(county_id) time(year) long2 gvar(treat_date) 
csdid_estat event
csdid_plot, title("Long-gap (T-1 baseline): Event Study")

* Step 4: Adding urban covariate
csdid birth_rate urban, ivar(county_id) time(year) method(dripw) gvar(treat_date) long2
csdid_estat event
csdid_plot, title("Long-gap w/ urban covariate: Event Study")




capture log close
exit

