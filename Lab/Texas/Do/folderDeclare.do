********************************************************************************
* NAME: 		folderDeclare.do
* DESCRIPTION:  Sets the folder directory, creates global use locals, and 		
*				installs packages used in the project.
* OUTPUT:		
* LAST UPDATE:	March 3, 2019
********************************************************************************

*==============================================================================*
*									SECTION 1								   *
* 								SET UNIVERSAL SETTINGS						   *
*==============================================================================*
  set more off, permanently
  set matsize 800
  global user = c(username)
  
  
*==============================================================================*
*									SECTION 2								   *
* 						  SET THE DATE OF CURRENT DAY						   *
*==============================================================================*
  local date : di %tdYYNNDD date(c(current_date),"DMY")
  global date = "`date'"


  
*==============================================================================*
*									SECTION 3								   *
* 							SET FILE DIRECTOY GLOBALS						   *
*==============================================================================*  

* a) Set main file directory
  if "`c(username)'" == "scott_cunningham"	cd "/Users/scott_cunningham/Dropbox/Workshop/Texas/Do"
  else										cd "C:\Users\skang\Dropbox\drug_courts\do"
  
 
* b) Data
  global data "../data"
  
  global teds 		"$data/teds"
  global ucr		"$data/ucr"
  global cps		"$data/cps"
  global seer		"$data/seer"
  global leoka		"$data/leoka"
  global crack		"$data/crack_index"
  global stride		"$data/stride"
  global cpi		"$data/cpi"
  global npp		"$data/npp"
  
  global tempfiles	"$data/tempfiles"
  
  
* c) Logs
  global logs "../logs"
  
  
* d) Ouput
  global figures 	"../figures"
  global tables 	"../tables"
  
  global synth		"$data/synth"
  global inference	"../inference"

  
  
*==============================================================================*
*									SECTION 1								   *
* 						INSTALL PROJECT STATA PACKAGES						   *
*==============================================================================*  
  foreach file in mdesc reghdfe ivreg2 ranktest estout coefplot winsor winsor2 distinct tuples gtools {
	capture findfile `file'.ado
	if _rc == 601 {
	ssc install `file'
	}
  }
