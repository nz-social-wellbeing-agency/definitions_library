/**************************************************************************************************
Title: Crude indication of drivers license
Author: Simon Anastasiadis

Inputs & Dependencies:
- [IDI_Clean].[nzta_clean].[drivers_licence_register]
  from refreshes: 20200120, 20191020, 20190420, 20181020, 20180720, 20180420, 20171020
Outputs:
- [IDI_Sandpit].[DL-MAA2016-15].[defn_end_of_month_location]

Description:
Crude indication of whether a person has an active/current driver's license

Intended purpose:
Identifying people with drivers licenses.
Counting number of people with drivers licenses.

Notes:
1) Drivers license history is not provided into the IDI. Only the most recent record
   / current status of each license at the time of data extraction is provided.
   Hence the only way to construct a history is to combine across refreshes.
2) As a result of (1), some changes in license status are unoberved. If a person is
   qualified, disqualified and requilified within a short time period then we may not
   observe the disqualification.
3) As a results of (1), final snz_uid must be constructed by joining refresh-invarient
   IDs [snz_nzta_uid] to the most recent refresh. This also means that this definition
   cannot be updated by simple find-and-replace.

Parameters & Present values:
  Current refresh = 20200120 BUT uses multiple refreshes
  Prefix = defn_
  Project schema = [DL-MAA2016-15]
   
Issues:

History (reverse order):
2020-05-20 SA v1
**************************************************************************************************/

/******************** Create full list ********************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_staging]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_staging];
GO

SELECT *
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_staging]
FROM (

-- 20200120 refresh
SELECT DISTINCT [snz_nzta_uid]
      ,[nzta_dlr_licence_issue_date]
      ,[nzta_dlr_licence_status_text]
      ,[nzta_dlr_licence_from_date]
FROM [IDI_Clean_20200120].[nzta_clean].[drivers_licence_register]

UNION ALL

-- 20191020 refresh
SELECT DISTINCT old.[snz_nzta_uid]
      ,old.[nzta_dlr_licence_issue_date]
      ,old.[nzta_dlr_licence_status_text]
      ,old.[nzta_dlr_licence_from_date]
FROM [IDI_Clean_20191020].[nzta_clean].[drivers_licence_register] old

UNION ALL

-- 20190420 refresh
SELECT DISTINCT old.[snz_nzta_uid]
      ,old.[nzta_dlr_licence_issue_date]
      ,old.[nzta_dlr_licence_status_text]
      ,old.[nzta_dlr_licence_from_date]
FROM [IDI_Clean_20190420].[nzta_clean].[drivers_licence_register] old

UNION ALL

-- 20181020 refresh
SELECT DISTINCT old.[snz_nzta_uid]
      ,old.[nzta_dlr_licence_issue_date]
      ,old.[nzta_dlr_licence_status_text]
      ,old.[nzta_dlr_licence_from_date]
FROM [IDI_Clean_20181020].[nzta_clean].[drivers_licence_register] old

UNION ALL

-- 20180720 refresh
SELECT DISTINCT old.[snz_nzta_uid]
      ,old.[nzta_dlr_licence_issue_date]
      ,old.[nzta_dlr_licence_status_text]
      ,old.[nzta_dlr_lic_class_start_date]
FROM [IDI_Clean_20180720].[nzta_clean].[drivers_licence_register] old

UNION ALL

-- 20180420 refresh
SELECT DISTINCT old.[snz_nzta_uid]
      ,old.[nzta_dlr_licence_issue_date]
      ,old.[nzta_dlr_licence_status_text]
      ,old.[nzta_dlr_lic_class_start_date]
FROM [IDI_Clean_20180420].[nzta_clean].[drivers_licence_register] old

UNION ALL

-- 20171020 refresh
SELECT DISTINCT old.[snz_nzta_uid]
      ,old.[nzta_dlr_licence_issue_date]
      ,old.[nzta_dlr_licence_status_text]
      ,old.[nzta_dlr_lic_class_start_date]
FROM [IDI_Clean_20171020].[nzta_clean].[drivers_licence_register] old
) k

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_staging] ([snz_nzta_uid]);
GO

/******************** Create tranlation ********************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_uid]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_uid];
GO

SELECT DISTINCT snz_uid, [snz_nzta_uid]
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_uid]
FROM [IDI_Clean_20200120].[nzta_clean].[drivers_licence_register]

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_uid] ([snz_nzta_uid]);
GO

/******************** Create final ********************/
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_drivers_license_w_history]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_drivers_license_w_history];
GO

SELECT new.snz_uid
	  ,old.[snz_nzta_uid]
	  ,old.[nzta_dlr_licence_issue_date]
      ,old.[nzta_dlr_licence_status_text]
      ,old.[nzta_dlr_licence_from_date]
	  ,old.next_date
INTO [IDI_Sandpit].[DL-MAA2016-15].[defn_drivers_license_w_history]
FROM (

	SELECT [snz_nzta_uid]
		  ,[nzta_dlr_licence_issue_date]
		  ,[nzta_dlr_licence_status_text]
		  ,[nzta_dlr_licence_from_date]
		  ,LEAD([nzta_dlr_licence_from_date], 1, '9999-01-01') OVER( PARTITION BY [snz_nzta_uid] ORDER BY [nzta_dlr_licence_from_date] ) AS next_date
	FROM [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_staging]

) old
INNER JOIN [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_uid] new
ON old.snz_nzta_uid = new.snz_nzta_uid
WHERE old.[nzta_dlr_licence_status_text] IN ('REQUALIFY', 'REINSTATE', 'CURRENT')
AND old.[nzta_dlr_licence_from_date] <> old.next_date

/* Add index */
CREATE CLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2016-15].[defn_drivers_license_w_history] ([snz_uid]);
GO
/* Compress final table to save space */
ALTER TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_drivers_license_w_history] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE);
GO

/* clear staging tables */
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_staging]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_staging];
GO
IF OBJECT_ID('[IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_uid]','U') IS NOT NULL
DROP TABLE [IDI_Sandpit].[DL-MAA2016-15].[defn_tmp_drivers_license_w_history_uid];
GO