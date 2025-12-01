USE msdb;
GO

-- Buat Job
EXEC sp_add_job
    @job_name = N'ETL_Daily_Load',
    @enabled = 1,
    @description = N'Daily ETL load for Data Mart';
GO

-- Buat Step (Langkah) untuk Eksekusi Master ETL
EXEC sp_add_jobstep
    @job_name = N'ETL_Daily_Load',
    @step_name = N'Execute Master ETL',
    @subsystem = N'TSQL',
    @command = N'EXEC dbo.usp_Master_ETL;',  
    @database_name = N'DM_SatuDataITERA_DW',    
    @retry_attempts = 3,
    @retry_interval = 5;
GO

-- Buat Jadwal Harian Pukul 02:00 AM
EXEC sp_add_schedule
    @schedule_name = N'Daily at 2 AM',
    @freq_type = 4,        -- harian
    @freq_interval = 1,    -- setiap 1 hari
    @active_start_time = 020000; -- 02:00:00
GO

-- Tempelkan Jadwal ke Job
EXEC sp_attach_schedule
    @job_name = N'ETL_Daily_Load',
    @schedule_name = N'Daily at 2 AM';
GO

-- Atur Target Local Server
EXEC sp_add_jobserver
    @job_name = N'ETL_Daily_Load';
GO