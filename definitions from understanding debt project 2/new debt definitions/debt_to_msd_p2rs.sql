/**************************************************************************************************
Title: Debt to MSD Phase 2
Authors: Freya Li and Simon Anastasiadis

Inputs & Dependencies:
- "classifying MSD debt using T3 data.sql" --> [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt]
Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_non_transactions]
- [IDI_UserCode].[DL-MAA2020-01].[d2gP2_msd_labels_balance]
- [IDI_UserCode].[DL-MAA2020-01].[d2gP2_msd_labels_transactions_part1]
- [IDI_UserCode].[DL-MAA2020-01].[d2gP2_msd_labels_transactions_part2]
- [IDI_UserCode].[DL-MAA2020-01].[d2gP2_msd_labels_repayments_part1]
- [IDI_UserCode].[DL-MAA2020-01].[d2gP2_msd_labels_repayments_part2]
- [IDI_UserCode].[DL-MAA2020-01].[d2gP2_msd_labels_persist]

Description:
Debt, debt balances, and repayment for debtors owing money to MSD.
Considering debt by Overpayment and Recoverable Assistance.

Intended purpose:
Identifying debtors.
Calculating number of debts and total value of debts.
Calculating change in debts - due to borrowing or repayment.

Notes: 
1. This file builds on previous work that splits debt incurred into overpayment and recoverable assistance. This file extends
	this work by splitting repayments into overpayment and recoverable assistance. This is done in accordance with guidance
	from MSD that:
	(1) The earliest debt is paid off first
	(2) benefit advances are paid off in parallel with other repayments ("separately at a rate of $1 to $5 per week").
	Based on this advice we assign repayments to overpayment and recoverable assistance besed on the oldest outstanding debt.
	We do not fully address point (2), but where overpayment and recoverable assistance debt is incurred in the same month we
	assign repayment first to recoverable assistance.

2. Detailed notes on the assumptions underlying our splitting of repayments into overpayment and recoverable assistance
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

3. Openning balances are much harder to separate into overpayment and recoverable assistance. This will have flow-on
	consequences for splitting repayments. More than 90% of openning balances (in the dataset) have been repaid by the
	end of 2018 (the earliest period for our study). As these unpaid balances will mostly be classified as overpayment,
	and overpayment debts are more likely to be large, this isunlikely to have significant impact on our results.
	However, researchers wanting to look at pre-2018 debt patterns may wish to refine our techniques.

4. When classifying repayments and write-offs to overpayment and recoverable assistance, we identify payments that are
	recoverable assistance. All other amounts are attributed to overpayment. Reverse payments and write-offs (wrong-signs)
	are handled via 'all other amounts' and hence are treated as overpayment.
	Less than 0.1% of all records contain a wrong sign (31000 of 44637000). Almost all wrong signs are write offs, and
	about 12% (25000 of 198000) of all write offs are wrong sign (positive).

5. We couldn't split writeoff and repayment seperately for recoverable assistance and overpayment debt. The month of 
	repayment for subtypes of MSD debt are estimations, as the writeoff is included in the repament.

6. Outlier values
	Some principle amounts > $10k, which is unlikely to be recoverable assistance or overpayment.
	Large transactions (>$10k) make up a tiny proportion of transactions (less than 0.1%) and 
	effect a small number of people (less than 3%) but are a significant amount of total amounts incurred (22%).
	Current hypothesis is that such amounts are fraud (which is part of the dataset) or 
	receipt of more than one form of recoverable assistance (e.g. one for clothes, another for heating).
	Conversation with MSD data experts suggests these amounts are most likely related to fraud.

7. Values approx 0 that should be zero is of minimal concern.
	As values are dollars, all numbers should be rounded to 2 decimal places.
	Less than 0.5% of people ever have an absolute debt balance of 1-5 cents.

8.  Recoverable assistance - Looking at third tier expenditure that is recoverable:
	- Amounts less than $2k are common
	- Amounts of $3-5k are uncommon
	- Amounts exceeding $5k occur but are rare
	So if we are concerned about spikes, $5k is a reasonable threshold for identifying spikes
	because people could plausably borrow and repay $2000 in recoverable assistance in a single month.

9. Spikes - Yes there are occurrences where people's balances change in a spike pattern
	(suddent, large change, immediately reversed) and the value of the change exceeds $5k.
	There are less than 6,000 instances of this in the dataset, about 0.01% of records
	The total amount of money involved is less than 0.2% of total debt.
	Hence this pattern is not of concern.

10. We would expect that a debtor's balance is always non-negative. So if we sum amounts incurred, repayments, and write offs,
	then debt balances should be >=0. However, some identities have dates on which their net amount owing is negative. About
	6000 people have negative amounts owing at some point (negative been considered as the cut-off). Inspection of the data
	suggests that this happens when repayments exceed debt, and rather than withdraw the excess, the amount is of debt is left
	negative until the individual borrows again (either overpayment or recoverable assistance). It is common to observe
	negative balances that later on become zero balances. We would not observe this if the negative balances implied that some
	debt incurred was not recorded in the dataset.

11. Notes in this file supported by investigations recorded in:
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
2021-10-06 SA merge relevant part of debt_to_msd_p2_split.sql in to reduce duplication
2021-09-08 FL restructure MSD debt data begun
**************************************************************************************************/

USE IDI_UserCode
GO

/*
Reference, input dataset

Notes:
- joined to spine
- indexed by snz_uid
- [amount_incurred], [amount_repaid], and [amount_written_off] contain zeros instead of NULL
- [amount_incurred_assistance], and [amount_incurred_overpayment] contains NULL if no amount incurred
- there are no duplicate months per individual
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
CREATE NONCLUSTERED INDEX snz_uid_index ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_classified_msd_repayment] (snz_uid); 
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
CREATE NONCLUSTERED INDEX snz_uid_index ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt_and_repayment] (snz_uid); 
GO
/*********** compress tables ***********/
ALTER TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt_and_repayment] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)

/**************************************************************************************************
Data preparation
Calculate running balances
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_prep]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_prep];
GO

SELECT *
	  ,SUM(delta) OVER (PARTITION BY snz_uid ORDER BY debt_as_at_date) AS balance
	  ,SUM(delta_assistance) OVER (PARTITION BY snz_uid ORDER BY debt_as_at_date) AS balance_assistance
	  ,SUM(delta_overpayment) OVER (PARTITION BY snz_uid ORDER BY debt_as_at_date) AS balance_overpayment
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_prep]
FROM(
	SELECT *
		  ,ISNULL(amount_incurred, 0) + ISNULL(amount_repaid, 0) + ISNULL(amount_written_off, 0) AS delta
		  ,ISNULL(amount_incurred_assistance, 0) + ISNULL(amount_repaid_assistance, 0) AS delta_assistance
		  ,ISNULL(amount_incurred_overpayment, 0) + ISNULL(amount_repaid_overpayment, 0) AS delta_overpayment
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt_and_repayment]
)b

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_prep] (snz_uid);
GO

/**************************************************************************************************
fill in records where balance is non-zero but transactions are zero
**************************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_non_transactions]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_non_transactions];
GO

WITH
/* list of 1000 numbers 1:1000 - spt_values is an admin table chosen as it is at least 1000 row long */
n AS (
	SELECT TOP 1000 ROW_NUMBER() OVER (ORDER BY type) AS x
	FROM master.dbo.spt_values
),
/* list of dates, constructed by adding list of numbers to initial date */
my_dates AS (
	SELECT TOP (DATEDIFF(MONTH, '2009-01-01', '2020-09-01') + 1) /* number of dates required */
		 EOMONTH(DATEADD(MONTH, x-1, '2009-01-01')) AS my_dates
	FROM n
	ORDER BY x
),
/* get the next date for each record */
debt_source AS (
	SELECT *
		,LEAD(debt_as_at_date, 1, '9999-01-01') OVER (PARTITION BY snz_uid  ORDER BY debt_as_at_date) AS lead_date
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_prep]
),
/* join where dates from list are between current and next date --> hence dates from list are missing */
joined AS (
	SELECT *
	FROM debt_source
	INNER JOIN my_dates
	ON EOMONTH(debt_as_at_date) < my_dates
	AND my_dates < EOMONTH(lead_date)
)
/* combine original and additional records into same table */
SELECT *
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_non_transactions]
FROM (
	/* original records */
	SELECT snz_uid
		,snz_msd_uid
		,debt_as_at_date
		,ROUND(amount_incurred, 2) AS amount_incurred
		,ROUND(amount_repaid, 2) AS amount_repaid
		,ROUND(amount_written_off, 2) AS amount_written_off
		,ROUND(amount_incurred_assistance, 2) AS amount_incurred_assistance
		,ROUND(amount_incurred_overpayment, 2) AS amount_incurred_overpayment
		,ROUND(amount_repaid_assistance, 2) AS amount_repaid_assistance
		,ROUND(amount_repaid_overpayment, 2) AS amount_repaid_overpayment
		,ROUND(delta, 2) AS delta
		,ROUND(delta_assistance, 2) AS delta_assistance
		,ROUND(delta_overpayment, 2) AS delta_overpayment
		,ROUND(balance, 2) AS balance
		,ROUND(balance_assistance, 2) AS balance_assistance
		,ROUND(balance_overpayment, 2) AS balance_overpayment
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_prep]

	UNION ALL

	/* additional records */
	SELECT snz_uid
		,snz_msd_uid
		,my_dates AS debt_as_at_date
		,NULL AS amount_incurred
		,NULL AS amount_repaid
		,NULL AS amount_written_off
		,NULL AS amount_incurred_assistance
		,NULL AS amount_incurred_overpayment
		,NULL AS amount_repaid_assistance
		,NULL AS amount_repaid_overpayment
		,0 AS delta
		,0 AS delta_assistance
		,0 AS delta_overpayment
		,ROUND(balance, 2) AS balance
		,ROUND(balance_assistance, 2) AS balance_assistance
		,ROUND(balance_overpayment, 2) AS balance_overpayment
	FROM joined
	WHERE NOT ( -- exclude small negative balances, the BETWEEN operator is inclusive
		balance BETWEEN -10 AND 2
		AND balance_assistance BETWEEN -10 AND 2
		AND balance_overpayment BETWEEN -10 AND 2
	)
) k

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_non_transactions] ([snz_uid]);
GO

/**************************************************************************************************
Views for balance labels
**************************************************************************************************/

IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_msd_labels_balance]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2gP2_msd_labels_balance];
GO

CREATE VIEW [DL-MAA2020-01].[d2gP2_msd_labels_balance] AS
SELECT snz_uid
	,debt_as_at_date
	,balance
	,balance_overpayment
	,balance_assistance
	/* balance labels */
	,CONCAT('msd_Y', YEAR(debt_as_at_date), 'M', MONTH(debt_as_at_date), '_', 'overpayment') AS balance_label_overpayment
	,CONCAT('msd_Y', YEAR(debt_as_at_date), 'M', MONTH(debt_as_at_date), '_', 'assistance') AS balance_label_assistance
	,CONCAT('msd_Y', YEAR(debt_as_at_date), 'M', MONTH(debt_as_at_date)) AS balance_label_all_types
FROM[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_non_transactions]
GO

/**************************************************************************************************
Views for transaction labels

Views for transaction labels contains two parts. Part1 (eg. [d2gP2_msd_labels_transactions_part1])
contains repayment & write off for subtype MSD debt. Part2 ([d2gP2_msd_labels_transactions_part2]) contains repayment and 
write off seperately for MSD debt.
**************************************************************************************************/

IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_msd_labels_transactions]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2gP2_msd_labels_transactions];
GO

CREATE VIEW [DL-MAA2020-01].[d2gP2_msd_labels_transactions] AS
SELECT snz_uid
	,snz_msd_uid
	,debt_as_at_date
	,amount_incurred
	,amount_repaid
	,amount_written_off
	,amount_incurred_assistance
	,amount_incurred_overpayment
	,amount_repaid_assistance
	,amount_repaid_overpayment
	/* incurred */
	,CONCAT('msd_', 'amount_incurred', '_', YEAR(debt_as_at_date), '_', 'overpayment') AS transaction_labels_incurred_overpayment
	,CONCAT('msd_', 'amount_incurred', '_', YEAR(debt_as_at_date), '_', 'assistance') AS transaction_labels_incurred_assistance
	,CONCAT('msd_', 'amount_incurred', '_', YEAR(debt_as_at_date)) AS transaction_labels_incurred_all_types
	/* repaid or write-off */
	,CONCAT('msd_', 'amount_repaid', '_', YEAR(debt_as_at_date), '_', 'overpayment') AS transaction_labels_repaid_writeoff_overpayment
	,CONCAT('msd_', 'amount_repaid', '_', YEAR(debt_as_at_date), '_', 'assistance') AS transaction_labels_repaid_writeoff_assistance
	,CONCAT('msd_', 'amount_repaid', '_', YEAR(debt_as_at_date)) AS transaction_labels_repaid_all_types
	,CONCAT('msd_', 'amount_writeoff', '_', YEAR(debt_as_at_date)) AS transaction_labels_writeoff_all_types
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_non_transactions]
GO

IF OBJECT_ID('[DL-MAA2020-01].[msd_labels_pre2019]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[msd_labels_pre2019];
GO                   

CREATE VIEW [DL-MAA2020-01].[msd_labels_pre2019] AS
SELECT snz_uid 
	  ,DATEADD(MONTH, 1, debt_as_at_date) AS debt_as_at_date
	  ,balance
	  ,balance_overpayment
	  ,balance_assistance
	  /*pre_2019*/
	  ,CONCAT('msd_', 'pre_2019', '_', 'overpayment') AS transaction_labels_pre_2019_overpayment
	  ,CONCAT('msd_', 'pre_2019', '_', 'assistance') AS transaction_labels_pre_2019_assistance
	  ,CONCAT('msd_', 'pre_2019') AS transaction_labels_pre_2019_all_types
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_non_transactions]
WHERE debt_as_at_date BETWEEN '2018-12-01' AND '2018-12-31'
GO

/**************************************************************************************************
Views for repayments

Views for repayments labels contains two parts. Part1 (eg. [d2gP2_msd_labels_repayments_part1])
contains repayment & write off for subtype MSD debt. Part2 ([d2gP2_msd_labels_repayments_part2]) contains 
repayment and write off seperately for MSD debt.
**************************************************************************************************/

IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_msd_labels_repayments]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2gP2_msd_labels_repayments];
GO

CREATE VIEW [DL-MAA2020-01].[d2gP2_msd_labels_repayments] AS
SELECT snz_uid
    ,snz_msd_uid
	,debt_as_at_date
	,amount_repaid
	,amount_repaid_assistance
	,amount_repaid_overpayment
	/* repayment labels by type */
	,IIF(debt_as_at_date BETWEEN '2020-07-01' AND '2020-09-30', CONCAT('msd_payment_03mth_', 'assistance'), NULL) AS payment_label_assistance_03
	,IIF(debt_as_at_date BETWEEN '2020-04-01' AND '2020-09-30', CONCAT('msd_payment_06mth_', 'assistance'), NULL) AS payment_label_assistance_06
	,IIF(debt_as_at_date BETWEEN '2020-01-01' AND '2020-09-30', CONCAT('msd_payment_09mth_', 'assistance'), NULL) AS payment_label_assistance_09
	,IIF(debt_as_at_date BETWEEN '2019-10-01' AND '2020-09-30', CONCAT('msd_payment_12mth_', 'assistance'), NULL) AS payment_label_assistance_12
	,IIF(debt_as_at_date BETWEEN '2020-07-01' AND '2020-09-30', CONCAT('msd_payment_03mth_', 'overpayment'), NULL) AS payment_label_overpayment_03
	,IIF(debt_as_at_date BETWEEN '2020-04-01' AND '2020-09-30', CONCAT('msd_payment_06mth_', 'overpayment'), NULL) AS payment_label_overpayment_06
	,IIF(debt_as_at_date BETWEEN '2020-01-01' AND '2020-09-30', CONCAT('msd_payment_09mth_', 'overpayment'), NULL) AS payment_label_overpayment_09
	,IIF(debt_as_at_date BETWEEN '2019-10-01' AND '2020-09-30', CONCAT('msd_payment_12mth_', 'overpayment'), NULL) AS payment_label_overpayment_12
	/* repayment labels all types */
	,IIF(debt_as_at_date BETWEEN '2020-07-01' AND '2020-09-30', 'msd_payment_03mth', NULL) AS payment_label_all_types_03
	,IIF(debt_as_at_date BETWEEN '2020-04-01' AND '2020-09-30', 'msd_payment_06mth', NULL) AS payment_label_all_types_06
	,IIF(debt_as_at_date BETWEEN '2020-01-01' AND '2020-09-30', 'msd_payment_09mth', NULL) AS payment_label_all_types_09
	,IIF(debt_as_at_date BETWEEN '2019-10-01' AND '2020-09-30', 'msd_payment_12mth', NULL) AS payment_label_all_types_12
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_non_transactions]
WHERE amount_repaid < -1
GO

/**************************************************************************************************
Views for persistence

To determine whether a person has persistent debt we count the number of distinct dates where
the label is non-null during assembly. After assembly, we create the indicator by checking
whether msd_persistence_XXmth = XX.
- If msd_persistence_XXmth = XX then in the last XX months there were XX months where the person
  had debt hence they had debt in every month.
- If msd_persistence_XXmth < XX then in the last XX months there were some months where the person
  did not have debt.
**************************************************************************************************/

IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_msd_labels_persist]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[msd_labels_persist];
GO

CREATE VIEW [DL-MAA2020-01].[d2gP2_msd_labels_persist] AS
SELECT snz_uid
	,snz_msd_uid
	,debt_as_at_date
	,balance
	,balance_overpayment
	,balance_assistance
	/* persistence labels assistance */
	,IIF(balance_assistance > 0 AND debt_as_at_date BETWEEN '2020-07-01' AND '2020-09-30', CONCAT('msd_persistence_03mth_', 'assistance'), NULL) AS persistence_label_assistance_03
	,IIF(balance_assistance > 0 AND debt_as_at_date BETWEEN '2020-04-01' AND '2020-09-30', CONCAT('msd_persistence_06mth_', 'assistance'), NULL) AS persistence_label_assistance_06
	,IIF(balance_assistance > 0 AND debt_as_at_date BETWEEN '2020-01-01' AND '2020-09-30', CONCAT('msd_persistence_09mth_', 'assistance'), NULL) AS persistence_label_assistance_09
	,IIF(balance_assistance > 0 AND debt_as_at_date BETWEEN '2019-10-01' AND '2020-09-30', CONCAT('msd_persistence_12mth_', 'assistance'), NULL) AS persistence_label_assistance_12
	,IIF(balance_assistance > 0 AND debt_as_at_date BETWEEN '2019-07-01' AND '2020-09-30', CONCAT('msd_persistence_15mth_', 'assistance'), NULL) AS persistence_label_assistance_15
	,IIF(balance_assistance > 0 AND debt_as_at_date BETWEEN '2019-04-01' AND '2020-09-30', CONCAT('msd_persistence_18mth_', 'assistance'), NULL) AS persistence_label_assistance_18
	,IIF(balance_assistance > 0 AND debt_as_at_date BETWEEN '2019-01-01' AND '2020-09-30', CONCAT('msd_persistence_21mth_', 'assistance'), NULL) AS persistence_label_assistance_21
	/* persistence labels overpayment */
	,IIF(balance_overpayment > 0 AND debt_as_at_date BETWEEN '2020-07-01' AND '2020-09-30', CONCAT('msd_persistence_03mth_', 'overpayment'), NULL) AS persistence_label_overpayment_03
	,IIF(balance_overpayment > 0 AND debt_as_at_date BETWEEN '2020-04-01' AND '2020-09-30', CONCAT('msd_persistence_06mth_', 'overpayment'), NULL) AS persistence_label_overpayment_06
	,IIF(balance_overpayment > 0 AND debt_as_at_date BETWEEN '2020-01-01' AND '2020-09-30', CONCAT('msd_persistence_09mth_', 'overpayment'), NULL) AS persistence_label_overpayment_09
	,IIF(balance_overpayment > 0 AND debt_as_at_date BETWEEN '2019-10-01' AND '2020-09-30', CONCAT('msd_persistence_12mth_', 'overpayment'), NULL) AS persistence_label_overpayment_12
	,IIF(balance_overpayment > 0 AND debt_as_at_date BETWEEN '2019-07-01' AND '2020-09-30', CONCAT('msd_persistence_15mth_', 'overpayment'), NULL) AS persistence_label_overpayment_15
	,IIF(balance_overpayment > 0 AND debt_as_at_date BETWEEN '2019-04-01' AND '2020-09-30', CONCAT('msd_persistence_18mth_', 'overpayment'), NULL) AS persistence_label_overpayment_18
	,IIF(balance_overpayment > 0 AND debt_as_at_date BETWEEN '2019-01-01' AND '2020-09-30', CONCAT('msd_persistence_21mth_', 'overpayment'), NULL) AS persistence_label_overpayment_21
	/* persistence labels all types */
	,IIF(balance > 0 AND debt_as_at_date BETWEEN '2020-07-01' AND '2020-09-30', 'msd_persistence_03mth', NULL) AS persistence_label_all_types_03
	,IIF(balance > 0 AND debt_as_at_date BETWEEN '2020-04-01' AND '2020-09-30', 'msd_persistence_06mth', NULL) AS persistence_label_all_types_06
	,IIF(balance > 0 AND debt_as_at_date BETWEEN '2020-01-01' AND '2020-09-30', 'msd_persistence_09mth', NULL) AS persistence_label_all_types_09
	,IIF(balance > 0 AND debt_as_at_date BETWEEN '2019-10-01' AND '2020-09-30', 'msd_persistence_12mth', NULL) AS persistence_label_all_types_12
	,IIF(balance > 0 AND debt_as_at_date BETWEEN '2019-07-01' AND '2020-09-30', 'msd_persistence_15mth', NULL) AS persistence_label_all_types_15
	,IIF(balance > 0 AND debt_as_at_date BETWEEN '2019-04-01' AND '2020-09-30', 'msd_persistence_18mth', NULL) AS persistence_label_all_types_18
	,IIF(balance > 0 AND debt_as_at_date BETWEEN '2019-01-01' AND '2020-09-30', 'msd_persistence_21mth', NULL) AS persistence_label_all_types_21
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_non_transactions]
GO

/**************************************************************************************************
remove temporary tables
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_signs_handled]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_signs_handled];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_classified_msd_repayment]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_classified_msd_repayment];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt_and_repayment]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_classified_msd_debt_and_repayment];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_prep]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_msd_debt_prep];
GO
