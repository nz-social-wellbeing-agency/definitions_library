/**************************************************************************************************
Title: Ischaemic heart disease register
Author: MOH
Re-edit: Manjusha Radhakrishnan
Reviewer: 

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
People in the IHD register.

Intended purpose:
Create register of people who have been hospitalised for IHD in the past years.

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[priv_fund_hosp_discharges_diag]   
- [IDI_Clean].[[moh_clean].[pub_fund_hosp_discharges_event]

Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[defn_ihd]

Notes:
- Ischaemic heart disease codes used:
	I20-I26, Z82.4

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]

Issues:
1. Duplicates can be found; this is because a person may receive multiple treatments for the same condition

History (reverse order):
2022-07-20 MR v1
**************************************************************************************************/
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[defn_ihd]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[defn_ihd] (
	snz_uid	INT
	, event_date DATE
	, source VARCHAR(255)
);
GO


/** PUBLIC HOSPITALS **/
INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_ihd] (snz_uid, event_date, source)
SELECT snz_uid,
        nmd.moh_evt_even_date AS event_date,
		'PUB HOSP' AS source
FROM [IDI_Clean_YYYYMM].[moh_clean].[pub_fund_hosp_discharges_event] as nmd
INNER JOIN (
		SELECT moh_dia_event_id_nbr,
               moh_dia_diagnosis_type_code,
               moh_dia_clinical_code,
               moh_dia_clinical_sys_code
        FROM [IDI_Clean_YYYYMM].[moh_clean].[pub_fund_hosp_discharges_diag]
        WHERE moh_dia_clinical_sys_code IN ('11','12','13','14','15')
        AND (substring(moh_dia_clinical_code,1,3) IN ('I20','I210','I211','I212','I213','I214','I219','I22','I23','I24','I25','Z824'))) as fndp
ON nmd.moh_evt_event_id_nbr = fndp.moh_dia_event_id_nbr
GO

/** PRIVATE HOSPITALS **/
INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_ihd] (snz_uid, event_date, source)
SELECT snz_uid,
       moh_pri_evt_end_date  AS event_date,
	   'PRIV HOSP' AS source
FROM [IDI_Clean_YYYYMM].[moh_clean].[priv_fund_hosp_discharges_event] as nmd
INNER JOIN (
		SELECT moh_pri_diag_event_id_nbr,
			   moh_pri_diag_diag_type_code,
               moh_pri_diag_clinic_code,
               moh_pri_diag_clinic_sys_code
               FROM [IDI_Clean_YYYYMM].[moh_clean].[priv_fund_hosp_discharges_diag]
               WHERE moh_pri_diag_clinic_sys_code IN ('11','12','13','14','15')
               AND (substring(moh_pri_diag_clinic_code,1,3) IN ('I20','I210','I211','I212','I213','I214','I219','I22','I23','I24','I25','Z824'))
) as fndp
ON nmd.moh_pri_evt_event_id_nbr = fndp.moh_pri_diag_event_id_nbr
GO

