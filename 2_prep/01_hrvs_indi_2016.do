*------------------------------------------------------------------------------*
*            				Title here						                   *
/*

	Author:				Anubhav
	Date created:		29th Oct 2023

	Notes:
			
	Dependencies:		Run master do file for global file/folder path macros

*/
{
*------------------------------------------------------------------------------*
**#							STATA setups       								    
*------------------------------------------------------------------------------*
clear
cap clear frames
set more off
set rmsg on
local dofilename "01_data_merge"
cap log close
	
	*--------------------------------------------------------------------------*
	**# Import macros (global)
	
	*--------------------------------------------------------------------------*
	**# Export macros (global)
	global vdcs_list_hrvs ""$data_clean/vdcs_list_hrvs.csv""
	
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
**#	Load 2016 data

*===================*
**# Basic Information
*===================*
use "${data_raw}/Wave 1 - Household/Section_1", clear
keep hhid psu district vdc member_id s01q02 s01q03 s01q03a s01q06a s01q07

*===================*
**# Education
*===================*
merge 1:1 hhid psu district vdc member_id using "${data_raw}/Wave 1 - Household/Section_2", keepusing(s02q02 s02q03 s02q04 s02q05 s02q06 s02q08 s02q09 s02q09a s02q09b s02q09c s02q09d s02q09e s02q09f s02q10 s02q11a s02q11b s02q11c s02q11d s02q11d_s_eng s02q11b_s_eng)
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                         1,482
        from master                     1,482  (_merge==1)
        from using                          0  (_merge==2)

    Matched                            26,117  (_merge==3)
    -----------------------------------------

*/

assert _merge!=2
drop _merge

*===================*
**# Health
*===================*
merge 1:1 hhid psu district vdc member_id using "${data_raw}/Wave 1 - Household/Section_3", keepusing(s03q01 s03q06a s03q06b s03q06c s03q06d s03q06e)
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                            27,599  (_merge==3)
    -----------------------------------------

*/
assert _merge ==3
drop _merge

*===================*
**# Migrant individuals
*===================*
merge 1:1 hhid psu district vdc member_id using "${data_raw}/Wave 1 - Household/Section_11", keepusing( s11q03 s11q07c s11q08b s11q09 s11q10b)
/*
   Result                      Number of obs
    -----------------------------------------
    Not matched                        30,102
        from master                    27,181  (_merge==1)
        from using                      2,921  (_merge==2)

    Matched                               764  (_merge==3)
    -----------------------------------------
	
	We have extra individuals!!
*/
drop _merge


merge m:1 hhid psu district vdc using "${data_raw}/Wave 1 - Household/Section_4", keepusing(s04q03 s04q04b s04q06  s04q21 s04q23 s04q24b s04q32b_1 s04q32b_2 s04q32b_3 s04q32b_4 s04q32a s04q32c s04q33b_1 s04q33b_2 s04q33b_3 s04q33b_4 s04q33a s04q33c)
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                           346
        from master                         0  (_merge==1)
        from using                        346  (_merge==2)

    Matched                            30,520  (_merge==3)
    -----------------------------------------

	Looks like there are some extra families here!!
*/
assert _merge!=1
drop _merge

preserve
	keep district vdc
	duplicates drop
	compress
	export delim $vdcs_list_hrvs, replace
restore

preserve
	use "${data_raw}/Wave 1 - Household/Section_5a", clear
	bys hhid psu district vdc:  egen c_home_produced = sum(s05q03), missing
	la var  c_home_produced "Food consumed expense home produced last 7 days"
	bys hhid psu district vdc:  egen c_market_purchased = sum(s05q06), missing 
	la var  c_market_purchased "Food consumed expensemarket purchased last 7 days"
	bys hhid psu district vdc:  egen c_recieved_inkind = sum(s05q09), missing 
	la var  c_recieved_inkind "Food consumed expense received in kind last 7 days"

	egen total_food_expense_7 = rowtotal(c_home_produced c_market_purchased c_recieved_inkind), missing
	la var total_food_expense_7 "Total Food consumed expense in last 7 days"

	gen total_food_expense_30 = total_food_expense_7 * (30/7)
	la var total_food_expense_30 "Total Food consumed expense in last 30 days, extrapolated"

	gen total_food_expense_365 = total_food_expense_30 * 12
	la var total_food_expense_30 "Total Food consumed expense in last 1 year, extrapolated"
	
	keep hhid psu district vdc s05q03 total_food_expense_7  total_food_expense_30 total_food_expense_365

	duplicates drop hhid psu district vdc, force
	
	tempfile sec_5a
	save `sec_5a', replace
restore

merge m:1 hhid psu district vdc using `sec_5a', keepusing(total_food_expense_7  total_food_expense_30 total_food_expense_365)
/*

    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                            30,866  (_merge==3)
    -----------------------------------------

*/
assert _merge ==3
drop _merge

preserve
	use "${data_raw}/Wave 1 - Household/Section_6a", clear // Household level!!
	
	bys hhid psu district vdc:  egen total_nfood_expense_30 = sum(s06q01a), missing
	la var total_nfood_expense_30 "Total non-Food consumed expense in last month"
	
	bys hhid psu district vdc:  egen total_nfood_expense_365 = sum(s06q01b), missing
	la var total_nfood_expense_365 "Total non-Food consumed expense in last year"

	keep hhid psu district vdc total_nfood_expense_30  total_nfood_expense_365
	
	duplicates drop	hhid psu district vdc, force

	tempfile sec_6a
	save `sec_6a', replace
	
restore	

merge m:1 hhid psu district vdc using `sec_6a', keepusing(total_nfood_expense_30  total_nfood_expense_365)
/*
 
    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                            30,866  (_merge==3)
    -----------------------------------------


*/
assert _merge ==3
drop _merge

preserve
	use "${data_raw}/Wave 1 - Household/Section_6b", clear // Household level!!

	bys hhid psu district vdc:  egen total_nfoodi_expense_365 = sum(s06q02), missing
	la var total_nfoodi_expense_365 "Total non-Food infrequent consumed expense in last year"

	gen total_nfoodi_expense_30 = total_nfoodi_expense_365 / 12
	la var total_nfoodi_expense_30 "Total non-Food infrequent consumed expense in month, extrapolated"
	
	keep hhid psu district vdc total_nfoodi_expense_30 total_nfoodi_expense_365

	duplicates drop hhid psu district vdc, force

	tempfile sec_6b
	save `sec_6b', replace
	
restore	

merge m:1 hhid psu district vdc using `sec_6b', keepusing(total_nfoodi_expense_365)
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                           508
        from master                       508  (_merge==1)
        from using                          0  (_merge==2)

    Matched                            30,358  (_merge==3)
    -----------------------------------------
*/
assert _merge !=2
drop _merge

merge m:1 hhid psu district vdc using "${data_raw}/Wave 1 - Household/Section_6d", keepusing(s06q04b s06q04c)
/*

    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                            30,866  (_merge==3)
    -----------------------------------------


*/
assert _merge ==3
drop _merge


merge m:1 hhid psu district vdc using "${data_raw}/Wave 1 - Household/Section_9a3", keepusing(s09q31a)
/*

    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                            30,866  (_merge==3)
    -----------------------------------------

*/
assert _merge ==3
drop _merge


preserve
	use "${data_raw}/Wave 1 - Household/Section_9c", clear // Household level!!
	
	egen total_agri_expense_365 = rowtotal(s09q52b s09q52d s09q52f s09q52h s09q52j s09q53b s09q53d s09q53f s09q53h s09q53j s09q55b s09q55d s09q55f s09q55h s09q55j s09q55l s09q55n s09q55p s09q55r), missing
	la var total_agri_expense_365 "Total Cost on agricultural production last year -seeds, fertilizer, equipments, labor, etc"

	keep hhid psu district vdc total_agri_expense_365
	
	tempfile sec_9c
	save `sec_9c', replace
	
restore
merge m:1 hhid psu district vdc using `sec_9c', keepusing(total_agri_expense_365)
/*

    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                            30,866  (_merge==3)
    -----------------------------------------


*/
assert _merge ==3
drop _merge

	
preserve
	use "${data_raw}/Wave 1 - Household/Section_9d", clear // Household level!!	
	
	bys hhid psu district vdc: egen total_livestock_cost_365 = total(s09q61b), missing
	la var total_livestock_cost_365 "Total Cost on buying livestock last year"
		
	keep hhid psu district vdc total_livestock_cost_365
	
	duplicates drop hhid psu district vdc, force

	
	tempfile sec_9d
	save `sec_9d', replace
	
restore	
merge m:1 hhid psu district vdc using `sec_9d', keepusing(total_livestock_cost_365)
/* needs update
    Result                      Number of obs
    -----------------------------------------
    Not matched                         4,388
        from master                     4,388  (_merge==1)
        from using                          0  (_merge==2)

    Matched                            23,557  (_merge==3)
    -----------------------------------------


*/
assert _merge !=2
drop _merge	
	
merge m:1 hhid psu district vdc using "${data_raw}/Wave 1 - Household/Section_9e", keepusing(s09q63a s09q63b s09q63c s09q63d)
egen total_livestock_rcost_365 = rowtotal(s09q63a s09q63b s09q63c s09q63d), missing
la var total_livestock_rcost_365 "Total Cost on maintaing livestock last year- fodder, vet, etc"
drop s09q63a s09q63b s09q63c s09q63d _merge

preserve
	use "${data_raw}/Wave 1 - Household/Section_9f", clear // Household level!!
	
	bys hhid psu district vdc: egen total_agri_asset_cost_365 = total(s09q70), missing
	la var total_agri_asset_cost_365 "Total cost of agricultural equipment for last year"
	
	keep hhid psu district vdc total_agri_asset_cost_365
	duplicates drop hhid psu district vdc, force
	
	tempfile sec_9f
	save `sec_9f', replace
	
restore	

merge m:1 hhid psu district vdc using `sec_9f', keepusing(total_agri_asset_cost_365)
/* needs update
    Result                      Number of obs
    -----------------------------------------
    Not matched                        12,923
        from master                    12,923  (_merge==1)
        from using                          0  (_merge==2)

    Matched                            15,022  (_merge==3)
    -----------------------------------------
*/
assert _merge !=2
drop _merge	

preserve
	use "${data_raw}/Wave 1 - Household/Section_10", clear // Household level!!
	
	bys hhid psu district vdc: egen total_bus_asset_cost_365 = total(s10q09), missing
	la var total_bus_asset_cost_365 "Total personal cost spend for business for last year"
	
	keep hhid psu district vdc total_bus_asset_cost_365
	
	duplicates drop hhid psu district vdc, force
	
	tempfile sec_10
	save `sec_10', replace
	
restore

merge m:1 hhid psu district vdc using `sec_10', keepusing(total_bus_asset_cost_365)
/* needs update
    Result                      Number of obs
    -----------------------------------------
    Not matched                        24,194
        from master                    24,194  (_merge==1)
        from using                          0  (_merge==2)

    Matched                             3,751  (_merge==3)
    -----------------------------------------
*/
assert _merge !=2
drop _merge	

*==========================*
**# Transfers to households
*==========================*

preserve
	use "${data_raw}/Wave 1 - Household/Section_13a", clear
	egen total = rowtotal(s13q07a s13q07b) , missing
	bys hhid psu district vdc: egen total_otransfered_365 = total(total), missing
	la var total_otransfered_365 "Total amount transfered in cash or kind to other household in last year"
	
	keep hhid psu district vdc total_otransfered_365
	duplicates drop hhid psu district vdc, force
	
	tempfile sec_13a
	save `sec_13a', replace
	
restore

merge m:1 hhid psu district vdc using `sec_13a', keepusing(total_otransfered_365)
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                        29,845
        from master                    29,845  (_merge==1)
        from using                          0  (_merge==2)

    Matched                             1,021  (_merge==3)
    -----------------------------------------

*/
assert _merge!=2
drop _merge

*============================*
**# Transfers from households
*============================*

preserve
	use "${data_raw}/Wave 1 - Household/Section_13b", clear
	egen total = rowtotal(s13q16a s13q16b) , missing
	bys hhid psu district vdc: egen total_itransfered_365 = total(total), missing
	la var total_itransfered_365 "Total amount of cash or kind recieved from other household in last year"
	
	bys hhid psu district vdc: egen itransfered_edu = total(s13q17a_3), missing
	la var itransfered_edu "Any cash or kind recieved from other household for Education cost in last year"
	
	keep hhid psu district vdc total_itransfered_365 nyear itransfered_edu // Interesting that it has year of survey variable
	duplicates drop hhid psu district vdc, force
	
	tempfile sec_13b
	save `sec_13b', replace
	
restore

merge m:1 hhid psu district vdc using `sec_13b', keepusing(total_itransfered_365 itransfered_edu nyear)
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                        30,226
        from master                    30,226  (_merge==1)
        from using                          0  (_merge==2)

    Matched                               640  (_merge==3)
    -----------------------------------------
*/
assert _merge!=2
drop _merge

*===============================*
**# Received from Organizations
*===============================*

preserve
	use "${data_raw}/Wave 1 - Household/Section_13c", clear
	egen total = rowtotal(s13q19a s13q19c) , missing
	bys hhid psu district vdc: egen total_ireceived_365 = total(total), missing
	la var total_ireceived_365 "Total amount of cash or kind recieved (Privately) from organizations in last year"
	
	bys hhid psu district vdc: egen ireceived_edu = total(s13q21a_3), missing
	la var ireceived_edu "Any cash or kind recieved (Privately)  from organizations for Education cost in last year"
	
	keep hhid psu district vdc total_ireceived_365 ireceived_edu // Interesting that it has year of survey variable
	duplicates drop hhid psu district vdc, force
	
	tempfile sec_13c
	save `sec_13c', replace
	
restore

merge m:1 hhid psu district vdc using `sec_13c', keepusing(total_ireceived_365 ireceived_edu)
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                        27,651
        from master                    27,651  (_merge==1)
        from using                          0  (_merge==2)

    Matched                             3,215  (_merge==3)
    -----------------------------------------
*/
assert _merge!=2
drop _merge

*===============================*
**# Received from Public programs
*===============================*

// preserve
	use "${data_raw}/Wave 1 - Household/Section_14a", clear
	bys hhid psu district vdc: egen total_ireceived_365 = total(total), missing
	la var total_ireceived_365 "Total amount of cash or kind recieved (Privately) from organizations in last year"
	
	bys hhid psu district vdc: egen ireceived_edu = total(s13q21a_3), missing
	la var ireceived_edu "Any cash or kind recieved (Privately)  from organizations for Education cost in last year"
	
	keep hhid psu district vdc total_ireceived_365 ireceived_edu // Interesting that it has year of survey variable
	duplicates drop hhid psu district vdc, force
	
	tempfile sec_13c
	save `sec_13c', replace
	
restore

merge m:1 hhid psu district vdc using `sec_13c', keepusing(total_ireceived_365 ireceived_edu)
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                        27,651
        from master                    27,651  (_merge==1)
        from using                          0  (_merge==2)

    Matched                             3,215  (_merge==3)
    -----------------------------------------
*/
assert _merge!=2
drop _merge

use "${data_raw}/Wave 1 - Household/Section_14a", clear // Household level!!
keep pubcashid s14q02 s14q04a s14q04b

use "${data_raw}/Wave 1 - Household/Section_14b", clear // Household level!!
keep pubkindid s14q11 s14q13b_q

use "${data_raw}/Wave 1 - Household/Section_14c", clear // Household level!!
keep publicworkid s14q17 

use "${data_raw}/Wave 1 - Household/Section_15a", clear // Household level!!
keep shockid-s15q12_s

use "${data_raw}/Wave 1 - Household/Section_15b", clear // Household level!!
keep s15q16a_1-s15q16b_998

use "${data_raw}/Wave 1 - Household/Section_17", clear // Household level!!
// keep s15q16a_1-s15q16b_998

*------------------------------------------------------------------------------*		
**#							End of do file
*------------------------------------------------------------------------------*
	cap log close
	exit
*------------------------------------------------------------------------------*