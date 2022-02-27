/**************************************************************************************************
Title: Country of Birth
Author: Craig Wright

Acknowledgements:
Informatics for Social Services and Wellbeing (terourou.org) supported the publishing of these definitions

Inputs & Dependencies:
- [IDI_Clean].[cen_clean].[census_individual_2018]
- [IDI_Clean].[cen_clean].[census_individual_2013]
- [IDI_Clean].[dia_clean].[births]
- [IDI_Clean].[cus_clean].[journey]
- [IDI_Clean].[nzta_clean].[dlr_historic]
- [IDI_Clean].[nzta_clean].[drivers_licence_register]
- [IDI_Clean].[dol_clean].[movement_identities]
- [IDI_Clean].[moe_clean].[enrolment]
- [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2019]
- [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2018]
- [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2017]
- [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2016]
- [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2015]
- [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2014]
- [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2013]
- [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2012]
- [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2011]
- [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2010]
- [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2009]
- [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2008]
- [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2007]
- [IDI_Clean].[moe_clean].[nsi]
Outputs:
- [IDI_Sandpit].[DL-MAA2021-49].[vacc_country_of_birth]

Description:
Country of birth (or citizenship where available COB not available)

Intended purpose:
Supplement ethnicity and identity information by including Country of Birth.
Where country of birth (COB) is not available we instead use country of
citizenship (COC).

Notes:
1) Multiple sources contain COB / COC information.
	Consistent with how SNZ makes the personal details table, the different sources
	are ranked and the highest quality source is kept.

2) The ranking of the sources are as follows (1 = best):
	1. census 2018
	2. census 2013
	3. DIA births - NZ birth
	4. CUS customs
	5. NZTA drivers license
	6. DOL
	7. MOE enrolment - country of citizenships - take first COC by date
	8. MOE school enrolment - country of citizenships - take first COC by date

3) This file is very long because it contains complete lists of countries and the
	(manual) recoding of their labels to a standard set of country codes.
	A single length of country codes is approx 5-6x the PgDn button. This means that
	you can push the PgDn button 5 or 6 times to go from the start to the end of a country list.

4) The output country encoding should be consistent with Census country codes.

Issues:
1) The long CASE WHEN statements can be slow to execute.
	This can be improved by loading a metadata table and using a JOIN.
	A suitable metadata table is saved alongside this definition, but has not been
	integrated into this definition.

Parameters & Present values:
  Current refresh = 20211020
  Prefix = vacc_
  Project schema = DL-MAA2021-49
 
History (reverse order):
2021-11-26 SA restructure and tidy
2021-10-31 CW
**************************************************************************************************/

/* create table of all COB */
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_COB_list]
GO

CREATE TABLE [IDI_Sandpit].[DL-MAA2021-49].[tmp_COB_list] (
	snz_uid INT,
	c_type VARCHAR(5),
	code VARCHAR(5),
	source_rank INT,
);
GO

/***************************************************************************************************************
append records from each source into the table
***************************************************************************************************************/

/********************************************************
Census 2018
'V14.1' as code_sys
********************************************************/
INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_COB_list] (snz_uid, c_type, code, source_rank)
SELECT [snz_uid]
	,'COB' AS c_type
	,[cen_ind_birth_country_code] as code
	,1 AS source_rank
FROM [IDI_Clean_20211020].[cen_clean].[census_individual_2018]
WHERE [cen_ind_birth_country_impt_ind] in ('11','12')
GO

/********************************************************
Census 2013 
'V14.1' as code_sys
********************************************************/
INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_COB_list] (snz_uid, c_type, code, source_rank)
SELECT [snz_uid]
	,'COB' as c_type
	,[cen_ind_birth_country_code] as code
	,2 AS source_rank
FROM [IDI_Clean_20211020].[cen_clean].[census_individual_2013]
GO

/********************************************************
DIA births - NZ birth 
'1999 4N V14.0.0' as code_sys
********************************************************/
INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_COB_list] (snz_uid, c_type, code, source_rank)
SELECT DISTINCT snz_uid
	,'COB' as c_type
	,'1201' as code
	,3 AS source_rank
FROM [IDI_Clean_20211020].[dia_clean].[births]
GO

/********************************************************
CUS customs 
'1999 4A V15.0.0' as raw_code_sys
'1999 4N V14.0.0' as code_sys
********************************************************/
INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_COB_list] (snz_uid, c_type, code, source_rank)
SELECT [snz_uid]
	,'COB' AS c_type
	,CASE [cus_jou_country_of_birth_code]
		WHEN '01' then NULL
		WHEN '02' then NULL
		WHEN '03' then NULL
		WHEN 'AD' then '3101'
		WHEN 'AE' then '4216'
		WHEN 'AF' then '7201'
		WHEN 'AG' then '8402'
		WHEN 'AI' then '8401'
		WHEN 'AL' then '3201'
		WHEN 'AM' then '7202'
		WHEN 'AN' then NULL
		WHEN 'AO' then '9201'
		WHEN 'AQ' then '1601'
		WHEN 'AR' then '8201'
		WHEN 'AS' then '1506'
		WHEN 'AT' then '2301'
		WHEN 'AU' then '1101'
		WHEN 'AW' then '8403'
		WHEN 'AZ' then '7203'
		WHEN 'BA' then '3202'
		WHEN 'BB' then '8405'
		WHEN 'BD' then '7101'
		WHEN 'BE' then '2302'
		WHEN 'BF' then '9102'
		WHEN 'BG' then '3203'
		WHEN 'BH' then '4201'
		WHEN 'BI' then '9203'
		WHEN 'BJ' then '9101'
		WHEN 'BM' then '8101'
		WHEN 'BN' then '5201'
		WHEN 'BO' then '8202'
		WHEN 'BR' then '8203'
		WHEN 'BS' then '8404'
		WHEN 'BT' then '7102'
		WHEN 'BU' then '5101'
		WHEN 'BW' then '9202'
		WHEN 'BY' then '3301'
		WHEN 'BZ' then '8301'
		WHEN 'CA' then '8102'
		WHEN 'CC' then '1101'
		WHEN 'CD' then '9108'
		WHEN 'CF' then '9105'
		WHEN 'CG' then '9107'
		WHEN 'CH' then '2311'
		WHEN 'CI' then '9111'
		WHEN 'CK' then '1501'
		WHEN 'CL' then '8204'
		WHEN 'CM' then '9103'
		WHEN 'CN' then '6101'
		WHEN 'CO' then '8205'
		WHEN 'CR' then '8302'
		WHEN 'CS' then '3215'
		WHEN 'CT' then '1402'
		WHEN 'CU' then '8407'
		WHEN 'CV' then '9104'
		WHEN 'CW' then '8433'
		WHEN 'CX' then '1101'
		WHEN 'CY' then '3205'
		WHEN 'CZ' then '3302'
		WHEN 'DD' then '2304'
		WHEN 'DE' then '2304'
		WHEN 'DJ' then '9205'
		WHEN 'DK' then '2401'
		WHEN 'DM' then '8408'
		WHEN 'DO' then '8411'
		WHEN 'DZ' then '4101'
		WHEN 'EC' then '8206'
		WHEN 'EE' then '3303'
		WHEN 'EG' then '4102'
		WHEN 'EH' then '4107'
		WHEN 'EN' then '2102'
		WHEN 'ER' then '9206'
		WHEN 'ES' then '3108'
		WHEN 'ET' then '9207'
		WHEN 'EU' then NULL
		WHEN 'FI' then '2403'
		WHEN 'FJ' then '1502'
		WHEN 'FK' then '8207'
		WHEN 'FM' then '1404'
		WHEN 'FO' then '2402'
		WHEN 'FR' then '2303'
		WHEN 'GA' then '9113'
		WHEN 'GB' then '2100'
		WHEN 'GD' then '8412'
		WHEN 'GE' then '7204'
		WHEN 'GF' then '8208'
		WHEN 'GH' then '9115'
		WHEN 'GI' then '3102'
		WHEN 'GJ' then '8412'
		WHEN 'GL' then '2404'
		WHEN 'GM' then '9114'
		WHEN 'GN' then '9116'
		WHEN 'GP' then '8413'
		WHEN 'GQ' then '9112'
		WHEN 'GR' then '3207'
		WHEN 'GS' then NULL
		WHEN 'GT' then '8304'
		WHEN 'GU' then '1401'
		WHEN 'GW' then '9117'
		WHEN 'GY' then '8211'
		WHEN 'HG' then NULL
		WHEN 'HI' then '2105'
		WHEN 'HK' then '6102'
		WHEN 'HN' then '8305'
		WHEN 'HR' then '3204'
		WHEN 'HT' then '8414'
		WHEN 'HU' then '3304'
		WHEN 'ID' then '5202'
		WHEN 'IE' then '2201'
		WHEN 'IL' then '4205'
		WHEN 'IM' then '2103'
		WHEN 'IN' then '7103'
		WHEN 'IO' then '9299'
		WHEN 'IQ' then '4204'
		WHEN 'IR' then '4203'
		WHEN 'IS' then '2405'
		WHEN 'IT' then '3104'
		WHEN 'JM' then '8415'
		WHEN 'JO' then '4206'
		WHEN 'JP' then '6103'
		WHEN 'KE' then '9208'
		WHEN 'KG' then '7206'
		WHEN 'KH' then '5102'
		WHEN 'KI' then '1402'
		WHEN 'KM' then '9204'
		WHEN 'KN' then '8422'
		WHEN 'KP' then '6104'
		WHEN 'KR' then '6105'
		WHEN 'KW' then '4207'
		WHEN 'KX' then '3216'
		WHEN 'KY' then '8406'
		WHEN 'KZ' then '7205'
		WHEN 'LA' then '5103'
		WHEN 'LB' then '4208'
		WHEN 'LC' then '8423'
		WHEN 'LI' then '2305'
		WHEN 'LK' then '7107'
		WHEN 'LR' then '9118'
		WHEN 'LS' then '9211'
		WHEN 'LT' then '3306'
		WHEN 'LU' then '2306'
		WHEN 'LV' then '3305'
		WHEN 'LY' then '4103'
		WHEN 'MA' then '4104'
		WHEN 'MC' then '2307'
		WHEN 'MD' then '3208'
		WHEN 'ME' then '3214'
		WHEN 'MG' then '9212'
		WHEN 'MH' then '1403'
		WHEN 'MK' then '3206'
		WHEN 'ML' then '9121'
		WHEN 'MM' then '5101'
		WHEN 'MN' then '6107'
		WHEN 'MO' then '6106'
		WHEN 'MP' then '1406'
		WHEN 'MQ' then '8416'
		WHEN 'MR' then '9122'
		WHEN 'MS' then '8417'
		WHEN 'MT' then '3105'
		WHEN 'MU' then '9214'
		WHEN 'MV' then '7104'
		WHEN 'MW' then '9213'
		WHEN 'MX' then '8306'
		WHEN 'MY' then '5203'
		WHEN 'MZ' then '9216'
		WHEN 'NA' then '9217'
		WHEN 'NC' then '1301'
		WHEN 'ND' then '2104'
		WHEN 'NE' then '9123'
		WHEN 'NF' then '1102'
		WHEN 'NG' then '9124'
		WHEN 'NI' then '8307'
		WHEN 'NL' then '2308'
		WHEN 'NO' then '2406'
		WHEN 'NP' then '7105'
		WHEN 'NR' then '1405'
		WHEN 'NT' then NULL
		WHEN 'NU' then '1504'
		WHEN 'NZ' then '1201'
		WHEN 'OM' then '4211'
		WHEN 'PA' then '8308'
		WHEN 'PC' then NULL
		WHEN 'PE' then '8213'
		WHEN 'PF' then '1503'
		WHEN 'PG' then '1302'
		WHEN 'PH' then '5204'
		WHEN 'PK' then '7106'
		WHEN 'PL' then '3307'
		WHEN 'PM' then '8103'
		WHEN 'PN' then '1513'
		WHEN 'PR' then '8421'
		WHEN 'PS' then '4202'
		WHEN 'PT' then '3106'
		WHEN 'PU' then NULL
		WHEN 'PW' then '1407'
		WHEN 'PX' then '4202'
		WHEN 'PY' then '8212'
		WHEN 'QA' then '4212'
		WHEN 'RE' then '9218'
		WHEN 'RK' then '3216'
		WHEN 'RO' then '3211'
		WHEN 'RS' then '3215'
		WHEN 'RU' then '3308'
		WHEN 'RW' then '9221'
		WHEN 'SA' then '4213'
		WHEN 'SB' then '1303'
		WHEN 'SC' then '9223'
		WHEN 'SD' then '4105'
		WHEN 'SE' then '2407'
		WHEN 'SG' then '5205'
		WHEN 'SH' then '9222'
		WHEN 'SI' then '3212'
		WHEN 'SK' then '3311'
		WHEN 'SL' then '9127'
		WHEN 'SM' then '3107'
		WHEN 'SN' then '9126'
		WHEN 'SO' then '9224'
		WHEN 'SP' then NULL
		WHEN 'SQ' then NULL
		WHEN 'SR' then '8214'
		WHEN 'SS' then '4111'
		WHEN 'ST' then '9125'
		WHEN 'SU' then NULL
		WHEN 'SV' then '8303'
		WHEN 'SX' then '3215'
		WHEN 'SY' then '4214'
		WHEN 'SZ' then '9226'
		WHEN 'TC' then '8426'
		WHEN 'TD' then '9106'
		WHEN 'TF' then '1601'
		WHEN 'TG' then '9128'
		WHEN 'TH' then '5104'
		WHEN 'TJ' then '7207'
		WHEN 'TK' then '1507'
		WHEN 'TL' then '5206'
		WHEN 'TM' then '7208'
		WHEN 'TN' then '4106'
		WHEN 'TO' then '1508'
		WHEN 'TP' then '5206'
		WHEN 'TR' then '4215'
		WHEN 'TT' then '8425'
		WHEN 'TV' then '1511'
		WHEN 'TW' then '6108'
		WHEN 'TZ' then '9227'
		WHEN 'UA' then '3312'
		WHEN 'UG' then '9228'
		WHEN 'UK' then '3216'
		WHEN 'UM' then '8104'
		WHEN 'UN' then NULL
		WHEN 'US' then '8104'
		WHEN 'UY' then '8215'
		WHEN 'UZ' then '7211'
		WHEN 'VA' then '3103'
		WHEN 'VC' then '8424'
		WHEN 'VE' then '8216'
		WHEN 'VG' then '8427'
		WHEN 'VI' then '8428'
		WHEN 'VN' then '5105'
		WHEN 'VU' then '1304'
		WHEN 'WA' then '2106'
		WHEN 'WF' then '1512'
		WHEN 'WS' then '1505'
		WHEN 'XX' then NULL
		WHEN 'YD' then '4217'
		WHEN 'YE' then '4217'
		WHEN 'YM' then '3206'
		WHEN 'YT' then '9215'
		WHEN 'YU' then NULL
		WHEN 'ZA' then '9225'
		WHEN 'ZM' then '9231'
		WHEN 'ZR' then '9108'
		WHEN 'ZW' then '9232'
		WHEN 'ZZ' then NULL
		ELSE NULL END AS code
	,4 AS source_rank
FROM [IDI_Clean_20211020].[cus_clean].[journey]
WHERE [cus_jou_country_of_birth_code] IS NOT NULL
AND [cus_jou_country_of_birth_code] != 'XX'
GO

/********************************************************
NZTA drivers license 
'1999 4N V14.0.0' as code_sys
********************************************************/
INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_COB_list] (snz_uid, c_type, code, source_rank)
SELECT DISTINCT snz_uid
	,'COB' AS c_type
	,CASE raw_text
		WHEN 'AUSTRALIA' then '1101'
		WHEN 'NORFOLK ISLAND' then '1102'
		WHEN 'NORFOLK ISLANDS' then '1102'
		WHEN 'NEW ZEALAND' then '1201'
		WHEN 'NEW CALEDONIA' then '1301'
		WHEN 'PAPUA NEW GUINEA' then '1302'
		WHEN 'SOLOMON ISLANDS' then '1303'
		WHEN 'BRITISH SOLOMON ISLANDS' then '1303'
		WHEN 'VANUATU' then '1304'
		WHEN 'GUAM' then '1401'
		WHEN 'KIRIBATI' then '1402'
		WHEN 'CANTON & ENDERBURY' then '1402'
		WHEN 'MARSHALL ISLANDS' then '1403'
		WHEN 'FEDERATED STATES OF MICRONESIA' then '1404'
		WHEN 'NAURU' then '1405'
		WHEN 'NORTHERN MARIANA ISLANDS' then '1406'
		WHEN 'PALAU' then '1407'
		WHEN 'COOK ISLANDS (RAROTONGA)' then '1501'
		WHEN 'FIJI' then '1502'
		WHEN 'FRENCH POLYNESIA' then '1503'
		WHEN 'NIUE ISLANDS' then '1504'
		WHEN 'SAMOA' then '1505'
		WHEN 'WESTERN SAMOA' then '1505'
		WHEN 'SAMOA AMERICAN' then '1506'
		WHEN 'AMERICAN SAMOA' then '1506'
		WHEN 'TOKELAU' then '1507'
		WHEN 'TONGA' then '1508'
		WHEN 'TUVALU' then '1511'
		WHEN 'WALLIS AND FUTUNA' then '1512'
		WHEN 'PITCAIRN' then '1513'
		WHEN 'UNITED KINGDOM' then '2100'
		WHEN 'CHANNEL ISLANDS' then '2101'
		WHEN 'ENGLAND' then '2102'
		WHEN 'ISLE OF MAN' then '2103'
		WHEN 'NORTHERN IRELAND' then '2104'
		WHEN 'SCOTLAND' then '2105'
		WHEN 'WALES' then '2106'
		WHEN 'IRELAND (EIRE)' then '2201'
		WHEN 'REPUBLIC OF IRELAND' then '2300'
		WHEN 'AUSTRIA' then '2301'
		WHEN 'BELGIUM' then '2302'
		WHEN 'FRANCE' then '2303'
		WHEN 'GERMANY' then '2304'
		WHEN 'LIECHTENSTEIN' then '2305'
		WHEN 'LUXEMBOURG' then '2306'
		WHEN 'MONACO' then '2307'
		WHEN 'NETHERLANDS (HOLLAND)' then '2308'
		WHEN 'SWITZERLAND' then '2311'
		WHEN 'DENMARK' then '2401'
		WHEN 'FAEROE ISLANDS' then '2402'
		WHEN 'FINLAND' then '2403'
		WHEN 'GREENLAND' then '2404'
		WHEN 'ICELAND' then '2405'
		WHEN 'NORWAY' then '2406'
		WHEN 'SWEDEN' then '2407'
		WHEN 'ANDORRA' then '3101'
		WHEN 'GIBRALTAR' then '3102'
		WHEN 'VATICAN CITY STATE' then '3103'
		WHEN 'ITALY' then '3104'
		WHEN 'MALTA' then '3105'
		WHEN 'PORTUGAL' then '3106'
		WHEN 'SAN MARINO' then '3107'
		WHEN 'SPAIN' then '3108'
		WHEN 'ALBANIA' then '3201'
		WHEN 'BOSNIA-HERZEGOVINA' then '3202'
		WHEN 'BULGARIA' then '3203'
		WHEN 'CROATIA' then '3204'
		WHEN 'CYPRUS' then '3205'
		WHEN 'GREECE' then '3207'
		WHEN 'MOLDOVA' then '3208'
		WHEN 'ROMANIA' then '3211'
		WHEN 'SLOVENIA' then '3212'
		WHEN 'MONTENEGRO' then '3214'
		WHEN 'SERBIA' then '3215'
		WHEN 'KOSOVO' then '3216'
		WHEN 'YUGOSLAVIA' then '3300'
		WHEN 'MACEDONIA' then '3300'
		WHEN 'BELARUS' then '3301'
		WHEN 'CZECH REPUBLIC' then '3302'
		WHEN 'CZECHOSLOVAKIA' then '3302'
		WHEN 'YUGOSLAVIA (SERBIA & MONTENEGRO)' then '3302'
		WHEN 'ESTONIA' then '3303'
		WHEN 'HUNGARY' then '3304'
		WHEN 'LATVIA' then '3305'
		WHEN 'LITHUANIA' then '3306'
		WHEN 'POLAND' then '3307'
		WHEN 'RUSSIA' then '3308'
		WHEN 'SLOVAKIA' then '3311'
		WHEN 'UKRAINE' then '3312'
		WHEN 'ALGERIA' then '4101'
		WHEN 'EGYPT' then '4102'
		WHEN 'MOROCCO' then '4104'
		WHEN 'SUDAN' then '4105'
		WHEN 'TUNISIA' then '4106'
		WHEN 'WESTERN SAHARA' then '4107'
		WHEN 'SOUTH SUDAN' then '4111'
		WHEN 'BAHRAIN' then '4201'
		WHEN 'PALESTINE' then '4202'
		WHEN 'GAZA STRIP' then '4202'
		WHEN 'WEST BANK' then '4202'
		WHEN 'IRAN' then '4203'
		WHEN 'IRAQ' then '4204'
		WHEN 'ISRAEL' then '4205'
		WHEN 'JORDAN' then '4206'
		WHEN 'KUWAIT' then '4207'
		WHEN 'LEBANON' then '4208'
		WHEN 'OMAN' then '4211'
		WHEN 'QATAR' then '4212'
		WHEN 'SAUDI ARABIA' then '4213'
		WHEN 'SYRIA' then '4214'
		WHEN 'TURKEY' then '4215'
		WHEN 'UNITED ARAB EMIRATES' then '4216'
		WHEN 'YEMEN' then '4217'
		WHEN 'MYANMAR' then '5101'
		WHEN 'BURMA' then '5101'
		WHEN 'CAMBODIA' then '5102'
		WHEN 'KAMPUCHEA' then '5102'
		WHEN 'LAOS' then '5103'
		WHEN 'THAILAND' then '5104'
		WHEN 'VIETNAM' then '5105'
		WHEN 'BRUNEI DARUSSALAM' then '5201'
		WHEN 'INDONESIA' then '5202'
		WHEN 'MALAYSIA' then '5203'
		WHEN 'PHILIPPINES' then '5204'
		WHEN 'SINGAPORE' then '5205'
		WHEN 'TIMOR (PORTUGESE)' then '5206'
		WHEN 'CHINA PEOPLE''S REPUBLIC OF' then '6101'
		WHEN 'HONG KONG' then '6102'
		WHEN 'JAPAN' then '6103'
		WHEN 'KOREA (NORTH) DPR' then '6104'
		WHEN 'KOREA (SOUTH) RPBC' then '6105'
		WHEN 'MACAU' then '6106'
		WHEN 'MONGOLIA' then '6107'
		WHEN 'TAIWAN' then '6108'
		WHEN 'BANGLADESH' then '7101'
		WHEN 'BHUTAN' then '7102'
		WHEN 'INDIA' then '7103'
		WHEN 'MALDIVES' then '7104'
		WHEN 'NEPAL' then '7105'
		WHEN 'PAKISTAN' then '7106'
		WHEN 'SRI LANKA' then '7107'
		WHEN 'AFGHANISTAN' then '7201'
		WHEN 'ARMENIA' then '7202'
		WHEN 'AZERBAIJAN' then '7203'
		WHEN 'GEORGIA' then '7204'
		WHEN 'KAZAKHSTAN' then '7205'
		WHEN 'KYRGYZSTAN' then '7206'
		WHEN 'TAJIKISTAN' then '7207'
		WHEN 'TURKMENISTAN' then '7208'
		WHEN 'UZBEKISTAN' then '7211'
		WHEN 'AMERICA UNDEFINED' then '8000'
		WHEN 'BERMUDA' then '8101'
		WHEN 'CANADA' then '8102'
		WHEN 'ST PIERRE AND MIQUELON' then '8103'
		WHEN 'UNITED STATES OF AMERICA' then '8104'
		WHEN 'ARGENTINA' then '8201'
		WHEN 'BOLIVIA' then '8202'
		WHEN 'BRAZIL' then '8203'
		WHEN 'CHILE' then '8204'
		WHEN 'COLOMBIA' then '8205'
		WHEN 'ECUADOR' then '8206'
		WHEN 'FALKLAND ISLANDS' then '8207'
		WHEN 'FRENCH GUIANA' then '8208'
		WHEN 'GUYANA' then '8211'
		WHEN 'PARAGUAY' then '8212'
		WHEN 'PERU' then '8213'
		WHEN 'SURINAME' then '8214'
		WHEN 'URUGUAY' then '8215'
		WHEN 'VENEZUELA' then '8216'
		WHEN 'BELIZE' then '8301'
		WHEN 'COSTA RICA' then '8302'
		WHEN 'EL SALVADOR' then '8303'
		WHEN 'GUATEMALA' then '8304'
		WHEN 'HONDURAS' then '8305'
		WHEN 'MEXICO' then '8306'
		WHEN 'NICARAGUA' then '8307'
		WHEN 'PANAMA' then '8308'
		WHEN 'CARIBBEAN UNSPECIFIED' then '8400'
		WHEN 'ANGUILLA' then '8401'
		WHEN 'ANTIGUA & BARBUDA' then '8402'
		WHEN 'ARUBA' then '8403'
		WHEN 'BAHAMAS' then '8404'
		WHEN 'BARBADOS' then '8405'
		WHEN 'CAYMAN ISLANDS' then '8406'
		WHEN 'CUBA' then '8407'
		WHEN 'DOMINICA' then '8408'
		WHEN 'DOMINICAN REPUBLIC' then '8411'
		WHEN 'GRENADA' then '8412'
		WHEN 'GUADELOUPE' then '8413'
		WHEN 'HAITI' then '8414'
		WHEN 'JAMAICA' then '8415'
		WHEN 'MARTINIQUE' then '8416'
		WHEN 'MONTSERRAT' then '8417'
		WHEN 'PUERTO RICO' then '8421'
		WHEN 'ST KITT-NEVIS' then '8422'
		WHEN 'ST LUCIA' then '8423'
		WHEN 'ST VINCENT AND THE GRENADINES' then '8424'
		WHEN 'TRINIDAD AND TOBAGO' then '8425'
		WHEN 'TURKS AND CAICOS ISLANDS' then '8426'
		WHEN 'VIRGIN ISLANDS BRITISH' then '8427'
		WHEN 'VIRGIN ISLANDS UNITED STATES' then '8428'
		WHEN 'BENIN' then '9101'
		WHEN 'BURKINA FASO' then '9102'
		WHEN 'CAMEROON REPUBLIC OF' then '9103'
		WHEN 'CENTRAL AFRICAN REPUBLIC' then '9105'
		WHEN 'CHAD' then '9106'
		WHEN 'CONGO' then '9107'
		WHEN 'REPUBLIC OF CONGO' then '9108'
		WHEN 'DEM REPUBLIC OF THE CONGO' then '9108'
		WHEN 'COTE D''IVOIRE' then '9111'
		WHEN 'EQUATORIAL GUINEA' then '9112'
		WHEN 'GABON' then '9113'
		WHEN 'GAMBIA' then '9114'
		WHEN 'GHANA' then '9115'
		WHEN 'GUINEA' then '9116'
		WHEN 'GUINEA-BISSAU' then '9117'
		WHEN 'LIBERIA' then '9118'
		WHEN 'MALI' then '9121'
		WHEN 'MAURITANIA' then '9122'
		WHEN 'NIGER' then '9123'
		WHEN 'NIGERIA' then '9124'
		WHEN 'SAO TOME AND PRINCIPE' then '9125'
		WHEN 'SENEGAL' then '9126'
		WHEN 'SIERRA LEONE' then '9127'
		WHEN 'TOGO' then '9128'
		WHEN 'ANGOLA' then '9201'
		WHEN 'BOTSWANA' then '9202'
		WHEN 'BURUNDI' then '9203'
		WHEN 'COMOROS' then '9204'
		WHEN 'DJIBOUTI' then '9205'
		WHEN 'ERITREA' then '9206'
		WHEN 'ETHIOPIA' then '9207'
		WHEN 'KENYA' then '9208'
		WHEN 'LESOTHO' then '9211'
		WHEN 'MADAGASCAR' then '9212'
		WHEN 'MALAWI' then '9213'
		WHEN 'MAURITIUS' then '9214'
		WHEN 'MAYOTTE' then '9215'
		WHEN 'MOZAMBIQUE' then '9216'
		WHEN 'NAMIBIA' then '9217'
		WHEN 'REUNION' then '9218'
		WHEN 'RWANDA' then '9221'
		WHEN 'ST HELENA' then '9222'
		WHEN 'SEYCHELLES' then '9223'
		WHEN 'SOMALIA' then '9224'
		WHEN 'SOUTH AFRICA' then '9225'
		WHEN 'TANZANIA' then '9227'
		WHEN 'UGANDA' then '9228'
		WHEN 'ZAMBIA' then '9231'
		WHEN 'ZIMBABWE' then '9232'
		WHEN 'UNKNOWN' then '9999'
		WHEN 'LIBYAN ARAB REPUBLIC' then NULL
		WHEN 'SWAZILAND' then NULL
		WHEN 'PACIFIC ISLANDS (UNSPECIFIED)' then NULL
		WHEN 'NETHERLANDS ANTILLES' then NULL
		WHEN 'US MISC PACIFIC ISLANDS' then NULL
		WHEN 'COCOS ISLANDS' then NULL
		WHEN 'IVORY COAST' then NULL
		WHEN 'LAO REPUBLIC' then NULL
		WHEN 'SOUTHERN RHODESIA' then NULL
		WHEN 'CHILEAN ANTARCTIC TERRITORY' then NULL
		WHEN 'NEUTRAL ZONE' then NULL
		WHEN 'KHMER REPUBLIC' then NULL
		WHEN 'ZAIRE' then NULL
		WHEN 'OTHER NORTH AFRICA' then NULL
		WHEN 'BRITISH ANTARCTIC TERRITORY' then NULL
		WHEN 'BRIT INDIAN OCEAN' then NULL
		WHEN 'AFARS & ISSAS' then NULL
		WHEN 'BYELORUSSIAN SSR' then NULL
		WHEN 'CAPE VERDE' then NULL
		WHEN 'OTHER POLYNESIA (EXCL HAWAII)' then NULL
		WHEN 'ADELIE LAND (FRANCE)' then NULL
		WHEN 'ARGENTINIAN ANTARCTIC' then NULL
		WHEN 'AUSTRALIAN ANTARCTIC TERRITORY' then NULL
		WHEN 'OTHER SOUTHERN & EAST AFRICA' then NULL
		WHEN 'UPPER VOLTA' then NULL
		ELSE NULL END AS code
	,5 AS source_rank
FROM (
	SELECT snz_uid, nzta_hist_birth_country_text AS raw_text
	FROM [IDI_Clean_20211020].[nzta_clean].[dlr_historic]

	UNION ALL

	SELECT snz_uid, nzta_dlr_birth_country_text AS raw_text
	FROM [IDI_Clean_20211020].[nzta_clean].[drivers_licence_register]
) AS a
GO

/********************************************************
DOL 
'1999 4A V15.0.0' as raw_code_sys
'1999 4N V14.0.0' as code_sys
********************************************************/
INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_COB_list] (snz_uid, c_type, code, source_rank)
SELECT DISTINCT [snz_uid]
	,'COB' as c_type
	,CASE [dol_mid_birth_country_code]
		WHEN 'AU' then '1101'
		WHEN 'NF' then '1102'
		WHEN 'NZ' then '1201'
		WHEN 'NC' then '1301'
		WHEN 'PG' then '1302'
		WHEN 'SB' then '1303'
		WHEN 'VU' then '1304'
		WHEN 'GU' then '1401'
		WHEN 'KI' then '1402'
		WHEN 'MH' then '1403'
		WHEN 'FM' then '1404'
		WHEN 'NR' then '1405'
		WHEN 'MP' then '1406'
		WHEN 'PW' then '1407'
		WHEN 'CK' then '1501'
		WHEN 'FJ' then '1502'
		WHEN 'PF' then '1503'
		WHEN 'NU' then '1504'
		WHEN 'WS' then '1505'
		WHEN 'AS' then '1506'
		WHEN 'TK' then '1507'
		WHEN 'TO' then '1508'
		WHEN 'TV' then '1511'
		WHEN 'WF' then '1512'
		WHEN 'PN' then '1513'
		WHEN 'AQ' then '1601'
		WHEN 'TF' then '1601'
		WHEN 'GB' then '2100'
		WHEN 'IM' then '2103'
		WHEN 'ND' then '2104'
		WHEN 'HI' then '2105'
		WHEN 'WA' then '2106'
		WHEN 'IE' then '2201'
		WHEN 'AT' then '2301'
		WHEN 'BE' then '2302'
		WHEN 'FR' then '2303'
		WHEN 'DE' then '2304'
		WHEN 'LI' then '2305'
		WHEN 'LU' then '2306'
		WHEN 'MC' then '2307'
		WHEN 'NL' then '2308'
		WHEN 'CH' then '2311'
		WHEN 'DK' then '2401'
		WHEN 'FO' then '2402'
		WHEN 'FI' then '2403'
		WHEN 'GL' then '2404'
		WHEN 'IS' then '2405'
		WHEN 'NO' then '2406'
		WHEN 'SE' then '2407'
		WHEN 'AD' then '3101'
		WHEN 'GI' then '3102'
		WHEN 'VA' then '3103'
		WHEN 'IT' then '3104'
		WHEN 'MT' then '3105'
		WHEN 'PT' then '3106'
		WHEN 'SM' then '3107'
		WHEN 'ES' then '3108'
		WHEN 'AL' then '3201'
		WHEN 'BA' then '3202'
		WHEN 'BG' then '3203'
		WHEN 'HR' then '3204'
		WHEN 'CY' then '3205'
		WHEN 'GR' then '3207'
		WHEN 'MD' then '3208'
		WHEN 'RO' then '3211'
		WHEN 'SI' then '3212'
		WHEN 'ME' then '3214'
		WHEN 'RS' then '3215'
		WHEN 'KX' then '3216'
		WHEN 'BY' then '3301'
		WHEN 'CZ' then '3302'
		WHEN 'EE' then '3303'
		WHEN 'EN' then '3303'
		WHEN 'HU' then '3304'
		WHEN 'LV' then '3305'
		WHEN 'LT' then '3306'
		WHEN 'PL' then '3307'
		WHEN 'RU' then '3308'
		WHEN 'SK' then '3311'
		WHEN 'UA' then '3312'
		WHEN 'DZ' then '4101'
		WHEN 'EG' then '4102'
		WHEN 'LY' then '4103'
		WHEN 'MA' then '4104'
		WHEN 'SD' then '4105'
		WHEN 'TN' then '4106'
		WHEN 'EH' then '4107'
		WHEN 'SS' then '4111'
		WHEN 'BH' then '4201'
		WHEN 'IR' then '4203'
		WHEN 'IQ' then '4204'
		WHEN 'IL' then '4205'
		WHEN 'JO' then '4206'
		WHEN 'KW' then '4207'
		WHEN 'LB' then '4208'
		WHEN 'OM' then '4211'
		WHEN 'QA' then '4212'
		WHEN 'SA' then '4213'
		WHEN 'SY' then '4214'
		WHEN 'TR' then '4215'
		WHEN 'AE' then '4216'
		WHEN 'YE' then '4217'
		WHEN 'MM' then '5101'
		WHEN 'KH' then '5102'
		WHEN 'LA' then '5103'
		WHEN 'TH' then '5104'
		WHEN 'VN' then '5105'
		WHEN 'BN' then '5201'
		WHEN 'ID' then '5202'
		WHEN 'MY' then '5203'
		WHEN 'PH' then '5204'
		WHEN 'SG' then '5205'
		WHEN 'TL' then '5206'
		WHEN 'CN' then '6101'
		WHEN 'HK' then '6102'
		WHEN 'JP' then '6103'
		WHEN 'KP' then '6104'
		WHEN 'KR' then '6105'
		WHEN 'MO' then '6106'
		WHEN 'MN' then '6107'
		WHEN 'TW' then '6108'
		WHEN 'BD' then '7101'
		WHEN 'BT' then '7102'
		WHEN 'IN' then '7103'
		WHEN 'MV' then '7104'
		WHEN 'NP' then '7105'
		WHEN 'PK' then '7106'
		WHEN 'LK' then '7107'
		WHEN 'AF' then '7201'
		WHEN 'AM' then '7202'
		WHEN 'AZ' then '7203'
		WHEN 'GE' then '7204'
		WHEN 'KZ' then '7205'
		WHEN 'KG' then '7206'
		WHEN 'TJ' then '7207'
		WHEN 'TM' then '7208'
		WHEN 'UZ' then '7211'
		WHEN 'BM' then '8101'
		WHEN 'CA' then '8102'
		WHEN 'PM' then '8103'
		WHEN 'US' then '8104'
		WHEN 'AR' then '8201'
		WHEN 'BO' then '8202'
		WHEN 'BR' then '8203'
		WHEN 'CL' then '8204'
		WHEN 'CO' then '8205'
		WHEN 'EC' then '8206'
		WHEN 'FK' then '8207'
		WHEN 'GF' then '8208'
		WHEN 'GY' then '8211'
		WHEN 'PY' then '8212'
		WHEN 'PE' then '8213'
		WHEN 'SR' then '8214'
		WHEN 'UY' then '8215'
		WHEN 'VE' then '8216'
		WHEN 'BZ' then '8301'
		WHEN 'CR' then '8302'
		WHEN 'SV' then '8303'
		WHEN 'GT' then '8304'
		WHEN 'HN' then '8305'
		WHEN 'MX' then '8306'
		WHEN 'NI' then '8307'
		WHEN 'PA' then '8308'
		WHEN 'AI' then '8401'
		WHEN 'AG' then '8402'
		WHEN 'AW' then '8403'
		WHEN 'BS' then '8404'
		WHEN 'BB' then '8405'
		WHEN 'KY' then '8406'
		WHEN 'CU' then '8407'
		WHEN 'DM' then '8408'
		WHEN 'DO' then '8411'
		WHEN 'GD' then '8412'
		WHEN 'GJ' then '8412'
		WHEN 'GP' then '8413'
		WHEN 'HT' then '8414'
		WHEN 'JM' then '8415'
		WHEN 'MQ' then '8416'
		WHEN 'MS' then '8417'
		WHEN 'PR' then '8421'
		WHEN 'KN' then '8422'
		WHEN 'LC' then '8423'
		WHEN 'VC' then '8424'
		WHEN 'TT' then '8425'
		WHEN 'TC' then '8426'
		WHEN 'VG' then '8427'
		WHEN 'VI' then '8428'
		WHEN 'CW' then '8433'
		WHEN 'BJ' then '9101'
		WHEN 'BF' then '9102'
		WHEN 'CM' then '9103'
		WHEN 'CV' then '9104'
		WHEN 'CF' then '9105'
		WHEN 'TD' then '9106'
		WHEN 'CG' then '9107'
		WHEN 'CD' then '9108'
		WHEN 'ZR' then '9108'
		WHEN 'CI' then '9111'
		WHEN 'GQ' then '9112'
		WHEN 'GA' then '9113'
		WHEN 'GM' then '9114'
		WHEN 'GH' then '9115'
		WHEN 'GN' then '9116'
		WHEN 'GW' then '9117'
		WHEN 'LR' then '9118'
		WHEN 'ML' then '9121'
		WHEN 'MR' then '9122'
		WHEN 'NE' then '9123'
		WHEN 'NG' then '9124'
		WHEN 'ST' then '9125'
		WHEN 'SN' then '9126'
		WHEN 'SL' then '9127'
		WHEN 'TG' then '9128'
		WHEN 'AO' then '9201'
		WHEN 'BW' then '9202'
		WHEN 'BI' then '9203'
		WHEN 'KM' then '9204'
		WHEN 'DJ' then '9205'
		WHEN 'ER' then '9206'
		WHEN 'ET' then '9207'
		WHEN 'KE' then '9208'
		WHEN 'LS' then '9211'
		WHEN 'MG' then '9212'
		WHEN 'MW' then '9213'
		WHEN 'MU' then '9214'
		WHEN 'YT' then '9215'
		WHEN 'MZ' then '9216'
		WHEN 'NA' then '9217'
		WHEN 'RE' then '9218'
		WHEN 'RW' then '9221'
		WHEN 'SH' then '9222'
		WHEN 'SC' then '9223'
		WHEN 'SO' then '9224'
		WHEN 'ZA' then '9225'
		WHEN 'TZ' then '9227'
		WHEN 'UG' then '9228'
		WHEN 'ZM' then '9231'
		WHEN 'ZW' then '9232'
		WHEN '01' then '9999'
		WHEN 'NULL' then '9999'
		WHEN '02' then '9999'
		WHEN '03' then '9999'
		WHEN 'BQ' then '9999'
		WHEN 'BL' then '9999'
		WHEN 'NT' then '9999'
		WHEN 'XX' then '9999'
		WHEN 'SU' then '3300'
		WHEN 'YU' then '3200'
		WHEN 'MK' then '3200'
		WHEN 'UN' then '9999'
		WHEN 'PS' then '4202'
		WHEN 'DD' then '2304'
		WHEN 'ZZ' then '3302'
		WHEN 'RK' then '3200'
		WHEN 'CS' then '3200'
		WHEN 'AN' then '2308'
		WHEN 'TP' then '5206'
		WHEN 'CX' then '1402'
		WHEN 'BU' then '5101'
		WHEN 'UK' then '9999'
		WHEN 'SP' then '9999'
		WHEN 'PC' then '9999'
		WHEN 'SQ' then '9999'
		WHEN 'CC' then '1101'
		WHEN 'EU' then '9999'
		WHEN 'SX' then '3200'
		WHEN 'GS' then '2102'
		WHEN 'UM' then '8104'
		WHEN 'PU' then '8104'
		WHEN 'CT' then '9999'
		WHEN 'HG' then '9999'
		WHEN 'PX' then '4202'
		WHEN 'YD' then '4217'
		WHEN 'IO' then '9999'
		WHEN 'SZ' then '9226'
		WHEN 'YM' then '3200'
		ELSE NULL END AS code
	,6 AS source_rank
FROM [IDI_Clean_20211020].[dol_clean].[movement_identities]
GO

/********************************************************
MOE enrollment - first COC by date 
'XXXX' as raw_code_sys
********************************************************/
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_moe_enrollment]
GO

SELECT DISTINCT [snz_uid]
	,moe_enr_prog_start_date
    ,[moe_enr_country_code]
INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_moe_enrollment]
FROM [IDI_Clean_20211020].[moe_clean].[enrolment]
WHERE [moe_enr_country_code] != '999'
AND [moe_enr_country_code] NOT IN ('XXX','999','000')
AND [moe_enr_country_code] IS NOT NULL
GO

CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2021-49].[tmp_moe_enrollment] (snz_uid)
GO

WITH date_ranked AS (
	SELECT *
		,RANK() OVER (PARTITION BY snz_uid ORDER BY moe_enr_prog_start_date) AS date_rank
	FROM [IDI_Sandpit].[DL-MAA2021-49].[tmp_moe_enrollment]
)
INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_COB_list] (snz_uid, c_type, code, source_rank)
SELECT snz_uid
	,'COC' AS c_type
	,CASE [moe_enr_country_code]
		WHEN '0' then '9999'
		WHEN '102' then '9999'
		WHEN '110' then '9999'
		WHEN '999' then '9999'
		WHEN 'ABW' then '2308'
		WHEN 'AFG' then '7201'
		WHEN 'AGO' then '9201'
		WHEN 'ALB' then '3201'
		WHEN 'AME' then '9999'
		WHEN 'AND' then '3101'
		WHEN 'ANT' then '2308'
		WHEN 'ARE' then '4216'
		WHEN 'ARG' then '8201'
		WHEN 'ARM' then '7202'
		WHEN 'ASM' then '1506'
		WHEN 'ATG' then '8402'
		WHEN 'AUL' then '9999'
		WHEN 'AUS' then '1101'
		WHEN 'AUT' then '2301'
		WHEN 'AZE' then '7203'
		WHEN 'BDI' then '9203'
		WHEN 'BEL' then '2302'
		WHEN 'BEN' then '9101'
		WHEN 'BFA' then '9102'
		WHEN 'BGD' then '7101'
		WHEN 'BGR' then '3203'
		WHEN 'BHR' then '4201'
		WHEN 'BHS' then '8404'
		WHEN 'BIH' then '3202'
		WHEN 'BLR' then '3301'
		WHEN 'BLZ' then '8301'
		WHEN 'BOL' then '8202'
		WHEN 'BOZ' then '3200'
		WHEN 'BRA' then '8203'
		WHEN 'BRB' then '8405'
		WHEN 'BRN' then '5201'
		WHEN 'BTN' then '7102'
		WHEN 'BUL' then '9999'
		WHEN 'BWA' then '9202'
		WHEN 'CAF' then '9105'
		WHEN 'CAN' then '8102'
		WHEN 'CHE' then '2311'
		WHEN 'CHI' then '9999'
		WHEN 'CHL' then '8204'
		WHEN 'CHN' then '6101'
		WHEN 'CIV' then '9111'
		WHEN 'CMR' then '9103'
		WHEN 'COD' then '9108'
		WHEN 'COG' then '9107'
		WHEN 'COK' then '1501'
		WHEN 'COL' then '8205'
		WHEN 'COM' then '9204'
		WHEN 'CRI' then '8302'
		WHEN 'CSK' then '3302'
		WHEN 'CUB' then '8407'
		WHEN 'CYP' then '3205'
		WHEN 'CZE' then '3302'
		WHEN 'DEU' then '2304'
		WHEN 'DJI' then '9205'
		WHEN 'DMA' then '8408'
		WHEN 'DNK' then '2401'
		WHEN 'DOM' then '8411'
		WHEN 'DZA' then '4101'
		WHEN 'ECU' then '8206'
		WHEN 'EGY' then '4102'
		WHEN 'ENG' then '2102'
		WHEN 'ERI' then '9206'
		WHEN 'ESH' then '4107'
		WHEN 'ESP' then '3108'
		WHEN 'EST' then '3303'
		WHEN 'ETH' then '9207'
		WHEN 'FIN' then '2403'
		WHEN 'FJI' then '1502'
		WHEN 'FRA' then '2303'
		WHEN 'FSM' then '1404'
		WHEN 'GAB' then '9113'
		WHEN 'GBR' then '2100'
		WHEN 'GEO' then '7204'
		WHEN 'GHA' then '9115'
		WHEN 'GIN' then '9116'
		WHEN 'GJS' then '2101'
		WHEN 'GMB' then '9114'
		WHEN 'GNQ' then '9112'
		WHEN 'GRC' then '3207'
		WHEN 'GRD' then '8412'
		WHEN 'GRE' then '9999'
		WHEN 'GTM' then '8304'
		WHEN 'GUY' then '8211'
		WHEN 'HIL' then '2105'
		WHEN 'HKG' then '6102'
		WHEN 'HND' then '8305'
		WHEN 'HOL' then '9999'
		WHEN 'HRV' then '3204'
		WHEN 'HTI' then '8414'
		WHEN 'HUN' then '3304'
		WHEN 'IDN' then '5202'
		WHEN 'IND' then '7103'
		WHEN 'IRL' then '2201'
		WHEN 'IRN' then '4203'
		WHEN 'IRQ' then '4204'
		WHEN 'ISL' then '2405'
		WHEN 'ISR' then '4205'
		WHEN 'ITA' then '3104'
		WHEN 'JAM' then '8415'
		WHEN 'JAP' then '9999'
		WHEN 'JOR' then '4206'
		WHEN 'JPN' then '6103'
		WHEN 'KAZ' then '7205'
		WHEN 'KEN' then '9208'
		WHEN 'KGZ' then '7206'
		WHEN 'KHM' then '5102'
		WHEN 'KIR' then '1402'
		WHEN 'KNA' then '8422'
		WHEN 'KOR' then '6105'
		WHEN 'KUR' then '9999'
		WHEN 'KWT' then '4207'
		WHEN 'LAO' then '5103'
		WHEN 'LBN' then '4208'
		WHEN 'LBR' then '9118'
		WHEN 'LBY' then '4103'
		WHEN 'LCA' then '8423'
		WHEN 'LIE' then '2305'
		WHEN 'LKA' then '7107'
		WHEN 'LSO' then '9211'
		WHEN 'LTU' then '3306'
		WHEN 'LUX' then '2306'
		WHEN 'LVA' then '3305'
		WHEN 'MAC' then '6106'
		WHEN 'MAL' then '9999'
		WHEN 'MAR' then '4104'
		WHEN 'MCD' then '3200'
		WHEN 'MCO' then '2307'
		WHEN 'MDA' then '3208'
		WHEN 'MDG' then '9212'
		WHEN 'MDV' then '7104'
		WHEN 'MEX' then '8306'
		WHEN 'MHL' then '1403'
		WHEN 'MKD' then '3200'
		WHEN 'MLI' then '9121'
		WHEN 'MLT' then '3105'
		WHEN 'MMR' then '5101'
		WHEN 'MNE' then '3214'
		WHEN 'MNG' then '6107'
		WHEN 'MOZ' then '9216'
		WHEN 'MRT' then '9122'
		WHEN 'MSR' then '2100'
		WHEN 'MUS' then '9214'
		WHEN 'MWI' then '9213'
		WHEN 'MYS' then '5203'
		WHEN 'MZL' then '9999'
		WHEN 'NAM' then '9217'
		WHEN 'NCL' then '1301'
		WHEN 'NER' then '9123'
		WHEN 'NET' then '9999'
		WHEN 'NEW' then '9999'
		WHEN 'NGA' then '9124'
		WHEN 'NIC' then '8307'
		WHEN 'NID' then '2104'
		WHEN 'NIU' then '1504'
		WHEN 'NLD' then '2308'
		WHEN 'NOR' then '2406'
		WHEN 'NPL' then '7105'
		WHEN 'NRU' then '1405'
		WHEN 'NULL' then '9999'
		WHEN 'NZL' then '1201'
		WHEN 'OMN' then '4211'
		WHEN 'PAK' then '7106'
		WHEN 'PAN' then '8308'
		WHEN 'PER' then '8213'
		WHEN 'PHI' then '9999'
		WHEN 'PHL' then '5204'
		WHEN 'PLW' then '1407'
		WHEN 'PNG' then '1302'
		WHEN 'POL' then '3307'
		WHEN 'PRK' then '6104'
		WHEN 'PRT' then '3106'
		WHEN 'PRY' then '8212'
		WHEN 'PSE' then '4202'
		WHEN 'PYF' then '1503'
		WHEN 'QAT' then '4212'
		WHEN 'ROM' then '3211'
		WHEN 'ROU' then '3211'
		WHEN 'RUS' then '3308'
		WHEN 'RWA' then '9221'
		WHEN 'SA' then '9999'
		WHEN 'SAU' then '4213'
		WHEN 'SCG' then '3200'
		WHEN 'SDN' then '4105'
		WHEN 'SEN' then '9126'
		WHEN 'SGP' then '5205'
		WHEN 'SIN' then '9999'
		WHEN 'SLB' then '1303'
		WHEN 'SLE' then '9127'
		WHEN 'SLV' then '8303'
		WHEN 'SMR' then '3107'
		WHEN 'SOM' then '9224'
		WHEN 'SOU' then '9999'
		WHEN 'SRB' then '3215'
		WHEN 'SSD' then '4111'
		WHEN 'STP' then '9125'
		WHEN 'SUR' then '8214'
		WHEN 'SVK' then '3311'
		WHEN 'SVN' then '3212'
		WHEN 'SWE' then '2407'
		WHEN 'SWI' then '9999'
		WHEN 'SWZ' then '9226'
		WHEN 'SYC' then '9223'
		WHEN 'SYR' then '4214'
		WHEN 'TCD' then '9106'
		WHEN 'TGO' then '9128'
		WHEN 'THA' then '5104'
		WHEN 'TJK' then '7207'
		WHEN 'TKL' then '1507'
		WHEN 'TKM' then '7208'
		WHEN 'TLS' then '5206'
		WHEN 'TON' then '1508'
		WHEN 'TTO' then '8425'
		WHEN 'TUN' then '4106'
		WHEN 'TUR' then '4215'
		WHEN 'TUV' then '1511'
		WHEN 'TWN' then '6108'
		WHEN 'TZA' then '9227'
		WHEN 'UGA' then '9228'
		WHEN 'UK' then '9999'
		WHEN 'UKR' then '3312'
		WHEN 'UMI' then '8104'
		WHEN 'UNI' then '9999'
		WHEN 'UNR' then '9999'
		WHEN 'URY' then '8215'
		WHEN 'USA' then '8104'
		WHEN 'UZB' then '7211'
		WHEN 'VAT' then '3103'
		WHEN 'VCT' then '8424'
		WHEN 'VEN' then '8216'
		WHEN 'VNM' then '5105'
		WHEN 'VUT' then '1304'
		WHEN 'WAL' then '2106'
		WHEN 'WSM' then '1505'
		WHEN 'XHI' then '9999'
		WHEN 'XXX' then '9999'
		WHEN 'YEM' then '4217'
		WHEN 'YUG' then '3200'
		WHEN 'ZAF' then '9225'
		WHEN 'ZMB' then '9231'
		WHEN 'ZWE' then '9232'
		ELSE NULL END AS code
	,7 AS source_rank
FROM date_ranked
WHERE date_rank = 1
GO

/********************************************************
MOE school enrolment - first COC by date
'XXXX' as raw_code_sys
********************************************************/
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_moe_school_roll]
GO

SELECT DISTINCT [snz_moe_uid]
	,[CollectionDate]
	,[CountryOfCitizenship]
INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_moe_school_roll]
FROM (

	SELECT DISTINCT [snz_moe_uid],[CollectionDate],[CountryOfCitizenship] FROM [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2019]
	UNION ALL
	SELECT DISTINCT [snz_moe_uid],[CollectionDate],[CountryOfCitizenship] FROM [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2018]
	UNION ALL
	SELECT DISTINCT [snz_moe_uid],[CollectionDate],[CountryOfCitizenship] FROM [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2017]
	UNION ALL
	SELECT DISTINCT [snz_moe_uid],[CollectionDate],[CountryOfCitizenship] FROM [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2016]
	UNION ALL
	SELECT DISTINCT [snz_moe_uid],[CollectionDate],[CountryOfCitizenship] FROM [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2015]
	UNION ALL
	SELECT DISTINCT [snz_moe_uid],[CollectionDate],[CountryOfCitizenship] FROM [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2014]
	UNION ALL
	SELECT DISTINCT [snz_moe_uid],[CollectionDate],[CountryOfCitizenship] FROM [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2013]
	UNION ALL
	SELECT DISTINCT [snz_moe_uid],[CollectionDate],[CountryOfCitizenship] FROM [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2012]
	UNION ALL
	SELECT DISTINCT [snz_moe_uid],[CollectionDate],[CountryOfCitizenship] FROM [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2011]
	UNION ALL
	SELECT DISTINCT [snz_moe_uid],[CollectionDate],[CountryOfCitizenship] FROM [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2010]
	UNION ALL
	SELECT DISTINCT [snz_moe_uid],[CollectionDate],[CountryOfCitizenship] FROM [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2009]
	UNION ALL
	SELECT DISTINCT [snz_moe_uid],[CollectionDate],[CountryOfCitizenship] FROM [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2008]
	UNION ALL
	SELECT DISTINCT [snz_moe_uid],[CollectionDate],[CountryOfCitizenship] FROM [IDI_Adhoc].[clean_read_MOE].[School_Roll_Return_2007]

) AS k
WHERE [CountryOfCitizenship] NOT IN ('XXX','999','000')
AND [CountryOfCitizenship] IS NOT NULL
GO

CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2021-49].[tmp_moe_school_roll] ([snz_moe_uid])
GO

WITH date_ranked AS (
	SELECT *
		,RANK() OVER (PARTITION BY [snz_moe_uid] ORDER BY [CollectionDate]) AS date_rank
	FROM [IDI_Sandpit].[DL-MAA2021-49].[tmp_moe_school_roll]
)
INSERT INTO [IDI_Sandpit].[DL-MAA2021-49].[tmp_COB_list] (snz_uid, c_type, code, source_rank)
SELECT snz_uid
	,'COC' AS c_type
	,CASE [CountryOfCitizenship]
		WHEN '0' then '9999'
		WHEN '102' then '9999'
		WHEN '110' then '9999'
		WHEN '999' then '9999'
		WHEN 'ABW' then '2308'
		WHEN 'AFG' then '7201'
		WHEN 'AGO' then '9201'
		WHEN 'ALB' then '3201'
		WHEN 'AME' then '9999'
		WHEN 'AND' then '3101'
		WHEN 'ANT' then '2308'
		WHEN 'ARE' then '4216'
		WHEN 'ARG' then '8201'
		WHEN 'ARM' then '7202'
		WHEN 'ASM' then '1506'
		WHEN 'ATG' then '8402'
		WHEN 'AUL' then '9999'
		WHEN 'AUS' then '1101'
		WHEN 'AUT' then '2301'
		WHEN 'AZE' then '7203'
		WHEN 'BDI' then '9203'
		WHEN 'BEL' then '2302'
		WHEN 'BEN' then '9101'
		WHEN 'BFA' then '9102'
		WHEN 'BGD' then '7101'
		WHEN 'BGR' then '3203'
		WHEN 'BHR' then '4201'
		WHEN 'BHS' then '8404'
		WHEN 'BIH' then '3202'
		WHEN 'BLR' then '3301'
		WHEN 'BLZ' then '8301'
		WHEN 'BOL' then '8202'
		WHEN 'BOZ' then '3200'
		WHEN 'BRA' then '8203'
		WHEN 'BRB' then '8405'
		WHEN 'BRN' then '5201'
		WHEN 'BTN' then '7102'
		WHEN 'BUL' then '9999'
		WHEN 'BWA' then '9202'
		WHEN 'CAF' then '9105'
		WHEN 'CAN' then '8102'
		WHEN 'CHE' then '2311'
		WHEN 'CHI' then '9999'
		WHEN 'CHL' then '8204'
		WHEN 'CHN' then '6101'
		WHEN 'CIV' then '9111'
		WHEN 'CMR' then '9103'
		WHEN 'COD' then '9108'
		WHEN 'COG' then '9107'
		WHEN 'COK' then '1501'
		WHEN 'COL' then '8205'
		WHEN 'COM' then '9204'
		WHEN 'CRI' then '8302'
		WHEN 'CSK' then '3302'
		WHEN 'CUB' then '8407'
		WHEN 'CYP' then '3205'
		WHEN 'CZE' then '3302'
		WHEN 'DEU' then '2304'
		WHEN 'DJI' then '9205'
		WHEN 'DMA' then '8408'
		WHEN 'DNK' then '2401'
		WHEN 'DOM' then '8411'
		WHEN 'DZA' then '4101'
		WHEN 'ECU' then '8206'
		WHEN 'EGY' then '4102'
		WHEN 'ENG' then '2102'
		WHEN 'ERI' then '9206'
		WHEN 'ESH' then '4107'
		WHEN 'ESP' then '3108'
		WHEN 'EST' then '3303'
		WHEN 'ETH' then '9207'
		WHEN 'FIN' then '2403'
		WHEN 'FJI' then '1502'
		WHEN 'FRA' then '2303'
		WHEN 'FSM' then '1404'
		WHEN 'GAB' then '9113'
		WHEN 'GBR' then '2100'
		WHEN 'GEO' then '7204'
		WHEN 'GHA' then '9115'
		WHEN 'GIN' then '9116'
		WHEN 'GJS' then '2101'
		WHEN 'GMB' then '9114'
		WHEN 'GNQ' then '9112'
		WHEN 'GRC' then '3207'
		WHEN 'GRD' then '8412'
		WHEN 'GRE' then '9999'
		WHEN 'GTM' then '8304'
		WHEN 'GUY' then '8211'
		WHEN 'HIL' then '2105'
		WHEN 'HKG' then '6102'
		WHEN 'HND' then '8305'
		WHEN 'HOL' then '9999'
		WHEN 'HRV' then '3204'
		WHEN 'HTI' then '8414'
		WHEN 'HUN' then '3304'
		WHEN 'IDN' then '5202'
		WHEN 'IND' then '7103'
		WHEN 'IRL' then '2201'
		WHEN 'IRN' then '4203'
		WHEN 'IRQ' then '4204'
		WHEN 'ISL' then '2405'
		WHEN 'ISR' then '4205'
		WHEN 'ITA' then '3104'
		WHEN 'JAM' then '8415'
		WHEN 'JAP' then '9999'
		WHEN 'JOR' then '4206'
		WHEN 'JPN' then '6103'
		WHEN 'KAZ' then '7205'
		WHEN 'KEN' then '9208'
		WHEN 'KGZ' then '7206'
		WHEN 'KHM' then '5102'
		WHEN 'KIR' then '1402'
		WHEN 'KNA' then '8422'
		WHEN 'KOR' then '6105'
		WHEN 'KUR' then '9999'
		WHEN 'KWT' then '4207'
		WHEN 'LAO' then '5103'
		WHEN 'LBN' then '4208'
		WHEN 'LBR' then '9118'
		WHEN 'LBY' then '4103'
		WHEN 'LCA' then '8423'
		WHEN 'LIE' then '2305'
		WHEN 'LKA' then '7107'
		WHEN 'LSO' then '9211'
		WHEN 'LTU' then '3306'
		WHEN 'LUX' then '2306'
		WHEN 'LVA' then '3305'
		WHEN 'MAC' then '6106'
		WHEN 'MAL' then '9999'
		WHEN 'MAR' then '4104'
		WHEN 'MCD' then '3200'
		WHEN 'MCO' then '2307'
		WHEN 'MDA' then '3208'
		WHEN 'MDG' then '9212'
		WHEN 'MDV' then '7104'
		WHEN 'MEX' then '8306'
		WHEN 'MHL' then '1403'
		WHEN 'MKD' then '3200'
		WHEN 'MLI' then '9121'
		WHEN 'MLT' then '3105'
		WHEN 'MMR' then '5101'
		WHEN 'MNE' then '3214'
		WHEN 'MNG' then '6107'
		WHEN 'MOZ' then '9216'
		WHEN 'MRT' then '9122'
		WHEN 'MSR' then '2100'
		WHEN 'MUS' then '9214'
		WHEN 'MWI' then '9213'
		WHEN 'MYS' then '5203'
		WHEN 'MZL' then '9999'
		WHEN 'NAM' then '9217'
		WHEN 'NCL' then '1301'
		WHEN 'NER' then '9123'
		WHEN 'NET' then '9999'
		WHEN 'NEW' then '9999'
		WHEN 'NGA' then '9124'
		WHEN 'NIC' then '8307'
		WHEN 'NID' then '2104'
		WHEN 'NIU' then '1504'
		WHEN 'NLD' then '2308'
		WHEN 'NOR' then '2406'
		WHEN 'NPL' then '7105'
		WHEN 'NRU' then '1405'
		WHEN 'NULL' then '9999'
		WHEN 'NZL' then '1201'
		WHEN 'OMN' then '4211'
		WHEN 'PAK' then '7106'
		WHEN 'PAN' then '8308'
		WHEN 'PER' then '8213'
		WHEN 'PHI' then '9999'
		WHEN 'PHL' then '5204'
		WHEN 'PLW' then '1407'
		WHEN 'PNG' then '1302'
		WHEN 'POL' then '3307'
		WHEN 'PRK' then '6104'
		WHEN 'PRT' then '3106'
		WHEN 'PRY' then '8212'
		WHEN 'PSE' then '4202'
		WHEN 'PYF' then '1503'
		WHEN 'QAT' then '4212'
		WHEN 'ROM' then '3211'
		WHEN 'ROU' then '3211'
		WHEN 'RUS' then '3308'
		WHEN 'RWA' then '9221'
		WHEN 'SA' then '9999'
		WHEN 'SAU' then '4213'
		WHEN 'SCG' then '3200'
		WHEN 'SDN' then '4105'
		WHEN 'SEN' then '9126'
		WHEN 'SGP' then '5205'
		WHEN 'SIN' then '9999'
		WHEN 'SLB' then '1303'
		WHEN 'SLE' then '9127'
		WHEN 'SLV' then '8303'
		WHEN 'SMR' then '3107'
		WHEN 'SOM' then '9224'
		WHEN 'SOU' then '9999'
		WHEN 'SRB' then '3215'
		WHEN 'SSD' then '4111'
		WHEN 'STP' then '9125'
		WHEN 'SUR' then '8214'
		WHEN 'SVK' then '3311'
		WHEN 'SVN' then '3212'
		WHEN 'SWE' then '2407'
		WHEN 'SWI' then '9999'
		WHEN 'SWZ' then '9226'
		WHEN 'SYC' then '9223'
		WHEN 'SYR' then '4214'
		WHEN 'TCD' then '9106'
		WHEN 'TGO' then '9128'
		WHEN 'THA' then '5104'
		WHEN 'TJK' then '7207'
		WHEN 'TKL' then '1507'
		WHEN 'TKM' then '7208'
		WHEN 'TLS' then '5206'
		WHEN 'TON' then '1508'
		WHEN 'TTO' then '8425'
		WHEN 'TUN' then '4106'
		WHEN 'TUR' then '4215'
		WHEN 'TUV' then '1511'
		WHEN 'TWN' then '6108'
		WHEN 'TZA' then '9227'
		WHEN 'UGA' then '9228'
		WHEN 'UK' then '9999'
		WHEN 'UKR' then '3312'
		WHEN 'UMI' then '8104'
		WHEN 'UNI' then '9999'
		WHEN 'UNR' then '9999'
		WHEN 'URY' then '8215'
		WHEN 'USA' then '8104'
		WHEN 'UZB' then '7211'
		WHEN 'VAT' then '3103'
		WHEN 'VCT' then '8424'
		WHEN 'VEN' then '8216'
		WHEN 'VNM' then '5105'
		WHEN 'VUT' then '1304'
		WHEN 'WAL' then '2106'
		WHEN 'WSM' then '1505'
		WHEN 'XHI' then '9999'
		WHEN 'XXX' then '9999'
		WHEN 'YEM' then '4217'
		WHEN 'YUG' then '3200'
		WHEN 'ZAF' then '9225'
		WHEN 'ZMB' then '9231'
		WHEN 'ZWE' then '9232'
		ELSE NULL END AS code
	,8 AS source_rank
FROM date_ranked AS a
INNER JOIN [IDI_Clean_20211020].[moe_clean].[nsi] AS b
ON a.snz_moe_uid = b.snz_moe_uid
WHERE date_rank = 1
GO

/***************************************************************************************************************
Keep best rank for each person
***************************************************************************************************************/

CREATE NONCLUSTERED INDEX my_index ON [IDI_Sandpit].[DL-MAA2021-49].[tmp_COB_list] (snz_uid)
GO

DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[vacc_country_of_birth]
GO

WITH source_ranked AS (
	SELECT *
		,RANK() OVER (PARTITION BY [snz_uid] ORDER BY source_rank) AS ranked
	FROM [IDI_Sandpit].[DL-MAA2021-49].[tmp_COB_list]
)
SELECT snz_uid
	, c_type
	, CAST(code AS INT) AS code
	, source_rank
INTO [IDI_Sandpit].[DL-MAA2021-49].[vacc_country_of_birth]
FROM source_ranked
WHERE ranked = 1
AND code IS NOT NULL
AND code NOT IN ('9999', '0000')
GO

CREATE NONCLUSTERED INDEX my_index_name ON [IDI_Sandpit].[DL-MAA2021-49].[vacc_country_of_birth] (snz_uid);
GO
ALTER TABLE [IDI_Sandpit].[DL-MAA2021-49].[vacc_country_of_birth] REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)
GO

/***************************************************************************************************************
Delete templorary tables
***************************************************************************************************************/
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_COB_list]
GO
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_moe_enrollment]
GO
DROP TABLE IF EXISTS [IDI_Sandpit].[DL-MAA2021-49].[tmp_moe_school_roll]
GO
