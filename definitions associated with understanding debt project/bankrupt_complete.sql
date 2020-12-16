/**************************************************************************************************
Title: Bankrupt/insolvent
Author: Simon Anastasiadis
Reviewer: Marianna Pekar

Inputs & Dependencies:
- [IDI_Clean].[ir_clean].[ird_cross_reference]
Outputs:
- [IDI_UserCode].[DL-MAA2020-01].[d2g_bankruptcy]

Description:
People who have become insolvent / completed bankruptcy proceedings.

Intended purpose:
Identifying when/whether people become bankrupt or insolvent.
Indicator for have you ever been bankrupt.
  
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
3) This definition is for people who have been declared bankrupt. It produces similar numbers
   per year reported by the New Zealand Insovency and Trustee Service, the Official Assignee.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = d2g_
  Project schema = [DL-MAA2020-01]

Issues:
 
History (reverse order):
2020-07-16 MP QA
2020-03-02 SA v1
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

/* Clear view */
IF OBJECT_ID('[DL-MAA2020-01].[d2g_bankruptcy]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[d2g_bankruptcy];
GO

CREATE VIEW [DL-MAA2020-01].[d2g_bankruptcy] AS
SELECT [snz_uid]
	  ,ir_xrf_applied_date AS [event_date]
	  ,ir_xrf_applied_date AS [start_date]
	  ,ir_xrf_ceased_date AS [end_date] -- should be '9999-12-31' as issue of new IRD number is irrevesable
	  ,ir_xrf_reference_type_code -- for confirming BAN code
	  ,ir_xrf_ird_timestamp_date
FROM [IDI_Clean_20200120].[ir_clean].[ird_cross_reference]
WHERE ir_xrf_reference_type_code = 'BAN'
AND ir_xrf_applied_date <= ir_xrf_ceased_date;
GO