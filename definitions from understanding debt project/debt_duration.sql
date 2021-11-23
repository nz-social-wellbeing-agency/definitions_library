/**************************************************************************************************
Title: Duration of debt
Author: Simon Anastasiadis
Reviewer: Marianna Pekar

Inputs & Dependencies:
- debt_to_ird.sql --> [IDI_Sandpit].[DL-MAA2020-01].[d2g_ird_debt_cases]
- debt_to_msd.sql --> [IDI_Sandpit].[DL-MAA2020-01].[d2g_msd_debt_cases]
Outputs:
- [IDI_UserCode].[DL-MAA2020-01].[d2g_ird_case_duration]
- [IDI_UserCode].[DL-MAA2020-01].[d2g_msd_case_duration]

Description:
Duration of MSD & IRD debt cases, and indication of whether
debt is long term.

Intended purpose:
Constructing a distribution of debt duration.
Identifying long term debtors.

Notes:
1) Measures of durations are imperfect for both MSD and IRD.
   For MSD we had to construct cases, and approximate end dates.
   For IRD there are differences between assessed dates and case dates.
2) This code considers debt cases separately. As debtors can have overlapping
   debt cases an individual can be in debt for a much longer period of time
   than the duration of any single debt case.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = d2g_
  Project schema = [DL-MAA2020-01]
  Long term debt duration (days) = 1000
 
Issues:
 
History (reverse order):
2020-07-21 MP QA
2020-07-03 SA v1
**************************************************************************************************/

USE IDI_UserCode
GO

/* remove views */
IF OBJECT_ID('[DL-MAA2020-01].[d2g_msd_case_duration]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2g_msd_case_duration];
GO
IF OBJECT_ID('[DL-MAA2020-01].[d2g_ird_case_duration]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2g_ird_case_duration];
GO

/* MSD durations */
CREATE VIEW [DL-MAA2020-01].[d2g_msd_case_duration] AS
SELECT *
	,DATEDIFF(DAY, debt_start_date, debt_end_date) AS days_debt
	,IIF(DATEDIFF(DAY, debt_start_date, debt_end_date) > 1000, 1, 0) AS long_term_debt
FROM IDI_Sandpit.[DL-MAA2020-01].d2g_msd_debt_cases
WHERE debt_end_date IS NOT NULL
AND YEAR(debt_end_date) <> 9999
AND debt_start_date <> debt_end_date;
GO

/* IRD durations */
CREATE VIEW [DL-MAA2020-01].[d2g_ird_case_duration] AS
SELECT *
	  ,DATEDIFF(DAY, [dbt_date_begin], [dbt_date_end]) AS days_debt
	  ,IIF(DATEDIFF(DAY, [dbt_date_begin], [dbt_date_end]) > 1000, 1, 0) AS long_term_debt
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2g_ird_debt_cases]
WHERE dbt_date_end IS NOT NULL
AND YEAR(dbt_date_end) <> 9999
AND dbt_date_begin <> dbt_date_end;
GO
