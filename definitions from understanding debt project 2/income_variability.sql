/**************************************************************************************************
Title: monthly income and income variabilirty
Author: Freya Li
Reviewer: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[ir_clean].[ird_ems]

Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_income_variability]


Description:
income variability


Intended purpose:
Measures of income stability and variability over time


Notes:
1. Date range for table [IDI_Clean].[ir_clean].[ird_ems]: 1999-04-30  --- 2020-08-31. (A few obervation
   with the year of date bigger than 2020).
   The observations with the year of the date bigger than 2020 has been treated as outlier and won't 
   be considered in the analysis.

2. An individual may have multiple records at one month with the same income source code

3. Standard deviation has been considered to measure income variability. However, two individuals may have the same standard 
   deviation but different levels of income variability. For example
   ID income1 income2
   xx 1000    2000
   yy 10000   11000
   Both individuals xx and yy have standard deviation 500, but xx's income increases 100%, while yy's income only increases 10%
   Hence, log transformation is nessecary.

   Another possible measure is Mean log deviation (MLD), which is a measure of inequality.
   MLD = log(mean(x)) - mean(log(x))
   The MLD is zero when the incomes are same, and takes on larger positive values as incomes become more unequal.

4. For majorities, there is a significant drop of the income on 2020 Aug. For all the population, the average monthly income is
   between $3000 - $4000 from Jan 2019 to Jul 2020, while it dorps to <$1000 on 2020 Aug. Thus, we excluded 2020 Aug when measuring
   the income variability. 

5. There are around 500,000 people have zero incomes every month except 2020 Aug (over 1 million people). Individuals may have 
   zero incomes overtime, most of the zero incomes seems are correctly recorded. 

6. The threshold of income variability has been considered as MLD = 0.5, it doesn't means those people who has MLD = 0.4 receiving 
   stable income, it means those people's income has less variability with MLD < 0.5 compare with those who have MLD > 0.5.

Issues and limitations:
1. For the ease of log transformation, if income is 0, 0.1 will repalce -Inf (log(0)). Note we cannot set zero incomes as NULL, because 
   it will fail to measure the income variability for those people who have stable non-zero income, then the income changes to zero.
   Further study on this may required.
2. We want zero income records when people have no income. Current approach ensures this, but implicitly pivots `SUM(IIF(...))` and
   unpivots data (UNION ALL). If using this approach further, recommend improving defn by changing data preparation.

Parameters & Present values:
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]
  Earliest start date = '2019-01-31'
  Latest end date = '2020-08-31'
 

History:
2021-09-21 SA review
2021-01-07 FL
**************************************************************************************************/
USE IDI_UserCode
GO

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


/********************************************************************************************
Monthly income (including all the source)

-- slow, takes about 4 mins
********************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income];
GO

SELECT snz_uid
      ,SUM(IIF([ir_ems_return_period_date] = '2019-01-31', [ir_ems_gross_earnings_amt], 0)) AS [value_2019Jan]
	  ,SUM(IIF([ir_ems_return_period_date] = '2019-02-28', [ir_ems_gross_earnings_amt], 0)) AS [value_2019Feb]
	  ,SUM(IIF([ir_ems_return_period_date] = '2019-03-31', [ir_ems_gross_earnings_amt], 0)) AS [value_2019Mar]
	  ,SUM(IIF([ir_ems_return_period_date] = '2019-04-30', [ir_ems_gross_earnings_amt], 0)) AS [value_2019Apr]
	  ,SUM(IIF([ir_ems_return_period_date] = '2019-05-31', [ir_ems_gross_earnings_amt], 0)) AS [value_2019May]
	  ,SUM(IIF([ir_ems_return_period_date] = '2019-06-30', [ir_ems_gross_earnings_amt], 0)) AS [value_2019Jun]
	  ,SUM(IIF([ir_ems_return_period_date] = '2019-07-31', [ir_ems_gross_earnings_amt], 0)) AS [value_2019Jul]
	  ,SUM(IIF([ir_ems_return_period_date] = '2019-08-31', [ir_ems_gross_earnings_amt], 0)) AS [value_2019Aug]
	  ,SUM(IIF([ir_ems_return_period_date] = '2019-09-30', [ir_ems_gross_earnings_amt], 0)) AS [value_2019Sep]
	  ,SUM(IIF([ir_ems_return_period_date] = '2019-10-31', [ir_ems_gross_earnings_amt], 0)) AS [value_2019Oct]
	  ,SUM(IIF([ir_ems_return_period_date] = '2019-11-30', [ir_ems_gross_earnings_amt], 0)) AS [value_2019Nov]
	  ,SUM(IIF([ir_ems_return_period_date] = '2019-12-31', [ir_ems_gross_earnings_amt], 0)) AS [value_2019Dec]

	  ,SUM(IIF([ir_ems_return_period_date] = '2020-01-31', [ir_ems_gross_earnings_amt], 0)) AS [value_2020Jan]
	  ,SUM(IIF([ir_ems_return_period_date] = '2020-02-29', [ir_ems_gross_earnings_amt], 0)) AS [value_2020Feb]
	  ,SUM(IIF([ir_ems_return_period_date] = '2020-03-31', [ir_ems_gross_earnings_amt], 0)) AS [value_2020Mar]
	  ,SUM(IIF([ir_ems_return_period_date] = '2020-04-30', [ir_ems_gross_earnings_amt], 0)) AS [value_2020Apr]
	  ,SUM(IIF([ir_ems_return_period_date] = '2020-05-31', [ir_ems_gross_earnings_amt], 0)) AS [value_2020May]
	  ,SUM(IIF([ir_ems_return_period_date] = '2020-06-30', [ir_ems_gross_earnings_amt], 0)) AS [value_2020Jun]
	  ,SUM(IIF([ir_ems_return_period_date] = '2020-07-31', [ir_ems_gross_earnings_amt], 0)) AS [value_2020Jul]
	  ,SUM(IIF([ir_ems_return_period_date] = '2020-08-31', [ir_ems_gross_earnings_amt], 0)) AS [value_2020Aug]
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ems]
GROUP BY [snz_uid]

CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income] (snz_uid);
GO

/********************************************************************************************
calculate standard deviation
********************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_income_variability]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_income_variability];
GO
SELECT [snz_uid]
      ,STDEV([log_inc_19]) AS [inc_sd_19]
	  ,STDEV([log_inc_20]) AS [inc_sd_20]
	  ,IIF(AVG([inc_19]) <> 0, LOG(AVG([inc_19])) - AVG(log_inc_19), NULL) AS MLD_2019
	  ,IIF(AVG([inc_20]) <> 0, LOG(AVG([inc_20])) - AVG(log_inc_20), NULL) AS MLD_2020
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_income_variability]
FROM(

SELECT [snz_uid] 
      ,'Jan' AS [month]
	  ,[value_2019Jan] AS [inc_19]
	  ,[value_2020Jan] AS [inc_20]
	  ,IIF([value_2019Jan] <> 0, LOG([value_2019Jan]), 0.1) AS [log_inc_19]
	  ,IIF([value_2020Jan] <> 0, LOG([value_2020Jan]), 0.1) AS [log_inc_20]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]
UNION ALL
SELECT [snz_uid]
	  ,'Feb' AS [month]
	  ,[value_2019Feb] AS [inc_19]
	  ,[value_2020Feb] AS [inc_20]
	  ,IIF([value_2019Feb] <> 0, LOG([value_2019Feb]), 0.1) AS [log_inc_19]
	  ,IIF([value_2020Feb] <> 0, LOG([value_2020Feb]), 0.1) AS [log_inc_20]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]
UNION ALL
SELECT [snz_uid]
	  ,'Mar' AS [month]
	  ,[value_2019Mar] AS [inc_19]
	  ,[value_2020Mar] AS [inc_20]
	  ,IIF([value_2019Mar] <> 0, LOG([value_2019Mar]), 0.1) AS [log_inc_19]
	  ,IIF([value_2020Mar] <> 0, LOG([value_2020Mar]), 0.1) AS [log_inc_20]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]
UNION ALL
SELECT [snz_uid]
	  ,'Apr' AS [month_year]
	  ,[value_2019Apr] AS [inc_19]
	  ,[value_2020Apr] AS [inc_20]
	  ,IIF([value_2019Apr] <> 0, LOG([value_2019Apr]), 0.1) AS [log_inc_19]
	  ,IIF([value_2020Apr] <> 0, LOG([value_2020Apr]), 0.1) AS [log_inc_20]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]
UNION ALL
SELECT [snz_uid]
	  ,'May' AS [month_year]
	  ,[value_2019May] AS [inc_19]
	  ,[value_2020May] AS [inc_20]
	  ,IIF([value_2019May] <> 0, LOG([value_2019May]), 0.1) AS [log_inc_19]
	  ,IIF([value_2020May] <> 0, LOG([value_2020May]), 0.1) AS [log_inc_20]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]
UNION ALL
SELECT [snz_uid]
	  ,'Jun' AS [month_year]
	  ,[value_2019Jun] AS [inc_19]
	  ,[value_2020Jun] AS [inc_20]
	  ,IIF([value_2019Jun] <> 0, LOG([value_2019Jun]), 0.1) AS [log_inc_19]
	  ,IIF([value_2020Jun] <> 0, LOG([value_2020Jun]), 0.1) AS [log_inc_20]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]
UNION ALL
SELECT [snz_uid]
	  ,'Jul' AS [month_year]
	  ,[value_2019Jul] AS [inc_19]
	  ,[value_2020Jul] AS [inc_20]
	  ,IIF([value_2019Jul] <> 0, LOG([value_2019Jul]), 0.1) AS [log_inc_19]
	  ,IIF([value_2020Jul] <> 0, LOG([value_2020Jul]), 0.1) AS [log_inc_20]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]
UNION ALL
SELECT [snz_uid]
	  ,'Aug' AS [month_year]
	  ,[value_2019Aug] AS [inc_19]
	  ,NULL AS [inc_20]
	  ,IIF([value_2019Aug] <> 0, LOG([value_2019Aug]), 0.1) AS [log_inc_19]
	  ,NULL AS [log_inc_20]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]
UNION ALL
SELECT [snz_uid]
	  ,'Sep' AS [month_year]
	  ,[value_2019Sep] AS [inc_19]
	  ,NULL AS [inc_20]
	  ,IIF([value_2019Sep] <> 0, LOG([value_2019Sep]), 0.1) AS [log_inc_19]
	  ,NULL AS [log_inc_20]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]
UNION ALL
SELECT [snz_uid]
	  ,'Oct' AS [month_year]
	  ,[value_2019Oct] AS [inc_19]
	  ,NULL AS [inc_20]
	  ,IIF([value_2019Oct] <> 0, LOG([value_2019Oct]), 0.1) AS [log_inc_19]
	  ,NULL AS [log_inc_20]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]
UNION ALL
SELECT [snz_uid]
	  ,'Nov' AS [month_year]
	  ,[value_2019Nov] AS [inc_19]
	  ,NULL AS [inc20]
	  ,IIF([value_2019Nov] <> 0, LOG([value_2019Nov]), 0.1) AS [log_inc_19]
	  ,NULL AS [log_inc_20]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]
UNION ALL
SELECT [snz_uid]
	  ,'Dec' AS [month_year]
	  ,[value_2019Dec] AS [inc_19]
	  ,NULL AS [inc_20]
	  ,IIF([value_2019Dec] <> 0, LOG([value_2019Dec]), 0.1) AS [log_inc_19]
	  ,NULL AS [log_inc_20]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]

) long
GROUP BY snz_uid


/********************************************************************
Remove temporary table
********************************************************************/
 
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_monthly_income];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ems]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_temp_ems];
GO
