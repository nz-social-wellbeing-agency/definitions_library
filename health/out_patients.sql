/**************************************************************************************************
Title: Hospital non-admitted patient events
Author: Simon Anastasiadis

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Disclaimer:
The definitions provided in this library were determined by the Social Wellbeing Agency to be suitable in the 
context of a specific project. Whether or not these definitions are suitable for other projects depends on the 
context of those projects. Researchers using definitions from this library will need to determine for themselves 
to what extent the definitions provided here are suitable for reuse in their projects. While the Agency provides 
this library as a resource to support IDI research, it provides no guarantee that these definitions are fit for reuse.

Citation:
Social Wellbeing Agency. Definitions library. Source code. https://github.com/nz-social-wellbeing-agency/definitions_library

Description:
Hospital non-admitted events (including emergency department,
out patients, community visits) where the patient attended.

Intended purpose:
Counting the number of non-admitted patient events.
Determining who had a non-admitted patient event.

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[nnpac]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[defn_non_admit_patient]

Notes:
1) Three types of non-admitted patient events are included:
   ED = Emergency department
   OP = Out patient
   CR = Community visit
2) We use ED visits as recorded in out patients. As per Craig's advice:
   because we are only interested in counting events, we do not need to
   combine with admitted patient ED events.
3) Craig advised that community visits by hospital based practitioner
   have only been consistently recorded recently.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]

Issues:
 
History (reverse order):
2020-05-20 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[defn_non_admit_patient];
GO

/* Create view */
CREATE VIEW [DL-MAA20XX-YY].[defn_non_admit_patient] AS
SELECT [snz_uid]
      ,[moh_nnp_service_date]
	  ,[moh_nnp_event_type_code]
	  ,[moh_nnp_attendence_code]
FROM [IDI_Clean_YYYYMM].[moh_clean].[nnpac]
WHERE [moh_nnp_event_type_code] IN ('ED', 'OP', 'CR')
AND [moh_nnp_service_date] IS NOT NULL
AND [moh_nnp_attendence_code] <> 'DNA'; --Exclude 'did not attend'
GO
