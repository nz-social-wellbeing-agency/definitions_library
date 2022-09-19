/**************************************************************************************************
Title: Cancer register
Author: MOH
Re-edit: Manjusha Radhakrishnan
Reviewer: 

Inputs & Dependencies:
- [moh_clean].[cancer_registrations]
- [moh_clean].[nnpac]

Outputs:
- [IDI_Sandpit].[DL-MAA2018-48].[def_cancer]

Intended purpose:
Create register of people who have been added to the cancer register or received treatment for cancer in the past years

Notes:
1. Cancer codes used:
	- ICD 10 codes: C00-C96, D00-D48, N60, N84, N87, Z08-Z09, Z12, Z80, Z85, Z86
	- NNPAC codes: M5007-M50025, M54002-M54004, MS02009, M30020-M30021

Parameters & Present values:
  Current refresh = 202203
  Prefix = defn_
  Project schema = [DL-MAA2018-48]

Issues:
1. Duplicates can be found; this is because a person may receive multiple treatments for the same condition

History (reverse order):
2022-07-20 MR v1
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[def_cancer]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2018-48].[def_cancer] (
	snz_uid	INT
	, event_date DATE
	, source VARCHAR(255)
);
GO

/** NMDS query - to access hospitalisation data **/
INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[def_cancer] (snz_uid, event_date, source)
SELECT	snz_uid
		,moh_can_diagnosis_date AS event_date
		, 'CANCER REG' AS source
FROM [IDI_Clean_202203].[moh_clean].[cancer_registrations]
WHERE moh_can_extent_of_disease_code NOT IN ('0','A')
	AND (SUBSTRING(moh_can_site_code,1,3) IN ('C00','C01','C02','C03','C04','C05','C06','C07','C08','C09',
				'C10','C11','C12','C13','C14','C15','C16','C17','C18','C19','C20',
				'C20','C21','C22','C23','C24','C25','C26','C27','C28','C29','C30','C31','C32','C33','C34','C35','C36',
				'C37','C38','C39','C40','C41','C42','C43','C44','C45','C46','C47','C48','C49',
				'C50','C51','C52','C53','C54','C55','C56','C57','C58','C59','C60','C61','C62','C63','C64','C65','C66',
				'C67','C68','C69','C70','C71','C72','C73','C74','C75','C76','C77','C78','C79',
				'C80','C81','C82','C83','C84','C85','C86','C87','C88','C89','C90','C91','C92','C93','C94','C95','C96',
				'D00','D01','D02','D03','D04','D05','D06','D07','D08','D09',
				'D10','D11','D12','D13','D14','D15','D16','D17','D18','D19','D20',
				'D20','D21','D22','D23','D24','D25','D26','D27','D28','D29','D30','D31','D32','D33','D34','D35','D36',
				'D37','D38','D39','D40','D41','D42','D43','D44','D45','D46','D47','D48',
				'N60','N84','N87','Z08','Z09','Z12','Z80','Z85','Z86'))
GO

/** NNPAC data **/
INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[def_cancer] (snz_uid, event_date, source)
SELECT snz_uid
      ,moh_nnp_service_date AS event_date
	  ,'NNPAC' AS source
  FROM [IDI_Clean_202203].[moh_clean].[nnpac]
  WHERE moh_nnp_purchase_unit_code IN ('M5007','M5008','M5009', 'M50010', 'M50011','M50012','M50013','M50014','M50015','M50016','M50017','M50018','M50019','M50020','M50021','M50022',
                                   'M50023','M50024','M50025','M54002','M54003','M54004','MS02009','M30020','M30021')
GO