/**************************************************************************************************
Title: Earliest date B4SC
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
Earliest date that a child receives some part of their before (B4) school check (B4SC).
Excludes declined checks.

Intended purpose:
Identifying when B4SC begin.
Determining which children are receiving B4SC.

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[b4sc]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[defn_earliest_b4sc]


Notes:
1) Linking errors are possible so some people older that 4 or 5 may be recorded as having
   before school checks. Such records should be discarded.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]

Issues:
 
History (reverse order):
2020-05-25 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[defn_earliest_b4sc];
GO

/* Create view */
CREATE VIEW [DL-MAA20XX-YY].[defn_earliest_b4sc] AS

WITH
strengths_difficulty_questionnaire_teacher AS (
	SELECT [snz_uid], [moh_bsc_sdqt_date] AS the_date
	FROM [IDI_Clean_YYYYMM].[moh_clean].[b4sc]
	WHERE [moh_bsc_sdqt_outcome_text] IS NOT NULL
	AND [moh_bsc_sdqt_outcome_text] <> 'Declined'
	AND [moh_bsc_sdqt_date] IS NOT NULL
),
strengths_difficulty_questionnaire_parent AS (
	SELECT [snz_uid], [moh_bsc_sdqp_date] AS the_date
	FROM [IDI_Clean_YYYYMM].[moh_clean].[b4sc]
	WHERE [moh_bsc_sdqp_outcome_text] IS NOT NULL
	AND [moh_bsc_sdqp_outcome_text] <> 'Declined'
	AND [moh_bsc_sdqp_date] IS NOT NULL
),
pediatrics AS (
	SELECT [snz_uid], [moh_bsc_peds_date] AS the_date
	FROM [IDI_Clean_YYYYMM].[moh_clean].[b4sc]
	WHERE [moh_bsc_peds_outcome_text] IS NOT NULL
	AND [moh_bsc_peds_outcome_text] <> 'Declined'
	AND [moh_bsc_peds_date] IS NOT NULL
),
immunisations AS (
	SELECT [snz_uid], [moh_bsc_imms_date] AS the_date
	FROM [IDI_Clean_YYYYMM].[moh_clean].[b4sc]
	WHERE [moh_bsc_imms_outcome_text] IS NOT NULL
	AND [moh_bsc_imms_outcome_text] <> 'Declined'
	AND [moh_bsc_imms_date] IS NOT NULL
),
dental AS (
	SELECT [snz_uid], [moh_bsc_dental_date] AS the_date
	FROM [IDI_Clean_YYYYMM].[moh_clean].[b4sc]
	WHERE [moh_bsc_dental_outcome_text] IS NOT NULL
	AND [moh_bsc_dental_outcome_text] <> 'Declined'
	AND [moh_bsc_dental_date] IS NOT NULL
),
growth AS (
	SELECT [snz_uid], [moh_bsc_growth_date] AS the_date
	FROM [IDI_Clean_YYYYMM].[moh_clean].[b4sc]
	WHERE [moh_bsc_growth_outcome_text] IS NOT NULL
	AND [moh_bsc_growth_outcome_text] <> 'Declined'
	AND [moh_bsc_growth_date] IS NOT NULL
),
hearing AS (
	SELECT [snz_uid], [moh_bsc_hearing_date] AS the_date
	FROM [IDI_Clean_YYYYMM].[moh_clean].[b4sc]
	WHERE [moh_bsc_hearing_outcome_text] IS NOT NULL
	AND [moh_bsc_hearing_outcome_text] <> 'Declined'
	AND [moh_bsc_hearing_date] IS NOT NULL
),
vision AS (
	SELECT [snz_uid], [moh_bsc_vision_date] AS the_date
	FROM [IDI_Clean_YYYYMM].[moh_clean].[b4sc]
	WHERE [moh_bsc_vision_outcome_text] IS NOT NULL
	AND [moh_bsc_vision_outcome_text] <> 'Declined'
	AND [moh_bsc_vision_date] IS NOT NULL
),
general_checkup AS (
	SELECT [snz_uid], [moh_bsc_general_date] AS the_date
	FROM [IDI_Clean_YYYYMM].[moh_clean].[b4sc]
	WHERE [moh_bsc_general_outcome_text] IS NOT NULL
	AND [moh_bsc_general_outcome_text] <> 'Declined'
	AND [moh_bsc_general_date] IS NOT NULL
),
overall_status AS (
	SELECT [snz_uid], [moh_bsc_check_date] AS the_date
	FROM [IDI_Clean_YYYYMM].[moh_clean].[b4sc]
	WHERE [moh_bsc_check_status_text] IS NOT NULL
	AND [moh_bsc_check_status_text] <> 'Declined'
	AND [moh_bsc_check_date] IS NOT NULL
)
SELECT [snz_uid], MIN(the_date) AS earliest_date
FROM (
	SELECT * FROM strengths_difficulty_questionnaire_teacher UNION ALL
	SELECT * FROM strengths_difficulty_questionnaire_parent UNION ALL
	SELECT * FROM pediatrics UNION ALL
	SELECT * FROM immunisations UNION ALL
	SELECT * FROM dental UNION ALL
	SELECT * FROM growth UNION ALL
	SELECT * FROM hearing UNION ALL
	SELECT * FROM vision UNION ALL
	SELECT * FROM general_checkup UNION ALL
	SELECT * FROM overall_status
) k
GROUP BY [snz_uid]
