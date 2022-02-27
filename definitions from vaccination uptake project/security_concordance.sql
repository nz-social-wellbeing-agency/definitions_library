/**************************************************************************************************
Title: Security concordance indicators
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[security].[concordance]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_security_concordance]

Description:
Security concordance indicators

Intended purpose:
Identifying which datasets an identity is linked to.

Notes:

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:

History (reverse order):
2021-10-31 CW
**************************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_security_concordance]
GO

CREATE VIEW [DL-MAA2021-49].[vacc_security_concordance] AS 
SELECT [link_set_key]
	,[snz_uid]
	,[snz_spine_uid]
	,IIF([snz_spine_uid] IS NOT NULL, 1, 0) AS [spine]
	,IIF([snz_ird_uid] IS NOT NULL, 1, 0) AS [ird]
	,IIF([snz_moe_uid] IS NOT NULL, 1, 0) AS [moe]
	,IIF([snz_dol_uid] IS NOT NULL, 1, 0) AS [dol]
	,IIF([snz_hlfs_uid] IS NOT NULL, 1, 0) AS [hlfs]
	,IIF([snz_msd_uid] IS NOT NULL, 1, 0) AS [msd]
	,IIF([snz_sofie_uid] IS NOT NULL, 1, 0) AS [sofie]
	,IIF([snz_jus_uid] IS NOT NULL, 1, 0) AS [jus]
	,IIF([snz_acc_uid] IS NOT NULL, 1, 0) AS [acc]
	,IIF([snz_moh_uid] IS NOT NULL, 1, 0) AS [moh]
	,IIF([snz_dia_uid] IS NOT NULL, 1, 0) AS [dia]
	,IIF([snz_cen_uid] IS NOT NULL, 1, 0) AS [cen]
	,IIF([snz_hes_uid] IS NOT NULL, 1, 0) AS [hes]
	,IIF([snz_acm_uid] IS NOT NULL, 1, 0) AS [acm]
	,IIF([snz_nzta_uid] IS NOT NULL, 1, 0) AS [nzta]
	,IIF([snz_gss_uid] IS NOT NULL, 1, 0) AS [gss]
	,IIF([snz_otfs_uid] IS NOT NULL, 1, 0) AS [otfs]
	,IIF([snz_piaac_uid] IS NOT NULL, 1, 0) AS [piaac]
	,IIF([snz_esp_uid] IS NOT NULL, 1, 0) AS [esp]
	,IIF([snz_nzcvs_uid] IS NOT NULL, 1, 0) AS [nzcvs]
	-- count linked UIDs
	,IIF([snz_ird_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_moe_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_dol_uid] IS NOT NULL, 1, 0)      
	+ IIF([snz_hlfs_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_msd_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_sofie_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_jus_uid] IS NOT NULL, 1, 0)      
	+ IIF([snz_acc_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_moh_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_dia_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_cen_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_hes_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_acm_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_nzta_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_gss_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_otfs_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_piaac_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_esp_uid] IS NOT NULL, 1, 0)       
	+ IIF([snz_nzcvs_uid] IS NOT NULL, 1, 0) AS [uids]
FROM [IDI_Clean_20211020].[security].[concordance]
GO
