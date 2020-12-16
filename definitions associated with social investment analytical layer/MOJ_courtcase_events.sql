/**************************************************************************************************
Title: MOJ Court case events
Author: K MaxwellV Benny

Inputs & Dependencies:
- [IDI_Clean].[moj_clean].[charges]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moj_court_id]
- moj_offense_cat_pricing.csv
- moj_offence_to_category_map.csv
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_moj_courtcase_events]

Description:
Create events table for court cases in SIAL format AND derive costs

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
2020-08-04 Simon A: recode into SQL
2019-08-01 Peter Holmes: Added a SELECT statement to ensure the user has access to the underlying IDI tables. This will show up in the log
2017-08-02 : Changes the JOIN between charges table and moj_court_id table to account for column name
				change for court_id_column in the latest IDI refresh
2016-10-19 : Incorporated the changes suggested during business QA to derive costs in a more accurate way
2016-10-01 MOJ: Business QA complete
2016-07-22 K Maxwell: Created
**************************************************************************************************/

/******************************* load reference tables *******************************/

SET DATEFORMAT DMY

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[sial_MOJ_OFFENCE_CAT_PRICING]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_MOJ_OFFENCE_CAT_PRICING];
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_MOJ_OFFENCE_CAT_PRICING] (
	offence_category CHAR(2),
	court_type CHAR(5),
	[start_date] DATE,
	[end_date] DATE,
	price FLOAT,
)

BULK INSERT [IDI_Sandpit].[DL-MAA2016-15].[sial_MOJ_OFFENCE_CAT_PRICING]
FROM '\\prtprdsasnas01\DataLab\MAA\project folder\subfolder\SIAL\moj_offense_cat_pricing.csv'
WITH
(
	DATAFILETYPE = 'char',
	CODEPAGE = 'RAW',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
)

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[sial_MOJ_OFFENCE_TO_CATEGORY_MAP]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_MOJ_OFFENCE_TO_CATEGORY_MAP];
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_MOJ_OFFENCE_TO_CATEGORY_MAP] (
	offence_Code VARCHAR(8),
	offence_category VARCHAR(3),
)

BULK INSERT [IDI_Sandpit].[DL-MAA2016-15].[sial_MOJ_OFFENCE_TO_CATEGORY_MAP]
FROM '\\prtprdsasnas01\DataLab\MAA\project folder\subfolder\SIAL\moj_offence_to_category_map.csv'
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

IF OBJECT_ID('[DL-MAA2016-15].[sial_MOJ_courtcase_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_MOJ_courtcase_events];
GO

CREATE VIEW [DL-MAA2016-15].[sial_MOJ_courtcase_events] as
SELECT cases.snz_uid AS snz_uid, 
	'MOJ' AS department,
	'COU' AS datamart,
	'CAS' AS subject_area,
	CAST(cases.start_date AS DATETIME) AS [start_date], 
	CAST(cases.end_date AS DATETIME) AS end_date, 
	pricing.price AS cost,
	cases.court_type AS event_type, 
	cases.outcome_type AS event_type_2, 
	cases.offence_category AS event_type_3
FROM (
	SELECT snz_uid, start_date, end_date, court_type, outcome_type, offence_category 
	FROM (
		SELECT snz_uid, start_date, end_date, court_type, outcome_type, offence_category,
		row_number() over (partition by snz_uid, court_type, end_date, outcome_type
						   order by snz_uid, court_type, end_date, outcome_type, offence_category desc, start_date) AS row_rank
		FROM (
			SELECT 
				snz_uid, 
				COALESCE([moj_chg_first_court_hearing_date], moj_chg_charge_laid_date) AS [start_date],
				COALESCE([moj_chg_last_court_hearing_date], [moj_chg_charge_outcome_date]) AS [end_date],
				CASE WHEN court1.court_type IN ('Youth Court') THEN 'Youth' ELSE 'Adult' END AS court_type,
				CASE WHEN c.moj_chg_charge_outcome_type_code IN (
					'CONV','CNV','CNVS','COAD','CNVD','COND','DCP','J118','J39J','MIPS34','COCC','COCM','CCMD','CVOC',/*Convicted*/
					'CPSY','CPY','PROV','ADMF','ADFN','ADMN','ADM','ADCH','ADMD','INTRES','YCDIS','YCADM','INTACT',/*Youth Court proved*/
					'DS42','D19C','DWC','DWS','DS19',/*Discharge without conviction*/
					'YDFC','INTSEN','DCYP','YP35','WDC','DDC' /*Adult diversion, Youth Court discharge*/
					) THEN 'PVN' /*Proved*/
					ELSE 'UNP' /*Not proved*/ END AS outcome_type,
				offcatmap.offence_category
			FROM [IDI_Clean_20200120].[moj_clean].[charges] c
			INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moj_court_id] court1
			ON c.[moj_chg_last_court_id_code] = court1.court_id
			LEFT JOIN [IDI_Sandpit].[DL-MAA2016-15].[sial_MOJ_OFFENCE_TO_CATEGORY_MAP] offcatmap 
			ON c.moj_chg_offence_code = offcatmap.offence_code
		) unordered_charges
	) ordered_charges 
	WHERE ordered_charges.row_rank = 1 /*Only pick up first rows FROM this sorted list of ordered charges. This row best represents the DISTINCT list of cases*/
)cases
LEFT JOIN [IDI_Sandpit].[DL-MAA2016-15].[sial_MOJ_OFFENCE_CAT_PRICING] pricing
ON cases.offence_category = pricing.offence_category 
AND cases.court_type = pricing.court_type 
AND cases.end_date BETWEEN pricing.start_date AND pricing.end_date
GO