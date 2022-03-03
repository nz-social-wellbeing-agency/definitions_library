/**************************************************************************************************
Title: CHiPs - Community Housing Providers
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[dbh_clean].[bond_lodgement]
Outputs:
- [IDI_UserCode].[DL-MAA2021-49].[vacc_community_housing]

Description:
Address UIDs for local authority Community Housing Providers (CHiPs)

Intended purpose:
Identifies addresses that are social/community housing provided by
local authorities, e.g. councils (in contrast to central government
provided social housing).

Notes:
1) The address UIDs from this definition can be joined to address_notifications
	table to identify people who's addresses are in community housing
2) Estimated/expected to be ~5000 address UIDs.
	We observe about 4950 addresses, so there are a few missing address uids.

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
Issues:

History (reverse order):
2021-11-20 CW
**************************************************************************************************/

USE IDI_UserCode
GO

DROP VIEW IF EXISTS [DL-MAA2021-49].[vacc_community_housing]
GO

CREATE VIEW [DL-MAA2021-49].[vacc_community_housing] AS
SELECT DISTINCT 
	[dbh_bond_landlord_group_code]
	,[dbh_bond_landlord_group_text]
	,[snz_idi_address_register_uid]
FROM [IDI_Clean_20211020].[dbh_clean].[bond_lodgement]
WHERE [dbh_bond_landlord_group_code] ='LOC'
AND [dbh_bond_tenancy_end_date] IS NULL -- tenancy is ongoing
GO
