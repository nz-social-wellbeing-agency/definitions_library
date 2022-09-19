/**************************************************************************************************
Title: Spell in Prison
Author: Simon Anastasiadis
re-edit: PMok

Inputs & Dependencies:
- [IDI_Clean_202203].[cor_clean].[ov_major_mgmt_periods]
Outputs:
- [IDI_UserCode].[DL-MAA2018-48].[defn_corrections_prison]

Description:
A spell for a person in a New Zealand prison managed by Corrections.

Intended purpose:
Creating indicators of when/whether a person has been imprisoned.
Identifying spells when a person is in prison.
Counting the number of days a person spends in prison.
 
Notes:
1) This data set includes only major management periods, of which Prison is one type.
   Where a person has multiple management/sentence types this dataset only records the
   most severe. See introduction of Corrections documentation (2016).
2) A small but meaningful number of snz_uid codes (between 1% and 5%) have some form of duplicate
   records. These people can be identified by having more than one [cor_mmp_max_period_nbr] value.
   To avoid double counting, we keep only the records that are part of the longest sequence.
   This requires the inner join.
3) A tiny number of snz_uid codes have duplicate records of equal length that can not be
   resolved using [cor_mmp_max_period_nbr]. Best estimates for the size of this group is <0.1%
   of the population. We have left these duplicate records in place.
4) IDI metadata: There are major management period start dates from 1882, however consistent 
   records did not appear until 1919 [although, unlikely & small numbers till the 1950s].

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]
 
Issues:
- Trivial number of records have start_date > end_date
 
History (reverse order):
2022-05-17 VW Update to latest refresh, point to [DL-MAA2018-48], add note on date coverage
2022-02-18 PM Update to latest refresh, point to [DL-MAA2021-60]
2021-06-09 SA QA
2021-06-04 FL update the input data to the latest reference
2020-11-19 FL QA
2020-02-28 SA v1
**************************************************************************************************/



/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA2018-48].[defn_corrections_prison]','V') IS NOT NULL
DROP VIEW [DL-MAA2018-48].[defn_corrections_prison];
GO

/* Create view */
CREATE VIEW [DL-MAA2018-48].[defn_corrections_prison] AS
SELECT a.snz_uid
	,a.cor_mmp_prev_mmc_code
	,a.cor_mmp_mmc_code
	,a.cor_mmp_next_mmc_code
	,a.cor_mmp_index_offence_code
	,a.cor_mmp_imposed_sentence_length_nbr
	,a.cor_mmp_sentence_location_text
	,a.cor_mmp_period_start_date AS [start_date]
	,a.cor_mmp_period_end_date AS [end_date]
FROM [IDI_Clean_202203].[cor_clean].[ov_major_mgmt_periods_historic] a
INNER JOIN (
	SELECT snz_uid, MAX(cor_mmp_max_period_nbr) AS cor_mmp_max_period_nbr
	FROM [IDI_Clean_202203].[cor_clean].[ov_major_mgmt_periods_historic]
	GROUP BY snz_uid
) b
ON a.snz_uid = b.snz_uid
AND a.cor_mmp_max_period_nbr = b.cor_mmp_max_period_nbr
WHERE cor_mmp_mmc_code = 'PRISON'
AND cor_mmp_period_start_date IS NOT NULL
AND cor_mmp_period_end_date IS NOT NULL
AND cor_mmp_period_start_date <= cor_mmp_period_end_date;
GO
