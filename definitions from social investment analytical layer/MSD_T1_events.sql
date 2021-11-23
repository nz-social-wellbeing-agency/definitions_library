/**************************************************************************************************
Title: MSD Tier 1 events
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[msd_clean].[msd_spell]
- [IDI_Clean].[msd_clean].[msd_partner]
- [IDI_Adhoc].[clean_read_MSD].[benefit_codes]
Outputs:
- [IDI_Sandpit].[DL-MAA2016-15].[sial_MSD_T1_events]

Description:
Create MSD Tier 1 benefit costs table

Notes:
0) This definition originates in the SIAL. The SIAL was retired mid-2020
   and is no longer supported. This definition has been provided for
   researchers wanting to contiune to use this SIAL definition.
1) See SIAL data dictionary for original documentation of business rules.
2) SAS code for the same purpose has been developed by Marc de Boer & team at MSD.
   We provide this equivalent approach in SQL. As it is more compact, and has only the
   details necessary for the creation of this table.
3) SQL code has almost perfect consistency with original SAS code. Examination of the
   differences suggest the SQL code corrects small errors in the original SAS.
   E.g. exclusion of records with zero duration, consistent merging of spells.
4) As per the MSD data dictionary: Benefit tables in the IDI cover entitlements and
   IRD EMS records dispensing. Differences between these tables can be due to changes
   in entiltements, partial dispensing (e.g. due to automated deductions), and differences
   in timing (weekly/daily vs. monthly).
5) The script is long as several intermediate tables must first be built. All intermediate
   tables are deleted at the conclusion of the script.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = sial_
  Project schema = [DL-MAA2016-15]
 
Issues:
- A very small number of records are duplicates. As de-duplicating is very slow
  these have not been removed.
- Very slow. Runtime > 18 minutes.
 
History (reverse order):
2020-03-02 SA updated header
2019-06-05 SA validated against previous table >99% match
2016-10-01 MSD: Business QA complete
2016-06-28 V Benny: Created
**************************************************************************************************/

/********************************************************************************
Interface

Views to provide an easy point of correction if columns renamed
********************************************************************************/

USE IDI_UserCode
GO

/* drop before re-creating */
IF OBJECT_ID('[DL-MAA2016-15].[tmp_main_benefit_spell_input]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[tmp_main_benefit_spell_input];
GO
IF OBJECT_ID('[DL-MAA2016-15].[tmp_main_benefit_partner_input]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[tmp_main_benefit_partner_input];
GO

/* view for main recipient spells */
CREATE VIEW [DL-MAA2016-15].[tmp_main_benefit_spell_input] AS
SELECT [snz_uid]
      ,COALESCE([msd_spel_servf_code], 'null') AS [msd_spel_servf_code]
      ,COALESCE([msd_spel_add_servf_code], 'null') AS [msd_spel_add_servf_code] -- must coalesce away missing values to join col to itself
      ,[msd_spel_spell_start_date] AS [start_date]
      ,COALESCE([msd_spel_spell_end_date], '9999-01-01') AS [end_date]
FROM [IDI_Clean_20200120].[msd_clean].[msd_spell]
WHERE [msd_spel_spell_start_date] IS NOT NULL
AND ([msd_spel_spell_end_date] IS NULL
	OR [msd_spel_spell_start_date] <= [msd_spel_spell_end_date])
GO

/* view for partner spells */
CREATE VIEW [DL-MAA2016-15].[tmp_main_benefit_partner_input] AS
SELECT [snz_uid]
      ,[partner_snz_uid]
      ,[msd_ptnr_ptnr_from_date] AS [start_date]
      ,COALESCE([msd_ptnr_ptnr_to_date], '9999-01-01') AS [end_date]
FROM [IDI_Clean_20200120].[msd_clean].[msd_partner]
WHERE [msd_ptnr_ptnr_from_date] IS NOT NULL
AND ([msd_ptnr_ptnr_to_date] IS NULL
	OR [msd_ptnr_ptnr_from_date] <= [msd_ptnr_ptnr_to_date])
GO

/********************************************************************************
Condense Primary Benefit spells
(AKA packing date intervals OR merging overlapping spells)

Where the same person has overlapping benefit spells, or a new spell
starts the same day/the day after an old spell ends, then merge the spells.

E.g. 
start_date   end_date
2001-01-01   2001-01-05
2001-01-06   2001-01-12
2001-02-09   2001-02-14
2001-02-12   2001-02-18
2001-02-18   2001-02-29
2010-10-10   2010-10-10

becomes
start_date   end_date
2001-01-01   2001-01-12
2001-02-09   2001-02-29
2010-10-10   2010-10-10
********************************************************************************/

/* drop table before re-creating */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_spell_condensed]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_spell_condensed];
GO

/* create table with condensed spells */
WITH
/* exclude start dates that are within another spell */
spell_starts AS (
	SELECT [snz_uid]
		,[msd_spel_servf_code]
		,[msd_spel_add_servf_code]
	    ,[start_date]
	    ,[end_date]
	FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_main_benefit_spell_input] s1
	WHERE NOT EXISTS (
		SELECT 1
		FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_main_benefit_spell_input] s2
		WHERE s1.snz_uid = s2.snz_uid
		AND s1.[msd_spel_servf_code] = s2.[msd_spel_servf_code]
		AND s1.[msd_spel_add_servf_code] = s2.[msd_spel_add_servf_code]
		AND s2.[start_date] < s1.[start_date] 
		AND s1.[start_date] <= s2.[end_date]
	)
),
/* exclude end dates that are within another spell */
spell_ends AS (
	SELECT [snz_uid]
	    ,[msd_spel_servf_code]
		,[msd_spel_add_servf_code]
	    ,[start_date]
	    ,[end_date]
	FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_main_benefit_spell_input] t1
	WHERE NOT EXISTS (
		SELECT 1 
		FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_main_benefit_spell_input]  t2
		WHERE t2.snz_uid = t1.snz_uid
		AND t1.[msd_spel_servf_code] = t2.[msd_spel_servf_code]
		AND t1.[msd_spel_add_servf_code] = t2.[msd_spel_add_servf_code]
		AND t2.[start_date] <= t1.[end_date] 
		AND t1.[end_date] < t2.[end_date]
	)
)
SELECT s.snz_uid
	,s.[msd_spel_servf_code]
	,s.[msd_spel_add_servf_code]
	,s.[start_date]
	,MIN(e.[end_date]) as [end_date]
INTO [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_spell_condensed]
FROM spell_starts s
INNER JOIN spell_ends e
ON s.snz_uid = e.snz_uid
AND s.[msd_spel_servf_code] = e.[msd_spel_servf_code]
AND s.[msd_spel_add_servf_code] = e.[msd_spel_add_servf_code]
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date], s.[msd_spel_servf_code], s.[msd_spel_add_servf_code]
ORDER BY s.[start_date]
GO

/********************************************************************************
Condense Partner Benefit spells
As per the same logic for primary benefit spells

Note that we ignore the benefit type of the main beneficiary.
********************************************************************************/

/* drop table before re-creating */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_condensed]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_condensed];
GO

/* create table with condensed spells */
WITH
/* exclude start dates that are within another spell */
spell_starts AS (
	SELECT [snz_uid]
		  ,[partner_snz_uid]
	      ,[start_date]
	      ,[end_date]
	FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_main_benefit_partner_input] s1
	WHERE NOT EXISTS (
		SELECT * 
		FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_main_benefit_partner_input] s2
		WHERE s1.snz_uid = s2.snz_uid
		AND s1.[partner_snz_uid] = s2.[partner_snz_uid]
		AND s2.[start_date] < s1.[start_date] 
		AND s1.[start_date] <= s2.[end_date]
	)
),
/* exclude end dates that are within another spell */
spell_ends AS (
	SELECT [snz_uid]
		  ,[partner_snz_uid]
	      ,[start_date]
	      ,[end_date]
	FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_main_benefit_partner_input] t1
	WHERE NOT EXISTS (
		SELECT * 
		FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_main_benefit_partner_input]  t2
		WHERE t2.snz_uid = t1.snz_uid
		AND t1.[partner_snz_uid] = t2.[partner_snz_uid]
		AND t2.[start_date] <= t1.[end_date] 
		AND t1.[end_date] < t2.[end_date]
	)
)
SELECT s.snz_uid
	,s.[partner_snz_uid]
	,s.[start_date]
	,MIN(e.[end_date]) as [end_date]
INTO [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_condensed]
FROM spell_starts s
INNER JOIN spell_ends e
ON s.snz_uid = e.snz_uid
AND s.[partner_snz_uid] = e.[partner_snz_uid]
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date], s.[partner_snz_uid]
ORDER BY s.[start_date]
GO


/********************************************************************************
Invert Primary benefit spells

Return periods where the person does not have any spells in the input table.
Requires that input table has already been condensed


E.g. 
start_date   end_date
2001-01-01   2001-01-05
2001-01-06   2001-01-12
2001-02-12   2001-02-18

becomes
start_date   end_date
1900-01-01   2000-12-31
2001-01-13   2001-02-11
2001-02-19   9999-12-31

********************************************************************************/

/* drop table before re-creating */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_spell_invert]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_spell_invert];
GO

/* create table with inverted spells */
SELECT [snz_uid]
	  ,'non-benefit' AS [description]
	  ,[start_date]
	  ,[end_date]
INTO [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_spell_invert]
FROM (
	/* all forward looking spells */
	SELECT [snz_uid]
		  ,DATEADD(DAY, 1, [end_date]) AS [start_date]
		  ,LEAD(DATEADD(DAY, -1, [start_date]), 1, '9999-01-01') OVER (
				PARTITION BY [snz_uid]
				ORDER BY [start_date] ) AS [end_date]
	FROM [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_spell_condensed]

	UNION ALL

	/* back looking spell (to 'origin of time') created separately */
	SELECT [snz_uid]
		  ,'1900-01-01' AS [start_date]
		  ,DATEADD(DAY, -1, MIN([start_date])) AS [end_date]
	FROM [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_spell_condensed]
	GROUP BY [snz_uid]
) k
WHERE [start_date] <= [end_date]
AND '1900-01-01' <= [start_date] 
AND [end_date] <= '9999-01-01'
GO


/********************************************************************************
Invert Partner Benefit spells
As per the same logic for primary benefit spells
********************************************************************************/

/* drop table before re-creating */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_invert]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_invert];
GO

/* create table with inverted spells */
SELECT [snz_uid]
	  ,NULL AS [partner_snz_uid]
	  ,[start_date]
	  ,[end_date]
INTO [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_invert]
FROM (
	/* all forward looking spells */
	SELECT [snz_uid]
		  ,DATEADD(DAY, 1, [end_date]) AS [start_date]
		  ,LEAD(DATEADD(DAY, -1, [start_date]), 1, '9999-01-01') OVER (
				PARTITION BY [snz_uid]
				ORDER BY [start_date] ) AS [end_date]
	FROM [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_condensed]

	UNION ALL

	/* back looking spell (to 'origin of time') created separately */
	SELECT [snz_uid]
		  ,'1900-01-01' AS [start_date]
		  ,DATEADD(DAY, -1, MIN([start_date])) AS [end_date]
	FROM [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_condensed]
	GROUP BY [snz_uid]
) k
WHERE [start_date] <= [end_date]
AND '1900-01-01' <= [start_date]
AND [end_date] <= '9999-01-01'
GO

/********************************************************************************
Apply categorisation rules

If in spell AND not in partner THEN 'single'
If in spell AND in partner THEN 'primary'
If partner in partner AND not in spell THEN 'partner'
ONLY 'single' and 'primary' have additional benefit details (like type & amount)
********************************************************************************/

/* drop table before re-creating */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[sial_main_benefit_final]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_main_benefit_final];
GO

SELECT k.[snz_uid],
	'MSD' AS department,
	'BEN' AS datamart,
	'T1' AS subject_area,
	k.[start_date] AS [start_date],
	k.[end_date] AS [end_date],
	k.[msd_spel_servf_code] AS event_type,
	k.[msd_spel_add_servf_code] AS event_type_2,
	code.level1 AS event_type_3,
	code.level4 AS event_type_4
INTO [IDI_Sandpit].[DL-MAA2016-15].[sial_main_benefit_final]
FROM (

/* recipient where role = single as no partner during period */
	SELECT ys.[snz_uid]
		,'single' AS [role]
		,CASE WHEN ys.[start_date] <= np.[start_date] THEN np.[start_date] ELSE ys.[start_date] END AS [start_date] -- latest start date
		,CASE WHEN ys.[end_date]   <= np.[end_date]   THEN ys.[end_date]   ELSE np.[end_date]   END AS [end_date]   -- earliest end date
		,ys.[msd_spel_servf_code]
		,ys.[msd_spel_add_servf_code]
	FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_main_benefit_spell_input] ys -- yes, spell
	INNER JOIN [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_invert] np -- no, partner
	ON ys.snz_uid = np.snz_uid -- identity appears in both tables
	AND ys.[start_date] <= np.[end_date]
	AND np.[start_date] <= ys.[end_date] -- periods overlap

UNION ALL

/* recipient where role = single as never had partner */
	SELECT ys.[snz_uid]
		,'single' AS [role]
		,[start_date]
		,[end_date]
		,ys.[msd_spel_servf_code]
		,ys.[msd_spel_add_servf_code]
	FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_main_benefit_spell_input] ys -- yes, spell
	WHERE NOT EXISTS (
		SELECT 1
		FROM [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_invert] np -- no, partner
		WHERE ys.snz_uid = np.snz_uid -- identity appears in both tables
	)

UNION ALL

/* recipient where role = primary */
	SELECT ys.[snz_uid]
		,'primary' AS [role]
		,CASE WHEN ys.[start_date] <= yp.[start_date] THEN yp.[start_date] ELSE ys.[start_date] END AS [start_date] -- latest start date
		,CASE WHEN ys.[end_date]   <= yp.[end_date]   THEN ys.[end_date]   ELSE yp.[end_date]   END AS [end_date]   -- earliest end date
		,ys.[msd_spel_servf_code]
		,ys.[msd_spel_add_servf_code]
	FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_main_benefit_spell_input] ys -- yes, spell
	INNER JOIN [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_condensed] yp -- yes, partner
	ON ys.snz_uid = yp.snz_uid -- identity appears in both tables
	AND ys.[start_date] <= yp.[end_date]
	AND yp.[start_date] < ys.[end_date] -- periods overlap

UNION ALL

/* receipt as role = partner */
	SELECT yp.[partner_snz_uid] AS [snz_uid]
		,'partner' AS [role]
		,CASE WHEN ns.[start_date] <= yp.[start_date] THEN yp.[start_date] ELSE ns.[start_date] END AS [start_date] -- latest start date
		,CASE WHEN ns.[end_date]   <= yp.[end_date]   THEN ns.[end_date]   ELSE yp.[end_date]   END AS [end_date]   -- earliest end date
		,ns.[msd_spel_servf_code]
		,ns.[msd_spel_add_servf_code]
	FROM [IDI_UserCode].[DL-MAA2016-15].[tmp_main_benefit_partner_input] yp -- yes, partner
	LEFT JOIN [IDI_UserCode].[DL-MAA2016-15].[tmp_main_benefit_spell_input] ns -- no, spell
	ON ns.snz_uid = yp.snz_uid
	AND yp.[start_date] <= ns.[end_date]
	AND ns.[start_date] < yp.[end_date] -- periods overlap

) k
LEFT JOIN IDI_Adhoc.clean_read_MSD.benefit_codes code
ON k.msd_spel_servf_code = code.serv
AND (k.msd_spel_add_servf_code = code.additional_service_data
	OR (code.additional_service_data IS NULL 
		AND (k.msd_spel_add_servf_code ='null' OR k.msd_spel_add_servf_code IS NULL)
		))
AND code.ValidFromtxt <= k.[start_date]
AND k.[start_date] <= code.ValidTotxt
GO

/********************************************************************************
Tidy up and remove all temporary tables/views that have been created
********************************************************************************/


IF OBJECT_ID('[DL-MAA2016-15].[tmp_main_benefit_spell_input]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[tmp_main_benefit_spell_input];
GO
IF OBJECT_ID('[DL-MAA2016-15].[tmp_main_benefit_partner_input]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[tmp_main_benefit_partner_input];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_spell_condensed]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_spell_condensed];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_condensed]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_condensed];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_spell_invert]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_spell_invert];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_invert]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[tmp_main_benefit_partner_invert];
GO

CREATE CLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2016-15].[sial_main_benefit_final] ([snz_uid])

ALTER TABLE [IDI_Sandpit].[DL-MAA2016-15].[sial_main_benefit_final] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
