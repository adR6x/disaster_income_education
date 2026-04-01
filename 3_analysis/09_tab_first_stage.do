*------------------------------------------------------------------------------*
*            			First Stage Regression   			                   *
/*

	Author:				Anubhav
	Date created:		20th April 2025

	Notes:				This do file runs and saves the first stage
						regression for the paper:
						"Disaster Exposure as an Instrument".
						Please note that the figure and table outputs are 
						manually uploaded to overleaf document:
						"https://www.overleaf.com/read/byttgnshfhtz#0a84f4"
			
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
local dofilename "09_tab_first_stage"
cap log close
	
	*--------------------------------------------------------------------------*
	**# Double Check if Master do file was run
	if "$workspace" == "" {
		di as error "Please set up workspace directory"
		exit
	}
	
	*--------------------------------------------------------------------------*
	**# Imports on the dofile
	global hrvs_family_expenses ""$data_analysis/hrvs_family_expenses""
	
	*--------------------------------------------------------------------------*
	**# Exports from the dofile
	global tab_first_stage ""${tab}/tab_first_stage.tex""
	global hrvs_family_expenses_1stage ""${data_tmp}/hrvs_family_expenses_1stage""
	
	*--------------------------------------------------------------------------*
	**# Logs (at least every hour)
	local datehour =ustrregexra(regexr("`c(current_date)'"," 20","")+"_"+regexr("`c(current_time)'",":[0-9]+:[0-9]+","")," ","") //saves string in 4Mar23_13 format, equivalent to 4th march 2023, 13 hour.
	
*------------------------------------------------------------------------------*
**#							Log start       								    
*------------------------------------------------------------------------------*	
	
	log using "$log/`dofilename'_`datehour'", replace
	
}	

*------------------------------------------------------------------------------*
**#	Load Prepped dataset
*------------------------------------------------------------------------------*

use $hrvs_family_expenses, clear

*------------------------------------------------------------------------------*
**#	Data prep before regression
*------------------------------------------------------------------------------*

** Keep 2 years panel
keep if inlist(survey_year, 2017, 2018)

** High Caste indicator (=1)
gen high_caste = inlist(ethnicity, 12, 13, 19, 71) // Brahman, Chetttri, newar

** Currency scale
foreach var in total_expense_365 total_edu_expense_36 {
	replace `var' = `var'/10000 // In ten thousand rupees
}

*------------------------------------------------------------------------------*
**#	Regression
*------------------------------------------------------------------------------*

local var Intensity_1 total_expense_365 total_edu_expense_365 edu_family_head children_in_school mean_level_school members_per_household high_caste

eststo clear

qui{
	
	* Model 1
	eststo reg_1: reg total_expense_365 Intensity_1 edu_family_head children_in_school mean_level_school members_per_household high_caste i.survey_year, vce(cluster community_id)
	estadd local com_fe "" 
	estadd local time_fe "\checkmark" 
	estadd local family_fe ""
	
	* Model 2
	eststo reg_2: reg total_expense_365 Intensity_1 edu_family_head children_in_school mean_level_school members_per_household high_caste i.survey_year i.community_id, vce(cluster community_id)
	estadd local com_fe "\checkmark"  
	estadd local time_fe "\checkmark"
	estadd local family_fe ""
	
	* Model 3
	eststo reg_3: reg total_expense_365 Intensity_1 edu_family_head children_in_school mean_level_school members_per_household i.survey_year i.community_id i.family_id, vce(cluster community_id)
	estadd local com_fe "\checkmark"  
	estadd local time_fe "\checkmark"
	estadd local family_fe "\checkmark"
	
	predict total_expense_365_pred, xb
	la var total_expense_365_pred "First stage predicted total expenses"
	
}

*------------------------------------------------------------------------------*
**#	Write the table on Latex Format
*------------------------------------------------------------------------------*

** Keeping just Model 2 and 3
esttab  reg_2 reg_3 ///
	using ${tab_first_stage}, replace noobs nomtitles ///
	title("Total expediture of families and Earthquake Intensity\label{tab_first_stage}") ///
	booktabs cells(b(fmt(%9.3f) star) se(par fmt(%9.3f))) ///
	starlevels(* .1 ** .05 *** .01) ///
	keep(Intensity_1 edu_family_head children_in_school mean_level_school members_per_household high_caste)  ///
	order(Intensity_1 edu_family_head children_in_school mean_level_school members_per_household high_caste) ///
	stats(com_fe time_fe family_fe r2 N_clust N, label("Community FE" "Time FE" "Family FE" "R-squared" "\# Communities" "\# Observations") fmt(%9.3gc)) noeqlines ///
	collabels(none) label substitute(\_ _) ///
	varlabels(Intensity_1 "Earthquake Intensity" ///
		total_expense_365 "Total Spending (NRs.)" ///
		total_edu_expense_365 "Education Spending (NRs.)" ///
		edu_family_head "Family Head Education" ///
		mean_level_school "Average grade enrolled" ///
		children_in_school "\# Enrolled in School" ///
		members_per_household "Family Size" ///
		high_caste "BCN Caste (=1)" ///
	) ///
	prehead("\begin{table}[htbp]\centering"	///
		"\scalebox{1}{"	///
		"\begin{threeparttable}[b]" ///
		"\caption{@title}"	///
		"\begin{tabular}{l*{@span}{c}}"	///
		"\toprule"			///
		"\addlinespace") ///
	postfoot("\bottomrule"	///
		 "\end{tabular}"	///
		 "\begin{tablenotes}"	///
		 "\item[] Note: Nepali Rupees (NRs.) is reported in ten thousands. Standard errors clustered at the level of the community are reported in parentheses." ///
		 "\end{tablenotes}"	///				
		 "\end{threeparttable}"	///
		 "}"				///	
		 "\end{table}")
	
*------------------------------------------------------------------------------*
**# Saving data
*------------------------------------------------------------------------------*
	
keep total_edu_expense_365 total_expense_365 total_expense_365_pred Intensity_1 edu_family_head children_in_school mean_level_school members_per_household survey_year community_id family_id high_caste
compress
save $hrvs_family_expenses_1stage, replace

*------------------------------------------------------------------------------*
**#							End of do file
*------------------------------------------------------------------------------*
	cap log close
	exit
*------------------------------------------------------------------------------*