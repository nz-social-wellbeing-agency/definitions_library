/**************************************************************************************************
Title: Hospital non-admitted patient events
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[nnpac]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[defn_non_admit_patient]

Description:
Hospital non-admitted events (including emergency department,
out patients, community visits) where the patient attended.

Intended purpose:
Counting the number of non-admitted patient events.
Determining who had a non-admitted patient event.
 
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
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]

Issues:
 
History (reverse order):
2020-05-20 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA2016-15].[defn_non_admit_patient]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_non_admit_patient];
GO

/* Create view */
CREATE VIEW [DL-MAA2016-15].[defn_non_admit_patient] AS
SELECT [snz_uid]
      ,[moh_nnp_service_date]
	  ,[moh_nnp_event_type_code]
	  ,[moh_nnp_attendence_code]
FROM [IDI_Clean_20200120].[moh_clean].[nnpac]
WHERE [moh_nnp_event_type_code] IN ('ED', 'OP', 'CR')
AND [moh_nnp_service_date] IS NOT NULL
AND [moh_nnp_attendence_code] <> 'DNA'; --Exclude 'did not attend'
GO
