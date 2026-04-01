*------------------------------------------------------------------------------*
*            				Summary stats table				                   *
/*

	Author:				Anubhav
	Date created:		20th April 2025

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
local dofilename "08_tab_summary_stats"
cap log close
	
	*--------------------------------------------------------------------------*
	**# Import macros (global)
	global hrvs_family_expenses ""$data_analysis/hrvs_family_expenses""
	
	*--------------------------------------------------------------------------*
	**# Export macros (global)
	global tab_summay_stats ""${tab}/tab_summay_stats.tex""
	global tab_summay_stats_balance ""${tab}/tab_summay_stats_balance.tex""
	
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
**#	Load dataset

use $hrvs_family_expenses, clear

keep if inlist(survey_year, 2017, 2018)

gen high_caste = inlist(ethnicity, 12, 13, 19, 71) // Brahman, Chetttri, newar

foreach var in total_expense_365 total_edu_expense_36 {
	replace `var' = `var'/10000 // In ten thousand rupees
}

eststo clear

local var Intensity_1 total_expense_365 total_edu_expense_365 edu_family_head children_in_school mean_level_school members_per_household high_caste


estpost summarize `var' if !mi(Intensity_1, total_expense_365, total_edu_expense_365, edu_family_head, children_in_school, mean_level_school, members_per_household, high_caste)

esttab using ${tab_summay_stats}, replace nogap nomtitle nonumber ///
		title("Summary Statistics \label{tab_summay_stats}") /// 
		cells("mean(label(Mean) fmt(%9.3g)) sd min(label(Min) fmt(%9.3g)) max(label(Max) fmt(%9.3g))")  ///
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
			 "Note: This table summarizes the key variables used in the analysis. The number of observations is slightly below the full sample of 12,056 (approximately 6,000 families surveyed over two years) because families with no members enrolled in school were excluded. Nepali Rupees (NRs.) is reported in ten thousands." ///
			 "\end{tablenotes}"	///				
			 "\end{threeparttable}"	///
			 "}"				///	
			 "\end{table}")
		
eststo clear	
foreach year in 2016 2017 2018{
	preserve
		if `year'!=2016{
			keep if survey_year==`year'	
		}
		qui sum Intensity_1, d
		gen above_median = Intensity_1 > r(p50)
		
		qui eststo bt_`year': estpost ttest total_expense_365 total_edu_expense_365 edu_family_head children_in_school mean_level_school members_per_household high_caste if !mi(Intensity_1, total_expense_365, total_edu_expense_365, edu_family_head, children_in_school, mean_level_school, members_per_household, high_caste), by(above_median)
		
	restore
}

esttab bt_2017 bt_2018 bt_2016 ///
		using ${tab_summay_stats_balance}, replace nogap nonumber se ///
		title("Balance Table \label{tab_summay_stats_balance}") /// 
		mtitle("2017" "2018" "All Sample") ///
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
			 "\item[] Note: This table compares mean values between families exposed to above-median and below-median earthquake intensity. Column 1 presents results for 2017, where groups are defined using intensity measured in that year; Column 2 follows the same approach for 2018. Column 3 pools data from both years and defines above/below median groups based on the combined distribution of intensity. Nepali Rupees (NRs.) is reported in ten thousands." ///
			 "\end{tablenotes}"	///				
			 "\end{threeparttable}"	///
			 "}"				///	
			 "\end{table}")
		
exit
*------------------------------------------------------------------------------*
**#							End of do file
*------------------------------------------------------------------------------*
	cap log close
	exit
*------------------------------------------------------------------------------*