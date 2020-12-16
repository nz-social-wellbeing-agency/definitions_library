/**************************************************************************************************
Title: IRD income events
Author: V Benny

Inputs & Dependencies:
- [IDI_Clean].[data].[income_tax_yr]
- [IDI_Clean].[ir_clean].[ird_ems]
- [IDI_Clean].[wff_clean].[lvl_two_both_primary]
- [IDI_Clean].[sla_clean].[MSD_borrowing]
- [IDI_Clean].[sla_clean].[ird_amt_by_trn_type]
Outputs:
- [IDI_UserCode].[DL-MAA2016-15].[sial_IRD_income_events]

Description:
Create IRD income event table in SIAL format. The code fetches all known sources of taxable 
income AND deductions at the individual level, except for MSD T1 AND T2 related benefits (which can be
obtained FROM the respective SIAL tables). This table also has the income tax component AND Student 
loan related income, deductions AND student allowances, pensions.

Notes:
0) This definition originates in the SIAL. The SIAL was retired mid-2020
   and is no longer supported. This definition has been provided for
   researchers wanting to contiune to use this SIAL definition.
1) See SIAL data dictionary for original documentation of business rules.
2) This is a very processing intensive piece of code, AND takes around 5 minutes
   to start fetching rows.
3) Keep in mind that this query retrieves a huge number of rows, in the order of
   billions. Judicious use of this query is strongly recommended.

Parameters & Present values:
  Current refresh = 20200120
  Prefix = sial_
  Project schema = [DL-MAA2016-15]

Issues:

History (reverse order):
2020-08-04 Simon A: recode into SQL
2019-08-01 Peter Holmes: Added a SELECT statement to ensure the user has access to the underlying IDI tables. This will show up in the log
2019-06-01 Peter Holmes: Views how have to be created in the IDI_UserCode schema in the IDI
2018-04-13 Vinay Benny: Removed the absolute value around cost column for income_tax_yr table. This accounts for negative values for S00 AND P00.
2017-07-08 Vinay Benny: V2 Re-adapted based on Marc De Boer's SAS code for income dataset creation for better detail
2016-10-01 Vinay Benny: First version based on data.income_cal_yr
**************************************************************************************************/

/* Establish database for writing views */
USE IDI_UserCode
GO

IF OBJECT_ID('[DL-MAA2016-15].[sial_IRD_income_events]','V') IS NOT NULL
DROP VIEW [DL-MAA2016-15].[sial_IRD_income_events];
GO

CREATE VIEW [DL-MAA2016-15].[SIAL_IRD_income_events] AS 
/* Income for individuals over each year FROM the income_tax_yr summary table*/
SELECT 
	unpvt.snz_uid, 
	'IRD' AS department, 
	CASE WHEN inc_tax_yr_income_source_code in ('C00', 'P00', 'S00', 'C01','P01','S01', 'C02','P02', 'S02', 'PPL', 'WAS', 'WHP') THEN 'EMP' /*Employment income for individual*/
		WHEN inc_tax_yr_income_source_code in ('BEN', 'CLM', 'PEN') THEN 'INS' /* Income Support benefits that individual receives FROM Govt. (excl. MSD T2 AND T3)*/
		WHEN inc_tax_yr_income_source_code = 'STU' THEN 'STS' /* Student support allowances*/
		WHEN inc_tax_yr_income_source_code = 'S03' THEN 'RNT' /* Rental Income*/
		ELSE 'UNK' END AS datamart, /* If none of the above codes, THEN use Unknown*/
	inc_tax_yr_income_source_code AS subject_area, 
	/* Start of month is calculated FROM the column name- if month is Jan, Feb or March, THEN the year should be the current year, ELSE previous year (since tax-year ranges FROM April to March)*/
	CAST(datefromparts( (CASE WHEN CAST(right(monthval, 2) AS integer) > 3 THEN inc_tax_yr_year_nbr - 1 ELSE inc_tax_yr_year_nbr END ), 
							CAST(right(monthval, 2) AS integer), 1) AS DATETIME) AS [start_date],
	CAST(eomonth(datefromparts( (CASE WHEN CAST(right(monthval, 2) AS integer) > 3 THEN inc_tax_yr_year_nbr - 1 ELSE inc_tax_yr_year_nbr END ), 
							CAST(right(monthval, 2) AS integer), 1) ) AS DATETIME) AS end_date, /* End of month calculated FROM column name*/
	unpvt.cost AS cost,
	'Net Income' AS event_type
from
(
	SELECT 
		snz_uid, 
		CASE WHEN inc_tax_yr_income_source_code='W&S' THEN 'WAS' ELSE inc_tax_yr_income_source_code END AS inc_tax_yr_income_source_code, 
		inc_tax_yr_year_nbr, 
		/* In CASE of Sole trader income(IR3), Partnership income (IR20), Shareholder income(IR4S) AND Rental income(IR3), divide it equally among all months of the financial year*/
		SUM(CASE WHEN inc_tax_yr_income_source_code in ('S00','P00','C00','S03') THEN inc_tax_yr_tot_yr_amt/12.0 ELSE  coalesce(inc_tax_yr_mth_01_amt, 0.00) end) AS mth_04,
		SUM(CASE WHEN inc_tax_yr_income_source_code in ('S00','P00','C00','S03') THEN inc_tax_yr_tot_yr_amt/12.0 ELSE  coalesce(inc_tax_yr_mth_02_amt, 0.00) end) AS mth_05,
		SUM(CASE WHEN inc_tax_yr_income_source_code in ('S00','P00','C00','S03') THEN inc_tax_yr_tot_yr_amt/12.0 ELSE  coalesce(inc_tax_yr_mth_03_amt, 0.00) end) AS mth_06,
		SUM(CASE WHEN inc_tax_yr_income_source_code in ('S00','P00','C00','S03') THEN inc_tax_yr_tot_yr_amt/12.0 ELSE  coalesce(inc_tax_yr_mth_04_amt, 0.00) end) AS mth_07,
		SUM(CASE WHEN inc_tax_yr_income_source_code in ('S00','P00','C00','S03') THEN inc_tax_yr_tot_yr_amt/12.0 ELSE  coalesce(inc_tax_yr_mth_05_amt, 0.00) end) AS mth_08,
		SUM(CASE WHEN inc_tax_yr_income_source_code in ('S00','P00','C00','S03') THEN inc_tax_yr_tot_yr_amt/12.0 ELSE  coalesce(inc_tax_yr_mth_06_amt, 0.00) end) AS mth_09,
		SUM(CASE WHEN inc_tax_yr_income_source_code in ('S00','P00','C00','S03') THEN inc_tax_yr_tot_yr_amt/12.0 ELSE  coalesce(inc_tax_yr_mth_07_amt, 0.00) end) AS mth_10,
		SUM(CASE WHEN inc_tax_yr_income_source_code in ('S00','P00','C00','S03') THEN inc_tax_yr_tot_yr_amt/12.0 ELSE  coalesce(inc_tax_yr_mth_08_amt, 0.00) end) AS mth_11,
		SUM(CASE WHEN inc_tax_yr_income_source_code in ('S00','P00','C00','S03') THEN inc_tax_yr_tot_yr_amt/12.0 ELSE  coalesce(inc_tax_yr_mth_09_amt, 0.00) end) AS mth_12,
		SUM(CASE WHEN inc_tax_yr_income_source_code in ('S00','P00','C00','S03') THEN inc_tax_yr_tot_yr_amt/12.0 ELSE  coalesce(inc_tax_yr_mth_10_amt, 0.00) end) AS mth_01,
		SUM(CASE WHEN inc_tax_yr_income_source_code in ('S00','P00','C00','S03') THEN inc_tax_yr_tot_yr_amt/12.0 ELSE  coalesce(inc_tax_yr_mth_11_amt, 0.00) end) AS mth_02,
		SUM(CASE WHEN inc_tax_yr_income_source_code in ('S00','P00','C00','S03') THEN inc_tax_yr_tot_yr_amt/12.0 ELSE  coalesce(inc_tax_yr_mth_12_amt, 0.00) end) AS mth_03
	FROM [IDI_Clean_20200120].data.income_tax_yr 
	GROUP BY snz_uid, inc_tax_yr_income_source_code, inc_tax_yr_year_nbr
) pvt
unpivot
(cost FOR monthval IN (mth_04, mth_05, mth_06, mth_07, mth_08, mth_09, mth_10, mth_11, mth_12, mth_01, mth_02, mth_03)
) AS unpvt

UNION ALL

/* Monthly deductions FROM income (as Income tax AND student loan deductions) AS part of Income tax AND student loans, FROM the ird_ems table.
	Note that the amounts are in negative values */
SELECT snz_uid
	,'IRD' AS department
	,CASE ir_ems_withholding_type_code WHEN 'P' THEN 'PYE' ELSE 'WHT' END AS datamart /*PYE is for PAYE deductions AND WHT is withheld deductions*/
	,CASE WHEN ir_ems_income_source_code = 'W&S' THEN 'WAS' ELSE ir_ems_income_source_code END AS subject_area
	,CAST(DATEFROMPARTS(YEAR(ir_ems_return_period_date), MONTH(ir_ems_return_period_date), 1) AS DATETIME) AS start_date
	,CAST(eomonth(datefromparts(year(ir_ems_return_period_date), month(ir_ems_return_period_date), 1)) AS DATETIME) AS end_date
	,SUM(ir_ems_paye_deductions_amt) AS cost
	,'Income Tax' AS event_type
FROM [IDI_Clean_20200120].ir_clean.ird_ems
WHERE ir_ems_paye_deductions_amt IS NOT NULL AND ir_ems_paye_deductions_amt  <> 0
GROUP BY snz_uid, ir_ems_income_source_code, YEAR(ir_ems_return_period_date), MONTH(ir_ems_return_period_date), ir_ems_withholding_type_code

UNION All

SELECT snz_uid,
	'IRD' AS department, 
	'STL' AS datamart, /* Student Loan*/
	'SLD' AS subject_area, /* Student loan deduction*/
	CAST(datefromparts(year(ir_ems_return_period_date), month(ir_ems_return_period_date), 1) AS DATETIME) AS start_date,
	CAST(eomonth(datefromparts(year(ir_ems_return_period_date), month(ir_ems_return_period_date), 1)) AS DATETIME) AS end_date,
	SUM(ir_ems_sl_amt) AS cost,
	'Deduction' AS event_type
FROM [IDI_Clean_20200120].ir_clean.ird_ems
WHERE ir_ems_sl_amt IS NOT NULL
AND ir_ems_sl_amt <> 0 
AND YEAR(ir_ems_return_period_date) < 2012 /* Only fetch data until 2012, as the student loan deductions information from 2012 onwards come from sla_clean.ird_amt_by_trn_type table*/
GROUP BY snz_uid, YEAR(ir_ems_return_period_date), MONTH(ir_ems_return_period_date)


UNION ALL

/* Working for Families tax credits returned to the individual*/
SELECT snz_uid
	,'IRD' AS department
	,'INS' AS datamart /*WFF tax credits are Income support payments*/
	,subject_area
	,CAST(month_sd AS DATETIME) AS start_date
	,CAST(eomonth(month_sd) AS DATETIME) AS end_date
	,SUM(amount) AS cost
	,'Net Income' AS event_type
FROM (
	SELECT snz_uid,
		'FTCb' AS subject_area, /* tax credits FROM benefits, given by MSD */
		DATEFROMPARTS(YEAR(wff_lbp_date), MONTH(wff_lbp_date), 1) AS month_sd,
		/* If there is a partner availing the tax credit, divide the amount equally between both partners*/
		CASE WHEN partner_snz_uid IS NULL THEN wff_lbp_msd_fam_tax_credit_amt ELSE wff_lbp_msd_fam_tax_credit_amt/2.0 END AS amount
	FROM [IDI_Clean_20200120].wff_clean.lvl_two_both_primary
	WHERE wff_lbp_msd_fam_tax_credit_amt > 0
	
	UNION ALL
	
	SELECT snz_uid,
		'FTCn' AS subject_area, /* tax credits FROM non-benefit income, given by IRD*/
		DATEFROMPARTS(YEAR(wff_lbp_date), MONTH(wff_lbp_date), 1) AS month_sd,
		/* If there is a partner availing the tax credit, divide the amount equally between both partners*/
		CASE WHEN partner_snz_uid IS NULL THEN wff_lbp_ird_fam_tax_credit_amt ELSE wff_lbp_ird_fam_tax_credit_amt/2.0 END AS amount
	FROM [IDI_Clean_20200120].wff_clean.lvl_two_both_primary
	WHERE wff_lbp_ird_fam_tax_credit_amt > 0
	
	UNION ALL
	
	/* Tax credits for partners*/
	SELECT partner_snz_uid AS snz_uid,
		'FTCb' AS subject_area, /* tax credits FROM benefits, given by MSD */
		DATEFROMPARTS(YEAR(wff_lbp_date), MONTH(wff_lbp_date), 1) AS month_sd,
		wff_lbp_msd_fam_tax_credit_amt/2.0 AS amount
	FROM [IDI_Clean_20200120].wff_clean.lvl_two_both_primary
	WHERE wff_lbp_msd_fam_tax_credit_amt > 0 AND partner_snz_uid > 0
	
	UNION ALL
	
	SELECT partner_snz_uid AS snz_uid,
		'FTCn' AS subject_area, /* tax credits FROM non-benefit income, given by IRD*/
		DATEFROMPARTS(YEAR(wff_lbp_date), MONTH(wff_lbp_date), 1) AS month_sd,
		wff_lbp_ird_fam_tax_credit_amt/2.0 AS amount
	FROM [IDI_Clean_20200120].wff_clean.lvl_two_both_primary
	WHERE wff_lbp_ird_fam_tax_credit_amt > 0 AND partner_snz_uid > 0
)x
GROUP BY snz_uid, subject_area, month_sd


UNION ALL

/* Student Loans data- use only until 01 January 2012 becuase monthly data is available FROM this point onwards in the ird_amt_by_trn_type table */
SELECT snz_uid
	,'IRD' AS department
	,'STL' AS datamart
	,'SLA' AS subject_area /* Student Loan lending*/
    ,CAST(msd_sla_sl_study_start_date AS DATETIME) AS start_date
    ,CAST(msd_sla_sl_study_end_date AS DATETIME) AS end_date
	,msd_sla_ann_drawn_course_rel_amt AS cost
	,'Advance' AS event_type
FROM [IDI_Clean_20200120].sla_clean.MSD_borrowing
WHERE msd_sla_ann_drawn_course_rel_amt <> 0 
AND msd_sla_ann_drawn_course_rel_amt IS NOT NULL
AND msd_sla_year_nbr < 2012

UNION ALL

SELECT snz_uid
	,'IRD' AS department
	,'STL' AS datamart
	,'SLA' AS subject_area /* Student Loan lending*/
    ,msd_sla_sl_study_start_date AS start_date
    ,msd_sla_sl_study_end_date AS end_date
	,msd_sla_ann_drawn_living_cost_amt AS cost
	,'Advance' AS event_type
FROM [IDI_Clean_20200120].sla_clean.MSD_borrowing 
WHERE msd_sla_ann_drawn_living_cost_amt <> 0 
AND msd_sla_ann_drawn_living_cost_amt IS NOT NULL
AND msd_sla_year_nbr < 2012

UNION ALL

SELECT snz_uid
	,'IRD' AS department
	,'STL' AS datamart
	,'SLF' AS subject_area /* Student Loan Deductions- fees penalties*/
    ,msd_sla_sl_study_start_date AS start_date
    ,msd_sla_sl_study_end_date AS end_date
	,COALESCE(msd_sla_ann_fee_refund_amt, 0.00) + COALESCE(msd_sla_ann_admin_fee_amt, 0.00) AS cost
	,'Deduction' AS event_type
FROM [IDI_Clean_20200120].[sla_clean].[MSD_borrowing]
WHERE COALESCE(msd_sla_ann_fee_refund_amt, 0.00) + COALESCE(msd_sla_ann_admin_fee_amt, 0.00) <> 0
AND msd_sla_year_nbr < 2012

UNION ALL

SELECT snz_uid
	,'IRD' AS department
	,'STL' AS datamart
	,'SLD' AS subject_area /* Student Loan deductions*/
    ,msd_sla_sl_study_start_date AS start_date
    ,msd_sla_sl_study_end_date AS end_date
	,msd_sla_ann_repayment_amt AS cost
	,'Deduction' AS event_type
FROM [IDI_Clean_20200120].[sla_clean].[MSD_borrowing]
WHERE msd_sla_ann_repayment_amt <> 0
AND msd_sla_ann_repayment_amt IS NOT NULL
AND msd_sla_year_nbr < 2012

UNION ALL

/* Monthly Student Loan transactions. This data exists FROM 01 Jan 2012 to now.*/
SELECT snz_uid
	,'IRD' AS department
	,'STL' AS datamart
	,CASE WHEN ir_att_trn_type_code = 'L' THEN 'SLA'  /* Student Loan lending*/
		WHEN ir_att_trn_type_code in ('G', 'I', 'J', 'P', 'Q') THEN 'SLF' /* Student Loan Deductions- fees penalties */
		WHEN ir_att_trn_type_code in ('R', 'W') THEN 'SLD' /* Student Loan Deductions - repayments & write-offs */
		ELSE ir_att_trn_type_code END AS subject_area
	,CAST(ir_att_trn_month_date AS DATETIME) AS start_date
	,CAST(eomonth(ir_att_trn_month_date) AS DATETIME) AS end_date
	,ir_att_trn_type_amt  AS cost
	,CASE WHEN ir_att_trn_type_code = 'L' THEN 'SLA'
		WHEN ir_att_trn_type_code in ('G', 'I', 'J', 'P', 'Q') THEN 'SLF'
		WHEN ir_att_trn_type_code in ('R', 'W') THEN 'SLD' 
		ELSE ir_att_trn_type_code END AS event_type
FROM [IDI_Clean_20200120].[sla_clean].[ird_amt_by_trn_type];
GO
