** Pretty plots of mean outcomes by cohort
preserve
collapse (mean) br1544 marriage_rate abortion_rate divorce_rate rate_gonorrhea rate_chlamydia fempop1544 RUCC_2003, by(treat_date5 year)
xtset treat_date year

label variable br1544 "Average County 15-44yo Birth Rates"
label variable marriage_rate "Average County Marriage Rates"
label variable divorce_rate "Average County Divorce Rates"
label variable abortion_rate "Average County Abortion Rates"
label variable rate_gonorrhea "Average County Gonorrhea Rates"
label variable rate_chlamydia "Average County Chlamydia Rates"
label variable fempop1544 "Average number of females aged 15-44"
label variable RUCC_2003 "Average RUCC Code From 2003"


// For births
separate br1544, by(treat_date5) gen(yr)

// Create individual birth rates plots with reference lines
foreach t in 2020 2030 2000 2001 2002 2003 2004 2005 2006 2007 {
    if (`t' == 2020) {
        local label "never treated"
        local rline 0
    }
    else if (`t' == 2030) {
        local label "2008-2010 cohorts"
        local rline 2008
    }
    else {
        local label "`t' cohort"
        local rline `t'
    }
    local linecolor = cond(`t' == 2020 | `t' == 2030, "blue", "blue")
    
    scatter yr* year, recast(line) lc(gs12 ...) lp(solid ...) ///
        legend(off) || line br1544 year if treat_date5 == `t', ///
        lc(`linecolor') lp(solid) lw(medthick) xtitle("") subtitle("`label'") ///
        name(plot_`t', replace) ///
        xline(`rline', lcolor(red) lpattern(dash)) ///
        xlabel(1995(2)2007, labsize(small)) ///
        xscale(range(1995 2007)) ///
        ylabel(, angle(0) labsize(small))
}

// Combine the birth rate individual plots into a single graph
graph combine plot_2020 plot_2030 plot_2000 plot_2001 plot_2002 plot_2003 plot_2004 plot_2005 plot_2006 plot_2007, ///
    title("Average Births per 1,000 females by Cohort") ///
    subtitle("15-44 year olds") ///
    ysize(8) xsize(10) ///
    scale(0.9)
graph export "../figures/msa_pretty_births.png", as(png) name("Graph") replace width(2000)
