/**************************************************************************************************
Title: Period a person is alive
Author: Simon Anastasiadis
Re-edit: Freya Li
Reviewer: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean_202203].[data].[personal_detail]
Outputs:
- [IDI_UserCode].[DL-MAA2021-60].[defn_alive]

Description:
The period we can be confident that a person is alive.
This is birth to death where both birth and death are available.
If death is not available, we assume people do not live beyond 130 years.

Intended purpose:
Suitable for creating indicators for when/whether a person is alive.
Expected to use to filter datasets for whether people are alive.
 
Notes:
1) Only year and month of death are available in the IDI. Day of birth and day of death
   are considered identifying. Hence all births happen on the 15th of the month and
   all deaths happen on the 28th.
2) Future births and deaths are excluded. This is applied via a filter on the year of
   birth and year of death.

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]
  Limit on future births & deaths = 2021

Issues:
 
History (reverse order):
2022-05-07 VW Point to DL-MAA2018-48, update to latest refresh (202203)
2022-02-21 VW Point to DL-MAA2021-60
2021-11-22 MR Update latest refresh (20211020)
2021-01-26 SA QA
2021-01-09 FL v2 (Change prefix and update the table to the latest refresh)
2020-07-22 JB QA
2020-07-16 MP QA
2020-02-28 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA2018-48].[defn_alive]','V') IS NOT NULL
DROP VIEW [DL-MAA2018-48].[defn_alive];
GO

/* Create view */
CREATE VIEW [DL-MAA2018-48].[defn_alive] AS
SELECT *
FROM (
	SELECT snz_uid
		,EOMONTH([snz_birth_date_proxy]) AS [start_date]
		,IIF( [snz_deceased_year_nbr] IS NOT NULL AND [snz_deceased_month_nbr] IS NOT NULL,
			EOMONTH(DATEFROMPARTS([snz_deceased_year_nbr], [snz_deceased_month_nbr], 1)),
			EOMONTH(DATEFROMPARTS([snz_birth_year_nbr] + 130, [snz_birth_month_nbr], 1))) AS [end_date]
	FROM [IDI_Clean_202203].[data].[personal_detail]
	WHERE [snz_person_ind] = 1
	AND [snz_birth_year_nbr] IS NOT NULL
	AND [snz_birth_month_nbr] IS NOT NULL
	AND [snz_birth_year_nbr] <= YEAR(GETDATE())
) k
WHERE [start_date] <= [end_date];
GO
