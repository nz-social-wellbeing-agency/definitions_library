/**************************************************************************************************
Title: Debt to MOJ Phase 2
Author: Freya Li and Simon Anastasiadis

Inputs & Dependencies:
- "debt_to_moj_p2rs.sql" --> [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_transactions_ready]
- "debt_to_moj_fcco_p2rs.sql" --> [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_fcco_transactions_ready]
Outputs:
- [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_all_moj_transactions_ready]
- [IDI_UserCode].[DL-MAA2020-01].[moj_labels_balance]
- [IDI_UserCode].[DL-MAA2020-01].[moj_labels_transactions]
- [IDI_UserCode].[DL-MAA2020-01].[moj_labels_repayments]
- [IDI_UserCode].[DL-MAA2020-01].[moj_labels_persist]

Description: 
Debt, debt balances, and repayment for debtors owing money to MOJ.

Intended purpose:
Identifying debtors.
Calculating number of debtors and total value of debts.
Calculating change in debts - due to borrowing or repayment.

Notes:
 1. See all notes in the construction scripts.
	This main purpose of this file to create all views needed as input to the
	assembly tool in a single place.

Issue:
 1. See all issues in the input construction scripts.

Parameters & Present values:
  Current refresh = 20201020
  Prefix = d2gP2_
  Project schema = [DL-MAA2020-01]

History (reverse order):
2021-10-04 SA separate file
2021-08-13 FL record as part of debt_to_moj_p2rs.sql
**************************************************************************************************/

USE IDI_UserCode
GO

/**************************************************************************************************
Combine MoJ fine and FCCO data
**************************************************************************************************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_both_transactions_ready]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_both_transactions_ready];
GO

SELECT snz_uid
      ,'Fine' AS debt_type
	  ,month_date 
	  ,ROUND(impositions, 2) AS principle
	  ,ROUND(penalty, 2) AS penalty
	  ,ROUND(-payment, 2) AS payment
	  ,ROUND(-remittals, 2) AS write_offs
	  ,ROUND(COALESCE(payment_reversal, 0) + COALESCE(remittal_reversal, 0), 2) AS reversal
	  ,ROUND(balance_correct, 2) AS outstanding_balance
	  ,ROUND(delta, 2) AS delta
INTO [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_both_transactions_ready]
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_transactions_ready]
WHERE snz_uid IS NOT NULL
AND month_date <= '2020-09-30'

UNION ALL

SELECT snz_uid
       ,'FCCO' AS debt_type
	   ,month_date
	   ,ROUND(new_debt_established, 2) AS principle
	   ,NULL AS penalty
	   ,ROUND(repayments, 2) AS payment
	   ,ROUND(write_offs, 2) AS write_offs
	   ,NULL AS reversals
	   ,ROUND(balance_correct, 2) AS outstanding_balance
	   ,ROUND(delta, 2) AS delta
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_fcco_transactions_ready]
WHERE snz_uid IS NOT NULL
AND month_date <= '2020-09-30'

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_both_transactions_ready] (snz_uid);
GO

/**************************************************************************************************
Views for balance labels
**************************************************************************************************/
IF OBJECT_ID('[DL-MAA2020-01].[moj_labels_balance]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[moj_labels_balance];
GO

CREATE VIEW [DL-MAA2020-01].[moj_labels_balance] AS
SELECT snz_uid
      ,month_date
	  ,outstanding_balance
	  /* balance labels */
	  ,CONCAT('moj_Y', YEAR(month_date), 'M', MONTH(month_date), '_', debt_type) AS balance_label 
	  ,CONCAT('moj_Y', YEAR(month_date), 'M', MONTH(month_date)) AS balance_label_all_types
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_both_transactions_ready]
WHERE month_date BETWEEN '2019-01-01' AND '2020-09-30'
GO

/**************************************************************************************************
Views for transaction labels
**************************************************************************************************/
IF OBJECT_ID('[DL-MAA2020-01].[moj_labels_pre2019]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[moj_labels_pre2019];
GO                   

CREATE VIEW [DL-MAA2020-01].[moj_labels_pre2019] AS
SELECT snz_uid 
      ,DATEADD(MONTH, 1, month_date) AS month_date
	  ,debt_type
	  ,outstanding_balance
	  /*pre_2019*/
	  ,CONCAT('moj_', 'pre_2019', '_', debt_type) AS transaction_labels_pre_2019_by_type
	  ,CONCAT('moj_', 'pre_2019') AS transaction_labels_pre_2019_all_types
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_both_transactions_ready]
WHERE month_date BETWEEN '2018-12-01' AND '2018-12-31'
GO

/**************************************************************************************************
Views for transaction labels
**************************************************************************************************/
IF OBJECT_ID('[DL-MAA2020-01].[moj_labels_transactions]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[moj_labels_transactions];
GO                   

CREATE VIEW [DL-MAA2020-01].[moj_labels_transactions] AS
SELECT snz_uid 
      ,month_date
	  ,debt_type
	  ,principle
	  ,penalty
	  ,payment
	  ,write_offs
	  ,reversal
	  /*principle*/
	  ,CONCAT('moj_', 'principle', '_', YEAR(month_date), debt_type) AS transaction_labels_principle_by_type
	  ,CONCAT('moj_', 'principle', '_', YEAR(month_date)) AS transaction_labels_principle_all_types
	  /* penalty */
	  ,CONCAT('moj_', 'penalty', '_', YEAR(month_date), '_', debt_type) AS transaction_labels_penalty_by_type
	  ,CONCAT('moj_', 'penalty', '_', YEAR(month_date)) AS transaction_labels_penalty_all_types
	  /* payment */
	  ,CONCAT('moj_', 'payment', '_', YEAR(month_date), '_', debt_type) AS transaction_labels_payment_by_type
	  ,CONCAT('moj_', 'payment', '_', YEAR(month_date)) AS transaction_labels_payment_all_types
	  /* write_offs */
	  ,CONCAT('moj_', 'write_offs', '_', YEAR(month_date), '_', debt_type) AS transaction_labels_write_offs_by_type
	  ,CONCAT('moj_', 'write_offs', '_', YEAR(month_date)) AS transaction_labels_write_offs_all_types
	  /* reversal */
	  ,CONCAT('moj_', 'reversal', '_', YEAR(month_date), '_', debt_type) AS transaction_labels_reversal_by_type
	  ,CONCAT('moj_', 'reversal', '_', YEAR(month_date)) AS transaction_labels_reversal_all_types
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_both_transactions_ready]
WHERE month_date BETWEEN '2019-01-01' AND '2020-09-30'
GO

/**************************************************************************************************
Views for repayments
**************************************************************************************************/

IF OBJECT_ID('[DL-MAA2020-01].[moj_labels_repayments]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[moj_labels_repayments];
GO

CREATE VIEW [DL-MAA2020-01].[moj_labels_repayments] AS

SELECT snz_uid
	,month_date
	,debt_type
	,payment
	/* repayment labels by type */
	,IIF(month_date BETWEEN '2020-07-01' AND '2020-09-30', CONCAT('moj_payment_03mth_', debt_type), NULL) AS payment_label_by_type_03
	,IIF(month_date BETWEEN '2020-04-01' AND '2020-09-30', CONCAT('moj_payment_06mth_', debt_type), NULL) AS payment_label_by_type_06
	,IIF(month_date BETWEEN '2020-01-01' AND '2020-09-30', CONCAT('moj_payment_09mth_', debt_type), NULL) AS payment_label_by_type_09
	,IIF(month_date BETWEEN '2019-10-01' AND '2020-09-30', CONCAT('moj_payment_12mth_', debt_type), NULL) AS payment_label_by_type_12
	/* repayment labels all types */
	,IIF(month_date BETWEEN '2020-07-01' AND '2020-09-30', 'moj_payment_03mth', NULL) AS payment_label_all_types_03
	,IIF(month_date BETWEEN '2020-04-01' AND '2020-09-30', 'moj_payment_06mth', NULL) AS payment_label_all_types_06
	,IIF(month_date BETWEEN '2020-01-01' AND '2020-09-30', 'moj_payment_09mth', NULL) AS payment_label_all_types_09
	,IIF(month_date BETWEEN '2019-10-01' AND '2020-09-30', 'moj_payment_12mth', NULL) AS payment_label_all_types_12
FROM [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_both_transactions_ready]
WHERE payment < -1
AND month_date BETWEEN '2019-10-01' AND '2020-09-30'
GO

/**************************************************************************************************
Views for persistence

To determine whether a person has persistent debt we count the number of distinct dates where
the label is non-null during assembly. After assembly, we create the indicator by checking
whether moj_persistence_XXmth = XX.
- If moj_persistence_XXmth = XX then in the last XX months there were XX months where the person
  had debt hence they had debt in every month.
- If moj_persistence_XXmth < XX then in the last XX months there were some months where the person
  did not have debt.
**************************************************************************************************/
IF OBJECT_ID('[DL-MAA2020-01].[moj_labels_persist]','V') IS NOT NULL
DROP VIEW [DL-MAA2020-01].[moj_labels_persist];
GO

CREATE VIEW [DL-MAA2020-01].[moj_labels_persist] AS
SELECT snz_uid
	,month_date
	,debt_type
	,outstanding_balance
	/* persistence labels by type */
	,IIF(month_date BETWEEN '2020-07-01' AND '2020-09-30', CONCAT('moj_persistence_03mth_', debt_type), NULL) AS persistence_label_by_type_03
	,IIF(month_date BETWEEN '2020-04-01' AND '2020-09-30', CONCAT('moj_persistence_06mth_', debt_type), NULL) AS persistence_label_by_type_06
	,IIF(month_date BETWEEN '2020-01-01' AND '2020-09-30', CONCAT('moj_persistence_09mth_', debt_type), NULL) AS persistence_label_by_type_09
	,IIF(month_date BETWEEN '2019-10-01' AND '2020-09-30', CONCAT('moj_persistence_12mth_', debt_type), NULL) AS persistence_label_by_type_12
	,IIF(month_date BETWEEN '2019-07-01' AND '2020-09-30', CONCAT('moj_persistence_15mth_', debt_type), NULL) AS persistence_label_by_type_15
	,IIF(month_date BETWEEN '2019-04-01' AND '2020-09-30', CONCAT('moj_persistence_18mth_', debt_type), NULL) AS persistence_label_by_type_18
	,IIF(month_date BETWEEN '2019-01-01' AND '2020-09-30', CONCAT('moj_persistence_21mth_', debt_type), NULL) AS persistence_label_by_type_21
	/* persistence labels all types */
	,IIF(month_date BETWEEN '2020-07-01' AND '2020-09-30', 'moj_persistence_03mth', NULL) AS persistence_label_all_types_03
	,IIF(month_date BETWEEN '2020-04-01' AND '2020-09-30', 'moj_persistence_06mth', NULL) AS persistence_label_all_types_06
	,IIF(month_date BETWEEN '2020-01-01' AND '2020-09-30', 'moj_persistence_09mth', NULL) AS persistence_label_all_types_09
	,IIF(month_date BETWEEN '2019-10-01' AND '2020-09-30', 'moj_persistence_12mth', NULL) AS persistence_label_all_types_12
	,IIF(month_date BETWEEN '2019-07-01' AND '2020-09-30', 'moj_persistence_15mth', NULL) AS persistence_label_all_types_15
	,IIF(month_date BETWEEN '2019-04-01' AND '2020-09-30', 'moj_persistence_18mth', NULL) AS persistence_label_all_types_18
	,IIF(month_date BETWEEN '2019-01-01' AND '2020-09-30', 'moj_persistence_21mth', NULL) AS persistence_label_all_types_21
FROM  [IDI_Sandpit].[DL-MAA2020-01].[d2gP2_moj_both_transactions_ready]
WHERE outstanding_balance IS NOT NULL
AND outstanding_balance > 0
AND month_date BETWEEN '2019-01-01' AND '2020-09-30'
GO
