/**************************************************************************************************
Title: Debt to MSD Phase 2

Authors: Simon Anastasiadis, Freya Li

Inputs & Dependencies:
- [IDI_Clean].[security].[concordance]
- [IDI_Adhoc].[clean_read_DEBT].[msd_debt_30sep]
- "classifying MSD debt using T3 data.sql" --> [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt]

Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt_and_repayment]
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_classified_debt_by_month]

Description:
Debt, debt balances, and repayment for debtors owing money to MSD.
Considering debt by Overpayment and Recoverable Assistance.

Intended purpose:
Identifying debtors.
Calculating number of debts and total value of debts.
Calculating change in debts - due to borrowing or repayment.

Notes: 
1. Source table needs to be linked to IDI_Clean via [snz_msd_uid], as it is a IDI_Adhoc table. 
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

9. We would expect that a debtor's balance is always non-negative. So if we sum amounts incurred, repayments, and write offs,
	then debt balances should be >=0. However, some identities have dates on which their net amount owing is negative. About
	6000 people have negative amounts owing at some point (negative been considered as the cut-off). Inspection of the data
	suggests that this happens when repayments exceed debt, and rather than withdraw the excess, the amount is of debt is left
	negative until the individual borrows again (either overpayment or recoverable assistance). It is common to observe
	negative balances that later on become zero balances. We would not observe this if the negative balances implied that some
	debt incurred was not recorded in the dataset.

10. This file builds on previous work that splits debt incurred into overpayment and recoverable assistance. This file extends
	this work by splitting repayments into overpayment and recoverable assistance. This is done in accordance with guidance
	from MSD that:
	(1) The earliest debt is paid off first
	(2) benefit advances are paid off in parallel with other repayments ("separately at a rate of $1 to $5 per week").
	Based on this advice we assign repayments to overpayment and recoverable assistance besed on the oldest outstanding debt.
	We do not fully address point (2), but where overpayment and recoverable assistance debt is incurred in the same month we
	assign repayment first to recoverable assistance.

11. Detailed notes on the assumptions underlying our splitting of repayments into overpayment and recoverable assistance
	can be found in supporting scripts. Key points from these can be summarised as follows:
	- A significant proportion of recoverable assistance payments (~80%) are done via benefit advances.
		This means that ignoring point (2) above is a strong assumption. And so analysis that depends on the exact timing
		that individuals gain or repay debt of a specific type will be less reliable.
	- Less than 5% of records where a debt is incurred has both overpayment and recoverable assistance incurred in the
		same month. As recoverable assistance is mainly requested by people on benefit, and overpayment is more likely
		to happen when a person comes off benefit, assuming repayment of recoverable assistance before overpayment in this
		case is not a strong assumption and will introduce minimal error into our results.
	- While repayments are allocated oldest-to-newest, we do not know how debt write-offs are allocated. But as write-offs
		are much less common than repayments (of every amount) treating write-offs as repayments seems reasonable.

12. Openning balances are much harder to separate into overpayment and recoverable assistance. This will have flow-on
	consequences for splitting repayments. More than 90% of openning balances (in the dataset) have been repaid by the
	end of 2018 (the earliest period for our study). As these unpaid balances will mostly be classified as overpayment,
	and overpayment debts are more likely to be large, this isunlikely to have significant impact on our results.
	However, researchers wanting to look at pre-2018 debt patterns may wish to refine our techniques.

13. When classifying repayments and write-offs to overpayment and recoverable assistance, we identify payments that are
	recoverable assistance. All other amounts are attributed to overpayment. Reverse payments and write-offs (wrong-signs)
	are handled via 'all other amounts' and hence are treated as overpayment.
	Less than 0.1% of all records contain a wrong sign (31000 of 44637000). Almost all wrong signs are write offs, and
	about 12% (25000 of 198000) of all write offs are wrong sign (positive).

14. Notes in this file supported by investigations recorded in:
	- testing msd debt data.sql
	- splitting_msd_debt_repayments - drafting ideas.sql
	- splitting_msd_debt_repayments - investigating complications.sql

Issues:
1. Runtime is long even with indexing >15 minutes (much slower at peak times).

Parameters & Present values:
  Current refresh = 20201020
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]

History (reverse order):
2021-06-18 FL create repayment indicator
2021-05-28 FL including annual principle, repayment,... for the different debt type 
2021-03-11 SA splitting repayments against overpayment and recoverable assistance
2021-02-03 FL including classified msd debt (overpayment and recoverable assistance) into this definition
2021-01-26 SA QA
2021-01-13 FL Create monthly time series
2020-12-21 FL v2 (update to the latest refresh, make necessary changes to the code)
2020-11-24 FL QA
2020-06-22 SA v1
2020-03-19 SA work begun
**************************************************************************************************/

/*
Reference, input dataset

Notes:
- joined to spine
- indexed by snz_uid
- [amount_incurred], [amount_repaid], and [amount_written_off] contain zeros instead of NULL
- [amount_incurred_assistance], and [amount_incurred_overpayment] contains NULL if no amount incurred
- there are no duplicate months per individual
*/
/*
SELECT TOP 100 snz_uid
	  ,[snz_msd_uid]
      ,[debt_as_at_date]
	  ,[amount_incurred]
      ,[amount_repaid]
	  ,[amount_written_off]
	  ,amount_incurred_assistance
	  ,amount_incurred_overpayment
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt];
*/

/**************************************************************************************************
Non-negative repayments/write-offs are treated as overpayment debt
**************************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_signs_handled]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_signs_handled];
GO

SELECT snz_uid
	,snz_msd_uid
	,debt_as_at_date
	,amount_incurred
		+ IIF(amount_repaid > 0, amount_repaid, 0)
		+ IIF(amount_written_off > 0, amount_written_off, 0)
		AS amount_incurred
	,IIF(amount_repaid <= 0, amount_repaid, 0) AS amount_repaid
	,IIF(amount_written_off <= 0, amount_written_off, 0) AS amount_written_off
	,ISNULL(amount_incurred_assistance, 0) AS amount_incurred_assistance
	,ISNULL(amount_incurred_overpayment, 0)
		+ IIF(amount_repaid > 0, amount_repaid, 0)
		+ IIF(amount_written_off > 0, amount_written_off, 0)
		AS amount_incurred_overpayment
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_signs_handled]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt]


/**************************************************************************************************
Split repayments and write-offs into overpayment and recoverable assistance
**************************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_classified_msd_repayment]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_classified_msd_repayment];
GO

/*
Concept for approach:

There is a technique we use for counting days in overlapping date ranges:
Given date1 - date2 and date3 - date4 as "the zone", count the number of days in dateA - dateB that are "in zone".
We can do the same thing for repayments - count dollar overlap ranges:
Given amount1 - amount2 and amount3 - amount4 are "recoverable assistance", count the number of dollars in amountA - amountB that are "recoverable assistance".

First setup dollar ranges of debt incurred.
For example:
First debt $100 overpayment, second debt $70 recoverable assistance, third debt $220 recoverable assistance
Gives dollar ranges:
(  0,100] dollars owed for overpayment
(100,170] dollars owed for recoverable assistance
(170,390] dollars owed for recoverable assistance

Second setup dollar ranges for repayments.
For example:
Repayment of $200 in January, followed by $90 in February.
Gives dollar ranges:
(  0,200] dollars paid in Jan
(200,290] dollars paid in Feb

Overlapping these dollar ranges:
(  0,200] dollars paid in Jan overlaps (  0,100] dollars owed for overpayment            so $100 overpayment            repaid in Jan
(  0,200] dollars paid in Jan overlaps (100,170] dollars owed for recoverable assistance so  $70 recoverable assistance repaid in Jan
(  0,200] dollars paid in Jan overlaps (170,390] dollars owed for recoverable assistance so  $30 recoverable assistance repaid in Jan
(200,290] dollars paid in Feb overlaps (170,390] dollars owed for recoverable assistance so  $90 recoverable assistance repaid in Feb
No overlap for the last $100 owed, so outstanding balance = $100 owed for recoverable assistance
*/

WITH
recoverable_assistance_range AS (

	SELECT snz_uid
		,snz_msd_uid
		,debt_as_at_date
		,amount_incurred
		,amount_incurred_assistance
		,amount_incurred_overpayment
		/* total debt incurred up-to-and-including current row - debt incurred this row = debt up-to-but-excluding current row */
		,SUM(amount_incurred) OVER (PARTITION BY snz_uid ORDER BY debt_as_at_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
			- amount_incurred AS assistance_start
		/* total debt incurred up-to-and-including current row - overpayment debt incurred this row = debt up-to-and-including recoverable assistance debt in current row */
		,SUM(amount_incurred) OVER (PARTITION BY snz_uid ORDER BY debt_as_at_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
			- amount_incurred_overpayment AS assistance_end
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_signs_handled]
	WHERE amount_incurred > 0

),
repayment_range AS (

	SELECT snz_uid
		,snz_msd_uid
		,debt_as_at_date
		,amount_incurred
		,amount_repaid
		,amount_written_off
		/* total repayment up-to-and-including current row - repayments this row = repayment up-to-but-excluding current row */
		,-1.0 * (SUM(amount_repaid + amount_written_off) OVER (PARTITION BY snz_uid ORDER BY debt_as_at_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
			- (amount_repaid + amount_written_off)) AS repayment_start
		/* total repayment up-to-and-including current row */
		,-1.0 * SUM(amount_repaid + amount_written_off) OVER (PARTITION BY snz_uid ORDER BY debt_as_at_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
			AS repayment_end
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_signs_handled]
	WHERE amount_repaid <> 0
	OR amount_written_off <> 0

),
split AS (

	SELECT r.snz_uid
		,r.debt_as_at_date
		,a.assistance_start
		,a.assistance_end
		,r.repayment_start AS repayment_start
		,r.repayment_end AS repayment_end
		,IIF(a.assistance_start < r.repayment_start, r.repayment_start, a.assistance_start) AS latest_start
		,IIF(a.assistance_end < r.repayment_end, a.assistance_end, r.repayment_end) AS earliest_end
		,IIF(a.assistance_end < r.repayment_end, a.assistance_end, r.repayment_end)
			- IIF(a.assistance_start < r.repayment_start, r.repayment_start, a.assistance_start)
			AS overlap_is_repayment_of_recoverable_assistance
	FROM repayment_range AS r
	INNER JOIN recoverable_assistance_range AS a
	ON r.snz_uid = a.snz_uid
	AND a.assistance_start <= r.repayment_end
	AND r.repayment_start <= a.assistance_end

)
SELECT snz_uid
	,debt_as_at_date
	,SUM(overlap_is_repayment_of_recoverable_assistance) AS recoverable_assistance_repaid
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_classified_msd_repayment]
FROM split
GROUP BY snz_uid, debt_as_at_date

/* Index by snz_uid (improve efficiency) */
CREATE CLUSTERED INDEX snz_uid_index ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_classified_msd_repayment] (snz_uid); 
GO

/**************************************************************************************************
Join repayment split back to base table
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt_and_repayment]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt_and_repayment];
GO

SELECT c.snz_uid
	  ,c.[snz_msd_uid]
      ,c.[debt_as_at_date]
	  ,[amount_incurred]
      ,[amount_repaid]
	  ,[amount_written_off]
	  ,amount_incurred_assistance
	  ,amount_incurred_overpayment
	  ,-1.0 * ROUND(ISNULL(r.recoverable_assistance_repaid, 0), 2) AS amount_repaid_assistance
	  ,-1.0 * ROUND((-[amount_repaid]) + (-[amount_written_off]) - ISNULL(r.recoverable_assistance_repaid,0), 2) AS amount_repaid_overpayment
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt_and_repayment]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_signs_handled] AS c
LEFT JOIN [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_classified_msd_repayment] AS r
ON c.snz_uid = r.snz_uid
AND c.debt_as_at_date = r.debt_as_at_date

/* Index by snz_uid (improve efficiency) */
CREATE CLUSTERED INDEX snz_uid_index ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt_and_repayment] (snz_uid); 
GO

/****************************************************************************************
Monthly debt balances (Jan 2019 -- Sep 2020)
****************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_classified_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_classified_debt_by_month];
GO

WITH manual_pivot AS (

SELECT snz_uid
	,[snz_msd_uid]
	,[debt_as_at_date]
	,[amount_incurred]
	,[amount_repaid]
	,[amount_written_off]
	,amount_incurred_assistance
	,amount_incurred_overpayment
	,amount_repaid_assistance
	,amount_repaid_overpayment
	/* 2019 months overpayment setup */
	,IIF([debt_as_at_date] <= '2019-01-31', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2019Jan_OV_value
	,IIF([debt_as_at_date] <= '2019-02-28', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2019Feb_OV_value
	,IIF([debt_as_at_date] <= '2019-03-31', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2019Mar_OV_value
	,IIF([debt_as_at_date] <= '2019-04-30', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2019Apr_OV_value
	,IIF([debt_as_at_date] <= '2019-05-31', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2019May_OV_value
	,IIF([debt_as_at_date] <= '2019-06-30', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2019Jun_OV_value
	,IIF([debt_as_at_date] <= '2019-07-31', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2019Jul_OV_value
	,IIF([debt_as_at_date] <= '2019-08-31', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2019Aug_OV_value
	,IIF([debt_as_at_date] <= '2019-09-30', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2019Sep_OV_value
	,IIF([debt_as_at_date] <= '2019-10-31', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2019Oct_OV_value
	,IIF([debt_as_at_date] <= '2019-11-30', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2019Nov_OV_value
	,IIF([debt_as_at_date] <= '2019-12-31', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2019Dec_OV_value
	/* 2020 months overpayment setup */
	,IIF([debt_as_at_date] <= '2020-01-31', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2020Jan_OV_value
	,IIF([debt_as_at_date] <= '2020-02-29', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2020Feb_OV_value
	,IIF([debt_as_at_date] <= '2020-03-31', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2020Mar_OV_value
	,IIF([debt_as_at_date] <= '2020-04-30', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2020Apr_OV_value
	,IIF([debt_as_at_date] <= '2020-05-31', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2020May_OV_value
	,IIF([debt_as_at_date] <= '2020-06-30', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2020Jun_OV_value
	,IIF([debt_as_at_date] <= '2020-07-31', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2020Jul_OV_value
	,IIF([debt_as_at_date] <= '2020-08-31', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2020Aug_OV_value
	,IIF([debt_as_at_date] <= '2020-09-30', ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0), 0) AS for_2020Sep_OV_value
	/* 2019 months recoverable assistance setup */
	,IIF([debt_as_at_date] <= '2019-01-31', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2019Jan_RA_value
	,IIF([debt_as_at_date] <= '2019-02-28', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2019Feb_RA_value
	,IIF([debt_as_at_date] <= '2019-03-31', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2019Mar_RA_value
	,IIF([debt_as_at_date] <= '2019-04-30', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2019Apr_RA_value
	,IIF([debt_as_at_date] <= '2019-05-31', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2019May_RA_value
	,IIF([debt_as_at_date] <= '2019-06-30', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2019Jun_RA_value
	,IIF([debt_as_at_date] <= '2019-07-31', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2019Jul_RA_value
	,IIF([debt_as_at_date] <= '2019-08-31', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2019Aug_RA_value
	,IIF([debt_as_at_date] <= '2019-09-30', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2019Sep_RA_value
	,IIF([debt_as_at_date] <= '2019-10-31', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2019Oct_RA_value
	,IIF([debt_as_at_date] <= '2019-11-30', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2019Nov_RA_value
	,IIF([debt_as_at_date] <= '2019-12-31', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2019Dec_RA_value
	/* 2020 months recoverable assistance setup */
	,IIF([debt_as_at_date] <= '2020-01-31', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2020Jan_RA_value
	,IIF([debt_as_at_date] <= '2020-02-29', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2020Feb_RA_value
	,IIF([debt_as_at_date] <= '2020-03-31', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2020Mar_RA_value
	,IIF([debt_as_at_date] <= '2020-04-30', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2020Apr_RA_value
	,IIF([debt_as_at_date] <= '2020-05-31', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2020May_RA_value
	,IIF([debt_as_at_date] <= '2020-06-30', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2020Jun_RA_value
	,IIF([debt_as_at_date] <= '2020-07-31', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2020Jul_RA_value
	,IIF([debt_as_at_date] <= '2020-08-31', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2020Aug_RA_value
	,IIF([debt_as_at_date] <= '2020-09-30', ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0), 0) AS for_2020Sep_RA_value	

	/* debt components for 2019 and 2020*/
	,IIF(YEAR(debt_as_at_date) < 2019, COALESCE(amount_incurred_assistance, 0) + COALESCE(amount_repaid_assistance, 0), 0)  AS  pre_2019_delta_RA
	,IIF(YEAR(debt_as_at_date) < 2019, COALESCE(amount_incurred_overpayment, 0) + COALESCE(amount_repaid_overpayment, 0), 0)  AS  pre_2019_delta_OV
	,IIF(YEAR([debt_as_at_date]) = 2019, COALESCE([amount_incurred_assistance], 0), 0) AS for_2019_principle_RA
	,IIF(YEAR([debt_as_at_date]) = 2019, COALESCE([amount_incurred_overpayment], 0), 0) AS for_2019_principle_OV
	,IIF(YEAR([debt_as_at_date]) = 2019, COALESCE([amount_repaid_assistance], 0), 0) AS for_2019_payment_writeoff_RA
	,IIF(YEAR([debt_as_at_date]) = 2019, COALESCE([amount_repaid_overpayment], 0), 0) AS for_2019_payment_writeoff_OV
	,IIF(YEAR([debt_as_at_date]) = 2020, COALESCE([amount_incurred_assistance], 0), 0) AS for_2020_principle_RA
	,IIF(YEAR([debt_as_at_date]) = 2020, COALESCE([amount_incurred_overpayment], 0), 0) AS for_2020_principle_OV
	,IIF(YEAR([debt_as_at_date]) = 2020, COALESCE([amount_repaid_assistance], 0), 0) AS for_2020_payment_writeoff_RA
	,IIF(YEAR([debt_as_at_date]) = 2020, COALESCE([amount_repaid_overpayment], 0), 0) AS for_2020_payment_writeoff_OV

	/*repayment plan*/
	,IIF('2020-07-01' <= debt_as_at_date AND debt_as_at_date <= '2020-09-30' AND amount_repaid_assistance < -1, 1, 0) AS for_payment_3mth_RA
	,IIF('2020-04-01' <= debt_as_at_date AND debt_as_at_date <= '2020-09-30' AND amount_repaid_assistance < -1, 1, 0) AS for_payment_6mth_RA
	,IIF('2020-01-01' <= debt_as_at_date AND debt_as_at_date <= '2020-09-30' AND amount_repaid_assistance < -1, 1, 0) AS for_payment_9mth_RA
	,IIF('2019-10-01' <= debt_as_at_date AND debt_as_at_date <= '2020-09-30' AND amount_repaid_assistance < -1, 1, 0) AS for_payment_12mth_RA

	,IIF('2020-07-01' <= debt_as_at_date AND debt_as_at_date <= '2020-09-30' AND amount_repaid_overpayment < -1, 1, 0) AS for_payment_3mth_OV
	,IIF('2020-04-01' <= debt_as_at_date AND debt_as_at_date <= '2020-09-30' AND amount_repaid_overpayment < -1, 1, 0) AS for_payment_6mth_OV
	,IIF('2020-01-01' <= debt_as_at_date AND debt_as_at_date <= '2020-09-30' AND amount_repaid_overpayment < -1, 1, 0) AS for_payment_9mth_OV
	,IIF('2019-10-01' <= debt_as_at_date AND debt_as_at_date <= '2020-09-30' AND amount_repaid_overpayment < -1, 1, 0) AS for_payment_12mth_OV

	
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt_and_repayment]

)
SELECT snz_uid
	/* 2019 months overpayment setup */
	,ROUND(SUM(for_2019Jan_OV_value), 2) AS overpayment_balance_2019Jan
	,ROUND(SUM(for_2019Feb_OV_value), 2) AS overpayment_balance_2019Feb
	,ROUND(SUM(for_2019Mar_OV_value), 2) AS overpayment_balance_2019Mar
	,ROUND(SUM(for_2019Apr_OV_value), 2) AS overpayment_balance_2019Apr
	,ROUND(SUM(for_2019May_OV_value), 2) AS overpayment_balance_2019May
	,ROUND(SUM(for_2019Jun_OV_value), 2) AS overpayment_balance_2019Jun
	,ROUND(SUM(for_2019Jul_OV_value), 2) AS overpayment_balance_2019Jul
	,ROUND(SUM(for_2019Aug_OV_value), 2) AS overpayment_balance_2019Aug
	,ROUND(SUM(for_2019Sep_OV_value), 2) AS overpayment_balance_2019Sep
	,ROUND(SUM(for_2019Oct_OV_value), 2) AS overpayment_balance_2019Oct
	,ROUND(SUM(for_2019Nov_OV_value), 2) AS overpayment_balance_2019Nov
	,ROUND(SUM(for_2019Dec_OV_value), 2) AS overpayment_balance_2019Dec
	/* 2020 months overpayment setup */
	,ROUND(SUM(for_2020Jan_OV_value), 2) AS overpayment_balance_2020Jan
	,ROUND(SUM(for_2020Feb_OV_value), 2) AS overpayment_balance_2020Feb
	,ROUND(SUM(for_2020Mar_OV_value), 2) AS overpayment_balance_2020Mar
	,ROUND(SUM(for_2020Apr_OV_value), 2) AS overpayment_balance_2020Apr
	,ROUND(SUM(for_2020May_OV_value), 2) AS overpayment_balance_2020May
	,ROUND(SUM(for_2020Jun_OV_value), 2) AS overpayment_balance_2020Jun
	,ROUND(SUM(for_2020Jul_OV_value), 2) AS overpayment_balance_2020Jul
	,ROUND(SUM(for_2020Aug_OV_value), 2) AS overpayment_balance_2020Aug
	,ROUND(SUM(for_2020Sep_OV_value), 2) AS overpayment_balance_2020Sep
	/* 2019 months recoverable assistance setup */
	,ROUND(SUM(for_2019Jan_RA_value), 2) AS assistance_balance_2019Jan
	,ROUND(SUM(for_2019Feb_RA_value), 2) AS assistance_balance_2019Feb
	,ROUND(SUM(for_2019Mar_RA_value), 2) AS assistance_balance_2019Mar
	,ROUND(SUM(for_2019Apr_RA_value), 2) AS assistance_balance_2019Apr
	,ROUND(SUM(for_2019May_RA_value), 2) AS assistance_balance_2019May
	,ROUND(SUM(for_2019Jun_RA_value), 2) AS assistance_balance_2019Jun
	,ROUND(SUM(for_2019Jul_RA_value), 2) AS assistance_balance_2019Jul
	,ROUND(SUM(for_2019Aug_RA_value), 2) AS assistance_balance_2019Aug
	,ROUND(SUM(for_2019Sep_RA_value), 2) AS assistance_balance_2019Sep
	,ROUND(SUM(for_2019Oct_RA_value), 2) AS assistance_balance_2019Oct
	,ROUND(SUM(for_2019Nov_RA_value), 2) AS assistance_balance_2019Nov
	,ROUND(SUM(for_2019Dec_RA_value), 2) AS assistance_balance_2019Dec
	/* 2020 months recoverable assistance setup */
	,ROUND(SUM(for_2020Jan_RA_value), 2) AS assistance_balance_2020Jan
	,ROUND(SUM(for_2020Feb_RA_value), 2) AS assistance_balance_2020Feb
	,ROUND(SUM(for_2020Mar_RA_value), 2) AS assistance_balance_2020Mar
	,ROUND(SUM(for_2020Apr_RA_value), 2) AS assistance_balance_2020Apr
	,ROUND(SUM(for_2020May_RA_value), 2) AS assistance_balance_2020May
	,ROUND(SUM(for_2020Jun_RA_value), 2) AS assistance_balance_2020Jun
	,ROUND(SUM(for_2020Jul_RA_value), 2) AS assistance_balance_2020Jul
	,ROUND(SUM(for_2020Aug_RA_value), 2) AS assistance_balance_2020Aug
	,ROUND(SUM(for_2020Sep_RA_value), 2) AS assistance_balance_2020Sep

	/* debt components for 2019 and 2020*/
	,ROUND(SUM(pre_2019_delta_RA), 2) AS balance_pre_2019_RA
	,ROUND(SUM(pre_2019_delta_OV), 2) AS balance_pre_2019_OV
	,ROUND(SUM(for_2019_principle_RA), 2) AS principle_2019_RA
	,ROUND(SUM(for_2019_principle_OV), 2) AS principle_2019_OV
	,ROUND(SUM(for_2019_payment_writeoff_RA), 2) AS payment_writeoff_2019_RA
	,ROUND(SUM(for_2019_payment_writeoff_OV), 2) AS payment_writeoff_2019_OV
	,ROUND(SUM(for_2020_principle_RA), 2) AS principle_2020_RA
	,ROUND(SUM(for_2020_principle_OV), 2) AS principle_2020_OV
	,ROUND(SUM(for_2020_payment_writeoff_RA), 2) AS payment_writeoff_2020_RA
	,ROUND(SUM(for_2020_payment_writeoff_OV), 2) AS payment_writeoff_2020_OV

	/*repayment indicator*/
	,IIF(SUM(for_payment_3mth_RA) >= 1, 1, 0) AS ind_payment_3mth_RA
	,IIF(SUM(for_payment_6mth_RA) >= 1, 1, 0) AS ind_payment_6mth_RA
	,IIF(SUM(for_payment_9mth_RA) >= 1, 1, 0) AS ind_payment_9mth_RA
	,IIF(SUM(for_payment_12mth_RA) >= 1, 1, 0) AS ind_payment_12mth_RA
	,IIF(SUM(for_payment_3mth_OV) >= 1, 1, 0) AS ind_payment_3mth_OV
	,IIF(SUM(for_payment_6mth_OV) >= 1, 1, 0) AS ind_payment_6mth_OV
	,IIF(SUM(for_payment_9mth_OV) >= 1, 1, 0) AS ind_payment_9mth_OV
	,IIF(SUM(for_payment_12mth_OV) >= 1, 1, 0) AS ind_payment_12mth_OV

INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_classified_debt_by_month]
FROM manual_pivot
GROUP BY snz_uid
/* At least one month has non-zero balance */
HAVING ABS(SUM(for_2019Jan_OV_value)) > 1
OR ABS(SUM(for_2019Feb_OV_value)) > 1
OR ABS(SUM(for_2019Mar_OV_value)) > 1
OR ABS(SUM(for_2019Apr_OV_value)) > 1
OR ABS(SUM(for_2019May_OV_value)) > 1
OR ABS(SUM(for_2019Jun_OV_value)) > 1
OR ABS(SUM(for_2019Jul_OV_value)) > 1
OR ABS(SUM(for_2019Aug_OV_value)) > 1
OR ABS(SUM(for_2019Sep_OV_value)) > 1
OR ABS(SUM(for_2019Oct_OV_value)) > 1
OR ABS(SUM(for_2019Nov_OV_value)) > 1
OR ABS(SUM(for_2019Dec_OV_value)) > 1
/* 2020 months overpayment setup */
OR ABS(SUM(for_2020Jan_OV_value)) > 1
OR ABS(SUM(for_2020Feb_OV_value)) > 1
OR ABS(SUM(for_2020Mar_OV_value)) > 1
OR ABS(SUM(for_2020Apr_OV_value)) > 1
OR ABS(SUM(for_2020May_OV_value)) > 1
OR ABS(SUM(for_2020Jun_OV_value)) > 1
OR ABS(SUM(for_2020Jul_OV_value)) > 1
OR ABS(SUM(for_2020Aug_OV_value)) > 1
OR ABS(SUM(for_2020Sep_OV_value)) > 1
/* 2019 months recoverable assistance setup */
OR ABS(SUM(for_2019Jan_RA_value)) > 1
OR ABS(SUM(for_2019Feb_RA_value)) > 1
OR ABS(SUM(for_2019Mar_RA_value)) > 1
OR ABS(SUM(for_2019Apr_RA_value)) > 1
OR ABS(SUM(for_2019May_RA_value)) > 1
OR ABS(SUM(for_2019Jun_RA_value)) > 1
OR ABS(SUM(for_2019Jul_RA_value)) > 1
OR ABS(SUM(for_2019Aug_RA_value)) > 1
OR ABS(SUM(for_2019Sep_RA_value)) > 1
OR ABS(SUM(for_2019Oct_RA_value)) > 1
OR ABS(SUM(for_2019Nov_RA_value)) > 1
OR ABS(SUM(for_2019Dec_RA_value)) > 1
/* 2020 months recoverable assistance setup */
OR ABS(SUM(for_2020Jan_RA_value)) > 1
OR ABS(SUM(for_2020Feb_RA_value)) > 1
OR ABS(SUM(for_2020Mar_RA_value)) > 1
OR ABS(SUM(for_2020Apr_RA_value)) > 1
OR ABS(SUM(for_2020May_RA_value)) > 1
OR ABS(SUM(for_2020Jun_RA_value)) > 1
OR ABS(SUM(for_2020Jul_RA_value)) > 1
OR ABS(SUM(for_2020Aug_RA_value)) > 1
OR ABS(SUM(for_2020Sep_RA_value)) > 1

CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_classified_debt_by_month] (snz_uid);
GO



/*debt persistence*/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_classified_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_classified_debt_by_month];
GO

SELECT *
     ,IIF(overpayment_balance_2020Sep > 1 AND overpayment_balance_2020Aug > 1 AND overpayment_balance_2020Jul > 1, 1, 0) persistence_3mth_OV
	 ,IIF(overpayment_balance_2020Sep > 1 AND overpayment_balance_2020Aug > 1 AND overpayment_balance_2020Jul > 1
	          AND overpayment_balance_2020Jun > 1 AND overpayment_balance_2020May > 1 AND overpayment_balance_2020Apr > 1, 1, 0) persistence_6mth_OV
	 ,IIF(overpayment_balance_2020Sep > 1 AND overpayment_balance_2020Aug > 1 AND overpayment_balance_2020Jul >1
	          AND overpayment_balance_2020Jun > 1 AND overpayment_balance_2020May > 1 AND overpayment_balance_2020Apr > 1
			  AND overpayment_balance_2020Mar > 1 AND overpayment_balance_2020Feb > 1 AND overpayment_balance_2020Jan > 1, 1, 0) persistence_9mth_OV
	 ,IIF(overpayment_balance_2020Sep > 1 AND overpayment_balance_2020Aug > 1 AND overpayment_balance_2020Jul > 1
	          AND overpayment_balance_2020Jun > 1 AND overpayment_balance_2020May > 1 AND overpayment_balance_2020Apr > 1
			  AND overpayment_balance_2020Mar > 1 AND overpayment_balance_2020Feb > 1 AND overpayment_balance_2020Jan > 1
	    	  AND overpayment_balance_2019Dec > 1 AND overpayment_balance_2019Nov > 1 AND overpayment_balance_2019Oct > 1, 1, 0) persistence_12mth_OV
	  ,IIF(overpayment_balance_2020Sep > 1 AND overpayment_balance_2020Aug > 1 AND overpayment_balance_2020Jul > 1
	          AND overpayment_balance_2020Jun > 1 AND overpayment_balance_2020May > 1 AND overpayment_balance_2020Apr > 1 
			  AND overpayment_balance_2020Mar > 1 AND overpayment_balance_2020Feb > 1 AND overpayment_balance_2020Jan > 1 
			  AND overpayment_balance_2019Dec > 1 AND overpayment_balance_2019Nov > 1 AND overpayment_balance_2019Oct > 1
			  AND overpayment_balance_2019Sep > 1 AND overpayment_balance_2019Aug > 1 AND overpayment_balance_2019Jul > 1, 1, 0) persistence_15mth_OV
	  ,IIF(overpayment_balance_2020Sep > 1 AND overpayment_balance_2020Aug > 1 AND overpayment_balance_2020Jul > 1
	          AND overpayment_balance_2020Jun > 1 AND overpayment_balance_2020May > 1 AND overpayment_balance_2020Apr > 1
			  AND overpayment_balance_2020Mar > 1 AND overpayment_balance_2020Feb > 1 AND overpayment_balance_2020Jan > 1
			  AND overpayment_balance_2019Dec > 1 AND overpayment_balance_2019Nov > 1 AND overpayment_balance_2019Oct > 1
			  AND overpayment_balance_2019Sep > 1 AND overpayment_balance_2019Aug > 1 AND overpayment_balance_2019Jul > 1
			  AND overpayment_balance_2019Jun > 1 AND overpayment_balance_2019May > 1 AND overpayment_balance_2019Apr > 1, 1, 0) persistence_18mth_OV
	  ,IIF(overpayment_balance_2020Sep > 1 AND overpayment_balance_2020Aug > 1 AND overpayment_balance_2020Jul > 1
	          AND overpayment_balance_2020Jun > 1 AND overpayment_balance_2020May > 1 AND overpayment_balance_2020Apr > 1
			  AND overpayment_balance_2020Mar > 1 AND overpayment_balance_2020Feb > 1 AND overpayment_balance_2020Jan > 1
			  AND overpayment_balance_2019Dec > 1 AND overpayment_balance_2019Nov > 1 AND overpayment_balance_2019Oct > 1
			  AND overpayment_balance_2019Sep > 1 AND overpayment_balance_2019Aug > 1 AND overpayment_balance_2019Jul > 1
			  AND overpayment_balance_2019Jun > 1 AND overpayment_balance_2019May > 1 AND overpayment_balance_2019Apr > 1
			  AND overpayment_balance_2019Mar > 1 AND overpayment_balance_2019Feb > 1 AND overpayment_balance_2019Jan > 1, 1, 0) persistence_21mth_OV

     ,IIF(assistance_balance_2020Sep > 1 AND assistance_balance_2020Aug > 1 AND assistance_balance_2020Jul > 1, 1, 0) persistence_3mth_RA
	 ,IIF(assistance_balance_2020Sep > 1 AND assistance_balance_2020Aug > 1 AND assistance_balance_2020Jul > 1
	          AND assistance_balance_2020Jun > 1 AND assistance_balance_2020May > 1 AND assistance_balance_2020Apr > 1, 1, 0) persistence_6mth_RA
	 ,IIF(assistance_balance_2020Sep > 1 AND assistance_balance_2020Aug > 1 AND assistance_balance_2020Jul >1
	          AND assistance_balance_2020Jun > 1 AND assistance_balance_2020May > 1 AND assistance_balance_2020Apr > 1
			  AND assistance_balance_2020Mar > 1 AND assistance_balance_2020Feb > 1 AND assistance_balance_2020Jan > 1, 1, 0) persistence_9mth_RA
	 ,IIF(assistance_balance_2020Sep > 1 AND assistance_balance_2020Aug > 1 AND assistance_balance_2020Jul > 1
	          AND assistance_balance_2020Jun > 1 AND assistance_balance_2020May > 1 AND assistance_balance_2020Apr > 1
			  AND assistance_balance_2020Mar > 1 AND assistance_balance_2020Feb > 1 AND assistance_balance_2020Jan > 1
	    	  AND assistance_balance_2019Dec > 1 AND assistance_balance_2019Nov > 1 AND assistance_balance_2019Oct > 1, 1, 0) persistence_12mth_RA
	  ,IIF(assistance_balance_2020Sep > 1 AND assistance_balance_2020Aug > 1 AND assistance_balance_2020Jul > 1
	          AND assistance_balance_2020Jun > 1 AND assistance_balance_2020May > 1 AND assistance_balance_2020Apr > 1 
			  AND assistance_balance_2020Mar > 1 AND assistance_balance_2020Feb > 1 AND assistance_balance_2020Jan > 1 
			  AND assistance_balance_2019Dec > 1 AND assistance_balance_2019Nov > 1 AND assistance_balance_2019Oct > 1
			  AND assistance_balance_2019Sep > 1 AND assistance_balance_2019Aug > 1 AND assistance_balance_2019Jul > 1, 1, 0) persistence_15mth_RA
	  ,IIF(assistance_balance_2020Sep > 1 AND assistance_balance_2020Aug > 1 AND assistance_balance_2020Jul > 1
	          AND assistance_balance_2020Jun > 1 AND assistance_balance_2020May > 1 AND assistance_balance_2020Apr > 1
			  AND assistance_balance_2020Mar > 1 AND assistance_balance_2020Feb > 1 AND assistance_balance_2020Jan > 1
			  AND assistance_balance_2019Dec > 1 AND assistance_balance_2019Nov > 1 AND assistance_balance_2019Oct > 1
			  AND assistance_balance_2019Sep > 1 AND assistance_balance_2019Aug > 1 AND assistance_balance_2019Jul > 1
			  AND assistance_balance_2019Jun > 1 AND assistance_balance_2019May > 1 AND assistance_balance_2019Apr > 1, 1, 0) persistence_18mth_RA
	  ,IIF(assistance_balance_2020Sep > 1 AND assistance_balance_2020Aug > 1 AND assistance_balance_2020Jul > 1
	          AND assistance_balance_2020Jun > 1 AND assistance_balance_2020May > 1 AND assistance_balance_2020Apr > 1
			  AND assistance_balance_2020Mar > 1 AND assistance_balance_2020Feb > 1 AND assistance_balance_2020Jan > 1
			  AND assistance_balance_2019Dec > 1 AND assistance_balance_2019Nov > 1 AND assistance_balance_2019Oct > 1
			  AND assistance_balance_2019Sep > 1 AND assistance_balance_2019Aug > 1 AND assistance_balance_2019Jul > 1
			  AND assistance_balance_2019Jun > 1 AND assistance_balance_2019May > 1 AND assistance_balance_2019Apr > 1
			  AND assistance_balance_2019Mar > 1 AND assistance_balance_2019Feb > 1 AND assistance_balance_2019Jan > 1, 1, 0) persistence_21mth_RA
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_classified_debt_by_month]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_classified_debt_by_month]
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_classified_debt_by_month] (snz_uid);
GO



/*********** remove temporary tables ***********/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_signs_handled]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_signs_handled];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_classified_msd_repayment]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_classified_msd_repayment];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_classified_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_classified_debt_by_month];
GO

/*********** compress tables ***********/
ALTER TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt_and_repayment] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
ALTER TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_classified_debt_by_month] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
