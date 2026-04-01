*------------------------------------------------------------------------------*
*            				EDA						                   *
/*

	Author:				Anubhav
	Date created:		29th Oct 2023

	Notes:
			
	Dependencies:		Run master do file for global file/folder path macros
						"$prep/07_hrvs_family_expenses.do"
*/
{
*------------------------------------------------------------------------------*
**#							STATA setups       								    
*------------------------------------------------------------------------------*
clear
cap clear frames
set more off
set rmsg on
local dofilename "01_eda"
cap log close

	*--------------------------------------------------------------------------*
	**# Import macros (global)
	global hrvs_family_expenses ""$data_analysis/hrvs_family_expenses""
	
	*--------------------------------------------------------------------------*
	**# Export macros (global)
	
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
**#	Load data
// set maxvar 120000

use $hrvs_family_expenses, clear

keep if inlist(survey_year, 2017, 2018)
foreach var in total_expense_365 total_edu_expense_365 total_food_expense_365 total_utilities_expenditure_365 total_sfood_expense_365 total_nfood_expense_365 total_nfoodi_expense_365 land_rent_365 total_land_investment_365 total_agri_expense_365 total_livestock_cost_365 total_livestock_rcost_365 total_agri_asset_cost_365 total_bus_asset_cost_365 total_otransfered_365 {
	
			qui{				
			eststo reg_1: reg `var' Intensity_1 i.ethnicity i.edu_family_head mean_level_school children_in_school members_per_household i.community_id i.survey_year
				estadd local com_fe "\checkmark" 
				estadd local time_fe "\checkmark" 
				estadd local family_fe "\checkmark"
	
			eststo reg_2: reg `var' Intensity_1_1 i.ethnicity i.edu_family_head mean_level_school children_in_school members_per_household i.community_id i.survey_year
			
			eststo reg_3: reg `var' Intensity_2 i.ethnicity i.edu_family_head mean_level_school children_in_school members_per_household i.community_id i.survey_year
						
			eststo reg_4: reg `var' Intensity_2_1 i.ethnicity i.edu_family_head mean_level_school children_in_school members_per_household i.community_id i.survey_year
		}

		di "`var'"
		esttab 	reg_1 reg_2 reg_3 reg_4, ///
				mtitle() ///
				cells(b(fmt(%9.3f) star) se(par fmt(%9.3f))) ///
				starlevels(* .1 ** .05 *** .01) ///
				keep(Intensity_1 Intensity_1_1 Intensity_2 Intensity_2_1 mean_level_school children_in_school members_per_household) ///
				stats(N r2 , label("N" "R2") fmt(%9.3gc)) ///
				varlabels(mean_level_school "Avg. Grade" ///
						  children_in_school "# in School" ///
						  members_per_household "# Members" ///
				) ///
				note("Levels of significance: *\$p<0.1\$, **\$p<0.05\$, ***\$p<0.01\$")
}		

exit

*------------------------------------------------------------------------------*		
**#							End of do file
*------------------------------------------------------------------------------*
	cap log close
	exit
*------------------------------------------------------------------------------*