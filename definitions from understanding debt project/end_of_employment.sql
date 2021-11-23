/**************************************************************************************************
Title: End of employment
Author: Simon Anastasiadis
Reviewer: Joel Bancolita

Inputs & Dependencies:
- [IDI_Clean].[ir_clean].[ird_ems]
Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2g_end_of_employment]

Description:
An event were a peron's employment ends followed by a gap in employment.
The event is the end date of employment where:
- they are never subsequently employed/paid by the same employer
  (this controls for periodic / occassional work)
- there is no income from wages & salaries in the next month
  (suggesting a person finished employment without a new role lined up)

Intended purpose:
As a proxy for job loss.
 
Notes:
1) Employer Monthly Summaries (EMS) records provide an indication that a person was employed
   during a specific month. These are not used - only the last day of the month is used.
2) Self employment does not appear in this definition.
3) We exclude the last date of every person's employment/EMS history as this is likely to
   reflect an event we are not intersted in (e.g. end of dataset, never works again).
4) No control for non-job loss explanations for stopping work, such as retirement,
   parental/caring responsibilities, travel overseas.
5) A placeholder identity exists where the encrypted IRD number [snz_ird_uid] is equal to
   zero. Checking across refreshes suggests this is people without an IRD number. We exclude
   this identity.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = d2g_
  Project schema = [DL-MAA2020-01]
 
Issues:

History (reverse order):
2020-07-22 JB QA
2020-03-05 SA v1
**************************************************************************************************/


/* Clear existing table */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2g_end_of_employment]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2g_end_of_employment];
GO

WITH possible_ends AS (

SELECT a.[snz_uid]
	,MAX(a.[ir_ems_return_period_date]) AS [event_date]
	,a.[snz_employer_ird_uid]
FROM [IDI_Clean_20200120].[ir_clean].[ird_ems] a
WHERE [ir_ems_income_source_code] = 'W&S'
AND a.[snz_ird_uid] <> 0 -- exclude placeholder person without IRD number
GROUP BY a.[snz_uid], a.[snz_employer_ird_uid]

),
final_ends AS (

SELECT snz_uid
	,MAX([ir_ems_return_period_date]) AS [final_date]
FROM [IDI_Clean_20200120].[ir_clean].[ird_ems]
WHERE [ir_ems_income_source_code] = 'W&S'
GROUP BY [snz_uid]

),
staging AS (

SELECT a.[snz_uid]
	,a.[event_date]
	,a.[snz_employer_ird_uid]
	,b.[final_date]
	,c.[snz_uid] AS has_income_next_month
FROM possible_ends a
INNER JOIN final_ends b
ON a.snz_uid = b.snz_uid
LEFT JOIN [IDI_Clean_20200120].[ir_clean].[ird_ems] c
ON a.snz_uid = c.snz_uid
AND DATEDIFF(MONTH, a.[event_date], c.[ir_ems_return_period_date]) = 1 
AND c.[ir_ems_income_source_code] = 'W&S'

)
SELECT DISTINCT [snz_uid]
	,[event_date]
	,[snz_employer_ird_uid]
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2g_end_of_employment]
FROM staging
WHERE [event_date] <> [final_date]
AND has_income_next_month IS NULL
GO

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2g_end_of_employment] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2g_end_of_employment] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO



/* Previous method that allowed for re-employment by the same employer
But had very slow runtime, > 70 minutes */

/*
SELECT a.[snz_uid]
	,CASE WHEN a.[ir_ems_employee_end_date] IS NOT NULL
			AND a.[ir_ems_employee_end_date] < a.[ir_ems_return_period_date]
			AND (a.[ir_ems_employee_start_date] IS NULL OR a.[ir_ems_employee_start_date] < a.[ir_ems_employee_end_date])
			AND DATEDIFF(DAY, a.[ir_ems_employee_end_date], a.[ir_ems_return_period_date]) < 27 -- employee finished in the last month
	THEN a.[ir_ems_employee_end_date] 
	ELSE a.[ir_ems_return_period_date] END AS [event_date]
	,a.[snz_employer_ird_uid]
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2g_end_of_employment]
FROM [IDI_Clean_20200120].[ir_clean].[ird_ems] a
LEFT JOIN (
	SELECT snz_uid, MAX([ir_ems_return_period_date]) AS [ir_ems_return_period_date]
	FROM [IDI_Clean_20200120].[ir_clean].[ird_ems]
	WHERE [ir_ems_income_source_code] = 'W&S'
	GROUP BY [snz_uid]
) d
ON a.[snz_uid] = d.[snz_uid]
WHERE [ir_ems_income_source_code] = 'W&S'
AND a.[snz_ird_uid] <> 0 -- exclude placeholder person without IRD number

AND NOT EXISTS (
	SELECT 1
	FROM [IDI_Clean_20200120].[ir_clean].[ird_ems] b
	WHERE a.[snz_uid] = b.[snz_uid]
	AND b.[ir_ems_income_source_code] = 'W&S'
	AND (
		-- no W&S from same employer within 6 months 
		(a.[snz_employer_ird_uid] = b.[snz_employer_ird_uid] AND DATEDIFF(MONTH, a.[ir_ems_return_period_date], b.[ir_ems_return_period_date]) BETWEEN 1 AND 6)
		OR
		-- no W&S in next month 
		(DATEDIFF(MONTH, a.[ir_ems_return_period_date], b.[ir_ems_return_period_date]) = 1)
	)
)

-- exclude last date in person's record
AND d.[ir_ems_return_period_date] <> a.[ir_ems_return_period_date];
GO
*/
