/**************************************************************************************************
Title: Debt to MOJ Phase 2

Author: Freya Li

Inputs & Dependencies:
- [IDI_Adhoc].[clean_read_DEBT].[moj_debt_full_summary_trimmed]

- [IDI_Adhoc].[clean_read_DEBT].[moj_debt_identity_fml_and_adhoc]
- [IDI_Adhoc].[clean_read_DEBT].[moj_debt_data_link] 
- [IDI_Clean].[security].[concordance]

Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_cases]
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_total_debt_by_month]
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_by_month]

Description: 
Debt, debt balances, and repayment for debtors owing money to MOJ.

Intended purpose:
Identifying debtors.
Calculating number of debtors and total value of debts.
Calculating change in debts - due to borrowing or repayment.

Notes:
1. Date range for table [moj_debt_full_summary_trimmed] is Dec2010 - Dec2020.
   The balance in 2011 has no change for every month, we discard all data pre-2012.

2. Numbers represent the amount of the money, they are all positive.
   Delta = penalty + impositions - payment - remittals + payment_reversal +remittal_reversal
   delta is calculated correctly


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
2021-06017 FL comment out the active debt duration as it's out of scope; add repayment indicator; debt persisitence
2021-05-07 FL including monthly incurred debt and repayment
2021-03-03 FL work begun
**************************************************************************************************/


/**************************************************************************************************
Prior to use, copy to sandpit and index
(runtime 2 minutes)
**************************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary];
GO

SELECT *
      ,DATEFROMPARTS(year_nbr, month_of_year_nbr, 1) AS date
	  ,penalty + impositions + payment_reversal + remittal_reversal AS amount_pos
	  ,payment + remittals AS amount_neg
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary]
FROM [IDI_Adhoc].[clean_read_DEBT].[moj_debt_full_summary_trimmed]
WHERE year_nbr>2011
GO
/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary] ([moj_ppn]);
GO



/**************************************************************************************************
Data prearation
**************************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_duration_prep]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_duration_prep];
GO
SELECT*
      ,SUM(amount_pos + balance_before_2012) OVER (PARTITION BY moj_ppn ORDER BY date)  AS incurred_running
	  ,SUM(amount_neg) OVER (PARTITION BY moj_ppn ORDER BY date) AS repaid_running	 
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_duration_prep]
FROM(
	SELECT*
		  ,IIF(first_record_ind = 1, COALESCE(outstanding_balance, 0) - delta, 0) AS balance_before_2012
	FROM(
		SELECT *
		       ,IIF(year_nbr < 2019, delta, 0)  AS  pre_2019_delta
			   ,IIF(date = MIN(date) OVER (PARTITION BY moj_ppn), 1, 0) AS first_record_ind
			   ,IIF(date = MAX(date) OVER (PARTITION BY moj_ppn), 1, 0) AS last_record_ind
		FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary]
		)a
	)b
/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_duration_prep] ([moj_ppn]);
GO



/****************************************************************************************
2019 & 2020 total debt for each month. 
(Jan 2019 -- Dec 2020)
****************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_by_month];
GO

SELECT moj_ppn
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
	  ,ROUND(SUM(for_2020Oct_value), 2) AS value_2020Oct
	  ,ROUND(SUM(for_2020Nov_value), 2) AS value_2020Nov
	  ,ROUND(SUM(for_2020Dec_value), 2) AS value_2020Dec

	  ,ROUND(SUM(pre_2019_delta + balance_before_2012), 2) AS balance_pre_2019
	  ,ROUND(SUM(for_2019_principle), 2) AS principle_2019
	  ,ROUND(SUM(for_2019_penalty), 2) AS penalty_2019
	  ,ROUND(SUM(for_2019_reversal), 2) AS reversal_2019
	  ,ROUND(SUM(for_2019_payment), 2) AS payment_2019
	  ,ROUND(SUM(for_2019_remittal), 2) AS remittal_2019
	  ,ROUND(SUM(for_2020_principle), 2) AS principle_2020
	  ,ROUND(SUM(for_2020_penalty), 2) AS penalty_2020
	  ,ROUND(SUM(for_2020_reversal), 2) AS reversal_2020
	  ,ROUND(SUM(for_2020_payment), 2) AS payment_2020
	  ,ROUND(SUM(for_2020_remittal), 2) AS remittal_2020

	  /*repayment indicator*/
	  ,IIF(SUM(for_payment_3mth) >= 1, 1, 0) AS ind_payment_3mth
	  ,IIF(SUM(for_payment_6mth) >= 1, 1, 0) AS ind_payment_6mth
	  ,IIF(SUM(for_payment_9mth) >= 1, 1, 0) AS ind_payment_9mth
	  ,IIF(SUM(for_payment_12mth) >= 1, 1, 0) AS ind_payment_12mth
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_by_month]
FROM (
	SELECT moj_ppn
       ,date
	   ,impositions
	   ,pre_2019_delta 
	   ,IIF(date <= '2020-09-01', balance_before_2012, 0) AS balance_before_2012
	  --only consider the debt balance before Sep2020 to keep the sum of the components is same as the balance as at Sep 2020
	   /* 2019 months setup */
	   ,IIF(date <= '2019-01-01', delta + balance_before_2012, 0) AS for_2019Jan_value  
	   ,IIF(date <= '2019-02-01', delta + balance_before_2012, 0) AS for_2019Feb_value  
	   ,IIF(date <= '2019-03-01', delta + balance_before_2012, 0) AS for_2019Mar_value  
	   ,IIF(date <= '2019-04-01', delta + balance_before_2012, 0) AS for_2019Apr_value  
	   ,IIF(date <= '2019-05-01', delta + balance_before_2012, 0) AS for_2019May_value  
 	   ,IIF(date <= '2019-06-01', delta + balance_before_2012, 0) AS for_2019Jun_value  
	   ,IIF(date <= '2019-07-01', delta + balance_before_2012, 0) AS for_2019Jul_value  
	   ,IIF(date <= '2019-08-01', delta + balance_before_2012, 0) AS for_2019Aug_value  
	   ,IIF(date <= '2019-09-01', delta + balance_before_2012, 0) AS for_2019Sep_value  
	   ,IIF(date <= '2019-10-01', delta + balance_before_2012, 0) AS for_2019Oct_value
       ,IIF(date <= '2019-11-01', delta + balance_before_2012, 0) AS for_2019Nov_value
	   ,IIF(date <= '2019-12-01', delta + balance_before_2012, 0) AS for_2019Dec_value
	   /* 2020 months setup */
	   ,IIF(date <= '2020-01-01', delta + balance_before_2012, 0) AS for_2020Jan_value  
	   ,IIF(date <= '2020-02-01', delta + balance_before_2012, 0) AS for_2020Feb_value  
	   ,IIF(date <= '2020-03-01', delta + balance_before_2012, 0) AS for_2020Mar_value  
	   ,IIF(date <= '2020-04-01', delta + balance_before_2012, 0) AS for_2020Apr_value  
	   ,IIF(date <= '2020-05-01', delta + balance_before_2012, 0) AS for_2020May_value  
 	   ,IIF(date <= '2020-06-01', delta + balance_before_2012, 0) AS for_2020Jun_value  
	   ,IIF(date <= '2020-07-01', delta + balance_before_2012, 0) AS for_2020Jul_value  
	   ,IIF(date <= '2020-08-01', delta + balance_before_2012, 0) AS for_2020Aug_value  
	   ,IIF(date <= '2020-09-01', delta + balance_before_2012, 0) AS for_2020Sep_value  
	   ,IIF(date <= '2020-10-01', delta + balance_before_2012, 0) AS for_2020Oct_value
       ,IIF(date <= '2020-11-01', delta + balance_before_2012, 0) AS for_2020Nov_value
	   ,IIF(date <= '2020-12-01', delta + balance_before_2012, 0) AS for_2020Dec_value

	   /* debt components for 2019 and 2020*/
	   
	   ,IIF(year_nbr = 2019, impositions, 0) AS for_2019_principle
	   ,IIF(year_nbr = 2019, penalty, 0) AS for_2019_penalty
	   ,IIF(year_nbr = 2019, payment_reversal + remittal_reversal, 0) AS for_2019_reversal
	   ,IIF(year_nbr = 2019, payment, 0) AS for_2019_payment
	   ,IIF(year_nbr = 2019, remittals, 0) AS for_2019_remittal
	   ,IIF(year_nbr = 2020 AND month_of_year_nbr <= 9, impositions, 0) AS for_2020_principle
	   ,IIF(year_nbr = 2020 AND month_of_year_nbr <= 9, penalty, 0) AS for_2020_penalty
	   ,IIF(year_nbr = 2020 AND month_of_year_nbr <= 9, payment_reversal + remittal_reversal, 0) AS for_2020_reversal
	   ,IIF(year_nbr = 2020 AND month_of_year_nbr <= 9, payment, 0) AS for_2020_payment
	   ,IIF(year_nbr = 2020 AND month_of_year_nbr <= 9, remittals, 0) AS for_2020_remittal
	   /*repayment plan*/
	   ,IIF('2020-07-01' <= date AND date <= '2020-09-01' AND payment > 1, 1, 0) AS for_payment_3mth
	   ,IIF('2020-04-01' <= date AND date <= '2020-09-01' AND payment > 1, 1, 0) AS for_payment_6mth
	   ,IIF('2020-01-01' <= date AND date <= '2020-09-01' AND payment > 1, 1, 0) AS for_payment_9mth
	   ,IIF('2019-10-01' <= date AND date <= '2020-09-01' AND payment > 1, 1, 0) AS for_payment_12mth

	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_duration_prep]
	) a
GROUP BY moj_ppn
HAVING ABS(SUM(for_2019Jan_value)) > 1
OR ABS(SUM(for_2019Feb_value)) > 1
OR ABS(SUM(for_2019Mar_value)) > 1
OR ABS(SUM(for_2019Apr_value)) > 1
OR ABS(SUM(for_2019May_value)) > 1
OR ABS(SUM(for_2019Jun_value)) > 1
OR ABS(SUM(for_2019Jul_value)) > 1
OR ABS(SUM(for_2019Aug_value)) > 1
OR ABS(SUM(for_2019Sep_value)) > 1
OR ABS(SUM(for_2019Oct_value)) > 1
OR ABS(SUM(for_2019Nov_value)) > 1
OR ABS(SUM(for_2019Dec_value)) > 1
OR ABS(SUM(for_2020Jan_value)) > 1
OR ABS(SUM(for_2020Feb_value)) > 1
OR ABS(SUM(for_2020Mar_value)) > 1
OR ABS(SUM(for_2020Apr_value)) > 1
OR ABS(SUM(for_2020May_value)) > 1
OR ABS(SUM(for_2020Jun_value)) > 1
OR ABS(SUM(for_2020Jul_value)) > 1
OR ABS(SUM(for_2020Aug_value)) > 1
OR ABS(SUM(for_2020Sep_value)) > 1
OR ABS(SUM(for_2020Oct_value)) > 1
OR ABS(SUM(for_2020Nov_value)) > 1
OR ABS(SUM(for_2020Dec_value)) > 1


CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_by_month] (moj_ppn);
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
      ,fml.[snz_fml_7_uid]
	  ,fml.[moj_ppn]
	  ,dl.[rhs_nbr]
	  ,dl.[lhs_nbr]
      ,sc_fml.snz_spine_uid
	  ,sc_fml.snz_uid
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_id]
FROM [IDI_Adhoc].[clean_read_DEBT].[moj_debt_identity_fml_and_adhoc] AS fml
LEFT JOIN [IDI_Adhoc].[clean_read_DEBT].[moj_debt_data_link] AS dl
ON fml.snz_fml_7_uid = dl.rhs_nbr 
AND (dl.near_exact_ind = 1
     OR dl.weight_nbr > 17) -- exclude only low weight, non-exact links
LEFT JOIN [IDI_Clean_20201020].[security].[concordance] AS sc_fml
ON dl.lhs_nbr = sc_fml.snz_spine_uid
WHERE dl.run_key = 941  -- there are different run_key suggest the same rhs_nbr. Rhs_nbr is the right_hand side identifier, also known as node.
--FML loader used twice for MoJ data 941 for fines & charges, 943 for FCCO



IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_debt_by_month];
GO
SELECT b.snz_uid
       ,a.*
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_debt_by_month]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_by_month] a
LEFT JOIN [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_id] b
ON a.moj_ppn = b.moj_ppn
/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_debt_by_month] (snz_uid);
GO

--Keep one record for each snz_uid
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tep3_moj_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tep3_moj_debt_by_month];
GO
SELECT snz_uid
       ,SUM(value_2019Jan) AS value_2019Jan
	   ,SUM(value_2019Feb) AS value_2019Feb
	   ,SUM(value_2019Mar) AS value_2019Mar
	   ,SUM(value_2019Apr) AS value_2019Apr
	   ,SUM(value_2019May) AS value_2019May
	   ,SUM(value_2019Jun) AS value_2019Jun
	   ,SUM(value_2019Jul) AS value_2019Jul
	   ,SUM(value_2019Aug) AS value_2019Aug
	   ,SUM(value_2019Sep) AS value_2019Sep
	   ,SUM(value_2019Oct) AS value_2019Oct
	   ,SUM(value_2019Nov) AS value_2019Nov
	   ,SUM(value_2019Dec) AS value_2019Dec

	   ,SUM(value_2020Jan) AS value_2020Jan
	   ,SUM(value_2020Feb) AS value_2020Feb
	   ,SUM(value_2020Mar) AS value_2020Mar
	   ,SUM(value_2020Apr) AS value_2020Apr
	   ,SUM(value_2020May) AS value_2020May
	   ,SUM(value_2020Jun) AS value_2020Jun
	   ,SUM(value_2020Jul) AS value_2020Jul
	   ,SUM(value_2020Aug) AS value_2020Aug
	   ,SUM(value_2020Sep) AS value_2020Sep
	   ,SUM(value_2020Oct) AS value_2020Oct
	   ,SUM(value_2020Nov) AS value_2020Nov
	   ,SUM(value_2020Dec) AS value_2020Dec
	   
	   ,SUM(balance_pre_2019) AS balance_pre_2019
	   ,SUM(principle_2019) AS principle_2019
	   ,SUM(penalty_2019) AS penalty_2019
	   ,SUM(reversal_2019) AS reversal_2019
	   ,SUM(payment_2019) AS payment_2019
	   ,SUM(remittal_2019) AS remittal_2019
	   ,SUM(principle_2020) AS principle_2020
	   ,SUM(penalty_2020) AS penalty_2020
	   ,SUM(reversal_2020) AS reversal_2020
	   ,SUM(payment_2020) AS payment_2020
	   ,SUM(remittal_2020) AS remittal_2020
	   ,IIF(SUM(ind_payment_3mth) >= 1, 1, 0) AS ind_payment_3mth
	   ,IIF(SUM(ind_payment_6mth) >= 1, 1, 0) AS ind_payment_6mth
	   ,IIF(SUM(ind_payment_9mth) >= 1, 1, 0) AS ind_payment_9mth
	   ,IIF(SUM(ind_payment_12mth) >= 1, 1, 0) AS ind_payment_12mth
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tep3_moj_debt_by_month]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_debt_by_month]
GROUP BY snz_uid

/*debt persistence*/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_by_month];
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
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_by_month]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tep3_moj_debt_by_month]



/****************************************************************************************
2019 & 2020 total debt owed to MoJ for each month (fines, and family court). 
(Jan 2019 -- Dec 2020)
Monthly new debt and repayment are recoded in [moj_debt_full_summary_trimmed]
****************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_total_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_total_debt_by_month];
GO
SELECT COALESCE(a.snz_uid, b.snz_uid) AS snz_uid
	    /*2019*/
      ,ROUND(ISNULL(a.value_2019Jan, 0) + ISNULL(b.value_2019Jan, 0), 2) AS value_2019Jan
	  ,ROUND(ISNULL(a.value_2019Feb, 0) + ISNULL(b.value_2019Feb, 0), 2) AS value_2019Feb
	  ,ROUND(ISNULL(a.value_2019Mar, 0) + ISNULL(b.value_2019Mar, 0), 2) AS value_2019Mar
	  ,ROUND(ISNULL(a.value_2019Apr, 0) + ISNULL(b.value_2019Apr, 0), 2) AS value_2019Apr
	  ,ROUND(ISNULL(a.value_2019May, 0) + ISNULL(b.value_2019May, 0), 2) AS value_2019May
	  ,ROUND(ISNULL(a.value_2019Jun, 0) + ISNULL(b.value_2019Jun, 0), 2) AS value_2019Jun
	  ,ROUND(ISNULL(a.value_2019Jul, 0) + ISNULL(b.value_2019Jul, 0), 2) AS value_2019Jul
	  ,ROUND(ISNULL(a.value_2019Aug, 0) + ISNULL(b.value_2019Aug, 0), 2) AS value_2019Aug
	  ,ROUND(ISNULL(a.value_2019Sep, 0) + ISNULL(b.value_2019Sep, 0), 2) AS value_2019Sep
	  ,ROUND(ISNULL(a.value_2019Oct, 0) + ISNULL(b.value_2019Oct, 0), 2) AS value_2019Oct
	  ,ROUND(ISNULL(a.value_2019Nov, 0) + ISNULL(b.value_2019Nov, 0), 2) AS value_2019Nov
	  ,ROUND(ISNULL(a.value_2019Dec, 0) + ISNULL(b.value_2019Dec, 0), 2) AS value_2019Dec
	   /*2020*/
	  ,ROUND(ISNULL(a.value_2020Jan, 0) + ISNULL(b.value_2020Jan, 0), 2) AS value_2020Jan
	  ,ROUND(ISNULL(a.value_2020Feb, 0) + ISNULL(b.value_2020Feb, 0), 2) AS value_2020Feb
	  ,ROUND(ISNULL(a.value_2020Mar, 0) + ISNULL(b.value_2020Mar, 0), 2) AS value_2020Mar
	  ,ROUND(ISNULL(a.value_2020Apr, 0) + ISNULL(b.value_2020Apr, 0), 2) AS value_2020Apr
	  ,ROUND(ISNULL(a.value_2020May, 0) + ISNULL(b.value_2020May, 0), 2) AS value_2020May
	  ,ROUND(ISNULL(a.value_2020Jun, 0) + ISNULL(b.value_2020Jun, 0), 2) AS value_2020Jun
	  ,ROUND(ISNULL(a.value_2020Jul, 0) + ISNULL(b.value_2020Jul, 0), 2) AS value_2020Jul
	  ,ROUND(ISNULL(a.value_2020Aug, 0) + ISNULL(b.value_2020Aug, 0), 2) AS value_2020Aug
	  ,ROUND(ISNULL(a.value_2020Sep, 0) + ISNULL(b.value_2020Sep, 0), 2) AS value_2020Sep
	  ,ROUND(ISNULL(a.value_2020Oct, 0) + ISNULL(b.value_2020Oct, 0), 2) AS value_2020Oct
	  ,ROUND(ISNULL(a.value_2020Nov, 0) + ISNULL(b.value_2020Nov, 0), 2) AS value_2020Nov
	  ,ROUND(ISNULL(a.value_2020Dec, 0) + ISNULL(b.value_2020Dec, 0), 2) AS value_2020Dec


	  /*debt components for 2019 and 2020*/
	  ,ROUND(ISNULL(a.balance_pre_2019, 0) + ISNULL(b.balance_pre_2019, 0), 2) AS balance_pre_2019
	  ,ROUND(ISNULL(a.principle_2019, 0) + ISNULL(b.principle_2019, 0), 2) AS principle_2019
	  ,ROUND(ISNULL(a.penalty_2019, 0), 2) AS penalty_2019
	  ,ROUND(ISNULL(a.reversal_2019, 0), 2) AS reversal_2019
	  ,ROUND(ISNULL(a.payment_2019, 0) + ISNULL(b.payment_2019, 0), 2) AS payment_2019
	  ,ROUND(ISNULL(a.remittal_2019, 0) + ISNULL(b.write_off_2019, 0), 2) AS write_off_2019
	  ,ROUND(ISNULL(a.principle_2020, 0) + ISNULL(b.principle_2020, 0), 2) AS principle_2020
	  ,ROUND(ISNULL(a.penalty_2020, 0), 2) AS penalty_2020
	  ,ROUND(ISNULL(a.reversal_2020, 0), 2) AS reversal_2020
	  ,ROUND(ISNULL(a.payment_2020, 0) + ISNULL(b.payment_2020, 0), 2) AS payment_2020
	  ,ROUND(ISNULL(a.remittal_2020, 0) + ISNULL(b.write_off_2020, 0), 2) AS write_off_2020

	  /*repayment indicator*/
	  ,IIF(a.ind_payment_3mth = 1 OR b.ind_payment_3mth = 1, 1, 0) AS ind_payment_3mth
	  ,IIF(a.ind_payment_6mth = 1 OR b.ind_payment_6mth = 1, 1, 0) AS ind_payment_6mth
	  ,IIF(a.ind_payment_9mth = 1 OR b.ind_payment_9mth = 1, 1, 0) AS ind_payment_9mth
	  ,IIF(a.ind_payment_12mth = 1 OR b.ind_payment_12mth = 1, 1, 0) AS ind_payment_12mth

	  /*debt persistence*/
	  ,IIF(a.persistence_3mth = 1 OR b.persistence_3mth = 1, 1, 0) AS persistence_3mth 
	  ,IIF(a.persistence_6mth = 1 OR b.persistence_6mth = 1, 1, 0) AS persistence_6mth 
	  ,IIF(a.persistence_9mth = 1 OR b.persistence_9mth = 1, 1, 0) AS persistence_9mth 
	  ,IIF(a.persistence_12mth = 1 OR b.persistence_12mth = 1, 1, 0) AS persistence_12mth 
	  ,IIF(a.persistence_15mth = 1 OR b.persistence_15mth = 1, 1, 0) AS persistence_15mth 
	  ,IIF(a.persistence_18mth = 1 OR b.persistence_18mth = 1, 1, 0) AS persistence_18mth 
	  ,IIF(a.persistence_21mth = 1 OR b.persistence_21mth = 1, 1, 0) AS persistence_21mth 
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_total_debt_by_month]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_by_month] a
FULL JOIN [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_by_month] b
ON a.snz_uid = b.snz_uid

CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_total_debt_by_month] (snz_uid);
GO


/*********** remove temporary table ***********/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_duration_prep]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_duration_prep];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_cases]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_cases];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_debt_by_month];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_debt_by_month];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_id]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_id];
GO

