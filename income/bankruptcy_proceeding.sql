/**************************************************************************************************
Title: Bankrupt proceedings
Author: Simon Anastasiadis
Reviewer: Marianna Pekar

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
Any bankruptcy proceedings against a person, irrespective of whether they result in the person being declared bankrupt/insolvent.

Intended purpose:
Identifying when/whether people are having trouble making repayments on their debt.

Inputs & Dependencies:
- [IDI_Clean].[ir_clean].[ird_customers]
Outputs:
- [IDI_UserCode].[DL-MAA20XX-YY].[d2g_bankruptcy_proceeding]

Notes:
1) Conversation with Joanne Butterfield (IRD) on 2020-01-08:
   - IRD applies the 'B' flag in the customers table when any bankruptcy proceedings
     are in progress. These do not always result in an insolvency (if people can
     resume making repayments or if another process is used, such as a no-asset proceedure).
   - New IRD numbers are issues when a person has completed bankruptcy/insolvency.
   Therefore
   - We use the customers table as an indication of 'trouble making repayments'
   - We use the cross-reference table to identify people declared bankrupt.
2) The New Zealand Insolvency and Trustee Service (insolvency.govt.nz) is the government
   office (part of MBIE) who handles insolvency. They distinguish between bankruptcy
   (which applies to individuals) and liquidation & receivership (which apply to companies).
   Sole traders are trated as individuals, because they are not distinct legal entities.
3) This definition is for people who have any bankruptcy proceeding against them.

Parameters & Present values:
  Current refresh = YYYYMM
  Prefix = d2g_
  Project schema = [DL-MAA20XX-YY]

Issues:
 
History (reverse order):
2020-07-17 MP QA
2020-03-02 SA v1
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

/* Clear view */
DROP VIEW IF EXISTS [DL-MAA20XX-YY].[d2g_bankruptcy_proceeding];
GO

CREATE VIEW [DL-MAA20XX-YY].[d2g_bankruptcy_proceeding] AS
SELECT [snz_uid]
	,[ir_cus_applied_date] AS [start_date]
	,[ir_cus_ceased_date] AS [end_date]
	,[ir_cus_client_status_code]
FROM [IDI_Clean_YYYYMM].[ir_clean].[ird_customers]
WHERE [ir_cus_client_status_code] IN ('B', 'U', 'R', 'L') -- Bankrupt or Undischarged bankrupt, or Receivership or Liquidator (though R & L should not apply to individuals)
AND [ir_cus_entity_type_code] = 'I' -- individual
AND [ir_cus_applied_date] <= [ir_cus_ceased_date];
GO
