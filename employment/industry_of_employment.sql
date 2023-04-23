/**************************************************************************************************
Title: Industry of employment
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
Industry of employer. Requires people to be employeers (have wages or salaries > 0)

Intended purpose:
Determining the mixture of businesses in an area.

Inputs & Dependencies:
- [IDI_Clean].[ir_clean].[ird_ems]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_ANZSIC06]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[defn_industry]

Notes:
1) Industry as reported in monthly summary to IRD. Coded according to level 2
   of ANZSIC 2006 codes (87 different values).
2) There are two sources from which industry type can be drawn:
   PBN = Permanent Business Bumber
   ENT = The Entity
   We prioritise the PBN over the ENT.
3) Note that this is not perfect identification of role/responsibilities due to lack of
   distinction between business industry and personal industry. For example the
   manager of a retirement home is likely to have ANZSIC code for personal care, not
   for management.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = defn_
  Project schema = [DL-MAA20XX-YY]

Issues:
 
History (reverse order):
2020-05-20 SA v1
**************************************************************************************************/

/* Set database for writing views */
USE IDI_UserCode
GO

/* Clear existing view */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[defn_industry];
GO

/* Create view */
CREATE VIEW [DL-MAA20XX-YY].[defn_industry] AS
SELECT  [snz_uid]
      ,[ir_ems_return_period_date]
	  ,[ir_ems_pbn_anzsic06_code]
	  ,k.[ir_ems_ent_anzsic06_code]
	  ,k.anzsic06
	  ,[descriptor_text]
FROM (

SELECT [snz_uid]
      ,[ir_ems_return_period_date]
	  ,[ir_ems_pbn_anzsic06_code]
	  ,[ir_ems_ent_anzsic06_code]
	  ,LEFT(COALESCE([ir_ems_pbn_anzsic06_code], [ir_ems_ent_anzsic06_code]), 1) AS anzsic06
FROM [IDI_Clean_YYYYMM].[ir_clean].[ird_ems]
WHERE [ir_ems_gross_earnings_amt] > 0
AND [ir_ems_income_source_code] = 'W&S'

) k
INNER JOIN [IDI_Metadata].[clean_read_CLASSIFICATIONS].[CEN_ANZSIC06] b
ON k.anzsic06 = b.[cat_code]
WHERE anzsic06 IS NOT NULL;
GO
