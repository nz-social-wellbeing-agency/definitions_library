/**************************************************************************************************
Title: MOH pfhd events
Author: V Benny

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]
- moh_pu_pricing.csv
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[SIAL_MOH_pfhd_events]

Description:
Create MOH pfhd (pubically funded hospital discharges) event table in SIAL format

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

IF OBJECT_ID('[DL-MAA2016-15].[SIAL_MOH_pfhd_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[SIAL_MOH_pfhd_events];
GO

CREATE VIEW [DL-MAA2016-15].[SIAL_MOH_pfhd_events] AS
SELECT 
	[snz_uid], 
	department,
	datamart,
	subject_area,
	CAST([start_date] AS DATETIME) AS [start_date],
	CAST([end_date] AS DATETIME) AS [end_date],
	SUM(cost) AS cost,
	event_type
FROM (
	SELECT 
		[snz_uid],
		[snz_moh_uid],
		[moh_evt_event_id_nbr], 
		'MOH' AS department,
		'PFH' AS datamart,
		'PFH' AS subject_area,
		[moh_evt_event_type_code],
		[moh_evt_end_type_code],
		[moh_evt_evst_date] AS [start_date],
		[moh_evt_even_date] AS [end_date],
		moh_evt_cost_weight_amt,
		[moh_evt_cost_wgt_code],
		pu.pu_price, 
		CASE WHEN moh_evt_pur_unit_text is null or moh_evt_cost_weight_amt is null or moh_evt_pur_unit_text='EXCLU' THEN 0.00
			ELSE  moh_evt_cost_weight_amt * pu.pu_price END AS cost,
		moh_evt_pur_unit_text AS event_type
	FROM [IDI_Clean_20200120].[moh_clean].[pub_fund_hosp_discharges_event] pfhd
	LEFT JOIN IDI_Sandpit.[DL-MAA2016-15].[sial_MOH_PU_PRICING] pu
	ON replace(pfhd.moh_evt_pur_unit_text, '.', '0') = pu.pu_code
	AND pfhd.moh_evt_evst_date BETWEEN pu.[start_date] AND pu.end_date
	/* Filter out short stay events as per Data dictionary advice*/
	WHERE [moh_evt_shrtsty_ed_flg_ind] IS NULL
) full_query
GROUP BY [snz_uid],
	department,
	datamart,
	subject_area,
	[start_date],
	[end_date],
	event_type
GO
