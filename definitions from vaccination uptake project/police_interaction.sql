/**************************************************************************************************
Title: Flag for recent police interaction
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[pol_clean].[post_count_victimisations]
- [IDI_Clean].[pol_clean].[post_count_offenders]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_police_interaction]

Description:
Flag for recent police interaction as victim or offender.

Intended purpose:
Identifying whether people have interacted with police in 2020 or 2021
and if so as a victim or as an offender.

Notes:

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
  
Issues:

History (reverse order):
2021-10-31 CW
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_police_interaction]
GO

/* create */
WITH
pol_off AS (

	SELECT DISTINCT [snz_uid]
		  ,[snz_jus_uid]
		  ,1 AS the_type
		  ,[pol_pov_year_nbr] AS the_year
	FROM [IDI_Clean_20211020].[pol_clean].[post_count_victimisations]
	WHERE [pol_pov_year_nbr] in (2020,2021)

),
pol_vic AS (

	SELECT DISTINCT [snz_uid]
		  ,[snz_jus_uid]
		  ,2 AS the_type
		  ,[pol_poo_year_nbr] AS the_year
	FROM [IDI_Clean_20211020].[pol_clean].[post_count_offenders]
	WHERE [pol_poo_year_nbr] in (2020,2021)

),
all_ids AS (

	SELECT DISTINCT snz_uid
	FROM (
		SELECT snz_uid FROM pol_off
		UNION ALL
		SELECT snz_uid FROM pol_vic
	) AS k

)
SELECT a.snz_uid
	,CASE WHEN b.the_type IS NULL THEN 0 ELSE 1 END AS off_2020
	,CASE WHEN c.the_type IS NULL THEN 0 ELSE 1 END AS off_2021
	,CASE WHEN d.the_type IS NULL THEN 0 ELSE 1 END AS vic_2020
	,CASE WHEN e.the_type IS NULL THEN 0 ELSE 1 END AS vic_2021
INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_police_interaction]
FROM all_ids AS a
LEFT JOIN pol_off AS b
ON a.snz_uid = b.snz_uid AND b.the_year=2020
LEFT JOIN pol_off AS c
ON a.snz_uid = c.snz_uid AND c.the_year=2021
LEFT JOIN pol_vic AS d 
ON a.snz_uid = d.snz_uid AND d.the_year=2020
LEFT JOIN pol_vic AS e
ON a.snz_uid = e.snz_uid AND e.the_year=2021
GO

/* index */
CREATE NONCLUSTERED INDEX mu_index ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_police_interaction] (snz_uid)
GO
