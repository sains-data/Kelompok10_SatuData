/* File: 01_Create_Database.sql
   Deskripsi: Membuat Database Data Mart dan Schema Staging
*/

-- Membuat Database
CREATE DATABASE DM_SatuDataITERA_DW;
GO

USE DM_SatuDataITERA_DW;
GO

-- Membuat Schema Staging
-- Schema ini akan menampung data mentah sebelum masuk ke tabel utama
CREATE SCHEMA stg;
GO

PRINT 'Database dan Schema berhasil dibuat.';