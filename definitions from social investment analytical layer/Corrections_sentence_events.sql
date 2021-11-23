/**************************************************************************************************
Title: Corrections sentence events
Author: E Walsh

Inputs & Dependencies:
- [IDI_Clean].[cor_clean].[ov_major_mgmt_periods]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_COR_sentence_events]

Description:
Reformat and recode corrections data into SIAL format

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
2017-01-20 Ernestynne Walsh: created
**************************************************************************************************/

/******************************* load pricing table *******************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[sial_COR_MMC_PRICING]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_COR_MMC_PRICING];
GO

SET DATEFORMAT DMY

CREATE TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_COR_MMC_PRICING] (
	mmc_code VARCHAR(10),
	direct_cost FLOAT,
	total_cost FLOAT,
	[start_date] DATE,
	[end_date] DATE,
)

BULK INSERT [IDI_Sandpit].[DL-MAA2016-15].[sial_COR_MMC_PRICING]
FROM '\\prtprdsasnas01\DataLab\MAA\project folder\subfolder\SIAL\cor_mmc_pricing.csv'
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

IF OBJECT_ID('[DL-MAA2016-15].[sial_COR_sentence_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_COR_sentence_events];
GO

CREATE VIEW [DL-MAA2016-15].[sial_COR_sentence_events] AS
SELECT  DISTINCT a.[snz_uid]
	,'COR' AS department
	,'MMP' AS datamart
	,'SAR' AS subject_area
	,CAST(a.[cor_mmp_period_start_date] AS DATETIME) AS start_date 
	,CAST(a.[cor_mmp_period_end_date] AS DATETIME) AS end_date
	,b.[direct_cost] * DATEDIFF(DAY, a.[cor_mmp_period_start_date], a.[cost_end_date]) AS cost
	,(b.[total_cost] - b.[direct_cost]) * DATEDIFF(DAY, [cor_mmp_period_start_date], a.[cost_end_date]) AS cost_2
	,codes.Group_code AS event_type
	,a.[cor_mmp_mmc_code] AS event_type_2
FROM (
	SELECT [snz_uid]
		,[cor_mmp_period_start_date]
		,[cor_mmp_period_end_date]
		,[cor_mmp_mmc_code]
		,CASE
			WHEN YEAR([cor_mmp_period_end_date]) = 9999 THEN (
				SELECT MAX(cor_mmp_modified_date)
				FROM [IDI_Clean_20200120].[cor_clean].[ov_major_mgmt_periods]
			) 
			ELSE [cor_mmp_period_end_date] END AS cost_end_date
	FROM [IDI_Clean_20200120].[cor_clean].[ov_major_mgmt_periods]
) a
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[cor_ov_mmc_dim] codes
ON a.[cor_mmp_mmc_code] = codes.Code
LEFT JOIN [IDI_Sandpit].[DL-MAA2016-15].[sial_COR_MMC_PRICING] b
ON a.cor_mmp_mmc_code = b.mmc_code
AND a.[cor_mmp_period_start_date] BETWEEN b.start_date AND b.end_date
WHERE [cor_mmp_mmc_code] IN ('PRISON','REMAND','HD_SENT','HD_REL','ESO','PAROLE','ROC','PDC',
'PERIODIC','COM_DET','CW', 'COM_PROG','COM_SERV','OTH_COM','INT_SUPER','SUPER');
GO
