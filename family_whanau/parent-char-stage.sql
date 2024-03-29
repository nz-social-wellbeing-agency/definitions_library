/*
Title: Highest Educational Attainment of Biological Parents
Author: Joel Bancolita
Intended use: Biological parents' educational attainment, work status
Notes:
Dependents:
- [$(PROJSCH)].[$(TBLPREF)parents_staging]
- [$(PROJSCH)].[$(TBLPREF)evtvw_hst_qual] 
History (reverse order):
2020-07-15: JB initialise
*/
--PARAMETERS##################################################################################################
--SQLCMD only (Activate by clicking Query->SQLCMD Mode)
/* Already in master.sql; Uncomment if running individually
:setvar TBLPREF "swangt_"
:setvar IDIREF "IDI_Clean_20200120"
:setvar PROJSCH "DL-MAA2020-35"
GO
*/
--##############################################################################################################
/*embedded in user code*/
USE IDI_UserCode
GO

--PARAMETERS##################################################################################################
--SQLCMD only
/* highest educational attainment of parents */
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_parent_hst_qual]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_parent_hst_qual];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_parent_hst_qual]
AS
SELECT [par].[snz_uid]
	,[qual].[start_date]
	,[qual].[end_date]
	,'Parent: ' + [qual].[description] AS [description]
	,[qual].[value]
	,[qual].[source]
FROM [$(PROJSCH)].[$(TBLPREF)parents_staging] [par]
INNER JOIN [$(PROJSCH)].[$(TBLPREF)evtvw_hst_qual] [qual] ON [par].[parent_id] = [qual].[snz_uid];
GO

/*
Title: Employment of parent (W&S and WHP)
Author: Joel Bancolita
Intended use: Biological parents' educational attainment, work status
Depends: employment-stage.sql
Notes:
History (reverse order):
2020-07-15: JB initialise
*/
IF OBJECT_ID('[$(PROJSCH)].[$(TBLPREF)evtvw_parent_empl]', 'V') IS NOT NULL
	DROP VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_parent_empl];
GO

CREATE VIEW [$(PROJSCH)].[$(TBLPREF)evtvw_parent_empl]
AS
SELECT [par].[snz_uid]
	,[empl].[start_date]
	,[empl].[end_date]
	,'Parent: ' + [empl].[description] AS [description]
	,[empl].[value]
	,'dia, ird ems' AS [source]
FROM [$(PROJSCH)].[$(TBLPREF)parents_staging] [par]
INNER JOIN [$(PROJSCH)].[$(TBLPREF)evtvw_empl] [empl] ON [par].[parent_id] = [empl].[snz_uid];
GO