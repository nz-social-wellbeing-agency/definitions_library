/**************************************************************************************************
Title: Period a person is alive
Author: Simon Anastasiadis
Re-edit: Freya Li

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Disclaimer:
The definitions provided in this library were determined by the Social Wellbeing Agency to be suitable in the 
context of a specific project. Whether or not these definitions are suitable for other projects depends on the 
context of those projects. Researchers using definitions from this library will need to determine for themselves 
to what extent the definitions provided here are suitable for reuse in their projects. While the Agency provides 
this library as a resource to support IDI research, it provides no guarantee that these definitions are fit for reuse.

Citation:
Social Wellbeing Agency. Definitions library. Source code. https://github.com/nz-social-wellbeing-agency/definitions_library

Description:
The period we can be confident that a person is alive. This is birth to death where both birth and death are available. If death is not available, we assume people do not live beyond 130 years.

Intended purpose:
1. Suitable for creating indicators for when/whether a person is alive.
2. Expected to use to filter datasets for whether people are alive.

Inputs & Dependencies:
- [IDI_Clean].[data].[personal_detail]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[defn_alive]

Notes:
1) Only year and month of death are available in the IDI. Day of birth and day of death
   are considered identifying. Hence all births happen on the 15th of the month and
   all deaths happen on the 28th.
2) Future births and deaths are excluded. This is applied via a filter on the year of
   birth and year of death.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]
  Limit on future births & deaths = 2021

Issues:
 
History (reverse order):
2022-10-20 SA merge w deaths defn
2022-05-07 VW Point to DL-MAA20XX-YY, update to latest refresh (202203)
2022-02-21 VW Point to DL-MAA20XX-YY
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
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[defn_alive];
GO

/* Create view */
CREATE VIEW [DL-MAA20XX-YY].[defn_alive] AS
SELECT *
FROM (
	SELECT snz_uid
		,EOMONTH([snz_birth_date_proxy]) AS [start_date]
		,IIF( [snz_deceased_year_nbr] IS NOT NULL AND [snz_deceased_month_nbr] IS NOT NULL,
			EOMONTH(DATEFROMPARTS([snz_deceased_year_nbr], [snz_deceased_month_nbr], 15)),
			EOMONTH(DATEFROMPARTS([snz_birth_year_nbr] + 130, [snz_birth_month_nbr], 15))) AS [end_date]
		,[snz_birth_year_nbr]
		,[snz_birth_month_nbr]
		,[snz_deceased_year_nbr]
		,[snz_deceased_month_nbr]
	FROM [IDI_Clean_YYYYMM].[data].[personal_detail]
	WHERE [snz_person_ind] = 1
	AND [snz_birth_year_nbr] IS NOT NULL
	AND [snz_birth_month_nbr] IS NOT NULL
	AND [snz_birth_year_nbr] <= YEAR(GETDATE())
) k
WHERE [start_date] <= [end_date];
GO
