/**************************************************************************************************
Title: Parenthood
Author: Joel Bancolita, Marianna Pekar

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
Identfying whether someone is a biological parent

Intended purpose:
When a person became a parent.
Identifying the birth of a child.

Inputs & Dependencies:
- [IDI_Clean].[dia_clean].[births]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[vacc_biol_parent]


Notes:
1) No controls are included for whether of not a parent has any role
	in their child's life. Biological parents may not be the caregivers of a child.
	Parental involvement might be proxied by checking how much the child and the
	parent(s) share an address.
2) Captures births in NZ. Unlikely to capture births that occurred overseas.
	Some family information is included in migrant records and could supplement this.
3) How/whether adoption interacts with birth records should be checked for researchers
	considering this are advised to investigate further. It is possible that adoption
	masks the biological birth record with the adoptive record for ease of administration.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = vacc_
  Project schema = DL-MAA20XX-YY
 
Issues:

History (reverse order):
2021-08-31 MP
2020-08-24 MP
2020-06-10 JB
**************************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA20XX-YY].[vacc_biol_parent];
GO

CREATE VIEW [DL-MAA20XX-YY].[vacc_biol_parent] AS
/* parent 1 */
SELECT [snz_uid] AS child_snz_uid
	,[parent1_snz_uid] AS parent_snz_uid
	,DATEFROMPARTS(dia_bir_birth_year_nbr, dia_bir_birth_month_nbr, 15) AS birth_date_proxy
FROM [IDI_Clean_YYYYMM].[dia_clean].[births]
WHERE dia_bir_still_birth_code IS NULL
AND [parent1_snz_uid] IS NOT NULL
AND [snz_uid] IS NOT NULL

UNION ALL
	
/* parent 2 */
SELECT [snz_uid] AS child_snz_uid
	,[parent2_snz_uid] AS parent_snz_uid
	,DATEFROMPARTS(dia_bir_birth_year_nbr, dia_bir_birth_month_nbr, 15) AS birth_date_proxy
FROM [IDI_Clean_YYYYMM].[dia_clean].[births]
WHERE dia_bir_still_birth_code IS NULL
AND [parent2_snz_uid] IS NOT NULL
AND [snz_uid] IS NOT NULL
GO
