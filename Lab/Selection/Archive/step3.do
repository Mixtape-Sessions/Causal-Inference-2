********************************************************************************
* name: step3.do
* author: scott cunningham (baylor) based on Yiqing Xu's excellent tutorial 
* 		  available here: https://yiqingxu.org/packages/panelview_stata/Stata_tutorial.pdf
* description: step 3 of Pedro Sant'Anna's did checklist.  Plot the outcomes associated with the staggered rollout using panelView by Yiqing Xu and coauthors
* last updated: june 7, 2024
********************************************************************************

capture log close
clear

* Load files
net install grc1leg, from(http://www.stata.com/users/vwiggins) replace
net install gr0075, from(http://www.stata-journal.com/software/sj18-4) replace
ssc install labutil, replace
ssc install sencode, replace

cap ado uninstall panelview //in-case already installed
net install panelview, all replace from("https://yiqingxu.org/packages/panelview_stata")

* Load the castle doctrine data
use "https://github.com/scunning1975/mixtape/raw/master/castle.dta", clear

* Key variables are outcome (log homicide), which is first, a treatment dummy (post), a panel unit identifier (state), a time identifier (year), and then name the type you want to show (treat) by the vertical axis (time labeled as Year) and then a title of the y-axis (here State).  And then the title of the entire thing will be "Treatment Status by Timing Group"

panelview l_homicide post, i(state) t(year) type(outcome) xtitle("Year") ytitle("Log Homicides") title("Castle Doctrine Reform and Log Homicides") ylabel(-0.5 (0.25) 3)

*prepost
panelview l_homicide post, i(state) t(year) type(outcome) xtitle("Year") ytitle("Log Homicides") title("Castle Doctrine Reform and Log Homicides") ylabel(-0.5 (0.25) 3) prepost

* colors
panelview l_homicide post, i(state) t(year) type(outcome) xtitle("Year") ytitle("Log Homicides") title("Castle Doctrine Reform and Log Homicides") ylabel(-0.5 (0.25) 3) mycolor(OrRd) prepost 

panelview l_homicide post if state=="Alabama" | state=="Alaska" | state=="Arizona" | state=="Florida" | state=="Georgia" | state=="Indiana" | state=="Kansas" | state=="Kentucky" | state=="Louisiana" | state=="Michigan" | state=="Mississippi" | state=="Missouri" | state=="Montana" | state=="North Dakota" | state=="Ohio" | state=="Oklahoma" | state=="South Carolina" | state=="South Dakota" | state=="Tennessee" | state=="Texas" | state=="West Virgnia", i(state) t(year) type(outcome) xtitle("Year") ytitle("Log Homicides") title("Castle Doctrine Reform and Log Homicides") ylabel(-0.5 (0.25) 3) mycolor(OrRd) prepost  

panelview l_homicide post, i(state) t(year) type(outcome) xtitle("Year") ytitle("Log Homicides") title("Castle Doctrine Reform and Log Homicides") ylabel(-0.5 (0.25) 3) bygroup   mycolor(OrRd) prepost

panelview l_homicide post, i(state) t(year) type(outcome) xtitle("Year") ytitle("Log Homicides") title("Castle Doctrine Reform and Log Homicides") ylabel(-0.5 (0.25) 3) bygroupside  

panelview l_homicide post, i(state) t(year) type(outcome) xtitle("Year") ytitle("Log Homicides") title("Castle Doctrine Reform and Log Homicides") ylabel(-0.5 (0.25) 3) bycohort mycolor(OrRd) prepost  



graph export "/Users/scunning/Causal-Inference-2/Lab/Pedro Checklist/rollout1.png", as(png) name("Graph") replace

* But maybe you'd like to group them together by treatment timing group
panelview l_homicide post, bytiming i(state) t(year) type(treat) xtitle("Year") ytitle("State") title("Treatment Status by Timing Group")

graph export "/Users/scunning/Causal-Inference-2/Lab/Pedro Checklist/rollout2.png", as(png) name("Graph") replace

* Distinguish visually the pre/post period
panelview turnout policy_edr policy_mail_in policy_motor, i(abb) t(year) type(outcome) xtitle("Year") ytitle("Turnout") by(, title("EDR Reform and Turnout")) bygroup xlabel(1920 (20) 2000) 
graph export "/Users/scunning/Causal-Inference-2/Lab/Pedro Checklist/rollout3.png", as(png) name("Graph") replace


clear
exit

