/**************************************************************************************************
Title: Spell waitlisted for social housing
Author: Simon Anastasiadis

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
A spell when a person is waitlisted for social housing provided by central government.

Intended purpose:
Creating indicators of when/whether a person is waiting for social housing.
Identifying spells when a person is waiting for social housing.

Inputs & Dependencies:
- [IDI_Clean].[hnz_clean].[new_applications_household]
- [IDI_Clean].[hnz_clean].[new_applications]
- [IDI_Clean].[hnz_clean].[register_exit]
Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[defn_hnz_waitlist]

Notes:
1) HNZ tenancy data includes three different identifiers for linking separate tables.
   These IDs have some complications:
   - Some records with only one ID (e.g. a legacy ID) link to records with two IDs
     (e.g. a legacy ID and an MSD ID).
   - The same number can appear in different ID columns. Hence legacy IDs can be
     incorrectly linked to MSD IDs.
   We use a simplified approach: link using each of the three IDs and keep the records
   that link. This means the resulting data does include duplicates where a record can
   link on more than one ID.
2) We have only included new applications for people not in social housing. This means we
   have excluded transfer applications: Social housing tenants requesting a movement to
   another address (e.g. because an additional bedroom is required).
3) The [hnz_na_hshd_size_nbr] column of [new_applications] may contain the number of
   people on the application. However the number that we can find on the household record
   [new_applications_household] is approximately three-quarters of this amount. Though
   the gap is smaller in recent years.
   The cause of this difference is unknown.
4) An alternative way to approach this calculation would be to use the registry snapshots
   in a similar way to how we used the tenancy snapshots. A comparison of these two ways
   remains to be done.
5) Requires spell condensing in order to count the number of days a person spends waiting
   for social housing. Spell condensing should also deduplicate.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]
 
Issues:
 
History (reverse order):
2020-05-19 SA v1
**************************************************************************************************/

/* Staging */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[defn_hnz_waitlist];
GO

WITH
via_application_uid AS (
	SELECT h.[snz_uid]
		  ,h.[hnz_nah_app_relship_text]
		  ,h.[hnz_nah_signatory_flg_ind]
		  ,a.[hnz_na_date_of_application_date]
		  ,a.[hnz_na_hshd_size_nbr]
		  ,e.[hnz_re_exit_date]
		  ,e.[hnz_re_exit_status_text]
		  ,e.[hnz_re_exit_reason_text]
		  ,h.[snz_application_uid] AS ID
	FROM [IDI_Clean_YYYYMM].[hnz_clean].[new_applications_household] h
	INNER JOIN [IDI_Clean_YYYYMM].[hnz_clean].[new_applications] a
	ON h.[snz_application_uid] = a.[snz_application_uid]
	LEFT JOIN [IDI_Clean_YYYYMM].[hnz_clean].[register_exit] e
	ON h.[snz_application_uid] = e.[snz_application_uid]
	WHERE h.[snz_application_uid] IS NOT NULL
),
via_legacy_application_uid AS (
	SELECT h.[snz_uid]
		  ,h.[hnz_nah_app_relship_text]
		  ,h.[hnz_nah_signatory_flg_ind]
		  ,a.[hnz_na_date_of_application_date]
		  ,a.[hnz_na_hshd_size_nbr]
		  ,e.[hnz_re_exit_date]
		  ,e.[hnz_re_exit_status_text]
		  ,e.[hnz_re_exit_reason_text]
		  ,h.[snz_legacy_application_uid] AS ID
	FROM [IDI_Clean_YYYYMM].[hnz_clean].[new_applications_household] h
	INNER JOIN [IDI_Clean_YYYYMM].[hnz_clean].[new_applications] a
	ON h.[snz_legacy_application_uid] = a.[snz_legacy_application_uid]
	LEFT JOIN [IDI_Clean_YYYYMM].[hnz_clean].[register_exit] e
	ON h.[snz_legacy_application_uid] = e.[snz_legacy_application_uid]
	WHERE h.[snz_legacy_application_uid] IS NOT NULL
),
via_msd_application_uid AS (
	SELECT h.[snz_uid]
		  ,h.[hnz_nah_app_relship_text]
		  ,h.[hnz_nah_signatory_flg_ind]
		  ,a.[hnz_na_date_of_application_date]
		  ,a.[hnz_na_hshd_size_nbr]
		  ,e.[hnz_re_exit_date]
		  ,e.[hnz_re_exit_status_text]
		  ,e.[hnz_re_exit_reason_text]
		  ,h.[snz_msd_application_uid] AS ID
	FROM [IDI_Clean_YYYYMM].[hnz_clean].[new_applications_household] h
	INNER JOIN [IDI_Clean_YYYYMM].[hnz_clean].[new_applications] a
	ON h.[snz_msd_application_uid] = a.[snz_msd_application_uid]
	LEFT JOIN [IDI_Clean_YYYYMM].[hnz_clean].[register_exit] e
	ON h.[snz_msd_application_uid] = e.[snz_msd_application_uid]
	WHERE h.[snz_msd_application_uid] IS NOT NULL
)
SELECT [snz_uid]
	  ,[hnz_nah_app_relship_text]
	  ,[hnz_nah_signatory_flg_ind]
	  ,[hnz_na_date_of_application_date]
	  ,[hnz_na_hshd_size_nbr]
	  ,COALESCE([hnz_re_exit_date], DATEADD(YEAR, 3, [hnz_na_date_of_application_date])) AS [hnz_re_exit_date]
	  ,[hnz_re_exit_status_text]
	  ,[hnz_re_exit_reason_text]
	  ,ID
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_hnz_waitlist]
FROM (
	SELECT *
	FROM via_application_uid
	UNION ALL
	SELECT *
	FROM via_legacy_application_uid
	UNION ALL
	SELECT *
	FROM via_msd_application_uid
) k
WHERE [hnz_na_date_of_application_date] <= [hnz_re_exit_date]
OR [hnz_re_exit_date] IS NULL
GO

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[defn_hnz_waitlist] (snz_uid);
GO

/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[defn_hnz_waitlist] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

