/**************************************************************************************************
Title: Chronic condition: Diabetes
Author: Simon Anastasiadis
Modified: Penny Mok

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_diag]
- [IDI_Clean].[moh_clean].[priv_fund_hosp_discharges_diag]
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].[priv_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].[nnpac]
- [IDI_Clean].[moh_clean].[pharmaceutical]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code]
Outputs:
- [IDI_Sandpit].[DL-MAA2018-48].[defn_chronic_coronary_heart_disease]

Description:
Diagnosis at a hospital with Diabetes or dispensing of diabetes drugs.

Intended purpose:
Determine who has been diagnosed with the chronic condition diabetes.
And when they were diagnosed.
 
Notes:
1) In the September 2018 refresh notes:
   "The data contained in the [moh.clean].[chronic_condition] table has changed due to some data
    sources being too outdated to provide value for researchers. COPD and CHD are no longer included
	in this table, and alternatives should be used to identify these conditions. The remaining
	conditions have been updated. Diabetes now uses data from the updated Virtual Diabetes 
	Register (VDR) methodology (v686) and contains data from the VDR 2017."
   IDI wiki Source:
   wprdtfs05/sites/DefaultProjectCollection/IDI/IDIwiki/UserWiki/Documents/September%202018%20IDI%20Refresh%20Updates.pdf
   However, we do not have access to the VDR within the IDI.
2) We have constructed this definition from the description given in the MoH IDI Data dictionary.
   This includes a list of diagnosis and proceedure codes, as well as a list of pharmaceuticals.
3) Testing against Chronic condition table in the 2018-07-20 refresh suggests high consistency.
4) To reduce the amount of data written/copied during the construction of these tables, we have
   commented out non-critical fields (lines starting with "--"). Uncommenting these lines is
   recommended is validating the construction/definition.
5) The [end_date] in this table is the end of the hospital visit when diagnosis took place,
   NOT the date that the chronic condition ended.

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]
 
Issues:
 
History (reverse order):
2020-05-26 SA v1
**************************************************************************************************/

/* Clear before creation */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_pfhd_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_pfhd_chronic_diags];
GO

/************************************ publically funded hospital discharages ************************************/
SELECT [moh_dia_event_id_nbr] AS [event_id]
      --,[moh_dia_clinical_sys_code]
      --,[moh_dia_submitted_system_code]
      --,[moh_dia_diagnosis_type_code]
      --,[moh_dia_clinical_code]
	  ,'pub_diab' AS [source]
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_pfhd_chronic_diags]
FROM [IDI_Clean_202203].[moh_clean].[pub_fund_hosp_discharges_diag]
WHERE [moh_dia_submitted_system_code] = [moh_dia_clinical_sys_code] /* higher accuracy when systems match */
AND [moh_dia_diagnosis_type_code] IN ('A', 'B') /* diagnosies */
AND [moh_dia_clinical_sys_code] IN ('10', '11', '12', '13', '14') /* ICD-10-AM */
AND (
	SUBSTRING([moh_dia_clinical_code], 1, 3) IN (
		 'E10' /* Type 1 DM */
		,'E11' /* TYPE 2 DM */
		,'E13' /* Other specified DM */
		,'E14' /* Unspecified DM */
	)
	OR SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('O240', 'O241', 'O242', 'O243') /* pre-existing diabetes in pregnancy */
)

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_pfhd_chronic_diags] ([event_id]);
GO

/* Clear before creation */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_vfhd_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_vfhd_chronic_diags];
GO

/************************************ privately funded hospital discharages ************************************/
SELECT [moh_pri_diag_event_id_nbr] AS [event_id]
      --,[moh_pri_diag_clinic_sys_code]
      --,[moh_pri_diag_sub_sys_code]
      --,[moh_pri_diag_diag_type_code]
      --,[moh_pri_diag_clinic_code]
	  ,'priv_diab' AS [source]
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_vfhd_chronic_diags]
FROM [IDI_Clean_202203].[moh_clean].[priv_fund_hosp_discharges_diag]
WHERE [moh_pri_diag_sub_sys_code] = [moh_pri_diag_clinic_sys_code] /* higher accuracy when systems match */
AND [moh_pri_diag_diag_type_code] IN ('A', 'B') /* diagnosies */
AND [moh_pri_diag_clinic_sys_code] IN ('10', '11', '12', '13','14') /* ICD-10-AM */
AND (
	SUBSTRING([moh_pri_diag_clinic_code], 1, 3) IN (
		 'E10' /* Type 1 DM */
		,'E11' /* TYPE 2 DM */
		,'E13' /* Other specified DM */
		,'E14' /* Unspecified DM */
	)
	OR SUBSTRING([moh_pri_diag_clinic_code], 1, 4) IN ('O240', 'O241', 'O242', 'O243') /* pre-existing diabetes in pregnancy */
)

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_vfhd_chronic_diags] ([event_id]);
GO

/* Clear before creation */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_pharm_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_pharm_chronic_diags];
GO

/************************************ pharmaceuticals ************************************/
/* Ignores one chemical IDs:
1794 - Metformin hydrochloride
The chronic table also includes this chemical, but excludes women aged 12-45 who may have only been dispensed Metformin
AND do not meet any of the other criteria.
Note: This is intended to exclude women age 12-45 whom may have polycystic ovary syndrome treated with metformin.
*/

SELECT [snz_uid]
      ,MIN([moh_pha_dispensed_date]) AS [moh_pha_dispensed_date]
	  --,[moh_pha_dim_form_pack_code]
	  --,[DIM_FORM_PACK_SUBSIDY_KEY]
      --,[CHEMICAL_ID]
      --,[CHEMICAL_NAME]
      --,[FORMULATION_ID]
      --,[FORMULATION_NAME]
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_pharm_chronic_diags]
FROM [IDI_Clean_202203].[moh_clean].[pharmaceutical] a
LEFT JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[moh_dim_form_pack_subsidy_code] b
ON a.[moh_pha_dim_form_pack_code] = b.[DIM_FORM_PACK_SUBSIDY_KEY]
WHERE snz_uid <> -1 /* remove non-personal identities */
AND [CHEMICAL_ID] IN (
	 1192 /* Insulin lispro */
	,1570 /* Glucagon hydrochloride */
	,1648 /* Insulin Neutral */
	,1649 /* Insulin isophane */
	,1655 /* Insulin zinc suspension */
	,3783 /* Insulin aspart */
	,3857 /* Insulin glargine */
	,6300 /* Insulin isophane with insulin neutral */
	,1068 /* Chlorpropamide */
	,1247 /* Acarbose */
	,1567 /* Glibenclamide */
	,1568 /* Gliclazide */
	,1569 /* Glipizide */
	,2276 /* Tolazamide */
	,2277 /* Tolbutamide */
	,3739 /* Rosiglitazone */
	,3800 /* Pioglitazone */

	,1794 /* Metformin hydrochloride --added based on advise by MOH but won't have much effect on Seniors project*/
	,3882 /* Insulin lispro with insulin lispro protamine */
	,3908 /* Insulin glulisine */
	,4103 /* Vildagliptin */
	,4104 /* Vildagliptin with metformin hydrochloride */
	,4137 /* Empagliflozin */
	,4138 /* Empagliflozin with metformin hydrochloride */

)
GROUP BY [snz_uid]
	  --,[moh_pha_dim_form_pack_code]
	  --,[DIM_FORM_PACK_SUBSIDY_KEY]
      --,[CHEMICAL_ID]
      --,[CHEMICAL_NAME]
      --,[FORMULATION_ID]
      --,[FORMULATION_NAME]


/* Clear before creation */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_nnpac_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_nnpac_chronic_diags];
GO

/************************************ National Non-Admitted Patient Collection ************************************/
SELECT [snz_uid]
	  ,MIN([moh_nnp_service_date]) AS [moh_nnp_service_date]
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_nnpac_chronic_diags]
FROM [IDI_Clean_202203].[moh_clean].[nnpac]
WHERE [moh_nnp_purchase_unit_code] IN ('M20006', 'M20007')
AND [moh_nnp_attendence_code] = 'ATT' /* attended */
GROUP BY [snz_uid]

/* Clear before creation */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2018-48].[defn_chronic_diabetes]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_chronic_diabetes];
GO

/************************************ combined final table ************************************/

SELECT *
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_chronic_diabetes]
FROM (
/* public */
SELECT [snz_uid]
	  --,[event_id]
      ,[source]
	  ,[moh_evt_evst_date] AS [start_date]
	  ,[moh_evt_even_date] AS [end_date]
FROM [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_pfhd_chronic_diags] a
INNER JOIN [IDI_Clean_202203].[moh_clean].[pub_fund_hosp_discharges_event] b
ON a.[event_id] = b.[moh_evt_event_id_nbr]

UNION ALL

/* private */
SELECT [snz_uid]
	  --,[event_id]
	  ,[source]
	  ,[moh_pri_evt_start_date] AS [start_date]
      ,[moh_pri_evt_end_date] AS [end_date]
FROM [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_vfhd_chronic_diags] a
INNER JOIN [IDI_Clean_202203].[moh_clean].[priv_fund_hosp_discharges_event] b
ON a.[event_id] = b.[moh_pri_evt_event_id_nbr]

UNION ALL

/* pharmaceuticals */
SELECT [snz_uid]
      --,NULL AS [event_id]
	  ,'pha_diab' AS [source]
	  ,[moh_pha_dispensed_date] AS [start_date]
	  ,[moh_pha_dispensed_date] AS [end_date]
FROM [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_pharm_chronic_diags]

UNION ALL

 /* Non-admittted hospital patients */
 SELECT [snz_uid]
	  --,NULL AS [event_id]
	  ,'out_diab' AS [source]
	  ,[moh_nnp_service_date] AS [start_date]
	  ,[moh_nnp_service_date] AS [end_date]
FROM [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_nnpac_chronic_diags]

) k

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2018-48].[defn_chronic_diabetes] ([snz_uid]);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_chronic_diabetes] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/************************************ tidy tempoary tables away ************************************/

IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_pfhd_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_pfhd_chronic_diags];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_vfhd_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_vfhd_chronic_diags];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_pharm_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_pharm_chronic_diags];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_nnpac_chronic_diags]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_tmp_nnpac_chronic_diags];
GO
