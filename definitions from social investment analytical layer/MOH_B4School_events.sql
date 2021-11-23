/**************************************************************************************************
Title: MOH B4School check events
Author: V Benny

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].b4sc
- moh_b4sc_pricing.csv
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[SIAL_MOH_B4School_events]

Description:
Create B4 School Check events table into SIAL format

Notes:
0) This definition originates in the SIAL. The SIAL was retired mid-2020
   and is no longer supported. This definition has been provided for
   researchers wanting to contiune to use this SIAL definition.
1) See SIAL data dictionary for original documentation of business rules.
2) For loading CSV file, SQL requires network path. Drive letter will fail.
   Example:
   Windows explorer shows "MAA (\\server\server_folder) (I:)"
   Becomes "\\server\server_folder\MAA\path_to_csv\file.csv"

Parameters & Present values:
  Current refresh = 20200120
  Prefix = sial_
  Project schema = [DL-MAA2016-15]
  location of csv cost file = '\\prtprdsasnas01\DataLab\MAA\project folder\subfolder\SIAL'

Issues:

History (reverse order):
2020-10-14 Simon A: recode into SQL
2019-08-01 Peter Holmes: Added a SELECT statement to ensure the user has access to the underlying IDI tables. This will show up in the log
2016-07-22 V Benny: Created
**************************************************************************************************/

/******************************* load pricing table *******************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[sial_B4SC_PRICING]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_B4SC_PRICING];
GO

SET DATEFORMAT DMY

CREATE TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_B4SC_PRICING] (
	b4sc_code CHAR(4),
	b4sc_type CHAR(13),
	fin_year CHAR(7),
	b4sc_spend INT,
	[start_date] DATE,
	[end_date] DATE,
)

BULK INSERT [IDI_Sandpit].[DL-MAA2016-15].[sial_B4SC_PRICING]
FROM '\\prtprdsasnas01\DataLab\MAA\project folder\subfolder\SIAL\moh_b4sc_pricing.csv'
WITH
(
	DATAFILETYPE = 'char',
	CODEPAGE = 'RAW',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
)

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[SIAL_MOH_B4School_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[SIAL_MOH_B4School_events];
GO

CREATE VIEW [DL-MAA2016-15].[SIAL_MOH_B4School_events] AS
SELECT 
	b4sc.snz_uid, 
	'MOH' AS department,
	'B4S' AS datamart,
	'B4S' AS subject_area,
	CAST(mindt.[start_date] AS DATETIME) AS [start_date],
	CAST(b4sc.moh_bsc_check_date AS DATETIME) AS [end_date],
	coverage.per_peron_amt AS cost,
	b4sc.moh_bsc_check_status_text AS event_type
FROM [IDI_Clean_20200120].[moh_clean].b4sc b4sc
INNER JOIN ( /* get the earliest test date for the child under the B4SC programme, AND use AS start date */
	SELECT snz_uid, MIN([start_date]) AS [start_date]
	FROM (
		SELECT snz_uid, coalesce(moh_bsc_general_date, CAST('9999-12-31' AS date)) AS [start_date] FROM [IDI_Clean_20200120].[moh_clean].b4sc UNION ALL
		SELECT snz_uid, coalesce([moh_bsc_vision_date], CAST('9999-12-31' AS date)) AS [start_date] FROM [IDI_Clean_20200120].[moh_clean].b4sc UNION ALL
		SELECT snz_uid, coalesce([moh_bsc_hearing_date], CAST('9999-12-31' AS date)) AS [start_date] FROM [IDI_Clean_20200120].[moh_clean].b4sc UNION ALL
		SELECT snz_uid, coalesce([moh_bsc_growth_date], CAST('9999-12-31' AS date)) AS [start_date] FROM [IDI_Clean_20200120].[moh_clean].b4sc UNION ALL
		SELECT snz_uid, coalesce([moh_bsc_dental_date], CAST('9999-12-31' AS date)) AS [start_date] FROM [IDI_Clean_20200120].[moh_clean].b4sc UNION ALL
		SELECT snz_uid, coalesce([moh_bsc_imms_date], CAST('9999-12-31' AS date)) AS [start_date] FROM [IDI_Clean_20200120].[moh_clean].b4sc UNION ALL
		SELECT snz_uid, coalesce([moh_bsc_peds_date], CAST('9999-12-31' AS date)) AS [start_date] FROM [IDI_Clean_20200120].[moh_clean].b4sc UNION ALL
		SELECT snz_uid, coalesce([moh_bsc_sdqp_date], CAST('9999-12-31' AS date)) AS [start_date] FROM [IDI_Clean_20200120].[moh_clean].b4sc UNION ALL
		SELECT snz_uid, coalesce([moh_bsc_sdqt_date], CAST('9999-12-31' AS date)) AS [start_date] FROM [IDI_Clean_20200120].[moh_clean].b4sc
	) x
	GROUP BY snz_uid
) mindt
ON b4sc.snz_uid = mindt.snz_uid
/* get the count of children for the financial year, AND divide the total allocation for this year by the count */
LEFT JOIN ( 
	SELECT pr.[start_date], pr.end_date, pr.b4sc_spend/count(snz_uid) AS per_peron_amt
	FROM [IDI_Clean_20200120].moh_clean.b4sc  AS b4sc
	INNER JOIN [IDI_Sandpit].[DL-MAA2016-15].[sial_B4SC_PRICING] pr
	ON b4sc.moh_bsc_check_date BETWEEN pr.[start_date] AND pr.[end_date]
	WHERE moh_bsc_check_status_text IN ('Closed','Completed')
	GROUP BY pr.[start_date], pr.[end_date], pr.[b4sc_spend]
) coverage 
ON b4sc.moh_bsc_check_date between coverage.[start_date] AND coverage.[end_date]
GO
