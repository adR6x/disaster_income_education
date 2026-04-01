*------------------------------------------------------------------------------*
*            				Title here						                   *
/*

	Author:				Arpan
	Date created:		12 April 2025

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
local dofilename "04_hrvs_family_2018"
cap log close
	
	*--------------------------------------------------------------------------*
	**# Import macros (global)
// 	global hrvs_family_2017 "${data_raw}/Wave 2 - Household"
	
	*--------------------------------------------------------------------------*
	**# Export macros (global)
	global hrvs_family_2018 ""$data_clean/hrvs_family_2018""
	
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
use "${data_raw}/Wave 3 - Household/Section_1", clear

gen is_hhhead = s01q01 == 1
	label define ishhhead 1 "Household Head" 0 "Other members"
	label values is_hhhead ishhhead

keep hhid psu district vdc is_hhhead

merge m:1 hhid psu district vdc using "${data_raw}/Wave 3 - Household/Section_0", keepusing (s00q15 s00q16 s00q17)

/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                            29,268  (_merge==3)
    -----------------------------------------
*/

assert _merge == 3
drop _merge

rename s00q15 ethnicity
rename s00q16 language_primary
rename s00q17 religion


preserve
	use "${data_raw}/Wave 3 - Household/Section_1", clear
	
	egen members_per_household = count(member_id), by(hhid psu district vdc)
	la var members_per_household "Total members in the household"
	duplicates drop hhid psu district vdc, force
	tempfile sec_1
	save `sec_1', replace
restore

merge m:1 hhid psu district vdc using `sec_1', keepusing (members_per_household)

/*
 Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                            29,268  (_merge==3)
    -----------------------------------------
*/

assert _merge == 3
drop _merge
duplicates drop hhid psu district vdc, force

preserve
	use "${data_raw}/Wave 3 - Household/Section_2", clear
	
	merge 1:1 hhid psu district vdc member_id using "${data_raw}/Wave 3 - Household/Section_1", keepusing(s01q01)
	/*
	    Result                      Number of obs
    -----------------------------------------
    Not matched                         1,482
        from master                         0  (_merge==1)
        from using                      1,482  (_merge==2)

    Matched                            26,117  (_merge==3)
    -----------------------------------------
	*/
	keep if _merge!=2
	drop _merge
	
	gen edu_hh_head = s02q02 if  s01q01 == 1 // Check if this household head
	bys hhid psu district vdc: egen edu_family_head = max(edu_hh_head)
	la var edu_family_head "Highest grade completed by household head"
	
	
	egen total_expenses_school = rowtotal(s02q09a s02q09b s02q09c s02q09d s02q09e s02q09f)
	la var total_expenses_school "Total school related expenses including fees and everything"
	
	bys hhid psu district vdc: egen mean_level_school = mean(s02q03)
	la var mean_level_school "Mean grade level of family members currently attending school"
	bys hhid psu district vdc: egen children_in_school = count(s02q03)
	la var children_in_school "Number of family members currently attending School"
	
	bys hhid psu district vdc: egen total_edu_expense_365 = sum(total_expenses_school), missing
	la var total_edu_expense_365 "Total amount spent by household member's education in last year"
	keep hhid psu district vdc edu_family_head total_edu_expense_365 mean_level_school children_in_school
	duplicates drop hhid psu district vdc, force
	tempfile sec_02
	save `sec_02', replace
restore

merge 1:1 hhid psu district vdc using `sec_02', keepusing (edu_family_head total_edu_expense_365 mean_level_school children_in_school)

/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                             6,051  (_merge==3)
    -----------------------------------------
*/
assert _merge == 3
drop _merge

*===================*
**# Section 4- Access to Services
*===================*

preserve 
	use "${data_raw}/Wave 3 - Household/Section_4", clear 

	gen rent_self_estimated_365 = s04q05a //for those who live in their own house
	la var rent_self_estimated_365 "what would rent be if they had to pay for the dwelling they own 1 year"
	gen rent_self_estimated_30 = rent_self_estimated_365/12 
	la var rent_self_estimated_30 "what would rent be if they had to pay for the dwelling they own 30 days, extrapolated"
	
	rename s04q06 rent_expense_365
	la var rent_expense_365 "Yearly rent paid amount"
	gen rent_expense_30 = rent_expense_365/12
	la var rent_expense_365 "Monthly rent paid amount, extrapolated"
	
	gen total_rent_expense_365 =cond(s04q03 == 1,rent_self_estimated_365,rent_expense_365)
	la var total_rent_expense_365 "[No data for 2016] Yearly rental expense. Includes paid and estimated if the family owns the dwelling"
	
	egen total_utilities_expenditure_365 = rowtotal(s04q21 s04q23 s04q24b)
	la var total_utilities_expenditure_365 "Yearly expenses on electricity, drinking water and communication"
	gen total_utilities_expenditure_30 = total_utilities_expenditure_365/12
	la var total_utilities_expenditure_30 "Monthly expenses on electricity, drinking water and communication, extrapolated"
	//excluded garbage disposal payment because everywhere it's missing
	
	
	tempfile sec_4
	save `sec_4', replace
restore

merge 1:1 hhid psu district vdc using `sec_4', keepusing (hhid psu district vdc rent_expense_30 rent_expense_365 rent_self_estimated_365 rent_self_estimated_30 total_utilities_expenditure_365 total_utilities_expenditure_30 s04q04b s04q05 s04q32b_1 s04q32b_2 s04q32b_3 s04q32b_4 s04q32a s04q32c s04q33b_1 s04q33b_2 s04q33b_3 s04q33b_4 s04q33a s04q33c)

/*

  Result                      Number of obs
>     -----------------------------------------
>     Not matched                             0
>     Matched                             6,051  (_merge==3)

*/
assert _merge == 3
drop _merge


*===================*
**# Section 5- Food Consumption
*===================*


preserve
	use "${data_raw}/Wave 3 - Household/Section_5a", clear
	bys hhid psu district vdc: egen c_home_produced = sum(s05q03), missing
	la var c_home_produced "Food consumed expense home produced last 7 days"
	bys hhid psu district vdc: egen c_market_purchased = sum(s05q06), missing
	la var c_market_purchased "Food consumed expense market purchased last 7 days"
	bys hhid psu district vdc: egen c_recieved_inkind = sum(s05q09), missing
	la var c_recieved_inkind "Food expense received in kind last 7 days"

	egen total_food_expense_7 = rowtotal(c_home_produced c_market_purchased c_recieved_inkind), missing
	la var total_food_expense_7 "Total food expense in last 7 days"

	gen total_food_expense_30 = total_food_expense_7 * (30/7)
	la var total_food_expense_30 "Food expense received in kind last 30 days, extrapolated"

	gen total_food_expense_365 = total_food_expense_30 * 12
	la var total_food_expense_30 "Total Food consumed expense in last 1 year, extrapolated"
	
	keep hhid psu district vdc s05q03 total_food_expense_7 total_food_expense_30 total_food_expense_365

	duplicates drop hhid psu district vdc, force

	tempfile sec_5a
	save `sec_5a', replace
restore

merge 1:1  hhid psu district vdc using `sec_5a', keepusing(total_food_expense_7 total_food_expense_30 total_food_expense_365)

/*
     Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                             6,051  (_merge==3)
    -----------------------------------------

*/
assert _merge == 3
drop _merge

*===================*
**# Section 6- Non-Food Consumption
*===================*

preserve
	use "${data_raw}/Wave 3 - Household/Section_6a", clear

	bys hhid psu district vdc: egen total_nfood_expense_30 = sum(s06q01a), missing
	la var total_nfood_expense_30 "Total non-food consumed in the last month"

	bys hhid psu district vdc: egen total_nfood_expense_365 = sum(s06q01b), missing
	la var total_nfood_expense_365 "Total non-food consumed in the last year"

	keep hhid psu district vdc total_nfood_expense_30 total_nfood_expense_365

	duplicates drop hhid psu district vdc, force

	tempfile sec_6a
	save `sec_6a', replace
restore

merge 1:1 hhid psu district vdc using `sec_6a', keepusing (total_nfood_expense_30 total_nfood_expense_365)

/*

	Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                             6,051  (_merge==3)
    -----------------------------------------

*/
assert _merge == 3
drop _merge

*===================*
**# Section 6b
*===================*

preserve
	use "${data_raw}/Wave 3 - Household/Section_6b", clear 

	bys hhid psu district vdc:  egen total_nfoodi_expense_365 = sum(s06q02), missing
	la var total_nfoodi_expense_365 "Total non-Food infrequent consumed expense in last year"

	gen total_nfoodi_expense_30 = total_nfoodi_expense_365 / 12
	la var total_nfoodi_expense_30 "Total non-Food infrequent consumed expense in month, extrapolated"
	
	keep hhid psu district vdc total_nfoodi_expense_30 total_nfoodi_expense_365

	duplicates drop hhid psu district vdc, force

	tempfile sec_6b
	save `sec_6b', replace
	
restore	

merge 1:1 hhid psu district vdc using `sec_6b', keepusing (total_nfoodi_expense_30 total_nfoodi_expense_365)

/*
	Result                      Number of obs
    -----------------------------------------
    Not matched                           400
        from master                       400  (_merge==1)
        from using                          0  (_merge==2)

    Matched                             5,651  (_merge==3)
    -----------------------------------------


*/

assert _merge != 2
drop _merge

*===================*
**# Section 6d- Non-Food
*===================*

merge 1:1 hhid psu district vdc using "${data_raw}/Wave 3 - Household/Section_6d", keepusing(s06q04b s06q04c)
rename s06q04c total_sfood_expense_365


/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                             6,051  (_merge==3)
    -----------------------------------------
*/
assert _merge == 3
drop _merge


*===================*
**# Section 9- Farming and Livestock
*===================*


preserve 
	use "${data_raw}/Wave 3 - Household/Section_9a2", clear 
	bys hhid psu district vdc: egen land_rent_cash = sum(s09q18), missing
	bys hhid psu district vdc: egen land_rent_kind_casheq = sum(s09q20), missing
	keep hhid psu district vdc land_rent_cash land_rent_kind_casheq
	egen land_rent_365 = rowtotal (land_rent_cash land_rent_kind_casheq) 
	la var land_rent_365 "Total land rent paid to the owner in a year"
	gen land_rent_30 = land_rent_365/12
	la var land_rent_30 "Total land rent paid to the owner in a month, extrapolated"
	duplicates drop hhid psu district vdc, force
	
	
	tempfile sec_9a2
	save `sec_9a2', replace 
restore

merge 1:1 hhid psu district vdc using `sec_9a2', keepusing (land_rent_365 land_rent_30)

/*
	Result                      Number of obs
    -----------------------------------------
    Not matched                         5,404
        from master                     5,404  (_merge==1)
        from using                          0  (_merge==2)

    Matched                               647  (_merge==3)
    -----------------------------------------

*/

assert _merge != 2
drop _merge

//Land investments in this section

merge 1:1 hhid psu district vdc using "${data_raw}/Wave 3 - Household/Section_9a3", keepusing (s09q31a)

/*
	Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                             6,051  (_merge==3)
    -----------------------------------------

*/
assert _merge == 3
drop _merge 
rename s09q31a total_land_investment_365
replace total_land_investment_365 = 0 if mi(total_land_investment_365)
la var total_land_investment_365 "Total amount paid for land bought in last 1 year"

preserve
	use "${data_raw}/Wave 3 - Household/Section_9c", clear 
	
	egen total_agri_expense_365 = rowtotal(s09q52b s09q52d s09q52f s09q52h s09q52j s09q53b s09q53d s09q53f s09q53h s09q53j s09q55b s09q55d s09q55f s09q55h s09q55j s09q55l s09q55n s09q55p s09q55r), missing
	la var total_agri_expense_365 "Total Cost on agricultural production last year -seeds, fertilizer, equipments, labor, etc"

	keep hhid psu district vdc total_agri_expense_365
	
	tempfile sec_9c
	save `sec_9c', replace
	
restore
merge 1:1 hhid psu district vdc using `sec_9c', keepusing(total_agri_expense_365)

/*
	Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                             6,051  (_merge==3)
    -----------------------------------------

*/
assert _merge == 3
drop _merge

preserve
	use "${data_raw}/Wave 3 - Household/Section_9d", clear
	bys hhid psu district vdc: egen total_livestock_cost_365 = total(s09q61b), missing
	la var total_livestock_cost_365 "Total Cost on buying livestock last year"
		
	keep hhid psu district vdc total_livestock_cost_365
	
	duplicates drop hhid psu district vdc, force
	tempfile sec_9d
	save `sec_9d', replace
restore	

merge 1:1 hhid psu district vdc using `sec_9d', keepusing(total_livestock_cost_365)


/*
  Result                      Number of obs
    -----------------------------------------
    Not matched                         1,069
        from master                     1,069  (_merge==1)
        from using                          0  (_merge==2)

    Matched                             4,982  (_merge==3)
    -----------------------------------------

*/

assert _merge != 2
drop _merge


preserve
	use "${data_raw}/Wave 3 - Household/Section_9e", clear
	egen total_livestock_rcost_365 = rowtotal(s09q63a s09q63b s09q63c s09q63d), missing
	la var total_livestock_rcost_365 "Total cost on maintaining livestock last year- fodder, vet, transportation etc"
	tempfile sec_9e
	save `sec_9e', replace
restore

merge 1:1 hhid psu district vdc using `sec_9e', keepusing(total_livestock_rcost_365)	

/*
	Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                             6,051  (_merge==3)
    -----------------------------------------

*/

assert _merge == 3
drop _merge

preserve
	use "${data_raw}/Wave 3 - Household/Section_9f", clear 
	bys hhid psu district vdc: egen total_agri_asset_cost_365 = total(s09q70), missing
	la var total_agri_asset_cost_365 "Total cost of agricultural equipment for last year"
	
	keep hhid psu district vdc total_agri_asset_cost_365
	duplicates drop hhid psu district vdc, force
	
	tempfile sec_9f
	save `sec_9f', replace
	
restore	

merge 1:1 hhid psu district vdc using `sec_9f', keepusing(total_agri_asset_cost_365)

/*
     Result                      Number of obs
    -----------------------------------------
    Not matched                         2,310
        from master                     2,310  (_merge==1)
        from using                          0  (_merge==2)

    Matched                             3,741  (_merge==3)
    -----------------------------------------
*/
assert _merge != 2
drop _merge 


*===================*
**# Section 10- Non-Agri
*===================*

preserve
	use "${data_raw}/Wave 3 - Household/Section_10", clear // Household level!!
	
	bys hhid psu district vdc: egen total_bus_asset_cost_365 = total(s10q09), missing
	la var total_bus_asset_cost_365 "Total personal cost spend for business for last year"
	
	keep hhid psu district vdc total_bus_asset_cost_365
	
	duplicates drop hhid psu district vdc, force
	
	tempfile sec_10
	save `sec_10', replace
	
restore

merge 1:1 hhid psu district vdc using `sec_10', keepusing(total_bus_asset_cost_365)

/*

     Result                      Number of obs
    -----------------------------------------
    Not matched                         4,906
        from master                     4,906  (_merge==1)
        from using                          0  (_merge==2)

    Matched                             1,145  (_merge==3)
    -----------------------------------------

*/

assert _merge != 2
drop _merge

*===================*
**# Section 12- Loans
*===================*
preserve
	use "${data_raw}/Wave 3 - Household/Section_12a", clear
	keep hhid psu district vdc s12q05 s12q06 s12q07_1 s12q07_2 s12q07_3 s12q07_4 s12q07_5 s12q07_6 s12q07_7 s12q07_8 s12q07_9 s12q07_10 s12q07_11 s12q07_12 s12q07_13 s12q07_14 s12q07_15
	gen loan_reason = .
	replace loan_reason = 1 if s12q07_5 == 1 | s12q07_6 == 1| s12q07_7 == 1| s12q07_8 == 1 | s12q07_9 == 1 | s12q07_10 == 1 | s12q07_11 == 1 | s12q07_14 == 1
	//4 = Others
	replace loan_reason = 4 if s12q07_15 == 1
	//1 = investment
	replace loan_reason = 2 if s12q07_3 == 1
	//2 = education
	replace loan_reason = 3 if s12q07_4 == 1
	//3= Health
	
	label define loanreasonlbl 1 "Investment" 2 "Education" 3 "Health" 4 "Others"
	label values loan_reason loanreasonlbl
	la var loan_reason "Reason for taking loan"
	
	bys hhid psu district vdc: egen total_loan_amount = sum(s12q06), missing
	keep hhid psu district vdc s12q05 s12q06 loan_reason 
	duplicates drop hhid psu district vdc, force
	
	tempfile sec_12a
	save `sec_12a', replace	
restore

merge 1:1 hhid psu district vdc using `sec_12a', keepusing (s12q05 s12q06 loan_reason)
	
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                         2,080
        from master                     2,080  (_merge==1)
        from using                          0  (_merge==2)

    Matched                             3,971  (_merge==3)
    -----------------------------------------
*/

assert _merge != 2
drop _merge


*===================*
**# Section 13- Gifts and Transfers
*===================*

//sent from our household
preserve
	use "${data_raw}/Wave 3 - Household/Section_13a", clear
	egen total = rowtotal(s13q07a s13q07b) , missing
	bys hhid psu district vdc: egen total_otransfered_365 = total(total), missing
	la var total_otransfered_365 "Total amount transfered in cash or kind to other household in last year"
	
	bys hhid psu district vdc: egen otransfered_edu_365 = sum(s13q08a_3*total_otransfered_365), missing
	la var otransfered_edu_365 "Total amount in cash or kind sent for education from this household to other household"
	
	keep hhid psu district vdc total_otransfered_365 otransfered_edu_365
	duplicates drop hhid psu district vdc, force
	
	tempfile sec_13a
	save `sec_13a', replace
	
restore

merge 1:1 hhid psu district vdc using `sec_13a', keepusing(total_otransfered_365 otransfered_edu_365)

/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                         5,371
        from master                     5,371  (_merge==1)
        from using                          0  (_merge==2)

    Matched                               680  (_merge==3)
    -----------------------------------------

*/

assert _merge != 2
drop _merge

//recieved by our household

preserve
	use "${data_raw}/Wave 3 - Household/Section_13b", clear
	egen total = rowtotal(s13q16a s13q16b) , missing
	bys hhid psu district vdc: egen total_itransfered_365 = total(total), missing
	la var total_itransfered_365 "Total amount of cash or kind recieved from other household in last year"
	
	bys hhid psu district vdc: egen itransfered_edu = total(s13q17a_3), missing
	la var itransfered_edu "Any cash or kind recieved from other household for Education cost in last year"
	
	keep hhid psu district vdc total_itransfered_365 itransfered_edu 
	duplicates drop hhid psu district vdc, force
	
	tempfile sec_13b
	save `sec_13b', replace
	
restore

merge 1:1 hhid psu district vdc using `sec_13b', keepusing(total_itransfered_365 itransfered_edu)

/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                         5,965
        from master                     5,965  (_merge==1)
        from using                          0  (_merge==2)

    Matched                                86  (_merge==3)
    -----------------------------------------
*/

assert _merge != 2
drop _merge

//received from organizations
preserve
	use "${data_raw}/Wave 3 - Household/Section_13c", clear
	egen total = rowtotal(s13q19a s13q19c) , missing
	bys hhid psu district vdc: egen total_ireceived_365 = total(total), missing
	la var total_ireceived_365 "Total amount of cash or kind recieved (Privately) from organizations in last year"
	
	bys hhid psu district vdc: egen ireceived_edu = total(s13q21a_3), missing
	la var ireceived_edu "Any cash or kind recieved (Privately)  from organizations for Education cost in last year"
	
	keep hhid psu district vdc total_ireceived_365 ireceived_edu
	duplicates drop hhid psu district vdc, force
	
	tempfile sec_13c
	save `sec_13c', replace
	
restore

merge m:1 hhid psu district vdc using `sec_13c', keepusing(total_ireceived_365 ireceived_edu)


/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                         5,977
        from master                     5,977  (_merge==1)
        from using                          0  (_merge==2)

    Matched                                74  (_merge==3)
    -----------------------------------------
*/

assert _merge != 2
drop _merge

//Provided donations? 
merge 1:1 hhid psu district vdc using "${data_raw}/Wave 3 - Household/Section_13d", keepusing (s13q23)
rename s13q23 donation_amount_365

/*
	Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                             6,051  (_merge==3)
    -----------------------------------------

*/

assert _merge == 3
drop _merge

//Public Programs
preserve
	use "${data_raw}/Wave 3 - Household/Section_14a", clear 

	bys hhid psu district vdc: egen total_creceived_365 = total(s14q04b), missing
	la var total_creceived_365 "Total cash transfer received by entire household last year" 

	keep hhid psu district vdc total_creceived_365
	duplicates drop hhid psu district vdc, force 

	tempfile sec_14a
	save `sec_14a', replace 
restore

merge 1:1 hhid psu district vdc using `sec_14a', keepusing (total_creceived_365)


/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                             1
        from master                         1  (_merge==1)
        from using                          0  (_merge==2)

    Matched                             6,050  (_merge==3)
    -----------------------------------------


*/

assert _merge != 2
drop _merge

*------------------------------------------------------------------------------*
**#							Save file
*------------------------------------------------------------------------------*

gen survey_year = 2018
gen survey_level = "Family"

// Some aggregates
foreach var in edu_family_head total_edu_expense_365 rent_expense_365 total_utilities_expenditure_365 total_sfood_expense_365 total_food_expense_365 total_nfood_expense_365 total_nfoodi_expense_365  land_rent_365 total_land_investment_365 total_agri_expense_365 total_livestock_cost_365 total_livestock_rcost_365 total_agri_asset_cost_365 total_bus_asset_cost_365 total_otransfered_365{
	replace `var' = 0 if mi(`var')
	
}

egen total_expense_365 = rowtotal(total_edu_expense_365 total_food_expense_365 total_utilities_expenditure_365 total_sfood_expense_365 total_nfood_expense_365 total_nfoodi_expense_365 land_rent_365 total_land_investment_365 total_agri_expense_365 total_livestock_cost_365 total_livestock_rcost_365 total_agri_asset_cost_365 total_bus_asset_cost_365 total_otransfered_365), missing 
la var total_expense_365 "Total Expense in last 1 year"

* Top code total_expense_365
qui sum total_expense_365
replace total_expense_365 = . if total_expense_365>`=`r(mean)' + 3*`r(sd)''

order hhid-children_in_school edu_family_head total_expense_365 total_edu_expense_365 rent_expense_365 total_utilities_expenditure_365 total_sfood_expense_365 total_food_expense_365 total_nfood_expense_365 total_nfoodi_expense_365  land_rent_365 total_land_investment_365 total_agri_expense_365 total_livestock_cost_365 total_livestock_rcost_365 total_agri_asset_cost_365 total_bus_asset_cost_365 total_otransfered_365 survey_year survey_level



compress
save $hrvs_family_2018, replace



*------------------------------------------------------------------------------*
**#							End of do file
*------------------------------------------------------------------------------*
	cap log close
	exit
*------------------------------------------------------------------------------*












