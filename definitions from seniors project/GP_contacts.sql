/**************************************************************************************************
Title: GP Contacts
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[acc_clean].[payments]
- [IDI_Clean].[acc_clean].[claims]
- [IDI_Clean].[moh_clean].[lab_claims]
- [IDI_Clean].[moh_clean].[pub_fund_hosp_discharges_event]
- [IDI_Clean].[moh_clean].[nnpac]
- [IDI_Clean].[moh_clean].[nes_enrolment]
- [IDI_Clean].[moh_clean].[pop_cohort_demographics]
- [IDI_Clean].[moh_clean].[pho_enrolment]
- [IDI_Clean].[moh_clean].[gms_claims]
Outputs:
- [IDI_Sandpit].[DL-MAA2018-48].[defn_GP_contacts]

Description:
GP visit proxy indicator
The General Practice contacts indicator is a proxy indicator of frequency
of GP contact at the individual level by date of visit.

Intended purpose:
Estimate primary care consults for each snz_uid by date.

Notes:
1) The indicator relies primarily on this:
	- The PHO quarterly reporting of last date of GP contact (up to four visits a year).
	- The General Medical Subsidy (GMS) claims for all primary care contacts outside of
		when a person is enrolled GP (all visits).
	- ACC funded primary care contacts.
	It also relies on laboratory test data and the date of visit that initiated the test request.
	Approximately 20% of lab tests are requested in the secondary care setting to this is likely
	to drive a slight over count in estimates.
2) Being based on quarterly PHO contacts and GMS events we expect the indicator to be accurate for
	people having primary care outside their PHO and people visiting the GP up to four times a year.
	Inclusion of ACC and lab tests likely improves the quality for people with more than four visits
	in a year. While the indicator will be accurate for most people, a small group will have more
	visits than the indicator suggests.
3) Comparisons of population total annual volumes of GP visits collected by the MOH from PHOs
	compare favourably to the indicator, within a few percent. Total volume comparisons by age,
	gender, and ethnic group are also similar but differ by about 5-10%.
4) We exclude multiple events on the same day, but for some people these are likely to exist.
5) Final table: Dec 2014-Jan 2021.
6) In the 20210720 refresh the data is complete from 2014-2018, partial for 2019-2020 (80-90%)
	and has very little for 2021 except for January.
7) Using Lab visits presents a challenge. ~20% of labs data is from hospitals and not GP visits.
	There is no indicator to identify this. Our approach is to drop lab visits on days where the
	snz_uid is in hospital or a non-admitted patient (NAP). This reduced lab tests by ~3.5%
	Investigation suggested that lab tests reported the day after a hospital visit behave similarly
	to lab tests during a hospital visit, hence these were also excluded. This increased the
	reduction in lab tests from ~3.5% to ~5.5%
8) Results are consistent with expectations that ~81% of the population have 1 or more contacts
	with their GP each year.
9) A small proportion of people will have multiple visits to a GP on the same day. For some datasets
	this can be observed via duplicate records. But this can not be reliably detected across datasets.
	We have not attempted to capture multiple visits on the same day.
10) The lab tests data includes provider codes. This should include the ID of the referring entity.
	This definition might be further refined by investigation & use of these codes.
	For example, if we observe providers whose lab tests never coincide with ACC, GMS, or GP enrolments,
	then this would suggest these providers are operating in a different function from GPs.

Parameters & Present values:
  Current refresh = 202203
  Prefix = vacc_
  Project schema = DL-MAA2018-48
 
Issues:

History (reverse order):
2022-06-01 VW Point to DL-MAA2018-48, update to latest refresh, remove vaccination summary view
2021-11-29 SA review and tidy
2021-10-31 CW
**************************************************************************************************/

/* create table of all possible contacts */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[tmp_GP_contacts_list]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2018-48].[tmp_GP_contacts_list] (
	snz_uid INT,
	visit_date DATE,
);
GO

/********************************************************
ACC GP visits 
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_GP_contacts_list] (snz_uid, visit_date)
SELECT DISTINCT b.[snz_uid]
	,[acc_pay_first_service_date] AS visit_date
FROM [IDI_Clean_202203].[acc_clean].[payments] AS a
INNER JOIN [IDI_Clean_202203].[acc_clean].[claims] AS b
ON a.[snz_acc_claim_uid] = b.[snz_acc_claim_uid]
WHERE [acc_pay_gl_account_text] = 'GENERAL PRACTITIONERS' 
AND [acc_pay_focus_group_text] = 'MEDICAL TREATMENT' 
AND [acc_pay_first_service_date] = [acc_pay_last_service_date] --ensure a single visit on same day
GO

/********************************************************
Labs
********************************************************/

WITH adding_hospital_indicators_to_lab_tests AS (

SELECT DISTINCT c.[snz_uid]
	,[moh_lab_visit_date] AS visit_date
	,IIF(b.snz_uid IS NOT NULL, 1, 0) AS public_hospital_discharge
	,IIF(n.snz_uid IS NOT NULL, 1, 0) AS non_admitted_patient
	,IIF(b.snz_uid IS NOT NULL OR n.snz_uid IS NOT NULL, 1, 0) AS hospital

	,IIF(c.[moh_lab_visit_date] = DATEADD(DAY, 1, b.[moh_evt_even_date]), 1, 0) AS public_hospital_discharge_extra
	,IIF(c.[moh_lab_visit_date] = DATEADD(DAY, 1, n.[moh_nnp_service_date]), 1, 0) AS non_admitted_patient_extra
FROM [IDI_Clean_202203].[moh_clean].[lab_claims] AS c
LEFT JOIN [IDI_Clean_202203].[moh_clean].[pub_fund_hosp_discharges_event] AS b 
ON c.snz_uid = b.snz_uid
AND c.[moh_lab_visit_date] BETWEEN b.[moh_evt_evst_date] AND DATEADD(DAY, 1, b.[moh_evt_even_date]) -- include one day later
LEFT JOIN [IDI_Clean_202203].[moh_clean].[nnpac] AS n 
ON c.snz_uid = n.snz_uid
AND c.[moh_lab_visit_date] BETWEEN n.[moh_nnp_service_date] AND DATEADD(DAY, 1, n.[moh_nnp_service_date]) -- include one day later
WHERE YEAR([moh_lab_visit_date]) BETWEEN 2014 AND 2021

)
INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_GP_contacts_list] (snz_uid, visit_date)
SELECT snz_uid
	,visit_date
FROM adding_hospital_indicators_to_lab_tests
GO

/********************************************************
NES - contact events for the National enrolment service data
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_GP_contacts_list] (snz_uid, visit_date)
SELECT DISTINCT b.snz_uid
	,[moh_nes_last_consult_date] AS visit_date
FROM [IDI_Clean_202203].[moh_clean].[nes_enrolment] AS a
LEFT JOIN [IDI_Clean_202203].[moh_clean].[pop_cohort_demographics] AS b
ON a.snz_moh_uid = b.snz_moh_uid
WHERE YEAR([moh_nes_last_consult_date]) IN (2014,2015,2016,2017,2018,2019,2020,2021)
GO

/********************************************************
PHO - contact events for the PHO enrolment service data
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_GP_contacts_list] (snz_uid, visit_date)
SELECT DISTINCT [snz_uid]
	,[moh_pho_last_consul_date] AS visit_date
FROM [IDI_Clean_202203].[moh_clean].[pho_enrolment]
WHERE YEAR([moh_pho_last_consul_date]) IN (2014,2015,2016,2017,2018,2019,2020,2021)
GO

/********************************************************
GMS - contact events for GP visits outside of PHO enrolment
********************************************************/

INSERT INTO [IDI_Sandpit].[DL-MAA2018-48].[tmp_GP_contacts_list] (snz_uid, visit_date)
SELECT [snz_uid] --not distinct as all discrete events
	,[moh_gms_visit_date] AS visit_date
FROM [IDI_Clean_202203].[moh_clean].[gms_claims]
WHERE YEAR([moh_gms_visit_date]) IN (2014,2015,2016,2017,2018,2019,2020,2021)
GO

/********************************************************
Combine
********************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[defn_GP_contacts]
GO

SELECT DISTINCT snz_uid
	,visit_date
INTO [IDI_Sandpit].[DL-MAA2018-48].[defn_GP_contacts]
FROM [IDI_Sandpit].[DL-MAA2018-48].[tmp_GP_contacts_list]
WHERE snz_uid IS NOT NULL
AND visit_date IS NOT NULL
AND YEAR(visit_date) >= 2014
AND YEAR(visit_date) <= 2021
GO

CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2018-48].[defn_GP_contacts] (snz_uid)
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA2018-48].[defn_GP_contacts] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO

/********************************************************
Tidy
********************************************************/

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2018-48].[tmp_GP_contacts_list]
GO
