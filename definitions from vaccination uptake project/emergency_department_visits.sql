/**************************************************************************************************
Title: Emergency Department visit
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual_2018]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_Cen2018_Occupation]

Description:
Emergency Department (ED) visits at hospital.

Intended purpose:
Identifying presentation at an emergency department, counting number of ED visits.

Notes:

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:

History (reverse order):
2021-10-31 CW
**************************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2021-49].[emergency_department_visit]
GO

CREATE VIEW [DL-MAA2021-49].[emergency_department_visit] AS
SELECT [snz_uid]
	,[moh_nnp_service_date]
	,[moh_nnp_presentation_datetime]
	,[moh_nnp_service_datetime]
	--ATT=attended / DNW= do not wait / DNA = did not attend
	,[moh_nnp_attendence_code]
	,[moh_nnp_event_type_code]
	,[moh_nnp_event_end_type_code]
	,[moh_nnp_triage_level_code]
	,[moh_nnp_purchase_unit_code]
	,[moh_nnp_hlth_spc_code]
	,[moh_nnp_volume_amt]
	,[moh_nnp_unit_of_measure_key]
	,b.[Classification]
FROM [IDI_Clean_20211020].[moh_clean].[nnpac] AS a
LEFT JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_nnpac_unit_of_measure] as b
ON a.[moh_nnp_unit_of_measure_key] = b.[Code]
WHERE [moh_nnp_event_type_code] = 'ED' -- emergency department
AND [moh_nnp_attendence_code] = 'ATT'
