/**************************************************************************************************
Title: Parenthood
Author: Joel Bancolita, Marianna Pekar

Inputs & Dependencies:
- [IDI_Clean].[dia_clean].[births]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_biol_parent]

Description:
Identfying whether someone is a biological parent

Intended purpose:
When a person became a parent.
Identifying the birth of a child.

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
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:

History (reverse order):
2021-08-31 MP
2020-08-24 MP
2020-06-10 JB
**************************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_biol_parent];
GO

CREATE VIEW [DL-MAA2021-49].[vacc_biol_parent] AS
/* parent 1 */
SELECT [snz_uid] AS child_snz_uid
	,[parent1_snz_uid] AS parent_snz_uid
	,DATEFROMPARTS(dia_bir_birth_year_nbr, dia_bir_birth_month_nbr, 15) AS birth_date_proxy
FROM [IDI_Clean_20211020].[dia_clean].[births]
WHERE dia_bir_still_birth_code IS NULL
AND [parent1_snz_uid] IS NOT NULL
AND [snz_uid] IS NOT NULL

UNION ALL
	
/* parent 2 */
SELECT [snz_uid] AS child_snz_uid
	,[parent2_snz_uid] AS parent_snz_uid
	,DATEFROMPARTS(dia_bir_birth_year_nbr, dia_bir_birth_month_nbr, 15) AS birth_date_proxy
FROM [IDI_Clean_20211020].[dia_clean].[births]
WHERE dia_bir_still_birth_code IS NULL
AND [parent2_snz_uid] IS NOT NULL
AND [snz_uid] IS NOT NULL
GO
