/**************************************************************************************************
Title: Health cards
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[pharmaceutical]
- [IDI_Clean].[moh_clean].[gms_claims]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[defn_health_cs_card]
- [IDI_UserCode].[DL-MAA2016-15].[defn_health_huh_card]

Description:
Community Services Card and High Use Health Card use
for perscriptions or claimed via general medical subsidies.

Intended purpose:
Determining who has a community services card and/or a high use health card.
 
Notes:
1) While the GMS table codes both health cards as Y(es) or N(o),
   the pharmaceutical table uses a different coding of health cards:
   HUHC in (NULL, U, Z)
   CSC in (NULL, 1, 3, 4)
   Based on the proportion of the population in each category, we has assumed
   HUHC = Z and CSC = 1 or 3 are equivalent to Yes, and the others are equivalent to No.
2) As this tables observes use of health cards, we require some assumptions as to
   when people have health cards. We shall assume if you used a health card then you
   have an active card for the month previous and two months after.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = defn_
  Project schema = [DL-MAA2016-15]

Issues:
 
History (reverse order):
2020-05-20 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA2016-15].[defn_health_cs_card]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_health_cs_card];
GO

/* Create view */
CREATE VIEW [DL-MAA2016-15].[defn_health_cs_card] AS
SELECT [snz_uid]
	  ,[moh_pha_dispensed_date] AS [event_date]
	  ,DATEADD(MONTH, -1, [moh_pha_dispensed_date]) AS [start_date]
	  ,DATEADD(MONTH,  2, [moh_pha_dispensed_date]) AS [end_date]
	  ,[moh_pha_csc_holder_code] AS [csc]
      ,[moh_pha_huhc_holder_code] AS [huhc]
FROM [IDI_Clean_20200120].[moh_clean].[pharmaceutical]
WHERE [moh_pha_csc_holder_code] IN ('1', '3')

UNION ALL

SELECT [snz_uid]
      ,[moh_gms_visit_date] AS [event_date]
      ,DATEADD(MONTH, -1, [moh_gms_visit_date]) AS [start_date]
	  ,DATEADD(MONTH,  2, [moh_gms_visit_date]) AS [end_date]
	  ,[moh_gms_csc_code] AS [csc]
      ,[moh_gms_huhc_code] AS [huhc]
FROM [IDI_Clean_20200120].[moh_clean].[gms_claims]
WHERE [moh_gms_csc_code] = 'Y'

GO

/* Clear existing view */
IF OBJECT_ID('[DL-MAA2016-15].[defn_health_huh_card]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[defn_health_huh_card];
GO

/* Create view */
CREATE VIEW [DL-MAA2016-15].[defn_health_huh_card] AS
SELECT [snz_uid]
	  ,[moh_pha_dispensed_date] AS [event_date]
	  ,DATEADD(MONTH, -1, [moh_pha_dispensed_date]) AS [start_date]
	  ,DATEADD(MONTH,  2, [moh_pha_dispensed_date]) AS [end_date]
	  ,[moh_pha_csc_holder_code] AS [csc]
      ,[moh_pha_huhc_holder_code] AS [huhc]
FROM [IDI_Clean_20200120].[moh_clean].[pharmaceutical]
WHERE [moh_pha_huhc_holder_code] IN ('Z')

UNION ALL

SELECT [snz_uid]
      ,[moh_gms_visit_date] AS [event_date]
      ,DATEADD(MONTH, -1, [moh_gms_visit_date]) AS [start_date]
	  ,DATEADD(MONTH,  2, [moh_gms_visit_date]) AS [end_date]
	  ,[moh_gms_csc_code] AS [csc]
      ,[moh_gms_huhc_code] AS [huhc]
FROM [IDI_Clean_20200120].[moh_clean].[gms_claims]
WHERE [moh_gms_huhc_code] = 'Y'
GO