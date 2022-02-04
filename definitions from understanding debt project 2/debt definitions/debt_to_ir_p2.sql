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
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_cases]
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_type_monthly]
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_tot_monthly]

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

Issues:
1. It seems that [running_balance_case] from table [ir_debt_transactions] is not correctly calculated, it doesn't sum up the
   running balance across the different tax type group whith in a debt case. 


History (reverse order):
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
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[tmp_ir_debt_transactions] ([snz_ird_uid], [snz_case_number], [tax_type_group]);
GO


IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected];
GO


SELECT *
       ,IIF([month_end] = [min_date], [running_balance_tax_type_num], [delta]) as [delta_updated]
	   ,IIF([account_maintenance] > 0, [account_maintenance], 0) AS [maintenance_pos]
	   ,IIF([account_maintenance] < 0, [account_maintenance], 0) AS [maintenance_neg]
	   ,IIF([month_end] = [min_date] AND [month_end] <= '2020-09-30' AND [running_balance_tax_type_num] <> [delta], [running_balance_tax_type_num] - [delta], 0) as [pre_2019]
 --around 300 identities' first records in the debt table is after 2020-09-30, however, they have balance before 2019,without consider these records will keep the debt balance consistent with the sum of component
 --If tax case started earlier than 2019 and unclosed until 2019-01-31, then set [running_balance_tax_type_num]  + [delta] as delta_updated at the first date of the record
INTO [IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected]
FROM(
SELECT *
	,CAST(REPLACE(REPLACE([running_balance_tax_type],'$',''), ',' , '') AS NUMERIC(10,2)) AS [running_balance_tax_type_num]
	,CAST(REPLACE(REPLACE([running_balance_case],'$',''), ',' , '') AS NUMERIC(10,2)) AS [running_balance_case_num]
	,MIN([month_end]) OVER(PARTITION BY [snz_ird_uid], [snz_case_number], [tax_type_group] ORDER BY [month_end]) AS [min_date]
FROM [IDI_Sandpit].[DL-MAA2020-01].[tmp_ir_debt_transactions]
)k1

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected] ([snz_ird_uid],[tax_type_group]);
GO


/**************************************************************************************************
2019 & 2020 total outstanding debt at the end of each month AND 2020 principle & repayments 
**************************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_ird_balances_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_ird_balances_by_month]; 
GO

SELECT snz_ird_uid
	,tax_type_group
	/*monthly set up*/
	,SUM(IIF( month_end <= '2019-01-31', delta_updated, 0)) AS Y2019Jan
	,SUM(IIF( month_end <= '2019-02-28', delta_updated, 0)) AS Y2019Feb
	,SUM(IIF( month_end <= '2019-03-31', delta_updated, 0)) AS Y2019Mar
	,SUM(IIF( month_end <= '2019-04-30', delta_updated, 0)) AS Y2019Apr
	,SUM(IIF( month_end <= '2019-05-31', delta_updated, 0)) AS Y2019May
	,SUM(IIF( month_end <= '2019-06-30', delta_updated, 0)) AS Y2019Jun
	,SUM(IIF( month_end <= '2019-07-31', delta_updated, 0)) AS Y2019Jul
	,SUM(IIF( month_end <= '2019-08-31', delta_updated, 0)) AS Y2019Aug
	,SUM(IIF( month_end <= '2019-09-30', delta_updated, 0)) AS Y2019Sep
	,SUM(IIF( month_end <= '2019-10-31', delta_updated, 0)) AS Y2019Oct
	,SUM(IIF( month_end <= '2019-11-30', delta_updated, 0)) AS Y2019Nov
	,SUM(IIF( month_end <= '2019-12-31', delta_updated, 0)) AS Y2019Dec
	,SUM(IIF( month_end <= '2020-01-31', delta_updated, 0)) AS Y2020Jan
	,SUM(IIF( month_end <= '2020-02-29', delta_updated, 0)) AS Y2020Feb
	,SUM(IIF( month_end <= '2020-03-31', delta_updated, 0)) AS Y2020Mar
	,SUM(IIF( month_end <= '2020-04-30', delta_updated, 0)) AS Y2020Apr
	,SUM(IIF( month_end <= '2020-05-31', delta_updated, 0)) AS Y2020May
	,SUM(IIF( month_end <= '2020-06-30', delta_updated, 0)) AS Y2020Jun
	,SUM(IIF( month_end <= '2020-07-31', delta_updated, 0)) AS Y2020Jul
	,SUM(IIF( month_end <= '2020-08-31', delta_updated, 0)) AS Y2020Aug
	,SUM(IIF( month_end <= '2020-09-30', delta_updated, 0)) AS Y2020Sep
	,SUM(IIF( month_end <= '2020-10-31', delta_updated, 0)) AS Y2020Oct
	,SUM(IIF( month_end <= '2020-11-30', delta_updated, 0)) AS Y2020Nov

	/* debt components for 2019 and 2020*/
	,ROUND(SUM(pre_2019), 2) AS type_pre_2019
	,ROUND(SUM(for_2019_principle), 2) AS type_principle_2019
	,ROUND(SUM(for_2019_penalty), 2) AS type_penalty_2019
	,ROUND(SUM(for_2019_interest), 2) AS type_interest_2019
	,ROUND(SUM(for_2019_maintenance_pos), 2) AS type_maintenance_pos_2019
	,ROUND(SUM(for_2019_payment), 2) AS type_payment_2019
	,ROUND(SUM(for_2019_remission), 2) AS type_remission_2019
	,ROUND(SUM(for_2019_maintenance_neg), 2) AS type_maintenance_neg_2019
	,ROUND(SUM(for_2020_principle), 2) AS type_principle_2020
	,ROUND(SUM(for_2020_penalty), 2) AS type_penalty_2020
	,ROUND(SUM(for_2020_interest), 2) AS type_interest_2020
	,ROUND(SUM(for_2020_maintenance_pos), 2) AS type_maintenance_pos_2020
	,ROUND(SUM(for_2020_payment), 2) AS type_payment_2020
	,ROUND(SUM(for_2020_remission), 2) AS type_remission_2020
	,ROUND(SUM(for_2020_maintenance_neg), 2) AS type_maintenance_neg_2020

	/*repayment indicator*/
	,IIF(SUM(for_payment_3mth) >= 1, 1, 0) AS ind_payment_3mth
	,IIF(SUM(for_payment_6mth) >= 1, 1, 0) AS ind_payment_6mth
	,IIF(SUM(for_payment_9mth) >= 1, 1, 0) AS ind_payment_9mth
	,IIF(SUM(for_payment_12mth) >= 1, 1, 0) AS ind_payment_12mth
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_ird_balances_by_month]
FROM(
SELECT snz_ird_uid
	  ,tax_type_group
	  ,month_end
	  ,delta_updated
	  ,[pre_2019]
	  ,running_balance_tax_type_num 
	/* debt components for 2019 and 2020*/
	,IIF(YEAR(month_end) = 2019, COALESCE(assess, 0), 0) AS for_2019_principle
	,IIF(YEAR(month_end) = 2019, COALESCE(penalty, 0), 0) AS for_2019_penalty
	,IIF(YEAR(month_end) = 2019, COALESCE(interest, 0), 0) AS for_2019_interest
	,IIF(YEAR(month_end) = 2019, COALESCE(maintenance_pos, 0), 0) AS for_2019_maintenance_pos
	,IIF(YEAR(month_end) = 2019, - COALESCE(payment, 0), 0) AS for_2019_payment
	,IIF(YEAR(month_end) = 2019, - COALESCE(remiss, 0), 0) AS for_2019_remission
	,IIF(YEAR(month_end) = 2019, - COALESCE(maintenance_neg, 0), 0) AS for_2019_maintenance_neg
	,IIF(YEAR(month_end) = 2020 AND month_end <= '2020-09-30', COALESCE(assess, 0), 0) AS for_2020_principle
	,IIF(YEAR(month_end) = 2020 AND month_end <= '2020-09-30', COALESCE(penalty, 0), 0) AS for_2020_penalty
	,IIF(YEAR(month_end) = 2020 AND month_end <= '2020-09-30', COALESCE(interest, 0), 0) AS for_2020_interest
	,IIF(YEAR(month_end) = 2020 AND month_end <= '2020-09-30', COALESCE(maintenance_pos, 0), 0) AS for_2020_maintenance_pos
	,IIF(YEAR(month_end) = 2020 AND month_end <= '2020-09-30', - COALESCE(payment, 0), 0) AS for_2020_payment
	,IIF(YEAR(month_end) = 2020 AND month_end <= '2020-09-30', - COALESCE(remiss, 0), 0) AS for_2020_remission
	,IIF(YEAR(month_end) = 2020 AND month_end <= '2020-09-30', - COALESCE(maintenance_neg, 0), 0) AS for_2020_maintenance_neg

	/*repayment plan*/
	,IIF('2020-07-31' <= month_end AND month_end <= '2020-09-30' AND payment < -1, 1, 0) AS for_payment_3mth
	,IIF('2020-04-30' <= month_end AND month_end <= '2020-09-30' AND payment < -1, 1, 0) AS for_payment_6mth
	,IIF('2020-01-31' <= month_end AND month_end <= '2020-09-30' AND payment < -1, 1, 0) AS for_payment_9mth
	,IIF('2019-10-31' <= month_end AND month_end <= '2020-09-30' AND payment < -1, 1, 0) AS for_payment_12mth

FROM [IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected]


) a
GROUP BY snz_ird_uid, tax_type_group

/* Add index */                        
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_ird_balances_by_month] (snz_ird_uid);
GO


/**************************************************************************************************
join on snz_uid
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_by_month];
GO

SELECT b.snz_uid
	  ,a.*
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_by_month]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_ird_balances_by_month] a
LEFT JOIN [IDI_Clean_20201020].[security].[concordance] b
ON a.snz_ird_uid = b.snz_ird_uid
/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_by_month] (snz_uid);
GO


/**************************************************************************************************
table for each debt type (monthly debt)
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ird_debt_type_monthly]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ird_debt_type_monthly];
GO

SELECT *
	,IIF(tax_type_group = 'Donation Tax Credits', Y2019Jan, 0) AS Y2019Jan_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2019Feb, 0) AS Y2019Feb_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2019Mar, 0) AS Y2019Mar_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2019Apr, 0) AS Y2019Apr_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2019MAy, 0) AS Y2019May_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2019Jun, 0) AS Y2019Jun_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2019Jul, 0) AS Y2019Jul_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2019Aug, 0) AS Y2019Aug_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2019Sep, 0) AS Y2019Sep_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2019Oct, 0) AS Y2019Oct_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2019Nov, 0) AS Y2019Nov_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2019Dec, 0) AS Y2019Dec_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2020Jan, 0) AS Y2020Jan_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2020Feb, 0) AS Y2020Feb_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2020Mar, 0) AS Y2020Mar_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2020Apr, 0) AS Y2020Apr_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2020MAy, 0) AS Y2020May_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2020Jun, 0) AS Y2020Jun_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2020Jul, 0) AS Y2020Jul_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2020Aug, 0) AS Y2020Aug_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2020Sep, 0) AS Y2020Sep_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2020Oct, 0) AS Y2020Oct_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', Y2020Nov, 0) AS Y2020Nov_Donation_Tax_Credits
	/* debt components for 2019 and 2020*/
	,IIF(tax_type_group = 'Donation Tax Credits', type_pre_2019, 0) AS pre_2019_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_principle_2019, 0) AS principle_2019_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_penalty_2019, 0) AS penalty_2019_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_interest_2019, 0) AS interest_2019_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_maintenance_pos_2019, 0) AS maintenance_pos_2019_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_payment_2019, 0) AS payment_2019_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_remission_2019, 0) AS remission_2019_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_maintenance_neg_2019, 0) AS maintenance_neg_2019_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_principle_2020, 0) AS principle_2020_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_penalty_2020, 0) AS penalty_2020_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_interest_2020, 0) AS interest_2020_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_maintenance_pos_2020, 0) AS maintenance_pos_2020_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_payment_2020, 0) AS payment_2020_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_remission_2020, 0) AS remission_2020_Donation_Tax_Credits
	,IIF(tax_type_group = 'Donation Tax Credits', type_maintenance_neg_2020, 0) AS maintenance_neg_2020_Donation_Tax_Credits
	/*repayment indicator*/
	,IIF(tax_type_group = 'Donation Tax Credict' AND ind_payment_3mth = 1, 1, 0) AS ind_payment_3mth_DTC
	,IIF(tax_type_group = 'Donation Tax Credits' AND ind_payment_6mth = 1, 1, 0) AS ind_payment_6mth_DTC
	,IIF(tax_type_group = 'Donation Tax Credits' AND ind_payment_9mth = 1, 1, 0) AS ind_payment_9mth_DTC
	,IIF(tax_type_group = 'Donation Tax Credits' AND ind_payment_12mth = 1, 1, 0) AS ind_payment_12mth_DTC

	,IIF(tax_type_group = 'Employment Activities', Y2019Jan, 0) AS Y2019Jan_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2019Feb, 0) AS Y2019Feb_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2019Mar, 0) AS Y2019Mar_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2019Apr, 0) AS Y2019Apr_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2019May, 0) AS Y2019May_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2019Jun, 0) AS Y2019Jun_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2019Jul, 0) AS Y2019Jul_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2019Aug, 0) AS Y2019Aug_Employment_Activities	
	,IIF(tax_type_group = 'Employment Activities', Y2019Sep, 0) AS Y2019Sep_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2019Oct, 0) AS Y2019Oct_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2019Nov, 0) AS Y2019Nov_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2019Dec, 0) AS Y2019Dec_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2020Jan, 0) AS Y2020Jan_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2020Feb, 0) AS Y2020Feb_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2020Mar, 0) AS Y2020Mar_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2020Apr, 0) AS Y2020Apr_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2020May, 0) AS Y2020May_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2020Jun, 0) AS Y2020Jun_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2020Jul, 0) AS Y2020Jul_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2020Aug, 0) AS Y2020Aug_Employment_Activities	
	,IIF(tax_type_group = 'Employment Activities', Y2020Sep, 0) AS Y2020Sep_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2020Oct, 0) AS Y2020Oct_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', Y2020Nov, 0) AS Y2020Nov_Employment_Activities
    /* debt components for 2019 and 2020*/
	,IIF(tax_type_group = 'Employment Activities', type_pre_2019, 0) AS pre_2019_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_principle_2019, 0) AS principle_2019_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_penalty_2019, 0) AS penalty_2019_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_interest_2019, 0) AS interest_2019_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_maintenance_pos_2019, 0) AS maintenance_pos_2019_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_payment_2019, 0) AS payment_2019_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_remission_2019, 0) AS remission_2019_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_maintenance_neg_2019, 0) AS maintenance_neg_2019_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_principle_2020, 0) AS principle_2020_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_penalty_2020, 0) AS penalty_2020_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_interest_2020, 0) AS interest_2020_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_maintenance_pos_2020, 0) AS maintenance_pos_2020_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_payment_2020, 0) AS payment_2020_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_remission_2020, 0) AS remission_2020_Employment_Activities
	,IIF(tax_type_group = 'Employment Activities', type_maintenance_neg_2020, 0) AS maintenance_neg_2020_Employment_Activities
	/*repayment indicator*/
	,IIF(tax_type_group = 'Employment Activities' AND ind_payment_3mth = 1, 1, 0) AS ind_payment_3mth_EA
	,IIF(tax_type_group = 'Employment Activities' AND ind_payment_6mth = 1, 1, 0) AS ind_payment_6mth_EA
	,IIF(tax_type_group = 'Employment Activities' AND ind_payment_9mth = 1, 1, 0) AS ind_payment_9mth_EA
	,IIF(tax_type_group = 'Employment Activities' AND ind_payment_12mth = 1, 1, 0) AS ind_payment_12mth_EA


	,IIF(tax_type_group = 'Families', Y2019Jan, 0) AS Y2019Jan_Families
	,IIF(tax_type_group = 'Families', Y2019Feb, 0) AS Y2019Feb_Families
	,IIF(tax_type_group = 'Families', Y2019Mar, 0) AS Y2019Mar_Families
	,IIF(tax_type_group = 'Families', Y2019Apr, 0) AS Y2019Apr_Families
	,IIF(tax_type_group = 'Families', Y2019May, 0) AS Y2019May_Families
	,IIF(tax_type_group = 'Families', Y2019Jun, 0) AS Y2019Jun_Families
	,IIF(tax_type_group = 'Families', Y2019Jul, 0) AS Y2019Jul_Families
	,IIF(tax_type_group = 'Families', Y2019Aug, 0) AS Y2019Aug_Families
	,IIF(tax_type_group = 'Families', Y2019Sep, 0) AS Y2019Sep_Families
	,IIF(tax_type_group = 'Families', Y2019Oct, 0) AS Y2019Oct_Families
	,IIF(tax_type_group = 'Families', Y2019Nov, 0) AS Y2019Nov_Families
	,IIF(tax_type_group = 'Families', Y2019Dec, 0) AS Y2019Dec_Families
	,IIF(tax_type_group = 'Families', Y2020Jan, 0) AS Y2020Jan_Families
	,IIF(tax_type_group = 'Families', Y2020Feb, 0) AS Y2020Feb_Families
	,IIF(tax_type_group = 'Families', Y2020Mar, 0) AS Y2020Mar_Families
	,IIF(tax_type_group = 'Families', Y2020Apr, 0) AS Y2020Apr_Families
	,IIF(tax_type_group = 'Families', Y2020May, 0) AS Y2020May_Families
	,IIF(tax_type_group = 'Families', Y2020Jun, 0) AS Y2020Jun_Families
	,IIF(tax_type_group = 'Families', Y2020Jul, 0) AS Y2020Jul_Families
	,IIF(tax_type_group = 'Families', Y2020Aug, 0) AS Y2020Aug_Families
	,IIF(tax_type_group = 'Families', Y2020Sep, 0) AS Y2020Sep_Families
	,IIF(tax_type_group = 'Families', Y2020Oct, 0) AS Y2020Oct_Families
	,IIF(tax_type_group = 'Families', Y2020Nov, 0) AS Y2020Nov_Families
    /* debt components for 2019 and 2020*/
	,IIF(tax_type_group = 'Families', type_pre_2019, 0) AS pre_2019_Families
	,IIF(tax_type_group = 'Families', type_principle_2019, 0) AS principle_2019_Families
	,IIF(tax_type_group = 'Families', type_penalty_2019, 0) AS penalty_2019_Families
	,IIF(tax_type_group = 'Families', type_interest_2019, 0) AS interest_2019_Families
	,IIF(tax_type_group = 'Families', type_maintenance_pos_2019, 0) AS maintenance_pos_2019_Families
	,IIF(tax_type_group = 'Families', type_payment_2019, 0) AS payment_2019_Families
	,IIF(tax_type_group = 'Families', type_remission_2019, 0) AS remission_2019_Families
	,IIF(tax_type_group = 'Families', type_maintenance_neg_2019, 0) AS maintenance_neg_2019_Families
	,IIF(tax_type_group = 'Families', type_principle_2020, 0) AS principle_2020_Families
	,IIF(tax_type_group = 'Families', type_penalty_2020, 0) AS penalty_2020_Families
	,IIF(tax_type_group = 'Families', type_interest_2020, 0) AS interest_2020_Families
	,IIF(tax_type_group = 'Families', type_maintenance_pos_2020, 0) AS maintenance_pos_2020_Families
	,IIF(tax_type_group = 'Families', type_payment_2020, 0) AS payment_2020_Families
	,IIF(tax_type_group = 'Families', type_remission_2020, 0) AS remission_2020_Families
	,IIF(tax_type_group = 'Families', type_maintenance_neg_2020, 0) AS maintenance_neg_2020_Families
	/*repayment indicator*/
	,IIF(tax_type_group = 'Families' AND ind_payment_3mth = 1, 1, 0) AS ind_payment_3mth_F
	,IIF(tax_type_group = 'Families' AND ind_payment_6mth = 1, 1, 0) AS ind_payment_6mth_F
	,IIF(tax_type_group = 'Families' AND ind_payment_9mth = 1, 1, 0) AS ind_payment_9mth_F
	,IIF(tax_type_group = 'Families' AND ind_payment_12mth = 1, 1, 0) AS ind_payment_12mth_F



	,IIF(tax_type_group = 'GST', Y2019Jan, 0) AS Y2019Jan_GST
	,IIF(tax_type_group = 'GST', Y2019Feb, 0) AS Y2019Feb_GST
	,IIF(tax_type_group = 'GST', Y2019Mar, 0) AS Y2019Mar_GST
	,IIF(tax_type_group = 'GST', Y2019Apr, 0) AS Y2019Apr_GST
	,IIF(tax_type_group = 'GST', Y2019May, 0) AS Y2019May_GST
	,IIF(tax_type_group = 'GST', Y2019Jun, 0) AS Y2019Jun_GST
	,IIF(tax_type_group = 'GST', Y2019Jul, 0) AS Y2019Jul_GST
	,IIF(tax_type_group = 'GST', Y2019Aug, 0) AS Y2019Aug_GST
	,IIF(tax_type_group = 'GST', Y2019Sep, 0) AS Y2019Sep_GST
	,IIF(tax_type_group = 'GST', Y2019Oct, 0) AS Y2019Oct_GST
	,IIF(tax_type_group = 'GST', Y2019Nov, 0) AS Y2019Nov_GST
	,IIF(tax_type_group = 'GST', Y2019Dec, 0) AS Y2019Dec_GST
	,IIF(tax_type_group = 'GST', Y2020Jan, 0) AS Y2020Jan_GST
	,IIF(tax_type_group = 'GST', Y2020Feb, 0) AS Y2020Feb_GST
	,IIF(tax_type_group = 'GST', Y2020Mar, 0) AS Y2020Mar_GST
	,IIF(tax_type_group = 'GST', Y2020Apr, 0) AS Y2020Apr_GST
	,IIF(tax_type_group = 'GST', Y2020May, 0) AS Y2020May_GST
	,IIF(tax_type_group = 'GST', Y2020Jun, 0) AS Y2020Jun_GST
	,IIF(tax_type_group = 'GST', Y2020Jul, 0) AS Y2020Jul_GST
	,IIF(tax_type_group = 'GST', Y2020Aug, 0) AS Y2020Aug_GST
	,IIF(tax_type_group = 'GST', Y2020Sep, 0) AS Y2020Sep_GST
	,IIF(tax_type_group = 'GST', Y2020Oct, 0) AS Y2020Oct_GST
	,IIF(tax_type_group = 'GST', Y2020Nov, 0) AS Y2020Nov_GST
	/* debt components for 2019 and 2020*/
	,IIF(tax_type_group = 'GST', type_pre_2019, 0) AS pre_2019_GST
	,IIF(tax_type_group = 'GST', type_principle_2019, 0) AS principle_2019_GST
	,IIF(tax_type_group = 'GST', type_penalty_2019, 0) AS penalty_2019_GST
	,IIF(tax_type_group = 'GST', type_interest_2019, 0) AS interest_2019_GST
	,IIF(tax_type_group = 'GST', type_maintenance_pos_2019, 0) AS maintenance_pos_2019_GST
	,IIF(tax_type_group = 'GST', type_payment_2019, 0) AS payment_2019_GST
	,IIF(tax_type_group = 'GST', type_remission_2019, 0) AS remission_2019_GST
	,IIF(tax_type_group = 'GST', type_maintenance_neg_2019, 0) AS maintenance_neg_2019_GST
	,IIF(tax_type_group = 'GST', type_principle_2020, 0) AS principle_2020_GST
	,IIF(tax_type_group = 'GST', type_penalty_2020, 0) AS penalty_2020_GST
	,IIF(tax_type_group = 'GST', type_interest_2020, 0) AS interest_2020_GST
	,IIF(tax_type_group = 'GST', type_maintenance_pos_2020, 0) AS maintenance_pos_2020_GST
	,IIF(tax_type_group = 'GST', type_payment_2020, 0) AS payment_2020_GST
	,IIF(tax_type_group = 'GST', type_remission_2020, 0) AS remission_2020_GST
	,IIF(tax_type_group = 'GST', type_maintenance_neg_2020, 0) AS maintenance_neg_2020_GST
	/*repayment indicator*/
	,IIF(tax_type_group = 'GST' AND ind_payment_3mth = 1, 1, 0) AS ind_payment_3mth_GST
	,IIF(tax_type_group = 'GST' AND ind_payment_6mth = 1, 1, 0) AS ind_payment_6mth_GST
	,IIF(tax_type_group = 'GST' AND ind_payment_9mth = 1, 1, 0) AS ind_payment_9mth_GST
	,IIF(tax_type_group = 'GST' AND ind_payment_12mth = 1, 1, 0) AS ind_payment_12mth_GST

	,IIF(tax_type_group = 'Income Tax', Y2019Jan, 0) AS Y2019Jan_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2019Feb, 0) AS Y2019Feb_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2019Mar, 0) AS Y2019Mar_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2019Apr, 0) AS Y2019Apr_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2019May, 0) AS Y2019May_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2019Jun, 0) AS Y2019Jun_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2019Jul, 0) AS Y2019Jul_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2019Aug, 0) AS Y2019Aug_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2019Sep, 0) AS Y2019Sep_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2019Oct, 0) AS Y2019Oct_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2019Nov, 0) AS Y2019Nov_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2019Dec, 0) AS Y2019Dec_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2020Jan, 0) AS Y2020Jan_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2020Feb, 0) AS Y2020Feb_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2020Mar, 0) AS Y2020Mar_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2020Apr, 0) AS Y2020Apr_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2020May, 0) AS Y2020May_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2020Jun, 0) AS Y2020Jun_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2020Jul, 0) AS Y2020Jul_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2020Aug, 0) AS Y2020Aug_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2020Sep, 0) AS Y2020Sep_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2020Oct, 0) AS Y2020Oct_Income_Tax
	,IIF(tax_type_group = 'Income Tax', Y2020Nov, 0) AS Y2020Nov_Income_Tax
	/* debt components for 2019 and 2020*/
	,IIF(tax_type_group = 'Income Tax', type_pre_2019, 0) AS pre_2019_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_principle_2019, 0) AS principle_2019_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_penalty_2019, 0) AS penalty_2019_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_interest_2019, 0) AS interest_2019_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_maintenance_pos_2019, 0) AS maintenance_pos_2019_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_payment_2019, 0) AS payment_2019_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_remission_2019, 0) AS remission_2019_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_maintenance_neg_2019, 0) AS maintenance_neg_2019_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_principle_2020, 0) AS principle_2020_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_penalty_2020, 0) AS penalty_2020_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_interest_2020, 0) AS interest_2020_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_maintenance_pos_2020, 0) AS maintenance_pos_2020_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_payment_2020, 0) AS payment_2020_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_remission_2020, 0) AS remission_2020_Income_Tax
	,IIF(tax_type_group = 'Income Tax', type_maintenance_neg_2020, 0) AS maintenance_neg_2020_Income_Tax
	/*repayment indicator*/
	,IIF(tax_type_group = 'Income Tax' AND ind_payment_3mth = 1, 1, 0) AS ind_payment_3mth_IT
	,IIF(tax_type_group = 'Income Tax' AND ind_payment_6mth = 1, 1, 0) AS ind_payment_6mth_IT
	,IIF(tax_type_group = 'Income Tax' AND ind_payment_9mth = 1, 1, 0) AS ind_payment_9mth_IT
	,IIF(tax_type_group = 'Income Tax' AND ind_payment_12mth = 1, 1, 0) AS ind_payment_12mth_IT
	
	,IIF(tax_type_group = 'Liable Parent', Y2019Jan, 0) AS Y2019Jan_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2019Feb, 0) AS Y2019Feb_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2019MAr, 0) AS Y2019Mar_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2019Apr, 0) AS Y2019Apr_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2019May, 0) AS Y2019May_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2019Jun, 0) AS Y2019Jun_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2019Jul, 0) AS Y2019Jul_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2019Aug, 0) AS Y2019Aug_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2019Sep, 0) AS Y2019Sep_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2019Oct, 0) AS Y2019Oct_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2019Nov, 0) AS Y2019Nov_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2019Dec, 0) AS Y2019Dec_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2020Jan, 0) AS Y2020Jan_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2020Feb, 0) AS Y2020Feb_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2020MAr, 0) AS Y2020Mar_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2020Apr, 0) AS Y2020Apr_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2020May, 0) AS Y2020May_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2020Jun, 0) AS Y2020Jun_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2020Jul, 0) AS Y2020Jul_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2020Aug, 0) AS Y2020Aug_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2020Sep, 0) AS Y2020Sep_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2020Oct, 0) AS Y2020Oct_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', Y2020Nov, 0) AS Y2020Nov_Liable_Parent
	/* debt components for 2019 and 2020*/
	,IIF(tax_type_group = 'Liable Parent', type_pre_2019, 0) AS pre_2019_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_principle_2019, 0) AS principle_2019_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_penalty_2019, 0) AS penalty_2019_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_interest_2019, 0) AS interest_2019_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_maintenance_pos_2019, 0) AS maintenance_pos_2019_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_payment_2019, 0) AS payment_2019_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_remission_2019, 0) AS remission_2019_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_maintenance_neg_2019, 0) AS maintenance_neg_2019_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_principle_2020, 0) AS principle_2020_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_penalty_2020, 0) AS penalty_2020_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_interest_2020, 0) AS interest_2020_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_maintenance_pos_2020, 0) AS maintenance_pos_2020_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_payment_2020, 0) AS payment_2020_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_remission_2020, 0) AS remission_2020_Liable_Parent
	,IIF(tax_type_group = 'Liable Parent', type_maintenance_neg_2020, 0) AS maintenance_neg_2020_Liable_Parent
	/*repayment indicator*/
	,IIF(tax_type_group = 'Liable Parent' AND ind_payment_3mth = 1, 1, 0) AS ind_payment_3mth_LP
	,IIF(tax_type_group = 'Liable Parent' AND ind_payment_6mth = 1, 1, 0) AS ind_payment_6mth_LP
	,IIF(tax_type_group = 'Liable Parent' AND ind_payment_9mth = 1, 1, 0) AS ind_payment_9mth_LP
	,IIF(tax_type_group = 'Liable Parent' AND ind_payment_12mth = 1, 1, 0) AS ind_payment_12mth_LP


	,IIF(tax_type_group = 'Other', Y2019Jan, 0) AS Y2019Jan_Other
	,IIF(tax_type_group = 'Other', Y2019Feb, 0) AS Y2019Feb_Other
	,IIF(tax_type_group = 'Other', Y2019Mar, 0) AS Y2019Mar_Other
	,IIF(tax_type_group = 'Other', Y2019Apr, 0) AS Y2019Apr_Other
	,IIF(tax_type_group = 'Other', Y2019May, 0) AS Y2019May_Other
	,IIF(tax_type_group = 'Other', Y2019Jun, 0) AS Y2019Jun_Other
	,IIF(tax_type_group = 'Other', Y2019Jul, 0) AS Y2019Jul_Other
	,IIF(tax_type_group = 'Other', Y2019Aug, 0) AS Y2019Aug_Other
	,IIF(tax_type_group = 'Other', Y2019Sep, 0) AS Y2019Sep_Other
	,IIF(tax_type_group = 'Other', Y2019Oct, 0) AS Y2019Oct_Other
	,IIF(tax_type_group = 'Other', Y2019Nov, 0) AS Y2019Nov_Other
	,IIF(tax_type_group = 'Other', Y2019Dec, 0) AS Y2019Dec_Other
	,IIF(tax_type_group = 'Other', Y2020Jan, 0) AS Y2020Jan_Other
	,IIF(tax_type_group = 'Other', Y2020Feb, 0) AS Y2020Feb_Other
	,IIF(tax_type_group = 'Other', Y2020Mar, 0) AS Y2020Mar_Other
	,IIF(tax_type_group = 'Other', Y2020Apr, 0) AS Y2020Apr_Other
	,IIF(tax_type_group = 'Other', Y2020May, 0) AS Y2020May_Other
	,IIF(tax_type_group = 'Other', Y2020Jun, 0) AS Y2020Jun_Other
	,IIF(tax_type_group = 'Other', Y2020Jul, 0) AS Y2020Jul_Other
	,IIF(tax_type_group = 'Other', Y2020Aug, 0) AS Y2020Aug_Other
	,IIF(tax_type_group = 'Other', Y2020Sep, 0) AS Y2020Sep_Other
	,IIF(tax_type_group = 'Other', Y2020Oct, 0) AS Y2020Oct_Other
	,IIF(tax_type_group = 'Other', Y2020Nov, 0) AS Y2020Nov_Other
	/* debt components for 2019 and 2020*/
	,IIF(tax_type_group = 'Other', type_pre_2019, 0) AS pre_2019_Other
	,IIF(tax_type_group = 'Other', type_principle_2019, 0) AS principle_2019_Other
	,IIF(tax_type_group = 'Other', type_penalty_2019, 0) AS penalty_2019_Other
	,IIF(tax_type_group = 'Other', type_interest_2019, 0) AS interest_2019_Other
	,IIF(tax_type_group = 'Other', type_maintenance_pos_2019, 0) AS maintenance_pos_2019_Other
	,IIF(tax_type_group = 'Other', type_payment_2019, 0) AS payment_2019_Other
	,IIF(tax_type_group = 'Other', type_remission_2019, 0) AS remission_2019_Other
	,IIF(tax_type_group = 'Other', type_maintenance_neg_2019, 0) AS maintenance_neg_2019_Other
	,IIF(tax_type_group = 'Other', type_principle_2020, 0) AS principle_2020_Other
	,IIF(tax_type_group = 'Other', type_penalty_2020, 0) AS penalty_2020_Other
	,IIF(tax_type_group = 'Other', type_interest_2020, 0) AS interest_2020_Other
	,IIF(tax_type_group = 'Other', type_maintenance_pos_2020, 0) AS maintenance_pos_2020_Other
	,IIF(tax_type_group = 'Other', type_payment_2020, 0) AS payment_2020_Other
	,IIF(tax_type_group = 'Other', type_remission_2020, 0) AS remission_2020_Other
	,IIF(tax_type_group = 'Other', type_maintenance_neg_2020, 0) AS maintenance_neg_2020_Other
	/*repayment indicator*/
	,IIF(tax_type_group = 'Other' AND ind_payment_3mth = 1, 1, 0) AS ind_payment_3mth_O
	,IIF(tax_type_group = 'Other' AND ind_payment_6mth = 1, 1, 0) AS ind_payment_6mth_O
	,IIF(tax_type_group = 'Other' AND ind_payment_9mth = 1, 1, 0) AS ind_payment_9mth_O
	,IIF(tax_type_group = 'Other' AND ind_payment_12mth = 1, 1, 0) AS ind_payment_12mth_O


	,IIF(tax_type_group = 'Receiving Carer', Y2019Jan, 0) AS Y2019Jan_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2019Feb, 0) AS Y2019Feb_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2019Mar, 0) AS Y2019Mar_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2019Apr, 0) AS Y2019Apr_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2019May, 0) AS Y2019May_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2019Jun, 0) AS Y2019Jun_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2019Jul, 0) AS Y2019Jul_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2019Aug, 0) AS Y2019Aug_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2019Sep, 0) AS Y2019Sep_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2019Oct, 0) AS Y2019Oct_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2019Nov, 0) AS Y2019Nov_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2019Dec, 0) AS Y2019Dec_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2020Jan, 0) AS Y2020Jan_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2020Feb, 0) AS Y2020Feb_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2020Mar, 0) AS Y2020Mar_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2020Apr, 0) AS Y2020Apr_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2020May, 0) AS Y2020May_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2020Jun, 0) AS Y2020Jun_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2020Jul, 0) AS Y2020Jul_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2020Aug, 0) AS Y2020Aug_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2020Sep, 0) AS Y2020Sep_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2020Oct, 0) AS Y2020Oct_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', Y2020Nov, 0) AS Y2020Nov_Receiving_Carer
	/* debt components for 2019 and 2020*/
	,IIF(tax_type_group = 'Receiving Carer', type_pre_2019, 0) AS pre_2019_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_principle_2019, 0) AS principle_2019_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_penalty_2019, 0) AS penalty_2019_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_interest_2019, 0) AS interest_2019_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_maintenance_pos_2019, 0) AS maintenance_pos_2019_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_payment_2019, 0) AS payment_2019_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_remission_2019, 0) AS remission_2019_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_maintenance_neg_2019, 0) AS maintenance_neg_2019_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_principle_2020, 0) AS principle_2020_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_penalty_2020, 0) AS penalty_2020_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_interest_2020, 0) AS interest_2020_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_maintenance_pos_2020, 0) AS maintenance_pos_2020_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_payment_2020, 0) AS payment_2020_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_remission_2020, 0) AS remission_2020_Receiving_Carer
	,IIF(tax_type_group = 'Receiving Carer', type_maintenance_neg_2020, 0) AS maintenance_neg_2020_Receiving_Carer
	/*repayment indicator*/
	,IIF(tax_type_group = 'Receiving Carer' AND ind_payment_3mth = 1, 1, 0) AS ind_payment_3mth_RC
	,IIF(tax_type_group = 'Receiving Carer' AND ind_payment_6mth = 1, 1, 0) AS ind_payment_6mth_RC
	,IIF(tax_type_group = 'Receiving Carer' AND ind_payment_9mth = 1, 1, 0) AS ind_payment_9mth_RC
	,IIF(tax_type_group = 'Receiving Carer' AND ind_payment_12mth = 1, 1, 0) AS ind_payment_12mth_RC


	,IIF(tax_type_group = 'Student Loans', Y2019Jan, 0) AS Y2019Jan_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2019Feb, 0) AS Y2019Feb_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2019Mar, 0) AS Y2019Mar_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2019Apr, 0) AS Y2019Apr_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2019May, 0) AS Y2019May_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2019Jun, 0) AS Y2019Jun_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2019Jul, 0) AS Y2019Jul_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2019Aug, 0) AS Y2019Aug_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2019Sep, 0) AS Y2019Sep_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2019Oct, 0) AS Y2019Oct_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2019Nov, 0) AS Y2019Nov_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2019Dec, 0) AS Y2019Dec_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2020Jan, 0) AS Y2020Jan_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2020Feb, 0) AS Y2020Feb_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2020Mar, 0) AS Y2020Mar_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2020Apr, 0) AS Y2020Apr_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2020May, 0) AS Y2020May_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2020Jun, 0) AS Y2020Jun_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2020Jul, 0) AS Y2020Jul_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2020Aug, 0) AS Y2020Aug_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2020Sep, 0) AS Y2020Sep_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2020Oct, 0) AS Y2020Oct_Student_Loan
	,IIF(tax_type_group = 'Student Loans', Y2020Nov, 0) AS Y2020Nov_Student_Loan
	/* debt components for 2019 and 2020*/
	,IIF(tax_type_group = 'Student Loans', type_pre_2019, 0) AS pre_2019_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_principle_2019, 0) AS principle_2019_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_penalty_2019, 0) AS penalty_2019_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_interest_2019, 0) AS interest_2019_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_maintenance_pos_2019, 0) AS maintenance_pos_2019_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_payment_2019, 0) AS payment_2019_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_remission_2019, 0) AS remission_2019_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_maintenance_neg_2019, 0) AS maintenance_neg_2019_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_principle_2020, 0) AS principle_2020_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_penalty_2020, 0) AS penalty_2020_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_interest_2020, 0) AS interest_2020_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_maintenance_pos_2020, 0) AS maintenance_pos_2020_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_payment_2020, 0) AS payment_2020_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_remission_2020, 0) AS remission_2020_Student_Loans
	,IIF(tax_type_group = 'Student Loans', type_maintenance_neg_2020, 0) AS maintenance_neg_2020_Student_Loans
	/*repayment indicator*/
	,IIF(tax_type_group = 'Student Loans' AND ind_payment_3mth = 1, 1, 0) AS ind_payment_3mth_SL
	,IIF(tax_type_group = 'Student Loans' AND ind_payment_6mth = 1, 1, 0) AS ind_payment_6mth_SL
	,IIF(tax_type_group = 'Student Loans' AND ind_payment_9mth = 1, 1, 0) AS ind_payment_9mth_SL
	,IIF(tax_type_group = 'Student Loans' AND ind_payment_12mth = 1, 1, 0) AS ind_payment_12mth_SL
	/*debt persistence*/
	 ,IIF(Y2020Sep > 1 AND Y2020Aug > 1 AND Y2020Jul > 1, 1, 0) AS persistence_3mth
		  ,IIF(Y2020Sep > 1 AND Y2020Aug > 1 AND Y2020Jul > 1
		          AND Y2020Jun > 1 AND Y2020May > 1 AND Y2020Apr > 1, 1, 0) AS persistence_6mth
	      ,IIF(Y2020Sep > 1 AND Y2020Aug > 1 AND Y2020Jul >1
		          AND Y2020Jun > 1 AND Y2020May > 1 AND Y2020Apr > 1
				  AND Y2020Mar > 1 AND Y2020Feb > 1 AND Y2020Jan > 1, 1, 0) AS persistence_9mth
		  ,IIF(Y2020Sep > 1 AND Y2020Aug > 1 AND Y2020Jul > 1
		          AND Y2020Jun > 1 AND Y2020May > 1 AND Y2020Apr > 1
				  AND Y2020Mar > 1 AND Y2020Feb > 1 AND Y2020Jan > 1
				  AND Y2019Dec > 1 AND Y2019Nov > 1 AND Y2019Oct > 1, 1, 0) AS  persistence_12mth
		  ,IIF(Y2020Sep > 1 AND Y2020Aug > 1 AND Y2020Jul > 1
		          AND Y2020Jun > 1 AND Y2020May > 1 AND Y2020Apr > 1 
				  AND Y2020Mar > 1 AND Y2020Feb > 1 AND Y2020Jan > 1 
				  AND Y2019Dec > 1 AND Y2019Nov > 1 AND Y2019Oct > 1
				  AND Y2019Sep > 1 AND Y2019Aug > 1 AND Y2019Jul > 1, 1, 0) AS persistence_15mth
		  ,IIF(Y2020Sep > 1 AND Y2020Aug > 1 AND Y2020Jul > 1
		          AND Y2020Jun > 1 AND Y2020May > 1 AND Y2020Apr > 1
				  AND Y2020Mar > 1 AND Y2020Feb > 1 AND Y2020Jan > 1
				  AND Y2019Dec > 1 AND Y2019Nov > 1 AND Y2019Oct > 1
				  AND Y2019Sep > 1 AND Y2019Aug > 1 AND Y2019Jul > 1
				  AND Y2019Jun > 1 AND Y2019May > 1 AND Y2019Apr > 1, 1, 0) AS persistence_18mth
		  ,IIF(Y2020Sep > 1 AND Y2020Aug > 1 AND Y2020Jul > 1
		          AND Y2020Jun > 1 AND Y2020May > 1 AND Y2020Apr > 1
				  AND Y2020Mar > 1 AND Y2020Feb > 1 AND Y2020Jan > 1
				  AND Y2019Dec > 1 AND Y2019Nov > 1 AND Y2019Oct > 1
				  AND Y2019Sep > 1 AND Y2019Aug > 1 AND Y2019Jul > 1
				  AND Y2019Jun > 1 AND Y2019May > 1 AND Y2019Apr > 1
				  AND Y2019Mar > 1 AND Y2019Feb > 1 AND Y2019Jan > 1, 1, 0) AS persistence_21mth
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ird_debt_type_monthly]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_by_month]
GO


/***********************************************
Table for total debt for each person owed by month
***********************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ird_debt_tot_monthly]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ird_debt_tot_monthly];
GO


SELECT snz_uid
	  ,snz_ird_uid
      ,SUM(Y2019Jan) AS value_2019Jan
	  ,SUM(Y2019Feb) AS value_2019Feb
	  ,SUM(Y2019Mar) AS value_2019Mar
	  ,SUM(Y2019Apr) AS value_2019Apr
	  ,SUM(Y2019May) AS value_2019May
	  ,SUM(Y2019Jun) AS value_2019Jun
	  ,SUM(Y2019Jul) AS value_2019Jul
	  ,SUM(Y2019Aug) AS value_2019Aug
      ,SUM(Y2019Sep) AS value_2019Sep
	  ,SUM(Y2019Oct) AS value_2019Oct
	  ,SUM(Y2019Nov) AS value_2019Nov
	  ,SUM(Y2019Dec) AS value_2019Dec
	  ,SUM(Y2020Jan) AS value_2020Jan
	  ,SUM(Y2020Feb) AS value_2020Feb
	  ,SUM(Y2020Mar) AS value_2020Mar
	  ,SUM(Y2020Apr) AS value_2020Apr
	  ,SUM(Y2020May) AS value_2020May
	  ,SUM(Y2020Jun) AS value_2020Jun
	  ,SUM(Y2020Jul) AS value_2020Jul
	  ,SUM(Y2020Aug) AS value_2020Aug
	  ,SUM(Y2020Sep) AS value_2020Sep
	  ,SUM(Y2020Oct) AS value_2020Oct
	  ,SUM(Y2020Nov) AS value_2020Nov

	  /* debt components for 2019 and 2020*/
	  ,ROUND(SUM(type_pre_2019), 2) AS balance_pre_2019
	  ,ROUND(SUM(type_principle_2019), 2) AS principle_2019
	  ,ROUND(SUM(type_penalty_2019), 2) AS penalty_2019
	  ,ROUND(SUM(type_interest_2019), 2) AS interest_2019
	  ,ROUND(SUM(type_maintenance_pos_2019), 2) AS maintenance_pos_2019
  	  ,ROUND(SUM(type_payment_2019), 2) AS payment_2019
	  ,ROUND(SUM(type_remission_2019), 2) AS remission_2019
	  ,ROUND(SUM(type_maintenance_neg_2019), 2) AS maintenance_neg_2019
	  ,ROUND(SUM(type_principle_2020), 2) AS principle_2020
	  ,ROUND(SUM(type_penalty_2020), 2) AS penalty_2020
	  ,ROUND(SUM(type_interest_2020), 2) AS interest_2020
	  ,ROUND(SUM(type_maintenance_pos_2020), 2) AS maintenance_pos_2020
	  ,ROUND(SUM(type_payment_2020), 2) AS payment_2020
	  ,ROUND(SUM(type_remission_2020), 2) AS remission_2020
	  ,ROUND(SUM(type_maintenance_neg_2020), 2) AS maintenance_neg_2020

	  ,IIF(SUM(ind_payment_3mth) >= 1, 1, 0) AS ind_payment_3mth
	  ,IIF(SUM(ind_payment_6mth) >= 1, 1, 0) AS ind_payment_6mth
	  ,IIF(SUM(ind_payment_9mth) >= 1, 1, 0) AS ind_payment_9mth
	  ,IIF(SUM(ind_payment_12mth) >= 1, 1, 0) AS ind_payment_12mth
INTO  [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ird_debt_tot_monthly]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_by_month]
GROUP BY snz_uid, snz_ird_uid
GO


/**********************************************************************
Debt persistence indicator
***********************************************************************/
IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_ird_debt_type_monthly]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_type_monthly];
GO


SELECT *
       ,IIF(tax_type_group = 'Donation Tax Credits', persistence_3mth, 0) AS persistence_3mth_DTC
	   ,IIF(tax_type_group = 'Donation Tax Credits', persistence_6mth, 0) AS persistence_6mth_DTC
	   ,IIF(tax_type_group = 'Donation Tax Credits', persistence_9mth, 0) AS persistence_9mth_DTC
	   ,IIF(tax_type_group = 'Donation Tax Credits', persistence_12mth, 0) AS persistence_12mth_DTC
	   ,IIF(tax_type_group = 'Donation Tax Credits', persistence_15mth, 0) AS persistence_15mth_DTC
	   ,IIF(tax_type_group = 'Donation Tax Credits', persistence_18mth, 0) AS persistence_18mth_DTC
	   ,IIF(tax_type_group = 'Donation Tax Credits', persistence_21mth, 0) AS persistence_21mth_DTC

	   ,IIF(tax_type_group = 'Employment Activities', persistence_3mth, 0) AS persistence_3mth_EA
	   ,IIF(tax_type_group = 'Employment Activities', persistence_6mth, 0) AS persistence_6mth_EA
	   ,IIF(tax_type_group = 'Employment Activities', persistence_9mth, 0) AS persistence_9mth_EA
	   ,IIF(tax_type_group = 'Employment Activities', persistence_12mth, 0) AS persistence_12mth_EA
	   ,IIF(tax_type_group = 'Employment Activities', persistence_15mth, 0) AS persistence_15mth_EA
	   ,IIF(tax_type_group = 'Employment Activities', persistence_18mth, 0) AS persistence_18mth_EA
	   ,IIF(tax_type_group = 'Employment Activities', persistence_21mth, 0) AS persistence_21mth_EA

	   ,IIF(tax_type_group = 'Families', persistence_3mth, 0) AS persistence_3mth_F
	   ,IIF(tax_type_group = 'Families', persistence_6mth, 0) AS persistence_6mth_F
	   ,IIF(tax_type_group = 'Families', persistence_9mth, 0) AS persistence_9mth_F
	   ,IIF(tax_type_group = 'Families', persistence_12mth, 0) AS persistence_12mth_F
	   ,IIF(tax_type_group = 'Families', persistence_15mth, 0) AS persistence_15mth_F
	   ,IIF(tax_type_group = 'Families', persistence_18mth, 0) AS persistence_18mth_F
	   ,IIF(tax_type_group = 'Families', persistence_21mth, 0) AS persistence_21mth_F

	   ,IIF(tax_type_group = 'GST', persistence_3mth, 0) AS persistence_3mth_GST
	   ,IIF(tax_type_group = 'GST', persistence_6mth, 0) AS persistence_6mth_GST
	   ,IIF(tax_type_group = 'GST', persistence_9mth, 0) AS persistence_9mth_GST
	   ,IIF(tax_type_group = 'GST', persistence_12mth, 0) AS persistence_12mth_GST
	   ,IIF(tax_type_group = 'GST', persistence_15mth, 0) AS persistence_15mth_GST
	   ,IIF(tax_type_group = 'GST', persistence_18mth, 0) AS persistence_18mth_GST
	   ,IIF(tax_type_group = 'GST', persistence_21mth, 0) AS persistence_21mth_GST

	   ,IIF(tax_type_group = 'Income Tax', persistence_3mth, 0) AS persistence_3mth_IT
	   ,IIF(tax_type_group = 'Income Tax', persistence_6mth, 0) AS persistence_6mth_IT
	   ,IIF(tax_type_group = 'Income Tax', persistence_9mth, 0) AS persistence_9mth_IT
	   ,IIF(tax_type_group = 'Income Tax', persistence_12mth, 0) AS persistence_12mth_IT
	   ,IIF(tax_type_group = 'Income Tax', persistence_15mth, 0) AS persistence_15mth_IT
	   ,IIF(tax_type_group = 'Income Tax', persistence_18mth, 0) AS persistence_18mth_IT
	   ,IIF(tax_type_group = 'Income Tax', persistence_21mth, 0) AS persistence_21mth_IT

	   ,IIF(tax_type_group = 'Liable Parent', persistence_3mth, 0) AS persistence_3mth_LP
	   ,IIF(tax_type_group = 'Liable Parent', persistence_6mth, 0) AS persistence_6mth_LP
	   ,IIF(tax_type_group = 'Liable Parent', persistence_9mth, 0) AS persistence_9mth_LP
	   ,IIF(tax_type_group = 'Liable Parent', persistence_12mth, 0) AS persistence_12mth_LP
	   ,IIF(tax_type_group = 'Liable Parent', persistence_15mth, 0) AS persistence_15mth_LP
	   ,IIF(tax_type_group = 'Liable Parent', persistence_18mth, 0) AS persistence_18mth_LP
	   ,IIF(tax_type_group = 'Liable Parent', persistence_21mth, 0) AS persistence_21mth_LP

	   ,IIF(tax_type_group = 'Other', persistence_3mth, 0) AS persistence_3mth_O
	   ,IIF(tax_type_group = 'Other', persistence_6mth, 0) AS persistence_6mth_O
	   ,IIF(tax_type_group = 'Other', persistence_9mth, 0) AS persistence_9mth_O
	   ,IIF(tax_type_group = 'Other', persistence_12mth, 0) AS persistence_12mth_O
	   ,IIF(tax_type_group = 'Other', persistence_15mth, 0) AS persistence_15mth_O
	   ,IIF(tax_type_group = 'Other', persistence_18mth, 0) AS persistence_18mth_O
	   ,IIF(tax_type_group = 'Other', persistence_21mth, 0) AS persistence_21mth_O

	   ,IIF(tax_type_group = 'Receiving Carer', persistence_3mth, 0) AS persistence_3mth_RC
	   ,IIF(tax_type_group = 'Receiving Carer', persistence_6mth, 0) AS persistence_6mth_RC
	   ,IIF(tax_type_group = 'Receiving Carer', persistence_9mth, 0) AS persistence_9mth_RC
	   ,IIF(tax_type_group = 'Receiving Carer', persistence_12mth, 0) AS persistence_12mth_RC
	   ,IIF(tax_type_group = 'Receiving Carer', persistence_15mth, 0) AS persistence_15mth_RC
	   ,IIF(tax_type_group = 'Receiving Carer', persistence_18mth, 0) AS persistence_18mth_RC
	   ,IIF(tax_type_group = 'Receiving Carer', persistence_21mth, 0) AS persistence_21mth_RC

	   ,IIF(tax_type_group = 'Student Loans', persistence_3mth, 0) AS persistence_3mth_SL
	   ,IIF(tax_type_group = 'Student Loans', persistence_6mth, 0) AS persistence_6mth_SL
	   ,IIF(tax_type_group = 'Student Loans', persistence_9mth, 0) AS persistence_9mth_SL
	   ,IIF(tax_type_group = 'Student Loans', persistence_12mth, 0) AS persistence_12mth_SL
	   ,IIF(tax_type_group = 'Student Loans', persistence_15mth, 0) AS persistence_15mth_SL
	   ,IIF(tax_type_group = 'Student Loans', persistence_18mth, 0) AS persistence_18mth_SL
	   ,IIF(tax_type_group = 'Student Loans', persistence_21mth, 0) AS persistence_21mth_SL
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_type_monthly]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ird_debt_type_monthly]
GO
/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_type_monthly] ([snz_uid]);
GO


IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_ird_debt_tot_monthly]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_tot_monthly];
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
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_tot_monthly]
FROM  [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ird_debt_tot_monthly]
GO

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_tot_monthly] ([snz_uid]);
GO



/**************************************************************************************************
remove temporary table
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[tmp_ir_debt_transactions]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[tmp_ir_debt_transactions];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[ir_debt_transactions_corrected];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_ird_balances_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_ird_balances_by_month]; 
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ird_debt_by_month];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ird_debt_type_monthly]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ird_debt_type_monthly];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ird_debt_tot_monthly]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ird_debt_tot_monthly];
GO
