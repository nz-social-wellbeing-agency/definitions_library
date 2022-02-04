/**************************************************************************************************
Title: Debt to MSD Phase 2

Authors: Simon Anastasiadis, Freya Li

Acknowledgement: The original code was writen by Simon Anastasiadis, which is saved in Debt to Government Phase 1 folder.
  Necessary changes have been made (eg. changing table name, date).

Inputs & Dependencies:
- [IDI_Clean].[security].[concordance]
- [IDI_Adhoc].[clean_read_DEBT].[msd_debt_30sep]
- "classifying MSD debt using T3 data.sql" --> [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt]

Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_debt_cases]
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_debt_by_quarter]
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_debt_by_month]
- [IDI_UserCode].[DL-MAA2020-01].[d2gP2_msd_classified_debt_monthly]

Description:
Debt, debt balances, and repayment for debtors owing money to MSD.

Intended purpose:
Identifying debtors.
Calculating number of debts and total value of debts.
Calculating change in debts - due to borrowing or repayment.

Notes: 
1. Table needs to be linked to IDI_Clean via [snz_msd_uid], as it is a IDI_Adhoc table. 
   Tables exhibits excellence linking to the spine. Less than 0.2% recods couldn't link to concordance 
   table for both [d2gP2_msd_debt_cases] and [d2gP2_msd_debt_by_quarter].

2. Date range for table [msd_debt_30sep] is 2009-01-01 to 2020-09-30. Existing balances are created as new principle 
   (amount incurred) on the opening date.

3. Total outstanding debt appears to be consistent with MSD & IRD debt comparison that
   looked at debt balances on 30 September 2016.

4. Numbers represent changes in debt owing. So principle is positive, repayments and
   write-offs are negative. A small number of repayments and write-offs are positive
   we assume these are reversals - and they increase debt in the same way as principle.

5. Outlier values
   Some principle amounts > $10k, which is unlikely to be recoverable assistance or overpayment.
   Large transactions (>$10k) make up a tiny proportion of transactions (less than 0.1%) and 
   effect a small number of people (less than 3%) but are a significant amount of total amounts incurred (22%).
   Current hypothesis is that such amounts are fraud (which is part of the dataset) or 
   receipt of more than one form of recoverable assistance (e.g. one for clothes, another for heating).
   Conversation with MSD data experts suggests these amounts are most likely related to fraud.

6. Values approx 0 that should be zero is of minimal concern.
   As values are dollars, all numbers should be rounded to 2 decimal places.
   Less than 0.5% of people ever have an absolute debt balance of 1-5 cents.

7.  Recoverable assistance - Looking at third tier expenditure that is recoverable:
   - Amounts less than $2k are common
   - Amounts of $3-5k are uncommon
   - Amounts exceeding $5k occur but are rare
   So if we are concerned about spikes, $5k is a reasonable threshold for identifying spikes
   because people could plausably borrow and repay $2000 in recoverable assistance in a single month.

8. Spikes - Yes there are occurrences where people's balances change in a spike pattern
   (suddent, large change, immediately reversed) and the value of the change exceeds $5k.
   There are less than 6,000 instances of this in the dataset, about 0.01% of records
   The total amount of money involved is less than 0.2% of total debt.
   Hence this pattern is not of concern.

9. We would expect that a debtor's balance is always non-negative. So if we summ amounts incurred,
   repayments, and write offs, then debt balances should be >=0.
   However, some identities have dates on which their net amount owing is negative.
   About 6000 people have negative amounts owing at some point.(negative been considered as the cut-off)
   Inspection of the data suggests that this happens when repayments exceed debt, and
   rather than withdraw the excess, the amount is of debt is left negative until the individual
   borrows again (either overpayment or recoverable assistance).
   It is common to observe negative balances that later on become zero balances.
   We would not observe this if the negative balances implied that some debt incurred was not
   recorded in the dataset.

   (The above conclutions can be drawn from the script "testing msd debt data.sql")

10. Runtime for table [d2gP2_tmp_msd_debt_cases] is around 33 minutes, even with indexing.

Parameters & Present values:
  Current refresh = 20201020
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]

History (reverse order):
2020-06-18 FL comment out active debt duration, as it's out of scope; repayment indicator; debt persistence
2020-05-07 FL including monthly debt increase and decrease
2020-01-26 SA QA
2020-01-13 FL Create monthly time series
2020-12-21 FL v2 (update to the latest refresh, make necessary changes to the code)
2020-11-24 FL QA
2020-06-22 SA v1
2020-03-19 SA work begun
**************************************************************************************************/



/*
Prior to use, copy to sandpit and index
*/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[msd_debt_30sep]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[msd_debt_30sep];
GO

SELECT *
      ,IIF(YEAR(debt_as_at_date) < 2019, COALESCE(amount_incurred, 0) + COALESCE(amount_repaid, 0) + COALESCE(amount_written_off, 0), 0)  AS  pre_2019_delta
INTO [IDI_Sandpit].[DL-MAA2020-01].[msd_debt_30sep]
FROM [IDI_Adhoc].[clean_read_DEBT].[msd_debt_30sep]

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[msd_debt_30sep] ([snz_msd_uid], [debt_as_at_date]);
GO





/****************************************************************************************
2019 & 2020 monthly debt. Monthly new debt and repayment are recoded in [msd_debt_30sep]
(Jan 2019 -- Sep 2020)
****************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_by_month];
GO

SELECT [snz_msd_uid]
	  ,ROUND(SUM(for_2019Jan_value), 2) AS value_2019Jan
	  ,ROUND(SUM(for_2019Feb_value), 2) AS value_2019Feb
	  ,ROUND(SUM(for_2019Mar_value), 2) AS value_2019Mar
	  ,ROUND(SUM(for_2019Apr_value), 2) AS value_2019Apr
	  ,ROUND(SUM(for_2019May_value), 2) AS value_2019May
	  ,ROUND(SUM(for_2019Jun_value), 2) AS value_2019Jun
	  ,ROUND(SUM(for_2019Jul_value), 2) AS value_2019Jul
	  ,ROUND(SUM(for_2019Aug_value), 2) AS value_2019Aug
	  ,ROUND(SUM(for_2019Sep_value), 2) AS value_2019Sep
	  ,ROUND(SUM(for_2019Oct_value), 2) AS value_2019Oct
	  ,ROUND(SUM(for_2019Nov_value), 2) AS value_2019Nov
	  ,ROUND(SUM(for_2019Dec_value), 2) AS value_2019Dec
	  ,ROUND(SUM(for_2020Jan_value), 2) AS value_2020Jan
	  ,ROUND(SUM(for_2020Feb_value), 2) AS value_2020Feb
	  ,ROUND(SUM(for_2020Mar_value), 2) AS value_2020Mar
	  ,ROUND(SUM(for_2020Apr_value), 2) AS value_2020Apr
	  ,ROUND(SUM(for_2020May_value), 2) AS value_2020May
	  ,ROUND(SUM(for_2020Jun_value), 2) AS value_2020Jun
	  ,ROUND(SUM(for_2020Jul_value), 2) AS value_2020Jul
	  ,ROUND(SUM(for_2020Aug_value), 2) AS value_2020Aug
	  ,ROUND(SUM(for_2020Sep_value), 2) AS value_2020Sep

	  ,ROUND(SUM(pre_2019_delta), 2) AS balance_pre_2019
	  ,ROUND(SUM(for_2019_principle), 2) AS principle_2019
	  ,ROUND(SUM(for_2019_payment), 2) AS payment_2019
	  ,ROUND(SUM(for_2019_write_off), 2) AS write_off_2019
	  ,ROUND(SUM(for_2020_principle), 2) AS principle_2020
	  ,ROUND(SUM(for_2020_payment), 2) AS payment_2020
	  ,ROUND(SUM(for_2020_write_off), 2) AS write_off_2020

	  /*repayment indicator*/
	  ,IIF(SUM(for_payment_3mth) >= 1, 1, 0) AS ind_payment_3mth
	  ,IIF(SUM(for_payment_6mth) >= 1, 1, 0) AS ind_payment_6mth
	  ,IIF(SUM(for_payment_9mth) >= 1, 1, 0) AS ind_payment_9mth
	  ,IIF(SUM(for_payment_12mth) >= 1, 1, 0) AS ind_payment_12mth


INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_by_month]
FROM (
	SELECT [snz_msd_uid]
		  ,[debt_as_at_date]
		  ,[amount_incurred]
		  ,[amount_repaid]
		  ,[amount_written_off]
		  ,[pre_2019_delta]
		  /* 2019 months setup */
		  ,IIF([debt_as_at_date] <= '2019-01-31', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2019Jan_value
		  ,IIF([debt_as_at_date] <= '2019-02-28', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2019Feb_value
		  ,IIF([debt_as_at_date] <= '2019-03-31', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2019Mar_value
		  ,IIF([debt_as_at_date] <= '2019-04-30', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2019Apr_value
		  ,IIF([debt_as_at_date] <= '2019-05-31', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2019May_value
		  ,IIF([debt_as_at_date] <= '2019-06-30', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2019Jun_value
		  ,IIF([debt_as_at_date] <= '2019-07-31', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2019Jul_value
		  ,IIF([debt_as_at_date] <= '2019-08-31', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2019Aug_value
		  ,IIF([debt_as_at_date] <= '2019-09-30', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2019Sep_value
		  ,IIF([debt_as_at_date] <= '2019-10-31', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2019Oct_value
		  ,IIF([debt_as_at_date] <= '2019-11-30', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2019Nov_value
		  ,IIF([debt_as_at_date] <= '2019-12-31', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2019Dec_value
			/* 2020 months setup */
		  ,IIF([debt_as_at_date] <= '2020-01-31', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2020Jan_value
		  ,IIF([debt_as_at_date] <= '2020-02-29', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2020Feb_value
		  ,IIF([debt_as_at_date] <= '2020-03-31', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2020Mar_value
		  ,IIF([debt_as_at_date] <= '2020-04-30', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2020Apr_value
		  ,IIF([debt_as_at_date] <= '2020-05-31', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2020May_value
		  ,IIF([debt_as_at_date] <= '2020-06-30', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2020Jun_value
		  ,IIF([debt_as_at_date] <= '2020-07-31', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2020Jul_value
		  ,IIF([debt_as_at_date] <= '2020-08-31', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2020Aug_value
	      ,IIF([debt_as_at_date] <= '2020-09-30', COALESCE([amount_incurred], 0) + COALESCE([amount_repaid], 0) + COALESCE([amount_written_off], 0), 0) AS for_2020Sep_value	

		  /* debt components for 2019 and 2020*/
		  ,IIF(YEAR([debt_as_at_date]) = 2019, COALESCE([amount_incurred], 0), 0) AS for_2019_principle
		  ,IIF(YEAR([debt_as_at_date]) = 2019, - COALESCE([amount_repaid], 0), 0) AS for_2019_payment
		  ,IIF(YEAR([debt_as_at_date]) = 2019, - COALESCE(amount_written_off, 0), 0) AS for_2019_write_off
		  ,IIF(YEAR([debt_as_at_date]) = 2020, COALESCE([amount_incurred], 0), 0) AS for_2020_principle
		  ,IIF(YEAR([debt_as_at_date]) = 2020, - COALESCE([amount_repaid], 0), 0) AS for_2020_payment
		  ,IIF(YEAR([debt_as_at_date]) = 2020, - COALESCE(amount_written_off, 0), 0) AS for_2020_write_off

		  /*repayment plan*/
	   ,IIF('2020-07-01' <= [debt_as_at_date] AND [debt_as_at_date] <= '2020-09-30' AND [amount_repaid] < -1, 1, 0) AS for_payment_3mth
	   ,IIF('2020-04-01' <= [debt_as_at_date] AND [debt_as_at_date] <= '2020-09-30' AND [amount_repaid] < -1, 1, 0) AS for_payment_6mth
	   ,IIF('2020-01-01' <= [debt_as_at_date] AND [debt_as_at_date] <= '2020-09-30' AND [amount_repaid] < -1, 1, 0) AS for_payment_9mth
	   ,IIF('2019-10-01' <= [debt_as_at_date] AND [debt_as_at_date] <= '2020-09-30' AND [amount_repaid] < -1, 1, 0) AS for_payment_12mth
	FROM [IDI_Sandpit].[DL-MAA2020-01].[msd_debt_30sep]
) k
GROUP BY snz_msd_uid
HAVING NOT (ABS(SUM(for_2019Jan_value)) < 1
AND ABS(SUM(for_2019Feb_value)) < 1
AND ABS(SUM(for_2019Mar_value)) < 1
AND ABS(SUM(for_2019Apr_value)) < 1
AND ABS(SUM(for_2019May_value)) < 1
AND ABS(SUM(for_2019Jun_value)) < 1
AND ABS(SUM(for_2019Jul_value)) < 1
AND ABS(SUM(for_2019Aug_value)) < 1
AND ABS(SUM(for_2019Sep_value)) < 1
AND ABS(SUM(for_2019Oct_value)) < 1
AND ABS(SUM(for_2019Nov_value)) < 1
AND ABS(SUM(for_2019Dec_value)) < 1
AND ABS(SUM(for_2020Jan_value)) < 1
AND ABS(SUM(for_2020Feb_value)) < 1
AND ABS(SUM(for_2020Mar_value)) < 1
AND ABS(SUM(for_2020Apr_value)) < 1
AND ABS(SUM(for_2020May_value)) < 1
AND ABS(SUM(for_2020Jun_value)) < 1
AND ABS(SUM(for_2020Jul_value)) < 1
AND ABS(SUM(for_2020Aug_value)) < 1
AND ABS(SUM(for_2020Sep_value)) < 1
)

/*debt persistence*/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_msd_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_msd_debt_by_month];
GO

SELECT *
       ,IIF(value_2020Sep > 1 AND value_2020Aug > 1 AND value_2020Jul > 1, 1, 0) persistence_3mth
	   ,IIF(value_2020Sep > 1 AND value_2020Aug > 1 AND value_2020Jul > 1
		          AND value_2020Jun > 1 AND value_2020May > 1 AND value_2020Apr > 1, 1, 0) persistence_6mth
       ,IIF(value_2020Sep > 1 AND value_2020Aug > 1 AND value_2020Jul >1
		          AND value_2020Jun > 1 AND value_2020May > 1 AND value_2020Apr > 1
				  AND value_2020Mar > 1 AND value_2020Feb > 1 AND value_2020Jan > 1, 1, 0) persistence_9mth
		  ,IIF(value_2020Sep > 1 AND value_2020Aug > 1 AND value_2020Jul > 1
		          AND value_2020Jun > 1 AND value_2020May > 1 AND value_2020Apr > 1
				  AND value_2020Mar > 1 AND value_2020Feb > 1 AND value_2020Jan > 1
				  AND value_2019Dec > 1 AND value_2019Nov > 1 AND value_2019Oct > 1, 1, 0) persistence_12mth
		  ,IIF(value_2020Sep > 1 AND value_2020Aug > 1 AND value_2020Jul > 1
		          AND value_2020Jun > 1 AND value_2020May > 1 AND value_2020Apr > 1 
				  AND value_2020Mar > 1 AND value_2020Feb > 1 AND value_2020Jan > 1 
				  AND value_2019Dec > 1 AND value_2019Nov > 1 AND value_2019Oct > 1
				  AND value_2019Sep > 1 AND value_2019Aug > 1 AND value_2019Jul > 1, 1, 0) persistence_15mth
		  ,IIF(value_2020Sep > 1 AND value_2020Aug > 1 AND value_2020Jul > 1
		          AND value_2020Jun > 1 AND value_2020May > 1 AND value_2020Apr > 1
				  AND value_2020Mar > 1 AND value_2020Feb > 1 AND value_2020Jan > 1
				  AND value_2019Dec > 1 AND value_2019Nov > 1 AND value_2019Oct > 1
				  AND value_2019Sep > 1 AND value_2019Aug > 1 AND value_2019Jul > 1
				  AND value_2019Jun > 1 AND value_2019May > 1 AND value_2019Apr > 1, 1, 0) persistence_18mth
		  ,IIF(value_2020Sep > 1 AND value_2020Aug > 1 AND value_2020Jul > 1
		          AND value_2020Jun > 1 AND value_2020May > 1 AND value_2020Apr > 1
				  AND value_2020Mar > 1 AND value_2020Feb > 1 AND value_2020Jan > 1
				  AND value_2019Dec > 1 AND value_2019Nov > 1 AND value_2019Oct > 1
				  AND value_2019Sep > 1 AND value_2019Aug > 1 AND value_2019Jul > 1
				  AND value_2019Jun > 1 AND value_2019May > 1 AND value_2019Apr > 1
				  AND value_2019Mar > 1 AND value_2019Feb > 1 AND value_2019Jan > 1, 1, 0) persistence_21mth
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_msd_debt_by_month]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_by_month]

CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_msd_debt_by_month] (snz_msd_uid);
GO



/*********** join on snz_uid ***********/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_debt_by_month];
GO

SELECT b.snz_uid
	  ,a.*
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_debt_by_month]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_msd_debt_by_month] a
LEFT JOIN [IDI_Clean_20201020].[security].[concordance] b
ON a.snz_msd_uid = b.snz_msd_uid

/* Add index */

CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_debt_by_month] (snz_uid);
GO


/*********** remove temporary table ***********/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[msd_debt_30sep]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[msd_debt_30sep];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_cases]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_cases];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_by_month];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_msd_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_msd_debt_by_month];
GO

