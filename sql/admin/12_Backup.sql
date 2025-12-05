/* File: 11_Backup_FIXED_DOCKER.sql
   Deskripsi: Strategi Backup dan Recovery untuk DM_SatuDataITERA_DW
*/

USE master;
GO

-- Pastikan Database dalam Recovery Model FULL (Syarat Transaction Log Backup)
ALTER DATABASE DM_SatuDataITERA_DW SET RECOVERY FULL;
GO


-- FULL BACKUP (Mingguan)
CREATE OR ALTER PROCEDURE dbo.sp_FullBackup_SatuDataITERA
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @BackupPath NVARCHAR(500) = '/var/opt/mssql/data/';
    DECLARE @FileName NVARCHAR(500);
    DECLARE @DatabaseName NVARCHAR(100) = 'DM_SatuDataITERA_DW';
    DECLARE @CurrentDate NVARCHAR(50);
    
    SET @CurrentDate = CONVERT(NVARCHAR(50), GETDATE(), 112) + '_' + REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 108), ':', '');
    SET @FileName = @BackupPath + @DatabaseName + '_Full_' + @CurrentDate + '.bak';
    
    BACKUP DATABASE [DM_SatuDataITERA_DW] 
    TO DISK = @FileName 
    WITH INIT, NAME = 'Full Backup', COMPRESSION, STATS = 10;
    
    PRINT 'Full Backup sukses: ' + @FileName;
END;
GO


-- DIFFERENTIAL BACKUP (Harian)
CREATE OR ALTER PROCEDURE dbo.sp_DifferentialBackup_SatuDataITERA
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @BackupPath NVARCHAR(500) = '/var/opt/mssql/data/'; -- [FIX]: Path Linux
    DECLARE @FileName NVARCHAR(500);
    DECLARE @DatabaseName NVARCHAR(100) = 'DM_SatuDataITERA_DW';
    DECLARE @CurrentDate NVARCHAR(50);
    
    SET @CurrentDate = CONVERT(NVARCHAR(50), GETDATE(), 112) + '_' + REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 108), ':', '');
    SET @FileName = @BackupPath + @DatabaseName + '_Diff_' + @CurrentDate + '.bak';
    
    BACKUP DATABASE [DM_SatuDataITERA_DW] 
    TO DISK = @FileName 
    WITH DIFFERENTIAL, INIT, NAME = 'Diff Backup', COMPRESSION, STATS = 10;
    
    PRINT 'Diff Backup sukses: ' + @FileName;
END;
GO


-- TRANSACTION LOG BACKUP (Per 6 Jam)
CREATE OR ALTER PROCEDURE dbo.sp_LogBackup_SatuDataITERA
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @BackupPath NVARCHAR(500) = '/var/opt/mssql/data/'; -- [FIX]: Path Linux
    DECLARE @FileName NVARCHAR(500);
    DECLARE @DatabaseName NVARCHAR(100) = 'DM_SatuDataITERA_DW';
    DECLARE @CurrentDate NVARCHAR(50);
    
    SET @CurrentDate = CONVERT(NVARCHAR(50), GETDATE(), 112) + '_' + REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 108), ':', '');
    SET @FileName = @BackupPath + @DatabaseName + '_Log_' + @CurrentDate + '.trn';
    
    BACKUP LOG [DM_SatuDataITERA_DW] 
    TO DISK = @FileName 
    WITH INIT, NAME = 'Log Backup', COMPRESSION, STATS = 10;
    
    PRINT 'Log Backup sukses: ' + @FileName;
END;
GO


-- CLEANUP OLD BACKUPS (Maintenance)
CREATE OR ALTER PROCEDURE dbo.sp_CleanupOldBackups_SatuDataITERA
    @RetentionDays INT = 30
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @DeleteDate DATETIME = DATEADD(DAY, -@RetentionDays, GETDATE());
    
    -- Hapus history backup dari msdb agar tidak membengkak
    EXEC msdb.dbo.sp_delete_backuphistory @oldest_date = @DeleteDate;
    
    PRINT 'Backup History Cleanup sukses.';
END;
GO


-- SQL AGENT JOBS (Penjadwalan)
USE msdb;
GO

-- JOB: Full Backup (Mingguan)
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = 'SatuData_Backup_Full_Weekly')
    EXEC sp_delete_job @job_name = 'SatuData_Backup_Full_Weekly', @delete_unused_schedule=1;
GO
EXEC sp_add_job @job_name = 'SatuData_Backup_Full_Weekly', @enabled = 1;
EXEC sp_add_jobstep @job_name = 'SatuData_Backup_Full_Weekly', @step_name = 'Exec Full Backup', 
    @subsystem = 'TSQL', @command = 'EXEC master.dbo.sp_FullBackup_SatuDataITERA;', @database_name = 'master';
EXEC sp_add_schedule @schedule_name = 'WeeklySunday', @freq_type = 8, @freq_interval = 1, @freq_recurrence_factor = 1, @active_start_time = 020000;
EXEC sp_attach_schedule @job_name = 'SatuData_Backup_Full_Weekly', @schedule_name = 'WeeklySunday';
EXEC sp_add_jobserver @job_name = 'SatuData_Backup_Full_Weekly';
GO

-- JOB: Diff Backup (Harian)
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = 'SatuData_Backup_Diff_Daily')
    EXEC sp_delete_job @job_name = 'SatuData_Backup_Diff_Daily', @delete_unused_schedule=1;
GO
EXEC sp_add_job @job_name = 'SatuData_Backup_Diff_Daily', @enabled = 1;
EXEC sp_add_jobstep @job_name = 'SatuData_Backup_Diff_Daily', @step_name = 'Exec Diff Backup', 
    @subsystem = 'TSQL', @command = 'EXEC master.dbo.sp_DifferentialBackup_SatuDataITERA;', @database_name = 'master';
EXEC sp_add_schedule @schedule_name = 'DailyNoSunday', @freq_type = 8, @freq_interval = 126, @freq_recurrence_factor = 1, @active_start_time = 020000;
EXEC sp_attach_schedule @job_name = 'SatuData_Backup_Diff_Daily', @schedule_name = 'DailyNoSunday';
EXEC sp_add_jobserver @job_name = 'SatuData_Backup_Diff_Daily';
GO

-- JOB: Log Backup (6 Jam)
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = 'SatuData_Backup_Log_6Hourly')
    EXEC sp_delete_job @job_name = 'SatuData_Backup_Log_6Hourly', @delete_unused_schedule=1;
GO
EXEC sp_add_job @job_name = 'SatuData_Backup_Log_6Hourly', @enabled = 1;
EXEC sp_add_jobstep @job_name = 'SatuData_Backup_Log_6Hourly', @step_name = 'Exec Log Backup', 
    @subsystem = 'TSQL', @command = 'EXEC master.dbo.sp_LogBackup_SatuDataITERA;', @database_name = 'master';
EXEC sp_add_schedule @schedule_name = 'Every6Hours', @freq_type = 4, @freq_interval = 1, @freq_subday_type = 8, @freq_subday_interval = 6, @active_start_time = 000000;
EXEC sp_attach_schedule @job_name = 'SatuData_Backup_Log_6Hourly', @schedule_name = 'Every6Hours';
EXEC sp_add_jobserver @job_name = 'SatuData_Backup_Log_6Hourly';
GO


PRINT 'KONFIGURASI BACKUP BERHASIL DITERAPKAN';
