/**************************************************************************************************
Title: End of employment
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
An event were a peron's employment ends followed by a gap in employment.
The event is the end date of employment where:
- they are never subsequently employed/paid by the same employer
  (this controls for periodic / occassional work)
- there is no income from wages & salaries in the next month
  (suggesting a person finished employment without a new role lined up)

Intended purpose:
As a proxy for job loss.

Inputs & Dependencies:
- [IDI_Clean].[ir_clean].[ird_ems]
Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_end_of_employment]


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
  Current refresh = YYYYMM
  Prefix = d2gP2_
  Project schema = [DL-MAA20XX-YY]
 
Issues:

History (reverse order):
2020-01-26 SA QA
2020_01-11 FL v2 (Change prefix, update the table to the latest refresh)
2020-07-22 JB QA
2020-03-05 SA v1
**************************************************************************************************/


/* Clear existing table */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_end_of_employment];
GO

WITH possible_ends AS (

SELECT a.[snz_uid]
	,MAX(a.[ir_ems_return_period_date]) AS [event_date]
	,a.[snz_employer_ird_uid]
FROM [IDI_Clean_YYYYMM].[ir_clean].[ird_ems] a
WHERE [ir_ems_income_source_code] = 'W&S'
AND a.[snz_ird_uid] <> 0 -- exclude placeholder person without IRD number
GROUP BY a.[snz_uid], a.[snz_employer_ird_uid]

),
final_ends AS (

SELECT snz_uid
	,MAX([ir_ems_return_period_date]) AS [final_date]
FROM [IDI_Clean_YYYYMM].[ir_clean].[ird_ems]
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
LEFT JOIN [IDI_Clean_YYYYMM].[ir_clean].[ird_ems] c
ON a.snz_uid = c.snz_uid
AND DATEDIFF(MONTH, a.[event_date], c.[ir_ems_return_period_date]) = 1 
AND c.[ir_ems_income_source_code] = 'W&S'

)
SELECT DISTINCT [snz_uid]
	,[event_date]
	,[snz_employer_ird_uid]
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_end_of_employment]
FROM staging
WHERE [event_date] <> [final_date]
AND has_income_next_month IS NULL
GO

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_end_of_employment] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[d2gP2_end_of_employment] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO


