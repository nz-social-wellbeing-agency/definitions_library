/**************************************************************************************************
Title: Spell living in community housing
Author: Hubert Zal

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
A spell for a person living in community housing.

Intended purpose:
Creating indicators of when/whether a person has lived in community housing.
Identifying spells when a person is living in community housing.
Counting the number of days a person spends in community housing.
 
Inputs & Dependencies:
- [IDI_Clean].[hnz_clean].[tenancy_household_snapshot]
- [IDI_Clean].[hnz_clean].[tenancy_snapshot]

Outputs:
- [IDI_Sandpit].[$(PROJSCH)].[tenancy_community_housing]

Notes:
1) The snapshot table identifies who was in a house at given points of time. Where the 
   same person appears in consecutive snapshots we infer they are in the house during the
   intervening time.
2) Condensing is used to avoid double counting where different tenancies overlap.
   If condensing is slow, pre-filtering the input tables may improve speed.

Parameters & Present values:
1. [$(PROJSCH)] = Project schema. "DL-MAA20XX-YY"
2. [$(IDIREF)] = Current refresh. "IDI_Clean_YYYYMM"
3. [$(TBLPREF)] = Prefix. "tmp"

 
Issues:
 
History (reverse order):
**************************************************************************************************/
--PARAMETERS##################################################################################################
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
--Already in master.sql; Uncomment when running individually
:setvar TBLPREF "tmp" 
:setvar IDIREF "IDI_Clean_YYYYMM" 
:setvar PROJSCH "DL-MAA20XX-YY"
GO

--##############################################################################################################
 USE IDI_Sandpit;

/* Include only tenancies which are Community Housing Providers (CHP) and where the primary has an associated address.*/
/* Condensed spells */
/*Link primaries from [tenancy_snapshot] to remaining household occupants in [tenancy_household_snaphot].*/
DROP TABLE IF EXISTS [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_tenancy_staging1];
GO

SELECT
		 a.[snz_uid]
		,a.[snz_household_uid]
		,a.[hnz_ths_snapshot_date]
		,b.[msd_provider_name_text]
		,b.[snz_idi_address_register_uid]
		,a.[hnz_ths_app_relship_text]
INTO [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_tenancy_staging1]
FROM [$(IDIREF)].[hnz_clean].[tenancy_household_snapshot] a
INNER JOIN [$(IDIREF)].[hnz_clean].[tenancy_snapshot] b
ON  a.[snz_household_uid] = b.[snz_household_uid]
AND a.[hnz_ths_snapshot_date] = b.[hnz_ts_snapshot_date]
WHERE b.[msd_provider_name_text] = 'CHP' -- Community Housing Providers
AND b.[snz_idi_address_register_uid] IS NOT NULL

/* Condensed spells - Spells are monthly snapshots. 
If snapshot dates are approx. a month apart then condense snapshot dates into start and end dates. */
DROP TABLE IF EXISTS [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_tenancy_staging2];
GO

/* Create staging table */
SELECT 
		 a.[snz_uid]
		,a.[hnz_ths_snapshot_date] AS [start_date]
		,b.[hnz_ths_snapshot_date] AS [end_date]
		,a.[snz_idi_address_register_uid]
		,a.snz_household_uid
		,a.[hnz_ths_app_relship_text]
INTO [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_tenancy_staging2]
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_tenancy_staging1] a
INNER JOIN [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_tenancy_staging1] b
ON a.snz_uid = b.snz_uid
WHERE DATEDIFF(DAY, a.[hnz_ths_snapshot_date], b.[hnz_ths_snapshot_date]) BETWEEN 20 AND 40 -- adjacent months
AND a.[snz_idi_address_register_uid] = b.[snz_idi_address_register_uid]

/* Condensed spells - merge all the spells to determine true end date */
DROP TABLE IF EXISTS [IDI_Sandpit].[$(PROJSCH)].[tenancy_community_housing];
GO

WITH
/* exclude start dates that are within another spell */
spell_starts AS (
	SELECT 
		 [snz_uid] 
		,[start_date]
		,[snz_idi_address_register_uid]
		,[hnz_ths_app_relship_text] 
		,[snz_household_uid]
	FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_tenancy_staging2] s1
	WHERE [start_date] <= [end_date] --This does not result in any records being excluded, however it is included in case a start_date ever occurs after the end_date in future updates.
	AND NOT EXISTS (
		SELECT 1
		FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_tenancy_staging2] s2
		WHERE s1.[snz_uid] = s2.[snz_uid]
		AND DATEADD(DAY, -1, s1.[start_date]) BETWEEN s2.[start_date] AND s2.[end_date]
	)
),
/* exclude end dates that are within another spell */
spell_ends AS (
	SELECT 
		 [snz_uid]
		,[end_date]
		,[snz_idi_address_register_uid]
	FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_tenancy_staging2] t1
	WHERE [start_date] <= [end_date]
	AND NOT EXISTS (
		SELECT 1 
		FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_tenancy_staging2] t2
		WHERE t2.snz_uid = t1.snz_uid
		AND IIF(YEAR(t1.[end_date]) = 9999, t1.[end_date], DATEADD(DAY, 1, t1.[end_date])) BETWEEN t2.[start_date] AND t2.[end_date]
	)
)
SELECT 
		 s.[snz_uid]
		,s.[start_date]
		,MIN(e.[end_date]) AS [end_date]
		,s.[snz_idi_address_register_uid]
		--,s.[hnz_ths_app_relship_text] --used for testing purposes
		--,s.[snz_household_uid] --used for testing purposes
INTO [IDI_Sandpit].[$(PROJSCH)].[tenancy_community_housing]
FROM spell_starts s
INNER JOIN spell_ends e
ON s.[snz_uid] = e.[snz_uid]
AND s.[start_date] <= e.[end_date]
GROUP BY s.snz_uid, s.[start_date], s.[snz_idi_address_register_uid], s.[hnz_ths_app_relship_text], s.[snz_household_uid]

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[$(PROJSCH)].[tenancy_community_housing] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[$(PROJSCH)].[tenancy_community_housing] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/* Clear staging tables */
DROP TABLE IF EXISTS [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_tenancy_CHP_primary];
DROP TABLE IF EXISTS [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_tenancy_staging1];
DROP TABLE IF EXISTS [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_tenancy_staging2];
GO
