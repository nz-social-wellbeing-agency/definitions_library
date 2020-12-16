/**************************************************************************************************
Title: Spell managed by Corrections
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[cor_clean].[ov_major_mgmt_periods]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[defn_corrections_any]

Description:
A spell for a person in New Zealand with any management by Corrections.

Intended purpose:
Creating indicators of when/whether a person has been managed by corrections.
Identifying spells when a person is under Corrections management.
Counting the number of days a person spends under Corrections management.
 
Notes:
1) Corrections management includes prison sentences (PRISON), remanded in custody (REMAND),
   supervision (ESO, INT_SUPER, SUPER), home detention (HD_REL, HD_SENT), conditions
   (PAROLE, ROC, PDC, PERIODIC), and community sentences (COM_DET, CW, COM_PROG, COM_SERV, OTH_COM)
2) Corrections management excludes not managed (ALIVE), deceased, deported or over 90 (AGED_OUT)
   not applicate (NA), or errors (ERROR).
3) This data set includes only major management periods, of which Prison is one type.
   Where a person has multiple management/sentence types this dataset only records the
   most severe. See introduction of Corrections documentation (2016).
4) A small but meaningful number of snz_uid codes have some form of duplicate
   records. These people can be identified by having more than one [cor_mmp_max_period_nbr] value.
   To avoid double counting, we keep only the records that are part of the longest sequence.
   This requires the inner join.
5) A tiny number of snz_uid codes have duplicate records of equal length that can not be
   resolved using [cor_mmp_max_period_nbr]. Best estimates for the size of this group is
   such a small preportion of the popultion as to be irrelevant. We have left these duplicate
   records in place.
6) One day is subtracted from the end date to ensure periods are non-overlapping.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]
 
Issues:
 
History (reverse order):
2020-02-28 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA2016-15].[defn_corrections_any]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_corrections_any];
GO

/* Create view */
CREATE VIEW [DL-MAA2016-15].[defn_corrections_any] AS
SELECT a.snz_uid
	,a.cor_mmp_prev_mmc_code
	,a.cor_mmp_mmc_code
	,a.cor_mmp_next_mmc_code
	,a.cor_mmp_index_offence_code
	,a.cor_mmp_imposed_sentence_length_nbr
	,a.cor_mmp_sentence_location_text
	,a.cor_mmp_period_start_date AS [start_date]
	,DATEADD(DAY, -1, a.cor_mmp_period_end_date) AS [end_date]
FROM IDI_Clean_20200120.[cor_clean].[ov_major_mgmt_periods] a
INNER JOIN (
	SELECT snz_uid, MAX(cor_mmp_max_period_nbr) AS cor_mmp_max_period_nbr
	FROM IDI_Clean_20200120.[cor_clean].[ov_major_mgmt_periods]
	GROUP BY snz_uid
) b
ON a.snz_uid = b.snz_uid
AND a.cor_mmp_max_period_nbr = b.cor_mmp_max_period_nbr
WHERE [cor_mmp_mmc_code] NOT IN ('AGED_OUT', 'ALIVE', 'ERROR', 'NA')
AND cor_mmp_period_start_date IS NOT NULL
AND cor_mmp_period_end_date IS NOT NULL;
GO
