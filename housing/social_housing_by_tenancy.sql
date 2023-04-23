/**************************************************************************************************
Title: Social housing
Author: Simon Anastasiadis
Reviewer: Akilesh Chokkanathapuram

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
Government provided social housing - application and residence.

Intended purpose:
Identify social housing applications
Identify social housing tenancy

Inputs & Dependencies:
- [IDI_Clean].[hnz_clean].[new_applications]
- [IDI_Clean].[hnz_clean].[new_applications_household]
- [IDI_Clean].[hnz_clean].[tenancy_household_snapshot]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[vacc_hnz_apply]
- [IDI_UserCode].[DL-MAA20XX-YY].[vacc_hnz_tenancy]
- [IDI_UserCode].[DL-MAA20XX-YY].[vacc_current_hnz_tenancy]

Notes:
1) The social housing application tables can join on any of three different IDs.
	- The oldest is snz_legacy_application_uid
	- Next is snz_application_uid
	- The latest is snz_msd_application_uid
	These different IDs were phased in progressively, so there is an overlap in time
	periods using each type of IDs, and some records have two different IDs.

2) Similar patterns are observed for the household identities.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = vacc_
  Project schema = DL-MAA20XX-YY
 
Issues:
1) Performance may be poor using all three of these as Views. Converting to indexed Tables
	may improve performance.
2) Captures application dates and move in dates well. As occupants may change uring a tenancy
	may not provide accurate measure of who lives in household (esp. during long or volatile
	tenancies).

History (reverse order):
2021-08-31 MP Parameterise for COVID-19 vaccination modelling
2020-08-18 MP Parameterise for Nga Tapuae
2019-04-23 AK Reviewed
2019-04-01 SA Initiated
**************************************************************************************************/

/*embedded in user code*/
USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA20XX-YY].[vacc_hnz_apply];
GO

CREATE VIEW [DL-MAA20XX-YY].[vacc_hnz_apply] AS
SELECT snz_uid
	,[hnz_na_date_of_application_date]
	,'apply social housing' AS [description]
FROM (
	-- join by MSD application ID (latest)
	SELECT b.snz_uid
		,a.[hnz_na_date_of_application_date]
	FROM  [IDI_Clean_YYYYMM].[hnz_clean].[new_applications] a
	INNER JOIN  [IDI_Clean_YYYYMM].[hnz_clean].[new_applications_household] b
	ON a.[snz_msd_application_uid] = b.[snz_msd_application_uid]

	UNION ALL

	-- join by application ID (a little old)
	SELECT b.snz_uid
		,a.[hnz_na_date_of_application_date]
	FROM  [IDI_Clean_YYYYMM].[hnz_clean].[new_applications] a
	INNER JOIN  [IDI_Clean_YYYYMM].[hnz_clean].[new_applications_household] b
	ON a.[snz_application_uid] = b.[snz_application_uid]
	WHERE a.[snz_msd_application_uid] IS NULL OR b.[snz_msd_application_uid] IS NULL -- MSD application ID unavailable

	UNION ALL

	-- join by legacy application ID (quite old)
	SELECT b.snz_uid
		,a.[hnz_na_date_of_application_date]
	FROM  [IDI_Clean_YYYYMM].[hnz_clean].[new_applications] a
	INNER JOIN  [IDI_Clean_YYYYMM].[hnz_clean].[new_applications_household] b
	ON a.[snz_legacy_application_uid] = b.[snz_legacy_application_uid]
	WHERE (a.[snz_msd_application_uid] IS NULL OR b.[snz_msd_application_uid] IS NULL) -- MSD application ID unavailable
	AND (a.[snz_application_uid] IS NULL OR b.[snz_application_uid] IS NULL) -- application ID unavailable

) k
GO

/* Social housing tenancy */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[vacc_hnz_tenancy];
GO

CREATE VIEW [DL-MAA20XX-YY].[vacc_hnz_tenancy] AS
SELECT a.[snz_uid]
      ,a.[hnz_ths_snapshot_date] AS [start_date]
	  ,b.[hnz_ths_snapshot_date] AS [end_date]
	  ,'HNZ tenant' AS [description]
FROM  [IDI_Clean_YYYYMM].[hnz_clean].[tenancy_household_snapshot] a
INNER JOIN  [IDI_Clean_YYYYMM].[hnz_clean].[tenancy_household_snapshot] b
ON a.snz_uid = b.snz_uid
WHERE DATEDIFF(DAY, a.[hnz_ths_snapshot_date], b.[hnz_ths_snapshot_date]) >= 20 -- snapshots are 20-40 days apart
AND DATEDIFF(DAY, a.[hnz_ths_snapshot_date], b.[hnz_ths_snapshot_date]) <= 40
AND (a.[snz_household_uid] = b.[snz_household_uid] -- same household
OR a.[snz_legacy_household_uid] = b.[snz_legacy_household_uid])
GO

/* Current social housing tenancy */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[vacc_current_hnz_tenancy]
GO

CREATE VIEW [DL-MAA20XX-YY].[vacc_current_hnz_tenancy] AS
SELECT DISTINCT [snz_uid]
	  ,'Current_HNZ_tenant_June21' AS [description]
FROM  [IDI_Clean_YYYYMM].[hnz_clean].[tenancy_household_snapshot] 
WHERE  MONTH([hnz_ths_snapshot_date]) = 6 
AND YEAR ([hnz_ths_snapshot_date]) = 2021
GO
