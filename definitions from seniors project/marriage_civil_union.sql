/**************************************************************************************************
Title: Official relationship - marriage or civil union
Author: Simon Anastasiadis
Reviewer: Freya Li

Inputs & Dependencies:
- [IDI_Clean_202203].[dia_clean].[marriages]
- [IDI_Clean_202203].[dia_clean].[civil_unions]
- [IDI_Clean_202203].[data].[personal_detail]
Outputs:
- [IDI_UserCode].[DL-MAA2018-48].[defn_official_relationship]

Description:
Period that a person is married or in a civil union for.

Intended purpose:
Determining whether a person is married or solemenised (civily unioned).
Identifying dates of marriage, divorce, union, or disolution.
 
Notes:
1) Each partner is recorded separately.
2) Max start date is 2021-12-30

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]
 
Issues:
- Contains a small number of records where [start_date] > [end_date]
- Contains a small number of duplicate records
 
History (reverse order):
2022-31-05 VW Point to DL-MAA2018-48 (seniors project) and 202203 refresh
2020-11-19 FL QA
2020-03-03 SA v1
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

/* Clear view */
IF OBJECT_ID('[DL-MAA2018-48].[defn_official_relationship]','V') IS NOT NULL
DROP VIEW [DL-MAA2018-48].[defn_official_relationship];
GO

CREATE VIEW [DL-MAA2018-48].[defn_official_relationship] AS
WITH
marriage AS (
	SELECT [partnr1_snz_uid]
	      ,[dia_mar_partnr1_sex_snz_code]
		  ,[partnr2_snz_uid]
	      ,[dia_mar_partnr2_sex_snz_code]
	      ,[dia_mar_marriage_date]
		  ,[dia_mar_disolv_order_date]
		  ,DATEFROMPARTS(b.[snz_deceased_year_nbr], b.[snz_deceased_month_nbr], 28) AS [partnr1_deceased_date]
		  ,DATEFROMPARTS(c.[snz_deceased_year_nbr], c.[snz_deceased_month_nbr], 28) AS [partnr2_deceased_date]
	FROM [IDI_Clean_202203].[dia_clean].[marriages] a
	INNER JOIN [IDI_Clean_202203].[data].[personal_detail] b
	ON a.[partnr1_snz_uid] = b.snz_uid
	INNER JOIN [IDI_Clean_202203].[data].[personal_detail] c
	ON a.[partnr2_snz_uid] = c.snz_uid
	WHERE [dia_mar_marriage_date] IS NOT NULL
	AND [partnr1_snz_uid] <> [partnr2_snz_uid]
),
civil_union AS (
	SELECT [partnr1_snz_uid]
		  ,[dia_civ_partnr1_sex_snz_code]
		  ,[partnr2_snz_uid]
		  ,[dia_civ_partnr2_sex_snz_code]
		  ,[dia_civ_civil_union_date]
		  ,[dia_civ_dissolution_type_text]
		  ,[dia_civ_disolv_order_date]
		  ,DATEFROMPARTS(b.[snz_deceased_year_nbr], b.[snz_deceased_month_nbr], 28) AS [partnr1_deceased_date]
		  ,DATEFROMPARTS(c.[snz_deceased_year_nbr], c.[snz_deceased_month_nbr], 28) AS [partnr2_deceased_date]
	FROM [IDI_Clean_202203].[dia_clean].[civil_unions] a
	INNER JOIN [IDI_Clean_202203].[data].[personal_detail] b
	ON a.[partnr1_snz_uid] = b.snz_uid
	INNER JOIN [IDI_Clean_202203].[data].[personal_detail] c
	ON a.[partnr2_snz_uid] = c.snz_uid
	WHERE [dia_civ_civil_union_date] IS NOT NULL
	AND [partnr1_snz_uid] <> [partnr2_snz_uid]

)
/* Partner 1, marriage */
SELECT [partnr1_snz_uid] as snz_uid
	,[dia_mar_marriage_date] AS [start_date]
	,COALESCE([dia_mar_disolv_order_date],
		IIF([partnr1_deceased_date] < [partnr2_deceased_date], [partnr1_deceased_date], [partnr2_deceased_date]),
		[partnr1_deceased_date],
		[partnr2_deceased_date],
		'9999-12-31') AS [end_date]
FROM marriage

UNION ALL

/* Partner 2, marriage */
SELECT [partnr2_snz_uid] as snz_uid
	,[dia_mar_marriage_date] AS [start_date]
	,COALESCE([dia_mar_disolv_order_date],
		IIF([partnr1_deceased_date] < [partnr2_deceased_date], [partnr1_deceased_date], [partnr2_deceased_date]),
		[partnr1_deceased_date],
		[partnr2_deceased_date],
		'9999-12-31') AS [end_date]
FROM marriage

UNION ALL

/* Partner 1, civil union */
SELECT [partnr1_snz_uid] AS [snz_uid]
	  ,[dia_civ_civil_union_date] AS [start_date]
	  ,COALESCE([dia_civ_disolv_order_date],
		IIF([partnr1_deceased_date] < [partnr2_deceased_date], [partnr1_deceased_date], [partnr2_deceased_date]),
		[partnr1_deceased_date],
		[partnr2_deceased_date],
		'9999-12-31') AS [end_date]
FROM civil_union

UNION ALL

/* Partner 2, civil union */
SELECT [partnr2_snz_uid] AS [snz_uid]
	  ,[dia_civ_civil_union_date] AS [start_date]
	  ,COALESCE([dia_civ_disolv_order_date],
		IIF([partnr1_deceased_date] < [partnr2_deceased_date], [partnr1_deceased_date], [partnr2_deceased_date]),
		[partnr1_deceased_date],
		[partnr2_deceased_date],
		'9999-12-31') AS [end_date]
FROM civil_union;
GO
