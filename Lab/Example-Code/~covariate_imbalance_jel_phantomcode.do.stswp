/*********************************************************************/
/*  Covariate-balance table   (Baker Table 4, Stata version)         */
/*********************************************************************/
cap mkdir "Tables"

/*--------------------------------------------------------------------
   0.  Convenience locals
--------------------------------------------------------------------*/
local covs perc_female perc_white perc_hispanic ///
           unemp_rate poverty_rate median_income_k

*--------------------------------------------------------------------
* 1.  2013 levels — unweighted means, SDs, and normalised diff
*--------------------------------------------------------------------
preserve
    keep if year == 2013

    *---- means and SDs in a single collapse -----------------------
    collapse (mean)  `covs'                                   ///
             (sd)    sd_female  = perc_female                 ///
                     sd_white   = perc_white                  ///
                     sd_hisp    = perc_hispanic               ///
                     sd_unemp   = unemp_rate                  ///
                     sd_pov     = poverty_rate                ///
                     sd_income  = median_income_k,            ///
             by(Treat)

*---- rename means with m-prefix, then add an ID --------------------
foreach v of varlist `covs' {
    rename `v' m`v'
}

generate byte id = 1          // same value for both rows (Treat 0/1)

*---- reshape into one wide row -------------------------------------
reshape wide m* sd_*, i(id) j(Treat)
drop id                       // no longer needed

*---- normalised differences ----------------------------------
*  map:  perc_female→female,  perc_white→white, …
local covs     perc_female perc_white perc_hispanic ///
               unemp_rate  poverty_rate median_income_k
local sdstems  female      white       hisp            ///
               unemp       pov         income

tokenize `covs'
local i = 1
while "`1'" != "" {
    local v  `1'
    local sd : word `i' of `sdstems'
    gen nd_`v' = (m`v'1 - m`v'0) / ///
                 sqrt( (sd_`sd'1^2 + sd_`sd'0^2) / 2 )
    macro shift
    local ++i
}

    keep m* nd_*                    // single-row dataset
    tempfile unwt_pre
    save `unwt_pre'
restore



/*--------------------------------------------------------------------
   2.  2013 levels — weighted
--------------------------------------------------------------------*/
preserve
    keep if year == 2013

    /* weighted means & *population* variances ---------------------- */
    foreach v of local covs {
        gen wm_`v' = .
        gen wv_`v' = .
        levelsof Treat, local(T)
        foreach g of local T {
            qui summarize `v' [aw = set_wt] if Treat == `g'
            scalar mu   = r(mean)
            scalar varp = r(Var)
            replace wm_`v' = mu   if Treat == `g'
            replace wv_`v' = varp if Treat == `g'
        }
    }

    collapse (first) wm_* wv_*, by(Treat)

    /* rename:  wm_*  →  wm...   (means) 
                 wv_*  →  ws...   (variances)  */
    foreach v of varlist wm_* wv_* {
        local stem = substr("`v'", 4, .)
        if substr("`v'",1,2) == "wm" rename `v' wm`stem'
        else                       rename `v' ws`stem'
    }

    /* reshape to one wide row ------------------------------------- */
    generate byte id = 1
    reshape wide wm* ws*, i(id) j(Treat)
    drop id

    /* weighted normalised differences ----------------------------- */
    foreach v of local covs {
        gen wnd_`v' = (wm`v'1 - wm`v'0) / sqrt( (ws`v'1 + ws`v'0) / 2 )
    }

    keep wm* wnd_*                          // one-row dataset
    tempfile wtd_pre
    save `wtd_pre'
restore



/********************************************************************
* 3.  Weighted long differences 2014–2013
********************************************************************/
preserve
    keep year countycode Treat set_wt `covs'
    reshape wide `covs', i(countycode Treat) j(year)

    foreach v of local covs {
        gen d_`v' = `v'2014 - `v'2013
    }

    /* weighted means & variances of the ∆'s ------------------------ */
    foreach v of local covs {
        gen wmd_`v' = .
        gen wsd_`v' = .
        levelsof Treat, local(T)
        foreach g of local T {
            qui summarize d_`v' [aw = set_wt] if Treat == `g'
            scalar mu   = r(mean)
            scalar varp = r(Var)
            replace wmd_`v' = mu   if Treat == `g'
            replace wsd_`v' = varp if Treat == `g'
        }
    }

    collapse (first) wmd_* wsd_*, by(Treat)

    /* wmd_* → wmd…   (mean Δ)   |   wsd_* → wsd…   (var Δ) -------- */
    foreach v of varlist wmd_* wsd_* {
        local stem = substr("`v'",4,.)
        if substr("`v'",1,3) == "wmd" rename `v' wmd`stem'
        else                       rename `v' wsd`stem'
    }

    generate id = 1
    reshape wide wmd* wsd*, i(id) j(Treat)
    drop id

	/* weighted normalised differences for Δ's -------------------------- */
	foreach v of local covs {
    gen wnd_d`v' = (wmd_`v'1 - wmd_`v'0) /                                 ///
                   sqrt( (wsd_`v'1 + wsd_`v'0) / 2 )
	}
    keep wmd* wnd_d*
    tempfile wtd_diff
    save `wtd_diff'
restore

/********************************************************************
* 3a.  UN-weighted long differences 2014–2013
********************************************************************/
preserve
    keep countycode year Treat `covs'
	
    reshape wide `covs', i(countycode Treat) j(year)

    foreach v of local covs {
        gen d_`v' = `v'2014 - `v'2013
    }

    /* ---- un-weighted panel ------------------------------------ */
    collapse                                                    ///
        (mean) d_perc_female      d_perc_white      d_perc_hispanic ///
               d_unemp_rate       d_poverty_rate    d_median_income_k ///
        (sd)   sd_dfemale = d_perc_female                          ///
               sd_dwhite  = d_perc_white                           ///
               sd_dhisp   = d_perc_hispanic                        ///
               sd_dunemp  = d_unemp_rate                           ///
               sd_dpov    = d_poverty_rate                         ///
               sd_dincome = d_median_income_k,                     ///
        by(Treat)
		
    foreach v of local covs {
        rename d_`v'  md`v'
    }
	
    generate byte id = 1
    reshape wide md* sd_d*, i(id) j(Treat)
    drop id

	/* normalised differences (un-weighted long-diffs) */
	local covs     perc_female perc_white perc_hispanic ///
               unemp_rate  poverty_rate median_income_k
	local sdstems  dfemale     dwhite      dhisp           ///
               dunemp      dpov        dincome

	tokenize `covs'
	local i = 1
	while "`1'" != "" {
		local v  `1'
		local sd : word `i' of `sdstems'
		gen nd_d`v' = (md`v'1 - md`v'0) / ///
                  sqrt( (sd_`sd'1 + sd_`sd'0) / 2 )
		macro shift
		local ++i
	}

    keep md* nd_d*
    tempfile unwt_diff
    save `unwt_diff'
restore


/*--------------------------------------------------------------------
   4.  Assemble the four blocks into one matrix
--------------------------------------------------------------------*/
use `unwt_pre',     clear
merge 1:1 _n using `wtd_pre',   nogen   // adds mw*  sw*  wnd_*
merge 1:1 _n using `unwt_diff', nogen   // adds md*  nd_d*
merge 1:1 _n using `wtd_diff',  nogen   // adds mwd* swd* wnd_d_*

de,f

* -- reorder (purely cosmetic) --------------------------------------
order  mperc_female*   wmperc_female*   wmd_perc_female* ///
       mperc_white*    wmperc_white*    wmd_perc_white*  ///
       mperc_hispanic* wmperc_hispanic* wmd_perc_hispanic* ///
       munemp_rate*    wmunemp_rate*    wmd_unemp_rate*  ///
       mpoverty_rate*  wmpoverty_rate*  wmd_poverty_rate* ///
       mmedian_income_k* wmmedian_income_k* wmd_median_income_k*
	   
* ---- row labels ----------------------------------------------------
local rowlbl  "% Female" "% White" "% Hispanic" ///
              "Unemployment Rate" "Poverty Rate" "Median Income"
local outrows
local i = 1
foreach v in perc_female perc_white perc_hispanic ///
             unemp_rate poverty_rate median_income_k {
    local outrows `"`outrows' `"`:word `i' of `rowlbl''"'"'
    local ++i
}

/* ---- build the 12 × 6 matrix ----------------------------------- */
matrix T = J(12,6,.)
local r 0
foreach v of local covs {
    local ++r
    * rows 1–6 : 2013 levels
    matrix T[`r',1] = m`v'0[1]          // un-wtd mean, Non-adopt
    matrix T[`r',2] = m`v'1[1]          // un-wtd mean, Adopt
    matrix T[`r',3] = nd_`v'[1]         // un-wtd norm-diff
    matrix T[`r',4] = wm`v'0[1]         // wtd mean,  Non-adopt
    matrix T[`r',5] = wm`v'1[1]         // wtd mean,  Adopt
    matrix T[`r',6] = wnd_`v'[1]        // wtd norm-diff
}

foreach v of local covs {
    local ++r
    * rows 7–12 : 2014–2013 long-differences
    matrix T[`r',1] = md`v'0[1]         // un-wtd ∆, Non-adopt
    matrix T[`r',2] = md`v'1[1]         // un-wtd ∆, Adopt
    matrix T[`r',3] = nd_d`v'[1]        // un-wtd norm-diff
    matrix T[`r',4] = wmd_`v'0[1]       // **underscore added**
    matrix T[`r',5] = wmd_`v'1[1]       // **underscore added**
    matrix T[`r',6] = wnd_d`v'[1]       // wtd norm-diff
}

matrix rownames T = `outrows' `outrows'
matrix colnames T = "Non-Adopt" "Adopt" "Norm. Diff." ///
                    "Non-Adopt" "Adopt" "Norm. Diff."
					
*--------------------------------------------------------------------
* 5.  Send to LaTeX via esttab
*--------------------------------------------------------------------

/* 1.  Give the matrix nice, final row-names ------------------------ */
matrix rownames T = ///
"\% Female" "\% White" "\% Hispanic" ///
"Unemployment Rate" "Poverty Rate" "Median Income" ///
"\% Female $\Delta$" "\% White $\Delta$" "\% Hispanic $\Delta$" ///
"Unemployment Rate $\Delta$" "Poverty Rate $\Delta$" "Median Income $\Delta$"

local rowname : word `=`i'-6' of ///
  "\% Female $\Delta$" "\% White $\Delta$" "\% Hispanic $\Delta$" ///
  "Unemployment Rate $\Delta$" "Poverty Rate $\Delta$" "Median Income $\Delta$"
  
  
/* 2.  LaTeX header / footer strings (single compound quote each) -- */
local prehead  "\begin{tabular}{l*{6}{c}} \\hline\\hline " ///
               "\multicolumn{7}{c}{\textit{2013 Covariate Levels}} \\\\"
local posthead "\hline"
local prefoot  "\hline \multicolumn{7}{c}{\textit{2014 -- 2013 Covariate Differences}} \\\\ \hline"
local postfoot "\hline\hline \end{tabular}"

/* 3.  esttab -------------------------------------------------------- */
esttab matrix(T) using "Tables/cov_balance_sc.tex", replace           ///
      title("Covariate Balance Statistics")                          ///
      fragment booktabs nomtitles label                              ///
      mgroups("Unweighted" "Weighted", pattern(1 1 1 1 1 1) span)    ///
      cells("b(fmt(%6.2f))")                                         ///  <-- two decimals everywhere
      nonumber noobs alignment(c) incelldelimiter("")                ///
      prehead(`"`prehead'"')   posthead(`"`posthead'"')              ///
      prefoot(`"`prefoot'"')   postfoot(`"`postfoot'"')

display "✓  LaTeX covariate-balance table written to Tables/cov_balance_sc.tex"


*--------------------------------------------------------------------
* 5.  Write LaTeX manually via file write
*--------------------------------------------------------------------

* Open LaTeX file
file open tableout using "Tables/cov_balance_sc.tex", write replace
file write tableout "\begin{tabular}{l*{6}{c}} \\" _n
file write tableout "\hline\hline" _n
file write tableout "\multicolumn{7}{c}{\textit{2013 Covariate Levels}} \\" _n
file write tableout "& \multicolumn{3}{c}{Unweighted} & \multicolumn{3}{c}{Weighted} \\" _n
file write tableout "Variable & Non-Adopt & Adopt & Norm. Diff. & Non-Adopt & Adopt & Norm. Diff. \\" _n
file write tableout "\hline" _n

* Write first 6 rows (2013 Levels)
forvalues i = 1/6 {
    local rowname : word `i' of ///
        "\% Female" "\% White" "\% Hispanic" ///
        "Unemployment Rate" "Poverty Rate" "Median Income"
    
    local line "`rowname'"
    
    forvalues j = 1/6 {
        local val = T[`i', `j']
        local val_fmt : display %4.2f `val'
        local line "`line' & `val_fmt'"
    }
    
    file write tableout "`line' \\" _n
}

file write tableout "\hline" _n
file write tableout "\multicolumn{7}{c}{\textit{2014 -- 2013 Covariate Differences}} \\" _n

* Write last 6 rows (Differences)
forvalues i = 7/12 {
    local rowname : word `=`i'-6' of ///
        "\% Female ($\Delta$)" "\% White ($\Delta$)" "\% Hispanic ($\Delta$)" ///
        "Unemployment Rate ($\Delta$)" "Poverty Rate ($\Delta$)" "Median Income ($\Delta$)"
    
    local line "`rowname'"
    
    forvalues j = 1/6 {
        local val = T[`i', `j']
        local val_fmt : display %4.2f `val'
        local line "`line' & `val_fmt'"
    }

    file write tableout "`line' \\" _n
}

* Close table
file write tableout "\hline\hline" _n
file write tableout "\end{tabular}" _n
file close tableout

display "✓  LaTeX covariate-balance table manually written to Tables/cov_balance_sc.tex"

