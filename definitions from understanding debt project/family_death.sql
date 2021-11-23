/**************************************************************************************************
Title: Death of an immediate family member
Author: Simon Anastasiadis
Reviewer: Marianna Pekar

Inputs & Dependencies:
- [IDI_Clean].[data].[personal_detail]
- [IDI_Clean].[dia_clean].[marriages]
- [IDI_Clean].[dia_clean].[civil_unions]
Outputs:
- [IDI_UserCode].[DL-MAA2020-01].[d2g_family_death]

Description:
The date and relationship to [snz_uid] of the death of an immediate family member.
Included relationships: children, parents, siblings (full or half), spouse 
(by marriage or civil-union), co-parent (partner with whom you had a child).

Intended purpose:
Identifying dates/periods where people are dealing with a death in their close family.
 
Notes:
1) There are many types of relationships that can not be identified using the IDI.
   This view is only those relationships we can observe with the available data.
2) Siblings are identified by people having at least one parent in common via DIA
   birth records. These may not go back far enough to identify siblings for older
   members of the population.
3) The marriage records contain a small number of records with the same partner snz_uid's
   (though other values of the record, such as date may differ). This includes couples who
   get married more than once on different dates. We have not filtered these out as they are
   a trivial proportion.
4) The relationship types are non-exclusive. So the same death can result in multiple
   records of different types (for example a single death can result in a person loosing
   both their spouse and co-partner if they were married and had children together).
5) The death of a child includes stillborn babies.
6) For simplicity we have NOT added a check that the person is alive when their family
   member dies. For example both spouses will have a record for each other's death,
   even if one dies several years before the other.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = d2g_
  Project schema = [DL-MAA2020-01]
 
Issues:
 
History (reverse order):
2020-07-21 MP QA
2020-03-04 SA v1
**************************************************************************************************/

USE [IDI_UserCode]
GO

/* Clear before creation */
IF OBJECT_ID('[DL-MAA2020-01].[d2g_family_death]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2g_family_death];
GO

CREATE VIEW [DL-MAA2020-01].[d2g_family_death] AS

/*********** Children ***********/

SELECT [snz_parent1_uid] AS [snz_uid]
	,DATEFROMPARTS([snz_deceased_year_nbr], [snz_deceased_month_nbr], 28) AS [event_date]
	,'child' AS [relationship]
	,[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[data].[personal_detail]
WHERE [snz_person_ind] = 1
AND [snz_deceased_year_nbr] IS NOT NULL
AND [snz_deceased_month_nbr] IS NOT NULL
AND [snz_parent1_uid] IS NOT NULL

UNION ALL

SELECT [snz_parent2_uid] AS [snz_uid]
	,DATEFROMPARTS([snz_deceased_year_nbr], [snz_deceased_month_nbr], 28) AS [event_date]
	,'child' AS [relationship]
	,[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[data].[personal_detail]
WHERE [snz_person_ind] = 1
AND [snz_deceased_year_nbr] IS NOT NULL
AND [snz_deceased_month_nbr] IS NOT NULL
AND [snz_parent2_uid] IS NOT NULL			-- parent 2 exists
AND [snz_parent1_uid] <> [snz_parent2_uid]	-- and is different from parent 1
AND [snz_parent2_uid] IS NOT NULL

UNION ALL

/*********** Parents ***********/

SELECT p.[snz_uid]
	,DATEFROMPARTS(d.[snz_deceased_year_nbr], d.[snz_deceased_month_nbr], 28) AS [event_date]
	,'parent' AS [relationship]
	,d.[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[data].[personal_detail] p		-- p for person who attends funeral
INNER JOIN [IDI_Clean_20200120].[data].[personal_detail] d	-- d for deceased person
ON d.[snz_uid] = p.[snz_parent1_uid]
WHERE d.[snz_person_ind] = 1
AND d.[snz_deceased_year_nbr] IS NOT NULL
AND d.[snz_deceased_month_nbr] IS NOT NULL

UNION ALL

SELECT p.[snz_uid]
	,DATEFROMPARTS(d.[snz_deceased_year_nbr], d.[snz_deceased_month_nbr], 28) AS [event_date]
	,'parent' AS [relationship]
	,d.[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[data].[personal_detail] p		-- p for person who attends funeral
INNER JOIN [IDI_Clean_20200120].[data].[personal_detail] d	-- d for deceased person
ON d.[snz_uid] = p.[snz_parent2_uid]
WHERE d.[snz_person_ind] = 1
AND d.[snz_deceased_year_nbr] IS NOT NULL
AND d.[snz_deceased_month_nbr] IS NOT NULL
AND p.[snz_parent2_uid] IS NOT NULL			-- parent 2 exists
AND p.[snz_parent1_uid] <> p.[snz_parent2_uid]	-- and is different from parent 1

UNION ALL

/*********** Siblings (half or full) ***********/

SELECT p.[snz_uid]
	,DATEFROMPARTS(d.[snz_deceased_year_nbr], d.[snz_deceased_month_nbr], 28) AS [event_date]
	,'sibling' AS [relationship]
	,d.[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[data].[personal_detail] p		-- p for person who attends funeral
INNER JOIN [IDI_Clean_20200120].[data].[personal_detail] d	-- d for deceased person
ON d.[snz_parent1_uid] = p.[snz_parent1_uid] -- both share same parent_1
AND d.[snz_uid] <> p.[snz_uid]
WHERE d.[snz_person_ind] = 1
AND d.[snz_deceased_year_nbr] IS NOT NULL
AND d.[snz_deceased_month_nbr] IS NOT NULL
AND p.[snz_parent1_uid] IS NOT NULL			-- parent 1 exists
AND d.[snz_parent1_uid] IS NOT NULL			-- parent 1 exists

UNION ALL

SELECT p.[snz_uid]
	,DATEFROMPARTS(d.[snz_deceased_year_nbr], d.[snz_deceased_month_nbr], 28) AS [event_date]
	,'sibling' AS [relationship]
	,d.[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[data].[personal_detail] p		-- p for person who attends funeral
INNER JOIN [IDI_Clean_20200120].[data].[personal_detail] d	-- d for deceased person
ON d.[snz_parent1_uid] = p.[snz_parent2_uid] -- parent_1 = parent_2
AND d.[snz_uid] <> p.[snz_uid]
WHERE d.[snz_person_ind] = 1
AND d.[snz_deceased_year_nbr] IS NOT NULL
AND d.[snz_deceased_month_nbr] IS NOT NULL
AND d.[snz_parent1_uid] IS NOT NULL			-- parent 1 exists
AND p.[snz_parent2_uid] IS NOT NULL			-- parent 2 exists
AND p.[snz_parent1_uid] <> p.[snz_parent2_uid]	-- and is different from parent 1

UNION ALL

SELECT p.[snz_uid]
	,DATEFROMPARTS(d.[snz_deceased_year_nbr], d.[snz_deceased_month_nbr], 28) AS [event_date]
	,'sibling' AS [relationship]
	,d.[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[data].[personal_detail] p		-- p for person who attends funeral
INNER JOIN [IDI_Clean_20200120].[data].[personal_detail] d	-- d for deceased person
ON d.[snz_parent2_uid] = p.[snz_parent1_uid] -- parent_2 = parent_1
AND d.[snz_uid] <> p.[snz_uid]
WHERE d.[snz_person_ind] = 1
AND d.[snz_deceased_year_nbr] IS NOT NULL
AND d.[snz_deceased_month_nbr] IS NOT NULL
AND p.[snz_parent1_uid] IS NOT NULL			-- parent 1 exists
AND d.[snz_parent2_uid] IS NOT NULL			-- parent 2 exists
AND d.[snz_parent1_uid] <> d.[snz_parent2_uid]	-- and is different from parent 1

UNION ALL

SELECT p.[snz_uid]
	,DATEFROMPARTS(d.[snz_deceased_year_nbr], d.[snz_deceased_month_nbr], 28) AS [event_date]
	,'sibling' AS [relationship]
	,d.[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[data].[personal_detail] p		-- p for person who attends funeral
INNER JOIN [IDI_Clean_20200120].[data].[personal_detail] d	-- d for deceased person
ON d.[snz_parent2_uid] = p.[snz_parent2_uid] -- both share same parent_2
AND d.[snz_uid] <> p.[snz_uid]
WHERE d.[snz_person_ind] = 1
AND d.[snz_deceased_year_nbr] IS NOT NULL
AND d.[snz_deceased_month_nbr] IS NOT NULL
AND p.[snz_parent2_uid] IS NOT NULL			-- parent 2 exists
AND p.[snz_parent1_uid] <> p.[snz_parent2_uid]	-- and is different from parent 1
AND d.[snz_parent2_uid] IS NOT NULL			-- parent 2 exists
AND d.[snz_parent1_uid] <> d.[snz_parent2_uid]	-- and is different from parent 1

UNION ALL

/*********** Spouse (by marriage or civil-union) ***********/

SELECT p.[partnr1_snz_uid] AS [snz_uid] -- first partner in marriage
	,DATEFROMPARTS(d.[snz_deceased_year_nbr], d.[snz_deceased_month_nbr], 28) AS [event_date]
	,'spouse' AS [relationship]
	,d.[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[dia_clean].[marriages] p			-- p for person who attends funeral
INNER JOIN [IDI_Clean_20200120].[data].[personal_detail] d	-- d for deceased person
ON p.[partnr2_snz_uid] = d.[snz_uid]
WHERE [dia_mar_marriage_date] IS NOT NULL
AND p.[partnr1_snz_uid] <> p.[partnr2_snz_uid]
AND d.[snz_person_ind] = 1
AND d.[snz_deceased_year_nbr] IS NOT NULL
AND d.[snz_deceased_month_nbr] IS NOT NULL
AND p.[partnr1_snz_uid] IS NOT NULL
AND p.[partnr2_snz_uid] IS NOT NULL

UNION ALL

SELECT p.[partnr2_snz_uid] AS [snz_uid] -- second partner in marriage
	,DATEFROMPARTS(d.[snz_deceased_year_nbr], d.[snz_deceased_month_nbr], 28) AS [event_date]
	,'spouse' AS [relationship]
	,d.[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[dia_clean].[marriages] p			-- p for person who attends funeral
INNER JOIN [IDI_Clean_20200120].[data].[personal_detail] d	-- d for deceased person
ON p.[partnr1_snz_uid] = d.[snz_uid]
WHERE [dia_mar_marriage_date] IS NOT NULL
AND p.[partnr1_snz_uid] <> p.[partnr2_snz_uid]
AND d.[snz_person_ind] = 1
AND d.[snz_deceased_year_nbr] IS NOT NULL
AND d.[snz_deceased_month_nbr] IS NOT NULL
AND p.[partnr1_snz_uid] IS NOT NULL
AND p.[partnr2_snz_uid] IS NOT NULL

UNION ALL

SELECT p.[partnr1_snz_uid] AS [snz_uid] -- first partner in civil union
	,DATEFROMPARTS(d.[snz_deceased_year_nbr], d.[snz_deceased_month_nbr], 28) AS [event_date]
	,'spouse' AS [relationship]
	,d.[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[dia_clean].[civil_unions] p		-- p for person who attends funeral
INNER JOIN [IDI_Clean_20200120].[data].[personal_detail] d	-- d for deceased person
ON p.[partnr2_snz_uid] = d.[snz_uid]
WHERE [dia_civ_civil_union_date] IS NOT NULL
AND p.[partnr1_snz_uid] <> p.[partnr2_snz_uid]
AND d.[snz_person_ind] = 1
AND d.[snz_deceased_year_nbr] IS NOT NULL
AND d.[snz_deceased_month_nbr] IS NOT NULL
AND p.[partnr1_snz_uid] IS NOT NULL
AND p.[partnr2_snz_uid] IS NOT NULL

UNION ALL

SELECT p.[partnr2_snz_uid] AS [snz_uid] -- second partner in civil union
	,DATEFROMPARTS(d.[snz_deceased_year_nbr], d.[snz_deceased_month_nbr], 28) AS [event_date]
	,'spouse' AS [relationship]
	,d.[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[dia_clean].[civil_unions] p		-- p for person who attends funeral
INNER JOIN [IDI_Clean_20200120].[data].[personal_detail] d	-- d for deceased person
ON p.[partnr1_snz_uid] = d.[snz_uid]
WHERE [dia_civ_civil_union_date] IS NOT NULL
AND p.[partnr1_snz_uid] <> p.[partnr2_snz_uid]
AND d.[snz_person_ind] = 1
AND d.[snz_deceased_year_nbr] IS NOT NULL
AND d.[snz_deceased_month_nbr] IS NOT NULL
AND p.[partnr1_snz_uid] IS NOT NULL
AND p.[partnr2_snz_uid] IS NOT NULL

UNION ALL

/*********** Co-parent (partner with whom you had a child) ***********/

SELECT DISTINCT p.[snz_parent2_uid] AS [snz_uid]		-- distinct is required to avoid duplicates where people have multiple children
	,DATEFROMPARTS(d.[snz_deceased_year_nbr], d.[snz_deceased_month_nbr], 28) AS [event_date]
	,'coparent' AS [relationship]
	,d.[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[data].[personal_detail] p		-- p for person who attends funeral
INNER JOIN [IDI_Clean_20200120].[data].[personal_detail] d	-- d for deceased person
ON d.[snz_uid] = p.[snz_parent1_uid]
WHERE d.[snz_person_ind] = 1
AND d.[snz_deceased_year_nbr] IS NOT NULL
AND d.[snz_deceased_month_nbr] IS NOT NULL
AND p.[snz_parent1_uid] IS NOT NULL			-- parent 1 exists
AND p.[snz_parent2_uid] IS NOT NULL			-- parent 2 exists
AND p.[snz_parent1_uid] <> p.[snz_parent2_uid]	-- and is different from parent 1

UNION ALL

SELECT DISTINCT p.[snz_parent1_uid] AS [snz_uid]		-- distinct is required to avoid duplicates where people have multiple children
	,DATEFROMPARTS(d.[snz_deceased_year_nbr], d.[snz_deceased_month_nbr], 28) AS [event_date]
	,'coparent' AS [relationship]
	,d.[snz_uid] AS [deceased_snz_uid]
FROM [IDI_Clean_20200120].[data].[personal_detail] p		-- p for person who attends funeral
INNER JOIN [IDI_Clean_20200120].[data].[personal_detail] d	-- d for deceased person
ON d.[snz_uid] = p.[snz_parent2_uid]
WHERE d.[snz_person_ind] = 1
AND d.[snz_deceased_year_nbr] IS NOT NULL
AND d.[snz_deceased_month_nbr] IS NOT NULL
AND p.[snz_parent1_uid] IS NOT NULL			-- parent 1 exists
AND p.[snz_parent2_uid] IS NOT NULL			-- parent 2 exists
AND p.[snz_parent1_uid] <> p.[snz_parent2_uid]	-- and is different from parent 1

GO
