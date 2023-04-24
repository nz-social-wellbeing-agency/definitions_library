/**************************************************************************************************
Title: Spell managed by Corrections
Author: Simon Anastasiadis
Reviewer: Marianna Pekar, Joel Bancolita

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
A spell for a person in New Zealand with any management by Corrections.

Intended purpose:
1. Creating indicators of when/whether a person has been managed by corrections.
2. Identifying spells when a person is under Corrections management.
3. Counting the number of days a person spends under Corrections management.

Inputs & Dependencies:
- [IDI_Clean].[cor_clean].[ov_major_mgmt_periods]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[d2gP2_corrections_any]
 
Notes:
1) Corrections management includes prison sentences (PRISON), remanded in custody (REMAND),
   supervision (ESO, INT_SUPER, SUPER), home detention (HD_REL, HD_SENT), conditions
   (PAROLE, ROC, PDC, PERIODIC), and community sentences (COM_DET, CW, COM_PROG, COM_SERV, OTH_COM)
2) Corrections management excludes not managed (ALIVE), deceased, deported or over 90 (AGED_OUT)
   not applicate (NA), or errors (ERROR).
3) This data set includes only major management periods, of which Prison is one type.
   Where a person has multiple management/sentence types this dataset only records the
   most severe. See introduction of Corrections documentation (2016).
4) A small but meaningful number of snz_uid codes (between 1% and 5%) have some form of duplicate
   records. These people can be identified by having more than one [cor_mmp_max_period_nbr] value.
   To avoid double counting, we keep only the records that are part of the longest sequence.
   This requires the inner join.
   An alternative approach would be to keep the sequence with the longest duration.
   The assumption behind keeping the more complex sequences is that the increased detail makes them
   more likely to be true. Contrast for example: 5 year prison sentence, vs. 2 years in prison,
   1 year home detention, 6 months supervision. In this case the first sequence, while longer,
   may not have been updated as the person's conditions changed with the updates appearing on
   the second sequence.
5) A tiny number of snz_uid codes have duplicate records of equal length that can not be
   resolved using [cor_mmp_max_period_nbr]. Best estimates for the size of this group is <0.1%
   of the population. We have left these duplicate records in place.
6) One day is subtracted from the end date to ensure periods are non-overlapping.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = d2g_
  Project schema = [DL-MAA20XX-YY]
 
Issues:
1) Starting with the March 2022 refresh, the input table [ov_major_mgmt_periods] is no longer
   being updated and new tables have been introduced. Definition will need updating to use
   these new tables for research studying the most recent time periods.
 
History (reverse order):
2021-06-04 FL update the input table to the latest reference
2020-07-22 JB QA
2020-07-16 MP QA
2020-02-28 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[d2gP2_corrections_any];
GO

/* Create view */
CREATE VIEW [DL-MAA20XX-YY].[d2gP2_corrections_any] AS
SELECT a.snz_uid
	,a.cor_mmp_prev_mmc_code
	,a.cor_mmp_mmc_code
	,a.cor_mmp_next_mmc_code
	,a.cor_mmp_index_offence_code
	,a.cor_mmp_imposed_sentence_length_nbr
	,a.cor_mmp_sentence_location_text
	,a.cor_mmp_period_start_date AS [start_date]
	,DATEADD(DAY, -1, a.cor_mmp_period_end_date) AS [end_date]
FROM  [IDI_Clean_YYYYMM].[cor_clean].[ov_major_mgmt_periods] a
INNER JOIN (
	SELECT snz_uid, MAX(cor_mmp_max_period_nbr) AS cor_mmp_max_period_nbr
	FROM  [IDI_Clean_YYYYMM].[cor_clean].[ov_major_mgmt_periods]
	GROUP BY snz_uid
) b
ON a.snz_uid = b.snz_uid
AND a.cor_mmp_max_period_nbr = b.cor_mmp_max_period_nbr
WHERE [cor_mmp_mmc_code] NOT IN ('AGED_OUT', 'ALIVE', 'ERROR', 'NA')
AND cor_mmp_period_start_date IS NOT NULL
AND cor_mmp_period_end_date IS NOT NULL
AND cor_mmp_period_start_date <= cor_mmp_period_end_date;
GO




