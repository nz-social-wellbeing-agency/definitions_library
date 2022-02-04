/**************************************************************************************************
Title: Debt to MOJ FCCO Phase 2
Author: Freya Li

Acknowledgement: Part of the code is took from Simon's code for D2G phase 1.


Inputs & Dependencies:
-  [IDI_Adhoc].[clean_read_DEBT].[moj_debt_fcco_monthly_balances]

Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_cases]
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_by_month]

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
   closing_balance[1] = new_debt_established[1] + repayments[1] + write_offs[1] 
   repayments + write_offs, the rest of the closing_balance (except first record) is just 
   the running balnce (which means that:
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
2021-06-18 FL comment out active debt deration period as it's out of scope; repayment indicator; persistence indicator
2021-05-07 FL including monthly incured debt and repayment 
2021-03-08 FL work begun
***************************************************************************************************/


/**************************************************************************************************
Prior to use, copy to sandpit and index
(runtime 2 minutes)
**************************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances];
GO

SELECT *
      ,DATEFROMPARTS(calendar_year,RIGHT(month_nbr,2),1) AS date
	  ,IIF(calendar_year < 2019, COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0), 0)  AS  pre_2019_delta
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances]
FROM [IDI_Adhoc].[clean_read_DEBT].[moj_debt_fcco_monthly_balances]

GO
/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances] ([fcco_file_nbr]);
GO



/****************************************************************************************
2019 & 2020 total debt for each montly. 
(Jan 2019 -- Dec 2020)
****************************************************************************************/
-- Those debt has been paid_off before 2019 has been excluded from our monthly debt table
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_fcco_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_fcco_debt_by_month];
GO
SELECT fcco_file_nbr
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

	
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_fcco_debt_by_month]
FROM(
SELECT fcco_file_nbr
      ,[pre_2019_delta]
      /*2019 months set up*/
      ,IIF( date <= '2019-01-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2019Jan_value
	  ,IIF( date <= '2019-02-01', COALESCE(new_debt_established, 0)	+ COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2019Feb_value
	  ,IIF( date <= '2019-03-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2019Mar_value
	  ,IIF( date <= '2019-04-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2019Apr_value
	  ,IIF( date <= '2019-05-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2019May_value
	  ,IIF( date <= '2019-06-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2019Jun_value
	  ,IIF( date <= '2019-07-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2019Jul_value
	  ,IIF( date <= '2019-08-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2019Aug_value
	  ,IIF( date <= '2019-09-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2019Sep_value
	  ,IIF( date <= '2019-10-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2019Oct_value
	  ,IIF( date <= '2019-11-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2019Nov_value
	  ,IIF( date <= '2019-12-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2019Dec_value
	  /*2020 months set up*/
      ,IIF( date <= '2020-01-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2020Jan_value
	  ,IIF( date <= '2020-02-01', COALESCE(new_debt_established, 0)	+ COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2020Feb_value
	  ,IIF( date <= '2020-03-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2020Mar_value
	  ,IIF( date <= '2020-04-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2020Apr_value
	  ,IIF( date <= '2020-05-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2020May_value
	  ,IIF( date <= '2020-06-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2020Jun_value
	  ,IIF( date <= '2020-07-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2020Jul_value
	  ,IIF( date <= '2020-08-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2020Aug_value
	  ,IIF( date <= '2020-09-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2020Sep_value
	  ,IIF( date <= '2020-10-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2020Oct_value
	  ,IIF( date <= '2020-11-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2020Nov_value
	  ,IIF( date <= '2020-12-01', COALESCE(new_debt_established, 0) + COALESCE(repayments, 0) + COALESCE(write_offs, 0),0) AS for_2020Dec_value


	  ,IIF(calendar_year = 2019, COALESCE(new_debt_established, 0), 0) AS for_2019_principle
	  ,IIF(calendar_year = 2019, - COALESCE(repayments, 0), 0) AS for_2019_payment
	  ,IIF(calendar_year = 2019, - COALESCE(write_offs, 0), 0) AS for_2019_write_off
	  ,IIF(calendar_year = 2020 AND MONTH(date)<=9, COALESCE(new_debt_established, 0), 0) AS for_2020_principle
	  ,IIF(calendar_year = 2020 AND MONTH(date)<=9, - COALESCE(repayments, 0), 0) AS for_2020_payment
	  ,IIF(calendar_year = 2020 AND MONTH(date)<=9, - COALESCE(write_offs, 0), 0) AS for_2020_write_off

	  /*repayment plan*/
	  ,IIF('2020-07-01' <= date AND date <= '2020-09-01' AND repayments < -1, 1, 0) AS for_payment_3mth
	  ,IIF('2020-04-01' <= date AND date <= '2020-09-01' AND repayments < -1, 1, 0) AS for_payment_6mth
	  ,IIF('2020-01-01' <= date AND date <= '2020-09-01' AND repayments < -1, 1, 0) AS for_payment_9mth
	  ,IIF('2019-10-01' <= date AND date <= '2020-09-01' AND repayments < -1, 1, 0) AS for_payment_12mth

FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances]
)a
GROUP BY fcco_file_nbr
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
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_fcco_debt_by_month] (fcco_file_nbr);
GO



/*************************************************************************
Join MoJ FCCO data to spine
*************************************************************************/
--Linking MoJ debt data with fast match loader
--FML for the MoJ debt data is specific to the 20201020 refresh. 
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_id]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_id];
GO
SELECT fml.[snz_fml_8_uid]
	  ,fml.[fcco_file_nbr]
	  ,dl.[rhs_nbr]
	  ,dl.[lhs_nbr]
      ,sc_fml.snz_spine_uid
	  ,sc_fml.snz_uid
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_id]
FROM [IDI_Adhoc].[clean_read_DEBT].[moj_debt_fcco_identities] AS fml
LEFT JOIN [IDI_Adhoc].[clean_read_DEBT].[moj_debt_data_link] AS dl
ON fml.snz_fml_8_uid = dl.rhs_nbr 
AND (dl.near_exact_ind = 1
     OR dl.weight_nbr > 17) -- exclude only low weight, non-exact links
LEFT JOIN [IDI_Clean_20201020].[security].[concordance] AS sc_fml
ON dl.lhs_nbr = sc_fml.snz_spine_uid
WHERE dl.run_key = 943  -- thre are different run_key suggest the same rhs_nbr. Rhs_nbr is the right_hand side identifier, also known as node.
--FML loader used twice for MoJ data 941 for fines & charges, 943 for FCCO



IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_fcco_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_fcco_debt_by_month];
GO
SELECT b.snz_uid
       ,a.*
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_fcco_debt_by_month]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_fcco_debt_by_month] a
LEFT JOIN [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_id] b
ON a.fcco_file_nbr = b.fcco_file_nbr
/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_fcco_debt_by_month] (snz_uid);
GO


/*************************************************
Keep one record for each snz_uid
*************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tem3_moj_fcco_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tem3_moj_fcco_debt_by_month];
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

	   ,sum(balance_pre_2019) AS balance_pre_2019
	   ,SUM(principle_2019) AS principle_2019
	   ,SUM(payment_2019) AS payment_2019
	   ,SUM(write_off_2019) AS write_off_2019
	   ,SUM(principle_2020) AS principle_2020
       ,SUM(payment_2020) AS payment_2020
	   ,SUM(write_off_2020) AS write_off_2020

	   ,IIF(SUM(ind_payment_3mth) >= 1, 1, 0) AS ind_payment_3mth
	   ,IIF(SUM(ind_payment_6mth) >= 1, 1, 0) AS ind_payment_6mth
	   ,IIF(SUM(ind_payment_9mth) >= 1, 1, 0) AS ind_payment_9mth
	   ,IIF(SUM(ind_payment_12mth) >= 1, 1, 0) AS ind_payment_12mth
  	
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tem3_moj_fcco_debt_by_month]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_fcco_debt_by_month]
GROUP BY snz_uid


/*persistence indicator*/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_by_month];
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
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_by_month]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tem3_moj_fcco_debt_by_month]




/*********** remove temporary table ***********/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_fcco_debt_duration_prep]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_fcco_debt_duration_prep];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_fcco_debt_cases]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_fcco_debt_cases];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_fcco_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_moj_fcco_debt_by_month];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_fcco_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp2_moj_fcco_debt_by_month];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_fcco_monthly_balances];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_id]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_fcco_debt_id];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tem3_moj_fcco_debt_by_month]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tem3_moj_fcco_debt_by_month];
GO