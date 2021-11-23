/**************************************************************************************************
Title: Mixed-source self-harm events
Author: E Walsh

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_diag]
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]
- ACC_injury_events.sql --> [IDI_UserCode].[DL-MAA2016-15].[sial_ACC_injury_events]
- CYB_abuse_events.sql --> [IDI_UserCode].[DL-MAA2016-15].[sial_CYF_abuse_events]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_MIX_selfharm_events]

Description:
Create an event table of records of suicide or self harm
using ACC events table, CYF events table, and MOH PFHD & NNPAC

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
2016-10-04 E Walsh: Created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[sial_MIX_selfharm_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_MIX_selfharm_events];
GO

CREATE VIEW [DL-MAA2016-15].[sial_MIX_selfharm_events] AS
SELECT  snz_uid, 
	'MIX' AS department,
	'HRM' AS datamart,
	'SLF' AS subject_area,	
	/* just in CASE the extra sources of info dont have DATETIME format*/			
	CAST(sdt AS DATETIME) AS [start_date],
	CAST(edt AS DATETIME) AS [end_date],
	source_agency AS event_type/*,*/
FROM (
	SELECT snz_uid
		, start_date AS sdt
		, end_date AS edt
		, department AS source_agency
	FROM [IDI_UserCode].[DL-MAA2016-15].sial_ACC_injury_events
	/* warning in the ACC_injury_events SIAL table if event_type_2 is no longer acc_cla_wilful_self_inflicted_status_text or the
	3 character code changes THEN this will be incorrect. A note is included in the ACC_injury_events SIAL script to note this dependency */
	/* CON is short for confirmed wilful self inflicted status*/
	WHERE event_type_2 = 'CON'

	UNION ALL
	
	SELECT snz_uid
		, start_date AS sdt
		, end_date AS edt
		, department AS source_agency
	FROM [DL-MAA2016-15].sial_CYF_abuse_events
	/* warning if these 3 digit short hands change THEN this will be incorrect */
	/* SHS is short for suicide or self harm */
	WHERE event_type = 'SHS'
	
	UNION ALL

	SELECT DISTINCT snz_uid
		, CAST([start_date] AS DATETIME) AS sdt
		, CAST([end_date] AS DATETIME) AS edt
		, department AS source_agency
	/* no filtering required for this table AS the identification of suicide AND self harm is done
	in the table above */
	/*--FROM [DL-MAA2016-15].[moh_sucide_selfharm_v2]*/
	FROM (
		SELECT p.snz_uid
			,'MOH' AS department
			,p.moh_evt_event_id_nbr
			,CASE WHEN d.moh_dia_op_date IS NULL /* If there is an operation date use that otherwise use the event start date */
				THEN p.moh_evt_evst_date
				ELSE d.moh_dia_op_date
				END AS [start_date]
			,p.moh_evt_even_date  AS end_date
		FROM [IDI_Clean_20200120].[moh_clean].[pub_fund_hosp_discharges_diag] d
		LEFT JOIN [IDI_Clean_20200120].[moh_clean].[pub_fund_hosp_discharges_event] p 
		ON d.moh_dia_event_id_nbr = p.moh_evt_event_id_nbr
		/* look for external cause */
		WHERE d.moh_dia_diagnosis_type_code = 'E'
		/* note we have constructed the codes in this way AS ICD10 codes refer to X60-X84 AS intentional self harm */
		AND SUBSTRING(d.moh_dia_clinical_code,1,3) IN ('X60','X61','X62','X63',
			'X64','X65','X66','X67','X68','X69','X70','X71','X72','X73','X74',
			'X75','X76','X77','X78','X79','X80','X81','X82','X83','X84')
		AND  p.snz_acc_claim_uid IS NULL
	) moh_sucide_selfharm_v2
)x
GO
