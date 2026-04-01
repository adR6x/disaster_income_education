*------------------------------------------------------------------------------*
*             Append cleaned family level data for HRVS		                  *
/*

	Author:				Anubhav
	Date created:		29th Oct 2023

	Notes:				This do file appends cleaned HRVS family data for 2016
						2017 and 2018.
			
	Dependencies:		This do file depends on previous do files that
						clean family datasets for HRVS 2016-2018.
						vdc_hrvs_eq_intense.py for earthquake intensity data.

*/
{
*------------------------------------------------------------------------------*
**#							STATA setups       								    
*------------------------------------------------------------------------------*
clear
cap clear frames
set more off
set rmsg on
local dofilename "07_hrvs_family_expenses"
cap log close
	
	*--------------------------------------------------------------------------*
	**# Import macros (global)
	global hrvs_family_2016 ""$data_clean/hrvs_family_2016""
	global hrvs_family_2017 ""$data_clean/hrvs_family_2017""
	global hrvs_family_2018 ""$data_clean/hrvs_family_2018""
	global vdc_hrvs_eq_intense ""$data_clean/vdc_hrvs_eq_intense"" // Earthquake intensity data
	
	
	*--------------------------------------------------------------------------*
	**# Export macros (global)
	global hrvs_family_expenses ""$data_analysis/hrvs_family_expenses""
	
	*--------------------------------------------------------------------------*
	**# Programs
	
	*--------------------------------------------------------------------------*
	**# Macros check
	
	** No need to change following codes
	if "$workspace" == "" {
		di as error "Please set up workspace directory"
		exit
	} 
	
	*--------------------------------------------------------------------------*
	**# Date/time macro (global)
	
	** Following is useful for hourly log purpose
	local datehour =ustrregexra(regexr("`c(current_date)'"," 20","")+"_"+regexr("`c(current_time)'",":[0-9]+:[0-9]+","")," ","") //saves string in 4Mar23_13 format, equivalent to 4th march 2023, 13 hour.
	
*------------------------------------------------------------------------------*
**#							Log start       								    
*------------------------------------------------------------------------------*	
	
	log using "$log/`dofilename'_`datehour'", replace
	
}	
*------------------------------------------------------------------------------*
**#	Append HRVS family data

use $hrvs_family_2016, clear
append using $hrvs_family_2017, force
append using $hrvs_family_2018, force

* just keeping relavant data for now
keep hhid-survey_level

* Exploration of the data
ds hhid psu district vdc is_hhhead ethnicity language_primary religion, not
foreach var in `r(varlist)'{
// 	hist `var', by(survey_year) name(`var', replace)
}

*------------------------------------------------------------------------------*
**# Merge Earthquake data
*------------------------------------------------------------------------------*

decode district, gen(district_str)
drop district
rename district_str district
order district, after(psu)

merge m:1 vdc district survey_year using $vdc_hrvs_eq_intense, keepusing(Intensity_1 Intensity_2)
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                           800
        from master                         0  (_merge==1)
        from using                        800  (_merge==2)

    Matched                            12,005  (_merge==3)
    -----------------------------------------

*/
assert _merge!= 1
keep if _merge == 3
drop _merge

la var Intensity_1 "Intensity 1 of Earthquake in last 1 year"
la var Intensity_2 "Intensity 2 of Earthquake in last 1 year"


preserve
	use $vdc_hrvs_eq_intense, clear
	replace survey_year = survey_year + 1

	rename (Intensity_1 Intensity_2) =_1
	la var Intensity_1_1 "Intensity 1 of Earthquake in year before the last year (T-1)"
	la var Intensity_2_1 "Intensity 2 of Earthquake in year before the last year (T-1)"
	
	tempfile vdc_hrvs_eq_intense_1
	save `vdc_hrvs_eq_intense_1', replace
restore

merge m:1 vdc district survey_year using `vdc_hrvs_eq_intense_1', keepusing(Intensity_1_1 Intensity_2_1 Latitude Longitude)
assert _merge!= 1
keep if _merge == 3
drop _merge


*------------------------------------------------------------------------------*
**# Some analysis
*------------------------------------------------------------------------------*
egen family_id = group(hhid psu district vdc)
egen community_id = group(psu district vdc)

order family_id community_id, before(hhid)

tsset family_id survey_year

// foreach var in total_edu_expense_365 total_food_expense_365 total_utilities_expenditure_365 total_sfood_expense_365 total_nfood_expense_365 total_nfoodi_expense_365 land_rent_365 total_land_investment_365 total_agri_expense_365 total_livestock_cost_365 total_livestock_rcost_365 total_agri_asset_cost_365 total_bus_asset_cost_365 total_otransfered_365{
//	
// 	local varlabel : variable label `var'
// 	tempvar expense_ln
// 	gen `expense_ln' = ln(`var'+1)
//	
// 	qui summarize `var' L.`var'
//	
// 	twoway (scatter `expense_ln' L.`expense_ln', msymbol(o) msize(vsmall) mcolor(black)) ///
// 	(lfit `expense_ln' L.`expense_ln') ///
// 	(function y = x, lpattern(dash)) ///
// 	,aspect(1) ///
// 	name(`var', replace) ///
// 	ytitle("Current Year") ///
// 	xtitle("Year Before") ///
// 	title("`varlabel'")
// }

compress
save $hrvs_family_expenses, replace


*------------------------------------------------------------------------------*		
**#							End of do file
*------------------------------------------------------------------------------*
	cap log close
	exit
*------------------------------------------------------------------------------*