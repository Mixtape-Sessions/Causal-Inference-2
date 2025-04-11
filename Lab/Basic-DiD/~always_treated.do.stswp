clear
set seed 12345

// Step 1: Generate 1000 workers
set obs 1000
gen id = _n

// Generate fixed effects from Uniform(0,5)
gen fe = runiform()*5

// Step 2: Define treatment based on fixed effects
summ fe, detail
gen treat = (fe > r(p50))

// Step 3: Generate data for two years (1990,1991)
expand 2, generate(year)
replace year = 1990 + year

gen post = (year == 1991)

// Step 4: Potential outcomes Y0 and Y1
// At baseline (1990): Y0 = fixed effect
// At post-period (1991): Y1 = Y0 + 5
gen e=rnormal()
bys id: gen Y0 = fe + e
bys id: gen Y1 = Y0 + 5

// Step 5: Generate Y1_C for Constant Treatment Effects
// Control group at baseline: Y0
// Control group post: Y0 + 5
gen Y1_C = cond(post==0, Y0, Y0 + 5)

// Step 6: Delta_C = Y1_C - Y0
gen Delta_C = Y1_C - Y0

// Summarize Delta_C if treated and year==1991
summ Delta_C if post==1 & treat==1

// Step 7: Earnings_C (Switching Equation for Constant TE)
gen earnings_C = .
replace earnings_C = cond(treat==1, cond(post==0,Y0,Y1), cond(post==0,Y0+5,Y0+5))

// Step 8: Run the standard DiD regression with constant TE
reg earnings_C i.post##i.treat, robust

// ---- Now for Dynamic Treatment Effects ----

// Step 9: Generate Y1_D for Dynamic Treatment Effects
// Treatment group:
// baseline: Y0; post: Y0 + 5
// Control group:
// baseline: Y0 + 5; post: Y0 + 10

gen Y1_D = cond(treat==1, cond(post==0, Y0, Y0+5), cond(post==0, Y0+5, Y0+10))

// Step 10: Earnings_D (Switching Equation for Dynamic TE)
gen earnings_D = Y1_D

// Step 11: Run the standard DiD regression with dynamic TE
reg earnings_D i.post##i.treat, robust
