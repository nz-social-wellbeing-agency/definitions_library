/**************************************************************************************************
Title: Dementia, Alzheimer's and Parkinson's register
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
People in the DAP register.

Intended purpose:
Create register of people who have been hospitalised for or received medicine for Dementia, Alzheimer's and Parkinson's in the past years

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[priv_fund_hosp_discharges_diag]   
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].[pharmaceutical]
- [IDI_Clean].[moh_clean].[interrai]
Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[defn_dap]


Notes:
- Dementia, Alzheimer's and Parkinson's codes used:
	ICD 10 codes: F00-F02.0, F02.8-F03.91, F06.2, G30-G31.1, G31.8-G32.89
	Pharms codes: 3923, 4037

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]

Issues:
1. Duplicates can be found; this is because a person may receive multiple treatments for the same condition

History (reverse order):
2022-07-20 MR v1

**************************************************************************************************/
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[defn_dap]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[defn_dap] (
	snz_uid	INT
	, event_date DATE
	, source VARCHAR(255)
);
GO


/** PUBLIC HOSPITALS **/
INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_dap] (snz_uid, event_date, source)
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
        AND (substring(moh_dia_clinical_code,1,3) IN ('F01','F02','F03','F06.2','G30','G310','G311','G318','G32'))) as fndp
ON nmd.moh_evt_event_id_nbr = fndp.moh_dia_event_id_nbr
GO

/** PRIVATE HOSPITALS **/
INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_dap] (snz_uid, event_date, source)
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
               AND (substring(moh_pri_diag_clinic_code,1,3) IN ('F01','F02','F03','F06.2','G30','G310','G311','G318','G32'))
) as fndp
ON nmd.moh_pri_evt_event_id_nbr = fndp.moh_pri_diag_event_id_nbr
GO

/** PHARMACEUTICAL **/
INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_dap] (snz_uid, event_date, source)
SELECT  snz_uid,
		moh_pha_dispensed_date AS event_date,
		'PHARM' AS source
FROM [IDI_Clean_YYYYMM].[moh_clean].[pharmaceutical] as pharm
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code] as form
ON pharm.moh_pha_dim_form_pack_code = form.dim_form_pack_subsidy_key
WHERE pharm.moh_pha_order_type_code IN (1,7)
		AND pharm.moh_pha_patent_category_code != 'W'
		AND pharm.moh_pha_admin_record_ind = '0'
		AND chemical_id IN ('3923', '4037')
GO

/** INTERAI **/
INSERT INTO [IDI_Sandpit].[DL-MAA20XX-YY].[defn_dap] (snz_uid, event_date, source)
SELECT snz_uid,
	moh_irai_assessment_date AS event_date,
   'INTERAI' AS source
FROM [IDI_Clean_YYYYMM].[moh_clean].[interrai]
WHERE moh_irai_alzheimers_code = 1 OR moh_irai_dementia_code = 1 OR moh_irai_parkinsons_code = 1
GO
