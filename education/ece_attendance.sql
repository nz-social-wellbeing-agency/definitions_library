/**************************************************************************************************
Title: ECE attendance
Author: Simon Anastasiadis

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
Recorded attendance at an ECE centre.

Intended purpose:
Identifying who has attended Early Childhood Education and when they attended.

Inputs & Dependencies:
- [IDI_Adhoc].[clean_read_MOE].[StudentAttendance]
- [IDI_Clean].[security].[concordance]
Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[defn_ece_attendance]

Notes:
1) Dataset is one row per attendance, not spells of enrollment.
   Hence to determine whether a child has been regularly attending ECE
   you will need to could records and apply some threshold/check.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]
  Earliest start date = '2016-01-01'
 
Issues:
 
History (reverse order):
2020-05-25 SA v1
**************************************************************************************************/

/* Clear table */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA20XX-YY].[defn_ece_attendance]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[defn_ece_attendance];
GO

SELECT c.[snz_uid]
	  ,a.[snz_moe_uid]
      ,a.[ProviderNumber]
      ,CAST(a.[AttendanceDate] AS DATE) AS [AttendanceDate]
      ,a.[ECEAttendanceCode]
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_ece_attendance]
FROM [IDI_Adhoc].[clean_read_MOE].[StudentAttendance] a
INNER JOIN [IDI_Clean_YYYYMM].[security].[concordance] c
ON a.[snz_moe_uid] = c.[snz_moe_uid]
WHERE a.ECEAttendanceCode = 'Present'
AND a.[snz_moe_uid] IS NOT NULL
AND CAST(a.[AttendanceDate] AS DATE) >= '2016-01-01'

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[defn_ece_attendance] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[defn_ece_attendance] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO