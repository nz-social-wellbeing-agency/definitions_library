/**************************************************************************************************
Title: Recent funded MOH disability client
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment_202110]
- [IDI_Clean].[security].[concordance]
Outputs:
- [IDI_Sandpit].[DL-MAA2021-49].[moh_disability_funded]

Description:
Recent funded MOH disability client in SOCRATES

Intended purpose:
Identifying people receiving funding via SOCRATES (MOH) for a disability.

Notes:

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:

History (reverse order):
2021-10-31 CW v1
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[moh_disability_funded]
GO

SELECT b.snz_uid
	,1 as moh_disability_funded
	--,a.[snz_moh_uid]
	--,[snz_moh_soc_client_uid]
	--,[ReferralID]
	--,[NeedsAssessmentID]
	--,[NASCCode]
	--,[AssessmentType]
	--,[AssessmentLocation]
	--,[ReassessmentRequestDate]
	--,[FirstContactDate]
	--,[DateAssessmentCompleted]
	--,[AssessmentOutcome]
	--,[CurrentNA]
INTO [IDI_Sandpit].[DL-MAA2021-49].[moh_disability_funded]
FROM [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment_202110] as a 
INNER JOIN [IDI_Clean_20211020].[security].[concordance] as b
ON a.snz_moh_uid = b.snz_moh_uid
WHERE [CurrentNA] = 1
AND assessmentoutcome = 'Requires Service Coordination'
GO

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2021-49].[moh_disability_funded] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA2021-49].[moh_disability_funded] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO
