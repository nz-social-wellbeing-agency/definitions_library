/**************************************************************************************************
Title: Stroke register
Author: MOH
Re-edit: Manjusha Radhakrishnan
Reviewer: 

Inputs & Dependencies:
- [moh_clean].[priv_fund_hosp_discharges_diag]   NB: MAA2018-48 does not have access to this as at 10/06/2022.
- [moh_clean].[pub_fund_hosp_discharges_event]

Outputs:
- [IDI_Sandpit].[DL-MAA2018-48].[defn_stroke]

Intended purpose:
Create register of people who have had a stroke in the past years

Notes:
1. Cancer codes used:
	- I60, I61, I62, I63, I65, I66, I67, I69, G45, G46

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]

Issues:
1. Duplicates can be found; this is because a person may receive multiple treatments for the same condition

History (reverse order):
2022-07-20 MR v1
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[defn_stroke]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_stroke] (
	snz_uid	INT
	, event_date DATE
	, source VARCHAR(255)
);
GO


/** PUBLIC HOSPITALS **/
INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_stroke] (snz_uid, event_date, source)
SELECT snz_uid,
        nmd.moh_evt_even_date AS event_date,
		'PUB HOSP' AS source
FROM [IDI_Clean_202203].[moh_clean].[pub_fund_hosp_discharges_event] as nmd
INNER JOIN (
		SELECT moh_dia_event_id_nbr,
               moh_dia_diagnosis_type_code,
               moh_dia_clinical_code,
               moh_dia_clinical_sys_code
        FROM [IDI_Clean_202203].[moh_clean].[pub_fund_hosp_discharges_diag]
        WHERE moh_dia_clinical_sys_code IN ('11','12','13','14','15')
        AND (substring(moh_dia_clinical_code,1,3) IN ('I60','I61','I62','I63','I65','I66','I67','I69','G45','G46'))) as fndp
ON nmd.moh_evt_event_id_nbr = fndp.moh_dia_event_id_nbr
GO

/** PRIVATE HOSPITALS **/
INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_stroke] (snz_uid, event_date, source)
SELECT snz_uid,
       moh_pri_evt_end_date  AS event_date,
	   'PRIV HOSP' AS source
FROM [IDI_Clean_202203].[moh_clean].[priv_fund_hosp_discharges_event] as nmd
INNER JOIN (
		SELECT moh_pri_diag_event_id_nbr,
			   moh_pri_diag_diag_type_code,
               moh_pri_diag_clinic_code,
               moh_pri_diag_clinic_sys_code
               FROM [IDI_Clean_202203].[moh_clean].[priv_fund_hosp_discharges_diag]
               WHERE moh_pri_diag_clinic_sys_code IN ('11','12','13','14','15')
               AND (substring(moh_pri_diag_clinic_code,1,3) IN ('I60','I61','I62','I63','I65','I66','I67','I69','G45','G46'))
) as fndp
ON nmd.moh_pri_evt_event_id_nbr = fndp.moh_pri_diag_event_id_nbr
GO

