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

**# Load 2017 data

*===================*
**# Basic Information
*===================*
use "${data_raw}/Wave 2 - Household/Section_1", clear

gen is_hhhead = s01q01 == 1
	label define ishhhead 1 "Household Head" 0 "Other members"
	label values is_hhhead ishhhead

keep hhid psu district vdc member_id is_hhhead s01q02 s01q03 s01q03a s01q06a s01q07

merge m:1 hhid psu district vdc using "${data_raw}/Wave 2 - Household/Section_0", keepusing (s00q15 s00q16 s00q17)

/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                            30,315  (_merge==3)
    -----------------------------------------
*/
assert _merge == 3
drop _merge

rename s00q15 ethnicity
rename s00q16 language_primary
rename s00q17 religion


*===================*
**# Education
*===================*
merge 1:1 hhid psu district vdc member_id using "${data_raw}/Wave 2 - Household/Section_2", keepusing(s02q02 s02q03 s02q04 s02q05 s02q06 s02q08 s02q09 s02q09a s02q09b s02q09c s02q09d s02q09e s02q09f s02q10 s02q11a s02q11b s02q11c s02q11d)

/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                         5,431
        from master                     5,431  (_merge==1)
        from using                          0  (_merge==2)

    Matched                            24,884  (_merge==3)
    -----------------------------------------
*/

assert _merge != 2
drop _merge

*===================*
**# Health
*===================*

merge 1:1 hhid psu district vdc member_id using "${data_raw}/Wave 2 - Household/Section_3", keepusing (s03q01 s03q06a s03q06b s03q06c s03q06d s03q06e)

/*
 Result                      Number of obs
    -----------------------------------------
    Not matched                         4,333
        from master                     4,333  (_merge==1)
        from using                          0  (_merge==2)

    Matched                            25,982  (_merge==3)
    -----------------------------------------
*/

assert _merge != 2
drop _merge


*===================*
**# Section 11- Migration
*===================*

merge 1:1 hhid psu district vdc member_id using "${data_raw}/Wave 2 - Household/Section_11", keepusing( s11q03 s11q07c s11q08b s11q09 s11q10b)

**#							End of do file
*------------------------------------------------------------------------------*
	cap log close
	exit
*------------------------------------------------------------------------------*
 

