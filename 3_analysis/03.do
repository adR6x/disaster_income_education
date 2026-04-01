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
cap log close

local dofilename "total_food_expense_2017_18_fe"
cap log close

	
** Following is useful for hourly log purpose
local datehour =ustrregexra(regexr("`c(current_date)'"," 20","")+"_"+regexr("`c(current_time)'",":[0-9]+:[0-9]+","")," ","") //saves string in 4Mar23_13 format, equivalent to 4th march 2023, 13 hour.
	
*------------------------------------------------------------------------------*
**#							Log start       								    
*------------------------------------------------------------------------------*	
	
log using "C:\Users\anubh\OneDrive\HRVS 2016-2018 panel\4_log/`dofilename'_`datehour'", replace
	
}
	
use "C:\Users\anubh\OneDrive\HRVS 2016-2018 panel\1_data\3_analysis\hrvs_family_expenses.dta", clear


// total_edu_expense_365  
keep if inlist(survey_year, 2017, 2018)

foreach var in total_food_expense_365 {
	
		{				
			eststo reg_1: reg `var' Intensity_1 i.ethnicity i.edu_family_head mean_level_school children_in_school members_per_household i.community_id i.survey_year
			
			eststo reg_2: reg `var' Intensity_1 i.ethnicity i.edu_family_head mean_level_school children_in_school members_per_household i.community_id i.survey_year i.family_id

		}

		di "`var'"
		esttab 	reg_1 reg_2, ///
				mtitle() ///
				cells(b(fmt(%9.3f) star) se(par fmt(%9.3f))) ///
				starlevels(* .1 ** .05 *** .01) ///
				keep(Intensity_1 mean_level_school children_in_school members_per_household) ///
				stats(N r2 , label("N" "R2") fmt(%9.3gc)) ///
				varlabels(mean_level_school "Avg. Grade" ///
						  children_in_school "# in School" ///
						  members_per_household "# Members" ///
				) ///
				note("Levels of significance: *\$p<0.1\$, **\$p<0.05\$, ***\$p<0.01\$")
}		

*------------------------------------------------------------------------------*		
**#							End of do file
*------------------------------------------------------------------------------*
	cap log close
*------------------------------------------------------------------------------*