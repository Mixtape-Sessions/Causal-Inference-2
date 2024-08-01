* Martingale property
program define dgp_martingale
    clear
    set obs 1000
    gen id = _n
    expand 6
    bysort id: gen year = _n
    
    * Generate a random walk (martingale process)
    gen y0 = 0
    bysort id (year): replace y0 = y0[_n-1] + rnormal(0, 1) if _n > 1
    
    * Treatment assignment (not based on future Y0)
    gen treat = runiform() < 0.5 if year == 1
    bysort id (year): replace treat = treat[1]
    
    * Generate Y1 (just for completeness)
    gen y1 = y0 + 5 if year >= 4
    replace y1 = y0 if year < 4
    
    gen y = y0
    replace y = y1 if treat == 1 & year >= 4
end


* Non-martingale property
program define dgp_non_martingale
    clear
    set obs 1000
    gen id = _n
    expand 6
    bysort id: gen year = _n
    
    * Generate a mean-reverting process (violates martingale property)
    gen y0 = 0
    bysort id (year): replace y0 = 0.5 * y0[_n-1] + rnormal(0, 1) if _n > 1
    
    * Treatment assignment (not based on future Y0)
    gen treat = runiform() < 0.5 if year == 1
    bysort id (year): replace treat = treat[1]
    
    * Generate Y1 (just for completeness)
    gen y1 = y0 + 5 if year >= 4
    replace y1 = y0 if year < 4
    
    gen y = y0
    replace y = y1 if treat == 1 & year >= 4
end

