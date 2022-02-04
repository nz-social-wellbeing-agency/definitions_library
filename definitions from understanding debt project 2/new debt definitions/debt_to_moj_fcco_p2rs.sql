/**************************************************************************************************
Title: Debt to MOJ FCCO Phase 2 -restructure
Author: Freya Li & Simon Anastasiadis

Inputs & Dependencies:
-  [IDI_Adhoc].[clean_read_DEBT].[moj_debt_fcco_monthly_balances]
- [IDI_Adhoc].[clean_read_DEBT].[moj_debt_identity_fml_and_adhoc]
- [IDI_Adhoc].[clean_read_DEBT].[moj_debt_data_link] 
- [IDI_Clean].[security].[concordance]
Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_fcco_transactions_ready]

Description:
Debt, debt balances, and repayment for debtors owing money to MOJ Family Court Cost Contribution Order (FCCO).

Intended purpose:
Identifying debtors.
Calculating number of debts and total value of debts.
Calculating change in debts - due to borrowing or repayment.

Notes:
1. Date range for table [d2gP2_moj_debt_fcco_monthly_balances] is Jul2014 to Jan2021
	Family Court Contribution Orders were introduced in the 2014 family justice reforms.
	Hence there is no FCCO debt prior to 2014.

2. The first record closing_balance for each identity is equal to the sum of all the conponent:
   closing_balance[1] = new_debt_established[1] + repayments[1] + write_offs[1], the rest of the
   closing_balance (except first record) is the running balnce (which means that:
   closing_balance[i+1] = closing_balance[i] + new_debt_established[i+1] + repayments[i+1] + write_offs[i+1] 
   where i = 2, 3,...).

3. 12% of the fcco_file_nbr couldn't be link to the corresponding snz_uid in table [d2gP2_moj_fcco_debt_cases]
   14% of the fcco_file_nbr couldn't be link to the corresponding snz_uid in table [d2gP2_moj_fcco_debt_by_month]

4. A single person may have multiple fcco_fiel_nbrs for multiple debts or debt roles.
   After link the monthly debt to spine, only keep one record for each snz_uid (which means combine those rows with
   same snz_uid but different fcco_file_nbr)
   For debt case data, we would keep it as it is, as different fcco_file_nbr refer to deffierent debt or debt roles.

5. FML for the MoJ debt data is specific to the 20201020 refresh. 

6. Fast match loader:
   Run_key is a number that is specific to the linking of a specific dataset.
   Lhs_nbr is the let hand side identifier, also known as the snz_spine _uid.
   Rhs_nbr is the right_hand side identifier, also known as node. This is the uid that was created in the primary 
   series table related to the primary series key. 

Parameters & Present values:
  Current refresh = 20201020
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]

History (reverse order):
2021-09-12 FL restructure 
2021-06-18 FL comment out active debt deration period as it's out of scope; repayment indicator; persistence indicator
2021-05-07 FL including monthly incured debt and repayment 
2021-03-08 FL work begun
***************************************************************************************************/

/**************************************************************************************************
Prior to use, copy to sandpit and index
**************************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances];
GO

With debt_source AS(
SELECT *
      ,EOMONTH(DATEFROMPARTS(calendar_year, RIGHT(month_nbr,2), 1)) AS month_date
	  ,COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0)  AS  delta
FROM [IDI_Adhoc].[clean_read_DEBT].[moj_debt_fcco_monthly_balances]
)
SELECT *
      ,SUM(delta) OVER (PARTITION BY fcco_file_nbr ORDER BY month_date) AS balance_correct
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances]
FROM debt_source
WHERE month_date <= '2020-12-31'
GO
/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances] ([fcco_file_nbr]);
GO

/**************************************************************************************************
fill in records where balance is non-zero but transactions are zero
**************************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_fcco_non_transactions]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_fcco_non_transactions];
GO

WITH 
/* list of 100 numbers of 1:100 - spt_values is a n admin table chosen as it is at least 100 row long */
n AS (
	SELECT TOP 100 ROW_NUMBER() OVER (ORDER BY type) AS x
	FROM master.dbo.spt_values
),
/* list of dates, constructed by adding list of numbers to initial date */
my_dates AS (
	SELECT TOP (DATEDIFF(MONTH, '2014-07-01', '2020-12-31') + 1) /* number of dates required */
		EOMONTH(DATEADD(MONTH, x-1, '2014-07-01')) AS my_dates
	FROM n
	ORDER BY x
),
/* get the date for each record */
debt_source AS(
	SELECT *
		,LEAD(month_date, 1, '9999-01-01') OVER (PARTITION BY fcco_file_nbr ORDER BY month_date) AS lead_date_cor
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances]
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
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_fcco_non_transactions]
FROM (
	/* original records */
	SELECT fcco_file_nbr
	      ,month_date
		  ,new_debt_established
		  ,repayments
		  ,write_offs
		  ,balance_correct
		  ,delta
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances]

	UNION ALL

	/* additional records */
	SELECT fcco_file_nbr
	      ,my_dates AS month_date
		  ,NULL AS new_debt_established
		  ,NULL AS repaymets
		  ,NULL AS write_offs
		  ,balance_correct
		  ,0 AS delta
	FROM joined
	WHERE NOT balance_correct BETWEEN -1 AND 0 -- exclude small negative balances
) k

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_fcco_non_transactions] ([fcco_file_nbr]);
GO

/*************************************************************************
Join MoJ FCCO data to spine
*************************************************************************/
--Linking MoJ debt data with fast match loader
--FML for the MoJ debt data is specific to the 20201020 refresh. 
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_id]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_id];
GO

SELECT fml.[fcco_file_nbr] -- uid on debt input table
	  ,fml.[snz_fml_8_uid] -- links to dl.rhs_nbr
	  ,dl.[rhs_nbr] -- links to fml.snz_fml_8_uid
	  ,dl.[lhs_nbr] -- links to sc.snz_spine_uid
      ,sc.snz_spine_uid -- links to dl.lhr_nbr
	  ,sc.snz_uid -- desired output uid
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_id]
FROM [IDI_Adhoc].[clean_read_DEBT].[moj_debt_fcco_identities] AS fml
LEFT JOIN [IDI_Adhoc].[clean_read_DEBT].[moj_debt_data_link] AS dl
ON fml.snz_fml_8_uid = dl.rhs_nbr 
AND (dl.near_exact_ind = 1
     OR dl.weight_nbr > 17) -- exclude only low weight, non-exact links
LEFT JOIN [IDI_Clean_20201020].[security].[concordance] AS sc
ON dl.lhs_nbr = sc.snz_spine_uid
WHERE dl.run_key = 943  -- there are two run_keys as FML used twice for MoJ data
-- runkey = 941 for fines & charges, runkey = 943 for FCCO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[[d2gP2_fcco_transactions_ready]]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_fcco_transactions_ready];
GO

SELECT b.snz_uid
       ,a.*
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_fcco_transactions_ready]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_fcco_non_transactions] a
LEFT JOIN [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_id] b
ON a.fcco_file_nbr = b.fcco_file_nbr

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_fcco_transactions_ready] (snz_uid);
GO

/*****************************************************************************
Remove temporary tables
*****************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_fcco_non_transactions]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_fcco_non_transactions];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_id]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_id];
GO
