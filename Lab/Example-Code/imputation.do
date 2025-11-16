insheet using "https://raw.githubusercontent.com/hollina/stacked-did-weights/main/data/acs1860_unins_2008_2021.csv", clear
sum

gen untreated = adopt_year >= .
gen rel_year = -1
replace rel_year = year - adopt_year if adopt_year != .
gen treat = rel_year >= 0


* Manual
reg unins i.statefip i.year if treat == 0
predict y0_hat, xb
gen te_hat = unins - y0_hat

reg te_hat i.treat, nocons

gen rel_year_shifted = rel_year + 13
reg te_hat i.rel_year_shifted

* with did2s, for correct standard errors
did2s unins, first_stage(i.statefip i.year) second_stage(i.treat) treatment(treat) cluster(statefip)
did2s unins, first_stage(i.statefip i.year) second_stage(i.rel_year_shifted) treatment(treat) cluster(statefip)


