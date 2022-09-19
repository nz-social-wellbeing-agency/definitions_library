/**************************************************************************************************
Title: Falls (injury) register
Author: MOH
Re-edit: Manjusha Radhakrishnan
Reviewer: 

Inputs & Dependencies:
- [moh_clean].[priv_fund_hosp_discharges_diag]   NB: MAA2018-48 does not have access to this as at 10/06/2022.
- [moh_clean].[pub_fund_hosp_discharges_event]

Outputs:
- [IDI_Sandpit].[DL-MAA2018-48].[defn_falls_injury]

Intended purpose:
Create register of people who have been hospitalised for a fall in the past years

Notes:
- Falls/Injury codes used:
	'W00','W01','W02','W03','W04','W05','W06','W07','W08','W09','W10','W11','W12','W13','W14','W15','W16','W17','W18','W19'

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]

Issues:
1. Duplicates can be found; this is because a person may receive multiple treatments for the same condition

History (reverse order):
2022-07-20 MR v1
**************************************************************************************************/
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[defn_falls_injury]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_falls_injury] (
	snz_uid	INT
	, event_date DATE
	, source VARCHAR(255)
);
GO


/** PUBLIC HOSPITALS **/
INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_falls_injury] (snz_uid, event_date, source)
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
        AND (substring(moh_dia_clinical_code,1,3) IN ('W00','W01','W02','W03','W04','W05','W06','W07','W08','W09','W10','W11',
                            'W12','W13','W14','W15','W16','W17','W18','W19'))) as fndp
ON nmd.moh_evt_event_id_nbr = fndp.moh_dia_event_id_nbr
GO

/** PRIVATE HOSPITALS **/
INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_falls_injury] (snz_uid, event_date, source)
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
               AND (substring(moh_pri_diag_clinic_code,1,3) IN ('W00','W01','W02','W03','W04','W05','W06','W07','W08','W09','W10','W11',
                            'W12','W13','W14','W15','W16','W17','W18','W19'))
) as fndp
ON nmd.moh_pri_evt_event_id_nbr = fndp.moh_pri_diag_event_id_nbr
GO
