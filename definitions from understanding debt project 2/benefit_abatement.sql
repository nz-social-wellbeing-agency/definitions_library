/**************************************************************************************************
Title: Benefit abetement
Author: Freya Li
Reviewer: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[ir_clean].[ird_ems] 

Outputs:
- [DL-MAA2020-01].[d2gP2_ben_abatement]

Description:
Number of month receiving both W&S and BEN
Abatement indicator

Intended purpose:
Indication of people receiving W&S and BEN concurrently as a proxy for benefit abatemnet.

Notes:
1. Date range for table [IDI_Clean].[ir_clean].[ird_ems]: 1999-04-30  --- 2020-08-31. (A few obervation
   with the year of date bigger than 2020).
   The observations with the year of the date bigger than 2020 has been treated as outlier and won't 
   be considered in the analysis.

2. An individual may have multiple records at one month with the same income source code

Parameters & Present values:
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]
  Earliest start date = '2019-01-31'
  Latest end date = '2020-08-31'
 

History:
2021-07-02 SA - QA complete
2021-06-15 FL
**************************************************************************************************/

/********************************************************
Filter out the variables and time period we don't need
********************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ems]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ems];
GO

SELECT snz_uid
	  ,ir_ems_return_period_date
	  ,ir_ems_gross_earnings_amt 
      ,ir_ems_income_source_code 
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ems]
FROM [IDI_Clean_20201020].[ir_clean].[ird_ems] 
WHERE '2018-12-31' < [ir_ems_return_period_date]
AND [ir_ems_return_period_date] < '2020-10-31'
AND [snz_uid] > 0

CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ems] (snz_uid);
GO

/********************************************************************************************************
Overlap for W&S and BEN 

Find those individuals and dates if they receive both wages & salaries and benefit, and indicate whether
they receive both W&S and BEN at any of the last threee months (Jun2020 - Aug2020).

--takes about 2 mins (remove the amount can save the running time, keep it for now for further investigation)
********************************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_was_ben]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_was_ben];
GO
WITH
/*filter W&S*/
WS AS(
	SELECT [snz_uid]
		  ,[ir_ems_return_period_date]  
		  ,SUM([ir_ems_gross_earnings_amt]) AS ws_amt
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ems]
	WHERE [ir_ems_income_source_code] = 'W&S'
	GROUP BY [snz_uid], [ir_ems_return_period_date]
),
/*filter BEN*/
BEN AS(
	SELECT [snz_uid]
		  ,[ir_ems_return_period_date]	   
		  ,SUM([ir_ems_gross_earnings_amt]) AS ben_amt
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ems]
	WHERE [ir_ems_income_source_code] = 'BEN'
	GROUP BY [snz_uid], [ir_ems_return_period_date]
)
SELECT WS.[snz_uid]
       ,WS.[ir_ems_return_period_date]
	   ,[ws_amt]
	   ,[ben_amt]
	   ,IIF(BEN.[ir_ems_return_period_date] IN ('2020-06-30', '2020-07-31', '2020-08-31'), 1, 0) AS recent_months
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_was_ben]
FROM WS 
INNER JOIN BEN
ON WS.[snz_uid] = BEN.[snz_uid]
AND WS.[ir_ems_return_period_date] = BEN.[ir_ems_return_period_date]
/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_was_ben] ([snz_uid]);
GO


/***************************************************************************************
Benefit abetement indicator
and
number of month with W&S and BEN between Jan2019 and Aug2020
***************************************************************************************/
USE [IDI_UserCode]
GO

/*number of month each individual receive both W&S and BEN between Jan2019 and Aug2020*/
IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_ben_abatement]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2gP2_ben_abatement];
GO
CREATE VIEW [DL-MAA2020-01].[d2gP2_ben_abatement] AS
SELECT snz_uid 
      ,COUNT(snz_uid) AS ws_ben_num
	  ,IIF(SUM(recent_months)>0, 1, NULL) AS abatement_ind -- if an individual have W&S and BEN concurrently at one of the last three months
FROM  [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_was_ben]
GROUP BY [snz_uid]
GO

/********************************************************************
Remove temporary table
********************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ems]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ems];
GO



