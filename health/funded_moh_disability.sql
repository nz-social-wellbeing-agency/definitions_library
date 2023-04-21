/**************************************************************************************************
Title: Recent funded MOH disability client
Author: Craig Wright

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
Recent funded MOH disability client in SOCRATES

Intended purpose:
Identifying people receiving funding via SOCRATES (MOH) for a disability.

Inputs & Dependencies:
- [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment_202110]
- [IDI_Clean].[security].[concordance]
Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[moh_disability_funded]

Notes:

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = vacc_
  Project schema = DL-MAA20XX-YY
 
Issues:

History (reverse order):
2021-10-31 CW v1
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[moh_disability_funded]
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
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[moh_disability_funded]
FROM [IDI_Adhoc].[clean_read_MOH_SOCRATES].[moh_needs_assessment_202110] as a 
INNER JOIN [IDI_Clean_YYYYMM].[security].[concordance] as b
ON a.snz_moh_uid = b.snz_moh_uid
WHERE [CurrentNA] = 1
AND assessmentoutcome = 'Requires Service Coordination'
GO

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[moh_disability_funded] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[moh_disability_funded] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO
