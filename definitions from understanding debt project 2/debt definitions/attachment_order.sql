 /**************************************************************************************************
Title: Debt to MOJ -- Attachment order

Author: Freya Li

Inputs & Dependencies:
- [IDI_Adhoc].[clean_read_DEBT].[moj_debt_full_summary_trimmed]
- [IDI_Clean_20201020].[msd_clean].[msd_spell]

Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_monthly_payment_AO] 

Description:
Find out proxy for attachment order, the output contains monthly payment for potential attachment order


Intended purpose:
Indication of people making repayments to MoJ while receiving a benefit as a proxy for attachment order
Estimate of the amount of money deducted via attachment orders.

Notes:
1. Date range for table [moj_debt_full_summary_trimmed] is Dec2010 - Dec2020.
   The balance in 2011 has no change for every month, we discard all data pre-2012.

2. MoJ staffs shared the information that attachment orders possibly inferred by person is on 
   benefit and is making repayment to Moj



Issues & limitation:

1. The attachment order indicator created in this file is just an estimator."An attachment order tells 
   an employer or Work and Income to transfer money from the debtor's wage or benefit to the creditor." 
   AS we create the AO indicator without taking wage into account, there is a potential that the attachment 
   order has been underestimated.

2. If the creditor and debtor agree at the hearing when the judgement order is made, the debtor must 
   both agree on:
   "(1) how much will be deducted;
    (2) how often it will be deducted: weekly, fornightly or monthly."
   
   The information above (from justice website) implys that an attachment order may have regularly payment
   with consistent amount. However, it has been observed that records with irregular payment at random 
   month has been recorded as attachment order.


Parameters & Present values:
  Current refresh = 20201020
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]
  start_date = 2019-01-01
  end_date   = 2020-12-31

History:
2021-06-14 FL
**************************************************************************************************/



/******************************************
Prior to use, copy to sandpit and index
(runtime 2 minutes)
******************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed];
GO

SELECT *
      ,EOMONTH(date_month_start) AS date_month_end
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed]
FROM(
	SELECT *
		  ,DATEFROMPARTS(year_nbr, month_of_year_nbr, 1) AS date_month_start
FROM [IDI_Adhoc].[clean_read_DEBT].[moj_debt_full_summary_trimmed]
WHERE year_nbr >= 2019
AND year_nbr <= 2020
) a

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed] ([moj_ppn]);
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

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_summary]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_summary];
GO
SELECT b.snz_uid
       ,a.*
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_summary]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed]  a
LEFT JOIN [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_id] b
ON a.moj_ppn = b.moj_ppn

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_summary](snz_uid);
GO

/******************************************************************
Prior to use, save msd spell table to sandpit and filter the data
******************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_spell]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_spell];
GO

SELECT [snz_uid]
      ,COALESCE([msd_spel_servf_code], 'null') AS [msd_spel_servf_code]
      ,COALESCE([msd_spel_add_servf_code], 'null') AS [msd_spel_add_servf_code] 
      ,[msd_spel_spell_start_date] AS [start_date]
      ,COALESCE([msd_spel_spell_end_date], '9999-01-01') AS [end_date]
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_spell]
FROM [IDI_Clean_20201020].[msd_clean].[msd_spell]
WHERE [msd_spel_spell_start_date] IS NOT NULL
AND ([msd_spel_spell_end_date] IS NULL
	OR [msd_spel_spell_start_date] <= [msd_spel_spell_end_date])

	/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_spell] (snz_uid);
GO


/******************************************************************************************
Create attachment order indicator

-- table only contains records for those who make payment while receiving benefit
-- method 1
******************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order];
GO
SELECT moj.*
      ,1 AS attachment_order
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_summary] moj
WHERE moj.payment <> 0
AND EXISTS(
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_spell] ben
	WHERE moj.snz_uid = ben.snz_uid
	AND ben.start_date <= moj.date_month_end 
	AND moj.date_month_start <= ben.end_date
)

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order] (snz_uid);
GO



/********************************************************************************************
Monthly attachment order payment
********************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_monthly_payment_AO]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_monthly_payment_AO];
GO

SELECT snz_uid
       ,SUM(IIF([date_month_start] = '2019-01-01', payment, 0)) AS [value_2019Jan]
	   ,SUM(IIF([date_month_start] = '2019-02-01', payment, 0)) AS [value_2019Feb]
	   ,SUM(IIF([date_month_start] = '2019-03-01', payment, 0)) AS [value_2019Mar]
	   ,SUM(IIF([date_month_start] = '2019-04-01', payment, 0)) AS [value_2019Apr]
	   ,SUM(IIF([date_month_start] = '2019-05-01', payment, 0)) AS [value_2019May]
	   ,SUM(IIF([date_month_start] = '2019-06-01', payment, 0)) AS [value_2019Jun]
	   ,SUM(IIF([date_month_start] = '2019-07-01', payment, 0)) AS [value_2019Jul]
	   ,SUM(IIF([date_month_start] = '2019-08-01', payment, 0)) AS [value_2019Aug]
	   ,SUM(IIF([date_month_start] = '2019-09-01', payment, 0)) AS [value_2019Sep]
	   ,SUM(IIF([date_month_start] = '2019-10-01', payment, 0)) AS [value_2019Oct]
	   ,SUM(IIF([date_month_start] = '2019-11-01', payment, 0)) AS [value_2019Nov]
	   ,SUM(IIF([date_month_start] = '2019-12-01', payment, 0)) AS [value_2019Dec]
	   ,SUM(IIF([date_month_start] = '2020-01-01', payment, 0)) AS [value_2020Jan]
	   ,SUM(IIF([date_month_start] = '2020-02-01', payment, 0)) AS [value_2020Feb]
	   ,SUM(IIF([date_month_start] = '2020-03-01', payment, 0)) AS [value_2020Mar]
	   ,SUM(IIF([date_month_start] = '2020-04-01', payment, 0)) AS [value_2020Apr]
	   ,SUM(IIF([date_month_start] = '2020-05-01', payment, 0)) AS [value_2020May]
	   ,SUM(IIF([date_month_start] = '2020-06-01', payment, 0)) AS [value_2020Jun]
	   ,SUM(IIF([date_month_start] = '2020-07-01', payment, 0)) AS [value_2020Jul]
	   ,SUM(IIF([date_month_start] = '2020-08-01', payment, 0)) AS [value_2020Aug]
	   ,SUM(IIF([date_month_start] = '2020-09-01', payment, 0)) AS [value_2020Sep]

	   ,SUM(IIF([year_nbr] = 2019, payment, 0)) AS [AO2019]
	   ,SUM(IIF([year_nbr] = 2020, payment, 0)) AS [AO2020]
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_monthly_payment_AO]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order]
GROUP BY snz_uid

CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_monthly_payment_AO] (snz_uid);
GO



/********************************************************************************************
Remove temporary tables
********************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_full_summary_trimmed];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_id]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_id];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_summary]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_summary];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_spell]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_spell];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order]', 'U') IS NOT NULL
DROP TABLE IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order];
GO

/**************************************************************************************************
--Method 2 create attachment order indicator
--equivalent to Method 1

/****************************************************************************************
Join msd spell together with moj debt table to find potential attachment order indicator
****************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order_ind]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order_ind];
GO

SELECT *
       ,IIF(ben_start_date IS NOT NULL AND payment <> 0, 1, 0)AS attachment_order
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order_ind] 
FROM (
SELECT moj.*
	  ,start_date AS ben_start_date
	  ,end_date AS ben_end_date
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_debt_summary] moj
LEFT JOIN  [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_spell] ben
ON  moj.snz_uid = ben.snz_uid
AND ((start_date <= date_month_start AND date_month_start <= end_date)
OR (start_date <= date_month_end AND date_month_end <= end_date)
OR (date_month_start <= start_date AND end_date <= date_month_end))
)a


/****************************************************************************************
Remove deplicates moj debt

The reason of duplicates: the month of moj debt repayments may be associated with more than
one benefit spells
****************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order];
GO
SELECT snz_uid, moj_ppn, delta, outstanding_balance, penalty, impositions, payment, remittals,
         payment_reversal, remittal_reversal, date_month_start, date_month_end, attachment_order
INTO  [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order]
FROM  [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_attachment_order_ind] 
GROUP BY snz_uid, moj_ppn, delta, outstanding_balance, penalty, impositions, payment, remittals,
         payment_reversal, remittal_reversal, date_month_start, date_month_end, attachment_order

**************************************************************************************************/





