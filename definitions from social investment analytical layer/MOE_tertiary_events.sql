/**************************************************************************************************
Title: MOE tertiary events
Author: Wen Jhe Lee

Inputs & Dependencies:
- [IDI_Clean].[moe_clean].[enrolment]
- moe_ter_pricing.csv
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_MOE_ter_edu_event]

Description:
Create the event table for tertiary education spells AND costs
excluding Industry Training

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
Changed provider code to be entity_id
2019-08-01 Peter Holmes: Added a SELECT statement to ensure the user has access to the underlying IDI tables. This will show up in the log
2017-04-28 WL: Added based on feedback domestic Ind = 1 AND fund codes list
2017-04-12 WL: port based code in moe_ter_edu_event.sas FROM Anotine Merval
2017-04-12 Wen Jhe Lee: Created
**************************************************************************************************/

/******************************* load pricing table *******************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_TER_FUNDINGRATES]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_TER_FUNDINGRATES];
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_TER_FUNDINGRATES] (
	[Year] INT,
	cost_type VARCHAR(7),
	Subsector VARCHAR(31),
	Ter_fund_rates FLOAT,
)

BULK INSERT [IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_TER_FUNDINGRATES]
FROM '\\prtprdsasnas01\DataLab\MAA\project folder\subfolder\SIAL\moe_ter_pricing.csv'
WITH
(
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '\n',
	TABLOCK
)

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[sial_MOE_tertiary_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_MOE_tertiary_events];
GO

CREATE VIEW [DL-MAA2016-15].[sial_MOE_tertiary_events] AS
SELECT snz_uid,
	'MOE' AS department,	
	'TER' AS datamart,	
	'ENR' AS subject_area,
	LEFT(subsector, 7) AS event_type,	
	moe_enr_provider_code AS entity_id,
	qual_code AS event_type_3,		
	ROUND(SUM(ter_cost), 3) AS cost,
	0 AS revenue,
	CAST(moe_enr_prog_start_date AS DATETIME) AS start_date, 
	CAST(moe_enr_prog_end_date  AS DATETIME) AS end_date
FROM (
	SELECT DISTINCT 
		snz_uid
		,moe_enr_year_nbr AS cal_year 
		,moe_enr_prog_start_date
		,moe_enr_qual_code AS qual_code
		,moe_enr_prog_end_date
		,moe_enr_efts_consumed_nbr AS EFTS_consumed
		,subsectord
		,moe_enr_provider_code
		,moe_enr_funding_srce_code
		,b.*
		,a.moe_enr_efts_consumed_nbr * b.ter_fund_rates AS ter_cost
	FROM (
		SELECT *,
			CASE 
			WHEN [moe_enr_subsector_code]=1 OR [moe_enr_subsector_code]=3 THEN 'Universities'
			WHEN [moe_enr_subsector_code]=2 THEN 'Polytechnics' 
			WHEN [moe_enr_subsector_code]=4 THEN 'Wananga'
			WHEN [moe_enr_subsector_code]=5 OR [moe_enr_subsector_code]=6 THEN 'Private Training Establishments' 
			END AS subsectord
		FROM [IDI_Clean_20200120].[moe_clean].[enrolment]
	) a
	LEFT JOIN [IDI_SANDPIT].[DL-MAA2016-15].[sial_MOE_TER_FUNDINGRATES] b
	ON a.moe_enr_year_nbr = b.[year]
	AND  a.subsectord = b.Subsector
	WHERE 2000 <= [moe_enr_year_nbr]   AND [moe_enr_year_nbr]  <= 9999
	AND [moe_enr_funding_srce_code] IN ('01','25','26','27','28','29','30','32')
	AND [moe_enr_is_domestic_ind] =1
	AND [moe_enr_efts_consumed_nbr] > 0 
) z
GROUP BY snz_uid,subsector,qual_code,moe_enr_provider_code,moe_enr_prog_start_date, moe_enr_prog_end_date 
GO