/**************************************************************************************************
Title: Tax year income summary
Author: Simon Anastasiadis
Reviewer: Marianna Pekar

Inputs & Dependencies:
- [IDI_Clean].[data].[income_tax_yr_summary]
Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2g_income_tax_year]

Description:
Summary of income for each tax year.

Intended purpose:
Calculating annual income from different sources and in grand total.
 
Notes:
1) Following a conversation with a staff member from IRD we were advised to use
   - IR3 data where possible.
   - PTS data where IR3 is not available
   - EMS date where IR3 and PTS are not available.
2) A comparison of total incomes from these three sources showed excellent consistency
   between [ir_ir3_gross_earnings_407_amt], [ir_pts_tot_gross_earnings_amt], [ir_ems_gross_earnings_amt]
   with more than 90% of our sample of records having identical values across all three.
3) However, rather than combine IR3, PTS and EMS ourselves we use the existing [income_tax_yr_summary]
   table as it addresses the same concern and is already a standard table.
4) Unlike EMS where W&S and WHP are reported directly, the tax year summary table re-assigns some
   W&S and WHP to the S0*, P0*, C0* categories. Hence sum(WHP) from tax year summary will not be
   consistent with sum(WHP) from IRD-EMS. You can see in the descriptions that S/C/P01 have PAYE
   and hence will (probably) appear in IRD-EMS as W&S, while S/C/P02 have WHT deducted and hence
   will (probably) appear in IRD-EMS as WHP.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = d2g_
  Project schema = [DL-MAA2020-01]
 
Issues:
- IR3 records in the IDI do not capture all income reported to IRD via IR3 records. As per the data
  dictionary only "active items that have non-zero partnership, self-employment, or shareholder salary
  income" are included. So people with IR3 income that is of a different type (e.g. rental income)
  may not appear in the data.
 
History (reverse order):
2020-07-16 MP QA
2020-03-02 SA v1
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

/* Wages and salaries by tax year */
IF OBJECT_ID('[DL-MAA2020-01].[d2g_income_tax_year]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2g_income_tax_year];
GO

CREATE VIEW [DL-MAA2020-01].[d2g_income_tax_year] AS
SELECT [snz_uid]
	  ,[inc_tax_yr_sum_year_nbr]
	  ,DATEFROMPARTS([inc_tax_yr_sum_year_nbr],  3, 31) AS [event_date]
	  ,DATEFROMPARTS([inc_tax_yr_sum_year_nbr],  1,  1) AS [start_date]
	  ,DATEFROMPARTS([inc_tax_yr_sum_year_nbr], 12, 31) AS [end_date]
      ,[inc_tax_yr_sum_WAS_tot_amt] /* wages & salaries */
      ,[inc_tax_yr_sum_WHP_tot_amt] /* withholding payments (schedular payments with withholding taxes) */
      ,[inc_tax_yr_sum_BEN_tot_amt] /* benefits */
      ,[inc_tax_yr_sum_ACC_tot_amt] /* ACC claimants compensation */
      ,[inc_tax_yr_sum_PEN_tot_amt] /* pensions (superannuation) */
      ,[inc_tax_yr_sum_PPL_tot_amt] /* Paid parental leave */
      ,[inc_tax_yr_sum_STU_tot_amt] /* Student allowance */
      ,[inc_tax_yr_sum_C00_tot_amt] /* Company director/shareholder income from IR4S */
      ,[inc_tax_yr_sum_C01_tot_amt] /* Comapny director/shareholder receiving PAYE deducted income */
      ,[inc_tax_yr_sum_C02_tot_amt] /* Company director/shareholder receiving WHT deducted income */
      ,[inc_tax_yr_sum_P00_tot_amt] /* Partnership income from IR20 */
      ,[inc_tax_yr_sum_P01_tot_amt] /* Partner receiving PAYE deducted income */
      ,[inc_tax_yr_sum_P02_tot_amt] /* Partner receiving withholding tax deducted income */
      ,[inc_tax_yr_sum_S00_tot_amt] /* Sole trader income from IR3 */
      ,[inc_tax_yr_sum_S01_tot_amt] /* Sole Trader receiving PAYE deducted income */
      ,[inc_tax_yr_sum_S02_tot_amt] /* Sole trader receiving withholding tax deducted income */
      ,[inc_tax_yr_sum_S03_tot_amt] /* Rental income from IR3 */
      ,[inc_tax_yr_sum_all_srces_tot_amt]
FROM [IDI_Clean_20200120].[data].[income_tax_yr_summary];
GO

/* Code for making the comparison between IR3, PTS, and EMS: */
/*
SELECT TOP 1000 ir3.[snz_uid]
      ,[ir_ir3_return_period_date]
      ,[ir_ir3_gross_earnings_407_amt] AS ir3_gross_income
      ,[ir_ir3_taxable_income_amt] AS ir3_taxable_income
      ,[ir_pts_tot_gross_earnings_amt] AS pts_gross_income
      ,[ir_pts_taxable_inc_amt] AS pts_taxable_income
	  ,[ir_ems_gross_earnings_amt] AS ems_gross_income
FROM [IDI_Clean_20200120].[ir_clean].[ird_rtns_keypoints_ir3] ir3
INNER JOIN [IDI_Clean_20200120].[ir_clean].[ird_pts] pts
ON ir3.snz_uid = pts.snz_uid
INNER JOIN (

SELECT [snz_uid]
      ,2018 AS the_year
      ,SUM([ir_ems_gross_earnings_amt]) AS [ir_ems_gross_earnings_amt]
FROM [IDI_Clean_20200120].[ir_clean].[ird_ems]
WHERE YEAR(DATEADD(MONTH, 9, [ir_ems_return_period_date])) = 2018
GROUP BY [snz_uid]

) ems
ON ir3.snz_uid = ems.snz_uid
AND YEAR([ir_ir3_return_period_date]) = the_year
WHERE the_year = 2018
AND YEAR([ir_ir3_return_period_date]) = 2018
AND YEAR([ir_pts_return_period_date]) = 2018
*/
