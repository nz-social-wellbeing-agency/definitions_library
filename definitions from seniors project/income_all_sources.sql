/***************************************************************************************************************************************
Title: Tax year income summary (including benefits)
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean_202203].[data].[income_cal_yr]
- [IDI_Clean_202203].[msd_clean].[msd_second_tier_expenditure]
- [IDI_Clean_202203].[msd_clean].[msd_third_tier_expenditure]
- [IDI_Clean_202203].[wff_clean].[fam_return_dtls]
Output:
- [IDI_UserCode].[DL-MAA2018-48].[defn_taxable_income_calendar_year]
- [IDI_UserCode].[DL-MAA2018-48].[defn_nontaxable_T2_benefit_income]
- [IDI_UserCode].[DL-MAA2018-48].[defn_nontaxable_T3_benefit_income]
- [IDI_Sandpit].[DL-MAA2018-48].[defn_nontaxable_wff_income]

Description:
Summary of total income (including non-taxible income) for each tax year.

Intended purpose:
Calculating annual income (including 2nd tier benefit , 3rd tier benefit and WWF) from different sources and in grand total.

Intended purpose:
Calculating annual total income (including non-taxible income)
from different sources and in grand total.
Identifying whether a person received income from any source
(taxible and non-taxible).


Notes:
1. Not all income is taxible. 2nd tier benefits, 3rd tier benefits, and WfF tax credits are non-taxible and hence are not
	reported to IRD. This income is not part of annual total taxible income but is part of annual total income.
	Complete income can be created from four tables:
	[msd_second_tier_expenditure]		April    1990 – July  2020
	[msd_third_tier_expenditure]		November 2009 – July  2020
	[wff_clean].[fam_return_dtls]		March    2000 – March 2020
	[income_cal_yr_summary]				April    1995 – March 2020

2. Some people have benefit or WfF as their only source of income.
	There are around 3% of data in second tier benefit couldn't link to ir data every year.
	There are around 2% of data in third tier benefit couldn't link to ir data every year.
	There are around 10% of data in wff couldn't link to ir data every year. 
	Potential reason is that IR records only include the "active items that have non-zero partnership, self-employment,
	or shareholder salary income".

3. In the table [IDI_Clean].[msd_clean].[msd_third_tier_expenditure], we only consider [msd_tte_recoverable_ind] = 'N', 
	as [msd_tte_recoverable_ind] = 'Y' means the participants have to pay back the money.

4. Around 3.5% of WfF payments ([wff_pmt] column) give negative values. This is likely correction for overpayment.
	- More than 95% of these negative values are smaller than -50.
	- 22% of the population have ever have a negative WfF payment.
	- 6% of the population have overall negative WfF payment if we sum over all years.
	To solve this, we add the negative WfF payment back, and deduct the abs(negative) from the previous year. This reduces
	the percent of negative payments to 2%.
	However, 16% people still have at least on negative WfF payment. This is because two successive years have negative
	payments, the payment the previous year is smaller than the negative amount, or the overall payment is negative.
	                             year1, year2, year3, year4, year5, year6
	eg. raw WfF payments of       $600,  $200, -$400,  $300, -$100, -$200
	   after ajustment would be   $600, -$200,    $0,  $200, -$200,    $0

5. Due to differences in date intervals in the source datasets are provided, care is required when assembling.
	The most likely setting are:
	[defn_taxable_income_calendar_year] and [defn_nontaxable_T3_benefit_income]: proportional = FALSE
	[defn_nontaxable_T2_benefit_income] and [defn_nontaxable_wff_income]: proportional = TRUE

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]


Issues:

History (reverse order):
2022-06-14 VW Alter tier 2 join to benefit types to include dates as well as benefit type codes (as per SA QA)
2022-05-04 VW Update to latest refresh (202203), remove time span (tool will edit, panel 2006 on)
2021-11-22 MR Update latest refresh (20211020)
2021-10-14 SA v1 starting from annual_income_bnt.sql definition by Freya Li
***************************************************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

/*********************************************************************
taxable income
*********************************************************************/

DROP VIEW IF EXISTS [DL-MAA2018-48].[defn_taxable_income_calendar_year];
GO

CREATE VIEW [DL-MAA2018-48].[defn_taxable_income_calendar_year] AS
SELECT [snz_uid]
	,[snz_ird_uid]
	,[snz_employer_ird_uid]
	,[inc_cal_yr_year_nbr]
	,[inc_cal_yr_income_source_code]
	,[inc_cal_yr_withholding_type_code]
	,[inc_cal_yr_mth_01_amt]
	,[inc_cal_yr_mth_02_amt]
	,[inc_cal_yr_mth_03_amt]
	,[inc_cal_yr_mth_04_amt]
	,[inc_cal_yr_mth_05_amt]
	,[inc_cal_yr_mth_06_amt]
	,[inc_cal_yr_mth_07_amt]
	,[inc_cal_yr_mth_08_amt]
	,[inc_cal_yr_mth_09_amt]
	,[inc_cal_yr_mth_10_amt]
	,[inc_cal_yr_mth_11_amt]
	,[inc_cal_yr_mth_12_amt]
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 01, 15) AS date_mth_01
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 02, 15) AS date_mth_02
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 03, 15) AS date_mth_03
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 04, 15) AS date_mth_04
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 05, 15) AS date_mth_05
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 06, 15) AS date_mth_06
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 07, 15) AS date_mth_07
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 08, 15) AS date_mth_08
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 09, 15) AS date_mth_09
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 10, 15) AS date_mth_10
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 11, 15) AS date_mth_11
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 12, 15) AS date_mth_12
	,[inc_cal_yr_mth_01_amt] + [inc_cal_yr_mth_02_amt] + [inc_cal_yr_mth_03_amt] AS inc_cal_yr_qtr_1_amt
	,[inc_cal_yr_mth_04_amt] + [inc_cal_yr_mth_05_amt] + [inc_cal_yr_mth_06_amt] AS inc_cal_yr_qtr_2_amt
	,[inc_cal_yr_mth_07_amt] + [inc_cal_yr_mth_08_amt] + [inc_cal_yr_mth_09_amt] AS inc_cal_yr_qtr_3_amt
	,[inc_cal_yr_mth_10_amt] + [inc_cal_yr_mth_11_amt] + [inc_cal_yr_mth_12_amt] AS inc_cal_yr_qtr_4_amt
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 02, 15) AS date_qtr_1
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 05, 15) AS date_qtr_2
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 08, 15) AS date_qtr_3
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 11, 15) AS date_qtr_4
	,[inc_cal_yr_tot_yr_amt]
	,DATEFROMPARTS([inc_cal_yr_year_nbr], 12, 15) AS date_year
FROM [IDI_Clean_202203].[data].[income_cal_yr]
GO

/*********************************************************************
second tier benefits by tax year
*********************************************************************/

DROP VIEW IF EXISTS [DL-MAA2018-48].[defn_nontaxable_T2_benefit_income];
GO

CREATE VIEW [DL-MAA2018-48].[defn_nontaxable_T2_benefit_income] AS
SELECT [snz_uid]
	,[msd_ste_start_date]
	,[msd_ste_end_date]
	,level1 AS benefit_name
	,[msd_ste_daily_gross_amt]
	,[msd_ste_period_nbr] -- equals number of days start-to-end inclusive
	,ROUND([msd_ste_period_nbr] * [msd_ste_daily_gross_amt], 2) AS [gross_payment] 
FROM [IDI_Clean_202203].[msd_clean].[msd_second_tier_expenditure] AS k
LEFT JOIN [IDI_Adhoc].[clean_read_MSD].[benefit_codes] code
ON k.msd_ste_supp_serv_code = code.serv
AND code.ValidFromtxt <= k.[msd_ste_start_date]
AND k.[msd_ste_start_date] <= code.ValidTotxt
GO

/*********************************************************************
third tier benefits by tax year
*********************************************************************/

DROP VIEW IF EXISTS [DL-MAA2018-48].[defn_nontaxable_T3_benefit_income];
GO

CREATE VIEW [DL-MAA2018-48].[defn_nontaxable_T3_benefit_income] AS
SELECT snz_uid
	,msd_tte_decision_date
	,msd_tte_pmt_amt
FROM [IDI_Clean_202203].[msd_clean].[msd_third_tier_expenditure]
WHERE [msd_tte_recoverable_ind] = 'N' -- non-recoverable payments
GO

/*********************************************************************
Working for Families (WfF) payment
*********************************************************************/

DROP VIEW IF EXISTS [DL-MAA2018-48].[tmp_wff];
GO

CREATE VIEW [DL-MAA2018-48].[tmp_wff] AS
SELECT [snz_uid]  
	,DATEADD(YEAR, -1, [wff_frd_return_period_date]) AS [tax_year_start_date]
	,[wff_frd_return_period_date] AS [tax_year_end_date]
	,SUM(ISNULL([wff_frd_fam_paid_amt], 0) - ISNULL([wff_frd_winz_paid_amt],0) - ISNULL([wff_frd_final_dr_cr_amt], 0)) AS [wff_pmt] 
FROM [IDI_Clean_202203].[wff_clean].[fam_return_dtls]
GROUP BY  [snz_uid], [wff_frd_return_period_date]
GO

-- add the negative wff payment back, and deduct it from previous wff payment
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[defn_nontaxable_wff_income];
GO

SELECT *
       ,wff_pmt + neg_adj + ISNULL(lead_neg_deduct,0) AS wff_pmt_neg_adj
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_nontaxable_wff_income]
FROM (
	SELECT *
		,IIF(wff_pmt < 0, -wff_pmt, 0) AS neg_adj
		,LEAD(IIF(wff_pmt < 0, wff_pmt, 0)) OVER(PARTITION BY snz_uid ORDER BY [tax_year_start_date]) AS lead_neg_deduct
	FROM [DL-MAA2018-48].[tmp_wff]
) k
GO

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2018-48].[defn_nontaxable_wff_income] (snz_uid);
GO
/* Compress to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_nontaxable_wff_income] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)

/********************************************************************************
Tidy up and remove all temporary tables/views that have been created
********************************************************************************/
DROP VIEW IF EXISTS [DL-MAA2018-48].[tmp_wff];
GO
