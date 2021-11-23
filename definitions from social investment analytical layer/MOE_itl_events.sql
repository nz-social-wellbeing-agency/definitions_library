/**************************************************************************************************
Title: MOE Industry training events
Author: Wen Jhe Lee

Inputs & Dependencies:
- [IDI_Clean].[moe_clean].[tec_it_learner]
- moe_itl_fund.csv
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_MOE_ITL_events]

Description:
Create the event table Industry Training AND Modern Apprenticeships

Notes:
0) This definition originates in the SIAL. The SIAL was retired mid-2020
   and is no longer supported. This definition has been provided for
   researchers wanting to contiune to use this SIAL definition.
1) See SIAL data dictionary for original documentation of business rules.
2) Reference period start:  1 January 2003.
   Target population: People undergoing workplace-based training activity eligible 
      for funding through the Industry Training fund AND Modern Apprenticeships funds.
   Observed population:  People undergoing workplace-based training activity which is
      eligible for funding through the Industry Training fund AND Modern Apprenticeships fund.
   Analysis Unit: Training activity of individuals in programmes administered by 
      Industry Training Organisation in each training fund in a calendar year. 
3) Cost is taken FROM fixed cost per year by the fund code FROM MOE - given by David Earle
4) Each row is per course for each snz_uid
5) Note that FROM 2011 onwards there is a change of management system
6) For loading CSV file, SQL requires network path. Drive letter will fail.
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
Changed event_type_3 to entity_id for output checking summarising
2019-08-01 Peter Holmes: Added a SELECT statement to ensure the user has access to the underlying IDI tables. This will show up in the log
2019-06-01 Peter Holmes: Views now have to be created in the IDI_UserCode schema in the IDI
v2 - updated with actual fund cost from MOE
2017-04-21 Wen Jhe Lee: Created
**************************************************************************************************/

/******************************* load pricing table *******************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_ITL_FUND_RATE]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_ITL_FUND_RATE];
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_ITL_FUND_RATE] (
	moe_itl_fund_code VARCHAR(3),
	cal_year INT,
	rate FLOAT,
)

BULK INSERT [IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_ITL_FUND_RATE]
FROM '\\prtprdsasnas01\DataLab\MAA\project folder\subfolder\SIAL\moe_itl_fund.csv'
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

IF OBJECT_ID('[DL-MAA2016-15].[sial_MOE_itl_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_MOE_itl_events];
GO

CREATE VIEW [DL-MAA2016-15].[sial_MOE_itl_events] as
SELECT snz_uid,
	'MOE' AS department,
	'ITL' AS datamart,
	'ENR' AS subject_area,
	CAST(moe_itl_start_date AS DATETIME) AS start_date,
	CAST(moe_itl_end_date AS DATETIME) AS end_date,
	moe_itl_fund_code AS event_type, /*-- Fund Code of either IT (Industry Training) or MA (Modern Apprenticeships)*/
	moe_itl_ito_edumis_id_code AS entity_id, /*-- MOE ID of Industry Training Provider*/
	moe_itl_nqf_level_code AS event_type_3, /*-- The NZQF level of the training programme*/
	moe_itl_nzsced_detail_text AS event_type_4, /*-- The NZSCED detail of programme*/
	ROUND(SUM(cost_sum),2)  AS cost
FROM (
	SELECT tec_learner.*
		,moerate.rate
		,DATEFROMPARTS(moerate.cal_year, 1, 1) AS sd_rate
		,DATEFROMPARTS(moerate.cal_year, 12, 31) AS ed_rate
		,moe_itl_sum_units_consumed_nbr * moerate.rate AS cost_sum 
	FROM [IDI_Clean_20200120].[moe_clean].[tec_it_learner] tec_learner
	INNER JOIN [IDI_Sandpit].[DL-MAA2016-15].[sial_MOE_ITL_FUND_RATE] moerate /*-- Table derived from MOE fixed cost by year*/
	ON tec_learner.moe_itl_fund_code = moerate.moe_itl_fund_code
	AND tec_learner.moe_itl_start_date BETWEEN DATEFROMPARTS(moerate.cal_year, 1, 1) AND DATEFROMPARTS(moerate.cal_year, 12, 31)
) summary
WHERE moe_itl_start_date != '' 
GROUP BY snz_uid,moe_itl_start_date,moe_itl_end_date,moe_itl_fund_code,moe_itl_ito_edumis_id_code,	moe_itl_nqf_level_code, moe_itl_nzsced_detail_text
GO
