/**************************************************************************************************
Title: Education intervention events
Author: K Maxwell

Inputs & Dependencies:
- [IDI_Clean].[moe_clean].[student_interventions]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_MOE_intervention_events]

Description:
Reformat and recode MOE interventions data into SIAL format

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
Added institution number for summary of entities for output checking
2016-07-22 K Maxwell: Created
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[sial_MOE_intervention_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_MOE_intervention_events];
GO

CREATE VIEW [DL-MAA2016-15].[sial_MOE_intervention_events] AS
SELECT snz_uid,
	'MOE' AS department,
	'STU' AS datamart,
	'INT' AS subject_area,	
	CAST(moe_inv_start_date AS DATETIME) AS [start_date],
	CAST(moe_inv_end_date AS DATETIME) AS [end_date],
	moe_inv_intrvtn_code AS event_type,
	moe_inv_inst_num_code AS entity_id
FROM [IDI_Clean_20200120].[moe_clean].[student_interventions];
GO