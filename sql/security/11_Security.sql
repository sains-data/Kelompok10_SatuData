/* File: 10_Security_FIXED_DOCKER.sql
   Deskripsi: Implementasi Keamanan (Roles, Users, Masking, Audit)
*/

USE DM_SatuDataITERA_DW;
GO


-- 1. PEMBUATAN ROLE DATABASE
-- Hapus member dari role terlebih dahulu sebelum drop role
IF DATABASE_PRINCIPAL_ID('executive_user') IS NOT NULL AND DATABASE_PRINCIPAL_ID('db_executive') IS NOT NULL
    ALTER ROLE db_executive DROP MEMBER executive_user;
IF DATABASE_PRINCIPAL_ID('analyst_user') IS NOT NULL AND DATABASE_PRINCIPAL_ID('db_analyst') IS NOT NULL
    ALTER ROLE db_analyst DROP MEMBER analyst_user;
IF DATABASE_PRINCIPAL_ID('etl_operator_user') IS NOT NULL AND DATABASE_PRINCIPAL_ID('db_etl_operator') IS NOT NULL
    ALTER ROLE db_etl_operator DROP MEMBER etl_operator_user;
IF DATABASE_PRINCIPAL_ID('viewer_user') IS NOT NULL AND DATABASE_PRINCIPAL_ID('db_viewer') IS NOT NULL
    ALTER ROLE db_viewer DROP MEMBER viewer_user;
GO

-- Sekarang baru drop role
IF DATABASE_PRINCIPAL_ID('db_executive') IS NOT NULL DROP ROLE db_executive;
IF DATABASE_PRINCIPAL_ID('db_analyst') IS NOT NULL DROP ROLE db_analyst;
IF DATABASE_PRINCIPAL_ID('db_etl_operator') IS NOT NULL DROP ROLE db_etl_operator;
IF DATABASE_PRINCIPAL_ID('db_viewer') IS NOT NULL DROP ROLE db_viewer;
GO

CREATE ROLE db_executive;
CREATE ROLE db_analyst;
CREATE ROLE db_etl_operator;
CREATE ROLE db_viewer;
GO

-- Grant Permissions
GRANT SELECT ON SCHEMA::dbo TO db_executive; -- Executive lihat semua
GRANT UNMASK TO db_executive; -- Executive lihat data asli (unmasked)

GRANT SELECT ON SCHEMA::dbo TO db_analyst;
GRANT CREATE VIEW TO db_analyst;
GRANT UNMASK TO db_analyst;

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO db_etl_operator;
GRANT EXECUTE TO db_etl_operator;

-- Viewer: Akses ke Tabel Dimensi/Fakta DAN VIEW (Penting untuk Power BI)
GRANT SELECT ON SCHEMA::dbo TO db_viewer; 
-- (Atau jika ingin spesifik, list tabel dan view satu per satu seperti script awal Anda)
-- Agar simpel untuk tugas besar, SCHEMA::dbo lebih aman biar tidak ada yang terlewat.
GO


-- 2. PEMBUATAN LOGIN DAN USER
-- Hapus Login Lama (Cleanup)
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'executive_user') DROP LOGIN executive_user;
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'analyst_user') DROP LOGIN analyst_user;
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'etl_operator_user') DROP LOGIN etl_operator_user;
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'viewer_user') DROP LOGIN viewer_user;
GO

-- Buat Login
CREATE LOGIN executive_user WITH PASSWORD = 'Executive@2025', CHECK_POLICY = ON;
CREATE LOGIN analyst_user WITH PASSWORD = 'Analyst@2025', CHECK_POLICY = ON;
CREATE LOGIN etl_operator_user WITH PASSWORD = 'ETL0perator@2025', CHECK_POLICY = ON;
CREATE LOGIN viewer_user WITH PASSWORD = 'Viewer@2025', CHECK_POLICY = ON;
GO

-- Hapus User Lama di Database
IF DATABASE_PRINCIPAL_ID('executive_user') IS NOT NULL DROP USER executive_user;
IF DATABASE_PRINCIPAL_ID('analyst_user') IS NOT NULL DROP USER analyst_user;
IF DATABASE_PRINCIPAL_ID('etl_operator_user') IS NOT NULL DROP USER etl_operator_user;
IF DATABASE_PRINCIPAL_ID('viewer_user') IS NOT NULL DROP USER viewer_user;
GO

-- Mapping User ke Login
CREATE USER executive_user FOR LOGIN executive_user;
CREATE USER analyst_user FOR LOGIN analyst_user;
CREATE USER etl_operator_user FOR LOGIN etl_operator_user;
CREATE USER viewer_user FOR LOGIN viewer_user;
GO

-- Assign Role
ALTER ROLE db_executive ADD MEMBER executive_user;
ALTER ROLE db_analyst ADD MEMBER analyst_user;
ALTER ROLE db_etl_operator ADD MEMBER etl_operator_user;
ALTER ROLE db_viewer ADD MEMBER viewer_user;
GO


-- 3. DYNAMIC DATA MASKING
-- Masking Username
IF OBJECT_ID('dbo.Dim_User', 'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.Dim_User 
    ALTER COLUMN Username ADD MASKED WITH (FUNCTION = 'partial(1,"XXX",1)');
END
GO

-- Masking Query_Text (Tanpa mengubah tipe data ke TEXT!)
IF OBJECT_ID('dbo.Fact_Search_Query', 'U') IS NOT NULL
BEGIN
    -- Kita asumsikan kolom ini sudah VARCHAR(MAX) dari perbaikan sebelumnya.
    -- Masking function 'default()' bekerja baik pada VARCHAR.
    ALTER TABLE dbo.Fact_Search_Query 
    ALTER COLUMN Query_Text ADD MASKED WITH (FUNCTION = 'default()');
END
GO


-- 4. AUDIT TRAIL (Custom Table & Trigger)
IF OBJECT_ID('dbo.AuditLog', 'U') IS NOT NULL DROP TABLE dbo.AuditLog;
GO

CREATE TABLE dbo.AuditLog (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(128),
    Operation NVARCHAR(10),
    RecordID BIGINT, 
    OldValue NVARCHAR(MAX),
    NewValue NVARCHAR(MAX),
    ModifiedBy NVARCHAR(128) DEFAULT SUSER_SNAME(),
    ModifiedDate DATETIME DEFAULT GETDATE()
);
GO

-- Trigger Audit
CREATE OR ALTER TRIGGER trg_Audit_Fact_Dataset_Access
ON dbo.Fact_Dataset_Access
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Operation NVARCHAR(10);
    
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted) SET @Operation = 'UPDATE';
    ELSE IF EXISTS (SELECT * FROM inserted) SET @Operation = 'INSERT';
    ELSE SET @Operation = 'DELETE';

    IF @Operation = 'INSERT'
        INSERT INTO dbo.AuditLog (TableName, Operation, RecordID, NewValue)
        SELECT 'Fact_Dataset_Access', 'INSERT', Access_SK, 
        CONCAT('DS:', Dataset_SK, ', Usr:', User_SK) FROM inserted;

    IF @Operation = 'UPDATE'
        INSERT INTO dbo.AuditLog (TableName, Operation, RecordID, OldValue, NewValue)
        SELECT 'Fact_Dataset_Access', 'UPDATE', i.Access_SK, 
        CONCAT('DS:', d.Dataset_SK, ', Usr:', d.User_SK),
        CONCAT('DS:', i.Dataset_SK, ', Usr:', i.User_SK)
        FROM inserted i JOIN deleted d ON i.Access_SK = d.Access_SK;

    IF @Operation = 'DELETE'
        INSERT INTO dbo.AuditLog (TableName, Operation, RecordID, OldValue)
        SELECT 'Fact_Dataset_Access', 'DELETE', Access_SK, 
        CONCAT('DS:', Dataset_SK, ', Usr:', User_SK) FROM deleted;
END;
GO


-- 5. SQL SERVER AUDIT (Linux Path Fixed)
USE master;
GO

IF EXISTS (SELECT * FROM sys.server_audits WHERE name = 'SatuDataITERA_Audit')
BEGIN
    ALTER SERVER AUDIT SatuDataITERA_Audit WITH (STATE = OFF);
    DROP SERVER AUDIT SatuDataITERA_Audit;
END
GO

-- [FIX]: Gunakan Path Linux untuk Docker
CREATE SERVER AUDIT SatuDataITERA_Audit
TO FILE 
(
    FILEPATH = '/var/opt/mssql/data/', -- Path aman di dalam container
    MAXSIZE = 100 MB,
    MAX_ROLLOVER_FILES = 10
)
WITH (ON_FAILURE = CONTINUE);
GO

ALTER SERVER AUDIT SatuDataITERA_Audit WITH (STATE = ON);
GO

-- Database Audit Spec
USE DM_SatuDataITERA_DW;
GO

IF EXISTS (SELECT * FROM sys.database_audit_specifications WHERE name = 'SatuDataITERA_Audit_Spec')
BEGIN
    ALTER DATABASE AUDIT SPECIFICATION SatuDataITERA_Audit_Spec WITH (STATE = OFF);
    DROP DATABASE AUDIT SPECIFICATION SatuDataITERA_Audit_Spec;
END
GO

CREATE DATABASE AUDIT SPECIFICATION SatuDataITERA_Audit_Spec
FOR SERVER AUDIT SatuDataITERA_Audit
ADD (SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo BY public),
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP);
GO

ALTER DATABASE AUDIT SPECIFICATION SatuDataITERA_Audit_Spec WITH (STATE = ON);
GO

PRINT '=== KEAMANAN (ROLES, MASKING, AUDIT) BERHASIL DITERAPKAN ===';