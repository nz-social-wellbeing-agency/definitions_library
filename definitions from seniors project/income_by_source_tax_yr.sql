/**************************************************************************************************
Title: Tax year income, by source 
Author: Verity Warn
Reviewer: Manjusha Radhakrishnan

Inputs & Dependencies:
- [IDI_Clean_202203].[data].[income_tax_yr]
Outputs:
- [IDI_Sandpit].[DL-MAA2018-48].[defn_income_by_source]

Description:
Tax year income, seperated out into sources

Intended purpose:
Using income components as indicators/variables in the MSD seniors project, as well as summing these to get a total income variable.

Notes:
1) Subgroups are (as defined in Freya's annual_income_bnt.sql definition) :
	- ACC = ACC claimants compensation 
	- BEN = Benefits (T1 only??)
	- C00 = Company director/shareholder income from IR4S
	- C01 = Company director/shareholder receiving PAYE deducted income 
	- C02 = Company director/shareholder receiving WHT deducted income 
	- P00 = Partnership income from IR20
	- P01 = Partner receiving PAYE deducted income 
	- P02 = Partner receiving withholding tax deducted income 
	- PEN = Pensions (superannuation) 
	- PPL = Paid parental leave 
	- S00 = Sole trader income from IR3
	- S01 = Sole trader receiving PAYE deducted income 
	- S02 = Sole trader receiving withholding tax deducted income 
	- S03 = Rental income from IR3
	- STU = Student allowance 
	- WAS = Wages & salaries 
	- WHP = Withholding payments (schedular payments with withholding taxes) 
2) Values are not inflation adjusted, this is done in data tidying phase, see I:\MAA2018-48 Modelling Social Outcomes\2022\Senior\analysis\tidy_variables - manual R.R

Issues:


Parameters & Present values:
  Current refresh = 202203 
  Prefix = defn_
  Project schema = [DL-MAA2018-48]
   
Issues:

History (reverse order):
2022-06-20 VW Grouped income into categories 
2022-06-14 SA QA, VW adjusted documentation based on feedback
2022-05-23 VW Created definition
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[defn_income_tax_year]
GO

SELECT snz_uid
	  ,DATEFROMPARTS([inc_tax_yr_sum_year_nbr] - 1,  4,  1) AS [start_date] -- tax year end e.g. 2022 means starts in 2021
	  ,DATEFROMPARTS([inc_tax_yr_sum_year_nbr], 3, 31) AS [end_date]
      ,[inc_tax_yr_sum_ACC_tot_amt] /* ACC claimants compensation */
	  ,[inc_tax_yr_sum_BEN_tot_amt] /* T1 benefits */
	  ,[inc_tax_yr_sum_C00_tot_amt] + [inc_tax_yr_sum_C01_tot_amt] + [inc_tax_yr_sum_C02_tot_amt] AS [inc_tax_yr_sum_C0X_tot_amt]
			/* Company director/shareholder income from IR4S + Company director/shareholder receiving PAYE deducted income + Company director/shareholder receiving WHT deducted income  */
      ,[inc_tax_yr_sum_P00_tot_amt] + [inc_tax_yr_sum_P01_tot_amt] + [inc_tax_yr_sum_P02_tot_amt] AS [inc_tax_yr_sum_P0X_tot_amt]
			/* Partnership income from IR20 + Partner receiving PAYE deducted income + Partner receiving withholding tax deducted income*/
	  ,[inc_tax_yr_sum_PEN_tot_amt] /* pensions (superannuation) */
      ,[inc_tax_yr_sum_PPL_tot_amt] /* Paid parental leave */
      ,[inc_tax_yr_sum_S00_tot_amt] + [inc_tax_yr_sum_S01_tot_amt] + [inc_tax_yr_sum_S02_tot_amt] AS [inc_tax_yr_sum_S0X_excl_S03]
			/* Sole trader income from IR3 + Sole Trader receiving PAYE deducted income + Sole trader receiving withholding tax deducted income */
      ,[inc_tax_yr_sum_S03_tot_amt] /* Rental income from IR3 */ 
	  ,[inc_tax_yr_sum_STU_tot_amt] /* Student allowance */
	  ,[inc_tax_yr_sum_WAS_tot_amt] /* Wages & salaries */
      ,[inc_tax_yr_sum_WHP_tot_amt] /* Withholding payments (schedular payments with withholding taxes) */
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_income_tax_year]
FROM [IDI_Clean_202203].[data].[income_tax_yr_summary]
WHERE inc_tax_yr_sum_year_nbr > 2010 -- Reducing table size by dropping irrelevant years

/* Index and compress to save space and time */

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2018-48].[defn_income_tax_year] (snz_uid);
GO

ALTER TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_income_tax_year] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)


