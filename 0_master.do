*------------------------------------------------------------------------------*
*           		 This is a master do file       				           *
/*

	Author:				Anubhav
	Date updated:		

	Notes:				This file lists all the STATA and Python scripts
						-in order- to replicate works for the paper
						"Disaster Exposure as an Instrument".
						Please note that the figure and table outputs are 
						manually uploaded to overleaf document:
						"https://www.overleaf.com/read/byttgnshfhtz#0a84f4"
			
	Dependencies:		This do file is not dependendent on any other do files.

*/

*------------------------------------------------------------------------------*
**#							STATA setups       								    
*------------------------------------------------------------------------------*

local dofilename "0_master"
version 17
clear all
macro drop _all
cap log close
set rmsg on	
set more off
cap clear frames

	*--------------------------------------------------------------------------*
	**# Folder macros (global)
	
	if "`c(username)'" == "anubh" {
		global workspace "C:\Users\anubh\OneDrive\HRVS 2016-2018 panel"
	}
	else if "`c(username)'" == "Lenovo" {
		global workspace "D:\OneDrive_2025-04-12\HRVS 2016-2018 panel"
	}

	
	
	*--------------------------------------------------------------------------*
	**# Sub folder macros (global)
	global	data			"$workspace/1_data"
		gl	data_raw		"$data/1_raw"
		gl	data_clean		"$data/2_clean"
		gl	data_analysis	"$data/3_analysis"
		gl	data_tmp		"$data/4_tmp"
	global	prep			"$workspace/2_prep"
	global	analysis		"$workspace/3_analysis"	
	global	log				"$workspace/4_log"
	global	fig				"$workspace/5_fig"
	global	tab				"$workspace/6_tab"
	
	*--------------------------------------------------------------------------*
	**# Macros check
	
	** No need to change following codes
	if "$workspace" == "" {
		di as error "Please set up workspace directory"
		exit
	} 
	
	*--------------------------------------------------------------------------*
	**# Packages check
	
	** Setting ado path
	adopath + "${prep}/ado"
	adopath + "${analysis}/ado"
	
	** List all required packages below as local. !! No SPACES in package name !!
	local packages "estout texify"
	
	foreach package in `packages' {
		cap which `package'
		if _rc {
			if "`package'"=="estout" {
				** Steps to install specific package
				ssc install estout
			}
			if "`package'"=="texify" {
				** Steps to install specific package
				ssc install texify
			}
			else {
				di as error "Need to install following package: `package'"
				search `package'
			}
		}
	}
	
	*--------------------------------------------------------------------------*
	**# Date/time macro (global)
	** Following is useful for hourly log purpose
	local datehour =ustrregexra(regexr("`c(current_date)'"," 20","") +"_"+regexr("`c(current_time)'",":[0-9]+:[0-9]+","")," ","") //saves string in 4Mar23_13 format, equivalent to 4th march 2023, 13 hour.
	
*------------------------------------------------------------------------------*
**#							Setting directory
/*
	Please avoid changing directory frequently during a STATA session. 
	Subsequent do files might be dependent on setting of directory to "workspace"
	folder. This avoids breakage of scripts. In cases where changing directory 
	is unavoidable, do change them back to "workspace" folder.
*/      								    
*------------------------------------------------------------------------------*

cd "$workspace"

exit

*------------------------------------------------------------------------------*
**#	Prep Data (files inside $prep directory)     								    
*------------------------------------------------------------------------------*
// doedit "$prep/01_hrvs_indi_2016.do" //Individual level (commented out for now)
doedit "$prep/02_hrvs_family_2016.do"
// doedit "$prep/03_hrvs_indi_2017.do" //Individual level (commented out for now)
doedit "$prep/04_hrvs_family_2017.do"
doedit "$prep/06_hrvs_family_2018.do"

** Python files (note that this cannot be run from here)
01p_vdcs_geo_list_hrvs.py // Uses community (VDCs) list from 01_hrvs_indi_2016.do to find geo location on google maps api
02p_vdc_hrvs_eq_intense.py // Merges earthquake data, calculates intensity for each community for each year.


doedit "$prep/07_hrvs_family_expenses.do"


*------------------------------------------------------------------------------*
**#	Analysis (files inside $analysis directory)						    
*------------------------------------------------------------------------------*
doedit "$analysis/01_eda.do"
07_fig_earthquakes.py
doedit "$analysis/08_tab_summary_stats"
doedit "$analysis/09_tab_first_stage"
doedit "$analysis/10_tab_second_stage"


*------------------------------------------------------------------------------*		
**#							End of do file
*------------------------------------------------------------------------------*
	exit
*------------------------------------------------------------------------------*