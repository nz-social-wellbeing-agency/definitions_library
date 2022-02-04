/**************************************************************************************************
Title: Debt to MOJ Phase 2
Author: Freya Li and Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Adhoc].[clean_read_DEBT].[moj_debt_full_summary_trimmed]
- [IDI_Adhoc].[clean_read_DEBT].[moj_debt_identity_fml_and_adhoc]
- [IDI_Adhoc].[clean_read_DEBT].[moj_debt_data_link] 
- [IDI_Clean].[security].[concordance]
Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_transactions_ready]

Description: 
Debt, debt balances, and repayment for debtors owing money to MOJ.

Intended purpose:
Identifying debtors.
Calculating number of debtors and total value of debts.
Calculating change in debts - due to borrowing or repayment.

Notes:
1. Date range for table [moj_debt_full_summary_trimmed] is Dec2010 - Dec2020.
   The balance in 2011 has no change for every month, we discard all data pre-2012.

2. Foe orginal data, numbers represent the amount of the money, they are all positive.
   Delta = penalty + impositions - payment - remittals + payment_reversal +remittal_reversal
   delta is calculated correctly.
   To keep consistency, in the final transaction views payment and remittals are switched as
   negative values.

3. If the first outstanding_balance for an identity may not equal to the delta, which means that 
   the outstanding_balance include the debt before 2012  
 
4. When we produce the table [d2gP2_tmp_moj_debt_cases], only debt incurred after 2012 will be 
   considered, because if a debt incurred before 2012, we don't know when exactly the debt 
   incurred. Thus, only 85% of the identities from [moj_debt_full_summary_trimmed] inculded in
   [d2gP2_tmp_moj_debt_cases].

5. A single person may have multiple PPNs for multiple debts or debt roles.
   We combined the debt for the same snz_uid with different moj_ppn (for monthly debt table),
   For debt case data, we keep it as it is, as different fcco_file_nbr refer to deffierent debt
   or debt roles.

6. The debt arise before 2012 most likely been paid off by end of 2018, it won't infulence too much on the
   analysis for 2019 and 2020 data; the total imposition debt is about 7 times more than penalty debt,
   thus we treat all the debt arise before 2012 as imposition on the date of the first record an individual has.
   An attempt of splitting debt repayment to repaid to debt arise before 2012, and to debt arise after 2012 in
   the file MoJ debt date investigation.sql. However, running the code takes extra time, and won't improve our 
   analysis significantly, that version has been abandoned.

7. The case of total repaid is more than total incurred has been observed.

8. This table contains debts from fines and infringements which have been imposed. These are not charges,
	which are more courts and tribunals related. (Email Stephanie Simpson, MoJ data SME, 2021-04-08)

9. FML for the MoJ debt data is specific to the 20201020 refresh. To use the data on a different refresh, 
   researchers have to first join it to the 20201020 refresh and then use snz_jus_uid to link to other refreshes.

10. Fast match loader:
    Run_key is a number that is specific to the linking of a specific dataset.
    Lhs_nbr is the let hand side identifier, also known as the snz_spine _uid.
    Rhs_nbr is the right_hand side identifier, also known as node. This is the uid that was created in the primary 
	series table related to the primary series key. 
    

Issue:
1. Data that has been linked with the Fast Match Loader (FML) requires some additional steps
   to connect to the spine.
   20% of the moj_ppn couldn't be link to the corresponding snz_uid in table [d2gP2_moj_debt_cases]
   30% of the moj_ppn couldn't be link to the corresponding snz_uid in table [d2gP2_moj_debt_by_month]

2. There are cases that individuals have outstanding balance from pre-2012, but the first transaction record 
   is not Janaury 2012. In this case, instead of record their outstanding balance before 2012 at January 2012, 
   we record it at the first date those individuals have a transaction record.

Parameters & Present values:
  Current refresh = 20201020
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]

History (reverse order):
2021-10-04 SA review
2021-08-13 FL insert records when there are no transactions
2021-06-17 FL comment out the active debt duration as it's out of scope; add repayment indicator; debt persisitence
2021-05-07 FL including monthly incurred debt and repayment
2021-03-03 FL work begun
**************************************************************************************************/

/**************************************************************************************************
Prior to use, copy to sandpit and index
(runtime 2 minutes)
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed];
GO

SELECT *
      ,EOMONTH(DATEFROMPARTS(year_nbr, month_of_year_nbr, 1)) AS month_date
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed]
FROM [IDI_Adhoc].[clean_read_DEBT].[moj_debt_full_summary_trimmed]
WHERE year_nbr > 2011
GO

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed] ([moj_ppn]);
GO

/**************************************************************************************************
Data preparation
Not all the outstanding_balance provided by MoJ are correct. Recalculation is required
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_prep]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_prep];
GO

SELECT *
	  ,SUM(balance_before_2012 + delta) OVER (PARTITION BY moj_ppn ORDER BY month_date) AS balance_correct
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_prep]
FROM(
	SELECT *
		  ,IIF(first_record_ind = 1, COALESCE(outstanding_balance, 0) - delta, 0) AS balance_before_2012
	FROM(
		SELECT *
			   ,IIF(month_date = MIN(month_date) OVER (PARTITION BY moj_ppn), 1, 0) AS first_record_ind
		FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed]
	)a
)b

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_prep] ([moj_ppn]);
GO

/**************************************************************************************************
fill in records where balance is non-zero but transactions are zero
**************************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_non_transactions]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_non_transactions];
GO

WITH 
/* list of 120 numbers of 1:120 - spt_values is a n admin table chosen as it is at least 120 row long */
n AS (
	SELECT TOP 120 ROW_NUMBER() OVER (ORDER BY type) AS x
	FROM master.dbo.spt_values
),
/* list of dates, constructed by adding list of numbers to initial date */
my_dates AS (
	SELECT TOP (DATEDIFF(MONTH, '2012-01-01', '2020-12-31') + 1) /* number of dates required */
		EOMONTH(DATEADD(MONTH, x-1, '2012-01-01')) AS my_dates
	FROM n
	ORDER BY x
),
/* get the next date for each record */
debt_source AS(
SELECT *
	  ,LEAD(month_date, 1, '9999-01-01') OVER (PARTITION BY moj_ppn ORDER BY month_date) AS lead_date_cor
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_prep]
),
joined AS (
	SELECT *
	FROM debt_source
	INNER JOIN my_dates
	ON month_date < my_dates 
	AND my_dates < lead_date_cor
)
/* combine oringinal and additional records into same table */
SELECT * 
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_non_transactions]
FROM (
	/* original records */
	SELECT moj_ppn 
	      ,month_date
		  ,impositions
		  ,penalty
		  ,payment
		  ,remittals
		  ,payment_reversal
		  ,remittal_reversal
		  ,balance_correct
		  ,delta
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_prep]

	UNION ALL

	/* additional records */
	SELECT moj_ppn 
	      ,my_dates AS month_date
		  ,NULL AS impositions
		  ,NULL AS penalty
		  ,NULL AS payment
		  ,NULL AS remittals
		  ,NULL AS payment_reversal
		  ,NULL AS remittal_reversal
		  ,balance_correct 
		  ,0 AS delta
	FROM joined
	WHERE NOT balance_correct BETWEEN - 1 AND 0 --exclude small netative balances
) k

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_non_transactions] ([moj_ppn]);
GO

/*************************************************************************
Join MoJ data to spine
*************************************************************************/
--Linking MoJ debt data with fast match loader
--FML for the MoJ debt data is specific to the 20201020 refresh. 
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_id]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_id];
GO

SELECT fml.[snz_jus_uid]
      ,fml.[moj_ppn] -- uid on debt input table
	  ,fml.[snz_fml_7_uid] -- links to dl.rhs_nbr
	  ,dl.[rhs_nbr] -- links to fml.snz_fml_8_uid
	  ,dl.[lhs_nbr] -- links to sc.snz_spine_uid
      ,sc.snz_spine_uid -- links to dl.lhr_nbr
	  ,sc.snz_uid -- desired output uid
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_id]
FROM [IDI_Adhoc].[clean_read_DEBT].[moj_debt_identity_fml_and_adhoc] AS fml
LEFT JOIN [IDI_Adhoc].[clean_read_DEBT].[moj_debt_data_link] AS dl
ON fml.snz_fml_7_uid = dl.rhs_nbr 
AND (dl.near_exact_ind = 1
     OR dl.weight_nbr > 17) -- exclude only low weight, non-exact links
LEFT JOIN [IDI_Clean_20201020].[security].[concordance] AS sc
ON dl.lhs_nbr = sc.snz_spine_uid
WHERE dl.run_key = 941  -- there are two run_keys as FML used twice for MoJ data
-- runkey = 941 for fines & charges, runkey = 943 for FCCO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[[d2gP2_moj_transactions_ready]]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_transactions_ready];
GO

SELECT b.snz_uid
       ,a.*
INTO  [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_transactions_ready]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_non_transactions] a
LEFT JOIN [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_id] b
ON a.moj_ppn = b.moj_ppn

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_transactions_ready] (snz_uid);
GO

/*****************************************************************************
Remove temporary tables
*****************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_prep]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_prep];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_non_transactions]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_non_transactions];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_id]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_id];
GO
