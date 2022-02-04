/**************************************************************************************************
Title: Receipt of disability benefit
Author: Freya Li
Reviewer: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[msd_clean].[msd_second_tier_expenditure]
- main_benefits_by_type_and_partner_status.sql --> [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_abt_main_benefit_final]
Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_disability_ben_spell]
- [IDI_UserCode].[DL-MAA2020-01].[d2gP2_census_disability]

Description
Indication of receipt of a disability from Census
and diasbility associated with benefit receipt

Intended purpose:
Creating indicators of when/whether a person was receiving a disability associated benefit.
Identifying spells when a person is receiving a disability associated benefit.
Counting the number of days a person spends receiving disability associated benefit.

Notes:
1) Disability associated benefits were specified by MSD staff as:
	- Jobseeker Support - Health Condition and Disability
	- Supported Living payment
	- Disability Allowance
	- Child Disability Allowance
2) Jobseeker Support - Health Condition and Disability and Supported Living payment
	are main benefits (Tier 1). Information on these benefits is drawn from
	[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_abt_main_benefit_final] which derives from [msd_spell].
3) Disability Allowance and Child Disability Allowance
	are supplementary benefits (Tier 2). Information on these benefits is drawn from
   [msd_second_tier_expenditure] (Supplementary service code [msd_ste_supp_serv_code]: '65', '425', '838')
4) Input table [d2gP2_abt_main_benefit_final] already contains condensing and preparation.
   But when we discard the benefit type and beneficiary role, further condensing is necessary
   to avoid double counting.
5) Condensing can be slow. But speed improvements arise from pre-filtering the input tables
   to narrower dates of interest.
6) "The 2013 New Zealand Disability Survey estimated that a total of 1.1 million New Zealanders were disabled."
   From census 2018 data, There are 1.3 million individuals are identified as having some difficulty' or 
   'a lot of difficulty' or 'cannot do at all' one or more of the six activities in the activity limitations 
   questions, the number is consistent with the survey results. However, in census data, a person is regarded 
   as disabled if they have 'a lot of difficulty' or 'cannot do at all' one or more of the six activities in 
   the activity limitations questions. We are using the [cen_ind_dsblty_ind_code] as disability indicator, 
   which classifies around 242,000 individuals as disabled.
7) There are ~73000 individuals are recorded as disability in both Census and MSD approaches.


Parameters & Present values:
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]
  Earliest start date = '2012-01-01'
  Latest end date = '2020-12-31'
 
Issues:
 
History (reverse order):
2021-06-14 SA QA complete
2021-06-14 FL revision to QA
2021-06-09 FL v1
**************************************************************************************************/

/**************************************************************************************************
Census disability records

Stats NZ uses the following definition of disability for Census:
A person is regarded as disabled if they have 'a lot of difficulty' or 'cannot do at all' one or 
more of the six activities in the activity limitations questions.

cat_code	descriptor_text
0              	No Disability
1              	Disability
7              	Response Unidentifiable
9              	Not Stated
**************************************************************************************************/

USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2020-01].[d2gP2_census_disability]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2gP2_census_disability];
GO


CREATE VIEW [DL-MAA2020-01].[d2gP2_census_disability] AS
SELECT [snz_uid]
      ,[snz_cen_uid]
	  ,'2018-03-06' AS [event_date]
      ,IIF([cen_ind_dsblty_ind_code] = 1, 1, 0 ) AS [cen_dsblty_ind] 
      ,CAST([cen_ind_dffcl_comt_code]  AS NUMERIC(2, 0)) AS [cen_ind_dffcl_comt_code]    --1  No difficulty; 2  Some difficulty; 3  A lot of difficulty; 4  Cannot do at all; 7  Response unidentifiable; 9  Not stated
      ,CAST([cen_ind_dffcl_hearing_code] AS NUMERIC(2, 0)) AS [cen_ind_dffcl_hearing_code]
      ,CAST([cen_ind_dffcl_remembering_code] AS NUMERIC(2, 0)) AS [cen_ind_dffcl_remembering_code]
      ,CAST([cen_ind_dffcl_seeing_code] AS NUMERIC(2, 0)) AS [cen_ind_dffcl_seeing_code]
      ,CAST([cen_ind_dffcl_walking_code] AS NUMERIC(2, 0)) AS [cen_ind_dffcl_walking_code]
      ,CAST([cen_ind_dffcl_washing_code] AS NUMERIC(2, 0)) AS [cen_ind_dffcl_washing_code]
	  ,IIF([cen_ind_dffcl_comt_code] IN (2,3,4) 
	  OR [cen_ind_dffcl_hearing_code] IN (2,3,4)
	  OR [cen_ind_dffcl_remembering_code] IN (2,3,4)
	  OR [cen_ind_dffcl_seeing_code] IN (2,3,4)
	  OR [cen_ind_dffcl_walking_code] IN (2,3,4)
	  OR [cen_ind_dffcl_washing_code] IN (2,3,4), 1, 0) AS cen_dffcl_act_ind  --indication of an individual has some difficulty or above for the 6 activities.
FROM [IDI_Clean_20201020].[cen_clean].[census_individual_2018]
GO

/***************************************************************************************
Disability associaed benefit from  [msd_second_tier_expenditure]
***************************************************************************************/

/*drop before re-creating*/
IF OBJECT_ID('[DL-MAA2020-01].[tmp_ste_benefit_spell_input]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[tmp_ste_benefit_spell_input];
GO

/*View for main recipient (who receiving disbility allowance and child disability allowance) spells*/
CREATE VIEW [DL-MAA2020-01].[tmp_ste_benefit_spell_input] AS
SELECT snz_uid 
       ,[msd_ste_supp_serv_code]
	   ,[msd_ste_start_date] AS [start_date]
	   ,COALESCE([msd_ste_end_date],  '9999-01-01') AS [end_date]
FROM [IDI_Clean_20201020].[msd_clean].[msd_second_tier_expenditure]
WHERE [msd_ste_supp_serv_code] IN ('65', '425', '838')  -- 65: child disability allowance; 425: disability allowance; 838: special disability allowance
GO

/*********************************************************************************************
Put the disbility associated benefit from second tier expenditure together with msd_spell
*********************************************************************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_disability_ben_spell]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_disability_ben_spell];
GO

/*filter disability associated benefit from main be*/
SELECT *
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_disability_ben_spell]
FROM (
	SELECT snz_uid
		  --,role
		  ,[start_date]
		  ,[end_date]
		  ,msd_spel_servf_code AS serv_code
		  ,level1
		  ,level2
		  ,level3
		  ,level4
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_abt_main_benefit_final]
	WHERE [role] <> 'partner'
		AND [level3] IN ('Job Seeker Health Condition Or Disability', 'Supported Living Payment', 'Supported Living Payment Carers')
		AND [start_date] <= [end_date]
		AND '2012-01-01' <= [end_date]
		AND [start_date] <= '2020-12-31'

	UNION ALL

	SELECT a.[snz_uid]
		  --,'Primary/Single' AS [role] 
		  ,a.[start_date]
		  ,a.[end_date]
		  ,a.[msd_ste_supp_serv_code] AS [serv_code]
		  ,code.level1
		  ,code.level2
		  ,code.level3
		  ,code.level4
	FROM [DL-MAA2020-01].[tmp_ste_benefit_spell_input] a
	LEFT JOIN [IDI_Adhoc].[clean_read_MSD].[benefit_codes] code
	ON a.[msd_ste_supp_serv_code] = code.serv
	AND code.[ValidFromtxt] <= a.[start_date]
	AND a.[start_date] <= code.[validTotxt]
	WHERE '2012-01-01' <= [end_date]
	AND [start_date] <= '2020-12-31'
) a

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_disability_ben_spell] (snz_uid);
GO


/********************************************************************************
Condense disability associated Benefit spells -- second tier and msd_spell

Where the same person has overlapping benefit spells, or a new spell
starts the same day, then merge the spells.
*********************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_disability_ben_spell]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_disability_ben_spell];
GO

/*Create table with condensed spells*/
WITH
/*exclude starrt date that are within another spell*/
spell_starts AS (
	SELECT [snz_uid], [start_date]
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_disability_ben_spell] s1
	WHERE NOT EXISTS (
		SELECT 1
		FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_disability_ben_spell] s2
		WHERE s1.snz_uid = s2.snz_uid 
		AND DATEADD(DAY, -1, s1.[start_date]) BETWEEN s2.[start_date] AND s2.[end_date]
	)
),
/*exclude end dates that are within another spell*/
spell_ends AS (
	SELECT [snz_uid], [end_date]
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_disability_ben_spell] t1
	WHERE NOT EXISTS (
		SELECT 1
		FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_disability_ben_spell] t2
		WHERE t1.[snz_uid] = t2.[snz_uid]
		AND YEAR(t1.[end_date]) <> 9999
		AND DATEADD(DAY, 1, t1.[end_date]) BETWEEN t2.[start_date] AND t2.[end_date]
	)
)
SELECT s.snz_uid
      ,s.[start_date]
	  ,MIN(e.[end_date]) AS [end_date]
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_disability_ben_spell]
FROM spell_starts s
INNER JOIN spell_ends e
ON s.snz_uid = e.snz_uid
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date]
GO


/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_disability_ben_spell] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_disability_ben_spell] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO



/**************************************************************************************************
Remove temporary tables
**************************************************************************************************/
IF OBJECT_ID('[DL-MAA2020-01].[tmp_ste_benefit_spell_input]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[tmp_ste_benefit_spell_input];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ste_disability_ben_spell]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_ste_disability_ben_spell];
GO

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_disability_ben_spell]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_tmp_disability_ben_spell];
GO



/********************************************************************************
SELECT COUNT(DISTINCT cen.snz_uid)
FROM [IDI_UserCode].[DL-MAA2020-01].[d2gP2_census_disability] cen
WHERE EXISTS (
	SELECT 1
	FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_msd_disability_ben_spell] msd
	WHERE cen.snz_uid = msd.snz_uid
	AND YEAR(msd.start_date) <= 2018
	AND YEAR(msd.end_date) >=2018
	)
-- there are ~73000 individuals has disability records in both census and msd tables
********************************************************************************/




