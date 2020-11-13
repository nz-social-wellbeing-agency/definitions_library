/**************************************************************************************************
Title: Parent of a child under 5 years old
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[dia_clean].[births]
- [IDI_Clean].[data].[address_notification] 
Outputs:
- [IDI_Sandpit].[DL-MAA2016-15].[defn_parent_under5_share_address]

Description:
Identifies years in which a person is a parent of a child under the age of 5
and the person has at least one address in common with the child.

Intended purpose:
Identifying whether a person is actively parenting a child under the age of 5.

Notes:
1) We use the age of 5 as until this age children do not have to attend school regularly.
2) We require that the parent has at least one address in common with the child
   as a proxy for whether the parent is living with, and involved in caring for,
   their child.
   Where there is a sole parent caring for the child, but both parents are named on the
   birth record, this should help reduce counting of the non-caring parent. But it
   is only an approximation.
3) Because babies may not have an address immediately after they are born,
   for the first year of birth, we require an address match in the first two years.
4) Script returns the message:
   "Warning: Null value is eliminated by an aggregate or other SET operation."
   This is not a cause for concern. We deliberately use aggregation to eliminate nulls.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]
  Min birth year = 2010
  Max age of child = 5 {this parameter can not be updated via find & replace}

Issues:
1) The crudeness with which we have filtered out parents who do not share an address
   with their child means that this definition is not suited to identifying specific
   individuals who are actively parenting. We recommend it only be used in aggregate
   and with clear caveats.
 
History (reverse order):
2020-05-25 SA v1
**************************************************************************************************/

/*********** all parents and spells when child is aged under 5 ***********/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_parent_under5]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_parent_under5];
GO

SELECT [snz_uid]
	,[dob]
	,[child_snz_uid]
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_parent_under5]
FROM (

SELECT [parent1_snz_uid] AS [snz_uid]
	,[dia_bir_birth_month_nbr]
	,[dia_bir_birth_year_nbr]
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS dob
	,[dia_bir_still_birth_code]
	,[snz_uid] AS child_snz_uid
FROM [IDI_Clean_20200120].[dia_clean].[births]
WHERE [parent1_snz_uid] IS NOT NULL

UNION ALL

SELECT [parent2_snz_uid] AS [snz_uid]
	,[dia_bir_birth_month_nbr]
	,[dia_bir_birth_year_nbr]
	,DATEFROMPARTS([dia_bir_birth_year_nbr], [dia_bir_birth_month_nbr], 15) AS dob
	,[dia_bir_still_birth_code]
	,[snz_uid] AS child_snz_uid
FROM [IDI_Clean_20200120].[dia_clean].[births]
WHERE [parent2_snz_uid] IS NOT NULL
AND ([parent1_snz_uid] IS NULL OR [parent1_snz_uid] <> [parent2_snz_uid])

) k
WHERE [dia_bir_still_birth_code] IS NULL
AND [dia_bir_birth_year_nbr] >= 2010;

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_parent_under5] (snz_uid);
GO

/*********** Must share address ***********/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_parent_under5_share_address]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_parent_under5_share_address];
GO

WITH
year1 AS (
	SELECT pc.[snz_uid]
		  ,DATEADD(YEAR, 0, pc.[dob]) AS [start_date]
		  ,DATEADD(YEAR, 1, pc.[dob]) AS [end_date]
		  ,pc.[child_snz_uid]
		  ,COUNT(ca.[snz_idi_address_register_uid]) AS num_address_matches
	FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_parent_under5] pc /* parent & child */
	LEFT JOIN [IDI_Clean_20200120].[data].[address_notification] pa /* parent address */
	ON pc.[snz_uid] = pa.[snz_uid]
	AND pa.[ant_notification_date] <= DATEADD(YEAR, 2, pc.[dob]) /* extended to 2 years after in case babies don't have address */
	AND DATEADD(YEAR, 0, pc.[dob]) <= pa.[ant_replacement_date]
	LEFT JOIN [IDI_Clean_20200120].[data].[address_notification] ca /* child address */
	ON pc.[child_snz_uid] = ca.[snz_uid]
	AND pa.[ant_notification_date] <= DATEADD(YEAR, 2, pc.[dob]) /* extended to 2 years after in case babies don't have address */
	AND DATEADD(YEAR, 0, pc.[dob]) <= pa.[ant_replacement_date]
	AND pa.[snz_idi_address_register_uid] = ca.[snz_idi_address_register_uid]
	GROUP BY pc.[snz_uid]
		  ,pc.[dob]
		  ,pc.[child_snz_uid]
),
year2 AS (
	SELECT pc.[snz_uid]
		  ,DATEADD(YEAR, 1, pc.[dob]) AS [start_date]
		  ,DATEADD(YEAR, 2, pc.[dob]) AS [end_date]
		  ,pc.[child_snz_uid]
		  ,COUNT(ca.[snz_idi_address_register_uid]) AS num_address_matches
	FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_parent_under5] pc /* parent & child */
	LEFT JOIN [IDI_Clean_20200120].[data].[address_notification] pa /* parent address */
	ON pc.[snz_uid] = pa.[snz_uid]
	AND pa.[ant_notification_date] <= DATEADD(YEAR, 2, pc.[dob])
	AND DATEADD(YEAR, 1, pc.[dob]) <= pa.[ant_replacement_date]
	LEFT JOIN [IDI_Clean_20200120].[data].[address_notification] ca /* child address */
	ON pc.[child_snz_uid] = ca.[snz_uid]
	AND pa.[ant_notification_date] <= DATEADD(YEAR, 2, pc.[dob])
	AND DATEADD(YEAR, 1, pc.[dob]) <= pa.[ant_replacement_date]
	AND pa.[snz_idi_address_register_uid] = ca.[snz_idi_address_register_uid]
	GROUP BY pc.[snz_uid]
		  ,pc.[dob]
		  ,pc.[child_snz_uid]
),
year3 AS (
	SELECT pc.[snz_uid]
		  ,DATEADD(YEAR, 2, pc.[dob]) AS [start_date]
		  ,DATEADD(YEAR, 3, pc.[dob]) AS [end_date]
		  ,pc.[child_snz_uid]
		  ,COUNT(ca.[snz_idi_address_register_uid]) AS num_address_matches
	FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_parent_under5] pc /* parent & child */
	LEFT JOIN [IDI_Clean_20200120].[data].[address_notification] pa /* parent address */
	ON pc.[snz_uid] = pa.[snz_uid]
	AND pa.[ant_notification_date] <= DATEADD(YEAR, 3, pc.[dob])
	AND DATEADD(YEAR, 2, pc.[dob]) <= pa.[ant_replacement_date]
	LEFT JOIN [IDI_Clean_20200120].[data].[address_notification] ca /* child address */
	ON pc.[child_snz_uid] = ca.[snz_uid]
	AND pa.[ant_notification_date] <= DATEADD(YEAR, 3, pc.[dob])
	AND DATEADD(YEAR, 2, pc.[dob]) <= pa.[ant_replacement_date]
	AND pa.[snz_idi_address_register_uid] = ca.[snz_idi_address_register_uid]
	GROUP BY pc.[snz_uid]
		  ,pc.[dob]
		  ,pc.[child_snz_uid]
),
year4 AS (
	SELECT pc.[snz_uid]
		  ,DATEADD(YEAR, 3, pc.[dob]) AS [start_date]
		  ,DATEADD(YEAR, 4, pc.[dob]) AS [end_date]
		  ,pc.[child_snz_uid]
		  ,COUNT(ca.[snz_idi_address_register_uid]) AS num_address_matches
	FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_parent_under5] pc /* parent & child */
	LEFT JOIN [IDI_Clean_20200120].[data].[address_notification] pa /* parent address */
	ON pc.[snz_uid] = pa.[snz_uid]
	AND pa.[ant_notification_date] <= DATEADD(YEAR, 4, pc.[dob])
	AND DATEADD(YEAR, 3, pc.[dob]) <= pa.[ant_replacement_date]
	LEFT JOIN [IDI_Clean_20200120].[data].[address_notification] ca /* child address */
	ON pc.[child_snz_uid] = ca.[snz_uid]
	AND pa.[ant_notification_date] <= DATEADD(YEAR, 4, pc.[dob])
	AND DATEADD(YEAR, 3, pc.[dob]) <= pa.[ant_replacement_date]
	AND pa.[snz_idi_address_register_uid] = ca.[snz_idi_address_register_uid]
	GROUP BY pc.[snz_uid]
		  ,pc.[dob]
		  ,pc.[child_snz_uid]
),
year5 AS (
	SELECT pc.[snz_uid]
		  ,DATEADD(YEAR, 4, pc.[dob]) AS [start_date]
		  ,DATEADD(YEAR, 5, pc.[dob]) AS [end_date]
		  ,pc.[child_snz_uid]
		  ,COUNT(ca.[snz_idi_address_register_uid]) AS num_address_matches
	FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_parent_under5] pc /* parent & child */
	LEFT JOIN [IDI_Clean_20200120].[data].[address_notification] pa /* parent address */
	ON pc.[snz_uid] = pa.[snz_uid]
	AND pa.[ant_notification_date] <= DATEADD(YEAR, 5, pc.[dob])
	AND DATEADD(YEAR, 4, pc.[dob]) <= pa.[ant_replacement_date]
	LEFT JOIN [IDI_Clean_20200120].[data].[address_notification] ca /* child address */
	ON pc.[child_snz_uid] = ca.[snz_uid]
	AND pa.[ant_notification_date] <= DATEADD(YEAR, 5, pc.[dob])
	AND DATEADD(YEAR, 4, pc.[dob]) <= pa.[ant_replacement_date]
	AND pa.[snz_idi_address_register_uid] = ca.[snz_idi_address_register_uid]
	GROUP BY pc.[snz_uid]
		  ,pc.[dob]
		  ,pc.[child_snz_uid]
)
SELECT [snz_uid], [start_date], [end_date], [child_snz_uid], [num_address_matches]
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_parent_under5_share_address]
FROM (
	SELECT * FROM year1 UNION ALL
	SELECT * FROM year2 UNION ALL
	SELECT * FROM year3 UNION ALL
	SELECT * FROM year4 UNION ALL
	SELECT * FROM year5
) k
WHERE [num_address_matches] > 0
GO

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_parent_under5_share_address] (snz_uid);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_parent_under5_share_address] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/* remove staging table */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_parent_under5]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_parent_under5];
GO