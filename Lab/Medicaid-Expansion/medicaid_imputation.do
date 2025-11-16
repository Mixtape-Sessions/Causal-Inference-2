* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
* Medicaid expansion on pct of county low-income residents who have health

* ssc install did2s
* ssc install coefplot
* ssc install eststore

clear all
use "Labs/Medicaid-Expansion/sahie_low_income_county_panel.dta", clear
sort fips year

* state doesn't allow i. with a variable that takes negative values (?)
gen rel_year_shift = rel_year + 15
egen fips_numeric = group(fips)

* Overall effect ----
did2s pct_insured_total, first_stage(i.year) second_stage(ib0.rel_year_shift) treatment(treat) cluster(fips_numeric) unit(fips)
coefplot, vertical


* e.g. rural/urban county event-study estimates
* did2s pct_insured_total, first_stage(i.year) second_stage(ib0.rel_year_shift#i.urban) treatment(treat) cluster(fips_numeric) unit(fips)

* Adding state-by-year time effects ----
egen census_region_numeric = group(census_region)
did2s pct_insured_total, first_stage(i.census_region_numeric#i.year) second_stage(ib0. rel_year_shift) treatment(treat) cluster(fips_numeric) unit(fips)
coefplot, vertical


* By gender ----
did2s pct_insured_male, first_stage(i.year) second_stage(ib0.rel_year_shift) treatment(treat) cluster(fips_numeric) unit(fips)
est store es_male

did2s pct_insured_female, first_stage(i.year) second_stage(ib0.rel_year_shift) treatment(treat) cluster(fips_numeric) unit(fips)
est store es_female

coefplot es_male es_female, vertical
