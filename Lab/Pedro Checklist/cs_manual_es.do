* cs_manual_es.do
* ssc install regsave

*set T and g
local T = 20
local g = 10
local pre = -(`T'-(`g'+1))
local post = (`g'+1)
clear
set obs `T'
gen time = _n
expand 2
bys time: gen unit = _n
gen g = `g'*(unit==2)
gen y = time + time*(unit==2) + (time-4)*(unit==2)*(time>=`g') + rnormal()
*a plot of the levels: obvious pre-trends
twoway line y time if unit==1 || line y time if unit==2
preserve
csdid y, ivar(unit) time(time) gvar(g) 			notyet
estat event, window(`pre',`post') post 
	*keep output in a Stata file to manipulate and prepare for graphing
	regsave
	keep if substr(var,1,1)=="T"
	gen pre = substr(var,2,1)=="m"
	destring var, ignore("T" "m" "p") gen(exp)
	*set pre-period times to negative
	replace exp = -exp if pre
	keep if coef<.
	keep coef exp
	order exp coef
	ren coef ddshort
	sort exp
	save long2bs, replace
restore
preserve
csdid y, ivar(unit) time(time) gvar(g) long 	notyet
estat event, window(`pre',`post') post 
	*keep output in a Stata file to manipulate and prepare for graphing
	regsave
	keep if substr(var,1,1)=="T"
	gen pre = substr(var,2,1)=="m"
	destring var, ignore("T" "m" "p") gen(exp)
	*set pre-period times to negative
	replace exp = -exp if pre
	**long still gives "Tm1" to the first pre-coef, which actually comes at event-time -2
	replace exp = exp-1 if exp<0
	*add a zero for the omitted period. 
	count
	local obs = r(N) + 1
	set obs `obs'
	replace exp = -1 in `obs'
	for var coef*: replace X = 0 in `obs'
	keep if coef<.
	keep coef exp
	order exp coef
	ren coef ddlong
	sort exp
	merge 1:1 exp using long2bs
	drop _merge
	save long2bs, replace
restore
preserve
csdid y, ivar(unit) time(time) gvar(g) long2 	notyet
estat event, window(`pre',`post') post 
	*keep output in a Stata file to manipulate and prepare for graphing
	regsave
	keep if substr(var,1,1)=="T"
	gen pre = substr(var,2,1)=="m"
	destring var, ignore("T" "m" "p") gen(exp)
	*set pre-period times to negative   	**long2 labels the pre-period times correctly
	replace exp = -exp if pre
	*add a zero for the omitted period. 
	count
	local obs = r(N) + 1
	set obs `obs'
	replace exp = -1 in `obs'
	for var coef*: replace X = 0 in `obs'
	keep if coef<.
	keep coef exp
	order exp coef
	ren coef ddlong2
	sort exp
	merge 1:1 exp using long2bs
	drop _merge
	save long2bs, replace
restore
*now get things totally by hand and plot
gen exp = time-`g'
drop unit time
reshape wide y, i(exp) j(g)
gen d = y`g'-y0
qui sum d if exp==-1
gen dd = d - r(mean)
merge 1:1 exp using long2bs
drop _merge
scatter dd ddshort ddlong ddlong2 exp, msym(o i i i i ) c(n l l l l ) legend(order(1 2 3 4) label(1 "By Hand, -1 reference") label(2 "short") label(3 "long") label(4 "long2")) xline(-1)
