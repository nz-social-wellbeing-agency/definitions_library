/**************************************************************************************************
Title: Classified Debt to MSD
Author: Simon Anastasiadis 
Contributors: Verity Warn

Inputs & Dependencies:
- [IDI_Adhoc].[clean_read_DEBT].[msd_debt_30sep]
- [IDI_Clean].[security].[concordance]
- [IDI_Clean].[msd_clean].[msd_third_tier_expenditure]

Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt]

Description:
Debt to MSD categorised by type.

Intended purpose:
Intermediate table for detailed MSD debt to be extracted from.
Identifying debtors, type of debt, and changes in debt.

Notes: 
1. Date range for table [msd_debt_30sep] is 2009-01-01 to 2020-09-01. Existing balances
	are created as new principle (amount incurred) on the opening date.

2. Numbers represent changes in debt owing. So principle is positive, repayments and
	write-offs are negative. A small number of repayments and write-offs are positive
	we assume these are reversals - and they increase debt in the same way as principle.

3. MSD debt data available at time of analysis does not classify MSD debt by type. We
	use the following method to classify MSD debt into recoverable assistance and
	overpayment:
	A) Fetch all T3 debt, filter to recoverable payments
	B) Split payments into 'within' month and 'at boundary of month'
		with 'boundary' defined as the last four days in the month.
	C) Group by identity and month and sum both dollar amounts.
	D) Join T3 payments to MSD debt
	E) Classify debt incurred into T3 (recoverable assistance) using the following order:
		- T3 payments 'within' a month
		- T3 payments on the border of the month
		- T3 payments on the border of the previous month that do not fit in previous month
	F) Any debt principle amounts not classified as due to T3 (recoverable) are classified
		as due to other, non-T3 causes (overpayment).

4. Consideration of 'within' vs. 'border' is necessary because recoverable assistance
	payments approved/made near the end of a month are sometimes recorded in the month
	and other times recorded in the next month.

5. Quality of this classification was assessed and found to be good. Consistent with other known
	sources of error in the IDI or better:
	- Of 8.9 million records, only 104,000 pass principle on the border to the next record.
		Of these we at most 7,700 could have error in timing (the wrong amount of border
		principle passed to the next month). But we estimate this is likely for only 1,600 records.
	- For 276,000 records (~3%) the amount of recoverable assistance from the T3 table is greater
		than the amount of debt recorded. Some of this will be due to differences in approvals
		and payment (e.g. $100 approved but only $99.97 needed).
	- Most debt classified as overpayment occurs within a benefit spell or at the end of a benefit spell
		as expected.

6. We do not attempt to distinguish between innocent overpayment debt and fraud. For two key reasons:
	A) No robust method for distinguishing the two in the available data.
	B) There are fewer than 600 fraud prosecutions each year but about 250,000 clients with an overpayment
		debt each year. So the percent of fraud cases is too small for approximate methods to work well
		(number from documents released by MSD under OIA).
	The best proxy we tested was to treat all principle amounts over $50,000 as fraud.

7. Performance can be slow: 14 minutes


Parameters & Present values:
  Current refresh = 20201020
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]
  Earliest year of data = 2009
  Number of days considered border of month = 4

History (reverse order):
2021-01-18 SA v1
2021-01-12 SA work begun
2020-12-01 VW initial exploration of MSD records
**************************************************************************************************/

/**********************************************************************
add snz_uid to msd_debt table in the sandpit
**********************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[tmp_msd_debt_principle]','U') IS NOT NULL DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[tmp_msd_debt_principle];
GO

SELECT b.snz_uid
	  ,a.[snz_msd_uid]
      ,a.[debt_as_at_date]
	  ,SUM(ISNULL(a.[amount_incurred], 0)) AS [amount_incurred] --some identities have more than one record per month, hence collapse
	  ,SUM(ISNULL(a.[amount_repaid], 0)) AS [amount_repaid]
	  ,SUM(ISNULL(a.[amount_written_off], 0)) AS [amount_written_off]
INTO [IDI_Sandpit].[DL-MAA2020-01].[tmp_msd_debt_principle]
FROM [IDI_Adhoc].[clean_read_DEBT].[msd_debt_30sep] AS a
INNER JOIN [IDI_Clean_20201020].[security].[concordance] AS b -- adding snz_uid 
ON a.snz_msd_uid = b.snz_msd_uid
GROUP BY b.snz_uid, a.snz_msd_uid, a.debt_as_at_date

/* Index by snz_uid (improve efficiency) */
CREATE CLUSTERED INDEX snz_uid_index ON [IDI_Sandpit].[DL-MAA2020-01].[tmp_msd_debt_principle] (snz_uid); 

/**********************************************************************
convert T3 to monthly
**********************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[tmp_recoverable_t3]','U') IS NOT NULL DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[tmp_recoverable_t3];
GO

WITH prep_t3 AS (
	/* filter and add some additional columns to MSD T3 expenditure */
	SELECT [snz_uid]
		  ,[snz_msd_uid]
		  ,[msd_tte_decision_date]
		  ,DATEFROMPARTS(YEAR([msd_tte_decision_date]), MONTH([msd_tte_decision_date]), 1) AS decision_month
		  ,DATEDIFF(DAY, [msd_tte_decision_date], EOMONTH([msd_tte_decision_date])) AS days_til_end_of_month
		  ,[msd_tte_pmt_amt]
	FROM [IDI_Clean_20201020].[msd_clean].[msd_third_tier_expenditure]
	WHERE [msd_tte_recoverable_ind] = 'Y'
	AND YEAR([msd_tte_decision_date]) >= 2009 -- debt data starts in 2009
)
SELECT [snz_uid]
      ,[snz_msd_uid]
	  ,[decision_month]
	  ,SUM(IIF(days_til_end_of_month <= 4, [msd_tte_pmt_amt], 0)) AS border_month_amount
	  ,SUM(IIF(days_til_end_of_month <= 4, 0, [msd_tte_pmt_amt])) AS within_month_amount
      ,SUM([msd_tte_pmt_amt]) AS total_t3_payment_amount
	  ,COUNT(*) AS num_payments -- used for auditing
INTO [IDI_Sandpit].[DL-MAA2020-01].[tmp_recoverable_t3]
FROM prep_t3
GROUP BY [snz_uid], [snz_msd_uid], [decision_month]

/* Index by snz_uid (improve efficiency) */
CREATE CLUSTERED INDEX snz_uid_index ON [IDI_Sandpit].[DL-MAA2020-01].[tmp_recoverable_t3] (snz_uid); 

/**********************************************************************
attach T3 to MSD debt 
**********************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[tmp_augmented_msd_debt]','U') IS NOT NULL DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[tmp_augmented_msd_debt];
GO

WITH
step_1_join AS (

SELECT pr.snz_uid
	,pr.snz_msd_uid
	,debt_as_at_date
	,amount_incurred
	,ISNULL(within_month_amount, 0) AS within_month_amount
	,ISNULL(border_month_amount, 0) AS border_month_amount
FROM [IDI_Sandpit].[DL-MAA2020-01].[tmp_msd_debt_principle] AS pr
LEFT JOIN [IDI_Sandpit].[DL-MAA2020-01].[tmp_recoverable_t3] AS t3
ON pr.snz_uid = t3.snz_uid
AND pr.[debt_as_at_date] = t3.decision_month
WHERE [amount_incurred] IS NOT NULL -- only interested in where debt has occured
AND [amount_incurred] > 0

),
step_2_assign_within AS (

SELECT snz_uid
	,snz_msd_uid
	,amount_incurred
	,debt_as_at_date
	,within_month_amount
	,border_month_amount
	,IIF(amount_incurred <= within_month_amount + border_month_amount, amount_incurred, within_month_amount + border_month_amount) AS recoverable_source
	,IIF(amount_incurred <= within_month_amount + border_month_amount, 0, amount_incurred - within_month_amount - border_month_amount) AS other_source
	,IIF(border_month_amount >= IIF(amount_incurred - within_month_amount > 0, amount_incurred - within_month_amount, 0),
		border_month_amount - IIF(amount_incurred - within_month_amount > 0, amount_incurred - within_month_amount, 0),
		0) AS border_remaining
FROM step_1_join

),
step_3_pass_across AS (

SELECT *
	,LAG(border_remaining, 1, 0) OVER (PARTITION BY snz_uid ORDER BY debt_as_at_date) AS passed_over_border
	,LAG(debt_as_at_date, 1, '1000-01-01') OVER (PARTITION BY snz_uid ORDER BY debt_as_at_date) AS passed_from_date
FROM step_2_assign_within

),
step_4_assign_across AS (

SELECT *
	,IIF(DATEDIFF(MONTH, passed_from_date, debt_as_at_date) = 1, -- was valid amount passed from previous
		recoverable_source + IIF(passed_over_border > other_source, other_source, passed_over_border), -- yes: increase recoverable source by passed amount
		recoverable_source -- no: then existing amount remains correct
	) AS recoverable_source_2
	,IIF(DATEDIFF(MONTH, passed_from_date, debt_as_at_date) = 1, -- was valid amount passed from previous
		IIF(passed_over_border > other_source, 0, other_source - passed_over_border), -- yes: reduce other source by passed amount
		other_source -- no: then existing amount remains correct
	) AS other_source_2
FROM step_3_pass_across

)
SELECT snz_uid
	,snz_msd_uid
	,amount_incurred
	,debt_as_at_date
	,recoverable_source_2 AS amount_incurred_t3_sources
	,other_source_2 AS amount_incurred_non_t3_sources
INTO [IDI_Sandpit].[DL-MAA2020-01].[tmp_augmented_msd_debt]
FROM step_4_assign_across

/* Index by snz_uid (improve efficiency) */
CREATE CLUSTERED INDEX snz_uid_index ON [IDI_Sandpit].[DL-MAA2020-01].[tmp_augmented_msd_debt] (snz_uid); 

/**********************************************************************
attach categorised debt to full MSD debt data
**********************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt]','U') IS NOT NULL DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt];
GO

SELECT a.snz_uid
	  ,a.[snz_msd_uid]
      ,a.[debt_as_at_date]
	  ,a.[amount_incurred]
      ,[amount_repaid]
	  ,[amount_written_off]
	  ,amount_incurred_t3_sources AS amount_incurred_assistance
	  ,amount_incurred_non_t3_sources AS amount_incurred_overpayment
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt]
FROM [IDI_Sandpit].[DL-MAA2020-01].[tmp_msd_debt_principle] AS a
LEFT JOIN [IDI_Sandpit].[DL-MAA2020-01].[tmp_augmented_msd_debt] AS b
ON a.snz_uid = b.snz_uid
AND a.debt_as_at_date = b.debt_as_at_date
/* the following conditions must be true by construction, checked & commented out for speed */
--AND a.snz_msd_uid = b.snz_msd_uid
--AND a.amount_incurred = b.amount_incurred

/* Index by snz_uid (improve efficiency) */
CREATE CLUSTERED INDEX snz_uid_index ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt] (snz_uid); 
/* Compact table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)

/**********************************************************************
remove temporary tables
**********************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[tmp_msd_debt_principle]','U') IS NOT NULL DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[tmp_msd_debt_principle];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[tmp_recoverable_t3]','U') IS NOT NULL DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[tmp_recoverable_t3];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[tmp_augmented_msd_debt]','U') IS NOT NULL DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[tmp_augmented_msd_debt];
GO
