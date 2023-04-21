/**************************************************************************************************
Title: ASH and child ASH/PAH
Author: HZ

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
Ambulatory sensitive hospitalisations (ASH) and Child ASH & Potentially Avoidable Hospitalisation (PAH)

Intended purpose:
Defines spells where clients have had a publicly funded hospital event which is considered
to be an Ambulatory Sensitive Care Hospitalisation (ASH) condition, child-related
Ambulatory Sensitive Care and/or Potentially avoidable hospitalisation (PAH). 

This includes the diagnosis (ICD10 code) and the relevant ages for which it is considered an ASH/PAH event.

Inputs & Dependencies:
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_diag]
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]
Outputs:
- [IDI_UserCode].[$(PROJSCH)].[$(TBLPREF)ash]

 
Notes:
1) Ambulatory Sensitive Hospitalisations (ASH) are the most acute admissions that are
	considered potentially reducible through prophylactic or therapeutic interventions
	deliverable in a primary care setting.
2) Potentially Avoidable Hospitalisations (PAH) is an indicator of health-related outcomes
	under the Child and Youth Wellbeing Strategy, and a Child Poverty Related Indicator
	required by the Child Poverty Reduction Act 2018.
3) The main ASH definition has been constructed from the description provided by Craig.
	This includes a list of diagnosis and procedure codes and the recommended age bracket for each condition.
4) The child ASH/PAH definitions have been constructed using the codes provided in Table 2 and 3 of 
	The New Zealand Medical Journal article called "Developing a tool to monitor potentially avoidable
	and ambulatory care sensitive hospitalisations in New Zealand children".
5) The [end_date] in this table is the end of the hospital visit when diagnosis took place,
	NOT the date that the chronic condition ended.
6) Most Child ASH and PAH codes correspond to children aged 1 month to 14 years. These are the upper and
	lower age bounds unless otherwise specified.
(pg. 28, www.journal.nzma.org.nz/journal-articles/developing-a-tool-to-monitor-potentially-avoidable-and-ambulatory-care-sensitive-hosptilisations-in-new-zealand-children).

Parameters & Present values:
  Current refresh = $(IDIREF)
  Prefix = $(TBLPREF)
  Project schema = [$(PROJSCH)]
 
Issues:

History (reverse order):


**************************************************************************************************/
--PARAMETERS##################################################################################################
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
--Already in master.sql; Uncomment when running individually
:setvar TBLPREF "SWA" 
:setvar IDIREF "IDI_Clean_YYYYMM" 
:setvar PROJSCH "DL-MAA20XX-YY"
GO

--##############################################################################################################

/* Clear before creation */
DROP TABLE IF EXISTS [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_ash_event];
GO

/************************************ publically funded hospital discharges ************************************/
SELECT [moh_dia_event_id_nbr]
      ,[moh_dia_clinical_code]
INTO [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_ash_event]
FROM [$(IDIREF)].[moh_clean].[pub_fund_hosp_discharges_diag]
WHERE [moh_dia_submitted_system_code] = [moh_dia_clinical_sys_code] /* higher accuracy when systems match */
AND (
/* diagnosis in ICD10 */
[moh_dia_diagnosis_type_code] IN ('A', 'B') /*"A" is "Principle diagnosis" and "B" is "Other relevant diagnosis" */
AND [moh_dia_clinical_sys_code] IN ('10', '11', '12', '13', '14') /* ICD-10-AM - First, second, third, sixth, eighth edition*/
AND (   SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('A00', 'A01', 'A02', 'A03', 'A04', 'A05', 'A06', 'A07', 'A08', 'A09', 'A15', 
													 'A16', 'A17', 'A18', 'A19', 'A33', 'A34', 'A35', 'A36', 'A37', 'A39', 'A50', 
													 'A51', 'A52', 'A53', 'A54', 'A55', 'A56', 'A57', 'A58', 'A59', 'A60', 'A63', 
													 'A64', 'A80', 'A87', 'B05', 'B06', 'B16', 'B18', 'B26', 'B34', 'C53', 'D50', 
													 'D51', 'D52', 'D53', 'E10', 'E11', 'E13', 'E14', 'E40', 'E41', 'E42', 'E43', 
													 'E44', 'E45', 'E46', 'E47', 'E48', 'E49', 'E50', 'E51', 'E52', 'E53', 'E54', 
													 'E55', 'E56', 'E57', 'E58', 'E59', 'E60', 'E61', 'E62', 'E63', 'E64', 'G00', 
													 'G01', 'G02', 'G03', 'G40', 'G41', 'H65', 'H66', 'H67', 'I00', 'I01', 'I02', 
													 'I05', 'I06', 'I07', 'I08', 'I09', 'I10', 'I11', 'I12', 'I13', 'I15', 'I20', 
													 'I21', 'I22', 'I23', 'I25', 'I50', 'I61', 'I63', 'I64', 'I65', 'I66', 'J00', 
													 'J01', 'J02', 'J03', 'J04', 'J06', 'J12', 'J13', 'J14', 'J15', 'J16', 'J18', 
													 'J21', 'J22', 'J44', 'J45', 'J46', 'J47', 'J81', 'K02', 'K04', 'K05', 'K21', 
													 'K25', 'K26', 'K27', 'K28', 'L00', 'L01', 'L02', 'L03', 'L04', 'L05', 'L08', 
													 'L20', 'L21', 'L22', 'L23', 'L24', 'L25', 'L26', 'L27', 'L28', 'L29', 'L30', 
													 'M86', 'N10', 'N12', 'O15', 'R11')
	 OR SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('A403', 'B180', 'B181', 'E162', 'H000', 'H010', 'I240', 'I241', 'I248', 'I249', 
													 'I674', 'J050', 'J100', 'J110', 'J340', 'K529', 'K590', 'L980', 'M014', 'M023', 
													 'M833', 'N136', 'N300', 'N309', 'N341', 'N390', 'P350', 'R062', 'R072', 'R073', 
													 'R074', 'R560', 'R568') 
													 ) /*Include only all main ASH, child ASH, and PAH ICD10 codes*/
)

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_ash_event] ([moh_dia_event_id_nbr]);
GO

/* Clear before creation */
DROP TABLE IF EXISTS [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_ash];
GO

/************************************ combined final table ************************************/
SELECT [snz_uid]
	  ,[moh_dia_event_id_nbr]
	  ,[start_date]
	  ,[end_date]
	  --,[moh_dia_clinical_code]
	  --,[moh_evt_birth_month_nbr]
	  --,[moh_evt_birth_year_nbr]
	  --,age_mnths
	  ,main_ASH
	  ,chld_ASH
	  ,chld_PAH
INTO [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_ash]
FROM (
SELECT *
/*Group the ICD10 codes as child PAH/ASH condition or Main ASH*/
-------------------------------------------------------------------------------
/*Child PAH*/
	,CASE WHEN SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('A00', 'A01', 'A02', 'A03', 'A04', 'A05', 'A06', 'A07', 'A08', 'A09', 'A15', 
															'A16', 'A17', 'A18', 'A19', 'A33', 'A34', 'A35', 'A36', 'A37', 'A39', 'A80', 
															'A87', 'B05', 'B06', 'B16', 'B26', 'B34', 'D50', 'D51', 'D52', 'D53', 'E40', 
															'E41', 'E42', 'E43', 'E44', 'E45', 'E46', 'E47', 'E48', 'E49', 'E50', 'E51', 
															'E52', 'E53', 'E54', 'E55', 'E56', 'E57', 'E58', 'E59', 'E60', 'E61', 'E62', 
															'E63', 'E64', 'G00', 'G01', 'G02', 'G03', 'H65', 'H66', 'H67', 'I00', 'I01', 
															'I02', 'I05', 'I06', 'I07', 'I08', 'I09', 'J00', 'J01', 'J02', 'J03', 'J04', 
															'J06', 'J12', 'J13', 'J14', 'J15', 'J16', 'J18', 'J21', 'J45', 'J46', 'J47', 
															'K02', 'K04', 'K05', 'K21', 'L00', 'L01', 'L02', 'L03', 'L04', 'L05', 'L08', 
															'L20', 'L21', 'L22', 'L23', 'L24', 'L25', 'L26', 'L27', 'L28', 'L29', 'L30', 
															'M86', 'R11') 
			AND age_mnths >= 1 AND age_mnths <= 168 THEN 1 /*3 substring - events that apply to ages greater than 1 month and less than 14 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('B180', 'B181', 'H000', 'H010', 'J050', 'J100', 'J110', 'J340', 'K529', 'K590', 'L980',
														  'M014', 'P350', 'R560')
			AND age_mnths >= 1 AND age_mnths <= 168 THEN 1 /*4 substring - events that apply to ages greater than 1 month and less than 14 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('N10', 'N12')
			AND age_mnths >= 60 and age_mnths <= 168 THEN 1 /*3 substring - events that apply to ages older than 5 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('N300', 'N390', 'N136', 'N309') 
			AND age_mnths >= 60 and age_mnths <= 168 THEN 1 /*4 substring - events that apply to ages older than 5 years*/
		ELSE 0 END AS chld_PAH

-------------------------------------------------------------------------------
/*Child ASH*/
	,CASE WHEN SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('A02', 'A03', 'A04', 'A05', 'A06', 'A07', 'A08', 'A09', 'A33', 'A34', 'D50',
															'D51', 'D52', 'D53', 'E40', 'E41', 'E42', 'E43', 'E44', 'E45', 'E46', 'E47',
															'E48', 'E49', 'E50', 'E51', 'E52', 'E53', 'E54', 'E55', 'E56', 'E57', 'E58',
															'E59', 'E60', 'E61', 'E62', 'E63', 'E64', 'H65', 'H66', 'H67', 'I00', 'I01',
															'I02', 'I05', 'I06', 'I07', 'I08', 'I09', 'J00', 'J01', 'J02', 'J03', 'J06',
															'J13', 'J14', 'J15', 'J16', 'J18', 'J45', 'J46', 'J47', 'K02', 'K04', 'K05',
															'K21', 'L00', 'L01', 'L02', 'L03', 'L04', 'L05', 'L08', 'L20', 'L21', 'L22',
															'L23', 'L24', 'L25', 'L26', 'L27', 'L28', 'L29', 'L30', 'R11')
			AND age_mnths >= 1 AND age_mnths <= 168 THEN 1 /*3 substring - events that apply to ages greater than 1 month and less than 14 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('K590', 'K529', 'L980', 'J340', 'H010', 'H000', 'P350')
			AND age_mnths >= 1 AND age_mnths <= 168 THEN 1 /*4 substring - events that apply to ages greater than 1 month and less than 14 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('N10', 'N12')
			AND age_mnths >= 60 and age_mnths <= 168  THEN 1 /*3 substring - events that apply to ages older than 5 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('N300', 'N390', 'N136', 'N309') 
			AND age_mnths >= 60 and age_mnths <= 168  THEN 1 /*4 substring - events that apply to ages older than 5 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('B05', 'B06', 'B26')
			AND age_mnths > 16 and age_mnths <= 168 THEN 1 /*3 substring - events that apply to ages older than 16 months*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('M014') 
			AND age_mnths > 16 and age_mnths <= 168 THEN 1 /*4 substring - events that apply to ages older than 16 months*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('A35', 'A36', 'A37', 'A80', 'B16')
			AND age_mnths > 6 and age_mnths <= 168 THEN 1 /*3 substring - events that apply to ages older than 6 months*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('B180', 'B181') 
			AND age_mnths > 6 and age_mnths <= 168 THEN 1 /*4 substring - events that apply to ages older than 6 months*/
		ELSE 0 END AS chld_ASH

-------------------------------------------------------------------------------
/*Main ASH*/
	,CASE WHEN SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('J22')
			AND age_mnths >= 0 AND age_mnths <= 48 THEN 1 /*3 substring - events that apply to ages greater than 0 month and less than 4 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('R062')
			AND age_mnths >= 0 AND age_mnths <= 48 THEN 1 /*4 substring - events that apply to ages greater than 0 month and less than 4 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('B05', 'B06', 'B26')
			AND age_mnths >= 15 AND age_mnths <= 168 THEN 1 /*3 substring - events that apply to ages greater than 15 month and less than 14 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('P350')
			AND age_mnths >= 15 AND age_mnths <= 168 THEN 1 /*4 substring - events that apply to ages greater than 15 month and less than 14 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('A50', 'A51', 'A52', 'A53', 'A54', 'A55', 'A56', 'A57', 'A58', 'A59', 'A60', 
														  'A63', 'A64', 'C53', 'E10', 'E11', 'E13', 'E14', 'G40', 'G41', 'I10', 'I11', 
														  'I12', 'I13', 'I15', 'I20', 'I21', 'I22', 'I23', 'I25', 'I50', 'I61', 'I63', 
														  'I64', 'I65', 'I66', 'J44', 'J47', 'J81', 'K25', 'K26', 'K27', 'K28', 'O15')
			AND age_mnths >= 180  THEN 1 /*3 substring - events that apply to ages greater than 15 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('E162', 'I240', 'I241', 'I248', 'I249', 'I674', 'M023', 'M833', 'N341', 
														  'R072', 'R073', 'R074', 'R560', 'R568') 
			AND age_mnths >= 180  THEN 1 /*4 substring - events that apply to ages greater than 15 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('N10', 'N12')
			AND age_mnths >= 60  THEN 1 /*3 substring - events that apply to ages greater than 5 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('N136', 'N309', 'N390') 
			AND age_mnths >= 60  THEN 1 /*4 substring - events that apply to ages greater than 5 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('A33', 'A34', 'A35', 'A36', 'A37', 'A80', 'B16', 'B18')
			AND age_mnths >= 6 AND age_mnths <= 168 THEN 1 /*3 substring - events that apply to ages greater than 6 month and less than 14 years*/ 
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('A403')
			AND age_mnths >= 6 AND age_mnths <= 168 THEN 1 /*4 substring - events that apply to ages greater than 6 month and less than 14 years*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 3) IN ('A02', 'A03', 'A04', 'A05', 'A06', 'A07', 'A08', 'A09', 'D50', 'D51', 'D52', 
														  'D53', 'E40', 'E41', 'E42', 'E43', 'E44', 'E45', 'E46', 'E50', 'E51', 'E52', 
														  'E53', 'E54', 'E55', 'E56', 'E58', 'E59', 'E60', 'E61', 'E63', 'H65', 'H66', 
														  'H67', 'I00', 'I01', 'I02', 'I05', 'I06', 'I07', 'I08', 'I09', 'J00', 'J01', 
														  'J02', 'J03', 'J04', 'J06', 'J13', 'J14', 'J15', 'J16', 'J18', 'J45', 'J46', 
														  'K02', 'K04', 'K05', 'K21', 'L01', 'L02', 'L03', 'L04', 'L08', 'L20', 'L21', 
														  'L22', 'L23', 'L24', 'L25', 'L26', 'L27', 'L28', 'L29', 'L30', 'R11')
			AND age_mnths >= 0  THEN 1 /*3 substring - events that apply to all ages*/
		WHEN SUBSTRING([moh_dia_clinical_code], 1, 4) IN ('H000', 'H010', 'J340', 'K529', 'K590', 'L980') 
			AND age_mnths >= 0  THEN 1 /*4 substring - events that apply to all ages*/
		ELSE 0 END AS main_ASH

FROM (
/* public */
SELECT [snz_uid]
	  ,[moh_dia_event_id_nbr]
	  ,[moh_evt_evst_date] AS [start_date]
	  ,[moh_evt_even_date] AS [end_date]
	  ,a.[moh_dia_clinical_code]
	  ,[moh_evt_birth_month_nbr]
	  ,[moh_evt_birth_year_nbr]
	  /*Determine the age (in months) of the individual at time of event*/
	  ,DATEDIFF(month, (DATEFROMPARTS([moh_evt_birth_year_nbr], [moh_evt_birth_month_nbr], 15)), [moh_evt_evst_date]) AS age_mnths
FROM [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_ash_event] a
INNER JOIN [$(IDIREF)].[moh_clean].[pub_fund_hosp_discharges_event] b
ON a.[moh_dia_event_id_nbr] = b.[moh_evt_event_id_nbr]
) k
) m
WHERE chld_PAH!=0 or chld_ASH!=0 or main_ASH!=0 /*Remove spells for individuals whose ages do not correspond to the age bands for ASH or child ASH/PAH*/

/* Add index */
CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_ash] ([snz_uid]);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_ash] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/************************************ tidy temporary tables away ************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[$(PROJSCH)].[$(TBLPREF)_ash_event];
GO


