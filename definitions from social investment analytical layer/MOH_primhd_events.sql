/**************************************************************************************************
Title: MOH PRIMHD events
Author: V Benny

Inputs & Dependencies:
- [IDI_Clean_20200120].[moh_clean].[PRIMHD]
- moh_primhd_pu_pricing.csv
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_MOE_ECE_events]

Description:
Create PRIMHD events table in SIAL format

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
2019-06-01 Peter Holmes: Views now have to be created in the IDI_UserCode Schema in the IDI 
2017-06-16 WJ: Adding for primhd tean type code
2016-07-22 V Benny: Created
**************************************************************************************************/

/******************************* load pricing table *******************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[sial_PRIMHD_PU_PRICING]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_PRIMHD_PU_PRICING];
GO

SET DATEFORMAT DMY

CREATE TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_PRIMHD_PU_PRICING] (
	activity_setting_code CHAR(2),
	activity_setting_desc VARCHAR(40),
	activity_type_code CHAR(3),
	activity_type_desc VARCHAR(90),
	activity_unit_type CHAR(14),
	fin_year CHAR(7),
	type_weight FLOAT,
	setting_weight FLOAT,
	activity_price FLOAT,
	[start_date] DATE,
	[end_date] DATE,
)

BULK INSERT [IDI_Sandpit].[DL-MAA2016-15].[sial_PRIMHD_PU_PRICING]
FROM '\\prtprdsasnas01\DataLab\MAA\project folder\subfolder\SIAL\moh_primhd_pu_pricing.csv'
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

IF OBJECT_ID('[DL-MAA2016-15].[SIAL_MOH_primhd_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[SIAL_MOH_primhd_events];
GO

CREATE VIEW [DL-MAA2016-15].[SIAL_MOH_primhd_events] AS
SELECT snz_uid, 
	'MOH' AS department,
	'PRM' AS datamart,
	'PRM' AS subject_area,
	CAST(moh_mhd_activity_start_date AS DATETIME) AS [start_date],
	CAST(moh_mhd_activity_end_date AS DATETIME) AS [end_date],
	CASE WHEN moh_mhd_activity_unit_type_text = 'SEC' THEN 0.00 
		ELSE price.activity_price*moh_mhd_activity_unit_count_nbr END AS cost,
	moh_mhd_activity_setting_code AS event_type,
	moh_mhd_activity_type_code AS event_type_2,
	moh_mhd_activity_unit_type_text AS event_type_3,
	moh_mhd_team_type_code AS event_type_4,
	moh_mhd_organisation_id_code AS entity_id
FROM [IDI_Clean_20200120].moh_clean.PRIMHD primhd
LEFT JOIN [IDI_Sandpit].[DL-MAA2016-15].[sial_PRIMHD_PU_PRICING] price
ON primhd.moh_mhd_activity_setting_code = price.activity_setting_code 
AND primhd.moh_mhd_activity_type_code = price.activity_type_code 
AND primhd.moh_mhd_activity_unit_type_text=price.activity_unit_type
AND primhd.moh_mhd_activity_start_date BETWEEN price.start_date AND price.end_date
GO
