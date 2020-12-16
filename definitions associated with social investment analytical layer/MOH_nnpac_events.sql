/**************************************************************************************************
Title: MOH nnpac events
Author: V Benny

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[nnpac]
- moh_pu_pricing.csv
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[SIAL_MOH_nnpac_events]

Description:
Create MOH National Non-admitted Patient Collection events table in SIAL format

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
2016-07-22 V Benny: Created
**************************************************************************************************/

/******************************* load pricing table *******************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[sial_MOH_PU_PRICING]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_MOH_PU_PRICING];
GO

SET DATEFORMAT DMY

CREATE TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_MOH_PU_PRICING] (
	pu_code VARCHAR(9),
	fin_year VARCHAR(8),
	pu_price FLOAT,
	[start_date] DATE,
	[end_date] DATE,
)

BULK INSERT [IDI_Sandpit].[DL-MAA2016-15].[sial_MOH_PU_PRICING]
FROM '\\prtprdsasnas01\DataLab\MAA\project folder\subfolder\SIAL\moh_pu_pricing.csv'
WITH
(
	DATAFILETYPE = 'char',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
)

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[SIAL_MOH_nnpac_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[SIAL_MOH_nnpac_events];
GO

CREATE VIEW [DL-MAA2016-15].[SIAL_MOH_nnpac_events] AS 
SELECT snz_uid, 
	department,
	datamart,
	subject_area,	
	CAST([start_date] AS DATETIME) AS [start_date], 
	CAST([end_date] AS DATETIME) AS end_date, 
	SUM(nnpac_claim_cost) AS cost,
	event_type,
	event_type_2,
	event_type_3
FROM (
	SELECT snz_uid, 
		nn.snz_moh_uid, 
		'MOH' AS department,
		'NNP' AS datamart,
		'NNP' AS subject_area,
		moh_nnp_service_datetime AS [start_date], /*+ CAST( coalesce(moh_nnp_time_of_service, CAST('00:00:00.0000000' AS time)) AS DATETIME) AS [start_date], */
		/* If there is a valid end date, use this, else use service date */
		CASE WHEN CAST(nn.moh_nnp_event_end_datetime AS DATE) = CAST('9999-12-31' AS DATE) THEN moh_nnp_service_datetime
			ELSE moh_nnp_event_end_datetime END AS [end_date], 
		nn.moh_nnp_volume_amt, 
		/* If ED results in hospital admission (ED%A), this is not counted AS an NNPAC event*/
		CASE WHEN nn.moh_nnp_event_type_code ='ED' AND nn.moh_nnp_purchase_unit_code LIKE 'ED%A' THEN 0.00
			ELSE (pu.pu_price * nn.moh_nnp_volume_amt) END AS nnpac_claim_cost,					
		nn.moh_nnp_purchase_unit_code AS event_type,
		nn.moh_nnp_attendence_code AS event_type_2,
		nn.moh_nnp_hlth_spc_code AS event_type_3
	FROM [IDI_Clean_20200120].[moh_clean].[nnpac] nn
	LEFT JOIN IDI_Sandpit.[DL-MAA2016-15].[sial_MOH_PU_PRICING] AS pu
	ON nn.moh_nnp_purchase_unit_code = pu.pu_code
	AND nn.moh_nnp_service_datetime BETWEEN pu.[start_date] AND pu.end_date
)x
GROUP BY snz_uid, department, datamart, subject_area, [start_date], [end_date], event_type, event_type_2, event_type_3
