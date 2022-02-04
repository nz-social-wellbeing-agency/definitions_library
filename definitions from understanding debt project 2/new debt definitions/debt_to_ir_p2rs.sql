/**************************************************************************************************
Title: Debt to IRD Phase 2
Author: Freya Li
Reviewer: Simon Anastasiadis

Acknowledgement: Part of the code is took from Simon's code for D2G phase 1.

Inputs & Dependencies:
- [IDI_Clean].[security].[concordance]
- [IDI_Adhoc].[clean_read_DEBT].[ir_debt_transactions]
- [IDI_Adhoc].[clean_read_DEBT].[ir_debt_collection_cases]
- [IDI_Adhoc].[clean_read_DEBT].[ir_debt_transactions_student_202105]
Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_transactions_ready]
- [IDI_UserCode].[DL-MAA2020-01].[ird_labels_balance]
- [IDI_UserCode].[DL-MAA2020-01].[ird_labels_transactions]
- [IDI_UserCode].[DL-MAA2020-01].[ird_labels_repayments]
- [IDI_UserCode].[DL-MAA2020-01].[ird_labels_persist]

Description:
Debt, debt balances, and repayment for debtors owing money to IRD.

Intended purpose:
Identifying debtors.
Calculating number of debts and total value of debts.
Calculating change in debts - due to borrowing or repayment.

Notes:
1. As tables are adhoc they need to be linked to IDI_Clean via agency specific uid's.
   Both IRD tables exhibit excellent correspondence to one-another and both link
   very well to the spine.
2. delta is the sum of assess, penalty, interest, account_maintenance, payment, remiss, the first record of each tax type should including
   the opening balance 
3. Some of the different debt types have different starting points.
   This is because of changes in IR's computer system between 2018 and 2020.
   It is not due to data missing from the table.
   Jordan's (IRD) response about this: There have been several releases as Inland Revenue are migrating completely over to our new tax system, 
   START. One of these key release dates was in April-2020 and specifically that was when the Income Tax type product was converted over.
   The collection case begin dates are correct if they were opened from before Jan-2019 but any specific historical transaction data is 
   essentially rolled up into a single converted transaction line item dated 20th April 2019. This is why it appears to have data missing 
   and only start from then.
      tax_type_group		start date  end date
	Donation Tax Credits	2019-04-30	2020-11-30
	Employment Activities	2019-01-31	2020-11-30
	Families				2019-04-30	2020-11-30
	GST						2019-01-31	2020-11-30
	Income Tax				2019-04-30	2020-11-30
	Liable Parent			2019-01-31	2020-11-30
	Other					2019-01-31	2020-11-30
	Receiving Carer			2019-01-31	2020-11-30
	Student Loans			2020-04-30	2020-11-30

4. Date range for dataset is 2019-01-31 to 2020-11-30. About 11% of debt cases arise before 2019. 
   If tax case started earlier than 2019 and unclosed until 2019-01-31, then there is a difference
   between [running_balance_tax_type] and [delta] at beginning of 2019.
5. Numbers represent changes in debt owing. So principle is positive, repayments are
   negative, interest is positive when charges and negative if reversed/waived.
   Around 2% assesses are negative. delta is the sum of the components
6. Each identity can have multiple cases, of different tax types, and case numbers are
   reused between tax types and individuals. 
7. Outliers:
   Very large positive and negative balances and delta values are observed in the data.
   Defining 'large values' as magnitudes in excess of $1 million, then a tiny fraction
   of people <0.1% have very large balances at any given time
8. 2% of the records has negative balance, only 0.4% of debt cases have negative debt balances
   of at least $100.
9. 46% of the records from [IDI_Adhoc].[clean_read_DEBT].[ir_debt_collection_cases] has NULL date_end
   Around 86% the records with NULL date_end has date_begin after 2018 (year 2018 excluded)
10. We consider a debt case is closed if the balance for a snz_uid within a snz_case_number and tax_type_group turns to 0. 
11. Opening date for a debt case in [ir_debt_collection_cases] is not consistent with the table [ir_debt_transactions],
   Recalculation of the open and close date for each debt case based on table [ir_debt_transactions] required. However, 
   the calculation is only an approximation, for two reasons:
   (1) Date range for dataset is 2019-01-31 to 2020-11-30. The open date for any case arise before 2019 will be extracted 
       from table [ir_debt_collection_cases]. However, [ir_debt_collection_cases] consider a case number as a debt case,
	   we consider each tax_type under a case number for a snz_uid as a debt case.
   (2) All the records in [ir_debt_transactions] are recored as the last date of the month rather than the exact date of 
       the transaction.
12. We observe student loan debt provided by IR in the table [ir_debt_transactions] to contain errors.
    - Double the amount of debt as reported outside the IDI
    - Double the amount of debt as observable in sla_clean.ird_overdue_debt
    - About half of all people with overdue student loan debt have multiple debt cases
	  (This is much higher than for all the other debt types).
    However, the number of people with debt is approximately consistent.

	Cause - due to a processing error IR has included both overdue AND non-overdue balance for some debtors.
	Initial solution - Join with SLA data and remove the debt cases most obviously wrong. Reduced error by two thirds.
	Fix - IR provided fresh overdue student loan information in table [ir_debt_transactions_student_202105].
		We replace student loan debt in the original table with the debt in this table.
		Original code moved to data exploration/unused definitions folder.
	Outstanding concerns - fix address majority of problem but still some differences from numbers reported outside the IDI.
13. There are around 3000 cases where the same identity has two (or more) records for the same month, tax type, and case number.
	This primariy affects Liable Parent debt. Our approach keeps all records, which is equivalent to assuming that the case
	numbers should be different.

Issues:
1. It seems that [running_balance_case] from table [ir_debt_transactions] is not correctly calculated, it doesn't sum up the
   running balance across the different tax type group with in a debt case. 

Parameters & Present values:
  Current refresh = 20201020
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]
  Earliest debt date = '2019-01-01'
  Latest debt date = '2020-12-31'

History (reverse order):
2021-07-13 SA insert records when there are no transactions
2021-06-18 FL comment out active cases part as it is out of scope; add repayment indicator, debt persistence indicator
2021-06-11 SA update notes on student loan debt and faster loading/setup
2021-05-26 FL IR reload the student loan debt, replace the student loan records with the new table
2021-04-13 FL removing wrong student loan debt
2021-02-02 FL v3
2021-01-26 SA QA
2021-01-13 FL v2 Create monthly time series
2021-01-06 FL (update to the latest refresh, make necessary changes to the code)
2020-11-25 FL QA
2020-07-02 SA update following input from SME
2020-06-23 SA v1
**************************************************************************************************/

/**************************************************************************************************
set location for views once at start
**************************************************************************************************/
USE [IDI_UserCode]
GO

/**************************************************************************************************
Prior to use, copy to sandpit and index
(runtime 2 minutes)
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[tmp_ir_debt_transactions]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[tmp_ir_debt_transactions];
GO

SELECT *
INTO [IDI_Sandpit].[DL-MAA2020-01].[tmp_ir_debt_transactions]
FROM (

	/* All debt in base table excluding faulty student loan records */
	SELECT *
	FROM [IDI_Adhoc].[clean_read_DEBT].[ir_debt_transactions]
	WHERE tax_type_group <> 'Student Loans'

	UNION ALL

	/* Corrected student loan debt records */
	SELECT *
	FROM [IDI_Adhoc].[clean_read_DEBT].[ir_debt_transactions_student_202105]
) k

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[tmp_ir_debt_transactions] ([snz_ird_uid], [snz_case_number], [tax_type_group]);
GO

/**************************************************************************************************
Standardise columns
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected];
GO

WITH standardised AS (
	SELECT *
		,REPLACE(tax_type_group, ' ', '_') AS tax_type_label
		,CAST(REPLACE(REPLACE([running_balance_tax_type],'$',''), ',' , '') AS NUMERIC(10,2)) AS [running_balance_tax_type_num] -- convert $text to numeric
		,CAST(REPLACE(REPLACE([running_balance_case],'$',''), ',' , '') AS NUMERIC(10,2)) AS [running_balance_case_num] -- convert $text to numeric
		,MIN([month_end]) OVER(PARTITION BY [snz_ird_uid], [snz_case_number], [tax_type_group] ORDER BY [month_end]) AS [min_date]
	FROM [IDI_Sandpit].[DL-MAA2020-01].[tmp_ir_debt_transactions]
)
SELECT *
       ,IIF([month_end] = [min_date], [running_balance_tax_type_num], [delta]) as [delta_updated]
	   ,IIF([account_maintenance] > 0, [account_maintenance], 0) AS [maintenance_pos]
	   ,IIF([account_maintenance] < 0, [account_maintenance], 0) AS [maintenance_neg]
	   ,IIF([month_end] = [min_date] AND [month_end] <= '2020-09-30' AND [running_balance_tax_type_num] <> [delta], [running_balance_tax_type_num] - [delta], 0) as [pre_2019]
 --around 300 identities' first records in the debt table is after 2020-09-30, however, they have balance before 2019,without consider these records will keep the debt balance consistent with the sum of component
 --If tax case started earlier than 2019 and unclosed until 2019-01-31, then set [running_balance_tax_type_num]  + [delta] as delta_updated at the first date of the record
INTO [IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected]
FROM standardised

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected] ([snz_ird_uid],[tax_type_group]);
GO
/**************************************************************************************************
fill in records where balance is non-zero but transactions are zero
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_non_transactions]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_non_transactions];
GO

WITH
/* list of 100 numbers 1:100 - spt_values is an admin table chosen as it is at least 100 rows long */
n AS (
	SELECT TOP 100 ROW_NUMBER() OVER (ORDER BY type) AS x
	FROM master.dbo.spt_values
),
/* list of dates, constructed by adding list of numbers to initial date */
my_dates AS (
	SELECT TOP (DATEDIFF(MONTH, '2019-01-01', '2020-12-31') + 1) /* number of dates required */
		EOMONTH(DATEADD(MONTH, x-1, '2019-01-01')) AS my_dates
	FROM n
	ORDER BY x
),
/* get the next date for each record */
debt_source AS (
	SELECT *
		,LEAD(month_end, 1, '9999-01-01') OVER (PARTITION BY snz_ird_uid, tax_type_label, snz_case_number ORDER BY month_end) AS lead_month_end
	FROM [IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected]
),
/* join where dates from list are between current and next date --> hence dates from list are missing */
joined AS (
	SELECT *
	FROM debt_source
	INNER JOIN my_dates
	ON month_end < my_dates
	AND my_dates < lead_month_end
)
/* combine original and additional records into same table */
SELECT *
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_non_transactions]
FROM (
	/* original records */
	SELECT snz_ird_uid
		,snz_case_number
		,month_end
		,tax_type_label
		,pre_2019
		,assess
		,penalty
		,interest
		,maintenance_pos
		,maintenance_neg
		,payment
		,remiss
		,delta_updated
		,running_balance_tax_type_num
	FROM [IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected]

	UNION ALL

	/* additional records */
	SELECT snz_ird_uid
		,snz_case_number
		,my_dates AS month_end
		,tax_type_label
		,NULL AS pre_2019
		,NULL AS assess
		,NULL AS penalty
		,NULL AS interest
		,NULL AS maintenance_pos
		,NULL AS maintenance_neg
		,NULL AS payment
		,NULL AS remiss
		,0 AS delta_updated
		,running_balance_tax_type_num
	FROM joined
	WHERE NOT running_balance_tax_type_num BETWEEN -10 AND 0 -- exclude small negative balances
) k

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_non_transactions] ([snz_ird_uid]);
GO

/**************************************************************************************************
join on snz_uid
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_transactions_ready]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_transactions_ready];
GO

SELECT b.snz_uid
	,a.*
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_transactions_ready]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_non_transactions] AS a
LEFT JOIN [IDI_Clean_20201020].[security].[concordance] AS b
ON a.snz_ird_uid = b.snz_ird_uid

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_transactions_ready] (snz_uid);
GO

/**************************************************************************************************
Views for balance labels
**************************************************************************************************/

IF OBJECT_ID('[DL-MAA2020-01].[ird_labels_balance]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[ird_labels_balance];
GO

CREATE VIEW [DL-MAA2020-01].[ird_labels_balance] AS
SELECT snz_uid
	,month_end
	,tax_type_label
	,running_balance_tax_type_num
	/* balance labels */
	,CONCAT('ird_Y', YEAR(month_end), 'M', MONTH(month_end), '_', tax_type_label) AS balance_label
	,CONCAT('ird_Y', YEAR(month_end), 'M', MONTH(month_end)) AS balance_label_all_types
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_transactions_ready]
WHERE month_end BETWEEN '2019-01-01' AND '2020-09-30'
GO

/**************************************************************************************************
Views for transaction labels
**************************************************************************************************/

IF OBJECT_ID('[DL-MAA2020-01].[ird_labels_transactions]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[ird_labels_transactions];
GO

CREATE VIEW [DL-MAA2020-01].[ird_labels_transactions] AS
SELECT snz_uid
	,month_end
	,tax_type_label
	,pre_2019
	,assess
	,penalty
	,interest
	,maintenance_pos
	,maintenance_neg
	,payment
	,remiss
	/* pre_2019 */
	,CONCAT('ird_', 'pre_2019', '_', tax_type_label) AS transaction_labels_pre_2019_by_type
	,CONCAT('ird_', 'pre_2019') AS transaction_labels_pre_2019_all_types
	/* assess */
	,CONCAT('ird_', 'assess', '_', YEAR(month_end), '_', tax_type_label) AS transaction_labels_assess_by_type
	,CONCAT('ird_', 'assess', '_', YEAR(month_end)) AS transaction_labels_assess_all_types
	/* penalty */
	,CONCAT('ird_', 'penalty', '_', YEAR(month_end), '_', tax_type_label) AS transaction_labels_penalty_by_type
	,CONCAT('ird_', 'penalty', '_', YEAR(month_end)) AS transaction_labels_penalty_all_types
	/* interest */
	,CONCAT('ird_', 'interest', '_', YEAR(month_end), '_', tax_type_label) AS transaction_labels_interest_by_type
	,CONCAT('ird_', 'interest', '_', YEAR(month_end)) AS transaction_labels_interest_all_types
	/* maintenance_pos */
	,CONCAT('ird_', 'maintenance_pos', '_', YEAR(month_end), '_', tax_type_label) AS transaction_labels_maintenance_pos_by_type
	,CONCAT('ird_', 'maintenance_pos', '_', YEAR(month_end)) AS transaction_labels_maintenance_pos_all_types
	/* maintenance_neg */
	,CONCAT('ird_', 'maintenance_neg', '_', YEAR(month_end), '_', tax_type_label) AS transaction_labels_maintenance_neg_by_type
	,CONCAT('ird_', 'maintenance_neg', '_', YEAR(month_end)) AS transaction_labels_maintenance_neg_all_types
	/* payment */
	,CONCAT('ird_', 'payment', '_', YEAR(month_end), '_', tax_type_label) AS transaction_labels_payment_by_type
	,CONCAT('ird_', 'payment', '_', YEAR(month_end)) AS transaction_labels_payment_all_types
	/* remiss */
	,CONCAT('ird_', 'remiss', '_', YEAR(month_end), '_', tax_type_label) AS transaction_labels_remiss_by_type
	,CONCAT('ird_', 'remiss', '_', YEAR(month_end)) AS transaction_labels_remiss_all_types
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_transactions_ready]
WHERE month_end BETWEEN '2019-01-01' AND '2020-09-30'
GO

/**************************************************************************************************
Views for repayments
**************************************************************************************************/

IF OBJECT_ID('[DL-MAA2020-01].[ird_labels_repayments]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[ird_labels_repayments];
GO

CREATE VIEW [DL-MAA2020-01].[ird_labels_repayments] AS

SELECT snz_uid
	,snz_case_number
	,month_end
	,tax_type_label
	,payment
	/* repayment labels by type */
	,IIF(month_end BETWEEN '2020-07-01' AND '2020-09-30', CONCAT('ird_payment_03mth_', tax_type_label), NULL) AS payment_label_by_type_03
	,IIF(month_end BETWEEN '2020-04-01' AND '2020-09-30', CONCAT('ird_payment_06mth_', tax_type_label), NULL) AS payment_label_by_type_06
	,IIF(month_end BETWEEN '2020-01-01' AND '2020-09-30', CONCAT('ird_payment_09mth_', tax_type_label), NULL) AS payment_label_by_type_09
	,IIF(month_end BETWEEN '2019-10-01' AND '2020-09-30', CONCAT('ird_payment_12mth_', tax_type_label), NULL) AS payment_label_by_type_12
	/* repayment labels all types */
	,IIF(month_end BETWEEN '2020-07-01' AND '2020-09-30', 'ird_payment_03mth', NULL) AS payment_label_all_types_03
	,IIF(month_end BETWEEN '2020-04-01' AND '2020-09-30', 'ird_payment_06mth', NULL) AS payment_label_all_types_06
	,IIF(month_end BETWEEN '2020-01-01' AND '2020-09-30', 'ird_payment_09mth', NULL) AS payment_label_all_types_09
	,IIF(month_end BETWEEN '2019-10-01' AND '2020-09-30', 'ird_payment_12mth', NULL) AS payment_label_all_types_12
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_transactions_ready]
WHERE payment < -1
AND month_end BETWEEN '2019-10-01' AND '2020-09-30'
GO

/**************************************************************************************************
Views for persistence

To determine whether a person has persistent debt we count the number of distinct dates where
the label is non-null during assembly. After assembly, we create the indicator by checking
whether ird_persistence_XXmth = XX.
- If ird_persistence_XXmth = XX then in the last XX months there were XX months where the person
  had debt hence they had debt in every month.
- If ird_persistence_XXmth < XX then in the last XX months there were some months where the person
  did not have debt.
**************************************************************************************************/

IF OBJECT_ID('[DL-MAA2020-01].[ird_labels_persist]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[ird_labels_persist];
GO

CREATE VIEW [DL-MAA2020-01].[ird_labels_persist] AS
SELECT snz_uid
	,snz_case_number
	,month_end
	,tax_type_label
	,running_balance_tax_type_num
	/* persistence labels by type */
	,IIF(month_end BETWEEN '2020-07-01' AND '2020-09-30', CONCAT('ird_persistence_03mth_', tax_type_label), NULL) AS persistence_label_by_type_03
	,IIF(month_end BETWEEN '2020-04-01' AND '2020-09-30', CONCAT('ird_persistence_06mth_', tax_type_label), NULL) AS persistence_label_by_type_06
	,IIF(month_end BETWEEN '2020-01-01' AND '2020-09-30', CONCAT('ird_persistence_09mth_', tax_type_label), NULL) AS persistence_label_by_type_09
	,IIF(month_end BETWEEN '2019-10-01' AND '2020-09-30', CONCAT('ird_persistence_12mth_', tax_type_label), NULL) AS persistence_label_by_type_12
	,IIF(month_end BETWEEN '2019-07-01' AND '2020-09-30', CONCAT('ird_persistence_15mth_', tax_type_label), NULL) AS persistence_label_by_type_15
	,IIF(month_end BETWEEN '2019-04-01' AND '2020-09-30', CONCAT('ird_persistence_18mth_', tax_type_label), NULL) AS persistence_label_by_type_18
	,IIF(month_end BETWEEN '2019-01-01' AND '2020-09-30', CONCAT('ird_persistence_21mth_', tax_type_label), NULL) AS persistence_label_by_type_21
	/* persistence labels all types */
	,IIF(month_end BETWEEN '2020-07-01' AND '2020-09-30', 'ird_persistence_03mth', NULL) AS persistence_label_all_types_03
	,IIF(month_end BETWEEN '2020-04-01' AND '2020-09-30', 'ird_persistence_06mth', NULL) AS persistence_label_all_types_06
	,IIF(month_end BETWEEN '2020-01-01' AND '2020-09-30', 'ird_persistence_09mth', NULL) AS persistence_label_all_types_09
	,IIF(month_end BETWEEN '2019-10-01' AND '2020-09-30', 'ird_persistence_12mth', NULL) AS persistence_label_all_types_12
	,IIF(month_end BETWEEN '2019-07-01' AND '2020-09-30', 'ird_persistence_15mth', NULL) AS persistence_label_all_types_15
	,IIF(month_end BETWEEN '2019-04-01' AND '2020-09-30', 'ird_persistence_18mth', NULL) AS persistence_label_all_types_18
	,IIF(month_end BETWEEN '2019-01-01' AND '2020-09-30', 'ird_persistence_21mth', NULL) AS persistence_label_all_types_21
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_transactions_ready]
WHERE running_balance_tax_type_num IS NOT NULL
AND running_balance_tax_type_num > 0
AND month_end BETWEEN '2019-01-01' AND '2020-09-30'
GO


/**************************************************************************************************
Generate group labels for rows you want the sum of during assembly

This approach not taken as storing a lot of text is very memory heavy
And there is lots of duplication in this text, so better to create it dynamically
at run time via views.
**************************************************************************************************/

/*

SELECT TOP 100 snz_ird_uid
	,snz_case_number
	,month_end
	,tax_type_label
	,assess
	,penalty
	,interest
	,maintenance_pos
	,maintenance_neg
	,payment
	,remiss
	--,delta
	,delta_updated
	,running_balance_tax_type_num
	--,running_balance_case_num
	,min_date
	,pre_2019
	/* balance labels */
	,IIF(month_end BETWEEN '2019-01-01' AND '2020-09-30', CONCAT('ird_Y', YEAR(month_end), 'M', MONTH(month_end), '_', tax_type_label), NULL) AS balance_label
	,IIF(month_end BETWEEN '2019-01-01' AND '2020-09-30', CONCAT('ird_Y', YEAR(month_end), 'M', MONTH(month_end)), NULL) AS balance_label_all_types
	/* transaction labels */
	,IIF(month_end BETWEEN '2019-01-01' AND '2020-09-30', CONCAT('ird_', '<TSC>', '_', YEAR(month_end), '_', tax_type_label), NULL) AS transaction_labels_by_type
	,IIF(month_end BETWEEN '2019-01-01' AND '2020-09-30', CONCAT('ird_', '<TSC>', '_', YEAR(month_end)), NULL) AS transaction_labels_all_types
	/* persistence labels by type */
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2020-07-01' AND '2020-09-30', CONCAT('ird_persistence_03mth_', tax_type_label), NULL) AS persistence_label_by_type_03
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2020-04-01' AND '2020-09-30', CONCAT('ird_persistence_06mth_', tax_type_label), NULL) AS persistence_label_by_type_06
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2020-01-01' AND '2020-09-30', CONCAT('ird_persistence_09mth_', tax_type_label), NULL) AS persistence_label_by_type_09
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2019-10-01' AND '2020-09-30', CONCAT('ird_persistence_12mth_', tax_type_label), NULL) AS persistence_label_by_type_12
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2019-07-01' AND '2020-09-30', CONCAT('ird_persistence_15mth_', tax_type_label), NULL) AS persistence_label_by_type_15
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2019-04-01' AND '2020-09-30', CONCAT('ird_persistence_18mth_', tax_type_label), NULL) AS persistence_label_by_type_18
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2019-01-01' AND '2020-09-30', CONCAT('ird_persistence_21mth_', tax_type_label), NULL) AS persistence_label_by_type_21
	/* persistence labels all types */
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2020-07-01' AND '2020-09-30', 'ird_persistence_03mth', NULL) AS persistence_label_all_types_03
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2020-04-01' AND '2020-09-30', 'ird_persistence_06mth', NULL) AS persistence_label_all_types_06
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2020-01-01' AND '2020-09-30', 'ird_persistence_09mth', NULL) AS persistence_label_all_types_09
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2019-10-01' AND '2020-09-30', 'ird_persistence_12mth', NULL) AS persistence_label_all_types_12
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2019-07-01' AND '2020-09-30', 'ird_persistence_15mth', NULL) AS persistence_label_all_types_15
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2019-04-01' AND '2020-09-30', 'ird_persistence_18mth', NULL) AS persistence_label_all_types_18
	,IIF(running_balance_tax_type_num > 1 AND month_end BETWEEN '2019-01-01' AND '2020-09-30', 'ird_persistence_21mth', NULL) AS persistence_label_all_types_21
	/* repayment labels by type */
	,IIF(payment > 1 AND month_end BETWEEN '2020-07-01' AND '2020-09-30', CONCAT('ird_payment_03mth_', tax_type_label), NULL) AS payment_label_by_type_03
	,IIF(payment > 1 AND month_end BETWEEN '2020-04-01' AND '2020-09-30', CONCAT('ird_payment_06mth_', tax_type_label), NULL) AS payment_label_by_type_06
	,IIF(payment > 1 AND month_end BETWEEN '2020-01-01' AND '2020-09-30', CONCAT('ird_payment_09mth_', tax_type_label), NULL) AS payment_label_by_type_09
	,IIF(payment > 1 AND month_end BETWEEN '2019-10-01' AND '2020-09-30', CONCAT('ird_payment_12mth_', tax_type_label), NULL) AS payment_label_by_type_12
	/* repayment labels all types */
	,IIF(payment > 1 AND month_end BETWEEN '2020-07-01' AND '2020-09-30', 'ird_payment_03mth', NULL) AS payment_label_by_type_03
	,IIF(payment > 1 AND month_end BETWEEN '2020-04-01' AND '2020-09-30', 'ird_payment_06mth', NULL) AS payment_label_by_type_06
	,IIF(payment > 1 AND month_end BETWEEN '2020-01-01' AND '2020-09-30', 'ird_payment_09mth', NULL) AS payment_label_by_type_09
	,IIF(payment > 1 AND month_end BETWEEN '2019-10-01' AND '2020-09-30', 'ird_payment_12mth', NULL) AS payment_label_by_type_12
FROM [IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected]

*/


/**************************************************************************************************
remove temporary tables
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[tmp_ir_debt_transactions]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[tmp_ir_debt_transactions];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_non_transactions]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_non_transactions];
GO