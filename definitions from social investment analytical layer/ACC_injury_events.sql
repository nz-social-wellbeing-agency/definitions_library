/**************************************************************************************************
Title: ACC injury events SIAL table
Author: E Walsh

Inputs & Dependencies:
- [IDI_Clean].[acc_clean].[claims]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_ACC_injury_events]

Description:
Reformat and recode ACC injury data into SIAL format

Notes:
0) This definition originates in the SIAL. The SIAL was retired mid-2020
   and is no longer supported. This definition has been provided for
   researchers wanting to contiune to use this SIAL definition.
1) See SIAL data dictionary for original documentation of business rules.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = sial_
  Project schema = [DL-MAA2016-15]

Issues:

History (reverse order):
2020-08-04 Simon A: recode into SQL
2019-08-01 Peter Holmes: Added a SELECT statement to ensure the user has access to the underlying IDI tables. This will show up in the log
2016-12-15 K Maxwell: changed order of event types to make them more usefulfor roll up processing (moving read codes to event_type_5 not event_type)
2016-07-05 Ernestynne Walsh: created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[sial_ACC_injury_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_ACC_injury_events];
GO

CREATE VIEW [DL-MAA2016-15].[sial_ACC_injury_events] AS
SELECT  snz_uid
	,'ACC' AS department
	,'CLA' AS datamart
	,'INJ' AS subject_area
	,CAST(acc_cla_accident_date AS DATETIME) AS [start_date] /*accidents are point in time events*/
	,CAST(acc_cla_accident_date AS DATETIME) AS [end_date]
	,acc_cla_tot_med_fee_paid_amt AS cost
	,acc_cla_tot_weekly_comp_paid_amt AS cost_2
	,CASE acc_cla_scene_text
		WHEN 'HOME'	THEN 'HOM'
		WHEN 'PLACE OF RECREATION OR SPORTS' THEN 'REC'
		WHEN 'COMMERCIAL / SERVICE LOCATION' THEN 'COM'
		WHEN 'OTHER' THEN 'OTH'
		WHEN 'ROAD OR STREET' THEN 'ROA'
		WHEN 'INDUSTRIAL PLACE' THEN 'IND'
		WHEN 'SCHOOL' THEN 'SCH'
		WHEN 'FARM' THEN 'FAR'
		WHEN 'PLACE OF MEDICAL TREATMENT' THEN 'MED'
		ELSE 'UNK' 
		END AS event_type
	/* event_type_2 needs to stay AS this variable AS it is a dependency for the MIX_selfharm_events  SIAL table */
	,CASE acc_cla_wilful_self_inflicted_status_text
		WHEN 'CONFIRMED' THEN 'CON' 
		ELSE 'OTH' 
		END AS event_type_2
	,acc_cla_gradual_process_ind AS event_type_3
	,CASE acc_cla_fund_account_text
		WHEN 'NON-EARNERS ACCOUNT' THEN 'NEA'
		WHEN 'EARNERS ACCOUNT' THEN 'EAR'
		WHEN 'WORK ACCOUNT' THEN 'WRK'
		WHEN 'MOTOR VEHICLE ACCOUNT' THEN 'MVH'
		WHEN 'TREATMENT INJURY ACCOUNT' THEN 'TRI'
		ELSE 'UNK' 
		END AS event_type_4
	,acc_cla_read_code AS event_type_5
	,CAST(acc_cla_weekly_comp_days_nbr AS varchar(5)) AS event_type_6
FROM [IDI_Clean_20200120].[acc_clean].[claims];
GO
