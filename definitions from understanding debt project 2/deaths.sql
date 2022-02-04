/**************************************************************************************************
Title: Dates of death
Author: Simon Anastasiadis
Re-edit: Freya Li
Reviewer: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[data].[personal_detail]
Outputs:
- [IDI_UserCode].[DL-MAA2020-01].[d2gP2_death]

Description:
The date we can be confident that a person is dead from.

Intended purpose:
Suitable for creating indicators for when/whether a person has died.
Counting the number of days a person has been dead for.
 
Notes:
1) Only year and month of death are available in the IDI. Day of death is considered identifying.
   Hence all death spells start on the 28th of the month. The 28th has been chosen because
   all months has a 28th day, and most people who die within a month will have died by the 28th.

Parameters & Present values:
  Current refresh = 20201020
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]
 
Issues:
 
History (reverse order):
2021-01-26 SA QA
2021-01-12 FL (Change prefix, update the table to the latest refresh)
2020-07-21 MP QA
2020-02-28 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_death]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2gP2_death];
GO

/* Create view */
CREATE VIEW [DL-MAA2020-01].[d2gP2_death] AS
SELECT [snz_uid]
	,[snz_deceased_year_nbr]
	,[snz_deceased_month_nbr]
	,[snz_deceased_date_source_code]
	,EOMONTH(DATEFROMPARTS([snz_deceased_year_nbr], [snz_deceased_month_nbr], 28)) AS [event_date]
FROM [IDI_Clean_20201020].[data].[personal_detail]
WHERE [snz_deceased_year_nbr] IS NOT NULL
AND [snz_deceased_month_nbr] IS NOT NULL;
GO

