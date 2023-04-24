/***************************************************************************************************************************************
Title: Tax year income summary (including benefits)
Author: Freya Li
Reviewer: Simon Anastasiadis

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Disclaimer:
The definitions provided in this library were determined by the Social Wellbeing Agency to be suitable in the 
context of a specific project. Whether or not these definitions are suitable for other projects depends on the 
context of those projects. Researchers using definitions from this library will need to determine for themselves 
to what extent the definitions provided here are suitable for reuse in their projects. While the Agency provides 
this library as a resource to support IDI research, it provides no guarantee that these definitions are fit for reuse.

Citation:
Social Wellbeing Agency. Definitions library. Source code. https://github.com/nz-social-wellbeing-agency/definitions_library

Description:
Summary of total income (including non-taxible income) for each tax year.

Intended purpose:
1. Calculating annual income (including 2nd tier benefit , 3rd tier benefit and WWF) from different sources and in grand total.
2. Identifying whether a person received income from any source (taxible and non-taxible).


Inputs & Dependencies:
- [IDI_Clean].[data].[income_tax_yr_summary]
- [IDI_Clean].[msd_clean].[msd_second_tier_expenditure]
- [IDI_Clean].[msd_clean].[msd_third_tier_expenditure]
- [IDI_Clean].[wff_clean].[fam_return_dtls]

Output:
- [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_income_bnt_wff_tax_year]

Notes:
1. Not all income is taxible. 2nd tier benefits, 3rd tier benefits, and WfF tax credits
   are non-taxible and hence are not reported to IRD. This income is not part of annual
   total taxible income but is part of annual total income.

2. Full OUTER JOIN been considered because some people only have benefit or salaries or wwf as the only source of income
   There are around 3% of data in second tier benefit couldn't link to ir data every year.
   There are around 2% of data in third tier benefit couldn't link to ir data every year.
   There are around 10% of data in wff couldn't link to ir data every year. 
   Potential reason is that IR records only include the "active items that have non-zero partnership, self-employment,
   or shareholder salary income".
   Although WFF spells table do not have any linking issue, and it seems to be a alternative, 
   the records only available for (2003--2013), thus we won't consider this table.


3. Table							     reference period 
   [msd_second_tier_expenditure]         April    1990 � July 2020
   [msd_third_tier_expenditure]          November 2009 � July 2020
   [wff_clean].[fam_return_dtls]         March    2000 � March    2020
   [income_tax_yr_summary]				 April    1995 � March    2020

   (the above dates take from data dictionaries)
   We have added the condition(:where year>=2010) for all analysis in this script to speed up the performance and save memory.

4. [inc_tax_yr_sum_year_nbr]
   The year in which income was derived. The tax year of 2001 would run from 01 April 2000 � 31 March 2001. 
   The calendar year of 2001 would run from 01 Jan � 31 Dec 2001.

5. In the table [IDI_Clean_20201020].[msd_clean].[msd_third_tier_expenditure], we only consider [msd_tte_recoverable_ind] = 'N', 
   as [msd_tte_recoverable_ind] = 'Y' means the participants have to pay back the money.


Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = d2gP2_
  Project schema = [DL-MAA20XX-YY]
  earliest_year = 2010


Issues:

1. There are around 3.5% negative values in the column [wff_pmt] (which is the work for family payment).
   More than 95% of thes negative values are smaller than -50.

   22% of the population have ever got negative wff payment.
   6% of the population got overall negative wff payment if we sum up the wff payment from all the years
   
   To soleve the issue, we add the negative wff payment back, and deduct the abs(negative) from previous year.
   The adjustment decrease the percentage of negative payment to 2%.
   There are still 16% people who have ever got negative wff payment.
   This is because if two successive years continiously have negative payment, then there will be negative values 
   after adjustment. Or if the payment from the previous year is smaller than the abs(negative payment) from current year. 
   The third reason is that the overall payment is negative.
                                year1,year2,year3, year4,year5, year6
   eg. the wff payment of       $600, $200, $-400, $300, $-100, $-200
       after ajustment would be $600, $-200, $0   , $200,$-200, $0

   It seems unlikely that people would keep overpaying having already overpaid, or they get overall negative payment. 
   It may caused by data missing from the table.


2. runtime for [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_benefit_tier2]:  18 mins
 

History (reverse order):
2021-06-10 SA QA
2021-02-03 FL v3 
2021-01-26 SA QA
2020-12-10 FL v2 include tier 2, tier 3 and wff tax credit into the income
2020-07-16 MP QA
2020-03-02 SA v1
***************************************************************************************************************************************/


/* Establish database for writing views */
USE IDI_UserCode
GO


/* Wages and salaries by tax year */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[temp_income_tax_year];
GO

CREATE VIEW [DL-MAA20XX-YY].[temp_income_tax_year] AS
SELECT *
      ,DATEFROMPARTS([inc_tax_yr_sum_year_nbr],  3, 31) AS [event_date]
	  ,DATEFROMPARTS([inc_tax_yr_sum_year_nbr],  1,  1) AS [start_date]
	  ,DATEFROMPARTS([inc_tax_yr_sum_year_nbr], 12, 31) AS [end_date]
FROM [IDI_Clean_YYYYMM].[data].[income_tax_yr_summary]
WHERE [inc_tax_yr_sum_year_nbr]>=2010
GO

/*********************************************************************
second tier benefits by tax year
*********************************************************************/

-- Creating a temporary dates table
GO

CREATE TABLE #tax_year
(yr_tax INT,
tax_year_start DATE,
tax_year_end DATE
)

DECLARE @y_min INT = 2010
DECLARE @y_max INT = 2020

WHILE @y_min <= @y_max
BEGIN
		INSERT INTO #tax_year
		SELECT @y_min+1 AS yr_tax
				,DATEFROMPARTS(@y_min, 4, 1) as tax_year_start
				,DATEFROMPARTS(@y_min+1, 3, 31) as tax_year_end
	SET @y_min = @y_min + 1
END 


/*Break down second tier benefit into tax years*/

-- drop table before re-creating 
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_benefit_tier2];
GO
WITH dates_breakdown AS (
SELECT t2.*
	   ,t1.[snz_uid]
	   ,t1.[msd_ste_start_date]
       ,t1.[msd_ste_end_date]
       ,t1.[msd_ste_daily_gross_amt]
       ,t1.[msd_ste_period_nbr]
	   ,IIF([msd_ste_start_date] > [tax_year_start], [msd_ste_start_date], [tax_year_start]) AS [start_date_tax]
	   ,IIF(msd_ste_end_date < tax_year_end, msd_ste_end_date, tax_year_end) AS [end_date_tax]
FROM  [IDI_Clean_YYYYMM].[msd_clean].[msd_second_tier_expenditure] t1
INNER JOIN #tax_year  t2
ON msd_ste_start_date < tax_year_end AND tax_year_start < msd_ste_end_date
WHERE YEAR([msd_ste_start_date])>=2010 
),

payment_breakdown AS (
SELECT 
	 [snz_uid]
	,[yr_tax]
	,[start_date_tax]                                                                                 
	,[end_date_tax]
	,[msd_ste_start_date]
	,[msd_ste_end_date]
	,(DATEDIFF(DAY, [start_date_tax], [end_date_tax])+1) AS [period_num]
	,(DATEDIFF(DAY, [start_date_tax], [end_date_tax])+1) * [msd_ste_daily_gross_amt] AS [gross_payment] 
FROM dates_breakdown
)
SELECT [snz_uid]
      ,DATEFROMPARTS([yr_tax],  1,  1) AS [start_date]
	  ,DATEFROMPARTS([yr_tax], 12, 31) AS [end_date]
      ,SUM([gross_payment]) AS [bet_pmt_tier2]
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_benefit_tier2]
FROM payment_breakdown
GROUP BY [snz_uid], [yr_tax]

CREATE INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_benefit_tier2] ([snz_uid]);
GO

 /*********************************************************************
 third tier benefits by tax year
 *********************************************************************/
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[tmp_benefit_tier3];
GO

CREATE VIEW [DL-MAA20XX-YY].[tmp_benefit_tier3] AS
SELECT [snz_uid]
	  ,DATEFROMPARTS([yr_tax],  1,  1) AS [start_date]
	  ,DATEFROMPARTS([yr_tax], 12, 31) AS [end_date]
	  ,SUM([msd_tte_pmt_amt]) as [bet_pmt_tier3]
FROM(
	 SELECT [snz_uid]
           ,IIF(MONTH([msd_tte_decision_date])<4, YEAR([msd_tte_decision_date]),  YEAR([msd_tte_decision_date]) + 1) AS [yr_tax]
           ,[msd_tte_pmt_amt]
	  FROM [IDI_Clean_YYYYMM].[msd_clean].[msd_third_tier_expenditure]
	  WHERE [msd_tte_recoverable_ind] = 'N'
	  AND YEAR([msd_tte_decision_date]) >= 2010 
	  ) tier3
	  GROUP BY [snz_uid], [yr_tax]
GO



 /*********************************************************************
 Work for family payment
 *********************************************************************/
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[tmp_wff];
GO

CREATE VIEW [DL-MAA20XX-YY].[tmp_wff] AS
SELECT [snz_uid]  
      ,[tax_year]
      ,DATEFROMPARTS([tax_year],  1,  1) AS [start_date]
	  ,DATEFROMPARTS([tax_year], 12, 31) AS [end_date]
	  ,SUM([wff_pmt_prt])  AS [wff_pmt] 
FROM (
	SELECT [snz_uid] 
		  ,IIF(MONTH([wff_frd_return_period_date])<4, YEAR([wff_frd_return_period_date]), YEAR([wff_frd_return_period_date])+1) AS [tax_year]
		  ,(COALESCE([wff_frd_fam_paid_amt], 0) - COALESCE([wff_frd_winz_paid_amt],0) - COALESCE([wff_frd_final_dr_cr_amt], 0)) AS [wff_pmt_prt] 
    FROM [IDI_Clean_YYYYMM].[wff_clean].[fam_return_dtls]	
	WHERE YEAR([wff_frd_return_period_date])>=2010
	) a
GROUP BY  [snz_uid], [tax_year]
GO

-- add the negative wff payment back, and deduct it from previous wff payment

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_wff_neg_adj];
GO

 SELECT *
       ,wff_pmt + neg_adj + COALESCE(lead_neg_deduct,0) AS wff_pmt_neg_adj
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_wff_neg_adj]
FROM(
 SELECT *
        ,IIF(wff_pmt<0,-wff_pmt,0) AS neg_adj
		,LEAD(IIF(wff_pmt<0, wff_pmt,0)) OVER(PARTITION BY snz_uid ORDER BY start_date) AS lead_neg_deduct
 FROM [DL-MAA20XX-YY].[tmp_wff]
 ) a
GO

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_wff_neg_adj] (snz_uid);
GO

/***********************************************************/

--join bnt_wff table with ir income table

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_income_bnt_wff_tax_year];
GO


SELECT COALESCE(ir.[snz_uid], tier2.[snz_uid],tier3.[snz_uid], wff.[snz_uid]) AS [snz_uid]
      ,COALESCE(ir.[start_date],tier2.[start_date], tier3.[start_date], wff.[start_date]) AS [start_date]
	  ,COALESCE(ir.[end_date], tier2.[end_date],tier3.[end_date],wff.[end_date]) AS[end_date]
	  ,ir.[event_date]
	  ,ir.[inc_tax_yr_sum_WAS_tot_amt] /* wages & salaries */
      ,ir.[inc_tax_yr_sum_WHP_tot_amt] /* withholding payments (schedular payments with withholding taxes) */
      ,ir.[inc_tax_yr_sum_BEN_tot_amt] /* benefits */
      ,ir.[inc_tax_yr_sum_ACC_tot_amt] /* ACC claimants compensation */
      ,ir.[inc_tax_yr_sum_PEN_tot_amt] /* pensions (superannuation) */
      ,ir.[inc_tax_yr_sum_PPL_tot_amt] /* Paid parental leave */
      ,ir.[inc_tax_yr_sum_STU_tot_amt] /* Student allowance */
      ,ir.[inc_tax_yr_sum_C00_tot_amt] /* Company director/shareholder income from IR4S */
      ,ir.[inc_tax_yr_sum_C01_tot_amt] /* Comapny director/shareholder receiving PAYE deducted income */
      ,ir.[inc_tax_yr_sum_C02_tot_amt] /* Company director/shareholder receiving WHT deducted income */
      ,ir.[inc_tax_yr_sum_P00_tot_amt] /* Partnership income from IR20 */
      ,ir.[inc_tax_yr_sum_P01_tot_amt] /* Partner receiving PAYE deducted income */
      ,ir.[inc_tax_yr_sum_P02_tot_amt] /* Partner receiving withholding tax deducted income */
      ,ir.[inc_tax_yr_sum_S00_tot_amt] /* Sole trader income from IR3 */
      ,ir.[inc_tax_yr_sum_S01_tot_amt] /* Sole Trader receiving PAYE deducted income */
      ,ir.[inc_tax_yr_sum_S02_tot_amt] /* Sole trader receiving withholding tax deducted income */
      ,ir.[inc_tax_yr_sum_S03_tot_amt] /* Rental income from IR3 */
      ,ir.[inc_tax_yr_sum_all_srces_tot_amt] /*The total earnings for the individual for the tax or calendar year in year_nbr sourced from wages and salaries.*/
	  ,tier2.[bet_pmt_tier2]
	  ,tier3.[bet_pmt_tier3]
	  ,wff.[wff_pmt_neg_adj]
	  ,COALESCE(ir.[inc_tax_yr_sum_all_srces_tot_amt], 0)
	   + COALESCE(tier2.[bet_pmt_tier2], 0)
	   + COALESCE(tier3.[bet_pmt_tier3], 0)
	   + COALESCE(wff.[wff_pmt_neg_adj], 0) AS [inc_tax_yr_inc_bnt] /*income including the benefit of the tax year*/
	  ,COALESCE(ir.[inc_tax_yr_sum_BEN_tot_amt], 0) 
	   + COALESCE(tier2.[bet_pmt_tier2], 0)
	   + COALESCE(tier3.[bet_pmt_tier3], 0) AS [inc_tax_yr_all_bnt] /*all benefit from the tax year*/
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_income_bnt_wff_tax_year]
FROM [DL-MAA20XX-YY].[temp_income_tax_year] ir
FULL JOIN [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_benefit_tier2] tier2
ON ir.[snz_uid] = tier2.[snz_uid]
AND ir.[start_date] = tier2.[start_date]
AND ir.[end_date] = tier2.[end_date]
FULL JOIN [DL-MAA20XX-YY].[tmp_benefit_tier3] tier3
ON ir.[snz_uid] = tier3.[snz_uid]
AND ir.[start_date] = tier3.[start_date]
AND ir.[end_date] = tier3.[end_date] 
FULL JOIN [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_wff_neg_adj] wff
ON ir.[snz_uid] = wff.[snz_uid]
AND ir.[start_date] = wff.[start_date]
AND ir.[end_date] = wff.[end_date]
GO
--running the code takes about 15 mins with index
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_income_bnt_wff_tax_year] (snz_uid, start_date, end_date);
GO

/* Compress to save space  (takes 12 minutes) */
ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_income_bnt_wff_tax_year] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)




/********************************************************************************
Tidy up and remove all temporary tables/views that have been created
********************************************************************************/
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[temp_income_tax_year];
GO
GO
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[tmp_benefit_tier2];
GO
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[tmp_benefit_tier3];
GO
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[tmp_wff];
GO
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[tmp_wff_neg_adj];
GO

