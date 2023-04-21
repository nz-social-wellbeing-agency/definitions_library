/**************************************************************************************************
Title: T2 benefit receipt by type
Author: Michael Hackney and Simon Anastasiadis, et. al. (HaBiSA project), 
Reviewer: Simon Anastasiadis, AK

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
Supplementary benefits received from MSD.

Intended purpose:
Identify periods of Tier 2 benefit receipt, value of Tier 2 benefit received,
and to identify the types of T2 benefits.

Inputs & Dependencies:
- [IDI_Clean].[msd_clean].[msd_second_tier_expenditure]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_benefit_type_code]
- [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_benefit_type_code_4] 
Outputs:
- [IDI_Sandpit].[DL-MAA20XX-YY].[supplementary_benefit_receipt]

Notes:
1) Periods of Tier 2 benefit receipt with daily amount received.
2) The IDI metadata database contains multiple tables that translate benefit type codes into benefit 
	names/descriptions. The differences between these tables are not well explained.
	As not every code appears in every table, for some applications we need to combine multiple metadata tables.


Parameters & Present values:
  Current refresh = YYYYMM
  Project schema = DL-MAA20XX-YY
 
Issues:

History (reverse order):
2021-09-03 MP modify for vaccination modelling
2019-04-09 AK QA, archived manual list, replaced with join to metadata, value change to total for period
2019-04-23 AK Changes applied, Code Index for codes 604, 605, 667 not available, Joining two tables, table meta data not available
2019-04-26 SA notes added above
2018-12-06 SA reviewed
2018-12-04 initiated
**************************************************************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA20XX-YY].[supplementary_benefit_receipt];
GO

WITH code_classifications AS (
	-- Code classifications
	SELECT [Code], [classification]
	FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_benefit_type_code]

	UNION ALL

	SELECT [Code], [classification]
	FROM [IDI_Metadata].[clean_read_CLASSIFICATIONS].[msd_benefit_type_code_4] -- add three codes that do not appear in the first metadata table
	WHERE Code IN (604, 605, 667)
)
SELECT DISTINCT snz_uid
	,[Code]
	,[classification]
	,msd_ste_start_date
	,msd_ste_end_date
	,[msd_ste_daily_gross_amt] AS daily_payment_amount
	,[msd_ste_daily_gross_amt] * (1 + DATEDIFF(DAY, msd_ste_start_date, msd_ste_end_date)) AS total_payment_amount
INTO [IDI_Sandpit].[DL-MAA20XX-YY].[vacc_supplementary_benefit_receipt]
FROM [IDI_Clean_YYYYMM].[msd_clean].[msd_second_tier_expenditure]  t2
INNER JOIN code_classifications AS codes
ON t2.[msd_ste_supp_serv_code] = codes.Code
WHERE [msd_ste_supp_serv_code] IS NOT NULL
GO

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA20XX-YY].[supplementary_benefit_receipt] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA20XX-YY].[supplementary_benefit_receipt] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO
